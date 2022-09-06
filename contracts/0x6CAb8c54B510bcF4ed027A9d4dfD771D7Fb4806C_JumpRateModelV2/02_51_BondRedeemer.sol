// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { ERC20 } from "./openzeppelin/ERC20.sol";
import { IERC20 } from "./openzeppelin/IERC20.sol";
import "./openzeppelin/Ownable.sol";
import "./openzeppelin/IOwnable.sol";
import "./AggregatorV3Interface.sol";
import "./openzeppelin/SafeERC20.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
contract BondRedeemer is Ownable {
  //Incorrect boilerplate addresses
  using SafeERC20 for IERC20;
  address public constant BDAMM = 0xc4F125F56e10980A26093c5ad22AEa1FA93cfd57;
  address public constant DAMM = 0xD9aA9fD99c2C085ce82A7f084A451C2460FCd73e;
  address public constant CHAINLINK_DAMM = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c; //using $LINK Oracle for testing
  address public admin;
  bool public redeemAllowed = true;

  mapping(address => bool) public tokensPermitted;

  mapping(address => uint256) public discountRates;

  mapping(address => address) public oracles;

  event Redemption(address redeemer, uint256 quantityOfdAMM, uint256 bdAMMRedeemed, uint256 usdcQuantity);
  //event TokenPermitted(address token, uint256 discountRates, address oracle);
  event TokenPermitted(address token, uint256 discountRates, address oracle);

  event NewAdmin(address newAdminAdd);

  constructor() {
    admin = msg.sender;
  }

  function dAMMBalance() public view returns (uint256) {
    uint256 balance = IERC20(DAMM).balanceOf(address(this));
    return balance;
  }

  function getLatestPrice(address oracleAdd) public view returns (int256) {
    AggregatorV3Interface oraclePriceFeed = AggregatorV3Interface(oracleAdd);
    (
      ,
      /*uint80 roundID*/
      int256 price, /*uint startedAt*/
      ,
      ,

    ) = /*uint timeStamp*/
      /*uint80 answeredInRound*/
      oraclePriceFeed.latestRoundData();
    return price;
  }

  function getLatestDecimals(address oracleAdd) public view returns (uint8) {
    AggregatorV3Interface oraclePriceFeed = AggregatorV3Interface(oracleAdd);
    uint8 decimals = oraclePriceFeed.decimals();
    return decimals;
  }

  function changeAdmin(address newAdmin) public onlyOwner {
    require(msg.sender == admin);
    transferOwnership(newAdmin);
    emit NewAdmin(newAdmin);
  }

  // release trapped funds
  function withdrawTokens(address token) public onlyOwner {
    require(msg.sender == admin);
    if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
      payable(IOwnable(admin).owner()).transfer(address(this).balance);
    } else {
      uint256 balance = IERC20(token).balanceOf(address(this));
      IERC20(token).transfer(admin, balance);
    }
  }

  //Set allowable tokens
  //Discount rate in BPS
  //This is the real line, I took out the oracle for testing

  function permitToken(
    address token,
    uint256 discountRate,
    address oracle
  ) public onlyOwner {
    require(msg.sender == admin); //double bagging
    tokensPermitted[token] = true;
    oracles[token] = oracle;
    discountRates[token] = discountRate;
    emit TokenPermitted(token, discountRate, oracle);
  }

  //Allows the delisting of a bond redemption token
  function disableToken(address token) public onlyOwner returns (bool) {
    require(msg.sender == admin);
    require(tokensPermitted[token] == true, "Token is not listed");
    tokensPermitted[token] = false;
    return tokensPermitted[token];
  }

  /**
   * @notice BONDING REDEMPTIONS
   * @notice Users can redeem their liquidity bonding tokens for dAMM at a discount to market price
   * @notice
   * @param rawbdAMMToRedeem is the quantity of discounted dAMM the user desires to redeem for dAMM
   * @param paymentToken is the specified redemption token
   */
  function BondRedemption(address paymentToken, uint256 rawbdAMMToRedeem) public {
    require(redeemAllowed == true, "Liquidity Bonds temporarily disabled.");
    require(tokensPermitted[paymentToken] == true, "Token is not permitted for redemption");

    uint256 currentBal = dAMMBalance();
    //current token discount rate
    uint256 inverseDiscountRateInBPS = 10000 - discountRates[paymentToken];

    //Get latest decimals and token scale
    uint256 dAMMDecimalScaleUp = 1**(18 - uint256(getLatestDecimals(CHAINLINK_DAMM)));
    uint256 paymentTokenDecimalScaleUp = 1**(18 - uint256(getLatestDecimals(oracles[paymentToken])));

    //Converting chainlink data to scale
    uint256 dAMMPriceInUSD = uint256(getLatestPrice(oracles[CHAINLINK_DAMM])) * dAMMDecimalScaleUp;
    uint256 paymentTokenPrice = uint256(getLatestPrice(oracles[paymentToken])) * paymentTokenDecimalScaleUp;

    //Calculating bdAMM and paymentToken needed, seperated as two variables for clarity
    uint256 dAMMToReceive = rawbdAMMToRedeem * 1e18;
    uint256 rawbdAMMConverted = rawbdAMMToRedeem * 1e18;

    uint256 dollarsOfPaymentTokenOwed = (dAMMPriceInUSD * inverseDiscountRateInBPS) / 10000;
    uint256 paymentTokenOwed = dollarsOfPaymentTokenOwed / paymentTokenPrice;

    //Some extra safety checks
    require(IERC20(paymentToken).balanceOf(msg.sender) >= paymentTokenOwed);
    require((currentBal >= dAMMToReceive));

    //msg.sender sends bdAMM to admin, and USDC
    //for testing removing BDAMM as the ERC20 and using a test ERC20
    SafeERC20.safeTransferFrom(IERC20(BDAMM), msg.sender, admin, rawbdAMMConverted);
    SafeERC20.safeTransferFrom(IERC20(paymentToken), msg.sender, admin, paymentTokenOwed);
    //No reversion because of SafeTransfer above. If either fails minting doesn't occur.
    //Transfer dAMM to the redeemer
    SafeERC20.safeTransfer(IERC20(DAMM), msg.sender, dAMMToReceive);
    emit Redemption(msg.sender, dAMMToReceive, rawbdAMMToRedeem, paymentTokenOwed);
  }
}