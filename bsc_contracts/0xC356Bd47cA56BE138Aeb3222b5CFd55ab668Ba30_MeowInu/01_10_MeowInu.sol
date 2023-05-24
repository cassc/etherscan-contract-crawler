// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract MeowInu is Context, IERC20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  address public router;
  address public basePair;

  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) private _isExcludedFromDevFee;
  mapping(address => bool) private _isExcludedFromMaxAmount;
  mapping(address => bool) private _isDevWallet;

  address[] private _excluded;
  address public _devWalletAddress;

  uint256 private _tTotal;

  uint256 public _devFee;
  uint256 private _previousDevFee = _devFee;

  uint256 public _maxTxAmount;
  uint256 public _maxHeldAmount;

  IUniswapV2Router02 public uniswapV2Router;
  IUniswapV2Pair public uniswapV2Pair;

  constructor(
    address tokenOwner,
    address devWalletAddress_,
    address _router,
    address _basePair
  ) {
    _name = "MeowInu";
    _symbol = "MEOWINU";
    _decimals = 18;
    _tTotal = 1000000000 * 10 ** _decimals;
    _tOwned[tokenOwner] = _tTotal;

    _devFee = 4;
    _devWalletAddress = devWalletAddress_;

    _maxHeldAmount = _tTotal.mul(50).div(1000); // 2%
    _maxTxAmount = _maxHeldAmount;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
    // Create a uniswap pair for this new token
    uniswapV2Pair = IUniswapV2Pair(
      IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
        address(this),
        _basePair
      )
    );

    // set the rest of the contract variables
    uniswapV2Router = _uniswapV2Router;
    _isExcludedFromDevFee[owner()] = true;
    _isExcludedFromDevFee[address(this)] = true;
    _isExcludedFromDevFee[_devWalletAddress] = true;

    _isExcludedFromMaxAmount[owner()] = true;
    _isExcludedFromMaxAmount[address(this)] = true;
    _isExcludedFromMaxAmount[_devWalletAddress] = true;

    //set wallet provided to true
    _isDevWallet[_devWalletAddress] = true;

    emit Transfer(address(0), tokenOwner, _tTotal);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _tOwned[account];
  }

  function getBasePairAddr() public view returns (address) {
    return basePair;
  }

  function transfer(
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(
    address _owner,
    address spender
  ) public view override returns (uint256) {
    return _allowances[_owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
  ) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  function increaseAllowance(
    address spender,
    uint256 addedValue
  ) public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  ) public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
    return true;
  }

  function excludeFromMaxAmount(address account) public onlyOwner {
    require(!_isExcludedFromMaxAmount[account], "Account is already excluded");
    _isExcludedFromMaxAmount[account] = true;
  }

  function includeInMaxAmount(address account) public onlyOwner {
    require(_isExcludedFromMaxAmount[account], "Account is already included");
    _isExcludedFromMaxAmount[account] = false;
  }

  receive() external payable {}

  function _getValues(uint256 tAmount) private view returns (uint256, uint256) {
    uint256 tDev = calculateDevFee(tAmount);
    uint256 tTransferAmount = tAmount.sub(tDev);
    return (tTransferAmount, tDev);
  }

  function _takeDev(uint256 tDev) private {
    _tOwned[_devWalletAddress] = _tOwned[_devWalletAddress].add(tDev);
  }

  function calculateDevFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_devFee).div(10 ** 2);
  }

  function isExcludedFromMaxAmount(address account) public view returns (bool) {
    return _isExcludedFromMaxAmount[account];
  }

  function _approve(address _owner, address spender, uint256 amount) private {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[_owner][spender] = amount;
    emit Approval(_owner, spender, amount);
  }

  function _transfer(address from, address to, uint256 amount) private {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    // Only limit max TX for swaps, not for standard transactions
    if (from == address(uniswapV2Router) || to == address(uniswapV2Router)) {
      if (!_isExcludedFromMaxAmount[from] && !_isExcludedFromMaxAmount[to])
        require(
          amount <= _maxTxAmount,
          "Transfer amount exceeds the maxTxAmount."
        );
    }

    if (!_isExcludedFromMaxAmount[to]) {
      require(
        _tOwned[to].add(amount) <= _maxHeldAmount,
        "Recipient already owns maximum amount of tokens."
      );
    }

    //transfer amount, it will take dev, liquidity fee
    _tokenTransfer(from, to, amount);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> WHT
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = getBasePairAddr();

    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: ETHAmount }(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      DEAD,
      block.timestamp
    );
  }

  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    (uint256 tTransferAmount, uint256 tDev) = _getValues(amount);
    _tOwned[sender] = _tOwned[sender].sub(amount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _takeDev(tDev);

    emit Transfer(sender, recipient, tTransferAmount);
  }
}