// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/Address.sol";
import "@openzeppelin/[email protected]/token/ERC20/utils/SafeERC20.sol";
import "./Storage.sol";

contract Proxy is Ownable {
    using SafeERC20 for IERC20;

    event ERC20Transaction(address coin, address target, address sender, uint amount, bytes data, bytes result);

    Storage private st;

    mapping (address => bool) private blockedAddresses;

    constructor(address payable storageAddress) {
        st = Storage(storageAddress);
    }

    function blockAddress(address target) external onlyOwner {
        require(!blockedAddresses[target], "[WPROXY] address already blocked");
        blockedAddresses[target] = true;
    }

    function unBlockAddress(address target) external onlyOwner {
        require(blockedAddresses[target], "[WPROXY] address already unblocked");
        blockedAddresses[target] = false;
    }

    function checkAddressBlock(address target) external view onlyOwner returns (bool) {
        return blockedAddresses[target];
    }

    function updateStorage(address payable storageAddress) external onlyOwner {
        require(address(st) != storageAddress, "[WPROXY] storage already set");
        st = Storage(storageAddress);
    }

    function proxy(address coin, address target, uint amount, bytes calldata data) payable external returns (bytes memory) {
        require(Address.isContract(target), "[WPROXY] target address must be smartcontract");
        require(!blockedAddresses[target], "[WPROXY] target address blocked");

        require(st.checkAccess(msg.sender) == true, "[WPROXY] sender is not allowed");

        IERC20(coin).safeApprove(target, amount);

        bytes memory result = Address.functionCallWithValue(target, data, msg.value, "[WPROXY] operation failed by unknown reason");

        emit ERC20Transaction(coin, target, msg.sender, amount, data, result);

        return result;
    }

    function transferTokens(address coin, address to, uint amount) external onlyOwner {
        return IERC20(coin).safeTransfer(to, amount);
    }

    function transferETH(address payable to, uint amount) external onlyOwner {
        Address.sendValue(to, amount);
    }
}