// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Auth} from "../security/Auth.sol";
import {IPool} from "./interfaces/IPool.sol";

/**
 * @title Minthree Pool
 * @dev Minthree pool. Funds can only be transferred by the Validator
 */
contract Pool is Initializable, IPool, Auth {
    address public VALIDATOR;
    mapping(address => uint256) private _balances;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Auth_init(msg.sender);
    }

    function name() external pure returns (string memory) {
        return "Minthree Pool";
    }

    function symbol() external pure returns (string memory) {
        return "";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }

    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    function setValidator(address _validator) external authorized {
        require(_validator != address(0), "Invalid address");
        VALIDATOR = _validator;
    }

    /**
     * @dev receive deposit function
     */
    receive() external payable {
        deposit();
    }

    /**
     * @dev deposit into pool
     */
    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    /**
     * @dev withdraw from pool
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) external {
        require(_balances[msg.sender] >= amount, "Insufficient funds");
        _balances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @dev withdraw from pool; only callable by Minthree Validator
     * @param from sender
     * @param to recipient
     * @param amount Amount to withdraw
     */
    function safeWithdraw(address from, address to, uint256 amount) external returns (bool) {
        require(msg.sender == VALIDATOR, "Unauthorized transfer");
        require(_balances[from] >= amount, "Insufficient funds");
        _balances[from] -= amount;
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Transfer failed");
        emit Transfer(msg.sender, address(0), amount);
        return success;
    }
}