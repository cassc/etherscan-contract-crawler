// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/IDerivative.sol";

/**
 @notice - Storage abstraction for SafEth contract
 @dev - Upgradeability Rules:
        DO NOT change existing variable names or types
        DO NOT change order of variables
        DO NOT remove any variables
        ONLY add new variables at the end
        Constant values CAN be modified on upgrade
*/
contract SafEthStorage {
    event ChangeMinAmount(
        uint256 indexed oldMinAmount,
        uint256 indexed newMinAmount
    );
    event ChangeMaxAmount(
        uint256 indexed oldMaxAmount,
        uint256 indexed newMaxAmount
    );
    event MaxPreMintAmount(uint256 indexed amount);
    event StakingPaused(bool indexed paused);
    event UnstakingPaused(bool indexed paused);
    event SetMaxSlippage(uint256 indexed index, uint256 indexed slippage);
    event Staked(
        address indexed recipient,
        uint256 indexed ethIn,
        uint256 totalStakeValue,
        uint256 price,
        bool indexed usedPremint
    );
    event Unstaked(
        address indexed recipient,
        uint256 indexed ethOut,
        uint256 indexed safEthIn,
        uint256 price
    );
    event PreMint(
        uint256 indexed ethIn,
        uint256 indexed mintAmount,
        uint256 newFloorPrice
    );
    event WeightChange(
        uint256 indexed index,
        uint256 indexed weight,
        uint256 indexed totalWeight
    );
    event DerivativeAdded(
        address indexed contractAddress,
        uint256 indexed weight,
        uint256 indexed index
    );
    event Rebalanced();
    event DerivativeDisabled(uint256 indexed index);
    event DerivativeEnabled(uint256 indexed index);
    event SingleDerivativeThresholdUpdated(uint256 indexed newThreshold);

    error BlacklistedAddress();
    error StakingPausedError();
    error UnstakingPausedError();
    error PremintTooLow();
    error AmountTooLow();
    error AmountTooHigh();
    error TotalWeightZero();
    error MintedAmountTooLow();
    error InsufficientBalance();
    error FailedToSend();
    error ReceivedZeroAmount();
    error IndexOutOfBounds();
    error SameDerivative();
    error NotEnabled();
    error AlreadyEnabled();
    error InvalidDerivative();
    error AlreadySet();
    error NoEnabledDerivatives();

    struct Derivatives {
        IDerivative derivative;
        uint256 weight;
        bool enabled;
    }

    bool public pauseStaking; // true if staking is paused
    bool public pauseUnstaking; // true if unstaking is pause
    uint256 public derivativeCount; // amount of derivatives added to contract
    uint256 public totalWeight; // total weight of all derivatives (used to calculate percentage of derivative)
    uint256 public minAmount; // minimum amount to stake
    uint256 public maxAmount; // maximum amount to stake
    mapping(uint256 => Derivatives) public derivatives; // derivatives in the system
    uint256 public floorPrice; // lowest price to sell preminted SafEth
    uint256 public maxPreMintAmount; // maximum amount of ETH that can be used for preminted safETH
    uint256 public preMintedSupply; // supply of preminted safEth that is available
    uint256 public ethToClaim; // amount of ETH that was used to claim preminted safEth
    mapping(address => bool) public blacklistedRecipients; // addresses not allowed to send to unless from whitelisted address
    mapping(address => bool) public whitelistedSenders; // addresses allowed to send to blacklisted addresses
    uint256 public singleDerivativeThreshold; // threshold for when to buy single derivative vs standard weighting
    uint256[] public enabledDerivatives; // array of indexes of enabled derivatives in the system
    uint256 public enabledDerivativeCount; // amount of enabled derivatives in the system
    bool public hasInitializedV2; // initializeV2 has been called

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[40] private __gap;
}