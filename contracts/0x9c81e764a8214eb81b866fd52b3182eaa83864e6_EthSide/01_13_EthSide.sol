//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";


contract EthSide is AccessControl, Pausable, Multicall {
    
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 public constant DRAINER_ROLE = keccak256("DRAINER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UNPAUSER_ROLE, msg.sender);
        _grantRole(DRAINER_ROLE, msg.sender);
    }

    event Lock(address to, uint256 amount, bytes32 symbol, uint256 timestamp);

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }

    function lock(bytes32 symbol, uint256 timestamp) public payable whenNotPaused {
        require(msg.value > 0, "Cannot transfer 0");
        //TODO accepted symbols
        emit Lock(msg.sender, msg.value, symbol, timestamp);
    }

    function drain(address recipient, uint256 amount) external onlyRole(DRAINER_ROLE) {
        payable(recipient).transfer(amount);
    }

    function drainToken(IERC20 _token, address recipient, uint256 amount) public onlyRole(DRAINER_ROLE) {
        _token.transfer(recipient, amount);
    }
}