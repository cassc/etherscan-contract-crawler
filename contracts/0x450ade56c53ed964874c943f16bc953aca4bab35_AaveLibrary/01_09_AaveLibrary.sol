pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../_lib/aave/contracts/interfaces/IAavePool.sol";


library AaveLibrary {
    using SafeERC20 for IERC20;

    struct Data {
        IAavePool aavePool;
        IAavePriceOracle aavePriceOracle;
        address tokenToBorrow;
        address collateral;
        uint256 ltv; // in 10^-6s
    }

    function performApprovals(Data storage self) public {
        IERC20(self.tokenToBorrow).safeIncreaseAllowance(
            address(self.aavePool),
            type(uint256).max
        );
        IERC20(self.collateral).safeIncreaseAllowance(
            address(self.aavePool),
            type(uint256).max
        );
        IERC20(self.aavePool.getReserveData(self.collateral).aTokenAddress)
            .safeIncreaseAllowance(address(self.aavePool), type(uint256).max);
    }

    function getCurrentLtv(Data storage self) public view returns (uint256) {
        uint256 collateral = getCurrentCollateralSupply(self);
        uint256 collateralValue = (collateral *
            self.aavePriceOracle.getAssetPrice(address(self.collateral))) /
            (10**IERC20Metadata(self.collateral).decimals());

        if (collateralValue == 0) {
            return self.ltv;
        }

        uint256 debt = getCurrentDebt(self);
        uint256 debtValue = (debt *
            self.aavePriceOracle.getAssetPrice(address(self.tokenToBorrow))) /
            (10**IERC20Metadata(self.tokenToBorrow).decimals());
        if (debtValue == 0) {
            return self.ltv;
        }
        return (debtValue * 1000000) / collateralValue;
    }

    function getCurrentCollateralSupply(Data storage self)
        public
        view
        returns (uint256)
    {
        return
            IERC20(
                self
                    .aavePool
                    .getReserveData(address(self.collateral))
                    .aTokenAddress
            ).balanceOf(address(this));
    }

    function getCurrentDebt(Data storage self) public view returns (uint256) {
        return
            IERC20(
                self
                    .aavePool
                    .getReserveData(address(self.tokenToBorrow))
                    .variableDebtTokenAddress
            ).balanceOf(address(this));
    }

    function getNeededDebt(
        Data storage self,
        uint256 collateral,
        uint256 ltv
    ) public view returns (uint256 neededDebt) {
        uint256 collateralValue = (collateral *
            self.aavePriceOracle.getAssetPrice(address(self.collateral))) /
            (10**IERC20Metadata(self.collateral).decimals());
        uint256 neededDebtValue = (collateralValue * ltv) / 1000000;
        neededDebt =
            (neededDebtValue *
                10**IERC20Metadata(self.tokenToBorrow).decimals()) /
            self.aavePriceOracle.getAssetPrice(address(self.tokenToBorrow));
    }

    function supply(Data storage self, uint256 amount) public {
        if (amount > 0)
            self.aavePool.supply(
                address(self.collateral),
                amount,
                address(this),
                0
            );
    }

    function withdraw(Data storage self, uint256 amount) public {
        if (amount > 0)
            self.aavePool.withdraw(
                address(self.collateral),
                amount,
                address(this)
            );
    }

    function borrow(Data storage self, uint256 amount) public {
        if (amount > 0)
            self.aavePool.borrow(
                address(self.tokenToBorrow),
                amount,
                2,
                0,
                address(this)
            );
    }

    function repay(Data storage self, uint256 amount) public {
        if (amount > 0)
            self.aavePool.repay(
                address(self.tokenToBorrow),
                amount,
                2,
                address(this)
            );
    }

    function repayAndWithdraw(Data storage self, uint256 debt)
        public
        returns (uint256 collateral)
    {
        uint256 totalDebt = getCurrentDebt(self);
        uint256 totalCollateral = getCurrentCollateralSupply(self);
        collateral = (debt * totalCollateral) / totalDebt;
        repay(self, debt);
        withdraw(self, collateral);
    }
    
    function flashloan(Data storage self, address asset, uint256 amount) public {
        self.aavePool.flashLoanSimple(address(this), asset, amount, "", 0);
    }
}