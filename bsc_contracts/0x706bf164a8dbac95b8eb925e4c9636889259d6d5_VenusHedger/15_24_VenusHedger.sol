// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.10;

import { EnumerableSet } from 'openzeppelin-contracts/utils/structs/EnumerableSet.sol';
// import { console } from 'forge-std/console.sol';

// https://github.com/VenusProtocol/venus-protocol/blob/develop/contracts/VToken.sol
// https://github.com/VenusProtocol/venus-protocol/blob/develop/contracts/Comptroller.sol

import { PriceOracle } from './interfaces/Venus/PriceOracle.sol';
import { VBep20Interface, VTokenInterface } from './interfaces/Venus/VTokenInterfaces.sol';
import { ComptrollerInterface } from './interfaces/Venus/ComptrollerInterface.sol';
import { UpgradeableHedgerBase } from './base/UpgradeableHedgerBase.sol';
import { IParaSwapAugustus } from './external/paraswap/IParaSwapAugustus.sol';
import { Config } from './components/Config.sol';
import { IERC20 } from './interfaces/tokens/IERC20.sol';

// All parent contracts must be OZ upgradeable-compatible
contract VenusHedger is UpgradeableHedgerBase {
  using EnumerableSet for EnumerableSet.AddressSet;

  VBep20Interface internal constant vUSDC = VBep20Interface(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8);

  ComptrollerInterface internal constant comptroller = ComptrollerInterface(0xfD36E2c2a6789Db23113685031d7F16329158384); // Unitroller proxy for comptroller

  PriceOracle internal constant oracle = PriceOracle(0xd8B6dA2bfEC71D684D3E2a2FC9492dDad5C3787F);

  EnumerableSet.AddressSet private enabledVTokens;

  // EnumerableSet.AddressSet private potentialOwners;

  modifier onlyEnabledVToken(address vToken) {
    require(isEnabledVToken(vToken), 'VToken not enabled for the contract.');
    _;
  }

  /// @dev Proxy initializer (constructor)
  function initialize(address _config) public initializer {
    // Call parent upgradeable contract initializers FIRST
    __Ownable_init_unchained();
    __Pausable_init_unchained();
    __UUPSUpgradeable_init_unchained();

    config = Config(_config);
    paraswap = IParaSwapAugustus(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57);
    paraswapTokenProxy = paraswap.getTokenTransferProxy();
    USDC = IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d); // underlying of vUSDC
  }

  /// @dev Enter vToken markets for the caller. Make sure to only call once (contract doesn't check for duplicate calls)
  function initiate() public onlyOwner {
    // Manaully approve USDC in particular here (approval from the contract address)
    USDC.approve(address(vUSDC), type(uint).max); // For minting vToken
    USDC.approve(address(paraswapTokenProxy), type(uint).max); // For swapping vToken

    // For msg.sender
    address[] memory vTokens = new address[](3);
    vTokens[0] = address(0xf508fCD89b8bd15579dc79A6827cB4686A3592c8); // vETH
    vTokens[1] = address(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8); // vUSDC
    vTokens[2] = address(0x650b940a1033B8A1b1873f78730FcFC73ec11f1f); // vLINK

    enableVTokens(vTokens);
  }

  /// @dev Deposit USDC directly as the collateral (mint vUSDC)
  function depositCollateral(uint256 amount) public override {
    require(USDC.allowance(msg.sender, address(this)) >= amount, 'Insufficient USDC allowance');
    require(USDC.balanceOf(msg.sender) >= amount, 'Insufficient USDC to transfer');
    USDC.transferFrom(msg.sender, address(this), amount);
    require(vUSDC.mint(amount) == 0, 'Mint failed'); // @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
  }

  /// @dev Convert underlying token to vToken
  function convertUnderlyingToVToken(VTokenInterface vToken, uint256 amount) public onlyOwner {
    IERC20 uToken = IERC20(VBep20Interface(address(vToken)).underlying()); // underlying token
    require(uToken.balanceOf(address(this)) >= amount, 'Insufficient underlying token to convert');
    require(VBep20Interface(address(vToken)).mint(amount) == 0, 'Mint failed');
  }

  /// @dev Redeem vToken for underlying token
  function redeemVToken(VTokenInterface vToken, uint256 target, uint256 buffer) public onlyOwner {
    uint beforeVTokenInUSDC = (vToken.exchangeRateStored() * vToken.balanceOf(address(this))) / 1e18;
    require(beforeVTokenInUSDC >= target, 'vToken balance is not enough to redeem');
    uint err = VBep20Interface(address(vToken)).redeemUnderlying(_amountMoreSlippage(target, buffer * 100));
    require(err == 0, string(abi.encodePacked('vToken redeem underlying failed with ', err)));
  }

  function canHedge(
    address vToken,
    address underlying, // underlying token of vToken (Venus contract is written horribly so .underlying() is NOT a view function!)
    uint256 amount, // amount to short (borrow & swap)
    // add buffer to `amountUSDC` (ie. add a bit more collateral than needed, in case the executing block has slippage)
    // 0.01% => 1 // 0.1% => 10 // 1% => 100
    uint256 buffer
  ) public view returns (bool possible, uint256 availableCollateral, uint256 shortfall) {
    (, availableCollateral, ) = getAccountLiquidity();
    (possible, shortfall) = _canHedge(
      underlying,
      amount * oracle.getUnderlyingPrice(VTokenInterface(vToken)) / 1e18,
      availableCollateral,
      0
    );
    // TODO: Shortfall returns right amount, but the actual depositAndCollateral results in less USDC collateral
    //       than the specified shortfall. So use `buffer = 1` to deposit additional USDC to make the hedge work.
    shortfall = shortfall * (1000 + buffer) / 1000;
  }

  /// @dev Hedge and gives negative delta
  function hedge(
    IERC20 vToken, // example: vETH
    bytes memory swapCalldata,
    uint256 amountToSwapToken, // expected amount of token to hedge & swap
    uint256 minAmountToReceiveUSDC // min amount of USDC to receive
  ) public override onlyOwner returns (uint256 amountReceived) {
    // Borrow succeed => returns 0
    uint err = VBep20Interface(address(vToken)).borrow(amountToSwapToken);
    require(err == 0, string(abi.encodePacked('Borrow failed with ', err)));

    // underlying token of vToken
    IERC20 vuToken = IERC20(VBep20Interface(address(vToken)).underlying());

    amountReceived = _hedgeSwapStep(vuToken, swapCalldata, amountToSwapToken, minAmountToReceiveUSDC);
  }

  /// @dev Unhedge by swapping USDC to borrowed token and repaying
  function payback(
    IERC20 vToken, // example: vETH
    bytes memory swapCalldata,
    uint256 maxAmountToSwapUSDC, // max amount of USDC to swap to token
    uint256 amountToReceiveToken // expected amount of token to receive
  ) public override onlyOwner returns (uint256 amountSold) {
    IERC20 vuToken = IERC20(VBep20Interface(address(vToken)).underlying()); // token underlying vToken

    amountSold = _paybackSwapStep(vuToken, swapCalldata, maxAmountToSwapUSDC, amountToReceiveToken);

    uint err2 = VBep20Interface(address(vToken)).repayBorrow(amountToReceiveToken);
    require(err2 == 0, string(abi.encodePacked('Repay borrow failed with ', err2)));
  }

  /// @dev Close all hedges of all tokens and exit immediately
  function exit() public onlyOwner {
    VTokenInterface[] memory vTokens = comptroller.getAssetsIn(address(this));
    for (uint i = 0; i < vTokens.length; ) {
      VTokenInterface vToken = vTokens[i];
      (, , uint borrowBalance, ) = vToken.getAccountSnapshot(address(this));
      if (borrowBalance == 0) {
        uint vTokenBalance = vToken.balanceOf(address(this));
        if (vTokenBalance > 0) VBep20Interface(address(vToken)).redeemUnderlying(vTokenBalance);
        uint tokenBalance = IERC20(VBep20Interface(address(vToken)).underlying()).balanceOf(address(this));
        if (tokenBalance > 0) IERC20(VBep20Interface(address(vToken)).underlying()).transfer(msg.sender, tokenBalance);
      }
      unchecked {
        i++;
      }
    }
  }

  //
  // vToken management
  //

  function enableVTokens(address[] memory vTokens) public onlyOwner {
    for (uint i = 0; i < vTokens.length; ) {
      enabledVTokens.add(vTokens[i]);

      IERC20 vuToken = IERC20(
        vTokens[i] != address(0xA07c5b74C9B40447a954e1466938b865b6BBea36)
          ? address(VBep20Interface(vTokens[i]).underlying()) // NOT vBNB, use underlying token
          : 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c // is vBNB, use wrapped BNB
      );

      vuToken.approve(address(vTokens[i]), type(uint).max); // For minting vToken
      // vuToken.approve(address(paraswap), type(uint).max); // For swapping vToken
      vuToken.approve(address(paraswapTokenProxy), type(uint).max); // For swapping vToken

      unchecked {
        i++;
      }
    }
    comptroller.enterMarkets(vTokens);
  }

  function disableVTokens(address[] memory vTokens) public onlyOwner {
    for (uint i = 0; i < vTokens.length; ) {
      enabledVTokens.remove(vTokens[i]);
      uint err = comptroller.exitMarket(vTokens[i]);
      require(err == 0, string(abi.encodePacked('Disable vToken failed with ', err)));
      unchecked {
        i++;
      }
    }
  }

  function getEnabledVTokens() public view returns (address[] memory) {
    return enabledVTokens.values();
  }

  function isEnabledVToken(address token) public view returns (bool) {
    return enabledVTokens.contains(token);
  }

  /// @dev Converts the input VToken amount to USDC value
  function getVTokenValue(VTokenInterface token, uint256 amount) public view returns (uint256) {
    return (token.exchangeRateStored() * amount) / 1e18;
  }

  function getAccountLiquidity() public view returns (uint256 err, uint256 collateral, uint256 shortfall) {
    (err, collateral, shortfall) = comptroller.getAccountLiquidity(address(this));
    // NOTE: collateral is returned as 0.8 of total deposit, but we do our own calculation
    collateral = (collateral * 1e18 * 125) / 100 / 1e18;
  }

  function withdrawVToken(address vToken, uint256 amount) public onlyOwner {
    require(VBep20Interface(vToken).transfer(msg.sender, amount), 'Fail to withdraw vToken');
  }

  function withdrawVTokenAll(address vToken) public onlyOwner {
    withdrawVToken(vToken, VBep20Interface(vToken).balanceOf(address(this)));
  }

  function withdrawBSC() public onlyOwner {
    (bool sent, ) = msg.sender.call{ value: address(this).balance }('');
    require(sent, 'Fail to send');
  }

  function approveVToken(address vToken, address spender, uint256 amount) public onlyOwner {
    VBep20Interface(vToken).approve(spender, amount);
  }
}