// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@tetu_io/tetu-contracts/contracts/openzeppelin/SafeERC20.sol";
import "@tetu_io/tetu-contracts/contracts/openzeppelin/EnumerableSet.sol";
import "@tetu_io/tetu-contracts/contracts/base/interfaces/ITetuLiquidator.sol";
import "@tetu_io/tetu-contracts/contracts/base/governance/ControllableV2.sol";
import "../third_party/paladin/IMultiMerkleDistributor.sol";
import "../third_party/hh/IRewardDistributor.sol";
import "../third_party/polygon/IRootChainManager.sol";

contract BribeLiquidator is ControllableV2 {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  // ----- CONSTANTS -------

  /// @notice Version of the contract
  string public constant VERSION = "1.0.0";

  address internal constant COMMUNITY_MSIG = 0xB9fA147b96BbC932e549f619A448275855b9A7D9;
  address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  ITetuLiquidator internal constant LIQUIDATOR = ITetuLiquidator(0x90351d15F036289BE9b1fd4Cb0e2EeC63a9fF9b0);
  IMultiMerkleDistributor internal constant PALADIN_DISTRIBUTOR = IMultiMerkleDistributor(0x8EdcFE9Bc7d2a735117B94C16456D8303777abbb);
  IRewardDistributor internal constant HH_DISTRIBUTOR = IRewardDistributor(0x0b139682D5C9Df3e735063f46Fb98c689540Cf3A);
  IRootChainManager internal constant POLYGON_BRIDGE = IRootChainManager(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);

  uint public constant PRICE_IMPACT_TOLERANCE = 5_000;

  // ----- VARIABLES -------

  address public gelato;
  uint public maxGas;
  uint public lastCall;
  EnumerableSet.AddressSet internal whitelistedTokens;
  uint public perfFee;
  address public feeRecipient;

  // ----- INITIALIZER -------

  function initialize(address controller_) external initializer {
    ControllableV2.initializeControllable(controller_);

    maxGas = 70 gwei;
    perfFee = 20;
    feeRecipient = IController(controller_).governance();
  }

  // ----- CONTROL -------

  function setGelato(address adr) external {
    require(IController(_controller()).governance() == msg.sender, "FORBIDDEN");
    gelato = adr;
  }

  function setFeeRecipient(address adr) external {
    require(IController(_controller()).governance() == msg.sender, "FORBIDDEN");
    feeRecipient = adr;
  }

  function setMaxGas(uint _maxGas) external {
    require(IController(_controller()).governance() == msg.sender, "FORBIDDEN");
    maxGas = _maxGas;
  }

  function setPerfFee(uint fee) external {
    require(IController(_controller()).governance() == msg.sender, "FORBIDDEN");
    require(fee >= 20, "WRONG");
    perfFee = fee;
  }

  function whitelist(address[] memory tokens, bool add) external {
    require(IController(_controller()).governance() == msg.sender, "FORBIDDEN");

    EnumerableSet.AddressSet storage _whitelistedTokens = whitelistedTokens;

    for (uint i; i < tokens.length; ++i) {
      if (add) {
        _whitelistedTokens.add(tokens[i]);
      } else {
        _whitelistedTokens.remove(tokens[i]);
      }

    }
  }

  /// @dev Governance can withdraw any token.
  function salvage(address token, uint amount, address dest) external {
    require(IController(_controller()).governance() == msg.sender, "FORBIDDEN");
    IERC20(token).safeTransfer(dest, amount);
  }

  // ----- CLAIMS -------

  /// @dev Claim Paladin rewards to this contract.
  function claimPaladin(IMultiMerkleDistributor.ClaimParams[] calldata claims) external {
    PALADIN_DISTRIBUTOR.multiClaim(address(this), claims);
  }

  /// @dev Claim Hidden Hand rewards to this contract.
  function claimHiddenHand(RewardDistributor.Claim[] calldata claims) external {
    HH_DISTRIBUTOR.claim(claims);
  }

  // ----- LIQUIDATE -------

  /// @dev Liquidate given amount of given token to USDC and bridge it to Polygon.
  function liquidateAndBridgeFromCommunityMsig(address[] memory tokens, uint[] memory amounts) external returns (uint amountUSDC) {
    require(msg.sender == gelato, "FORBIDDEN");

    return _liquidateAndBridgeInternal(tokens, amounts, true);
  }

  function liquidateAndBridgeFromThis(address[] memory tokens, uint[] memory amounts) external returns (uint amountUSDC) {
    require(msg.sender == gelato, "FORBIDDEN");

    return _liquidateAndBridgeInternal(tokens, amounts, false);
  }

  function _liquidateAndBridgeInternal(address[] memory tokens, uint[] memory amounts, bool isTransfer) internal returns (uint amountUSDC) {
    for (uint i; i < tokens.length; ++i) {
      address token = tokens[i];
      uint amount = amounts[i];

      // transfer tokens to this contract, assume max approve was given
      if (isTransfer) {
        IERC20(token).safeTransferFrom(COMMUNITY_MSIG, address(this), amount);
      }

      // liquidate any token to usdc for bridging
      _liquidateToUSDC(token, amount);
    }

    amountUSDC = IERC20(USDC).balanceOf(address(this));

    if (amountUSDC != 0) {

      uint toFess = amountUSDC / perfFee;
      uint toBridge = amountUSDC - toFess;

      if (toFess != 0) {
        IERC20(USDC).safeTransfer(feeRecipient, toFess);
      }

      if (toBridge != 0) {
        address predicate = POLYGON_BRIDGE.typeToPredicate(POLYGON_BRIDGE.tokenToType(USDC));
        require(predicate != address(0), "INVALID_PREDICATE");
        _approveIfNeed(USDC, predicate, toBridge);
        POLYGON_BRIDGE.depositFor(COMMUNITY_MSIG, USDC, abi.encode(toBridge));
      }
    }

    lastCall = block.timestamp;
  }

  // ----- GELATO -------

  function maxGasAdjusted() public view returns (uint) {
    uint _maxGas = maxGas;
    uint diff = block.timestamp - lastCall;
    uint multiplier = diff * 100 / 1 days;
    return _maxGas + _maxGas * multiplier / 100;
  }

  function isReadyToLiquidate() external view returns (bool canExec, bytes memory execPayload) {
    if (tx.gasprice > maxGasAdjusted()) {
      return (false, abi.encodePacked("Too high gas: ", _toString(tx.gasprice / 1e9)));
    }

    address[] memory _whitelistedTokens = whitelistedTokens.values();

    address[] memory tokens = new address[](_whitelistedTokens.length);
    uint[] memory amounts = new uint[](_whitelistedTokens.length);

    uint counter;

    // ---------- CHECK COMMUNITY MSIG BALANCES ---------------

    for (uint i; i < _whitelistedTokens.length; ++i) {
      address token = _whitelistedTokens[i];
      uint balance = IERC20(token).balanceOf(COMMUNITY_MSIG);

      // 1mil threshold for any token, for wbtc probably too much but we not assume it will exist here
      if (balance < 1_000_000) {
        continue;
      }

      uint approve = IERC20(token).allowance(COMMUNITY_MSIG, address(this));

      if (balance > approve) {
        revert(string(abi.encodePacked("No approve for 0x", _toAsciiString(token))));
      }

      tokens[i] = token;
      amounts[i] = balance;
      counter++;
    }

    if (counter != 0) {
      address[] memory resultTokens = new address[](counter);
      uint[] memory resultAmounts = new uint[](counter);

      uint j;
      for (uint i; i < _whitelistedTokens.length; ++i) {
        if (tokens[i] == address(0)) {
          continue;
        }
        resultTokens[j] = tokens[i];
        resultAmounts[j] = amounts[i];
        j++;
      }
      return (true, abi.encodeWithSelector(BribeLiquidator.liquidateAndBridgeFromCommunityMsig.selector, resultTokens, resultAmounts));
    }

    // ---------- CHECK LOCAL BALANCES ---------------

    // refresh variables
    tokens = new address[](_whitelistedTokens.length);
    amounts = new uint[](_whitelistedTokens.length);
    counter = 0;

    for (uint i; i < _whitelistedTokens.length; ++i) {
      address token = _whitelistedTokens[i];
      uint balance = IERC20(token).balanceOf(address(this));

      // 1mil threshold for any token, for wbtc probably too much but we not assume it will exist here
      if (balance < 1_000_000) {
        continue;
      }

      tokens[i] = token;
      amounts[i] = balance;
      counter++;
    }

    if (counter != 0) {
      address[] memory resultTokens = new address[](counter);
      uint[] memory resultAmounts = new uint[](counter);

      uint j;
      for (uint i; i < _whitelistedTokens.length; ++i) {
        if (tokens[i] == address(0)) {
          continue;
        }
        resultTokens[j] = tokens[i];
        resultAmounts[j] = amounts[i];
        j++;
      }
      return (true, abi.encodeWithSelector(BribeLiquidator.liquidateAndBridgeFromThis.selector, resultTokens, resultAmounts));
    }


    return (false, "Nothing");
  }

  // ----- INTERNAL -------

  /// @dev Sell given token to USDC using Tetu liquidator.
  function _liquidateToUSDC(address tokenIn, uint amount) internal {
    if (tokenIn == USDC) {
      return;
    }

    _approveIfNeed(tokenIn, address(LIQUIDATOR), amount);
    LIQUIDATOR.liquidate(tokenIn, USDC, amount, PRICE_IMPACT_TOLERANCE);
  }

  function _approveIfNeed(address token, address dst, uint amount) internal {
    if (IERC20(token).allowance(address(this), dst) < amount) {
      IERC20(token).safeApprove(dst, 0);
      IERC20(token).safeApprove(dst, type(uint).max);
    }
  }

  function _toString(uint value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint temp = value;
    uint digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }


  function _toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = _char(hi);
      s[2 * i + 1] = _char(lo);
    }
    return string(s);
  }

  function _char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

}