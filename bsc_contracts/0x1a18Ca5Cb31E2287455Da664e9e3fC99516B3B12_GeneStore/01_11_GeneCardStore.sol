// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Interfaces.sol";

contract GeneStore is AccessControl {

    uint256 public constant CARD = 0;

    bytes32 public constant ROOT_ROLE = keccak256("ROOT");
    bytes32 public constant MANAGER = keccak256("MANAGER");
    address token;
    address geneCards;
    uint256 price;

    constructor(address _token, address _geneCards) {
        _setupRole(ROOT_ROLE, msg.sender);
        _setupRole(MANAGER, msg.sender);
        _setRoleAdmin(MANAGER, ROOT_ROLE);

        token = _token;
        geneCards = _geneCards;
        price = 5*(10**18);
    }

    function buy(uint _amount) public payable {
        // Set the minimum amount to 1 token (in this case I'm using LINK token)
        uint256 _minAmount = price * _amount;
        uint256 balance = IERC20(token).balanceOf(msg.sender);

        require(balance > _minAmount, "Insufficient balance");

        IERC20(token).transferFrom(msg.sender, address(this), _minAmount);
        IGeneCards(geneCards).dispenseSpecific(msg.sender, CARD, _amount);
    }

    function deposit() public onlyRole(MANAGER) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    function adjust_price(uint256 _price) public onlyRole(MANAGER) {
        price = _price;
    } 
}