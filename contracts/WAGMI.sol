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

    mapping(address => Agreement[]) public signerToAgreementMapping;

    uint256 immutable groupId;
    uint256 immutable actionId;
    IWorldID worldId;

    // Errors

    error IncorrectSigner();

    // Events

    event Signed(string message, address signer);

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
            emit Signed(message, msg.sender);
        } else {
            revert IncorrectSigner();
        }
    }

    function verifyAgreement(
        address signer,
        uint256 index,
        string calldata agreement
    ) external view returns (bool) {
        Agreement memory tempAgreement = signerToAgreementMapping[signer][
            index
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
