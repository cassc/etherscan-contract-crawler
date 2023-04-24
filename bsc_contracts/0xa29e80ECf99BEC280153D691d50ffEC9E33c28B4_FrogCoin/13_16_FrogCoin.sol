pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IPancakeRouter.sol";
import "./interfaces/IPancakeFactory.sol";
import "./helpers/TransferHelpers.sol";

contract FrogCoin is Ownable, AccessControl, ERC20 {
  using SafeMath for uint256;

  address public taxCollector;

  bytes32 public taxExclusionPrivilege = keccak256(abi.encode("TAX_EXCLUSION_PRIVILEGE"));
  bytes32 public liquidityExclusionPrivilege = keccak256(abi.encode("LIQUIDITY_EXCLUSION_PRIVILEGE"));

  IPancakeRouter02 pancakeRouter;

  uint8 public taxPercentage;
  uint8 public liquidityPercentageForEcosystem = 8;
  uint256 public maxAmount = 10000000 * 10**18;
  uint256 public minHoldOfTokenForContract = 1200000 * 10**18;

  bool public swapAndLiquifyEnabled;
  bool public inSwapAndLiquify;

  modifier lockswap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 amount,
    address _taxCollector,
    uint8 _taxPercentage
  ) ERC20(name_, symbol_) {
    taxCollector = _taxCollector;
    taxPercentage = _taxPercentage;
    _mint(_msgSender(), amount);
    _grantRole(taxExclusionPrivilege, _msgSender());
    _grantRole(taxExclusionPrivilege, _taxCollector);
    pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    address pair = IPancakeFactory(pancakeRouter.factory()).createPair(pancakeRouter.WETH(), address(this));

    _grantRole(liquidityExclusionPrivilege, pair);
    _grantRole(liquidityExclusionPrivilege, address(pancakeRouter));
  }

  function _splitFeesFromTransfer(uint256 amount)
    internal
    view
    returns (
      uint256 forHolders,
      uint256 forPools,
      uint256 forTaxCollector
    )
  {
    uint256 totalTaxValue = amount.mul(uint256(taxPercentage)).div(100);
    forHolders = totalTaxValue.div(3);
    forPools = totalTaxValue.div(3);
    forTaxCollector = totalTaxValue.div(3);
  }

  function _swapAndLiquify(uint256 amount) private lockswap {
    uint256 half = amount.div(2);
    uint256 otherHalf = amount.sub(half);
    uint256 initialETHBalance = address(this).balance;

    _swapThisTokenForEth(half);

    uint256 newETHBalance = address(this).balance.sub(initialETHBalance);

    // Ecosystem's fee
    uint256 ecosystemFee = newETHBalance.mul(liquidityPercentageForEcosystem).div(100);
    uint256 etherForLiquidity = newETHBalance.sub(ecosystemFee);

    if (ecosystemFee > 0) TransferHelpers._safeTransferEther(taxCollector, ecosystemFee);
    _addLiquidity(otherHalf, etherForLiquidity);
  }

  function _addLiquidity(uint256 tokenAmount, uint256 etherAmount) private {
    _approve(address(this), address(pancakeRouter), tokenAmount);

    pancakeRouter.addLiquidityETH{value: etherAmount}(
      address(this),
      tokenAmount,
      0,
      0,
      address(this),
      block.timestamp.add(60 * 20)
    );
  }

  function _swapThisTokenForEth(uint256 amount) private {
    _approve(address(this), address(pancakeRouter), amount);

    IPancakeFactory factory = IPancakeFactory(pancakeRouter.factory());
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = pancakeRouter.WETH();

    if (IERC20(pancakeRouter.WETH()).balanceOf(factory.getPair(address(this), pancakeRouter.WETH())) > 0)
      pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
        amount,
        0,
        path,
        address(this),
        block.timestamp.add(60 * 20)
      );
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20) {
    if ((from != owner() && from != taxCollector) && (to != owner() && to != taxCollector))
      require(amount <= maxAmount, "transfer_amount_cannot_exceed_max_amount");

    if (!hasRole(taxExclusionPrivilege, from) && from != address(this)) {
      (uint256 forHolders, uint256 forPools, uint256 forTaxCollector) = _splitFeesFromTransfer(amount);
      uint256 perHolder = forHolders.div(2);

      uint256 tBalance = balanceOf(address(this));

      if (tBalance >= maxAmount) tBalance = maxAmount;

      bool isMinTokenBalance = tBalance >= minHoldOfTokenForContract;

      if (
        !hasRole(liquidityExclusionPrivilege, from) && isMinTokenBalance && !inSwapAndLiquify && swapAndLiquifyEnabled
      ) _swapAndLiquify(tBalance);

      super._transfer(from, to, amount.sub(forHolders + forPools + forTaxCollector).add(perHolder));
      super._transfer(from, from, perHolder);
      super._transfer(from, address(this), forPools);
      super._transfer(from, taxCollector, forTaxCollector);
    } else {
      super._transfer(from, to, amount);
    }
  }

  function setTaxPercentage(uint8 _taxPercentage) external onlyOwner {
    taxPercentage = _taxPercentage;
  }

  function setLiquidityPercentageForEcosystem(uint8 _lpPercentage) external onlyOwner {
    liquidityPercentageForEcosystem = _lpPercentage;
  }

  function setMaxAmount(uint256 _max) external onlyOwner {
    maxAmount = _max;
  }

  function switchSwapAndLiquifyEnabled() external onlyOwner {
    swapAndLiquifyEnabled = !swapAndLiquifyEnabled;
  }

  function setTaxCollector(address _taxCollector) external onlyOwner {
    _revokeRole(taxExclusionPrivilege, taxCollector);
    taxCollector = _taxCollector;
    _grantRole(taxExclusionPrivilege, _taxCollector);
  }

  function setPancakeRouter(address router) external onlyOwner {
    pancakeRouter = IPancakeRouter02(router);
  }

  function setMinHoldOfTokenForContract(uint256 minHold) external onlyOwner {
    minHoldOfTokenForContract = minHold;
  }

  function excludeFromPayingTax(address account) external onlyOwner {
    require(!hasRole(taxExclusionPrivilege, account), "already_excluded_from_paying_tax");
    _grantRole(taxExclusionPrivilege, account);
  }

  function includeInTaxPayment(address account) external onlyOwner {
    require(hasRole(taxExclusionPrivilege, account), "already_pays_tax");
    _revokeRole(taxExclusionPrivilege, account);
  }

  function retrieveEther(address to) external onlyOwner {
    TransferHelpers._safeTransferEther(to, address(this).balance);
  }

  function retrieveERC20(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    TransferHelpers._safeTransferERC20(token, to, amount);
  }

  receive() external payable {}
}