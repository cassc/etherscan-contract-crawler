// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {StrategyController} from "../strategies/StrategyController.sol";

abstract contract Strategy {
    address payable public immutable controller;

    address public governance;

    string public name;

    modifier onlyGovernance() {
        require(governance == msg.sender, "not governace");
        _;
    }

    event TransferGovernance(address oldOwner, address newOwner);

    constructor(address payable _controller, string memory _name) {
        require(_controller != address(0), "ZERO ADDRESS");

        governance = msg.sender;
        controller = _controller;
        name = _name;
    }

    modifier onlyController() {
        require(controller == msg.sender, "not controller");
        _;
    }

    function deposit() public payable virtual onlyController {}

    function withdraw(
        uint256 _amount
    ) public virtual onlyController returns (uint256 actualAmount) {}

    function instantWithdraw(
        uint256 _amount
    ) public virtual onlyController returns (uint256 actualAmount) {}

    function clear() public virtual onlyController returns (uint256 amount) {}

    function execPendingRequest(
        uint256 _amount
    ) public virtual returns (uint256 amount) {}

    function getAllValue() public virtual returns (uint256 value) {}

    function getPendingValue() public virtual returns (uint256 value) {}

    function getInvestedValue() public virtual returns (uint256 value) {}

    function checkPendingStatus()
        public
        virtual
        returns (uint256 pending, uint256 executable)
    {}

    function setGovernance(address governance_) external onlyGovernance {
        emit TransferGovernance(governance, governance_);
        governance = governance_;
    }
}