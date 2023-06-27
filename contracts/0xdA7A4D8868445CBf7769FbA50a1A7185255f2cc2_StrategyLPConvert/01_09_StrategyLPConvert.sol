// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;
pragma experimental ABIEncoderV2;

import "SafeERC20.sol";
import {BaseStrategy, StrategyParams} from "BaseStrategy.sol";

interface ICurve {
    function remove_liquidity(uint _burn_amount, uint[2] memory _min_amounts) external returns (uint[2] calldata);
    function add_liquidity(uint[2] memory _amounts, uint _min_mint_amount) external returns (uint);
    function coins(uint) external view returns (address);
}

interface IVault {
    function deposit(uint amount) external returns (uint);
}

contract StrategyLPConvert is BaseStrategy {
    using SafeERC20 for IERC20;

    address constant YTRADES = 0x7d2aB9CA511EBD6F03971Fb417d3492aA82513f0;
    address constant V2POOL = 0x99f5aCc8EC2Da2BC0771c32814EFF52b712de1E5;
    address constant V2VAULT = 0x6E9455D109202b426169F0d8f01A3332DAE160f3;
    bool public firstHarvest = true;
    uint public migratedDebt;
    uint[2] public minAmountsRemoved;
    uint public minLPsOut;


    constructor(address _vault) BaseStrategy(_vault) {
        IERC20(ICurve(V2POOL).coins(0)).approve(V2POOL, type(uint256).max); // Approve CRV
        IERC20(ICurve(V2POOL).coins(1)).approve(V2POOL, type(uint256).max); // Approve YCRV
        IERC20(V2POOL).approve(V2VAULT, type(uint256).max);
    }

    function name() external view override returns (string memory) {
        return "StrategyLPConvert";
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
        )
    {
        _debtPayment = _debtOutstanding - migratedDebt;
    }

    // @dev Provides graceful method to fix accounting if ever necessary
    // @dev Anybody is allowed to repay the bad debt amount
    function repayDebt() external {
        want.transferFrom(msg.sender, address(this), migratedDebt);
        migratedDebt = 0;
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        // Even though "tend" could technically get us past this condition before first harvest...
        // it would revert on attempting LP convert.
        if (firstHarvest){
            require(minLPsOut != 0, "SetMinsPlease!");
            migratedDebt = calculateHoldings();
            uint amount = migrateLPs(migratedDebt);
            IVault(V2VAULT).deposit(amount);
            firstHarvest = false;
        }
    }

    function setParams(uint[2] memory _minAmountsRemoved, uint _minLPsOut) external onlyVaultManagers{
        minAmountsRemoved = _minAmountsRemoved;
        minLPsOut = _minLPsOut;
    }

    function migrateLPs(uint _amount) internal returns (uint) {
        uint[2] memory tokenAmounts = ICurve(address(want)).remove_liquidity(_amount, minAmountsRemoved); // Remove LP from v1 pool
        return ICurve(V2POOL).add_liquidity(tokenAmounts, minLPsOut); // Add LP to v2 pool
    }

    function calculateHoldings() internal view returns (uint256) {
        uint256 tokenBalance = IERC20(address(vault)).balanceOf(YTRADES);
        return vault.pricePerShare() * tokenBalance / 1e18;
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        // Attempt to liquidate assets if available. If not, we assign no losses.
        uint256 totalAssets = want.balanceOf(address(this));
        if (_amountNeeded > totalAssets) {
            _liquidatedAmount = totalAssets;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        return want.balanceOf(address(this));
    }

    function prepareMigration(address _newStrategy) internal override {
        IERC20(V2VAULT).transfer(_newStrategy, IERC20(V2VAULT).balanceOf(address(this)));
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}

    function ethToWant(uint256 _amtInWei)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // TODO create an accurate price oracle
        return _amtInWei;
    }
}