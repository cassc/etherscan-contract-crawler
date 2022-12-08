// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "vesper-pools/contracts/interfaces/vesper/IVesperPool.sol";
import "vesper-pools/contracts/Errors.sol";
import "../interfaces/aave/IAave.sol";
import "../interfaces/dydx/ISoloMargin.sol";

/**
 * @title FlashLoanHelper:: This contract does all heavy lifting to get flash loan via Aave and DyDx.
 * @dev End user has to override _flashLoanLogic() function to perform logic after flash loan is done.
 *      Also needs to approve token to aave and dydx via _approveToken function.
 *      2 utility internal functions are also provided to activate/deactivate flash loan providers.
 *      Utility function are provided as internal so that end user can choose controlled access via public functions.
 */
abstract contract FlashLoanHelper {
    using SafeERC20 for IERC20;

    PoolAddressesProvider internal poolAddressesProvider;

    address internal constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    uint256 public dyDxMarketId;
    bytes32 private constant AAVE_PROVIDER_ID = 0x0100000000000000000000000000000000000000000000000000000000000000;
    bool public isAaveActive = false;
    bool public isDyDxActive = false;

    constructor(address _aaveAddressesProvider) {
        require(_aaveAddressesProvider != address(0), Errors.INPUT_ADDRESS_IS_ZERO);

        poolAddressesProvider = PoolAddressesProvider(_aaveAddressesProvider);
    }

    function _updateAaveStatus(bool _status) internal {
        isAaveActive = _status;
    }

    function _updateDyDxStatus(bool _status, address _token) internal {
        if (_status) {
            dyDxMarketId = _getMarketIdFromTokenAddress(SOLO, _token);
        }
        isDyDxActive = _status;
    }

    /// @notice Approve all required tokens for flash loan
    function _approveToken(address _token, uint256 _amount) internal {
        IERC20(_token).safeApprove(SOLO, _amount);
        IERC20(_token).safeApprove(poolAddressesProvider.getLendingPool(), _amount);
    }

    /// @dev Override this function to execute logic which uses flash loan amount
    function _flashLoanLogic(bytes memory _data, uint256 _repayAmount) internal virtual;

    /***************************** Aave flash loan functions ***********************************/

    bool private awaitingFlash = false;

    /**
     * @notice This is entry point for Aave flash loan
     * @param _token Token for which we are taking flash loan
     * @param _amountDesired Flash loan amount
     * @param _data This will be passed downstream for processing. It can be empty.
     */
    function _doAaveFlashLoan(
        address _token,
        uint256 _amountDesired,
        bytes memory _data
    ) internal returns (uint256 _amount) {
        require(isAaveActive, Errors.AAVE_FLASH_LOAN_NOT_ACTIVE);
        AaveLendingPool _aaveLendingPool = AaveLendingPool(poolAddressesProvider.getLendingPool());
        AaveProtocolDataProvider _aaveProtocolDataProvider = AaveProtocolDataProvider(
            poolAddressesProvider.getAddress(AAVE_PROVIDER_ID)
        );
        // Check token liquidity in Aave
        (uint256 _availableLiquidity, , , , , , , , , ) = _aaveProtocolDataProvider.getReserveData(_token);
        if (_amountDesired > _availableLiquidity) {
            _amountDesired = _availableLiquidity;
        }

        address[] memory assets = new address[](1);
        assets[0] = _token;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amountDesired;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        // Anyone can call aave flash loan to us, so we need some protection
        awaitingFlash = true;

        // function params: receiver, assets, amounts, modes, onBehalfOf, data, referralCode
        _aaveLendingPool.flashLoan(address(this), assets, amounts, modes, address(this), _data, 0);
        _amount = _amountDesired;
        awaitingFlash = false;
    }

    /// @dev Aave will call this function after doing flash loan
    function executeOperation(
        address[] calldata, /*_assets*/
        uint256[] calldata _amounts,
        uint256[] calldata _premiums,
        address _initiator,
        bytes calldata _data
    ) external returns (bool) {
        require(msg.sender == poolAddressesProvider.getLendingPool(), "!aave-pool");
        require(awaitingFlash, Errors.INVALID_FLASH_LOAN);
        require(_initiator == address(this), Errors.INVALID_INITIATOR);

        // Flash loan amount + flash loan fee
        uint256 _repayAmount = _amounts[0] + _premiums[0];
        _flashLoanLogic(_data, _repayAmount);
        return true;
    }

    /***************************** Aave flash loan functions ends ***********************************/

    /***************************** DyDx flash loan functions ***************************************/

    /**
     * @notice This is entry point for DyDx flash loan
     * @param _token Token for which we are taking flash loan
     * @param _amountDesired Flash loan amount
     * @param _data This will be passed downstream for processing. It can be empty.
     */
    function _doDyDxFlashLoan(
        address _token,
        uint256 _amountDesired,
        bytes memory _data
    ) internal returns (uint256 _amount) {
        require(isDyDxActive, Errors.DYDX_FLASH_LOAN_NOT_ACTIVE);

        // Check token liquidity in DyDx
        uint256 amountInSolo = IERC20(_token).balanceOf(SOLO);
        if (_amountDesired > amountInSolo) {
            _amountDesired = amountInSolo;
        }
        // Repay amount, amount with fee, can be 2 wei higher. Consider 2 wei as fee
        uint256 repayAmount = _amountDesired + 2;

        // Encode custom data for callFunction
        bytes memory _callData = abi.encode(_data, repayAmount);

        // 1. Withdraw _token
        // 2. Call callFunction(...) which will call loanLogic
        // 3. Deposit _token back
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(dyDxMarketId, _amountDesired);
        operations[1] = _getCallAction(_callData);
        operations[2] = _getDepositAction(dyDxMarketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        ISoloMargin(SOLO).operate(accountInfos, operations);
        _amount = _amountDesired;
    }

    /// @dev DyDx calls this function after doing flash loan
    function callFunction(
        address _sender,
        Account.Info memory, /* _account */
        bytes memory _callData
    ) external {
        (bytes memory _data, uint256 _repayAmount) = abi.decode(_callData, (bytes, uint256));
        require(msg.sender == SOLO, "!solo");
        require(_sender == address(this), Errors.INVALID_INITIATOR);
        _flashLoanLogic(_data, _repayAmount);
    }

    /********************************* DyDx helper functions *********************************/
    function _getAccountInfo() internal view returns (Account.Info memory) {
        return Account.Info({owner: address(this), number: 1});
    }

    function _getMarketIdFromTokenAddress(address _solo, address token) internal view returns (uint256) {
        ISoloMargin solo = ISoloMargin(_solo);

        uint256 numMarkets = solo.getNumMarkets();

        address curToken;
        for (uint256 i = 0; i < numMarkets; i++) {
            curToken = solo.getMarketTokenAddress(i);

            if (curToken == token) {
                return i;
            }
        }

        revert(Errors.NO_MARKET_ID_FOUND);
    }

    function _getWithdrawAction(uint256 marketId, uint256 amount) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Withdraw,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }

    function _getCallAction(bytes memory data) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Call,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: 0
                }),
                primaryMarketId: 0,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: data
            });
    }

    function _getDepositAction(uint256 marketId, uint256 amount) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Deposit,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: true,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }

    /***************************** DyDx flash loan functions end *****************************/
}