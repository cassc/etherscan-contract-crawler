pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LaunchRestrictToken.sol";

contract PBXToken is Ownable, LaunchRestrictToken, ERC20Burnable {
  string private constant _name = "Paribus";
  string private constant _symbol = "PBX";

  constructor(uint256 initialSupply)
    public
    ERC20(_name, _symbol)
    LaunchRestrictToken()
  {
    _mint(owner(), initialSupply);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override launchRestrict(sender) {
    ERC20._transfer(sender, recipient, amount);
  }
}