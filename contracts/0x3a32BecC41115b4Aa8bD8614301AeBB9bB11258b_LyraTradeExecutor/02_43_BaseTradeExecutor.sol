//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ITradeExecutor.sol";
import "../interfaces/IVault.sol";

abstract contract BaseTradeExecutor is ITradeExecutor {
    uint256 internal constant MAX_INT = type(uint256).max;

    ActionStatus public override depositStatus;
    ActionStatus public override withdrawalStatus;

    address public override vault;

    constructor(address _vault) {
        vault = _vault;
        IERC20(vaultWantToken()).approve(vault, MAX_INT);
    }

    function vaultWantToken() public view returns (address) {
        return IVault(vault).wantToken();
    }

    function governance() public view returns (address) {
        return IVault(vault).governance();
    }

    function keeper() public view returns (address) {
        return IVault(vault).keeper();
    }

    modifier onlyGovernance() {
        require(msg.sender == governance(), "ONLY_GOV");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper(), "ONLY_KEEPER");
        _;
    }

    modifier keeperOrGovernance() {
        require(
            msg.sender == keeper() || msg.sender == governance(),
            "ONLY_KEEPER_OR_GOVERNANCE"
        );
        _;
    }

    function sweep(address _token) public onlyGovernance {
        IERC20(_token).transfer(
            governance(),
            IERC20(_token).balanceOf(address(this))
        );
    }

    function initiateDeposit(bytes calldata _data) public override onlyKeeper {
        require(!depositStatus.inProcess, "DEPOSIT_IN_PROGRESS");
        depositStatus.inProcess = true;
        _initateDeposit(_data);
    }

    function confirmDeposit() public override onlyKeeper {
        require(depositStatus.inProcess, "DEPOSIT_COMPLETED");
        depositStatus.inProcess = false;
        _confirmDeposit();
    }

    function initiateWithdraw(bytes calldata _data) public override onlyKeeper {
        require(!withdrawalStatus.inProcess, "WITHDRAW_IN_PROGRESS");
        withdrawalStatus.inProcess = true;
        _initiateWithdraw(_data);
    }

    function confirmWithdraw() public override onlyKeeper {
        require(withdrawalStatus.inProcess, "WITHDRAW_COMPLETED");
        withdrawalStatus.inProcess = false;
        _confirmWithdraw();
    }

    /// Internal Funcs

    function _initateDeposit(bytes calldata _data) internal virtual;

    function _confirmDeposit() internal virtual;

    function _initiateWithdraw(bytes calldata _data) internal virtual;

    function _confirmWithdraw() internal virtual;
}