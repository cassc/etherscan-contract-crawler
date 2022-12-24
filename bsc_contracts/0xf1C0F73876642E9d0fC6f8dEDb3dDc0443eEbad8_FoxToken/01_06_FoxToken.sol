// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FoxToken is Ownable, ERC20 {
    mapping (address => bool) internal operator;

    modifier onlyOperator {
        require(isOperator(msg.sender), "Only operator can perform this action");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20 (_name, _symbol) {
        operator[msg.sender] = true;
    }

    function mint(address _to, uint256 _amount) external onlyOperator{
        _mint(_to, _amount);

        emit Mint(_to, _amount);
    }

    function setOperator(address _userAddress, bool _bool) external onlyOwner {
        require(_userAddress != address(0), "Address zero");
        operator[_userAddress] = _bool;

        emit SetOperator(_userAddress, _bool);
    }

    function isOperator(address _userAddress) public view returns(bool) {
        return operator[_userAddress];
    }

    event Mint(address _to, uint256 _amount);
    event SetOperator(address _userAddress, bool _bool);
}