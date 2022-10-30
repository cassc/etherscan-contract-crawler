// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

import "./IPriceCalculator.sol";
import "../../base/governance/ControllableV2.sol";
import "../../third_party/uniswap/IUniswapV2Factory.sol";
import "../../third_party/uniswap/IUniswapV2Pair.sol";
import "../../third_party/uniswap/IUniPoolV3.sol";
import "../../third_party/uniswap/IUniFactoryV3.sol";
import "../../third_party/firebird/IFireBirdPair.sol";
import "../../third_party/firebird/IFireBirdFactory.sol";
import "../../base/interface/ISmartVault.sol";
import "../../third_party/iron/IIronSwap.sol";
import "../../third_party/iron/IIronLpToken.sol";
import "../../third_party/curve/ICurveLpToken.sol";
import "../../third_party/curve/ICurveMinter.sol";
import "../../third_party/IERC20Extended.sol";
import "../../third_party/aave/IAaveToken.sol";
import "../../third_party/balancer/IBPT.sol";
import "../../third_party/balancer/IBVault.sol";
import "../../third_party/dystopia/IDystopiaFactory.sol";
import "../../third_party/dystopia/IDystopiaPair.sol";
import "../../openzeppelin/Math.sol";

pragma solidity 0.8.4;

/// @title Calculate current price for token using data from swap platforms
/// @author belbix, bogdoslav
contract PriceCalculator is Initializable, ControllableV2, IPriceCalculator {

  // ************ CONSTANTS **********************

  string public constant VERSION = "1.6.0";
  string public constant IS3USD = "IRON Stableswap 3USD";
  string public constant IRON_IS3USD = "IronSwap IRON-IS3USD LP";
  address public constant FIREBIRD_FACTORY = 0x5De74546d3B86C8Df7FEEc30253865e1149818C8;
  address public constant DYSTOPIA_FACTORY = 0x1d21Db6cde1b18c7E47B0F7F42f4b3F68b9beeC9;
  address public constant CONE_FACTORY = 0x0EFc2D2D054383462F2cD72eA2526Ef7687E1016;
  address public constant UNIV3_FACTORY_ETHEREUM = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
  bytes32 internal constant _DEFAULT_TOKEN_SLOT = 0x3787EA0F228E63B6CF40FE5DE521CE164615FC0FBC5CF167A7EC3CDBC2D38D8F;
  uint256 constant public PRECISION_DECIMALS = 18;
  uint256 constant public DEPTH = 20;
  address public constant CRV_USD_BTC_ETH_MATIC = 0xdAD97F7713Ae9437fa9249920eC8507e5FbB23d3;
  address public constant CRV_USD_BTC_ETH_FANTOM = 0x58e57cA18B7A47112b877E31929798Cd3D703b0f;
  address public constant BEETHOVEN_VAULT_FANTOM = 0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce;
  address public constant BALANCER_VAULT_ETHEREUM = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  // ************ VARIABLES **********************
  // !!! DON'T CHANGE NAMES OR ORDERING !!!

  // Addresses for factories and registries for different DEX platforms.
  // Functions will be added to allow to alter these when needed.
  address[] public swapFactories;
  // Symbols for detecting platforms
  string[] public swapLpNames;

  //Key tokens are used to find liquidity for any given token on Swap platforms.
  address[] public keyTokens;

  mapping(address => address) public replacementTokens;

  mapping(address => bool) public allowedFactories;

  // ********** EVENTS ****************************

  event DefaultTokenChanged(address oldToken, address newToken);
  event KeyTokenAdded(address newKeyToken);
  event KeyTokenRemoved(address keyToken);
  event SwapPlatformAdded(address factoryAddress, string name);
  event SwapPlatformRemoved(address factoryAddress, string name);
  event ReplacementTokenUpdated(address token, address replacementToken);
  event MultipartTokenUpdated(address token, bool status);

  constructor() {
    assert(_DEFAULT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.calculator.defaultToken")) - 1));
  }

  function initialize(address _controller) external initializer {
    ControllableV2.initializeControllable(_controller);
  }

  /// @dev Allow operation only for Controller or Governance
  modifier onlyControllerOrGovernance() {
    require(_isController(msg.sender) || _isGovernance(msg.sender), "Not controller or gov");
    _;
  }

  function getPriceWithDefaultOutput(address token) external view override returns (uint256) {
    return getPrice(token, defaultToken());
  }

  //Main function of the contract. Gives the price of a given token in the defined output token.
  //The contract allows for input tokens to be LP tokens from Uniswap forks.
  //In case of LP token, the underlying tokens will be found and valued to get the price.
  // Output token should exist int the keyTokenList
  function getPrice(address token, address outputToken) public view override returns (uint256) {

    if (token == outputToken) {
      return (10 ** PRECISION_DECIMALS);
    }

    uint256 rate = 1;
    uint256 rateDenominator = 1;
    // check if it is a vault need to return the underlying price
    if (IController(_controller()).vaults(token)) {
      rate = ISmartVault(token).getPricePerFullShare();
      token = ISmartVault(token).underlying();
      rateDenominator = 10 ** IERC20Extended(token).decimals();
      // some vaults can have another vault as underlying
      if (IController(_controller()).vaults(token)) {
        rate = rate * ISmartVault(token).getPricePerFullShare();
        token = ISmartVault(token).underlying();
        rateDenominator = rateDenominator * (10 ** IERC20Extended(token).decimals());
      }
    }

    // if the token exists in the mapping, we'll swap it for the replacement
    // example amBTC/renBTC pool -> wbtc
    if (replacementTokens[token] != address(0)) {
      token = replacementTokens[token];
    }

    uint256 price;
    if (isSwapPlatform(token)) {
      address[2] memory tokens;
      uint256[2] memory amounts;
      (tokens, amounts) = getLpUnderlying(token);
      for (uint256 i = 0; i < 2; i++) {
        address[] memory usedLps = new address[](DEPTH);
        uint256 priceToken = computePrice(tokens[i], outputToken, usedLps, 0);
        if (priceToken == 0) {
          return 0;
        }
        uint256 tokenValue = priceToken * amounts[i] / 10 ** PRECISION_DECIMALS;
        price += tokenValue;
      }
    } else if (isIronPair(token)) {
      price = IIronSwap(IIronLpToken(token).swap()).getVirtualPrice();
    } else if (token == CRV_USD_BTC_ETH_FANTOM || token == CRV_USD_BTC_ETH_MATIC) {
      ICurveMinter minter = ICurveMinter(ICurveLpToken(token).minter());
      uint tvl = 0;
      for (uint256 i = 0; i < 3; i++) {
        address coin = minter.coins(i);
        uint balance = normalizePrecision(minter.balances(i), IERC20Extended(coin).decimals());
        uint256 priceToken = getPrice(coin, outputToken);
        if (priceToken == 0) {
          return 0;
        }

        uint256 tokenValue = priceToken * balance / 10 ** PRECISION_DECIMALS;
        tvl += tokenValue;
      }
      price = tvl * (10 ** PRECISION_DECIMALS)
      / normalizePrecision(IERC20Extended(token).totalSupply(), IERC20Extended(token).decimals());

    } else if (isAave(token)) {
      uint ratio = IAaveToken(token).totalSupply() * (10 ** PRECISION_DECIMALS) / IAaveToken(token).scaledTotalSupply();
      address[] memory usedLps = new address[](DEPTH);
      price = computePrice(IAaveToken(token).UNDERLYING_ASSET_ADDRESS(), outputToken, usedLps, 0);
      price = price * ratio / (10 ** PRECISION_DECIMALS);
    } else if (isBPT(token)) {
      price = calculateBPTPrice(token, outputToken);
    } else {
      address[] memory usedLps = new address[](DEPTH);
      price = computePrice(token, outputToken, usedLps, 0);
    }

    return price * rate / rateDenominator;
  }

  function isSwapPlatform(address token) public view returns (bool) {
    address factory;
    //slither-disable-next-line unused-return,variable-scope,uninitialized-local
    try IUniswapV2Pair(token).factory{gas : 3000}() returns (address _factory) {
      factory = _factory;
    } catch {}

    return allowedFactories[factory];
  }

  function isIronPair(address token) public view returns (bool) {
    return isEqualString(IERC20Extended(token).name(), IS3USD) || isEqualString(IERC20Extended(token).name(), IRON_IS3USD);
  }

  function isAave(address token) public view returns (bool) {
    try IAaveToken(token).UNDERLYING_ASSET_ADDRESS{gas : 60000}() returns (address) {
      return true;
    } catch {}
    return false;
  }

  function isBPT(address token) public view returns (bool) {
    IBPT bpt = IBPT(token);
    try bpt.getVault{gas : 3000}() returns (address vault){
      return (vault == BEETHOVEN_VAULT_FANTOM
      || vault == BALANCER_VAULT_ETHEREUM);
    } catch {}
    return false;
  }

  /* solhint-disable no-unused-vars */
  function checkFactory(IUniswapV2Pair pair, address compareFactory) public view returns (bool) {
    //slither-disable-next-line unused-return,variable-scope,uninitialized-local
    try pair.factory{gas : 3000}() returns (address factory) {
      bool check = (factory == compareFactory) ? true : false;
      return check;
    } catch {}
    return false;
  }

  //Get underlying tokens and amounts for LP
  function getLpUnderlying(address lpAddress) public view returns (address[2] memory, uint256[2] memory) {
    IUniswapV2Pair lp = IUniswapV2Pair(lpAddress);
    address[2] memory tokens;
    uint256[2] memory amounts;
    tokens[0] = lp.token0();
    tokens[1] = lp.token1();
    uint256 token0Decimals = IERC20Extended(tokens[0]).decimals();
    uint256 token1Decimals = IERC20Extended(tokens[1]).decimals();
    uint256 supplyDecimals = lp.decimals();
    (uint256 reserve0, uint256 reserve1,) = lp.getReserves();
    uint256 totalSupply = lp.totalSupply();
    if (reserve0 == 0 || reserve1 == 0 || totalSupply == 0) {
      amounts[0] = 0;
      amounts[1] = 0;
      return (tokens, amounts);
    }
    amounts[0] = reserve0 * 10 ** (supplyDecimals - token0Decimals + PRECISION_DECIMALS) / totalSupply;
    amounts[1] = reserve1 * 10 ** (supplyDecimals - token1Decimals + PRECISION_DECIMALS) / totalSupply;
    return (tokens, amounts);
  }

  //General function to compute the price of a token vs the defined output token.
  function computePrice(address token, address outputToken, address[] memory usedLps, uint256 deep)
  public view returns (uint256) {
    if (token == outputToken) {
      return 10 ** PRECISION_DECIMALS;
    } else if (token == address(0)) {
      return 0;
    }

    require(deep < DEPTH, "PC: too deep");

    (address keyToken,, address lpAddress) = getLargestPool(token, usedLps);
    require(lpAddress != address(0), toAsciiString(token));
    usedLps[deep] = lpAddress;
    deep++;

    uint256 lpPrice = getPriceFromLp(lpAddress, token);
    uint256 keyTokenPrice = computePrice(keyToken, outputToken, usedLps, deep);
    return lpPrice * keyTokenPrice / 10 ** PRECISION_DECIMALS;
  }

  // Gives the LP with largest liquidity for a given token
  // and a given tokenset (either keyTokens or pricingTokens)
  function getLargestPool(address token, address[] memory usedLps)
  public override view returns (address, uint256, address) {
    uint256 largestLpSize = 0;
    address largestKeyToken = address(0);
    uint256 largestPlatformIdx = 0;
    address lpAddress = address(0);
    address[] memory _keyTokens = keyTokens;
    for (uint256 i = 0; i < _keyTokens.length; i++) {
      if (token == _keyTokens[i]) {
        continue;
      }
      for (uint256 j = 0; j < swapFactories.length; j++) {
        (uint256 poolSize, address lp) = getLpForFactory(swapFactories[j], token, _keyTokens[i]);

        if (arrayContains(usedLps, lp)) {
          continue;
        }

        if (poolSize > largestLpSize) {
          largestLpSize = poolSize;
          largestKeyToken = _keyTokens[i];
          largestPlatformIdx = j;
          lpAddress = lp;
        }
      }
    }

    // try to find in UNIv3
    if (lpAddress == address(0) && block.chainid == 1) {
      for (uint256 i = 0; i < _keyTokens.length; i++) {
        if (token == _keyTokens[i]) {
          continue;
        }

        (uint256 poolSize, address lp) = findLpInUniV3(token, _keyTokens[i]);

        if (arrayContains(usedLps, lp)) {
          continue;
        }

        if (poolSize > largestLpSize) {
          largestLpSize = poolSize;
          largestKeyToken = _keyTokens[i];
          largestPlatformIdx = type(uint).max;
          lpAddress = lp;
        }

      }
    }

    return (largestKeyToken, largestPlatformIdx, lpAddress);
  }

  function getLpForFactory(address _factory, address token, address tokenOpposite)
  public view returns (uint256, address){
    address pairAddress;
    // shortcut for firebird ice-weth
    if (_factory == FIREBIRD_FACTORY) {
      pairAddress = IFireBirdFactory(_factory).getPair(token, tokenOpposite, 50, 20);
    } else if (_factory == DYSTOPIA_FACTORY || _factory == CONE_FACTORY) {
      address sPair = IDystopiaFactory(_factory).getPair(token, tokenOpposite, true);
      address vPair = IDystopiaFactory(_factory).getPair(token, tokenOpposite, false);
      uint sReserve = getLpSize(sPair, token);
      uint vReserve = getLpSize(vPair, token);
      if (sReserve > vReserve) {
        return (sReserve, sPair);
      } else {
        return (vReserve, vPair);
      }
    } else {
      pairAddress = IUniswapV2Factory(_factory).getPair(token, tokenOpposite);
    }
    if (pairAddress != address(0)) {
      return (getLpSize(pairAddress, token), pairAddress);
    }
    return (0, address(0));
  }

  function findLpInUniV3(address token, address tokenOpposite)
  public view returns (uint256, address){

    address pairAddress;
    uint reserve;
    uint[] memory fees = new uint[](4);
    fees[0] = 100;
    fees[1] = 500;
    fees[2] = 3000;
    fees[3] = 10000;
    for (uint i; i < fees.length; ++i) {
      address pairAddressTmp = IUniFactoryV3(UNIV3_FACTORY_ETHEREUM).getPool(token, tokenOpposite, uint24(fees[i]));
      if (pairAddressTmp != address(0)) {
        uint reserveTmp = getUniV3Reserve(pairAddressTmp, token);
        if (reserveTmp > reserve) {
          pairAddress = pairAddressTmp;
          reserve = reserveTmp;
        }
      }
    }
    return (reserve, pairAddress);
  }

  function getUniV3Reserve(address pairAddress, address token) public view returns (uint) {
    return IERC20(token).balanceOf(pairAddress);
  }

  function getLpSize(address pairAddress, address token) public view returns (uint256) {
    if (pairAddress == address(0)) {
      return 0;
    }
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    address token0 = pair.token0();
    (uint112 poolSize0, uint112 poolSize1,) = pair.getReserves();
    uint256 poolSize = (token == token0) ? poolSize0 : poolSize1;
    return poolSize;
  }

  //Generic function giving the price of a given token vs another given token on Swap platform.
  function getPriceFromLp(address lpAddress, address token) public override view returns (uint256) {
    address _factory = IUniswapV2Pair(lpAddress).factory();
    if (_factory == DYSTOPIA_FACTORY || _factory == CONE_FACTORY) {
      (address token0, address token1) = IDystopiaPair(lpAddress).tokens();
      uint256 tokenInDecimals = token == token0 ? IERC20Extended(token0).decimals() : IERC20Extended(token1).decimals();
      uint256 tokenOutDecimals = token == token1 ? IERC20Extended(token0).decimals() : IERC20Extended(token1).decimals();
      uint out = IDystopiaPair(lpAddress).getAmountOut(10 ** tokenInDecimals, token);
      return out * (10 ** PRECISION_DECIMALS) / (10 ** tokenOutDecimals);
    } else if (_factory == UNIV3_FACTORY_ETHEREUM) {
      address token0 = IUniPoolV3(lpAddress).token0();
      address token1 = IUniPoolV3(lpAddress).token1();

      uint256 tokenInDecimals = token == token0 ? IERC20Extended(token0).decimals() : IERC20Extended(token1).decimals();
      uint256 tokenOutDecimals = token == token1 ? IERC20Extended(token0).decimals() : IERC20Extended(token1).decimals();
      (uint160 sqrtPriceX96,,,,,,) = IUniPoolV3(lpAddress).slot0();

      uint divider = Math.max(10 ** tokenOutDecimals / 10 ** tokenInDecimals, 1);
      if (token == token0) {
        return uint(sqrtPriceX96) ** 2 / 2 ** 96 * 1e18 / 2 ** 96 / divider * 1e18 / (10 ** tokenOutDecimals);
      } else {
        return 2 ** 192 * 1e18 / uint(sqrtPriceX96) ** 2 / divider * 1e18 / (10 ** tokenOutDecimals);
      }
    } else {
      IUniswapV2Pair pair = IUniswapV2Pair(lpAddress);
      address token0 = pair.token0();
      address token1 = pair.token1();
      (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
      uint256 token0Decimals = IERC20Extended(token0).decimals();
      uint256 token1Decimals = IERC20Extended(token1).decimals();

      // both reserves should have the same decimals
      reserve0 = reserve0 * (10 ** PRECISION_DECIMALS) / (10 ** token0Decimals);
      reserve1 = reserve1 * (10 ** PRECISION_DECIMALS) / (10 ** token1Decimals);

      if (token == token0) {
        return reserve1 * (10 ** PRECISION_DECIMALS) / reserve0;
      } else if (token == token1) {
        return reserve0 * (10 ** PRECISION_DECIMALS) / reserve1;
      } else {
        revert("PC: token not in lp");
      }
    }
  }

  //Checks if a given token is in the keyTokens list.
  function isKeyToken(address token) public view returns (bool) {
    for (uint256 i = 0; i < keyTokens.length; i++) {
      if (token == keyTokens[i]) {
        return true;
      }
    }
    return false;
  }

  function isSwapFactoryToken(address adr) public view returns (bool) {
    for (uint256 i = 0; i < swapFactories.length; i++) {
      if (adr == swapFactories[i]) {
        return true;
      }
    }
    return false;
  }

  function isSwapName(string memory name) public view returns (bool) {
    for (uint256 i = 0; i < swapLpNames.length; i++) {
      if (isEqualString(name, swapLpNames[i])) {
        return true;
      }
    }
    return false;
  }

  function keyTokensSize() external view returns (uint256) {
    return keyTokens.length;
  }

  function swapFactoriesSize() external view returns (uint256) {
    return swapFactories.length;
  }

  // ************* INTERNAL *****************

  function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = char(hi);
      s[2 * i + 1] = char(lo);
    }
    return string(s);
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  function isEqualString(string memory arg1, string memory arg2) internal pure returns (bool) {
    bool check = (keccak256(abi.encodePacked(arg1)) == keccak256(abi.encodePacked(arg2))) ? true : false;
    return check;
  }

  function arrayContains(address[] memory usedLps, address lp) internal pure returns (bool) {
    for (uint256 d = 0; d < usedLps.length; d++) {
      if (usedLps[d] == lp) {
        return true;
      }
    }
    return false;
  }

  function removeFromKeyTokens(uint256 index) internal {
    require(index < keyTokens.length, "PC: wrong index");

    for (uint256 i = index; i < keyTokens.length - 1; i++) {
      keyTokens[i] = keyTokens[i + 1];
    }
    keyTokens.pop();
  }

  function removeFromSwapFactories(uint index) internal {
    require(index < swapFactories.length, "PC: wrong index");

    for (uint i = index; i < swapFactories.length - 1; i++) {
      swapFactories[i] = swapFactories[i + 1];
    }
    swapFactories.pop();
  }

  function removeFromSwapNames(uint index) internal {
    require(index < swapLpNames.length, "PC: wrong index");

    for (uint i = index; i < swapLpNames.length - 1; i++) {
      swapLpNames[i] = swapLpNames[i + 1];
    }
    swapLpNames.pop();
  }

  function defaultToken() public view returns (address value) {
    bytes32 slot = _DEFAULT_TOKEN_SLOT;
    assembly {
      value := sload(slot)
    }
  }

  function normalizePrecision(uint256 amount, uint256 decimals) internal pure returns (uint256){
    return amount * (10 ** PRECISION_DECIMALS) / (10 ** decimals);
  }

  function calculateBPTPrice(address token, address outputToken) internal view returns (uint256){
    IBPT bpt = IBPT(token);
    address balancerVault = bpt.getVault();
    bytes32 poolId = bpt.getPoolId();
    uint256 totalBPTSupply = bpt.totalSupply();
    (IERC20[] memory poolTokens, uint256[] memory balances,) = IBVault(balancerVault).getPoolTokens(poolId);

    uint256 totalPrice = 0;
    for (uint i = 0; i < poolTokens.length; i++) {
      uint256 tokenDecimals = IERC20Extended(address(poolTokens[i])).decimals();
      uint256 tokenPrice = getPrice(address(poolTokens[i]), outputToken);
      // unknown token price
      if (tokenPrice == 0) {
        return 0;
      }
      totalPrice = totalPrice + tokenPrice * balances[i] * 10 ** PRECISION_DECIMALS / 10 ** tokenDecimals;
    }
    return totalPrice / totalBPTSupply;
  }

  // ************* GOVERNANCE ACTIONS ***************

  function setDefaultToken(address _newDefaultToken) external onlyControllerOrGovernance {
    require(_newDefaultToken != address(0), "PC: zero address");
    emit DefaultTokenChanged(defaultToken(), _newDefaultToken);
    bytes32 slot = _DEFAULT_TOKEN_SLOT;
    assembly {
      sstore(slot, _newDefaultToken)
    }
  }

  function addKeyTokens(address[] memory newTokens) external onlyControllerOrGovernance {
    for (uint256 i = 0; i < newTokens.length; i++) {
      addKeyToken(newTokens[i]);
    }
  }

  function addKeyToken(address newToken) public onlyControllerOrGovernance {
    require(!isKeyToken(newToken), "PC: already have");
    keyTokens.push(newToken);
    emit KeyTokenAdded(newToken);
  }

  function removeKeyToken(address keyToken) external onlyControllerOrGovernance {
    require(isKeyToken(keyToken), "PC: not key");
    uint256 i;
    for (i = 0; i < keyTokens.length; i++) {
      if (keyToken == keyTokens[i]) {
        break;
      }
    }
    removeFromKeyTokens(i);
    emit KeyTokenRemoved(keyToken);
  }

  function addSwapPlatform(address _factoryAddress, string memory _name) external onlyControllerOrGovernance {
    for (uint256 i = 0; i < swapFactories.length; i++) {
      require(swapFactories[i] != _factoryAddress, "PC: factory already exist");
      require(!isEqualString(swapLpNames[i], _name), "PC: name already exist");
    }
    swapFactories.push(_factoryAddress);
    swapLpNames.push(_name);
    allowedFactories[_factoryAddress] = true;
    emit SwapPlatformAdded(_factoryAddress, _name);
  }

  function changeFactoriesStatus(address[] memory factories, bool status) external onlyControllerOrGovernance {
    for (uint256 i; i < factories.length; i++) {
      allowedFactories[factories[i]] = status;
    }
  }

  function removeSwapPlatform(address _factoryAddress, string memory _name) external onlyControllerOrGovernance {
    require(isSwapFactoryToken(_factoryAddress), "PC: swap not exist");
    require(isSwapName(_name), "PC: name not exist");
    uint256 i;
    for (i = 0; i < swapFactories.length; i++) {
      if (_factoryAddress == swapFactories[i]) {
        break;
      }
    }
    removeFromSwapFactories(i);

    for (i = 0; i < swapLpNames.length; i++) {
      if (isEqualString(_name, swapLpNames[i])) {
        break;
      }
    }
    removeFromSwapNames(i);
    emit SwapPlatformRemoved(_factoryAddress, _name);
  }

  function setReplacementTokens(address _inputToken, address _replacementToken)
  external onlyControllerOrGovernance {
    replacementTokens[_inputToken] = _replacementToken;
    emit ReplacementTokenUpdated(_inputToken, _replacementToken);
  }
}