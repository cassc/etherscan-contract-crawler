// SPDX-License-Identifier: MIT
// Version 1.0.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Game is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ACCOUNTANT_ROLE = keccak256("ACCOUNTANT_ROLE");

    mapping(string => address) public mapTokenToContractAddress;
    event onDeposit(string _token, uint256 _quantity, address _from);
    event onWithdraw(string _token, uint256 _quantity, address _to);

    constructor(address _adminAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, _adminAddress);
        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ACCOUNTANT_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function AddTokenAndAddress(string memory _token, address _contractAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mapTokenToContractAddress[_token] = _contractAddress;
    }

    function deposit(string memory _token, uint256 _quantity) external {
        require(_quantity > 0, "quantity must be greater than 0");
        require(
            mapTokenToContractAddress[_token] != address(0x00),
            "token is not added"
        );
        IERC20 contractAddr = IERC20(mapTokenToContractAddress[_token]);
        contractAddr.transferFrom(msg.sender, address(this), _quantity);
        emit onWithdraw(_token, _quantity, msg.sender);
    }

    function withdraw(
        string memory _token,
        uint256 _quantity,
        address _to
    ) external whenNotPaused onlyRole(ACCOUNTANT_ROLE) {
        require(_quantity > 0, "quantity must be greater than 0");
        require(
            mapTokenToContractAddress[_token] != address(0x00),
            "token is not added"
        );
        IERC20 contractAddr = IERC20(mapTokenToContractAddress[_token]);
        contractAddr.transfer(_to, _quantity);
        emit onWithdraw(_token, _quantity, _to);
    }
}