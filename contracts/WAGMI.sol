// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IWorldID.sol";
import {ByteHasher} from "./helpers/ByteHasher.sol";

contract WAGMI {
    using ByteHasher for bytes;

    // Storage
    struct Agreement {
        uint256 id;
        address signer;
        string agreement;
        bytes signature;
    }

    struct UnSignedAgreement {
        uint256 id;
        address signer;
        string agreement;
        bytes signature;
        bool isSigned;
    }

    mapping(address => Agreement[]) public signerToAgreementMapping;
    mapping(uint256 => UnSignedAgreement) public indexToAgreementStorage;

    uint256 immutable groupId;
    uint256 immutable actionId;
    IWorldID worldId;
    uint256 index;

    // Errors

    error IncorrectSigner();
    error IncorrectSignee();

    // Events

    event Signed(string message, address signer, uint256 id);
    event AgreementAdded(string agreement, address signer, uint256 id);

    // Logic
    constructor(
        IWorldID _worldId,
        uint256 _groupId,
        string memory _actionId
    ) {
        worldId = _worldId;
        groupId = _groupId;
        actionId = abi.encodePacked(_actionId).hashToField();
    }

    function addAgreement(UnSignedAgreement calldata _agreement) external {
        address sig = recoverAddress(
            _agreement.agreement,
            _agreement.signature
        );
        if (sig != msg.sender) revert IncorrectSignee();
        indexToAgreementStorage[index] = _agreement;
        emit AgreementAdded(_agreement.agreement, sig, index);
        index++;
    }

    function recoverAddress(string calldata message, bytes calldata sig)
        internal
        pure
        returns (address)
    {
        bytes32 hash = ECDSA.toEthSignedMessageHash(abi.encodePacked(message));
        address _sig = ECDSA.recover(hash, sig);
        return _sig;
    }

    function signAgreement(
        string calldata message,
        bytes calldata signature,
        uint256 id,
        address receiver,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external {
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(receiver).hashToField(), // The signal of the proof
            nullifierHash,
            actionId,
            proof
        );
        address _signer = recoverAddress(message, signature);
        if (_signer == msg.sender) {
            uint256 len = signerToAgreementMapping[msg.sender].length;
            Agreement memory _agreement = Agreement(
                len,
                msg.sender,
                message,
                signature
            );
            signerToAgreementMapping[msg.sender].push(_agreement);
            indexToAgreementStorage[id].isSigned = true;
            emit Signed(message, msg.sender, id);
        } else {
            revert IncorrectSigner();
        }
    }

    function verifyAgreement(
        address signer,
        uint256 _index,
        string calldata agreement
    ) external view returns (bool) {
        Agreement memory tempAgreement = signerToAgreementMapping[signer][
            _index
        ];
        string memory _agreement = tempAgreement.agreement;
        if (
            keccak256(abi.encodePacked(_agreement)) ==
            keccak256(abi.encodePacked(agreement))
        ) {
            return true;
        } else {
            return false;
        }
    }
}
