//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from  "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";



contract TaskRewards is Ownable, ReentrancyGuard {
    /// @notice Thrown when signature is invalid
    error InvalidSignature();

    /// @notice Thrown when cooldownPeriod is not passed
    error CoolPeriodNotOver();

    /// @notice Thrown when value is zero
    error ZeroValue();

    /// @notice Thrown when trying to reuse same signature
    error HashUsed();

    /// @notice Thrown when zero address is passed in an input
    error ZeroAddress();

    /// @notice Thrown when updating with the same value as previously stored
    error IdenticalValue();

    IERC20 public tomiToken;
    using SafeERC20 for IERC20;

    /// @notice Returns the address of signerWallet
    address private signerWallet;

    /// @notice Returns the address of rewardWallet
    address public rewardWallet;

    /// @notice Returns the cooldownPeriod (in second)
    uint256 public cooldownPeriod;

    /// @notice mapping gives last redeem time of the address
    mapping(address => uint256) public lastRedeemTime;

    /// @notice mapping gives the amount redeemed by the address
    mapping(address => uint256) public userRedeemHistory;

    /// @notice mapping gives the info of the signature
    mapping(bytes32 => bool) private _isUsed;

    event TokensDeposited(address indexed depositor, uint256 amount);
    event TokensRedeemed(address indexed redeemer, uint256 amount);

    event CooldownPeriodUpdated(
        uint256 oldCoolDownPeriod,
        uint256 newCooldownPeriod
    );

    event RewardWalletUpdated(
        address oldRewardWallet,
        address newRewardWallet
    );
    event SignerUpdated(address oldSigner, address newSigner);

    /// @notice restricts when updating wallet/contract address to zero address
    modifier checkZeroAddress(address which) {
        if (which == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    /// @dev Constructor.
    /// @param signerAddress The address of signer wallet
    /// @param tomiTokenAddress The address of tomi token
    /// @param cooldownDuration The cooldown duration in seconds
    constructor(
        address signerAddress,
        address tomiTokenAddress,
        uint256 cooldownDuration,
        address rewardWalletAddress
    ) Ownable(msg.sender) {
        if (signerAddress == address(0) || tomiTokenAddress == address(0)) {
            revert ZeroAddress();
        }
        signerWallet = signerAddress;
        tomiToken = IERC20(tomiTokenAddress);
        cooldownPeriod = cooldownDuration;
        rewardWallet = rewardWalletAddress;
    }

    /// @notice Redeems tomi tokens
    /// @param time The expiry time of the signature
    /// @param amount The amount of tomi tokens
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function redeemTokens(
        uint256 time,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        if (lastRedeemTime[msg.sender] + cooldownPeriod > block.timestamp) {
            revert CoolPeriodNotOver();
        }
        if (amount == 0) {
            revert ZeroValue();
        }
        _verifySignature(msg.sender, amount, time, v, r, s);
        userRedeemHistory[msg.sender] += amount;
        lastRedeemTime[msg.sender] = block.timestamp;
        tomiToken.safeTransferFrom(rewardWallet, msg.sender, amount);
        emit TokensRedeemed({redeemer: msg.sender, amount: amount});
    }

    /// @notice Updates cool down period
    /// @param newCooldownPeriod The new cool down period in seconds
    function updateCooldownPeriod(
        uint256 newCooldownPeriod
    ) external onlyOwner {
        uint oldCoolDownPeriod = cooldownPeriod;
        if (newCooldownPeriod == 0) {
            revert ZeroValue();
        }
        if (oldCoolDownPeriod == newCooldownPeriod) {
            revert IdenticalValue();
        }
        emit CooldownPeriodUpdated({
            oldCoolDownPeriod: oldCoolDownPeriod,
            newCooldownPeriod: newCooldownPeriod
        });
        cooldownPeriod = newCooldownPeriod;
    }

    /// @notice Updates reward wallet
    /// @param newRewardWallet The new reward wallet address
    function updateRewardWallet(
        address newRewardWallet
    ) external onlyOwner {
        address oldRewardWallet = rewardWallet;
        if (newRewardWallet == address(0)) {
            revert ZeroValue();
        }
        if (oldRewardWallet == newRewardWallet) {
            revert IdenticalValue();
        }
        emit RewardWalletUpdated({
            oldRewardWallet: oldRewardWallet,
            newRewardWallet: newRewardWallet
        });
        rewardWallet = newRewardWallet;
    }

    /// @notice Changes signer wallet address
    /// @param newSigner The address of the new signer wallet
    function updateSignerAddress(
        address newSigner
    ) external checkZeroAddress(newSigner) onlyOwner {
        address oldSigner = signerWallet;
        if (oldSigner == newSigner) {
            revert IdenticalValue();
        }
        emit SignerUpdated({oldSigner: oldSigner, newSigner: newSigner});
        signerWallet = newSigner;
    }

    /// @notice The helper function which verifies signature, signed by signerWallet, reverts if invalid sSignature
    function _verifySignature(
        address redeemer,
        uint256 amount,
        uint256 time,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        bytes32 hash = keccak256(abi.encodePacked(redeemer, amount, time));
        if (_isUsed[hash]) {
            revert HashUsed();
        }
        if (
            signerWallet !=
            ECDSA.recover(MessageHashUtils.toEthSignedMessageHash(hash), v, r, s)
        ) {
            revert InvalidSignature();
        }
        _isUsed[hash] = true;
    }
}