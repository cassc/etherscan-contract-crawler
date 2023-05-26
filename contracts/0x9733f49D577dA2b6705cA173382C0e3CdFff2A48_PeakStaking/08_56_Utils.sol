pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/KyberNetwork.sol";
import "./interfaces/OneInchExchange.sol";

/**
 * @title The smart contract for useful utility functions and constants.
 * @author Zefram Lou (Zebang Liu)
 */
contract Utils {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Detailed;

  /**
   * @notice Checks if `_token` is a valid token.
   * @param _token the token's address
   */
  modifier isValidToken(address _token) {
    require(_token != address(0));
    if (_token != address(ETH_TOKEN_ADDRESS)) {
      require(isContract(_token));
    }
    _;
  }

  address public USDC_ADDR;
  address payable public KYBER_ADDR;
  address payable public ONEINCH_ADDR;

  bytes public constant PERM_HINT = "PERM";

  // The address Kyber Network uses to represent Ether
  ERC20Detailed internal constant ETH_TOKEN_ADDRESS = ERC20Detailed(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
  ERC20Detailed internal usdc;
  KyberNetwork internal kyber;

  uint256 constant internal PRECISION = (10**18);
  uint256 constant internal MAX_QTY   = (10**28); // 10B tokens
  uint256 constant internal ETH_DECIMALS = 18;
  uint256 constant internal MAX_DECIMALS = 18;

  constructor(
    address _usdcAddr,
    address payable _kyberAddr,
    address payable _oneInchAddr
  ) public {
    USDC_ADDR = _usdcAddr;
    KYBER_ADDR = _kyberAddr;
    ONEINCH_ADDR = _oneInchAddr;

    usdc = ERC20Detailed(_usdcAddr);
    kyber = KyberNetwork(_kyberAddr);
  }

  /**
   * @notice Get the number of decimals of a token
   * @param _token the token to be queried
   * @return number of decimals
   */
  function getDecimals(ERC20Detailed _token) internal view returns(uint256) {
    if (address(_token) == address(ETH_TOKEN_ADDRESS)) {
      return uint256(ETH_DECIMALS);
    }
    return uint256(_token.decimals());
  }

  /**
   * @notice Get the token balance of an account
   * @param _token the token to be queried
   * @param _addr the account whose balance will be returned
   * @return token balance of the account
   */
  function getBalance(ERC20Detailed _token, address _addr) internal view returns(uint256) {
    if (address(_token) == address(ETH_TOKEN_ADDRESS)) {
      return uint256(_addr.balance);
    }
    return uint256(_token.balanceOf(_addr));
  }

  /**
   * @notice Calculates the rate of a trade. The rate is the price of the source token in the dest token, in 18 decimals.
   *         Note: the rate is on the token level, not the wei level, so for example if 1 Atoken = 10 Btoken, then the rate
   *         from A to B is 10 * 10**18, regardless of how many decimals each token uses.
   * @param srcAmount amount of source token
   * @param destAmount amount of dest token
   * @param srcDecimals decimals used by source token
   * @param dstDecimals decimals used by dest token
   */
  function calcRateFromQty(uint256 srcAmount, uint256 destAmount, uint256 srcDecimals, uint256 dstDecimals)
        internal pure returns(uint)
  {
    require(srcAmount <= MAX_QTY);
    require(destAmount <= MAX_QTY);

    if (dstDecimals >= srcDecimals) {
      require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
      return (destAmount * PRECISION / ((10 ** (dstDecimals - srcDecimals)) * srcAmount));
    } else {
      require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
      return (destAmount * PRECISION * (10 ** (srcDecimals - dstDecimals)) / srcAmount);
    }
  }

  /**
   * @notice Wrapper function for doing token conversion on Kyber Network
   * @param _srcToken the token to convert from
   * @param _srcAmount the amount of tokens to be converted
   * @param _destToken the destination token
   * @return _destPriceInSrc the price of the dest token, in terms of source tokens
   *         _srcPriceInDest the price of the source token, in terms of dest tokens
   *         _actualDestAmount actual amount of dest token traded
   *         _actualSrcAmount actual amount of src token traded
   */
  function __kyberTrade(ERC20Detailed _srcToken, uint256 _srcAmount, ERC20Detailed _destToken)
    internal
    returns(
      uint256 _destPriceInSrc,
      uint256 _srcPriceInDest,
      uint256 _actualDestAmount,
      uint256 _actualSrcAmount
    )
  {
    require(_srcToken != _destToken);

    uint256 beforeSrcBalance = getBalance(_srcToken, address(this));
    uint256 msgValue;
    if (_srcToken != ETH_TOKEN_ADDRESS) {
      msgValue = 0;
      _srcToken.safeApprove(KYBER_ADDR, 0);
      _srcToken.safeApprove(KYBER_ADDR, _srcAmount);
    } else {
      msgValue = _srcAmount;
    }
    _actualDestAmount = kyber.tradeWithHint.value(msgValue)(
      _srcToken,
      _srcAmount,
      _destToken,
      toPayableAddr(address(this)),
      MAX_QTY,
      1,
      address(0),
      PERM_HINT
    );
    _actualSrcAmount = beforeSrcBalance.sub(getBalance(_srcToken, address(this)));
    require(_actualDestAmount > 0 && _actualSrcAmount > 0);
    _destPriceInSrc = calcRateFromQty(_actualDestAmount, _actualSrcAmount, getDecimals(_destToken), getDecimals(_srcToken));
    _srcPriceInDest = calcRateFromQty(_actualSrcAmount, _actualDestAmount, getDecimals(_srcToken), getDecimals(_destToken));
  }

  /**
   * @notice Wrapper function for doing token conversion on 1inch
   * @param _srcToken the token to convert from
   * @param _srcAmount the amount of tokens to be converted
   * @param _destToken the destination token
   * @return _destPriceInSrc the price of the dest token, in terms of source tokens
   *         _srcPriceInDest the price of the source token, in terms of dest tokens
   *         _actualDestAmount actual amount of dest token traded
   *         _actualSrcAmount actual amount of src token traded
   */
  function __oneInchTrade(ERC20Detailed _srcToken, uint256 _srcAmount, ERC20Detailed _destToken, bytes memory _calldata)
    internal
    returns(
      uint256 _destPriceInSrc,
      uint256 _srcPriceInDest,
      uint256 _actualDestAmount,
      uint256 _actualSrcAmount
    )
  {
    require(_srcToken != _destToken);

    uint256 beforeSrcBalance = getBalance(_srcToken, address(this));
    uint256 beforeDestBalance = getBalance(_destToken, address(this));
    // Note: _actualSrcAmount is being used as msgValue here, because otherwise we'd run into the stack too deep error
    if (_srcToken != ETH_TOKEN_ADDRESS) {
      _actualSrcAmount = 0;
      OneInchExchange dex = OneInchExchange(ONEINCH_ADDR);
      address approvalHandler = dex.spender();
      _srcToken.safeApprove(approvalHandler, 0);
      _srcToken.safeApprove(approvalHandler, _srcAmount);
    } else {
      _actualSrcAmount = _srcAmount;
    }

    // trade through 1inch proxy
    (bool success,) = ONEINCH_ADDR.call.value(_actualSrcAmount)(_calldata);
    require(success);

    // calculate trade amounts and price
    _actualDestAmount = getBalance(_destToken, address(this)).sub(beforeDestBalance);
    _actualSrcAmount = beforeSrcBalance.sub(getBalance(_srcToken, address(this)));
    require(_actualDestAmount > 0 && _actualSrcAmount > 0);
    _destPriceInSrc = calcRateFromQty(_actualDestAmount, _actualSrcAmount, getDecimals(_destToken), getDecimals(_srcToken));
    _srcPriceInDest = calcRateFromQty(_actualSrcAmount, _actualDestAmount, getDecimals(_srcToken), getDecimals(_destToken));
  }

  /**
   * @notice Checks if an Ethereum account is a smart contract
   * @param _addr the account to be checked
   * @return True if the account is a smart contract, false otherwise
   */
  function isContract(address _addr) internal view returns(bool) {
    uint256 size;
    if (_addr == address(0)) return false;
    assembly {
        size := extcodesize(_addr)
    }
    return size>0;
  }

  function toPayableAddr(address _addr) internal pure returns (address payable) {
    return address(uint160(_addr));
  }
}