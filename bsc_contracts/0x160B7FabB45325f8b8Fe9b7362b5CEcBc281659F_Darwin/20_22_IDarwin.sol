pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

interface IDarwin {

    /// @notice Accumulatively log sold tokens
    struct TokenSellLog {
        uint40 lastSale;
        uint216 amount;
    }

    event ExcludedFromReflection(address account, bool isExcluded);
    event ExcludedFromSellLimit(address account, bool isExcluded);

    // PUBLIC
    function distributeRewards(uint256 amount) external;
    function bulkTransfer(address[] calldata recipients, uint256[] calldata amounts) external;

    // PRESALE
    function pause() external;
    function unPause() external;
    function setLive() external;

    // COMMUNITY
    // function upgradeTo(address newImplementation) external; RESTRICTED
    // function upgradeToAndCall(address newImplementation, bytes memory data) external payable; RESTRICTED
    function setMinter(address user_, bool canMint_) external; // RESTRICTED
    function setReceiveRewards(address account, bool shouldReceive) external; // RESTRICTED
    function setHoldingLimitWhitelist(address account, bool whitelisted) external; // RESTRICTED
    function setSellLimitWhitelist(address account, bool whitelisted) external; // RESTRICTED
    function registerPair(address pairAddress) external; // RESTRICTED
    function communityUnPause() external;

    // FACTORY
    function registerDarwinSwapPair(address _pair) external;

    // SECURITY
    function emergencyPause() external;
    function emergencyUnPause() external;

    // MAINTENANCE
    function setDarwinSwapFactory(address _darwinSwapFactory) external;
    function setPauseWhitelist(address _addr, bool value) external;
    function setPrivateSaleAddress(address _addr) external;

    // VIEW
    function isExcludedFromHoldingLimit(address account) external view returns (bool);
    function isExcludedFromSellLimit(address account) external view returns (bool);
    function isPaused() external view returns (bool);
    function maxTokenHoldingSize() external view returns(uint256);
    function maxTokenSellSize() external view returns(uint256);

    /// TransferFrom amount is greater than allowance
    error InsufficientAllowance();
    /// Only the DarwinCommunity can call this function
    error OnlyDarwinCommunity();

    /// Input cannot be the zero address
    error ZeroAddress();
    /// Amount cannot be 0
    error ZeroAmount();
    /// Arrays must be the same length
    error InvalidArrayLengths();

    /// Holding limit exceeded
    error HoldingLimitExceeded();
    /// Sell limit exceeded
    error SellLimitExceeded();
    /// Paused
    error Paused();
    error AccountAlreadyExcluded();
    error AccountNotExcluded();

    /// Max supply reached, cannot mint more Darwin
    error MaxSupplyReached();
}