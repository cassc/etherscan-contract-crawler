// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { BaseStrategy } from "BaseStrategy.sol";
import {SafeERC20, SafeMath, IERC20, Address} from "SafeERC20.sol";


interface ITradeFactory {
    function enable(address, address) external;
}

interface IVoterProxy {
    function lock() external;
    function claim(address _recipient) external;
    function claimable() external view returns (bool);
}

interface IBaseFee {
    function isCurrentBaseFeeAcceptable() external view returns (bool);
}

interface IVoter {
    function strategy() external view returns (address);
}

contract Strategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint profitThreshold = 5_000e18;
    address public tradeFactory;
    address public proxy;
    address public voter = 0xF147b8125d2ef93FB6965Db97D6746952a133934;
    IERC20 internal constant crv3 = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    bool public ignoreClaim;

    constructor(address _vault) BaseStrategy(_vault) public {
        healthCheck = 0xDDCea799fF1699e98EDF118e0629A974Df7DF012;
        tradeFactory = 0x7BAF843e06095f68F4990Ca50161C2C4E4e01ec6;
        proxy = IVoter(voter).strategy();
    }

    function name() external view override returns (string memory) {
        return "StrategyStYCRV";
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        return want.balanceOf(address(this));
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        ) {

        require(tradeFactory != address(0), "!tf");
 
        if (_debtOutstanding > 0) {
            (_debtPayment, ) = liquidatePosition(_debtOutstanding);
        }

        // ignoreClaim is a toggle which allows us to bypass claim logic if it is reverting
        if (!ignoreClaim) _claim();

        uint256 debt = vault.strategies(address(this)).totalDebt;
        uint256 assets = estimatedTotalAssets();
        if (assets >= debt){
            _profit = assets.sub(debt);
        } else {
            _loss = debt.sub(assets);
        }
    }

    // Here we lock curve in the voter contract. Lock doesn't require approval.
    function adjustPosition(uint256 _debtOutstanding) internal override {
        IVoterProxy(proxy).lock();
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 totalAssets = want.balanceOf(address(this));
        if (_amountNeeded > totalAssets) {
            _liquidatedAmount = totalAssets;
            _loss = _amountNeeded.sub(totalAssets);
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        uint256 balance3crv = balanceOf3crv();
        if(balance3crv > 0){
            crv3.safeTransfer(_newStrategy, balance3crv);
        }
    }

    function harvestTrigger(uint256 callCostinEth)
        public
        view
        override
        returns (bool)
    {
        // harvest if we have a profit to claim at our upper limit without considering gas price
        uint256 debt = vault.strategies(address(this)).totalDebt;
        uint256 assets = estimatedTotalAssets();

        if (!isBaseFeeAcceptable()) {
            return false;
        }

        if (
            assets >= debt.add(profitThreshold) ||
            IVoterProxy(proxy).claimable()            
        ) return true;

        return false;
    }

    // We don't need this anymore since we don't use baseStrategy harvestTrigger
    function ethToWant(uint256 _amtInWei)
        public
        view
        virtual
        override
        returns (uint256)
    {}

    function liquidateAllPositions() internal override returns (uint256) {
        return want.balanceOf(address(this));
    }

    function claim() public onlyVaultManagers {
        _claim();
    }

    function _claim() internal {
        // Hardcoding this strategy address for safety
        IVoterProxy(proxy).claim(address(this));
    }

    function isBaseFeeAcceptable() internal view returns (bool) {
        return
            IBaseFee(0xb5e1CAcB567d98faaDB60a1fD4820720141f064F)
                .isCurrentBaseFeeAcceptable();
    }

    function balanceOf3crv() public view returns (uint256) {
        return crv3.balanceOf(address(this));
    }

    // Common API used to update Yearn's StrategyProxy if needed in case of upgrades.
    function setProxy(address _proxy) external onlyGovernance {
        proxy = _proxy;
    }

    // @dev Set true to ignore 3CRV claim from proxy. This allows us to bypass a revert if necessary.
    function setIgnoreClaim(bool _ignoreClaim) external onlyEmergencyAuthorized {
        ignoreClaim = _ignoreClaim;
    }

    function setProfitThreshold(uint _profitThreshold) external onlyVaultManagers {
        profitThreshold = _profitThreshold;
    }

    // internal helpers
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}

    // ----------------- YSWAPS FUNCTIONS ---------------------

    function setTradeFactory(address _tradeFactory) external onlyGovernance {
        if (tradeFactory != address(0)) {
            _removeTradeFactoryPermissions();
        }

        // approve and set up trade factory
        crv3.safeApprove(_tradeFactory, type(uint256).max);
        ITradeFactory tf = ITradeFactory(_tradeFactory);
        tf.enable(address(crv3), address(want));
        tradeFactory = _tradeFactory;
    }

    function removeTradeFactoryPermissions() external onlyVaultManagers {
        _removeTradeFactoryPermissions();

    }

    function _removeTradeFactoryPermissions() internal {
        crv3.safeApprove(tradeFactory, 0);
        tradeFactory = address(0);
    }
}