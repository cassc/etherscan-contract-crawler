// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IKochiLock.sol";

// Uniswap V2
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IUniswapV2Factory.sol";

// DEV ENVIRONMENT ONLY
// hardhat tools
// DEV ENVIRONMENT ONLY
// import "hardhat/console.sol";

contract Kochi is Context, ERC20, ERC20Burnable, Ownable, Pausable, ReentrancyGuard {
  mapping(address => bool) public whitelist;
  IUniswapV2Router02 public router;
  IERC20 baseValueToken; // to be USDT
  IKochiLock public kochiLock;

  // number of blocks from the startingBlock until transactions are not flagged as being botted.
  uint256 botLimit = 10;
  uint256 startingBlock;
  mapping(address => bool) public bots;

  // tax can only be decreased.
  // calculated as per mille (0/00 or ‰)
  uint16 public tax = 100; // 10.0% (including 2% to the liquidity provider)
  uint16 public botTax = 200; // 20.0%
  uint16 public liquidity = 200; // 20.0% of the tax (2%)
  address public taxWallet; // tax wallet is a gnosis multisig
  uint256 public taxThreshold = 100 * 10**16; // threshold before the tax is applied; this allows small transaction to not pay the gas for the tax swaps

  uint256 private taxable;

  constructor(
    address tax_wallet,
    address _router,
    address _base_value_token,
    address _kochi_lock
  ) ERC20("KOCHI", "KOCHI") {
    // cannot mint more than the total supply. (total supply is constant)
    _mint(msg.sender, 1000000000 * 10**18);

    taxWallet = tax_wallet;

    // setup the router
    router = IUniswapV2Router02(_router);
    _approve(address(this), _router, 2**256 - 1);

    baseValueToken = IERC20(_base_value_token);
    baseValueToken.approve(address(router), 2**256 - 1);

    kochiLock = IKochiLock(_kochi_lock);

    _pause(); // the contract should be paused by default.

    whitelist[taxWallet] = true;
    whitelist[msg.sender] = true;
    whitelist[address(this)] = true;
  }

  //////////////////////////////////////////////////////////////////////////////
  // OVERRIDES
  //////////////////////////////////////////////////////////////////////////////

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    address uniswap_pair = IUniswapV2Factory(router.factory()).getPair(address(baseValueToken), address(this));

    // is whitelisted, is to the contract, or is pair not initialized
    if (whitelist[from] || to == address(this) || uniswap_pair == address(0)) return super._transfer(from, to, amount);

    require(!paused(), "ERROR: The token is currently paused for maintenance.");

    // set the bot flag if the sender is detected as being a bot.
    if (block.number < botLimit + startingBlock) {
      bots[from] = true; // CKK-03
    }

    uint256 remainder = amount;

    // since the tax is the same both ways, no need to check if the user is a buyer or a seller on another pair/dex.
    bool buyer = from == uniswap_pair && to != address(router); // CKK-06

    if (tax != 0) remainder = payTaxes(amount, buyer, buyer ? to : from);

    super._transfer(from, to, remainder); // transfer the amount after having paid the taxes paying the taxes.
  }

  //////////////////////////////////////////////////////////////////////////////
  // FEE FUNCTIONS
  //////////////////////////////////////////////////////////////////////////////

  function payTaxes(
    uint256 amount,
    bool buyer,
    address from
  ) private nonReentrant returns (uint256 remainder) {
    uint256 _tax = bots[from] ? botTax : tax;
    if (_tax == 0) return amount; // no tax

    uint256 total_taxed_amount = (amount * _tax) / 1000;

    // transfer all of the tax money to this contract.
    super._transfer(from, address(this), total_taxed_amount);
    taxable += total_taxed_amount;

    // some transactions will revert because of a loop. (e.g. when the user buys)
    if (buyer || taxThreshold > amount) return buyer ? amount : amount - total_taxed_amount;

    // performs a multiplication on the result of a division. should be safe though, the most lost should be one token (1e-18) due to solidity rounding down.
    uint256 liquidity_tokens = (taxable * liquidity) / 1000;
    uint256 half_liquidity_tokens = liquidity_tokens / 2;

    // swap most of the tax tokens to base value (ex: USDT), but keep half the autolp to strenghen both LPs of the pair proportionately.
    _swapForBase(taxable - half_liquidity_tokens);

    // 50% of the liquidity in tokens, 50% in base value (ex: USDT)
    if (liquidity != 0) _addLiquidity(half_liquidity_tokens, (baseValueToken.balanceOf(address(this)) * half_liquidity_tokens) / taxable);

    // balance should now be lower, the rest goes to the tax wallet
    SafeERC20.safeTransfer(baseValueToken, taxWallet, baseValueToken.balanceOf(address(this)));
    // return the remainder

    // the buyer is because we can't interact with uniswap formula of K
    // if the user is selling, we remove the tax before it gets to the user. else we remove the tax after it gets to the user.
    taxable = 0;

    return buyer ? amount : amount - total_taxed_amount;
  }

  function _swapForBase(uint256 amount) private {
    require(amount > 0, "ERROR: Amount must be greater than 0.");

    // the first instinct would be to do a swapExactTokensForTokens, but UniswapV2Pair swap prohibits the receipient to be one of the tokens in the path.
    // https://github.com/Uniswap/v2-core/blob/ee547b17853e71ed4e0101ccfd52e70d5acded58/contracts/UniswapV2Pair.sol#L169

    // this isn't the case when going from token to ETH, as the swap happens first in the router, then a call to WETH with the receipient being this contract.
    // this allows us to then buy the USDT token using the ETH token.
    // another way to do this would be to have a second contract that receives and immediately sends the tokens here. however this solution would be even dirtier.

    // Kochi -> USDT -> ETH -> USDT
    // realistic loss of value should be only due to price impact. around 1% of the value sent.

    address[] memory path0 = new address[](3);
    path0[0] = address(this);
    path0[1] = address(baseValueToken);
    path0[2] = router.WETH();
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, (amount * 8) / 10, path0, address(this), block.timestamp); // CKK-04

    address[] memory path1 = new address[](2);
    path1[0] = router.WETH();
    path1[1] = address(baseValueToken);

    router.swapExactETHForTokens{value: address(this).balance}((address(this).balance * 8) / 10, path1, address(this), block.timestamp + 60); // CKK-04
  }

  function _addLiquidity(uint256 tokenAmount, uint256 baseAmount) private {
    // add the liquidity
    router.addLiquidity(
      address(baseValueToken),
      address(this),
      tokenAmount,
      baseAmount,
      (tokenAmount * 8) / 10, // CKK-04 - slippage is unavoidable
      (baseAmount * 8) / 10, // CKK-04 - slippage is unavoidable
      address(this), // CKK-02
      block.timestamp
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // ADMIN
  //////////////////////////////////////////////////////////////////////////////

  function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
    // CKK-05
    require(tokenAddress != address(this), "ERROR: Cannot recover the native token.");
    IERC20(tokenAddress).transfer(taxWallet, tokenAmount);
  }

  function recoverETH(uint256 amount) external onlyOwner {
    // CKK-05
    payable(taxWallet).transfer(amount);
  }

  function setTaxThreshold(uint256 tax_threshold) external onlyOwner {
    taxThreshold = tax_threshold;
  }

  // CKK-02
  function releaseAndLockLP() external onlyOwner {
    require(address(kochiLock) != address(0), "ERROR: The lock contract is not set.");

    // lock the lp tokens for 48 hours with the taxWallet as beneficiary
    IERC20 lpToken = IERC20(IUniswapV2Factory(router.factory()).getPair(address(baseValueToken), address(this)));
    lpToken.approve(address(kochiLock), lpToken.balanceOf(address(this)));
    IKochiLock(kochiLock).lock(address(lpToken), lpToken.balanceOf(address(this)), taxWallet, block.timestamp + 48 hours);
  }

  // CKK-02
  function setLockContract(address lock) external onlyOwner {
    kochiLock = IKochiLock(lock);
  }

  function setRouter(address _router) external onlyOwner {
    router = IUniswapV2Router02(_router);
    _approve(address(this), _router, 2**256 - 1);
    baseValueToken.approve(address(router), 2**256 - 1);
  }

  function setBaseValueToken(address _base_value_token) external onlyOwner {
    // used for auto LP adder
    baseValueToken = IERC20(_base_value_token);

    // is it a valid ERC20 ?
    baseValueToken.balanceOf(address(this)); // this should revert if not a token.

    baseValueToken.approve(address(router), 2**256 - 1);
  }

  function setTaxWallet(address _taxWallet) external onlyOwner {
    taxWallet = _taxWallet;
  }

  function setBlockLimit(uint256 bot_limit) external onlyOwner {
    require(bot_limit <= 200, "ERROR: Bot limit must be less than 200."); // block time 3s, 200 blocks = 10 minutes (max)
    botLimit = bot_limit;
  }

  function setWhitelisted(address addr, bool is_whitelisted) external onlyOwner {
    whitelist[addr] = is_whitelisted;
  }

  function setArrayWhitelisted(address[] calldata addrs, bool is_whitelisted) external onlyOwner {
    for (uint256 i = 0; i < addrs.length; i++) {
      whitelist[addrs[i]] = is_whitelisted;
    }
  }

  function decreaseTax(uint16 new_tax) external onlyOwner {
    require(new_tax < tax, "new tax must be less than current tax");
    tax = new_tax;
  }

  function setLiquidityPercent(uint16 new_tax) external onlyOwner {
    require(new_tax <= 1000, "new tax must be less or equal to 100% of the tax");
    liquidity = new_tax;
  }

  function decreaseBotTax(uint16 new_bot_tax) external onlyOwner {
    require(new_bot_tax < botTax, "new bot tax must be less than current bot tax");
    botTax = new_bot_tax;
  }

  // contract can only be unapused, not paused. (it is paused by default)
  function unpause() external onlyOwner whenPaused {
    super._unpause();

    // set the starting block bot the antibot (ONLY ONCE)
    if (startingBlock == 0) startingBlock = block.number;
  }

  receive() external payable {}
}