// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IAave.sol";
import "../interfaces/IVesperFinance.sol";
import "../interfaces/IUniswapConnector.sol";


contract S3TokenAaveVesperFinanceDAIProxy {
    uint8 private constant defaultInterestRate = 2;
    address private deployer;
    address private uniswapConnector;
    address private wethAddress;
    address private daiAddress;
    address private vPoolDAI;
    address private vPoolRewardsDAI;
    address private vspToken;
    address private aave;
    address private aavePriceOracle;
    address private aaveInterestDAI;
    address private collateral;
    address private aCollateral;

    constructor(
        address _deployer,
        address _uniswapConnector,
        address _wethAddress,
        address _daiAddress,
        address _vPoolDAI,
        address _vPoolRewardsDAI,
        address _vspToken,
        address _aave,
        address _collateral,
        address _aCollateral
    ) {
        deployer = _deployer;
        uniswapConnector = _uniswapConnector;
        wethAddress = _wethAddress;
        daiAddress = _daiAddress;
        vPoolDAI = _vPoolDAI;
        vPoolRewardsDAI = _vPoolRewardsDAI;
        vspToken = _vspToken; 
        aave = _aave;
        collateral = _collateral; 
        aCollateral = _aCollateral;  

        // Give Aave lending protocol approval - needed when repaying the DAI loan
        IERC20(daiAddress).approve(aave, 2**256 - 1);
        // Give S3AaveVesperFinanceDAI DAI approval - needed when sending the DAI rewards to the depositor
        IERC20(daiAddress).approve(deployer, 2**256 - 1);
        // Allow Vesper Finance protocol to take DAI from the proxy
        IERC20(daiAddress).approve(vPoolDAI, 2**256 - 1);
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    }

    function setupAaveAddresses(
        address _aavePriceOracle,
        address _aaveInterestDAI
    ) external onlyDeployer {
        aavePriceOracle = _aavePriceOracle;
        aaveInterestDAI = _aaveInterestDAI;
    }

    function deposit(address _token, uint256 _amount, uint8 _borrowPercentage, bool _borrowAndDeposit) external onlyDeployer {
        IERC20(_token).transferFrom(deployer, address(this), _amount);

        if (IERC20(_token).allowance(address(this), aave) == 0) {
            IERC20(_token).approve(aave, 2**256 - 1);
        }
        
        (, , uint256 availableBorrowsETH, , ,) = IAave(aave).getUserAccountData(address(this));

        // supply to Aave protocol
        IAave(aave).deposit(_token, _amount, address(this), 0);

        // Aave borrow & TrueFi deposit
        if (_borrowAndDeposit) {
            // borrow DAI from Aave protocol
            (, , uint256 availableBorrowsETHAfterDeposit, , ,) = IAave(aave).getUserAccountData(address(this));
            uint256 maxAmountToBeBorrowed = ((availableBorrowsETHAfterDeposit - availableBorrowsETH) * 10 ** IERC20(daiAddress).decimals()) / IPriceOracleGetter(aavePriceOracle).getAssetPrice(daiAddress); 
            IAave(aave).borrow(
                daiAddress, 
                (maxAmountToBeBorrowed * _borrowPercentage) / 100,
                defaultInterestRate,
                0, 
                address(this)
            );

            // Vesper Finance deposit
            IVPoolDAI(vPoolDAI).deposit(IERC20(daiAddress).balanceOf(address(this)));
        }
    }

    function withdraw(uint8 _percentage, uint256 _amountInMaximum) external onlyDeployer returns(uint256) {
        IVPoolDAI(vPoolDAI).withdraw((IERC20(vPoolDAI).balanceOf(address(this)) * _percentage) / 100);

        // repay the DAI loan to Aave protocol
        uint256 currentDebt = IERC20(aaveInterestDAI).balanceOf(address(this));
        uint256 borrowAssetBalance = IERC20(daiAddress).balanceOf(address(this));
        uint256 currentDebtAfterRepaying;
        if (borrowAssetBalance > (currentDebt * _percentage) / 100) {
            // full repay
            _aaveRepay((currentDebt * _percentage) / 100, address(this));
        } else {
            // partly repay
            _aaveRepay(borrowAssetBalance, address(this));
            currentDebtAfterRepaying = (currentDebt * _percentage) / 100 - borrowAssetBalance;
        }

        return _withdrawCollateral(
            _percentage,
            currentDebtAfterRepaying, 
            _amountInMaximum
        );
    }

    function withdrawCollateral(uint8 _percentage) external onlyDeployer returns(uint256) {
        return _withdrawCollateral(_percentage, 0, 0);
    }

    function _withdrawCollateral(uint8 _percentage, uint256 _currentDebtAfterRepaying, uint256 _amountInMaximum) private returns(uint256) {
        uint256 maxAmountToBeWithdrawn = _calculateMaxAmountToBeWithdrawn();
        if (_percentage != 100) {
            maxAmountToBeWithdrawn = (maxAmountToBeWithdrawn * _percentage) / 100;
        }

        // if there is debt sell part of the collateral to cover it
        if (_currentDebtAfterRepaying > 0) {
            _aaveWithdraw(maxAmountToBeWithdrawn, address(this));

            if (IERC20(collateral).allowance(address(this), uniswapConnector) == 0) {
                IERC20(collateral).approve(uniswapConnector, 2**256 - 1);
            }

            IUniswapConnector(uniswapConnector).swapTokenForTokenV3ExactOutput(
                collateral, 
                daiAddress,
                _currentDebtAfterRepaying, 
                _amountInMaximum, 
                address(this)
            );

            uint256 maxAmountToBeWithdrawnBeforeRepay = _calculateMaxAmountToBeWithdrawn();
            _aaveRepay(IERC20(daiAddress).balanceOf(address(this)), address(this));
            uint256 maxAmountToBeWithdrawnAfterRepay = _calculateMaxAmountToBeWithdrawn();
            
            // withdraw rest of the unlocked collateral after repaying the loan
            _aaveWithdraw(maxAmountToBeWithdrawnAfterRepay - maxAmountToBeWithdrawnBeforeRepay, deployer);
            uint256 currentCollateralBalance = IERC20(collateral).balanceOf(address(this));
            IERC20(collateral).transfer(deployer, currentCollateralBalance);

            return currentCollateralBalance;
        } else {
            return _aaveWithdraw(maxAmountToBeWithdrawn, deployer);
        }
    }

    function emergencyWithdraw(address _token, address _depositor) external onlyDeployer {
        IERC20(_token).transfer(_depositor, IERC20(_token).balanceOf(address(this)));
    }

    function _calculateMaxAmountToBeWithdrawn() private view returns(uint256) {
        (, uint256 totalDebtETH, , uint256 currentLiquidationThreshold, , ) = IAave(aave).getUserAccountData(address(this));
        uint256 maxAmountToBeWithdrawn;
        if (totalDebtETH > 0) {
            uint256 collateralPriceRatio = IPriceOracleGetter(aavePriceOracle).getAssetPrice(collateral);
            maxAmountToBeWithdrawn = (((10100 * totalDebtETH) / currentLiquidationThreshold) * 10 ** IERC20(collateral).decimals()) / collateralPriceRatio;
            maxAmountToBeWithdrawn = IERC20(aCollateral).balanceOf(address(this)) - maxAmountToBeWithdrawn;
        } else {
            maxAmountToBeWithdrawn = IERC20(aCollateral).balanceOf(address(this));
        }

        return maxAmountToBeWithdrawn;
    }

    function _aaveRepay(uint256 _amount, address _to) private {
        IAave(aave).repay(
            daiAddress, 
            _amount,
            defaultInterestRate, 
            _to
        );
    }

    function _aaveWithdraw(uint256 _amount, address _to) private returns(uint256) {
        return IAave(aave).withdraw(
            collateral,
            _amount, 
            _to
        );
    }

    function claimToDepositor(address _depositor) external onlyDeployer returns(uint256) {
        return _claim(_depositor);
    }

    function claimToDeployer() external onlyDeployer returns(uint256) {
        return _claim(deployer);
    }

    function _claim(address _address) private returns(uint256) {
        // VSP tokens
        IVPoolRewards(vPoolRewardsDAI).claimReward(address(this));

        uint256 vspBalance = IERC20(vspToken).balanceOf(address(this));
        IERC20(vspToken).transfer(
            _address,
            vspBalance
        );

        return vspBalance;
    }
}

// MN bby ¯\_(ツ)_/¯