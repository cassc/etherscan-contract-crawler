// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../token/IERC20.sol';
import '../token/IDToken.sol';
import '../vault/IVToken.sol';
import '../vault/IVault.sol';
import '../oracle/IOracleManager.sol';
import '../swapper/ISwapper.sol';
import '../symbol/ISymbolManager.sol';
import '../utils/IPrivileger.sol';
import '../utils/IRewardVault.sol';
import './PoolStorage.sol';
import '../utils/NameVersion.sol';
import '../library/SafeMath.sol';
import '../library/SafeERC20.sol';

contract PoolImplementation is PoolStorage, NameVersion {

    event CollectProtocolFee(address indexed collector, uint256 amount);

    event AddMarket(address indexed market);

    event SetRouter(address router, bool isActive);

    event AddLiquidity(
        uint256 indexed lTokenId,
        address indexed underlying,
        uint256 amount,
        int256 newLiquidity
    );

    event RemoveLiquidity(
        uint256 indexed lTokenId,
        address indexed underlying,
        uint256 amount,
        int256 newLiquidity
    );

    event AddMargin(
        uint256 indexed pTokenId,
        address indexed underlying,
        uint256 amount,
        int256 newMargin
    );

    event RemoveMargin(
        uint256 indexed pTokenId,
        address indexed underlying,
        uint256 amount,
        int256 newMargin
    );

    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;

    int256 constant ONE = 1e18;
    uint256 constant UONE = 1e18;
    uint256 constant UMAX = type(uint256).max / UONE;

    address public immutable vaultTemplate;

    address public immutable vaultImplementation;

    address public immutable tokenB0;

    address public immutable tokenWETH;

    address public immutable vTokenB0;

    address public immutable vTokenETH;

    IDToken public immutable lToken;

    IDToken public immutable pToken;

    IOracleManager public immutable oracleManager;

    ISwapper public immutable swapper;

    ISymbolManager public immutable symbolManager;

    IPrivileger public immutable privileger;

    IRewardVault public immutable rewardVault;

    uint8 public immutable decimalsB0;

    uint256 public immutable reserveRatioB0;

    int256 public immutable minRatioB0;

    int256 public immutable poolInitialMarginMultiplier;

    int256 public immutable protocolFeeCollectRatio;

    int256 public immutable minLiquidationReward;

    int256 public immutable maxLiquidationReward;

    int256 public immutable liquidationRewardCutRatio;

    constructor (
        address[13] memory addresses_,
        uint256[7] memory parameters_
    ) NameVersion('PoolImplementation', '3.0.2')
    {
        vaultTemplate = addresses_[0];
        vaultImplementation = addresses_[1];
        tokenB0 = addresses_[2];
        tokenWETH = addresses_[3];
        vTokenB0 = addresses_[4];
        vTokenETH = addresses_[5];
        lToken = IDToken(addresses_[6]);
        pToken = IDToken(addresses_[7]);
        oracleManager = IOracleManager(addresses_[8]);
        swapper = ISwapper(addresses_[9]);
        symbolManager = ISymbolManager(addresses_[10]);
        privileger = IPrivileger(addresses_[11]);
        rewardVault = IRewardVault(addresses_[12]);
        decimalsB0 = IERC20(tokenB0).decimals();

        reserveRatioB0 = parameters_[0];
        minRatioB0 = parameters_[1].utoi();
        poolInitialMarginMultiplier = parameters_[2].utoi();
        protocolFeeCollectRatio = parameters_[3].utoi();
        minLiquidationReward = parameters_[4].utoi();
        maxLiquidationReward = parameters_[5].utoi();
        liquidationRewardCutRatio = parameters_[6].utoi();
    }

    function addMarket(address market) external _onlyAdmin_ {
        // underlying is the underlying token of Venus market
        address underlying = IVToken(market).underlying();
        require(
            IVToken(market).isVToken(),
            'PI: invalid vToken'
        );
        require(
            IVToken(market).comptroller() == IVault(vaultImplementation).comptroller(),
            'PI: wrong comptroller'
        );
        require(
            swapper.isSupportedToken(underlying),
            'PI: no swapper support'
        );
        require(
            markets[underlying] == address(0),
            'PI: replace not allowed'
        );

        markets[underlying] = market;
        approveSwapper(underlying);

        emit AddMarket(market);
    }

    function approveSwapper(address underlying) public _onlyAdmin_ {
        uint256 allowance = IERC20(underlying).allowance(address(this), address(swapper));
        if (allowance != type(uint256).max) {
            if (allowance != 0) {
                IERC20(underlying).safeApprove(address(swapper), 0);
            }
            IERC20(underlying).safeApprove(address(swapper), type(uint256).max);
        }
    }

    function setRouter(address router_, bool isActive) external _onlyAdmin_ {
        isRouter[router_] = isActive;
        emit SetRouter(router_, isActive);
    }

    function collectProtocolFee() external {
        require(protocolFeeCollector != address(0), 'PI: collector not set');
        // rescale protocolFeeAccrued from decimals18 to decimalsB0
        (uint256 amount, uint256 remainder) = protocolFeeAccrued.itou().rescaleDown(18, decimalsB0);
        protocolFeeAccrued = remainder.utoi();
        IERC20(tokenB0).safeTransfer(protocolFeeCollector, amount);
        emit CollectProtocolFee(protocolFeeCollector, amount);
    }

    function claimVenusLp(address account) external {
        uint256 lTokenId = lToken.getTokenIdOf(account);
        if (lTokenId != 0) {
            IVault(lpInfos[lTokenId].vault).claimVenus(account);
        }
    }

    function claimVenusTrader(address account) external {
        uint256 pTokenId = pToken.getTokenIdOf(account);
        if (pTokenId != 0) {
            IVault(tdInfos[pTokenId].vault).claimVenus(account);
        }
    }

    //================================================================================

    // amount in underlying's own decimals
    function addLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external payable _reentryLock_
    {
        _updateOracles(oracleSignatures);
        if (underlying == address(0)) amount = msg.value;

        Data memory data = _initializeDataWithAccount(msg.sender, underlying);
        _getLpInfo(data, true);

        ISymbolManager.SettlementOnAddLiquidity memory s =
        symbolManager.settleSymbolsOnAddLiquidity(data.liquidity + data.lpsPnl);

        int256 undistributedPnl = s.funding - s.deltaTradersPnl;
        if (undistributedPnl != 0) {
            data.lpsPnl += undistributedPnl;
            data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;
        }

        uint256 balanceB0 = IERC20(tokenB0).balanceOf(address(this));
        _settleLp(data);
        _transferIn(data, amount);
        int256 newLiquidity = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;

        if (address(rewardVault) != address(0)) {
            (, uint256 underlyingBalanceB0) = IVault(data.vault).getBalances(vTokenB0);
            int256 newLiquidityB0 = underlyingBalanceB0.utoi() + data.amountB0;
            newLiquidityB0 = newLiquidity >= newLiquidityB0 ? newLiquidityB0 : newLiquidity;
            rewardVault.updateVault(data.liquidity.itou(), data.tokenId, data.lpLiquidity.itou(), balanceB0.rescale(decimalsB0, 18), newLiquidityB0);
        }

        data.liquidity += newLiquidity - data.lpLiquidity;
        data.lpLiquidity = newLiquidity;

        // only check B0 sufficiency when underlying is not B0
        if (underlying != tokenB0) {
            require(
                // rescale tokenB0 balance from decimalsB0 to 18
                IERC20(tokenB0).balanceOf(address(this)).rescale(decimalsB0, 18).utoi() * ONE >= data.liquidity * minRatioB0,
                'PI: insufficient B0'
            );
        }

        liquidity = data.liquidity;
        lpsPnl = data.lpsPnl;
        cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

        LpInfo storage info = lpInfos[data.tokenId];
        info.vault = data.vault;
        info.amountB0 = data.amountB0;
        info.liquidity = data.lpLiquidity;
        info.cumulativePnlPerLiquidity = data.lpCumulativePnlPerLiquidity;

        emit AddLiquidity(data.tokenId, underlying, amount, newLiquidity);
    }

    // amount in underlying's own decimals
    function removeLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external _reentryLock_
    {
        _updateOracles(oracleSignatures);

        Data memory data = _initializeDataWithAccount(msg.sender, underlying);
        _getLpInfo(data, false);

        int256 removedLiquidity;
        (uint256 vTokenBalance, uint256 underlyingBalance) = IVault(data.vault).getBalances(data.market);
        if (underlying == tokenB0) {
            int256 available = underlyingBalance.rescale(decimalsB0, 18).utoi() + data.amountB0; // available in decimals18
            if (available > 0) {
                int256 amountIn18 = amount.rescale(decimalsB0, 18).utoi(); // amount in decimals18
                removedLiquidity = amountIn18.min(available);
            }
        } else if (underlyingBalance > 0) {
            uint256 redeemAmount = amount >= underlyingBalance ?
                                   vTokenBalance :
                                   vTokenBalance * amount / underlyingBalance;
            uint256 bl1 = IVault(data.vault).getVaultLiquidity();
            uint256 bl2 = IVault(data.vault).getHypotheticalVaultLiquidity(data.market, redeemAmount);
            removedLiquidity = (bl1 - bl2).utoi();
        }

        require(data.liquidity + data.lpsPnl > removedLiquidity, 'PI: removedLiquidity > total liquidity');
        ISymbolManager.SettlementOnRemoveLiquidity memory s =
        symbolManager.settleSymbolsOnRemoveLiquidity(data.liquidity + data.lpsPnl, removedLiquidity);
        require(s.removeLiquidityPenalty >= 0, 'PI: negative penalty');

        int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.removeLiquidityPenalty;
        data.lpsPnl += undistributedPnl;
        data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;
        data.amountB0 -= s.removeLiquidityPenalty;

        _settleLp(data);

        uint256 balanceB0 = IERC20(tokenB0).balanceOf(address(this));
        uint256 newVaultLiquidity = _transferOut(data, amount, vTokenBalance, underlyingBalance);
        int256 newLiquidity = newVaultLiquidity.utoi() + data.amountB0;

        if (address(rewardVault) != address(0)) {
            (, uint256 underlyingBalanceB0) = IVault(data.vault).getBalances(vTokenB0);
            int256 newLiquidityB0 = underlyingBalanceB0.utoi() + data.amountB0;
            newLiquidityB0 = newLiquidity >= newLiquidityB0 ? newLiquidityB0 : newLiquidity;
            rewardVault.updateVault(data.liquidity.itou(), data.tokenId, data.lpLiquidity.itou(), balanceB0.rescale(decimalsB0, 18), newLiquidityB0);
        }

        data.liquidity += newLiquidity - data.lpLiquidity;
        data.lpLiquidity = newLiquidity;

        require(
            data.liquidity * ONE >= s.initialMarginRequired * poolInitialMarginMultiplier,
            'PI: pool insufficient liquidity'
        );

        liquidity = data.liquidity;
        lpsPnl = data.lpsPnl;
        cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

        LpInfo storage info = lpInfos[data.tokenId];
        info.amountB0 = data.amountB0;
        info.liquidity = data.lpLiquidity;
        info.cumulativePnlPerLiquidity = data.lpCumulativePnlPerLiquidity;

        emit RemoveLiquidity(data.tokenId, underlying, amount, newLiquidity);
    }

    function addMargin(address account, address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external payable _reentryLock_{
        if (!isRouter[msg.sender]) {
            require(account == msg.sender, "PI: unauthorized call");
        }

         _updateOracles(oracleSignatures);

        if (underlying == address(0)) amount = msg.value;

        Data memory data;
        data.underlying = underlying;
        data.decimalsUnderlying = _getDecimalsUnderlying(underlying); // get underlying's decimals
        data.market = _getMarket(underlying);
        data.account = account;

        _getTdInfo(data, true);
        _transferIn(data, amount);

        int256 newMargin = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;

        TdInfo storage info = tdInfos[data.tokenId];
        info.vault = data.vault;
        info.amountB0 = data.amountB0;


        emit AddMargin(data.tokenId, underlying, amount, newMargin);
    }


    function removeMargin(address account, address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external _reentryLock_ {
        if (!isRouter[msg.sender]) {
            require(account == msg.sender, "PI: unauthorized call");
        }

        _updateOracles(oracleSignatures);

        Data memory data = _initializeDataWithAccount(account, underlying);
        _getTdInfo(data, false);

        ISymbolManager.SettlementOnRemoveMargin memory s =
        symbolManager.settleSymbolsOnRemoveMargin(data.tokenId, data.liquidity + data.lpsPnl);

        int256 undistributedPnl = s.funding - s.deltaTradersPnl;
        data.lpsPnl += undistributedPnl;
        data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;

        data.amountB0 -= s.traderFunding;

        (uint256 vTokenBalance, uint256 underlyingBalance) = IVault(data.vault).getBalances(data.market);
        uint256 newVaultLiquidity = _transferOut(data, amount, vTokenBalance, underlyingBalance);

        require(
            newVaultLiquidity.utoi() + data.amountB0 + s.traderPnl >= s.traderInitialMarginRequired,
            'PI: insufficient margin'
        );

        lpsPnl = data.lpsPnl;
        cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

        tdInfos[data.tokenId].amountB0 = data.amountB0;

        emit RemoveMargin(data.tokenId, underlying, amount, newVaultLiquidity.utoi() + data.amountB0);
    }


    function trade(address account, string memory symbolName, int256 tradeVolume, int256 priceLimit) _reentryLock_ external
    {
        require(isRouter[msg.sender], 'PI: only router');
        bytes32 symbolId = keccak256(abi.encodePacked(symbolName));

        Data memory data = _initializeDataWithAccount(account);
        _getTdInfo(data, false);

        ISymbolManager.SettlementOnTrade memory s =
        symbolManager.settleSymbolsOnTrade(data.tokenId, symbolId, tradeVolume, data.liquidity + data.lpsPnl, priceLimit);

        int256 collect = s.tradeFee * protocolFeeCollectRatio / ONE;
        int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.tradeFee - collect + s.tradeRealizedCost;
        data.lpsPnl += undistributedPnl;
        data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;

        data.amountB0 -= s.traderFunding + s.tradeFee + s.tradeRealizedCost;
        int256 margin = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;

        require(
            (data.liquidity + data.lpsPnl) * ONE >= s.initialMarginRequired * poolInitialMarginMultiplier,
            'PI: pool insufficient liquidity'
        );
        require(
            margin + s.traderPnl >= s.traderInitialMarginRequired,
            'PI: insufficient margin'
        );

        lpsPnl = data.lpsPnl;
        cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;
        protocolFeeAccrued += collect;

        tdInfos[data.tokenId].amountB0 = data.amountB0;

    }

    function liquidate(uint256 pTokenId, OracleSignature[] memory oracleSignatures) external _reentryLock_
    {
        require(
            address(privileger) == address(0) || privileger.isQualifiedLiquidator(msg.sender),
            'PI: unqualified liquidator'
        );

        _updateOracles(oracleSignatures);

        require(
            pToken.exists(pTokenId),
            'PI: nonexistent pTokenId'
        );

        Data memory data = _initializeDataWithAccount(msg.sender);
        data.vault = tdInfos[pTokenId].vault;
        data.amountB0 = tdInfos[pTokenId].amountB0;

        ISymbolManager.SettlementOnLiquidate memory s =
        symbolManager.settleSymbolsOnLiquidate(pTokenId, data.liquidity + data.lpsPnl);

        int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.traderRealizedCost;

        data.amountB0 -= s.traderFunding;
        int256 margin = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;

        require(
            s.traderMaintenanceMarginRequired > 0,
            'PI: no position'
        );
        require(
            margin + s.traderPnl < s.traderMaintenanceMarginRequired,
            'PI: cannot liquidate'
        );

        data.amountB0 -= s.traderRealizedCost;

        IVault v = IVault(data.vault);
        address[] memory inMarkets = v.getMarketsIn();

        for (uint256 i = 0; i < inMarkets.length; i++) {
            address market = inMarkets[i];
            uint256 balance = IVToken(market).balanceOf(data.vault);
            if (balance > 0) {
                address underlying = _getUnderlying(market);
                v.redeem(market, balance);
                balance = v.transferAll(underlying, address(this));
                if (underlying == address(0)) {
                    (uint256 resultB0, ) = swapper.swapExactETHForB0{value: balance}();
                    data.amountB0 += resultB0.rescale(decimalsB0, 18).utoi(); // rescale resultB0 from decimalsB0 to 18
                } else if (underlying == tokenB0) {
                    data.amountB0 += balance.rescale(decimalsB0, 18).utoi(); // rescale balance from decimalsB0 to 18
                } else {
                    (uint256 resultB0, ) = swapper.swapExactBXForB0(underlying, balance);
                    data.amountB0 += resultB0.rescale(decimalsB0, 18).utoi(); // rescale resultB0 from decimalsB0 to 18
                }
            }
        }

        int256 reward;
        if (data.amountB0 <= minLiquidationReward) {
            reward = minLiquidationReward;
        } else {
            reward = (data.amountB0 - minLiquidationReward) * liquidationRewardCutRatio / ONE + minLiquidationReward;
            reward = reward.min(maxLiquidationReward);
        }
        reward = reward.itou().rescale(18, decimalsB0).rescale(decimalsB0, 18).utoi(); // make reward no remainder when convert to decimalsB0

        undistributedPnl += data.amountB0 - reward;
        data.lpsPnl += undistributedPnl;
        data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;

        _transfer(tokenB0, msg.sender, reward.itou().rescale(18, decimalsB0)); // when transfer, use decimalsB0

        lpsPnl = data.lpsPnl;
        cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

        tdInfos[pTokenId].amountB0 = 0;
    }

    //================================================================================

    struct OracleSignature {
        bytes32 oracleSymbolId;
        uint256 timestamp;
        uint256 value;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function _updateOracles(OracleSignature[] memory oracleSignatures) internal {
        for (uint256 i = 0; i < oracleSignatures.length; i++) {
            OracleSignature memory signature = oracleSignatures[i];
            oracleManager.updateValue(
                signature.oracleSymbolId,
                signature.timestamp,
                signature.value,
                signature.v,
                signature.r,
                signature.s
            );
        }
    }

    struct Data {
        int256 liquidity;
        int256 lpsPnl;
        int256 cumulativePnlPerLiquidity;

        address underlying;
        address market;
        uint256 decimalsUnderlying;

        address account;
        uint256 tokenId;
        address vault;
        int256 amountB0;
        int256 lpLiquidity;
        int256 lpCumulativePnlPerLiquidity;
    }

//    function _initializeData() internal view returns (Data memory data) {
//        data.liquidity = liquidity;
//        data.lpsPnl = lpsPnl;
//        data.cumulativePnlPerLiquidity = cumulativePnlPerLiquidity;
//        data.account = msg.sender;
//    }

    function _initializeDataWithAccount(address account) internal view returns (Data memory data) {
        data.liquidity = liquidity;
        data.lpsPnl = lpsPnl;
        data.cumulativePnlPerLiquidity = cumulativePnlPerLiquidity;
        data.account = account;
    }

    function _initializeDataWithAccount(address account, address underlying) internal view returns (Data memory data) {
        data = _initializeDataWithAccount(account);
        data.underlying = underlying;
        data.decimalsUnderlying = _getDecimalsUnderlying(underlying); // get underlying's decimals
        data.market = _getMarket(underlying);
    }

//    function _initializeData(address underlying) internal view returns (Data memory data) {
//        data = _initializeData();
//        data.underlying = underlying;
//        data.decimalsUnderlying = _getDecimalsUnderlying(underlying); // get underlying's decimals
//        data.market = _getMarket(underlying);
//    }

    function _getDecimalsUnderlying(address underlying) internal view returns (uint8) {
        if (underlying == address(0)) {
            return 18;
        } else if (underlying == tokenB0) {
            return decimalsB0;
        } else {
            return IERC20(underlying).decimals();
        }
    }

    function _getMarket(address underlying) internal view returns (address market) {
        if (underlying == address(0)) {
            market = vTokenETH;
        } else if (underlying == tokenB0) {
            market = vTokenB0;
        } else {
            market = markets[underlying];
            require(
                market != address(0),
                'PI: unsupported market'
            );
        }
    }

    function _getUnderlying(address market) internal view returns (address underlying) {
        if (market == vTokenB0) {
            underlying = tokenB0;
        } else if (market == vTokenETH) {
            underlying = address(0);
        } else {
            underlying = IVToken(market).underlying();
        }
    }

    function _getLpInfo(Data memory data, bool createOnDemand) internal {
        data.tokenId = lToken.getTokenIdOf(data.account);
        if (data.tokenId == 0) {
            require(createOnDemand, 'PI: not LP');
            data.tokenId = lToken.mint(data.account);
            data.vault = _clone(vaultTemplate);
        } else {
            LpInfo storage info = lpInfos[data.tokenId];
            data.vault = info.vault;
            data.amountB0 = info.amountB0;
            data.lpLiquidity = info.liquidity;
            data.lpCumulativePnlPerLiquidity = info.cumulativePnlPerLiquidity;
        }
    }

    function _getTdInfo(Data memory data, bool createOnDemand) internal {
        data.tokenId = pToken.getTokenIdOf(data.account);
        if (data.tokenId == 0) {
            require(createOnDemand, 'PI: not trader');
            data.tokenId = pToken.mint(data.account);
            data.vault = _clone(vaultTemplate);
        } else {
            TdInfo storage info = tdInfos[data.tokenId];
            data.vault = info.vault;
            data.amountB0 = info.amountB0;
        }
    }

    function _clone(address source) internal returns (address target) {
        bytes20 sourceBytes = bytes20(source);
        assembly {
            let c := mload(0x40)
            mstore(c, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(c, 0x14), sourceBytes)
            mstore(add(c, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            target := create(0, c, 0x37)
        }
    }

    function _settleLp(Data memory data) internal pure {
        int256 diff;
        unchecked { diff = data.cumulativePnlPerLiquidity - data.lpCumulativePnlPerLiquidity; }
        int256 pnl = diff * data.lpLiquidity / ONE;

        data.amountB0 += pnl;
        data.lpsPnl -= pnl;
        data.lpCumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;
    }

    // amount in underlying's own decimals
    function _transfer(address underlying, address to, uint256 amount) internal {
        if (underlying == address(0)) {
            (bool success, ) = payable(to).call{value: amount}('');
            require(success, 'PI: send ETH fail');
        } else {
            IERC20(underlying).safeTransfer(to, amount);
        }
    }

    // amount in underlying's own decimals
    function _transferIn(Data memory data, uint256 amount) internal {
        IVault v = IVault(data.vault);

        if (!v.isInMarket(data.market)) {
            v.enterMarket(data.market);
        }

        if (data.underlying == address(0)) { // ETH
            v.mint{value: amount}();
        }
        else if (data.underlying == tokenB0) {
            uint256 reserve = amount * reserveRatioB0 / UONE;
            uint256 deposit = amount - reserve;

            IERC20(data.underlying).safeTransferFrom(data.account, address(this), amount);
            IERC20(data.underlying).safeTransfer(data.vault, deposit);

            v.mint(data.market, deposit);
            data.amountB0 += reserve.rescale(data.decimalsUnderlying, 18).utoi(); // amountB0 is in decimals18
        }
        else {
            IERC20(data.underlying).safeTransferFrom(data.account, data.vault, amount);
            v.mint(data.market, amount);
        }
    }

    // amount/vTokenBalance/underlyingBalance are all in their own decimals
    function _transferOut(Data memory data, uint256 amount, uint256 vTokenBalance, uint256 underlyingBalance)
    internal returns (uint256 newVaultLiquidity)
    {
        IVault v = IVault(data.vault);

        if (underlyingBalance > 0) {
            if (amount >= underlyingBalance) {
                v.redeem(data.market, vTokenBalance);
            } else {
                v.redeemUnderlying(data.market, amount);
            }

            underlyingBalance = data.underlying == address(0) ?
                                data.vault.balance :
                                IERC20(data.underlying).balanceOf(data.vault);

            if (data.amountB0 < 0) {
                (uint256 owe, uint256 excessive) = (-data.amountB0).itou().rescaleUp(18, decimalsB0); // amountB0 is in decimals18
                v.transfer(data.underlying, address(this), underlyingBalance);

                if (data.underlying == address(0)) {
                    (uint256 resultB0, uint256 resultBX) = swapper.swapETHForExactB0{value: underlyingBalance}(owe);
                    data.amountB0 += resultB0.rescale(decimalsB0, 18).utoi(); // rescale resultB0 from decimalsB0 to 18
                    underlyingBalance -= resultBX;
                }
                else if (data.underlying == tokenB0) {
                    if (underlyingBalance >= owe) {
                        data.amountB0 = excessive.utoi(); // excessive is already in decimals18
                        underlyingBalance -= owe;
                    } else {
                        data.amountB0 += underlyingBalance.rescale(decimalsB0, 18).utoi(); // rescale underlyingBalance to decimals18
                        underlyingBalance = 0;
                    }
                }
                else {
                    (uint256 resultB0, uint256 resultBX) = swapper.swapBXForExactB0(
                        data.underlying, owe, underlyingBalance
                    );
                    data.amountB0 += resultB0.rescale(decimalsB0, 18).utoi(); // resultB0 to decimals18
                    underlyingBalance -= resultBX;
                }

                if (underlyingBalance > 0) {
                    _transfer(data.underlying, data.account, underlyingBalance);
                }
            }
            else {
                v.transfer(data.underlying, data.account, underlyingBalance);
            }
        }

        newVaultLiquidity = v.getVaultLiquidity();

        if (newVaultLiquidity == 0 && amount >= UMAX && data.amountB0 > 0) {
            (uint256 own, uint256 remainder) = data.amountB0.itou().rescaleDown(18, decimalsB0); // rescale amountB0 to decimalsB0
            uint256 resultBX;

            if (data.underlying == address(0)) {
                (, resultBX) = swapper.swapExactB0ForETH(own);
            } else if (data.underlying == tokenB0) {
                resultBX = own;
            } else {
                (, resultBX) = swapper.swapExactB0ForBX(data.underlying, own);
            }

            _transfer(data.underlying, data.account, resultBX);
            data.amountB0 = remainder.utoi(); // assign the remainder back to amountB0, which is not swappable
        }

        if (data.underlying == tokenB0 && data.amountB0 > 0 && amount > underlyingBalance) {
            uint256 own = data.amountB0.itou().rescale(18, decimalsB0); // rescale amountB0 to decimalsB0
            uint256 resultBX = own.min(amount - underlyingBalance);
            _transfer(tokenB0, data.account, resultBX);
            data.amountB0 -= resultBX.rescale(decimalsB0, 18).utoi();
        }
    }

}