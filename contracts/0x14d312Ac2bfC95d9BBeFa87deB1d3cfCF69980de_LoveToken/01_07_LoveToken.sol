// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract LoveToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Love", "Love") {
      authorise(_msgSender(), true);
    }
    
    event Authorise(address indexed addressToAuth, bool isAuthorised);
    mapping (address => bool) private _authorised;

    modifier onlyAuthorised {
      require(_authorised[_msgSender()], "Not authorised");
      _;
    }

    function mint(address mintTo, uint256 amount) external onlyAuthorised {
      _mint(mintTo, amount);
    }

    function authorise(address _addressToAuth, bool _isAuthorised) public onlyOwner {
      _authorised[_addressToAuth] = _isAuthorised;
      emit Authorise(_addressToAuth, _isAuthorised);
    }
}