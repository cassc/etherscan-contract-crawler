// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IDEXRouter.sol";
import "./token/interfaces/IBEP20.sol";
import "./token/ERC1363/IERC1363.sol";
import "./token/ERC2612/IERC2612.sol";
import "./token/interfaces/IERC20Burnable.sol";
import "./token/interfaces/IERC20TokenRecover.sol";
import "./IFight4HopeDividendTracker.sol";

interface IFight4Hope is IBEP20, IERC1363, IERC2612, IERC20Burnable, IERC20TokenRecover {
    function dexRouters(address router) external view returns (bool);

    // store addresses that are automatic market maker (dex) pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    function automatedMarketMakerPairs(address pair) external view returns (bool);

    function defaultDexRouter() external view returns (IDEXRouter);

    function defaultPair() external view returns (address);

    function dividendToken() external view returns (address);

    function marketingWallet() external view returns (address);

    function liquidityWallet() external view returns (address);

    function dividendTracker() external view returns (IFight4HopeDividendTracker);

    function transfersEnabled() external view returns (bool);

    // Supply and amounts
    function swapTokensAtAmount() external view returns (uint256);

    function maxWalletToken() external view returns (uint256);

    // fees (from a total of 10000)
    function buyFeesCollected() external view returns (uint256);

    function buyDividendFee() external view returns (uint256);

    function buyLiquidityFee() external view returns (uint256);

    function buyMarketingFee() external view returns (uint256);

    function buyTotalFees() external view returns (uint256);

    function sellFeesCollected() external view returns (uint256);

    function sellDividendFee() external view returns (uint256);

    function sellLiquidityFee() external view returns (uint256);

    function sellMarketingFee() external view returns (uint256);

    function sellTotalFees() external view returns (uint256);

    function gasForProcessing() external view returns (uint256);

    // white listed adresses (excluded from fees and dividends)
    // these addresses can also make transfers before presale is over
    function whitelistedAddresses(address account) external view returns (bool);

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateDefaultDexRouter(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event FixedSaleBuy(
        address indexed account,
        uint256 indexed amount,
        bool indexed earlyParticipant,
        uint256 numberOfBuyers
    );

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    event SendDividends(uint256 tokensSwapped, uint256 amount);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    function initializeDividendTracker(IFight4HopeDividendTracker _dividendTracker) external;

    function setWhitelistAddress(address _whitelistAddress, bool whitelisted) external;

    function updateDividendTracker(address newAddress) external;

    function addNewRouter(address _router, bool makeDefault) external;

    function excludeFromFees(address account, bool excluded) external;

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external;

    function setAutomatedMarketMakerPair(address pair, bool value) external;

    function updateMinTokenBalance(uint256 minTokens) external;

    function updateMarketingWallet(address newVault1) external;

    function updateLiquidityWallet(address newLiquidityWallet) external;

    function updateGasForProcessing(uint256 newValue) external;

    function updateClaimWait(uint256 claimWait) external;

    function getClaimWait() external view returns (uint256);

    function getTotalDividendsDistributed() external view returns (uint256);

    function isExcludedFromFees(address account) external view returns (bool);

    function withdrawableDividendOf(address account) external view returns (uint256);

    function dividendTokenBalanceOf(address account) external view returns (uint256);

    function getAccountDividendsInfo(address account)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getAccountDividendsInfoAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function processDividendTracker(uint256 gas) external;

    function claim() external;

    function getLastProcessedIndex() external view returns (uint256);

    function getNumberOfDividendTokenHolders() external view returns (uint256);

    /**
     * Enable or disable transfers, used before presale and on critical problems in or with the token contract
     */
    function setTransfersEnabled(bool enabled) external;

    function updateBuyFees(
        uint256 _dividendFee,
        uint256 _liquidityFee,
        uint256 _marketingFee
    ) external;

    function updateSellFees(
        uint256 _dividendFee,
        uint256 _liquidityFee,
        uint256 _marketingFee
    ) external;

    function updateSwapTokensAtAmount(uint256 _swapTokensAtAmount) external;
}