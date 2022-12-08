// SPDX-License-Identifier: MIT
// Heavily inspired from CompoundLeverage strategy of Yearn. https://etherscan.io/address/0x4031afd3B0F71Bace9181E554A9E680Ee4AbE7dF#code

pragma solidity 0.8.9;

import "../../interfaces/compound/ICompound.sol";
import "../Strategy.sol";
import "../FlashLoanHelper.sol";
import "./CompoundLeverageBase.sol";

// solhint-disable no-empty-blocks

/// @title This strategy will deposit collateral token in Compound and based on position
/// it will borrow same collateral token. It will use borrowed asset as supply and borrow again.
contract CompoundLeverage is CompoundLeverageBase, FlashLoanHelper {
    using SafeERC20 for IERC20;

    constructor(
        address _pool,
        address _swapper,
        address _comptroller,
        address _rewardToken,
        address _aaveAddressesProvider,
        address _receiptToken,
        string memory _name
    )
        CompoundLeverageBase(_pool, _swapper, _comptroller, _rewardToken, _receiptToken, _name)
        FlashLoanHelper(_aaveAddressesProvider)
    {}

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        FlashLoanHelper._approveToken(address(collateralToken), _amount);
    }

    /**
     * @dev Aave flash is used only for withdrawal due to high fee compare to DyDx
     * @param _flashAmount Amount for flash loan
     * @param _shouldRepay Flag indicating we want to leverage or deleverage
     * @return Total amount we leverage or deleverage using flash loan
     */
    function _doFlashLoan(uint256 _flashAmount, bool _shouldRepay) internal override returns (uint256) {
        uint256 _totalFlashAmount;
        // Due to less fee DyDx is our primary flash loan provider
        if (isDyDxActive && _flashAmount > 0) {
            bytes memory _data = abi.encode(_flashAmount, _shouldRepay);
            _totalFlashAmount = _doDyDxFlashLoan(address(collateralToken), _flashAmount, _data);
            _flashAmount -= _totalFlashAmount;
        }
        if (isAaveActive && _shouldRepay && _flashAmount > 0) {
            bytes memory _data = abi.encode(_flashAmount, _shouldRepay);
            _totalFlashAmount += _doAaveFlashLoan(address(collateralToken), _flashAmount, _data);
        }
        return _totalFlashAmount;
    }

    /**
     * @notice This function will be called by flash loan
     * @dev In case of borrow, DyDx is preferred as fee is so low that it does not effect
     * our collateralRatio and liquidation risk.
     */
    function _flashLoanLogic(bytes memory _data, uint256 _repayAmount) internal override {
        (uint256 _amount, bool _deficit) = abi.decode(_data, (uint256, bool));
        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        require(_collateralHere >= _amount, "FLASH_FAILED"); // to stop malicious calls

        //if in deficit we repay amount and then withdraw
        if (_deficit) {
            _repayBorrow(_amount);
            //if we are withdrawing we take more to cover fee
            _redeemUnderlying(_repayAmount);
        } else {
            _mint(_collateralHere);
            //borrow more to cover fee
            _borrowCollateral(_repayAmount);
        }
    }

    /************************************************************************************************
     *                          Governor/admin/keeper function                                      *
     ***********************************************************************************************/

    /// @notice Claim rewardToken and convert rewardToken into collateral token.
    function claimAndSwapRewards(uint256 _minAmountOut) external onlyKeeper returns (uint256 _amountOut) {
        uint256 _collateralBefore = collateralToken.balanceOf(address(this));
        address[] memory _markets = new address[](1);
        _markets[0] = address(cToken);
        comptroller.claimComp(address(this), _markets);
        uint256 _rewardAmount = IERC20(rewardToken).balanceOf(address(this));
        if (_rewardAmount > 0) {
            _safeSwapExactInput(rewardToken, address(collateralToken), _rewardAmount);
            _amountOut = collateralToken.balanceOf(address(this)) - _collateralBefore;
            require(_amountOut >= _minAmountOut, "not-enough-amountOut");
        }
    }

    function updateAaveStatus(bool _status) external onlyGovernor {
        _updateAaveStatus(_status);
    }

    function updateDyDxStatus(bool _status) external virtual onlyGovernor {
        _updateDyDxStatus(_status, address(collateralToken));
    }
}