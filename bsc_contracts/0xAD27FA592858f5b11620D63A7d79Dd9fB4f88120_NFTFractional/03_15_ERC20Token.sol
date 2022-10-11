// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract ERC20Token is ERC20Upgradeable {

  address private owner;
  constructor(string memory _name, string memory _symbol) initializer {
    __ERC20_init(_name, _symbol);
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "ERC20Token: Only controllers");
    _;
  }

  function mintERC20(address _curator, uint256 _supply) external onlyOwner {
    _mint(_curator, _supply);
  }

  function burnFrom(address account, uint256 amount) public onlyOwner {
    // _spendAllowance(_msgSender(),account, amount);
    _burn(account, amount);
  }

  function decimals() public view virtual override returns (uint8) {
    return 8;
  }
  
}