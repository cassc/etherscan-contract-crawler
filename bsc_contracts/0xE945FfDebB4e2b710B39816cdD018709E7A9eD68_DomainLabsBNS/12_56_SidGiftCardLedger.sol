// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "./SidGiftCardRegistrar.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SidGiftCardVoucher.sol";

contract SidGiftCardLedger is Ownable {
    SidGiftCardRegistrar public registrar;
    SidGiftCardVoucher public voucher;
    mapping(address => uint256) public balances;
    mapping(address => bool) public controllers;

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);

    constructor(SidGiftCardRegistrar _registrar, SidGiftCardVoucher _voucher) {
        registrar = _registrar;
        voucher = _voucher;
    }

    modifier onlyController() {
        require(controllers[msg.sender], "Not a authorized controller");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function redeem(uint256[] calldata ids, uint256[] calldata amounts) external {
        registrar.batchBurn(msg.sender, ids, amounts);
        uint256 totalValue = voucher.totalValue(ids, amounts);
        balances[msg.sender] += totalValue;
    }

    function deduct(address account, uint256 amount) public onlyController {
        uint256 fromBalance = balances[account];
        require(fromBalance >= amount, "Insufficient balance");
        balances[account] = fromBalance - amount;
    }

    function addController(address controller) external onlyOwner {
        require(controller != address(0), "address can not be zero!");
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    function removeController(address controller) external onlyOwner {
        require(controller != address(0), "address can not be zero!");
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }
}