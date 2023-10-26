// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "./IScaledBalanceToken.sol";
import "./IKyokoPoolAddressesProvider.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IKToken is IERC20Upgradeable, IScaledBalanceToken {
    /**
     * @dev Emitted when an kToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated lending pool
     * @param reserveId The id of the reserves
     * @param treasury The address of the treasury
     * @param kTokenDecimals the decimals of the underlying
     * @param kTokenName the name of the kToken
     * @param kTokenSymbol the symbol of the kToken
     **/
    event Initialize(
        address indexed underlyingAsset,
        address indexed pool,
        uint256 indexed reserveId,
        address treasury,
        uint8 kTokenDecimals,
        string kTokenName,
        string kTokenSymbol
    );

    /**
     * @dev Initializes the kToken
     * @param pool The address of the lending pool where this kToken will be used
     * @param reserveId The id of the reserves
     * @param treasury The address of the Kyoko treasury, receiving the fees on this kToken
     * @param underlyingAsset The address of the underlying asset of this kToken (E.g. WETH for kWETH)
     * @param kTokenDecimals The decimals of the kToken, same as the underlying asset's
     * @param kTokenName The name of the kToken
     * @param kTokenSymbol The symbol of the kToken
     */
    function initialize(
        IKyokoPoolAddressesProvider pool,
        uint256 reserveId,
        address treasury,
        address underlyingAsset,
        uint8 kTokenDecimals,
        string calldata kTokenName,
        string calldata kTokenSymbol
    ) external;

    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     * @param index The new liquidity index of the reserve
     **/
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Mints `amount` kTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted after kTokens are burned
     * @param from The owner of the kTokens, getting them burned
     * @param target The address that will receive the underlying
     * @param value The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    event Burn(
        address indexed from,
        address indexed target,
        uint256 value,
        uint256 index
    );

    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The amount being transferred
     * @param index The new liquidity index of the reserve
     **/
    event BalanceTransfer(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 index
    );

    /**
     * @dev Burns kTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param user The owner of the kTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @dev Burns kTokens from `user`
     * @param user The owner of the kTokens, getting them burned
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(address user, uint256 amount, uint256 index) external;

    /**
     * @dev Mints kTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @dev Transfers kTokens in the event of a borrow being liquidated, in case the liquidators reclaims the kToken
     * @param from The address getting liquidated, current owner of the kTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external;

    /**
     * @dev Transfers the underlying asset to `target`. Used by the KyokoPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the underlying
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(
        address user,
        uint256 amount
    ) external returns (uint256);

    function transferUnderlyingNFTTo(
        address nft,
        address target,
        uint256 nftId
    ) external returns (uint256);

    /**
     * @dev Invoked to execute actions on the kToken side after a repayment.
     * @param user The user executing the repayment
     * @param amount The amount getting repaid
     **/
    function handleRepayment(address user, uint256 amount) external;

    /**
     * @dev Returns the address of the underlying asset of this kToken (E.g. WETH for aWETH)
     **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}