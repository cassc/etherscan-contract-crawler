// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../libs/venus/VenusComptroller.sol";  
import "../../../libs/atlantis/ExponentialNoError.sol"; 
 
import "../../interfaces/ILendingAdapter.sol";
import "../../../common/Errors.sol";

contract VenusAdapter is ILendingAdapter, ExponentialNoError {

    VenusComptroller public immutable comptroller;
    address public immutable rewardToken;

    address constant NATIVE_TOKEN_ADDRESS = address(0x1E1e1E1E1e1e1e1e1e1E1E1E1E1e1e1E1e1e1E1E);
    bytes32 constant NATIVE_VTOKEN_NAME = keccak256("vBNB");

    constructor(VenusComptroller account, address _rewardToken) {
        comptroller = account;
        rewardToken = _rewardToken;
    }

    function initialize() external {
        // empty by purpose
    }

    function getMarket(address asset) external view override returns(address platformToken) { 
        VToken[] memory tokens = comptroller.getAllMarkets();
        for (uint i = 0; i < tokens.length; i++) {
            VToken aToken = tokens[i];
            if (_underlying(aToken) == asset)
                return address(aToken);
        }
        return address(0);
    }

    function getMarkets() external view override returns(MarketInfo[] memory markets) {
        VToken[] memory tokens = comptroller.getAllMarkets();
        markets = new MarketInfo[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            VToken vToken = tokens[i];
            markets[i].platformToken = address(vToken);
            markets[i].asset = _underlying(vToken);
            markets[i].collateralFactor = collateralFactor(address(vToken));
        }
    }

    function rewardTokens() external view override returns(address[] memory result) {
        result = new address[](1);
        result[0] = rewardToken;
    }

    function underlying(address platformToken) public view override returns(address asset) {
        VToken vToken = VToken(platformToken);
        return _underlying(vToken);
    }

    function _underlying(VToken vToken) internal view returns(address asset) {
        if (compareStrings(vToken.symbol(), "vBNB"))  
            return NATIVE_TOKEN_ADDRESS;
        return vToken.underlying();
    }

    function amountUnderlying(address platformToken, uint amount) public view override returns(uint) {
        VToken vToken = VToken(platformToken);
        Exp memory exchangeRate = Exp({mantissa: vToken.exchangeRateStored()});
        return mul_ScalarTruncate(exchangeRate, amount);
    }

    function priceUnderlying(address platformToken) public view override returns(uint) {
        return comptroller.oracle().getUnderlyingPrice(VToken(platformToken));
    }

    function isCollateral(address account, address platformToken) external view override returns(bool) {
        return comptroller.checkMembership(account, platformToken); 
    }

    function collateralFactor(address platformToken) public view override returns(uint factor) {
        bool listed;
        (listed, factor, ) = comptroller.markets(platformToken);
        if (!listed)
            factor = 0;
    }

    function enableCollateral(address platformToken) external override {
        address[] memory tokens = new address[](1);
        tokens[0] = platformToken;
        comptroller.enterMarkets(tokens);
    }

    function accountInfo(address account) external view override
        returns(uint totalDeposit,
                uint totalCollateral,
                uint totalBorrow, 
                uint healthFactor) {
        (totalDeposit, totalCollateral, totalBorrow, healthFactor) = 
            _accountInfoInternal(account);
    }

    function accountInfo(address account, address platformToken) external view override 
        returns(uint depositToken, uint borrowToken) 
    {
        VToken vToken = VToken(platformToken);
        uint oErr;
        (oErr, depositToken, borrowToken, ) = vToken.getAccountSnapshot(account);
        if (oErr != 0) {
            depositToken = 0;
            borrowToken = 0;
        }
    }

    function rewardAccrued(address account) external view override returns(uint) {
        return comptroller.venusAccrued(account);
    }

    function deposit(address platformToken, uint amount) external override {
        VToken token = VToken(platformToken);
        IERC20 asset = IERC20(_underlying(token));
        if (address(asset) == NATIVE_TOKEN_ADDRESS) {
            // TODO handle native asset
        } else {
            if (asset.allowance(address(this), address(token)) < amount)
                asset.approve(address(token), type(uint).max);
            token.mint(amount);
        }
    }

    function withdraw(address platformToken, uint amount) external override {
        VToken token = VToken(platformToken);
        token.redeemUnderlying(amount);
    }

    function borrow(address platformToken, uint amount) external override {
        VToken token = VToken(platformToken);
        IERC20 asset = IERC20(underlying(platformToken));
        if (address(asset) != NATIVE_TOKEN_ADDRESS &&
            asset.allowance(address(this), platformToken) < amount) {
            asset.approve(platformToken, type(uint256).max);
        }
        token.borrow(amount);
    }

    function repay(address platformToken, uint amount) external override {
        VToken token = VToken(platformToken);
        token.repayBorrow(amount);
    }

    function harvestReward(address account) external override {  
        comptroller.claimVenus(account);
    }

    function getBorrowableToken(address account, address platformToken, uint expectedHealthFactor) 
        external view override returns(uint)  
    {
        require(expectedHealthFactor >= 1 ether, Errors.ILA_INVALID_EXPECTED_HEALTH_FACTOR);

        (,uint totalCollateral, uint totalBorrow, uint healthFactor) = _accountInfoInternal(account);

        if (expectedHealthFactor >= healthFactor && healthFactor > 0)
            return 0;

        VToken aToken = VToken(platformToken);

        uint extraBorrowAmount = totalCollateral * 1 ether / expectedHealthFactor - totalBorrow;
        
        uint oraclePriceMantissa = comptroller.oracle().getUnderlyingPrice(aToken);        
        Exp memory oraclePrice = Exp({mantissa: oraclePriceMantissa});

        uint borrowToken = div_(extraBorrowAmount, oraclePrice);
        return borrowToken;
    }

    function getWithdrawableToken(address account, address platformToken, uint expectedHealthFactor) 
        external view override returns(uint) 
    {
        require(expectedHealthFactor >= 1 ether, Errors.ILA_INVALID_EXPECTED_HEALTH_FACTOR);

        (,uint totalCollateral, uint totalBorrow, uint healthFactor) = _accountInfoInternal(account);

        if (expectedHealthFactor >= healthFactor && healthFactor > 0)
            return 0;

        VToken vToken = VToken(platformToken);
        uint withdrawableAmount = totalCollateral - totalBorrow * expectedHealthFactor / 1 ether;

        uint maxWithdrawAmount = amountUnderlying(platformToken, vToken.balanceOf(account));

        uint oraclePriceMantissa = comptroller.oracle().getUnderlyingPrice(vToken);        
        Exp memory oraclePrice = Exp({mantissa: oraclePriceMantissa});

        uint withdrawToken = div_(withdrawableAmount, oraclePrice);

        return withdrawToken > maxWithdrawAmount ? maxWithdrawAmount : withdrawToken;
    }

    struct AccountLiquidityLocalVars {
        uint sumDeposit;
        uint sumCollateral;
        uint sumBorrow;
        uint aTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    function _accountInfoInternal(address account) internal view 
        returns(uint totalDeposit, uint totalCollateral, uint totalBorrow, uint healthFactor) 
    {
        AccountLiquidityLocalVars memory vars;
        uint oErr;
        VToken[] memory vTokens = comptroller.getAssetsIn(account);
        for (uint i = 0; i < vTokens.length; i++) {
            VToken vToken = vTokens[i];

            (bool isListed, uint collateralFactorMantissa, ) = comptroller.markets(address(vToken));
            if (!isListed)
                continue;

            (oErr, vars.aTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) =
                vToken.getAccountSnapshot(account);
            require(oErr == 0, "VenusAdapter: error querying account snapshot");

            vars.collateralFactor = Exp({mantissa: collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});
            vars.aTokenBalance = mul_ScalarTruncate(vars.exchangeRate, vars.aTokenBalance);

            // Get the normalized price of the vToken
            vars.oraclePriceMantissa = comptroller.oracle().getUnderlyingPrice(vToken);
            if (vars.oraclePriceMantissa == 0) {
                continue;
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = mul_(vars.collateralFactor, vars.oraclePrice);

            // sumDeposit += oraclePrice * aTokenBalance
            vars.sumDeposit = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.aTokenBalance, vars.sumDeposit);

            // sumCollateral += tokensToDenom * aTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.aTokenBalance, vars.sumCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrow = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrow);
       }

       return (vars.sumDeposit, 
                vars.sumCollateral, 
                vars.sumBorrow, 
                vars.sumBorrow == 0 ? 0 :  vars.sumCollateral * 1 ether / vars.sumBorrow );
    }

    function accountDetailInfo(address account) external view override returns(AccountDetailInfo[] memory result) {
        uint oErr;
        uint collateralFactorMantissa;
        uint vTokenBalance;
        AccountLiquidityLocalVars memory vars;
        VToken[] memory vTokens = comptroller.getAssetsIn(account);
        result = new AccountDetailInfo[](vTokens.length);

        for(uint i = 0; i < vTokens.length; i++) {
            VToken vToken = vTokens[i];

            result[i].platformToken = address(vToken);
            result[i].asset = _underlying(vToken);

            (oErr, vTokenBalance, result[i].borrow, vars.exchangeRateMantissa) =
                vToken.getAccountSnapshot(account);
            
            (result[i].listed, collateralFactorMantissa,) = comptroller.markets(address(vToken));

            if (!result[i].listed)
                continue;

            vars.collateralFactor = Exp({mantissa: collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the vToken
            vars.oraclePriceMantissa = comptroller.oracle().getUnderlyingPrice(vToken);
            
            result[i].deposit = mul_ScalarTruncate(vars.exchangeRate, vTokenBalance);
            result[i].exchangeRateMantissa = vars.exchangeRateMantissa; 
            result[i].oraclePriceMantissa = vars.oraclePriceMantissa;


            if (vars.oraclePriceMantissa == 0) {
                continue;
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = mul_(vars.collateralFactor, vars.oraclePrice);

            // sumDeposit += oraclePrice * aTokenBalance
            result[i].depositValue = mul_ScalarTruncate(vars.oraclePrice, result[i].deposit);

            // sumCollateral += tokensToDenom * aTokenBalance
            result[i].collateral = mul_ScalarTruncate(vars.tokensToDenom, result[i].deposit);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            result[i].borrowValue = mul_ScalarTruncate(vars.oraclePrice, result[i].borrow);
        }
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}