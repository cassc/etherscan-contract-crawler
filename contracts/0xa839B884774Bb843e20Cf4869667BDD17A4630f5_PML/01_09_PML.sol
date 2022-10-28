// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Utils.sol";

contract PML is Ownable, Mintable, Burnable, ERC20 {

    ILocker private locker;
    constructor() ERC20("Prime Meta Token", "PML") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }

    function setLocker(address _locker) public onlyOwner {
        locker = ILocker(_locker);
    }

    function mint(address account, uint256 amount) public onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyBurner {
        _burn(account, amount);
    }

    function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    // check lock before transfer
    if (address(locker) != address(0)) {
        if (locker.isLocked(sender, balanceOf(sender) - amount))
            revert("Your token has been locked");
    }
    return ERC20._transfer(sender, recipient, amount);
  }

  function getLocker() public view returns (address){
      return address(locker);
  }

}