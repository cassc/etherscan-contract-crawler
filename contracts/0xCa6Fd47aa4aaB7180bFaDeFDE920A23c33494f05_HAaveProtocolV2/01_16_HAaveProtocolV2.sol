// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interface/IProxy.sol";
import "../HandlerBase.sol";
import "../wrappednativetoken/IWrappedNativeToken.sol";
import "./ILendingPoolV2.sol";
import "./IFlashLoanReceiver.sol";
import "./ILendingPoolAddressesProviderV2.sol";
import "./libraries/DataTypes.sol";

contract HAaveProtocolV2 is HandlerBase, IFlashLoanReceiver {
    using SafeERC20 for IERC20;

    uint16 public constant REFERRAL_CODE = 56;
    address public immutable provider;
    address public immutable wrappedNativeToken;

    constructor(address wrappedNativeToken_, address provider_) {
        wrappedNativeToken = wrappedNativeToken_;
        provider = provider_;
    }

    function getContractName() public pure override returns (string memory) {
        return "HAaveProtocolV2";
    }

    function deposit(
        address asset,
        uint256 amount
    ) external payable returns (uint256 depositAmount) {
        amount = _getBalance(asset, amount);
        depositAmount = _deposit(asset, amount);
    }

    function depositETH(
        uint256 amount
    ) external payable returns (uint256 depositAmount) {
        amount = _getBalance(NATIVE_TOKEN_ADDRESS, amount);
        IWrappedNativeToken(wrappedNativeToken).deposit{value: amount}();
        depositAmount = _deposit(wrappedNativeToken, amount);

        _updateToken(wrappedNativeToken);
    }

    function withdraw(
        address asset,
        uint256 amount
    ) external payable returns (uint256 withdrawAmount) {
        withdrawAmount = _withdraw(asset, amount);

        _updateToken(asset);
    }

    function withdrawETH(
        uint256 amount
    ) external payable returns (uint256 withdrawAmount) {
        withdrawAmount = _withdraw(wrappedNativeToken, amount);
        IWrappedNativeToken(wrappedNativeToken).withdraw(withdrawAmount);
    }

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable returns (uint256 remainDebt) {
        remainDebt = _repay(asset, amount, rateMode, onBehalfOf);
    }

    function repayETH(
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable returns (uint256 remainDebt) {
        IWrappedNativeToken(wrappedNativeToken).deposit{value: amount}();
        remainDebt = _repay(wrappedNativeToken, amount, rateMode, onBehalfOf);

        _updateToken(wrappedNativeToken);
    }

    function borrow(
        address asset,
        uint256 amount,
        uint256 rateMode
    ) external payable {
        address onBehalfOf = _getSender();
        _borrow(asset, amount, rateMode, onBehalfOf);
        _updateToken(asset);
    }

    function borrowETH(uint256 amount, uint256 rateMode) external payable {
        address onBehalfOf = _getSender();
        _borrow(wrappedNativeToken, amount, rateMode, onBehalfOf);
        IWrappedNativeToken(wrappedNativeToken).withdraw(amount);
    }

    function flashLoan(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        bytes calldata params
    ) external payable {
        _requireMsg(
            assets.length == amounts.length,
            "flashLoan",
            "assets and amounts do not match"
        );

        _requireMsg(
            assets.length == modes.length,
            "flashLoan",
            "assets and modes do not match"
        );

        address onBehalfOf = _getSender();
        address pool = ILendingPoolAddressesProviderV2(provider)
            .getLendingPool();

        try
            ILendingPoolV2(pool).flashLoan(
                address(this),
                assets,
                amounts,
                modes,
                onBehalfOf,
                params,
                REFERRAL_CODE
            )
        {} catch Error(string memory reason) {
            _revertMsg("flashLoan", reason);
        } catch {
            _revertMsg("flashLoan");
        }

        // approve lending pool zero
        for (uint256 i = 0; i < assets.length; i++) {
            _tokenApproveZero(assets[i], pool);
            if (modes[i] != 0) _updateToken(assets[i]);
        }
    }

    function executeOperation(
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory premiums,
        address initiator,
        bytes memory params
    ) external override returns (bool) {
        _requireMsg(
            msg.sender ==
                ILendingPoolAddressesProviderV2(provider).getLendingPool(),
            "executeOperation",
            "invalid caller"
        );

        _requireMsg(
            initiator == address(this),
            "executeOperation",
            "not initiated by the proxy"
        );

        (
            address[] memory tos,
            bytes32[] memory configs,
            bytes[] memory datas
        ) = abi.decode(params, (address[], bytes32[], bytes[]));
        IProxy(address(this)).execs(tos, configs, datas);

        address pool = ILendingPoolAddressesProviderV2(provider)
            .getLendingPool();
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountOwing = amounts[i] + premiums[i];
            _tokenApprove(assets[i], pool, amountOwing);
        }
        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _deposit(
        address asset,
        uint256 amount
    ) internal returns (uint256 depositAmount) {
        (address pool, address aToken) = _getLendingPoolAndAToken(asset);
        _tokenApprove(asset, pool, amount);
        uint256 beforeATokenAmount = IERC20(aToken).balanceOf(address(this));

        try
            ILendingPoolV2(pool).deposit(
                asset,
                amount,
                address(this),
                REFERRAL_CODE
            )
        {} catch Error(string memory reason) {
            _revertMsg("deposit", reason);
        } catch {
            _revertMsg("deposit");
        }

        unchecked {
            depositAmount =
                IERC20(aToken).balanceOf(address(this)) -
                beforeATokenAmount;
        }

        _tokenApproveZero(asset, pool);
        _updateToken(aToken);
    }

    function _withdraw(
        address asset,
        uint256 amount
    ) internal returns (uint256 withdrawAmount) {
        (address pool, address aToken) = _getLendingPoolAndAToken(asset);
        amount = _getBalance(aToken, amount);

        try
            ILendingPoolV2(pool).withdraw(asset, amount, address(this))
        returns (uint256 ret) {
            withdrawAmount = ret;
        } catch Error(string memory reason) {
            _revertMsg("withdraw", reason);
        } catch {
            _revertMsg("withdraw");
        }
    }

    function _repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) internal returns (uint256 remainDebt) {
        address pool = ILendingPoolAddressesProviderV2(provider)
            .getLendingPool();
        _tokenApprove(asset, pool, amount);

        try
            ILendingPoolV2(pool).repay(asset, amount, rateMode, onBehalfOf)
        {} catch Error(string memory reason) {
            _revertMsg("repay", reason);
        } catch {
            _revertMsg("repay");
        }
        _tokenApproveZero(asset, pool);

        DataTypes.ReserveData memory reserve = ILendingPoolV2(pool)
            .getReserveData(asset);
        remainDebt = DataTypes.InterestRateMode(rateMode) ==
            DataTypes.InterestRateMode.STABLE
            ? IERC20(reserve.stableDebtTokenAddress).balanceOf(onBehalfOf)
            : IERC20(reserve.variableDebtTokenAddress).balanceOf(onBehalfOf);
    }

    function _borrow(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) internal {
        address pool = ILendingPoolAddressesProviderV2(provider)
            .getLendingPool();

        try
            ILendingPoolV2(pool).borrow(
                asset,
                amount,
                rateMode,
                REFERRAL_CODE,
                onBehalfOf
            )
        {} catch Error(string memory reason) {
            _revertMsg("borrow", reason);
        } catch {
            _revertMsg("borrow");
        }
    }

    function _getLendingPoolAndAToken(
        address underlying
    ) internal view returns (address pool, address aToken) {
        pool = ILendingPoolAddressesProviderV2(provider).getLendingPool();
        try ILendingPoolV2(pool).getReserveData(underlying) returns (
            DataTypes.ReserveData memory data
        ) {
            aToken = data.aTokenAddress;
            _requireMsg(
                aToken != address(0),
                "General",
                "aToken should not be zero address"
            );
        } catch Error(string memory reason) {
            _revertMsg("General", reason);
        } catch {
            _revertMsg("General");
        }
    }
}