// SPDX-License-Identifier: MIT LICENSE


/*
Collect, trade, stake and earn SEMI with your TRUCK NFTs!!
Twitter: @RowdyUnicorns
*/

pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ShippingEquipmentMaterializingIncome is ERC20, ERC20Burnable, Ownable {
  using SafeMath for uint256;

  
  mapping(address => uint256) private _balances;
  mapping(address => bool) controllers;

  uint256 public percentage;
  uint256 private _totalSupply;
  uint256 private MAXSUP;
  uint256 constant MAXIMUMSUPPLY=100000000000*10**18;

  constructor() ERC20("Shipping Equipment Materializing Income", "SEMI") { 
      _mint(msg.sender, 100000 * 10 ** 18);

  }

  function setPercentageFee(uint256 fee) external onlyOwner {
    percentage = fee;
  }

  function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) { 
    uint256 percentageFee = (amount.mul(percentage)).div(10000);
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    uint256 total = amount.sub(percentageFee);
    transfer(address(this), percentageFee);
    transfer(to ,total);
    return true;
  }


  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    require((MAXSUP+amount)<=MAXIMUMSUPPLY,"Maximum supply has been reached");
    _totalSupply = _totalSupply.add(amount);
    MAXSUP=MAXSUP.add(amount);
    _balances[to] = _balances[to].add(amount);
    _mint(to, amount);
  }

  function burnFrom(address account, uint256 amount) public override {
      if (controllers[msg.sender]) {
          _burn(account, amount);
      }
      else {
          super.burnFrom(account, amount);
      }
  }

  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
  
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  function maxSupply() public  pure returns (uint256) {
    return MAXIMUMSUPPLY;
  }

}