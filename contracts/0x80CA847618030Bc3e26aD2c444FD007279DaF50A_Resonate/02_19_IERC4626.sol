// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC4626 is IERC20 {


    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Deposit(address indexed caller, address indexed owner, uint256 amountUnderlying, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 amountUnderlying,
        uint256 shares
    );

    /// Transactional Functions

    function deposit(uint amountUnderlying, address receiver) external returns (uint shares);

    function mint(uint shares, address receiver) external returns (uint amountUnderlying);

    function withdraw(uint amountUnderlying, address receiver, address owner) external returns (uint shares);

    function redeem(uint shares, address receiver, address owner) external returns (uint amountUnderlying);


    /// View Functions

    function asset() external view returns (address assetTokenAddress);

    // Total assets held within
    function totalAssets() external view returns (uint totalManagedAssets);

    function convertToShares(uint amountUnderlying) external view returns (uint shares);

    function convertToAssets(uint shares) external view returns (uint amountUnderlying);

    function maxDeposit(address receiver) external view returns (uint maxAssets);

    function previewDeposit(uint amountUnderlying) external view returns (uint shares);

    function maxMint(address receiver) external view returns (uint maxShares);

    function previewMint(uint shares) external view returns (uint amountUnderlying);

    function maxWithdraw(address owner) external view returns (uint maxAssets);

    function previewWithdraw(uint amountUnderlying) external view returns (uint shares);

    function maxRedeem(address owner) external view returns (uint maxShares);

    function previewRedeem(uint shares) external view returns (uint amountUnderlying);

    /// IERC20 View Methods

    /**
     * @dev Returns the amount of shares in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of shares owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of shares that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Returns the name of the vault shares.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the vault shares.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the vault shares.
     */
    function decimals() external view returns (uint8);

    
}