// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./MrLiquidity.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/ISwapFactory.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MrT is ERC20, Ownable  {

  mapping(string => mapping(address => bool)) public _taxList;
  uint32 public _taxPercision = 10000;
  uint16 public _tax = 300;
  bool public _taxActive;

  uint256 private _totalSupply;

  address public TAddress = 0x6967299e9F3d5312740Aa61dEe6E9ea658958e31;
  address public uniswapAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  address public routerAddress = uniswapAddress;
  uint256 minTokensBeforeSwap = 0;

  address public lpAddress;

  MrLiquidity public mrLiquidity;

  /* Events */
  event RemoveFromTaxList(string list, address indexed wallet);
  event AddToTaxList(string list, address indexed wallet);
  event UpdateTaxPercentage(uint16 _newTaxAmount);
  event MinSwapTokensChanged(uint256 amount);
  event ToggleTax(bool _active);

  ISwapRouter public router = ISwapRouter(routerAddress);
  IERC20 public T = IERC20(TAddress);
  bool inSwap;

  event SwapUpdated(bool enabled);
  event Swap(uint256 swaped, uint256 recieved);

  modifier lockTheSwap() {
    inSwap = true;
    _;
    inSwap = false;
  }

  constructor(address mrLiqidityAddress) ERC20('Mr. T', 'MR') {
    mrLiquidity = MrLiquidity(mrLiqidityAddress);
    _totalSupply = 1000000000 * (10**18);
    approveRouterSpending();

    _mint(msg.sender, _totalSupply);
    _taxActive = true;
  }

  function setLPAddress() public onlyOwner {
    if (lpAddress == address(0)) {
      lpAddress = ISwapFactory(router.factory()).getPair(TAddress, address(this));
      addToTaxList('from', lpAddress);
      addToTaxList('to', lpAddress);
    }
  }

  /**
  * @notice overrides ERC20 transferFrom function to introduce tax functionality
  * @param from address amount is coming from
  * @param to address amount is going to
  * @param amount amount being sent
  */
  function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    return taxedTransfer(from, to, amount);
  }

  /**
  * @notice : overrides ERC20 transfer function to introduce tax functionality
  * @param to address amount is going to
  * @param amount amount being sent
  */
  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    return taxedTransfer(_msgSender(), to, amount);
  }


  function taxedTransfer(address from, address to, uint256 amount) private returns (bool) {
    require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");
    if(!inSwap && _taxActive && (_taxList['from'][from] || _taxList['to'][to])) {
      uint256 tax = amount * _tax / _taxPercision;
      amount = amount - tax;
      _transfer(from, address(this), tax);

      // Swapping taxes for T fails on buys with the same LP pair address.
      // So we only swap the taxes for T on sells and when using other DEXs.
      if (lpAddress != from) _swap();
    }
    _transfer(from, to, amount);
    return true;
  }

  function _swap() internal lockTheSwap {
    if (minTokensBeforeSwap > balanceOf(address(this))) return;

    address[] memory sellPath = new address[](2);
    sellPath[0] = address(this);
    sellPath[1] = TAddress;

    uint256 tokensBefore = balanceOf(address(this));
    uint256 TBalanceBefore = T.balanceOf(address(this));

    _transfer(address(this), address(mrLiquidity), tokensBefore / 2);
    router.swapExactTokensForTokens(
      tokensBefore / 2,
      0,
      sellPath,
      address(mrLiquidity),
      block.timestamp
    );

    emit Swap(tokensBefore, T.balanceOf(address(this)) - TBalanceBefore);

    mrLiquidity.addLiquidity();
  }

  function approveRouterSpending() internal {
    _approve(address(this), address(router), type(uint256).max);
    T.approve(address(router), type(uint256).max);
  }

  /**
  * @notice : toggles tax on or off
  */
  function toggleTax() external onlyOwner {
    _taxActive = !_taxActive;
    emit ToggleTax(_taxActive);
  }

  /**
  * @notice : updates min tokens before swap
  * @param amount new min amount
  */
  function setMinTokensBeforeSwap(uint256 amount) external onlyOwner {
    minTokensBeforeSwap = amount;
    emit MinSwapTokensChanged(amount);
  }

  /**
  * @notice : updates address tax amount
  * @param newTax new tax amount
  */
  function setTax(uint16 newTax) external onlyOwner {
    require(newTax <= 8 * _taxPercision / 100, 'Tax can not be set to more than 8%');

    _tax = newTax;
    emit UpdateTaxPercentage(newTax);
  }

  /**
   * @notice : add address to tax taxList
   * @param wallet address to add to taxList
   */
  function addToTaxList(string memory list, address wallet) public onlyOwner {
    require(wallet != address(0), "Cant use 0 address");
    require(!_taxList[list][wallet], "Address already added");
    _taxList[list][wallet] = true;

    emit AddToTaxList(list, wallet);
  }

  /**
   * @notice : remoe address from a taxList
   * @param list indicates which taxList ('to' or 'from')
   * @param wallet address to remove from taxList
   */
  function removeFromTaxList(string memory list, address wallet) external onlyOwner {
    require(wallet != address(0), "Cant use 0 address");
    require(_taxList[list][wallet], "Address not added");
    _taxList[list][wallet] = false;

    emit RemoveFromTaxList(list, wallet);
  }
}