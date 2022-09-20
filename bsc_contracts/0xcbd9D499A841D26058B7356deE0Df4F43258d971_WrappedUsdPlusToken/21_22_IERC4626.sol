// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface IERC4626 {

    /**
     * @dev `caller` has exchanged `assets` for `shares`, and transferred those `shares` to `owner`.
     */
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev `caller` has exchanged `shares`, owned by `owner`, for `assets`, and transferred those `assets` to
     * `receiver`.
     */
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Total amount of the underlying asset that is “managed” by Vault
     **/
    function totalAssets() external view returns (uint256);

    /**
     * @dev The amount of shares that the Vault would exchange for the amount of assets provided,
     * in an ideal scenario where all the conditions are met.
     */
    function convertToShares(uint256 assets) external view returns (uint256);

    /**
     * @dev The amount of assets that the Vault would exchange for the amount of shares provided,
     * in an ideal scenario where all the conditions are met.
     */
    function convertToAssets(uint256 shares) external view returns (uint256);

    /**
     * @dev Maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     */
    function maxDeposit(address receiver) external view returns (uint256);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block,
     * given current on-chain conditions.
     */
    function previewDeposit(uint256 assets) external view returns (uint256);

    /**
     * @dev Mints `shares` Vault shares to `receiver` by depositing exactly `amount` of underlying tokens.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256);

    /**
     * @dev Maximum amount of shares that can be minted from the Vault for the receiver, through a mint call.
     */
    function maxMint(address receiver) external view returns (uint256);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block,
     * given current on-chain conditions.
     */
    function previewMint(uint256 shares) external view returns (uint256);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     */
    function mint(uint256 shares, address receiver) external returns (uint256);

    /**
     * @dev Maximum amount of the underlying asset that can be withdrawn from the owner balance in the Vault,
     * through a withdraw call.
     */
    function maxWithdraw(address owner) external view returns (uint256);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);

    /**
     * @dev Maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     */
    function maxRedeem(address owner) external view returns (uint256);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     */
    function previewRedeem(uint256 shares) external view returns (uint256);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);

}