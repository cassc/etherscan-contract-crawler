// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "./MerkleDistributorWithDeadline.sol";

/**
 * @dev Error: claimants MUST use the proper acceptance hash.
 */
error WrongAcceptanceHash(bytes32 _acceptanceHash);

/**
 * @dev Error: claimants MUST use claimAndDelegate function.
 */
error NotUsingClaimAndDelegateMethod(
    uint256 _index,
    address _account,
    uint256 _amount,
    bytes32[] _merkleProof
);

/**
 * @title MerkleDistributorWithDelegation.
 * @author ShamirLabs
 * @notice Merkle distributor with claim and delegation packed in one transaction.
 * @dev This contract inherits Uniswaps well-known Merkle Distributor contract.
 * The purpose of building this contract is to enforce self-delegation of tokens
 * at claiming time.
 */
contract MerkleDistributorWithDelegation is MerkleDistributorWithDeadline {
    using SafeERC20 for IERC20;

    bytes32 public immutable acceptanceHash; // @dev hash of the acceptance message.

    constructor(
        address token_,
        bytes32 merkleRoot_,
        uint256 endTime_,
        bytes32 acceptanceHash_,
        address nonClaimedTokensReceiver_
    )
        MerkleDistributorWithDeadline(
            token_,
            merkleRoot_,
            endTime_,
            nonClaimedTokensReceiver_
        )
    {
        acceptanceHash = acceptanceHash_;
    }

    /**
     * @notice This function is overriden to revert.
     */
    function claim(
        uint256 _index,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) public pure override {
        revert NotUsingClaimAndDelegateMethod(
            _index,
            _account,
            _amount,
            _merkleProof
        );
    }

    /**
     * @notice Claim and delegate tokens in one transaction.
     * @param _index index of the merkle proof.
     * @param _account claimant address
     * @param _amount amount of tokens to claim.
     * @param _merkleProof merkle proof.
     * @param _acceptanceHash hash of the acceptance message.
     */
    function claimAndDelegate(
        uint256 _index,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        bytes32 _acceptanceHash
    ) public {
        if (acceptanceHash != _acceptanceHash)
            revert WrongAcceptanceHash(_acceptanceHash);

        super.claim(_index, _account, _amount, _merkleProof);

        (bool success, ) = token.call(
            abi.encodeWithSignature(
                "delegateFromMerkleDistributor(address)",
                _account
            )
        );

        require(success, "MerkleDistributorWithDelegation: delegate failed");
    }
}