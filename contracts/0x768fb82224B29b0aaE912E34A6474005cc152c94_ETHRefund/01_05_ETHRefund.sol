// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IApes.sol";

/// @title Bulls and Apes Project - 6-Month ETH back
/// @author BAP Dev Team
/// @notice Helper Contract to handle Apes ETH-back
contract ETHRefund is ReentrancyGuard, Ownable {
    /// @notice BAP Apes contract
    IApes public apesContract;
    /// @notice Address of the signer wallet
    address public secret;

    bool public isRefundActive;

    event Equipped(uint256 tokenId, string changeCode, address operator);

    /// @notice Deploys the contract
    /// @param _apes BAP Apes address
    /// @param _secret Signer address
    constructor(address _apes, address _secret) {
        apesContract = IApes(_apes);
        secret = _secret;
    }

    /// @notice Helper function to request ETH-Back refund
    /// @param tokenId ID of the Ape to ask refund
    /// @param to Owner of the Ape to send the funds
    /// @param signature Signature to verify above parameters
    function requestRefund(
        uint256 tokenId,
        address to,
        bytes memory signature
    ) external nonReentrant {
        require(tokenId <= 10000, "requestRefund: Can't refund equipped Ape");
        require(apesContract.exists(tokenId), "requestRefund: Ape doesn't exists");
        require(
            _verifyHashSignature(
                keccak256(abi.encode(tokenId, to, msg.sender, "BAP Refund")),
                signature
            ), // Checks validity of back-end provided signatre
            "requestRefund: Signature is invalid"
        );
        require(isRefundActive, "requestRefund: Refund is not active");

        apesContract.refund(to, tokenId);
    }

    /// @notice Batch request to check refund status on Apes
    /// @param ids IDs of Apes to check refund status
    function batchCheckRefund(uint256[] memory ids)
        external
        view
        returns (bool[] memory status, uint256[] memory prices)
    {
        uint256 tokenCount = ids.length;

        status = new bool[](tokenCount);
        prices = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            uint256 tokenId = ids[i];
            try apesContract.notRefundable(tokenId) returns (
                bool isRefundable
            ) {
                status[i] = isRefundable;
            } catch {
                status[i] = false;
            }

            prices[i] = apesContract.mintingPrice(tokenId);
        }
    }

    /// @notice Set new contracts addresses for Apes
    /// @param _apes New address for BAP Apes
    /// @dev Can only be called by the contract owner
    function setContracts(address _apes) external onlyOwner {
        apesContract = IApes(_apes);
    }

    /// @notice Change the signer address
    /// @param _secret new signer for encrypted signatures
    /// @dev Can only be called by the contract owner
    function setSecret(address _secret) external onlyOwner {
        secret = _secret;
    }

    /// @notice Change the refund status
    /// @param status new refund status
    /// @dev Can only be called by the contract owner
    function setRefundStatus(bool status) external onlyOwner {
        isRefundActive = status;
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}