// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IREUSD.sol";
import "./Base/UpgradeableBase.sol";
import "./IRECustodian.sol";
import "./Library/CheapSafeCurve.sol";
import "./IRECurveBlargitrage.sol";

/**
    An arbitrage contract

    If a curve pool is made of REUSD + 3CRV, for example...

    If there's more 3CRV than REUSD, then calling "balance" will mint REUSD
    and exchange it for 3CRV to bring the pool back into balance.

    More specifically, it actually extracts one of the underlying tokens
    like USDC from 3CRV after doing the balancing.  USDC goes to custodian.

    However, if there's more REUSD than 3CRV, there's nothing this
    contract can do.  We could manually add funds from the custodian if
    it seems appropriate.

    A call to "balance" can be the last step in zap/unzap in the 
    RECurveZapper contract.
 */
contract RECurveBlargitrage is UpgradeableBase(2), IRECurveBlargitrage
{
    uint256 public totalAmount;
    
    //------------------ end of storage

    uint256 constant MinImbalance = 1000 ether;
    bool public constant isRECurveBlargitrage = true;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IREUSD immutable public REUSD;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurveStableSwap immutable public pool;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurvePool immutable public basePool;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 immutable reusdIndex;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 immutable basePoolIndex;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRECustodian immutable public custodian;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable public desiredToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 immutable desiredTokenIndex;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IRECustodian _custodian, IREUSD _reusd, ICurveStableSwap _pool, ICurvePool _basePool, IERC20 _desiredToken)
    {
        assert(_reusd.isREUSD() && _custodian.isRECustodian());
        custodian = _custodian;
        REUSD = _reusd;
        pool = _pool;
        basePool = _basePool;
        desiredToken = _desiredToken;
        reusdIndex = _pool.coins(0) == _reusd ? 0 : 1;
        basePoolIndex = 1 - reusdIndex;
        assert(reusdIndex == 0 || _pool.coins(1) == _reusd);
        basePoolToken = _pool.coins(basePoolIndex);
        
        uint256 _index = 3;
        if (_basePool.coins(0) == _desiredToken) { _index = 0; }
        else if (_basePool.coins(1) == _desiredToken) { _index = 1; }
        else if (_basePool.coins(2) == _desiredToken) { _index = 2; }
        desiredTokenIndex = _index;
        // ^-- workaround for https://github.com/sc-forks/solidity-coverage/issues/751
        //desiredTokenIndex = _basePool.coins(0) == _desiredToken ? 0 : _basePool.coins(1) == _desiredToken ? 1 : _basePool.coins(2) == _desiredToken ? 2 : 3;

        assert(desiredTokenIndex < 3 || _basePool.coins(desiredTokenIndex) == _desiredToken);
    }

    function initialize()
        public
    {
        REUSD.approve(address(pool), type(uint256).max);
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IRECurveBlargitrage(newImplementation).isRECurveBlargitrage());
    }

    function balance()
        public
        virtual
    {
        uint256 baseDollarValue = pool.balances(basePoolIndex) * basePool.get_virtual_price() / 1 ether;
        uint256 reusdBalance = pool.balances(reusdIndex);
        if (reusdBalance >= baseDollarValue) { return; }
        uint256 imbalance = baseDollarValue - reusdBalance;
        if (imbalance < MinImbalance) { return; }
        REUSD.mint(address(this), imbalance);
        uint256 received = CheapSafeCurve.safeAddLiquidity(address(pool), pool, reusdIndex == 0 ? [imbalance, 0] : [0, imbalance], 0);
        uint256[2] memory amounts = pool.remove_liquidity(received, [uint256(0), 0]);
        REUSD.transfer(address(0), amounts[reusdIndex]);
        totalAmount += CheapSafeCurve.safeRemoveLiquidityOneCoin(address(basePool), desiredToken, desiredTokenIndex, amounts[basePoolIndex], 0, address(custodian));
    }
}