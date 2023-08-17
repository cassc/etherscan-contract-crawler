// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../../interface/IProxy.sol";
import "../HandlerBase.sol";
import "../wrappednativetoken/IWrappedNativeToken.sol";
import "./IPool.sol";
import "./IFlashLoanReceiver.sol";

contract HAaveProtocolV3 is HandlerBase, IFlashLoanReceiver {
    // prettier-ignore
    uint16 public constant REFERRAL_CODE = 56;

    address public immutable wrappedNativeToken;
    address public immutable provider;

    constructor(address wrappedNativeToken_, address provider_) {
        wrappedNativeToken = wrappedNativeToken_;
        provider = provider_;
    }

    function getContractName() public pure override returns (string memory) {
        return "HAaveProtocolV3";
    }

    function supply(
        address asset,
        uint256 amount
    ) external payable returns (uint256 supplyAmount) {
        amount = _getBalance(asset, amount);
        supplyAmount = _supply(asset, amount);
    }

    function supplyETH(
        uint256 amount
    ) external payable returns (uint256 supplyAmount) {
        amount = _getBalance(NATIVE_TOKEN_ADDRESS, amount);
        IWrappedNativeToken(wrappedNativeToken).deposit{value: amount}();

        supplyAmount = _supply(wrappedNativeToken, amount);

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
        address pool = IPoolAddressesProvider(provider).getPool();

        try
            IPool(pool).flashLoan(
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

        // approve pool zero
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
            msg.sender == IPoolAddressesProvider(provider).getPool(),
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

        address pool = IPoolAddressesProvider(provider).getPool();
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountOwing = amounts[i] + premiums[i];
            _tokenApprove(assets[i], pool, amountOwing);
        }
        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _supply(
        address asset,
        uint256 amount
    ) internal returns (uint256 supplyAmount) {
        (address pool, address aToken) = _getPoolAndAToken(asset);
        _tokenApprove(asset, pool, amount);
        uint256 beforeATokenAmount = IERC20(aToken).balanceOf(address(this));

        try
            IPool(pool).supply(asset, amount, address(this), REFERRAL_CODE)
        {} catch Error(string memory reason) {
            _revertMsg("supply", reason);
        } catch {
            _revertMsg("supply");
        }

        unchecked {
            supplyAmount =
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
        (address pool, address aToken) = _getPoolAndAToken(asset);
        amount = _getBalance(aToken, amount);

        try IPool(pool).withdraw(asset, amount, address(this)) returns (
            uint256 ret
        ) {
            withdrawAmount = ret;
        } catch Error(string memory reason) {
            _revertMsg("withdraw", reason);
        } catch {
            _revertMsg("withdraw");
        }
    }

    function _borrow(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) internal {
        address pool = IPoolAddressesProvider(provider).getPool();

        try
            IPool(pool).borrow(
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

    function _repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) internal returns (uint256 remainDebt) {
        address pool = IPoolAddressesProvider(provider).getPool();
        _tokenApprove(asset, pool, amount);

        try
            IPool(pool).repay(asset, amount, rateMode, onBehalfOf)
        {} catch Error(string memory reason) {
            _revertMsg("repay", reason);
        } catch {
            _revertMsg("repay");
        }

        _tokenApproveZero(asset, pool);

        DataTypes.ReserveData memory reserve = IPool(pool).getReserveData(
            asset
        );
        remainDebt = DataTypes.InterestRateMode(rateMode) ==
            DataTypes.InterestRateMode.STABLE
            ? IERC20(reserve.stableDebtTokenAddress).balanceOf(onBehalfOf)
            : IERC20(reserve.variableDebtTokenAddress).balanceOf(onBehalfOf);
    }

    function _getPoolAndAToken(
        address underlying
    ) internal view returns (address pool, address aToken) {
        pool = IPoolAddressesProvider(provider).getPool();
        try IPool(pool).getReserveData(underlying) returns (
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