// SPDX-License-Identifier: MIT

pragma solidity >=0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract E_BRC20 is ERC20, ERC20Burnable, Ownable {
  event Inscribe(address indexed to, uint256 amount);
  event InscribeFinished();

  using SafeMath for uint256;
  mapping(address => uint256) private _balances;
  mapping(address => bool) controllers;
  uint256 private _totalSupply;
  uint256 private MAXSUP;
  uint256 public MAXIMUMSUPPLY; 
  uint256 public LimitPerMint;
  bool public inscribingFinished = false;

  constructor(string memory _ticker, uint256 _supply, uint256 _limitPerMint) ERC20(_ticker, _ticker) { 
      MAXIMUMSUPPLY = _supply;
      LimitPerMint = _limitPerMint;
  }

  modifier canInscribe() { require(!inscribingFinished); _; }

  function inscribe(address to, uint256 amount) canInscribe external {
    require((MAXSUP + amount) <= MAXIMUMSUPPLY, "Maximum supply has been reached");
    require(amount <= LimitPerMint, "Maximum Batch size has been reached");

    _totalSupply = _totalSupply.add(amount);
    MAXSUP = MAXSUP.add(amount);
    _balances[to] = _balances[to].add(amount);
    _mint(to, amount);
    emit Inscribe(to, amount);
  }

  function finishInscribing() onlyOwner public returns(bool success) {
        inscribingFinished = true;
        emit InscribeFinished();
        return true;
    }
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }
}