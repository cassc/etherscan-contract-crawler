// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ReservoirOracleUnderwriter} from "../ReservoirOracleUnderwriter.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {INFTEDA} from "../NFTEDA/extensions/NFTEDAStarterIncentive.sol";

interface IPaprController {
    /// @notice collateral for a vault
    struct Collateral {
        /// @dev address of the collateral, cast to ERC721
        ERC721 addr;
        /// @dev tokenId of the collateral
        uint256 id;
    }

    /// @notice vault information for a vault
    struct VaultInfo {
        /// @dev number of collateral tokens in the vault
        uint16 count;
        /// @dev number of auctions on going for this vault
        uint16 auctionCount;
        /// @dev start time of last auction the vault underwent, 0 if no auction has been started
        uint40 latestAuctionStartTime;
        /// @dev debt of the vault, expressed in papr token units
        uint184 debt;
    }

    /// @notice parameters describing a swap
    /// @dev increaseDebtAndSell has the input token as papr and output token as the underlying
    /// @dev buyAndReduceDebt has the input token as the underlying and output token as papr
    struct SwapParams {
        /// @dev amount of input token to swap
        uint256 amount;
        /// @dev minimum amount of output token to be received
        uint256 minOut;
        /// @dev sqrt price limit for the swap
        uint160 sqrtPriceLimitX96;
        /// @dev optional address to receive swap fees
        address swapFeeTo;
        /// @dev optional swap fee in bips
        uint256 swapFeeBips;
        /// @dev timestamp after which the swap should not be executed
        uint256 deadline;
    }

    /// @notice parameters to be encoded in safeTransferFrom collateral addition
    struct OnERC721ReceivedArgs {
        /// @dev address to send proceeds to if minting debt or swapping
        address proceedsTo;
        /// @dev debt is ignored in favor of `swapParams.amount` of minOut > 0
        uint256 debt;
        /// @dev optional swapParams
        SwapParams swapParams;
        /// @dev oracle information associated with collateral being sent
        ReservoirOracleUnderwriter.OracleInfo oracleInfo;
    }

    /// @notice parameters to change what collateral addresses can be used for a vault
    struct CollateralAllowedConfig {
        ERC721 collateral;
        bool allowed;
    }

    /// @notice emitted when an address increases the debt balance of their vault
    /// @param account address increasing their debt
    /// @param collateralAddress address of the collateral token
    /// @param amount amount of debt added
    /// @dev vaults are uniquely identified by the address of the vault owner and the address of the collateral token used in the vault
    event IncreaseDebt(address indexed account, ERC721 indexed collateralAddress, uint256 amount);

    /// @notice emitted when a user adds collateral to their vault
    /// @param account address adding collateral
    /// @param collateralAddress contract address of the ERC721 collateral added
    /// @param tokenId token id of the ERC721 collateral added
    event AddCollateral(address indexed account, ERC721 indexed collateralAddress, uint256 indexed tokenId);

    /// @notice emitted when a user removes collateral from their vault
    /// @param account address removing collateral
    /// @param collateralAddress contract address of the ERC721 collateral removed
    /// @param tokenId token id of the ERC721 collateral removed
    event RemoveCollateral(address indexed account, ERC721 indexed collateralAddress, uint256 indexed tokenId);

    /// @notice emitted when a user reduces the debt balance of their vault
    /// @param account address reducing their debt
    /// @param collateralAddress address of the collateral token
    /// @param amount amount of debt removed
    event ReduceDebt(address indexed account, ERC721 indexed collateralAddress, uint256 amount);

    /// @notice emitted when the owner sets whether a token address is allowed to serve as collateral for a vault
    /// @param collateral address of the collateral token
    /// @param isAllowed whether the collateral is allowed
    event AllowCollateral(ERC721 indexed collateral, bool isAllowed);

    /// @notice emitted when the owner sets a new funding period for the controller
    /// @param newPeriod new funding period that was set, in seconds
    event UpdateFundingPeriod(uint256 newPeriod);

    /// @notice emitted when the owner sets a new Uniswap V3 pool for the controller
    /// @param newPool address of the new Uniswap V3 pool that was set
    event UpdatePool(address indexed newPool);

    /// @notice emitted when the owner sets whether or not liquidations for the controller are locked
    /// @param locked whether or not the owner set liquidations to be locked or not
    event UpdateLiquidationsLocked(bool locked);

    /// @param vaultDebt how much debt the vault has
    /// @param maxDebt the max debt the vault is allowed to have
    error ExceedsMaxDebt(uint256 vaultDebt, uint256 maxDebt);

    error InvalidCollateral();

    error MinAuctionSpacing();

    error NotLiquidatable();

    error InvalidCollateralAccountPair();

    error AccountHasNoDebt();

    error OnlyCollateralOwner();

    error DebtAmountExceedsUint184();

    error CollateralAddressesDoNotMatch();

    error LiquidationsLocked();

    /// @notice adds collateral to msg.senders vault for collateral.addr
    /// @dev use safeTransferFrom to save gas if only sending one NFT
    /// @param collateral collateral to add
    function addCollateral(IPaprController.Collateral[] calldata collateral) external;

    /// @notice removes collateral from msg.senders vault
    /// @dev all collateral must be from same contract address
    /// @dev oracleInfo price must be type LOWER
    /// @param sendTo address to send the collateral to when removed
    /// @param collateralArr array of IPaprController.Collateral to be removed
    /// @param oracleInfo oracle information for the collateral being removed
    function removeCollateral(
        address sendTo,
        IPaprController.Collateral[] calldata collateralArr,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external;

    /// @notice increases debt balance of the vault uniquely identified by msg.sender and the collateral address
    /// @dev oracleInfo price must be type LOWER
    /// @param mintTo address to mint the debt to
    /// @param asset address of the collateral token used to mint the debt
    /// @param amount amount of debt to mint
    /// @param oracleInfo oracle information for the collateral being used to mint debt
    function increaseDebt(
        address mintTo,
        ERC721 asset,
        uint256 amount,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external;

    /// @notice removes and burns debt from the vault uniquely identified by account and the collateral address
    /// @param account address reducing their debt
    /// @param asset address of the collateral token the user would like to remove debt from
    /// @param amount amount of debt to remove
    function reduceDebt(address account, ERC721 asset, uint256 amount) external;

    /// @notice mints debt and swaps the debt for the controller's underlying token on Uniswap
    /// @dev oracleInfo price must be type LOWER
    /// @param proceedsTo address to send the proceeds to
    /// @param collateralAsset address of the collateral token used to mint the debt
    /// @param params parameters for the swap
    /// @param oracleInfo oracle information for the collateral being used to mint debt
    /// @return amount amount of underlying token received by the user
    function increaseDebtAndSell(
        address proceedsTo,
        ERC721 collateralAsset,
        IPaprController.SwapParams calldata params,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external returns (uint256);

    /// @notice removes debt from a vault and burns it by swapping the controller's underlying token for Papr tokens using the Uniswap V3 pool
    /// @param account address reducing their debt
    /// @param collateralAsset address of the collateral token the user would like to remove debt from
    /// @param params parameters for the swap
    /// @return amount amount of debt received from the swap and burned
    function buyAndReduceDebt(address account, ERC721 collateralAsset, IPaprController.SwapParams calldata params)
        external
        returns (uint256);

    /// @notice purchases a liquidation auction with the controller's papr token
    /// @dev oracleInfo price must be type TWAP
    /// @param auction auction to purchase
    /// @param maxPrice maximum price to pay for the auction
    /// @param sendTo address to send the collateral to if auction is won
    function purchaseLiquidationAuctionNFT(
        INFTEDA.Auction calldata auction,
        uint256 maxPrice,
        address sendTo,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external;

    /// @notice starts a liquidation auction for a vault if it is liquidatable
    /// @dev oracleInfo price must be type TWAP
    /// @param account address of the user who's vault to liquidate
    /// @param collateral collateral to liquidate
    /// @param oracleInfo oracle information for the collateral being liquidated
    /// @return auction auction that was started
    function startLiquidationAuction(
        address account,
        IPaprController.Collateral calldata collateral,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external returns (INFTEDA.Auction memory auction);

    /// @notice sets the Uniswap V3 pool that is used to determine mark
    /// @dev owner function
    /// @param _pool address of the Uniswap V3 pool
    function setPool(address _pool) external;

    /// @notice sets the funding period for interest payments
    /// @param _fundingPeriod new funding period in seconds
    function setFundingPeriod(uint256 _fundingPeriod) external;

    /// @notice sets value of liquidationsLocked
    /// @dev owner function for use in emergencies
    /// @param locked new value for liquidationsLocked
    function setLiquidationsLocked(bool locked) external;

    /// @notice sets whether a collateral is allowed to be used to mint debt
    /// @dev owner function
    /// @param collateralConfigs configuration settings indicating whether a collateral is allowed or not
    function setAllowedCollateral(IPaprController.CollateralAllowedConfig[] calldata collateralConfigs) external;

    /// @notice returns who owns a collateral token in a vault
    /// @param collateral address of the collateral
    /// @param tokenId tokenId of the collateral
    function collateralOwner(ERC721 collateral, uint256 tokenId) external view returns (address);

    /// @notice returns whether a token address is allowed to serve as collateral for a vault
    /// @param collateral address of the collateral token
    function isAllowed(ERC721 collateral) external view returns (bool);

    /// @notice if liquidations are currently locked, meaning startLiquidationAuciton will revert
    /// @dev for use in case of emergencies
    /// @return liquidationsLocked whether liquidations are locked
    function liquidationsLocked() external view returns (bool);

    /// @notice boolean indicating whether token0 in pool is the underlying token
    function token0IsUnderlying() external view returns (bool);

    /// @notice maximum LTV a vault can have, expressed as a decimal scaled by 1e18
    function maxLTV() external view returns (uint256);

    /// @notice minimum time that must pass before consecutive collateral is liquidated from the same vault
    function liquidationAuctionMinSpacing() external view returns (uint256);

    /// @notice fee paid by the vault owner when their vault is liquidated if there was excess debt credited to their vault, in bips
    function liquidationPenaltyBips() external view returns (uint256);

    /// @notice returns the maximum debt that can be minted for a given collateral value
    /// @param totalCollateraValue total value of the collateral
    /// @return maxDebt maximum debt that can be minted, expressed in terms of the papr token
    function maxDebt(uint256 totalCollateraValue) external view returns (uint256);

    /// @notice returns information about a vault
    /// @param account address of the vault owner
    /// @param asset address of the collateral token associated with the vault
    /// @return vaultInfo VaultInfo struct representing information about a vault
    function vaultInfo(address account, ERC721 asset) external view returns (IPaprController.VaultInfo memory);
}