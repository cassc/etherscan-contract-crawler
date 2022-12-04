// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/UpgradeableBase.sol";
import "./IRECurveZapper.sol";
import "./Library/CheapSafeERC20.sol";
import "./Base/REUSDMinterBase.sol";
import "./Library/CheapSafeCurve.sol";

using CheapSafeERC20 for IERC20;
using CheapSafeERC20 for ICurveStableSwap;

contract RECurveZapper is REUSDMinterBase, UpgradeableBase(1), IRECurveZapper
{
    /*
        addWrapper(unwrappedToken, supportedButWrappedToken, wrapSig, unwrapSig);
    */
    bool public constant isRECurveZapper = true;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurveStableSwap public immutable pool;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurvePool public immutable basePool;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 public immutable basePoolToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable poolCoin0;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable poolCoin1;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolCoin0;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolCoin1;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolCoin2;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolCoin3;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurveGauge public immutable gauge;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable basePoolCoinCount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IRECustodian _custodian, ICurveGauge _gauge, ICurvePool _basePool, IREUSD _reusd, IREStablecoins _stablecoins)
        REUSDMinterBase(_custodian, _reusd, _stablecoins)
    {
        assert(_reusd.isREUSD() && _stablecoins.isREStablecoins());
        
        basePool = _basePool;
        gauge = _gauge;
        pool = gauge.lp_token();
        poolCoin0 = pool.coins(0); 
        poolCoin1 = pool.coins(1);
        basePoolToken = address(poolCoin0) == address(_reusd) ? poolCoin1 : poolCoin0;

        assert(address(poolCoin0) == address(_reusd) || address(poolCoin1) == address(_reusd));
        try pool.coins(5) returns (IERC20Full) { assert(false); } catch {}

        basePoolCoin0 = _basePool.coins(0);
        basePoolCoin1 = _basePool.coins(1);
        uint256 count = 2;
        try _basePool.coins(2) returns (IERC20Full coin2)
        {
            basePoolCoin2 = coin2;
            count = 3;
            try _basePool.coins(3) returns (IERC20Full coin3)
            {
                basePoolCoin3 = coin3;
                count = 4;
            }
            catch {}
        }
        catch {}
        basePoolCoinCount = count;

        assert(basePoolCoin0 != _reusd && basePoolCoin1 != _reusd && basePoolCoin2 != _reusd && basePoolCoin3 != _reusd);
    }

    function initialize()
        public
        virtual
    {
        poolCoin0.safeApprove(address(pool), type(uint256).max);
        poolCoin1.safeApprove(address(pool), type(uint256).max);
        basePoolCoin0.safeApprove(address(basePool), type(uint256).max);
        basePoolCoin1.safeApprove(address(basePool), type(uint256).max);
        if (address(basePoolCoin2) != address(0)) { basePoolCoin2.safeApprove(address(basePool), type(uint256).max); }
        if (address(basePoolCoin3) != address(0)) { basePoolCoin3.safeApprove(address(basePool), type(uint256).max); }
        basePoolToken.safeApprove(address(basePool), type(uint256).max);
        pool.safeApprove(address(gauge), type(uint256).max);
    }
    
    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IRECurveZapper(newImplementation).isRECurveZapper());
    }

    function isBasePoolToken(IERC20 token) 
        private
        view
        returns (bool)
    {
        return address(token) != address(0) &&
            (
                token == basePoolCoin0 ||
                token == basePoolCoin1 ||
                token == basePoolCoin2 ||
                token == basePoolCoin3
            );
    }

    function addBasePoolLiquidity(IERC20 token, uint256 amount)
        private
        returns (uint256)
    {
        uint256 amount0 = token == basePoolCoin0 ? amount : 0;
        uint256 amount1 = token == basePoolCoin1 ? amount : 0;
        if (basePoolCoinCount == 2)
        {
            return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amount0, amount1], 0);
        }
        uint256 amount2 = token == basePoolCoin2 ? amount : 0;
        if (basePoolCoinCount == 3)
        {
            return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amount0, amount1, amount2], 0);
        }
        uint256 amount3 = token == basePoolCoin3 ? amount : 0;
        return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amount0, amount1, amount2, amount3], 0);
    }

    function addBasePoolLiquidity(uint256[] memory amounts)
        private
        returns (uint256)
    {
        if (basePoolCoinCount == 2)
        {
            return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amounts[0], amounts[1]], 0);
        }
        if (basePoolCoinCount == 3)
        {
            return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amounts[0], amounts[1], amounts[2]], 0);
        }
        return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amounts[0], amounts[1], amounts[2], amounts[3]], 0);
    }

    function zap(IERC20 token, uint256 tokenAmount, bool mintREUSD)
        public
    {
        if (tokenAmount == 0) { revert ZeroAmount(); }

        if (mintREUSD && token != REUSD) 
        {
            tokenAmount = getREUSDAmount(token, tokenAmount);
            if (tokenAmount == 0) { revert ZeroAmount(); }
            mintREUSDCore(msg.sender, token, address(this), tokenAmount);
            token = REUSD;
        }
        else 
        {
            token.safeTransferFrom(msg.sender, address(this), tokenAmount);
        }
        
        if (isBasePoolToken(token)) 
        {
            tokenAmount = addBasePoolLiquidity(token, tokenAmount);
            if (tokenAmount == 0) { revert ZeroAmount(); }
            token = address(poolCoin0) == address(REUSD) ? poolCoin1 : poolCoin0;
        }
        if (token == poolCoin0 || token == poolCoin1) 
        {
            tokenAmount = CheapSafeCurve.safeAddLiquidity(address(pool), pool, [
                token == poolCoin0 ? tokenAmount : 0,
                token == poolCoin1 ? tokenAmount : 0
                ], 0);
            if (tokenAmount == 0) { revert ZeroAmount(); }
            token = pool;
        }
        else if (token != pool) { revert UnsupportedToken(); }

        gauge.deposit(tokenAmount, msg.sender, true);
    }

    function zapPermit(IERC20Full token, uint256 tokenAmount, bool mintREUSD, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        token.permit(msg.sender, address(this), permitAmount, deadline, v, r, s);
        zap(token, tokenAmount, mintREUSD);
    }

    function unzap(IERC20 token, uint256 tokenAmount)
        public
    {
        if (tokenAmount == 0) { revert ZeroAmount(); }       

        gauge.transferFrom(msg.sender, address(this), tokenAmount);
        gauge.claim_rewards(msg.sender);
        gauge.withdraw(tokenAmount, false);
        
        if (token == pool)
        {
            token.safeTransfer(msg.sender, tokenAmount);
            return;
        }
        if (token == poolCoin0 || token == poolCoin1)
        {
            CheapSafeCurve.safeRemoveLiquidityOneCoin(address(pool), token, token == poolCoin0 ? 0 : 1, tokenAmount, 1, msg.sender);
            return;
        }
        
        if (!isBasePoolToken(token)) { revert UnsupportedToken(); }

        tokenAmount = CheapSafeCurve.safeRemoveLiquidityOneCoin(address(pool), basePoolToken, poolCoin0 == basePoolToken ? 0 : 1, tokenAmount, 1, address(this));
        
        CheapSafeCurve.safeRemoveLiquidityOneCoin(
            address(basePool), 
            token, 
            token == basePoolCoin0 ? 0 : token == basePoolCoin1 ? 1 : token == basePoolCoin2 ? 2 : 3,
            tokenAmount, 
            1, 
            msg.sender);
    }

    function multiZap(TokenAmount[] calldata mints, TokenAmount[] calldata tokenAmounts)
        public
    {
        /*
            0-3 = basePoolCoin[0-3]
            4 = reusd
            5 = base pool token
            6 = reusd + base pool token
        */
        uint256[] memory amounts = new uint256[](7);        
        for (uint256 x = mints.length; x > 0;)
        {
            IERC20 token = mints[--x].token;
            uint256 amount = getREUSDAmount(token, mints[x].amount);
            mintREUSDCore(msg.sender, token, address(this), amount);
            amounts[4] += amount;
        }
        for (uint256 x = tokenAmounts.length; x > 0;)
        {
            IERC20 token = tokenAmounts[--x].token;
            uint256 amount = tokenAmounts[x].amount;
            if (token == basePoolCoin0)
            {
                amounts[0] += amount;
            }
            else if (token == basePoolCoin1)
            {
                amounts[1] += amount;
            }
            else if (token == basePoolCoin2)
            {
                amounts[2] += amount;
            }
            else if (token == basePoolCoin3)
            {
                amounts[3] += amount;
            }
            else if (token == REUSD)
            {
                amounts[4] += amount;
            }
            else if (token == basePoolToken)
            {
                amounts[5] += amount;
            }
            else if (token == pool)
            {
                amounts[6] += amount;
            }
            else 
            {
                revert UnsupportedToken();
            }
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
        if (amounts[0] > 0 || amounts[1] > 0 || amounts[2] > 0 || amounts[3] > 0)
        {
            amounts[5] += addBasePoolLiquidity(amounts);
        }
        if (amounts[4] > 0 || amounts[5] > 0)
        {
            amounts[6] += CheapSafeCurve.safeAddLiquidity(address(pool), pool, poolCoin0 == REUSD ? [amounts[4], amounts[5]] : [amounts[5], amounts[4]], 0);            
        }
        if (amounts[6] == 0)
        {
            revert ZeroAmount();
        }

        gauge.deposit(amounts[6], msg.sender, true);
    }

    function multiZapPermit(TokenAmount[] calldata mints, TokenAmount[] calldata tokenAmounts, PermitData[] calldata permits)
        public
    {
        for (uint256 x = permits.length; x > 0;)
        {
            --x;
            permits[x].token.permit(msg.sender, address(this), permits[x].permitAmount, permits[x].deadline, permits[x].v, permits[x].r, permits[x].s);
        }
        multiZap(mints, tokenAmounts);
    }
}