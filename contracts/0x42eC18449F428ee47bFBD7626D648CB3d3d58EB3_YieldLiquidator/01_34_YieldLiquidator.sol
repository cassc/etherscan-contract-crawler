// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {YieldMath} from "@yield-protocol/yieldspace-tv/src/YieldMath.sol";
import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";
import {IOracle} from "@yield-protocol/vault-v2/contracts/interfaces/IOracle.sol";
import {IFYToken} from "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
import {ILadle} from "@yield-protocol/vault-v2/contracts/interfaces/ILadle.sol";
import {ICauldron} from "@yield-protocol/vault-v2/contracts/interfaces/ICauldron.sol";
import {IWitch} from "@yield-protocol/vault-v2/contracts/interfaces/IWitch.sol";
import {DataTypes} from "@yield-protocol/vault-v2/contracts/interfaces/DataTypes.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./dependencies/Balancer.sol";
import "./dependencies/IPoolView.sol";
import "./dependencies/IWETH9.sol";
import "./handlers/ICollateralHandler.sol";

contract YieldLiquidator is AccessControl, IFlashLoanRecipient {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    event CallFailed(bytes12 indexed vaultId, bytes returnData);

    struct FlashLoanCallback {
        IWitch witch;
        bytes12 vaultId;
        address joinOrPool;
        address tokenIn;
        address tokenOut;
        IFYToken fyToken;
        bool beforeMaturity;
        uint128 art;
        uint128 ink;
        bytes uniswapCalldata;
        bytes6 ilkId;
        uint128 fyTokenLiquidity;
        ILadle ladle;
    }

    struct LiquidateParams {
        IWitch witch;
        ILadle ladle;
        ICauldron cauldron;
        bytes12 vaultId;
        bytes uniswapCalldata;
        DataTypes.Vault vault;
        DataTypes.Series series;
        uint128 maxArtIn;
        uint128 minInkOut;
    }

    struct LiquidationQuote {
        address liquidatorCutAsset;
        uint256 liquidatorCut;
        uint256 liquidatorCutETH;
        address effectiveLiquidatorCutAsset;
        uint256 effectiveLiquidatorCut;
        address auctioneerCutAsset;
        uint256 auctioneerCut;
        address artAsset;
        uint256 artIn;
        uint256 artInETH;
        uint128 fyTokenLiquidity;
        uint256 fyTokenInCost;
    }

    struct Call {
        bytes12 vaultId;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    bytes32 public constant BOT = keccak256("BOT");

    address public immutable uniswap;
    IFlashLoaner public immutable balancer;
    address payable public immutable treasury;
    IWETH9 public immutable weth;
    bytes6 public immutable ethAssetId;

    mapping(bytes6 => ICollateralHandler) public collateralHandlers;

    constructor(address _uniswap, IFlashLoaner _balancer, address payable _treasury, IWETH9 _weth, bytes6 _ethAssetId) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        uniswap = _uniswap;
        balancer = _balancer;
        treasury = _treasury;
        weth = _weth;
        ethAssetId = _ethAssetId;
    }

    function setCollateralHandler(bytes6 assetId, ICollateralHandler ch) external onlyRole(DEFAULT_ADMIN_ROLE) {
        collateralHandlers[assetId] = ch;
    }

    function setCollateralHandler(bytes6[] calldata assetIds, ICollateralHandler ch)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 length = assetIds.length;
        for (uint256 i = 0; i < length; i++) {
            collateralHandlers[assetIds[i]] = ch;
        }
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(Call[] calldata calls) external payable returns (Result[] memory returnData) {
        returnData = new Result[](calls.length);
        for (uint256 i; i < calls.length;) {
            (returnData[i].success, returnData[i].returnData) = address(this).delegatecall(calls[i].callData);
            if (!returnData[i].success) {
                emit CallFailed(calls[i].vaultId, returnData[i].returnData);
            }
            unchecked {
                ++i;
            }
        }
    }

    function startAuction(IWitch witch, bytes12 vaultId)
        external
        returns (DataTypes.Auction memory, DataTypes.Vault memory, DataTypes.Series memory)
    {
        return witch.auction(vaultId, treasury);
    }

    function calcPayout(IWitch witch, bytes12 vaultId, address to, uint256 maxArtIn)
        external
        view
        returns (LiquidationQuote memory quote)
    {
        ILadle ladle = witch.ladle();
        ICauldron cauldron = witch.cauldron();
        (quote.liquidatorCut, quote.auctioneerCut, quote.artIn) = witch.calcPayout(vaultId, to, maxArtIn);
        DataTypes.Vault memory vault = cauldron.vaults(vaultId);
        DataTypes.Series memory series = cauldron.series(vault.seriesId);

        quote.liquidatorCutAsset = quote.auctioneerCutAsset = cauldron.assets(vault.ilkId);
        quote.artAsset = cauldron.assets(series.baseId);

        ICollateralHandler collateralHandler = collateralHandlers[vault.ilkId];
        if (address(collateralHandler) != address(0)) {
            (quote.effectiveLiquidatorCutAsset, quote.effectiveLiquidatorCut) =
                collateralHandler.quote(quote.liquidatorCut, quote.liquidatorCutAsset, vault.ilkId, ladle);
        } else {
            quote.effectiveLiquidatorCutAsset = quote.liquidatorCutAsset;
            quote.effectiveLiquidatorCut = quote.liquidatorCut;
        }

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < series.maturity) {
            IPool pool = IPool(ladle.pools(vault.seriesId));
            quote.fyTokenLiquidity = maxFYTokenOut(pool, series.maturity);
            quote.fyTokenInCost = _buyFYTokenPreview(pool, quote.fyTokenLiquidity, uint128(quote.artIn));
        } else {
            quote.fyTokenInCost = quote.artIn;
        }

        if (address(weth) == quote.effectiveLiquidatorCutAsset) {
            quote.liquidatorCutETH = quote.effectiveLiquidatorCut;
        }
        if (address(weth) == quote.artAsset) {
            quote.artInETH = quote.artIn;
        }
        if (quote.liquidatorCutETH == 0) {
            quote.liquidatorCutETH = _toETH(cauldron, vault.ilkId, quote.liquidatorCut);
        }
        if (quote.artInETH == 0) {
            quote.artInETH = _toETH(cauldron, series.baseId, quote.artIn);
        }
    }

    function _toETH(ICauldron cauldron, bytes6 assetId, uint256 amount) internal view returns (uint256 amountETH) {
        IOracle oracle = cauldron.spotOracles(assetId, ethAssetId).oracle;
        if (address(oracle) == address(0)) {
            oracle = cauldron.spotOracles(ethAssetId, assetId).oracle;
        }
        if (address(oracle) != address(0)) {
            (amountETH,) = oracle.peek(assetId, ethAssetId, amount);
        }
    }

    /// @dev Some pools were deployed without the liquidity functions, so it's not safe to use them in mainnet before 2023
    function maxFYTokenOut(IPool pool, uint32 maturity) public view returns (uint128 fyTokenOut) {
        uint96 scaleFactor = pool.scaleFactor();
        (uint104 sharesCached, uint104 fyTokenCached,,) = pool.getCache();
        uint128 unscaledFyTokenOut = YieldMath.maxFYTokenOut(
            sharesCached * scaleFactor,
            fyTokenCached * scaleFactor,
            // solhint-disable-next-line not-rely-on-time
            maturity - uint32(block.timestamp),
            pool.ts(),
            pool.g1(),
            pool.getC(),
            pool.mu()
        );

        fyTokenOut = unscaledFyTokenOut < 1e12 ? 0 : unscaledFyTokenOut / scaleFactor;
    }

    function liquidate(
        IWitch witch,
        bytes12 vaultId,
        bytes calldata uniswapCalldata,
        uint128 fyTokenLiquidity,
        uint128 maxArtIn,
        uint128 minInkOut
    ) external onlyRole(BOT) {
        LiquidateParams memory params;
        params.witch = witch;
        params.cauldron = witch.cauldron();
        params.ladle = witch.ladle();

        DataTypes.Auction memory auction = witch.auctions(vaultId);
        if (auction.start == 0) {
            (auction, params.vault, params.series) = witch.auction(vaultId, address(this));
        } else {
            params.vault = params.cauldron.vaults(vaultId);
            params.series = params.cauldron.series(params.vault.seriesId);
        }

        params.vaultId = vaultId;
        params.uniswapCalldata = uniswapCalldata;
        params.maxArtIn = maxArtIn;
        params.minInkOut = minInkOut;

        // solhint-disable-next-line not-rely-on-time
        if (fyTokenLiquidity > 0 && block.timestamp < params.series.maturity) {
            _liquidateWithFYTokens(params, fyTokenLiquidity);
        } else {
            _liquidateAtFaceValue(params);
        }
    }

    function _buyFYTokenPreview(IPool pool, uint128 fyTokenLiquidity, uint128 fyTokenOut)
        internal
        view
        returns (uint128 baseIn)
    {
        // buyFYTokenPreview blows on 0
        if (fyTokenLiquidity == 0) {
            return fyTokenOut;
        }

        baseIn = fyTokenLiquidity >= fyTokenOut
            ? pool.buyFYTokenPreview(fyTokenOut)
            : fyTokenOut - fyTokenLiquidity + pool.buyFYTokenPreview(fyTokenLiquidity);

        // Math is not exact anymore with the PoolEuler, so we need to transfer a bit more to the pool
        if (baseIn > 0) {
            baseIn++;
        }
    }

    function _liquidateWithFYTokens(LiquidateParams memory params, uint128 fyTokenLiquidity) internal {
        IPool pool = IPool(params.ladle.pools(params.vault.seriesId));
        uint256 amount = _buyFYTokenPreview(pool, fyTokenLiquidity, params.maxArtIn);
        _flashLoan(params, amount, address(pool), true, fyTokenLiquidity);
    }

    function _liquidateAtFaceValue(LiquidateParams memory params) internal {
        _flashLoan(
            params,
            // TODO check what happens with rounding,
            // maybe always offer a few more wei to force the witch to do the same math
            params.cauldron.debtToBase(params.vault.seriesId, params.maxArtIn),
            address(params.ladle.joins(params.series.baseId)),
            false,
            0
        );
    }

    function _flashLoan(
        LiquidateParams memory params,
        uint256 amount,
        address joinOrPool,
        bool beforeMaturity,
        uint128 fyTokenLiquidity
    ) internal {
        address[] memory tokens = new address[](1);
        tokens[0] = params.cauldron.assets(params.series.baseId);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        FlashLoanCallback memory callback = FlashLoanCallback({
            witch: params.witch,
            vaultId: params.vaultId,
            joinOrPool: joinOrPool,
            tokenIn: params.cauldron.assets(params.vault.ilkId),
            tokenOut: tokens[0],
            fyToken: params.series.fyToken,
            art: params.maxArtIn,
            ink: params.minInkOut,
            beforeMaturity: beforeMaturity,
            uniswapCalldata: params.uniswapCalldata,
            ilkId: params.vault.ilkId,
            fyTokenLiquidity: fyTokenLiquidity,
            ladle: params.ladle
        });

        balancer.flashLoan(this, tokens, amounts, abi.encode(callback));
    }

    function receiveFlashLoan(
        address[] memory,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        require(msg.sender == address(balancer), "not balancer");

        FlashLoanCallback memory callback = abi.decode(userData, (FlashLoanCallback));

        uint256 inkOut;
        if (callback.beforeMaturity) {
            inkOut = _completeLiquidationBeforeMaturity(amounts[0], callback);
        } else {
            inkOut = _completeLiquidationAfterMaturity(amounts[0], callback);
        }

        _repayDebtAndCollectProfit(amounts[0] + feeAmounts[0], inkOut, callback);
    }

    function _completeLiquidationBeforeMaturity(uint256 debt, FlashLoanCallback memory callback)
        internal
        returns (uint256 inkOut)
    {
        if (callback.fyTokenLiquidity >= callback.art) {
            // Send the debt amount to the pool
            IERC20(callback.tokenOut).safeTransfer(callback.joinOrPool, debt);
            // Sell the underlying for FYTokens
            IPool(callback.joinOrPool).buyFYToken(address(callback.fyToken), callback.art, uint128(debt));
        } else {
            // Math is not exact anymore with the PoolEuler, so we need to transfer a bit more to the pool
            uint128 toBuy = IPool(callback.joinOrPool).buyFYTokenPreview(callback.fyTokenLiquidity)+1;
            uint256 toMint = debt - toBuy;
            // Send only the necessary amount to the pool
            IERC20(callback.tokenOut).safeTransfer(callback.joinOrPool, toBuy);
            // Send the remainder to the join
            IERC20(callback.tokenOut).safeTransfer(address(callback.fyToken.join()), toMint);

            // Sell some of the underlying for FYTokens
            IPool(callback.joinOrPool).buyFYToken(
                address(callback.fyToken), callback.fyTokenLiquidity, callback.fyTokenLiquidity
            );

            // Mint FYTokens 1:1
            callback.fyToken.mintWithUnderlying(address(callback.fyToken), toMint);
        }

        // Pay debt and get some ink
        (inkOut,,) = callback.witch.payFYToken(callback.vaultId, address(this), callback.ink, callback.art);
    }

    function _completeLiquidationAfterMaturity(uint256 debt, FlashLoanCallback memory callback)
        internal
        returns (uint256 inkOut)
    {
        // Send the debt amount to the join
        IERC20(callback.tokenOut).safeTransfer(callback.joinOrPool, debt);
        // Pay debt and get some ink
        (inkOut,,) = callback.witch.payBase(callback.vaultId, address(this), callback.ink, uint128(debt));
    }

    function _repayDebtAndCollectProfit(
        uint256 debtToRepay,
        uint256 collateralReceived,
        FlashLoanCallback memory callback
    ) internal {
        address collateralHandler = address(collateralHandlers[callback.ilkId]);
        if (collateralHandler != address(0)) {
            bytes memory returnData = collateralHandler.functionDelegateCall(
                abi.encodeWithSelector(
                    ICollateralHandler.handle.selector,
                    collateralReceived,
                    callback.tokenIn,
                    callback.ilkId,
                    callback.ladle
                )
            );

            (callback.tokenIn, collateralReceived) = abi.decode(returnData, (address, uint256));
        }

        if (callback.tokenIn != callback.tokenOut) {
            // Allow Uniswap to take money from this contract
            IERC20(callback.tokenIn).safeIncreaseAllowance(address(uniswap), collateralReceived);

            // Swap the purchased ink for art (amount is defined by the caller)
            uniswap.functionCall(callback.uniswapCalldata);
        }

        // Payback the flash loan
        IERC20(callback.tokenOut).safeTransfer(msg.sender, debtToRepay);

        _transferProfits(callback.tokenIn);
        _transferProfits(callback.tokenOut);
    }

    function _transferProfits(address token) internal returns (uint256 balance) {
        balance = IERC20(token).balanceOf(address(this));

        if (balance > 0) {
            if (token == address(weth)) {
                weth.withdraw(balance);
                treasury.sendValue(balance);
            } else {
                IERC20(token).safeTransfer(treasury, balance);
            }
        }
    }

    /// @dev allows to retrieve any token that for any reason is stuck in the contract
    function transferProfits(address token) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        return _transferProfits(token);
    }

    // @dev WETH unwrapping and some swaps deal with real ETH
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}