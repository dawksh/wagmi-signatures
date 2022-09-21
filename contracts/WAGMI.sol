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
        bool isSigned;
    }

    mapping(uint256 => Agreement) public indexToAgreementStorage;

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

    function addAgreement(Agreement calldata _agreement) external {
        address sig = recoverAddress(
            _agreement.agreement,
            _agreement.signature
        );
        if (sig != msg.sender) revert IncorrectSignee();
        if (msg.sender == _agreement.signer) revert IncorrectSignee();
        indexToAgreementStorage[index] = _agreement;
        emit AgreementAdded(_agreement.agreement, msg.sender, index);
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

        function recoverAddress(string storage message, bytes calldata sig)
        internal
        pure
        returns (address)
    {
        bytes32 hash = ECDSA.toEthSignedMessageHash(abi.encodePacked(message));
        address _sig = ECDSA.recover(hash, sig);
        return _sig;
    }

    function signAgreement(
        bytes calldata signature,
        uint256 id,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external {
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(msg.sender).hashToField(), // The signal of the proof
            nullifierHash,
            actionId,
            proof
        );
        string storage message = indexToAgreementStorage[id].agreement;
        address signer = indexToAgreementStorage[id].signer;
        if(msg.sender != signer) revert IncorrectSigner();
        address _signer = recoverAddress(message, signature);
        if (_signer == msg.sender) {
            indexToAgreementStorage[id].isSigned = true;
            emit Signed(message, msg.sender, id);
        } else {
            revert IncorrectSigner();
        }
    }

    function verifyAgreement(
        uint256 id,
        string calldata agreement
    ) external view returns (bool) {
        Agreement memory tempAgreement = indexToAgreementStorage[id];
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

