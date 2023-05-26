// SPDX-License-Identifier: MIT
// Non-Fungible Labs
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFLCreditsPurchase is Ownable {
  using SafeERC20 for IERC20;

  uint256 public creditsPerUSDC = 0.5 ether;
  IERC20 public asto = IERC20(0x823556202e86763853b40e9cDE725f412e294689);
  IERC20 public usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  uint8 public USDCDecimals = 6;
  uint256 public slippage = 103;
  bool public paused = false;

  IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  event PausedUpdated(bool indexed state);
  event USDCUpdated(address indexed newAddress, uint8 indexed newDecimals);
  event ASTOUpdated(address indexed newAddress);
  event SlippageUpdated(uint256 indexed newSlippage);
  event UniswapRouterUpdated(address indexed newAddress);
  event CreditsPerUSDCUpdated(uint256 indexed value);
  event ASTOWithdrawn(address indexed recipient, uint256 indexed amount);
  event ERC20Withdrawn(address indexed recipient, uint256 indexed amount);
  event PurchaseCredits(address indexed from, uint256 indexed astoAmount, uint256 indexed creditsAmount);

  constructor(IUniswapV2Router02 _uniswapRouter) {
    uniswapRouter = _uniswapRouter;
  }

  /* @dev: Updates the Uniswap V2 Router
   * @param: Contractaddress of Uni V2 Router
   */
  function updateRouter(IUniswapV2Router02 _address) external onlyOwner {
    uniswapRouter = _address;
    emit UniswapRouterUpdated({newAddress: address(_address)});
  }

  /* @dev: Updates the slippage percentage must be 105 106 ( 105 = 5% )
   * @param: Slippage percentage as a whole
   */
  function updateSlippage(uint256 _slippage) external onlyOwner {
    slippage = _slippage;
    emit SlippageUpdated({newSlippage: _slippage});
  }

  /* @dev: Pauses/unpauses purchases
   * @param: Paused state boolean
   */
  function setPaused(bool _state) external onlyOwner {
    paused = _state;
    emit PausedUpdated({state: _state});
  }

  /* @dev: Updates USDC contract referenced
   * @param: USDC contract address
   */
  function setUSDC(IERC20 _address) external onlyOwner {
    usdc = _address;
    (bool success, bytes memory data) = address(_address).staticcall(abi.encodeWithSelector(0x313ce567));
    require(success, "failed to call decimals() on USDC contract");

    USDCDecimals = abi.decode(data, (uint8));

    emit USDCUpdated({newAddress: address(_address), newDecimals: USDCDecimals});
  }

  /* @dev: Updates ASTO contract referenced
   * @param: ASTO contract address
   */
  function setASTO(IERC20 _address) external onlyOwner {
    asto = _address;
    emit ASTOUpdated({newAddress: address(_address)});
  }

  /* @dev: Sets the amount of credits you get per USDC
   * @param: Amount of credits (18 decimals)
   */
  function setCreditsPerUSDC(uint256 _amount) external onlyOwner {
    require(_amount > 0, "Credits per USDC cant be zero");
    creditsPerUSDC = _amount;
    emit CreditsPerUSDCUpdated({value: _amount});
  }

  /* @dev: Allows user to purchase credits with ASTO
   * @param: Amount of ASTO
   */
  function purchaseTokens(uint256 astoAmount) external {
    require(msg.sender == tx.origin, "contracts not allowed");
    require(!paused, "contract paused");
    require(astoAmount > 0, "asto cant be zero");
    require(asto.allowance(msg.sender, address(this)) >= astoAmount, "not enough allowance");
    asto.safeTransferFrom(msg.sender, address(this), astoAmount);
    uint256 credits = astoToCredits(astoAmount);
    require(credits > 0, "credits cant be zero");
    emit PurchaseCredits({from: msg.sender, astoAmount: astoAmount, creditsAmount: credits});
  }

  /* @dev: Returns amount of credits you get for X ASTO
   * @param: Amount of ASTO
   * @return: Amount of credits (18 decimals)
   */
  function astoToCredits(uint256 astoAmount) public view returns (uint256) {
    return usdcToCredits(astoUsdcPairPrice(astoAmount)[1]);
  }

  /* @dev: Returns raw amounts from Uniswap V2
   * @param: asto 18 decimals
   */
  function astoUsdcPairPrice(uint256 astoAmount) public view returns (uint256[] memory) {
    require(address(asto) != address(0), "ASTO Address not set");
    require(address(usdc) != address(0), "USDC Address not set");
    require(astoAmount > 0, "No need to query zero balance");
    uint256[] memory output = uniswapRouter.getAmountsOut(astoAmount, getPathForASTOtoUSDC());
    return output;
  }

  /* @dev: Returns amount of credits you get for X USDC
   * @param: Amount of USDC
   * @return: Amount of credits (18 decimals)
   */
  function usdcToCredits(uint256 usdcAmount) public view returns (uint256) {
    return (((usdcAmount * 100) / 10**USDCDecimals) * creditsPerUSDC) / 100;
  }

  /* @dev: Returns the amount of ASTO you need to get X credits
   * @param: Amount of credits (18 decimals)
   * @return: Amount of ASTO (18 decimals)
   */
  function creditsToAsto(uint256 creditsAmount) public view returns (uint256) {
    uint256[] memory oneAstoWorth = astoUsdcPairPrice(1 ether);
    uint256 oneAstoUSDC = oneAstoWorth[1];
    uint256 astoNeededForOneCredit = (((1000000 * 100) / oneAstoUSDC) * 2 * 10**18) / 100;
    uint256 priceOfCreditsInAsto = (((creditsAmount * 100) / 10**18) * astoNeededForOneCredit) / 100;

    return (priceOfCreditsInAsto / 100) * slippage;
  }

  /* @dev: Creates pair from ASTO/USDC
   */
  function getPathForASTOtoUSDC() internal view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = address(asto);
    path[1] = address(usdc);
    return path;
  }

  /* @dev: Withdraws the ASTO tokens to the recipient
   * @param: Walletaddress of the recipient
   */
  function withdrawAstoTokens(address recipient) external onlyOwner {
    uint256 amount = asto.balanceOf(address(this));
    asto.safeTransfer(recipient, amount);
    emit ASTOWithdrawn({recipient: recipient, amount: amount});
  }

  /* @dev: Withdraws any ERC20 token to the recipient
   * @param: Walletaddress of the recipient
   */
  function withdrawAnyErc20(address contractAddress, address recipient) external onlyOwner {
    uint256 amount = IERC20(contractAddress).balanceOf(address(this));
    IERC20(contractAddress).safeTransfer(recipient, amount);
    emit ERC20Withdrawn({recipient: recipient, amount: amount});
  }
}