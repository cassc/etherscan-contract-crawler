// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.6;

import "solmate/src/utils/SafeTransferLib.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./Utils.sol";

interface IWrapped is IERC20 {
    function withdraw(uint256 amount) external;
}

/// Cumulative Merkle distributor that supports claiming native chain currency via unwrapping.
/// @author Euler developers, modified by Morpho developers, modified by ParaSwap developers
contract CumulativeMerkleDistributor is Ownable {
    using SafeTransferLib for ERC20;

    /// STORAGE ///

    ERC20 public immutable TOKEN;
    bytes32 public currRoot; // The merkle tree's root of the current rewards distribution.
    bytes32 public prevRoot; // The merkle tree's root of the previous rewards distribution.
    mapping(address => uint256) public claimed; // The rewards already claimed. account -> amount.
    bool public isWrappedNative;

    /// EVENTS ///

    /// @notice Emitted when the root is updated.
    /// @param newRoot The new merkle's tree root.
    event RootUpdated(bytes32 newRoot);

    /// @notice Emitted when tokens are withdrawn.
    /// @param to The address of the recipient.
    /// @param amount The amount of tokens withdrawn.
    /// @param isNative Amount sent as native or wrapped
    event Withdrawn(address to, uint256 amount, bool isNative);

    /// @notice Emitted when an account claims rewards.
    /// @param account The address of the claimer.
    /// @param amount The amount of rewards claimed.
    /// @param isNative Rewards sent as native or wrapped
    event RewardsClaimed(address account, uint256 amount, bool isNative);

    /// ERRORS ///

    /// @notice Thrown when the proof is invalid or expired.
    error ProofInvalidOrExpired();

    /// @notice Thrown when the claimer has already claimed the rewards.
    error AlreadyClaimed();

    /// @notice throw when trying to claim native while not supported
    error NativeNotSupported();

    /// CONSTRUCTOR ///

    /// @notice Constructs RewardsDistributor contract.
    /// @param _token The address of the token to distribute.
    constructor(address _token, bool _isWrappedNative) {
        TOKEN = ERC20(_token);
        isWrappedNative = _isWrappedNative;
    }

    /// EXTERNAL ///

    /// @notice Updates the current merkle tree's root.
    /// @param _newRoot The new merkle tree's root.
    function updateRoot(bytes32 _newRoot) external onlyOwner {
        prevRoot = currRoot;
        currRoot = _newRoot;
        emit RootUpdated(_newRoot);
    }

    /// @notice Withdraws tokens to a recipient.
    /// @param _to The address of the recipient.
    /// @param _amount The amount of tokens to transfer.
    function withdrawTokens(address _to, uint256 _amount) external onlyOwner {
        uint256 tokenBalance = TOKEN.balanceOf(address(this));
        uint256 toWithdraw = tokenBalance < _amount ? tokenBalance : _amount;
        TOKEN.safeTransfer(_to, toWithdraw);
        emit Withdrawn(_to, toWithdraw, false);
    }

    /// @notice Withdraws native to a recipient.
    /// @param _to The address of the recipient.
    /// @param _amount The amount of tokens to transfer.
    function withdrawNative(address _to, uint256 _amount) external onlyOwner {
        if (isWrappedNative != true) {
            revert NativeNotSupported();
        }

        uint256 nativeBalance = address(this).balance;
        uint256 toWithdraw = nativeBalance < _amount ? nativeBalance : _amount;
        Utils.transferETH(payable(_to), toWithdraw);
        emit Withdrawn(_to, toWithdraw, true);
    }

    /// @notice Claims rewards.
    /// @param _account The address of the claimer.
    /// @param _claimable The overall claimable amount of token rewards.
    /// @param _proof The merkle proof that validates this claim.
    function _claim(
        address _account,
        uint256 _claimable,
        bytes32[] calldata _proof
    ) private returns (uint256) {
        bytes32 candidateRoot = MerkleProof.processProof(_proof, keccak256(abi.encodePacked(_account, _claimable)));
        if (candidateRoot != currRoot && candidateRoot != prevRoot) revert ProofInvalidOrExpired();

        uint256 alreadyClaimed = claimed[_account];
        if (_claimable <= alreadyClaimed) revert AlreadyClaimed();

        uint256 amount;
        unchecked {
            amount = _claimable - alreadyClaimed;
        }

        claimed[_account] = _claimable;

        return amount;
    }

    /// @notice Claims rewards.
    /// @param _account The address of the claimer.
    /// @param _claimable The overall claimable amount of token rewards.
    /// @param _proof The merkle proof that validates this claim.
    function claim(
        address _account,
        uint256 _claimable,
        bytes32[] calldata _proof
    ) external {
        uint256 amount = _claim(_account, _claimable, _proof);
        TOKEN.safeTransfer(_account, amount);

        emit RewardsClaimed(_account, amount, false);
    }

    /// @notice Claims rewards.
    /// @param _account The address of the claimer.
    /// @param _claimable The overall claimable amount of token rewards in native token.
    /// @param _proof The merkle proof that validates this claim.
    function claimNative(
        address _account,
        uint256 _claimable,
        bytes32[] calldata _proof
    ) external {
        if (isWrappedNative != true) {
            revert NativeNotSupported();
        }

        uint256 amount = _claim(_account, _claimable, _proof);
        IWrapped(address(TOKEN)).withdraw(amount);
        Utils.transferETH(payable(_account), amount);

        emit RewardsClaimed(_account, amount, true);
    }

    receive() external payable {}
}