// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Token is ERC20, Ownable {

  address factory;
  bool locked;

  modifier onlyFactory {
		require(_msgSender() == factory, "Only factory can call this."); _;
	}

  constructor(
    address owner_,
    string memory _name,
    string memory _symbol,
    uint totalSupply_,
    uint amountSender
  ) ERC20(_name, _symbol) {
    factory = msg.sender;

    _mint(owner_, totalSupply_ - amountSender);
    _mint(_msgSender(), amountSender);

    transferOwnership(owner_);
  }

  function burn(uint amount) onlyOwner external {
    _burn(_msgSender(), amount);
  }

  function lock(bool _locked) onlyFactory external {
    locked = _locked;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);
    require(!locked, "Token is locked.");
  }

}