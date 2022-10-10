// SPDX-License-Identifier: BUSL-1.1-COPYCAT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./lib/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICopycatAdapter.sol";
import "./interfaces/ICopycatPlugin.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IWETH.sol";

import "./CopycatLeaderFactory.sol";
import "./CopycatLeaderStorage.sol";
import "./lib/CopycatEmergency.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// CopycatLeader is the main contract for controlling Master fund
contract CopycatLeader is ERC20('', ''), CopycatEmergency, ReentrancyGuard {
  using SafeERC20 for IERC20;

  event ApproveToken(address indexed token, address indexed spender, uint256 amount);

  address private _owner;

  CopycatLeaderFactory public factory;
  CopycatLeaderStorage public S;
  IWETH public WETH;

  bool public initialized = false;
  uint256 public createdAt;

  // string public tokenName = "";
  // string public tokenSymbol = "";
  // string public description = "";
  // string public avatar = "";
  // string public ipfsHash;
  // uint256 public level = 0;

  bool public disabled;
  // ICopycatLeader public migratedTo;
  // address public migratedFrom;

  constructor() {
    _owner = msg.sender;
  }

  modifier onlyPlugin() {
    require(S.pluginsEnMap(address(this), ICopycatPlugin(msg.sender)), "I");
    _;
  }

  IERC20[] public tokens;
  mapping(address => uint256) public tokensType; // 1 = Normal, 2 = UniV2 LP

  function getTokens() public view returns(IERC20[] memory) {
    return tokens;
  }

  // uint256 public depositFeeRate = 0;
  // uint256 public withdrawFeeRate = 0;

  // netCopycatFee = copycatFee * copycatToken.copycatFeeMultiplier

  /**
   * @dev Tells the address of the owner
   * @return the address of the owner
   */
  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner, "OO");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  event OwnershipTransferred(address previousOwner, address newOwner);
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  /**
    * @dev Returns true if `account` is a contract.
    *
    * [IMPORTANT]
    * ====
    * It is unsafe to assume that an address for which this function returns
    * false is an externally-owned account (EOA) and not a contract.
    *
    * Among others, `isContract` will return false for the following
    * types of addresses:
    *
    *  - an externally-owned account
    *  - a contract in construction
    *  - an address where a contract will be created
    *  - an address where a contract lived, but was destroyed
    * ====
    */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  modifier onlyEOA(){
    bool isEOA = tx.origin == msg.sender && !isContract(msg.sender);
    require(isEOA || S.contractWhitelist(msg.sender), "EOA");
    _;
  }

  fallback() external payable {
    // WETH.deposit{value: msg.value}();
  }

  receive() external payable {
    // WETH.deposit{value: msg.value}();
  }

  function wrapEth(uint256 value) public onlyOwner {
    WETH.deposit{value: value}();
  }

  // event Initialize(
  //   address indexed initializer, 
  //   address indexed _leaderAddr
  // );
  function initialize(
    address _leaderAddr
  ) public {
    require(!initialized && _owner == address(0), "AI");
    
    factory = CopycatLeaderFactory(msg.sender);
    S = factory.S();
    WETH = S.WETH();
    createdAt = block.timestamp;
    _mint(msg.sender, 0.0001 ether);
    _addToken(WETH, 1);

    _owner = _leaderAddr;

    initialized = true;

    emit OwnershipTransferred(address(0), _owner);
    // emit Initialize(msg.sender, _leaderAddr);
  }

  // !!! Don't forget to reset allowance after disabled plugin !!! (Disable, Enable Plugin)
  // event ModifyPlugin(address indexed caller, uint256 indexed adpterId, bool enabled, address plugin);
  // function modifyPlugin(uint256 pluginId, bool enabled) external nonReentrant {
  //   ICopycatPlugin plugin = plugins[pluginId];

  //   require(factory.isAllowEmergency(ICopycatEmergencyAllower(msg.sender)) || plugin.balance() == 0, "F");

  //   pluginsEnMap[plugin] = enabled;

  //   emit ModifyPlugin(msg.sender, pluginId, enabled, address(plugin));
  // }

  function resetAllowance(IERC20 token, address spender) external nonReentrant onlyOwner {
    token.safeApproveNew(spender, 0);
    emit ApproveToken(address(token), spender, 0);
  }

  function pluginRequestAllowance(IERC20 token, address spender, uint256 amount) external virtual nonReentrant onlyPlugin {
    token.safeApproveNew(spender, amount);
    emit ApproveToken(address(token), spender, amount);
  }

  // Plugin must be approved by Copycat team. If plugin's code is not malcious, it is safe to allow this ability
  event PluginMintShare(address indexed plugin, address indexed to, uint256 amount);
  function pluginMintShare(address to, uint256 amount) external nonReentrant onlyPlugin {
    _mint(to, amount);
    emit PluginMintShare(msg.sender, to, amount);
  }

  event AddToken(address indexed adder, address indexed token, uint256 indexed tokenType);
  function _addToken(IERC20 _token, uint256 _type) internal virtual {
    if(tokensType[address(_token)] == 0) {
      tokens.push(_token);
      tokensType[address(_token)] = _type;
      emit AddToken(msg.sender, address(_token), _type);
    }
  }

  function addToken(IERC20 token) nonReentrant onlyOwner public virtual {
    require(S.getTradingRouteEnabled(address(token)), "NA");
    _addToken(token, 1);
  }

  function pluginAddToken(IERC20 token, uint256 _type) nonReentrant onlyPlugin public {
    _addToken(token, _type);
  }

  function getTokenBalance(IERC20 token) public virtual view returns(uint256 balance) {
    ICopycatAdapter[] memory adapters = S.getTokenAdapters(address(this), token);
    balance = token.balanceOf(address(this));
    for (uint256 i = 0; i < adapters.length; i++) {
      balance += adapters[i].balance();
    }
  }

  // function getTokenUsableBalance(IERC20 token) public virtual view returns(uint256) {
  //   return token.balanceOf(address(this));
  // }

  event RemoveToken(uint256 indexed i, address indexed token);
  function removeToken(uint256 i) public onlyOwner {
    // Removing WBNB is restricted
    require(i > 0 && getTokenBalance(tokens[i]) == 0, "NZ");
    emit RemoveToken(i, address(tokens[i]));
    tokensType[address(tokens[i])] = 0;
    tokens[i] = tokens[tokens.length - 1];
    tokens.pop();
  }

  event Deposit(address indexed from, address indexed to, uint256 percentage, uint256 totalShare);
  function depositTo(address to, uint256 percentage, IERC20 refToken, uint256 maxRefAmount) payable public virtual nonReentrant onlyEOA returns(uint256 totalShare) {
    require(!disabled, "D");

    uint256 refAmount = 0;
    uint256 bnbBefore = address(this).balance;

    ICopycatAdapter[] memory adapters = S.getAdapters(address(this));

    // Collect CPC fee
    uint256 depositCopycatFee = S.getLeaderDepositCopycatFee(address(this));
    if (depositCopycatFee > 0 && msg.sender != address(factory) && to != owner() && msg.sender != owner()) {
      S.collectLeaderFee(msg.sender, depositCopycatFee);
    }

    // Transfer tokens
    for (uint i = 0; i < tokens.length; i++) {
      IERC20 token = tokens[i];

      uint256 amount = token.balanceOf(address(this)) * percentage / 1e18;

      if (amount > 0) {
        if (i > 0 || msg.value == 0) {
          token.safeTransferFrom(msg.sender, address(this), amount);
        } else {
          WETH.deposit{value: amount}();
        }

        if (token == refToken) {
          refAmount += amount;
        }
      }
    }

    // Transfer to adapters
    for (uint i = 0; i < adapters.length; i++) {
      ICopycatAdapter adapter = adapters[i];
      if (S.pluginsEnMap(address(this), adapter)) {
        IERC20 token = S.adaptersToken(address(this), adapter);
        uint256 amount = adapter.balance() * percentage / 1e18;
        if (amount > 0) {
          if (token != WETH || msg.value == 0) {
            token.safeTransferFrom(msg.sender, address(adapter), amount);
          } else {
            WETH.deposit{value: amount}();
            token.safeTransfer(address(adapter), amount);
          }
          
          adapter.sync();

          if (token == refToken) {
            refAmount += amount;
          }
        }
      }
    }

    require(refAmount <= maxRefAmount, "I");

    // Mint share
    totalShare = percentage * totalSupply() / 1e18;
    uint256 shareFee = totalShare * S.getLeaderDepositPercentageFee(address(this)) / 1e18;

    if (msg.sender == address(factory) || msg.sender == owner() || to == owner()) {
      shareFee = 0;
    }

    // Reduce gas for minting
    if (shareFee > 0) {
      totalShare -= shareFee;

      _mint(owner(), shareFee * 6 / 10);
      _mint(S.feeAddress(), shareFee * 4 / 10);
    }

    _mint(to, totalShare);

    emit Deposit(msg.sender, to, percentage, totalShare);
    S.emitDeposit(msg.sender, totalShare);

    if (msg.value > 0) {
      payable(msg.sender).transfer(msg.value - (bnbBefore - address(this).balance));
    }
  }

  event Withdraw(address indexed from, address indexed to, uint256 percentage, uint256 totalShare);
  function withdrawTo(address to, uint256 shareAmount, IERC20 refToken, uint256 minRefAmount, bool asWeth) public virtual nonReentrant onlyEOA returns(uint256 percentage) {
    uint256 refAmount = 0;
    percentage = shareAmount * 1e18 / totalSupply();

    _burn(msg.sender, shareAmount);

    ICopycatAdapter[] memory adapters = S.getAdapters(address(this));

    // Transfer tokens
    for (uint i = 0; i < tokens.length; i++) {
      IERC20 token = tokens[i];

      uint256 amount = token.balanceOf(address(this)) * percentage / 1e18;

      if (amount > 0) {
        if (i > 0 || asWeth) {
          token.safeTransfer(to, amount);
        } else {
          WETH.withdraw(amount);
          payable(to).transfer(amount);
        }

        if (token == refToken) {
          refAmount += amount;
        }
      }
    }

    // Transfer to adapters
    for (uint i = 0; i < adapters.length; i++) {
      ICopycatAdapter adapter = adapters[i];
      if (S.pluginsEnMap(address(this), adapter)) {
        IERC20 token = S.adaptersToken(address(this), adapter);
        uint256 amount = adapter.balance() * percentage / 1e18;
        if (amount > 0) {
          if (token != WETH || asWeth) {
            adapter.withdrawTo(msg.sender, amount);
          } else {
            adapter.withdrawTo(address(this), amount);
            WETH.withdraw(amount);
            payable(to).transfer(amount);
          }

          if (token == refToken) {
            refAmount += amount;
          }
        }
      }
    }

    require(refAmount >= minRefAmount, "I");

    emit Withdraw(msg.sender, to, percentage, shareAmount);
    S.emitWithdraw(msg.sender, shareAmount);
  }


  function addLiquidity(
    IUniswapV2Router02 router,
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin
  )
    external
    nonReentrant
    onlyOwner
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    )
  {
    require(tokensType[tokenA] != 0 && tokensType[tokenB] != 0, "E");
    require(amountADesired >= amountAMin && amountBDesired >= amountBMin, "A");

    IERC20(tokenA).safeApproveNew(address(router), amountADesired);
    IERC20(tokenB).safeApproveNew(address(router), amountBDesired);

    (amountA, amountB, liquidity) = router.addLiquidity(
      tokenA,
      tokenB,
      amountADesired,
      amountBDesired,
      amountAMin,
      amountBMin,
      address(this),
      block.timestamp
    );

    address pair = IUniswapV2Factory(router.factory()).getPair(tokenA, tokenB);
    require(S.tokenAllowed(pair), "T");
    _addToken(IERC20(pair), 2);
  }

  function removeLiquidity(
    IUniswapV2Router02 router,
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin
  ) external nonReentrant onlyOwner returns (uint256 amountA, uint256 amountB) {
    require(tokensType[tokenA] != 0 && tokensType[tokenB] != 0, "E");

    IERC20(IUniswapV2Factory(router.factory()).getPair(tokenA, tokenB)).safeApproveNew(address(router), liquidity);

    (amountA, amountB) = router.removeLiquidity(
      tokenA,
      tokenB,
      liquidity,
      amountAMin,
      amountBMin,
      address(this),
      block.timestamp
    );
  }

  // function swapExactTokensForTokens(
  //   IUniswapV2Router02 router,
  //   uint256 amountIn,
  //   uint256 amountOutMin,
  //   address[] calldata path,
  //   address to,
  //   uint256 deadline
  // ) external returns (uint256[] memory amounts) {
  //   require(tokensType[path[0]] != 0 && tokensType[path[path.length - 1]] != 0, "E");

  //   IERC20(path[0]).safeApproveNew(address(router), amountIn);

  //   amounts = router.swapExactTokensForTokens(
  //     amountIn,
  //     amountOutMin,
  //     path,
  //     to,
  //     deadline
  //   );
  // }

  function mainPathSwapOut(IUniswapV2Router02 router, uint256 amountIn, address tokenIn, address tokenOut) public view returns(uint256) {
    uint256 step1 = amountIn;

    if (tokenIn != address(S.WETH())) {
      uint256[] memory step1a = router.getAmountsOut(amountIn, S.getTradingRouteSell(tokenIn));
      step1 = step1a[step1a.length - 1];
    }

    if (tokenOut == address(S.WETH())) {
      return step1;
    }

    uint256[] memory step2 = router.getAmountsOut(step1, S.getTradingRouteBuy(tokenOut));

    return step2[step2.length - 1];
  }

  function mainPathSwapIn(IUniswapV2Router02 router, uint256 amountOut, address tokenIn, address tokenOut) public view returns(uint256) {
    uint256 step1 = amountOut;

    if (tokenOut != address(S.WETH())) {
      step1 = router.getAmountsIn(amountOut, S.getTradingRouteBuy(tokenOut))[0];
    }

    if (tokenIn == address(S.WETH())) {
      return step1;
    }

    return router.getAmountsIn(step1, S.getTradingRouteSell(tokenIn))[0];
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    IUniswapV2Router02 router,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path
  ) external nonReentrant onlyOwner {
    address tokenIn = path[0];
    address tokenOut = path[path.length - 1];

    require(tokensType[tokenIn] != 0 && tokensType[tokenOut] != 0, "E");

    uint256 fee = S.FEE_LIST(5) * amountIn / 1e18;
    IERC20(tokenIn).safeTransfer(S.feeAddress(), fee);
    amountIn -= fee;

    uint256 mainOut = mainPathSwapOut(router, amountIn, tokenIn, tokenOut);    
    if (mainOut > amountOutMin) amountOutMin = mainOut;

    IERC20(tokenIn).safeApproveNew(address(router), amountIn);

    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      amountIn,
      amountOutMin,
      path,
      address(this),
      block.timestamp
    );
  }

  function swapTokensForExactTokens(
    IUniswapV2Router02 router,
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path
  ) external nonReentrant onlyOwner returns (uint256[] memory amounts) {
    address tokenIn = path[0];
    address tokenOut = path[path.length - 1];

    require(tokensType[tokenIn] != 0 && tokensType[tokenOut] != 0, "E");

    uint256 mainIn = mainPathSwapIn(router, amountOut, tokenIn, tokenOut) * 103 / 100;
    if (mainIn < amountInMax) amountInMax = mainIn;
    
    IERC20(tokenIn).safeApproveNew(address(router), amountInMax);

    amounts = router.swapTokensForExactTokens(
      amountOut,
      amountInMax,
      path,
      address(this),
      block.timestamp
    );

    uint256 fee = S.FEE_LIST(5) * amountOut / 1e18;
    IERC20(tokenOut).safeTransfer(S.feeAddress(), fee);
  }

  event ToAdapter(address indexed caller, address indexed adapter, uint256 amount);
  function toAdapter(ICopycatAdapter adapter, uint256 amount) public nonReentrant onlyOwner {
    require(S.pluginsEnMap(address(this), adapter), "F");
    S.adaptersToken(address(this), adapter).safeTransfer(address(adapter), amount);
    adapter.sync();
    emit ToAdapter(msg.sender, address(adapter), amount);
  }

  event ToLeader(address indexed caller, address indexed adapter, uint256 amount);
  function toLeader(ICopycatAdapter adapter, uint256 amount) public nonReentrant onlyOwner {
    require(S.pluginsEnMap(address(this), adapter), "F");
    adapter.withdrawTo(address(this), amount);
    emit ToLeader(msg.sender, address(adapter), amount);
  }


  /**
    * @dev Returns the name of the token.
    */
  function name() public override view virtual returns (string memory) {
    return S.getLeaderName(address(this));
  }

  /**
    * @dev Returns the symbol of the token, usually a shorter version of the
    * name.
    */
  function symbol() public override view virtual returns (string memory) {
    return S.getLeaderSymbol(address(this));
  }

  function allowEmergencyCall(ICopycatEmergencyAllower allower, bytes32 txHash) public override view returns(bool) {
    return msg.sender == owner() && factory.isAllowEmergency(allower) && allower.isAllowed(txHash);
  }

  // event Disable(address indexed disabler, bool disabled);
  function disable(bool _disabled) public onlyOwner {
    disabled = _disabled;
    // emit Disable(msg.sender, _disabled);
  }
}