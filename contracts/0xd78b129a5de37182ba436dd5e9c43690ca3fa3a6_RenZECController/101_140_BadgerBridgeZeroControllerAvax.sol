// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma abicoder v2;

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { JoeLibrary } from "../libraries/JoeLibrary.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";
import { IERC2612Permit } from "../interfaces/IERC2612Permit.sol";
import { IRenCrv } from "../interfaces/CurvePools/IRenCrv.sol";
import { SplitSignatureLib } from "../libraries/SplitSignatureLib.sol";
import { IBadgerSettPeak } from "../interfaces/IBadgerSettPeak.sol";
import { ICurveFi } from "../interfaces/ICurveFiAvax.sol";
import { IGateway } from "../interfaces/IGateway.sol";
import { ICurveUInt256 } from "../interfaces/CurvePools/ICurveUInt256.sol";
import { ICurveInt128 } from "../interfaces/CurvePools/ICurveInt128Avax.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IyVault } from "../interfaces/IyVault.sol";
import { ISett } from "../interfaces/ISett.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/cryptography/ECDSA.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";
import { ICurveFi as ICurveFiRen } from "../interfaces/ICurveFi.sol";
import { IJoeRouter02 } from "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeRouter02.sol";

contract BadgerBridgeZeroControllerAvax is EIP712Upgradeable {
  using SafeERC20 for IERC20;
  using SafeMath for *;
  uint256 public fee;
  address public governance;
  address public strategist;

  address constant btcGateway = 0x05Cadbf3128BcB7f2b89F3dD55E5B0a036a49e20;
  address constant factory = 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10;
  address constant crvUsd = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
  address constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
  address constant usdc = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
  address constant usdc_native = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
  address constant usdcpool = 0x3a43A5851A3e3E0e25A3c1089670269786be1577;
  address constant wavax = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
  address constant weth = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
  address constant wbtc = 0x50b7545627a5162F82A992c33b87aDc75187B218;
  address constant avWbtc = 0x686bEF2417b6Dc32C50a3cBfbCC3bb60E1e9a15D;
  address constant renbtc = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;
  address constant renCrv = 0x16a7DA911A4DD1d83F3fF066fE28F3C792C50d90;
  address constant tricrypto = 0xB755B949C126C04e0348DD881a5cF55d424742B2;
  address constant renCrvLp = 0xC2b1DF84112619D190193E48148000e3990Bf627;
  address constant joeRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
  address constant bCrvRen = 0x6dEf55d2e18486B9dDfaA075bc4e4EE0B28c1545;
  address constant settPeak = 0x41671BA1abcbA387b9b2B752c205e22e916BE6e3;
  address constant ibbtc = 0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F;
  uint256 public governanceFee;
  bytes32 constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
  uint256 constant GAS_COST = uint256(124e4);
  uint256 constant IBBTC_GAS_COST = uint256(7e5);
  uint256 constant ETH_RESERVE = uint256(5 ether);
  bytes32 constant LOCK_SLOT = keccak256("upgrade-lock-v1-avax");
  uint256 internal renbtcForOneETHPrice;
  uint256 internal burnFee;
  uint256 public keeperReward;
  uint256 public constant REPAY_GAS_DIFF = 41510;
  uint256 public constant BURN_GAS_DIFF = 41118;
  mapping(address => uint256) public nonces;
  mapping(address => uint256) public noncesUsdc;
  bytes32 internal PERMIT_DOMAIN_SEPARATOR_WBTC;
  bytes32 internal PERMIT_DOMAIN_SEPARATOR_IBBTC;
  bytes32 internal PERMIT_DOMAIN_SEPARATOR_USDC;

  function setStrategist(address _strategist) public {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  function postUpgrade() public {
    bool isLocked;
    bytes32 upgradeSlot = LOCK_SLOT;

    assembly {
      isLocked := sload(upgradeSlot)
    }
    require(!isLocked, "already upgraded");
    IERC20(usdc).safeApprove(usdcpool, ~uint256(0) >> 2);
    IERC20(usdc_native).safeApprove(usdcpool, ~uint256(0) >> 2);
    isLocked = true;
    assembly {
      sstore(upgradeSlot, isLocked)
    }
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function computeCalldataGasDiff() internal pure returns (uint256 diff) {
    if (true) return 0; // TODO: implement exact gas metering
    // EVM charges less for zero bytes, we must compute the offset for refund
    // TODO make this efficient
    uint256 sz;
    assembly {
      sz := calldatasize()
    }
    diff = sz.mul(uint256(68));
    bytes memory slice;
    for (uint256 i = 0; i < sz; i += 0x20) {
      uint256 word;
      assembly {
        word := calldataload(i)
      }
      for (uint256 i = 0; i < 256 && ((uint256(~0) << i) & word) != 0; i += 8) {
        if ((word >> i) & 0xff != 0) diff -= 64;
      }
    }
  }

  function getChainId() internal pure returns (uint256 result) {
    assembly {
      result := chainid()
    }
  }

  function setParameters(
    uint256 _governanceFee,
    uint256 _fee,
    uint256 _burnFee,
    uint256 _keeperReward
  ) public {
    require(governance == msg.sender, "!governance");
    governanceFee = _governanceFee;
    fee = _fee;
    burnFee = _burnFee;
    keeperReward = _keeperReward;
  }

  function initialize(address _governance, address _strategist) public initializer {
    fee = uint256(25e14);
    burnFee = uint256(4e15);
    governanceFee = uint256(5e17);
    governance = _governance;
    strategist = _strategist;
    keeperReward = uint256(1 ether).div(1000);
    //IERC20(renbtc).safeApprove(btcGateway, ~uint256(0) >> 2);
    IERC20(renbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(avWbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(avWbtc).safeApprove(tricrypto, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(joeRouter, ~uint256(0) >> 2);
    IERC20(weth).safeApprove(tricrypto, ~uint256(0) >> 2);
    IERC20(weth).safeApprove(joeRouter, ~uint256(0) >> 2);
    IERC20(wavax).safeApprove(joeRouter, ~uint256(0) >> 2);
    IERC20(av3Crv).safeApprove(crvUsd, ~uint256(0) >> 2);
    IERC20(av3Crv).safeApprove(tricrypto, ~uint256(0) >> 2);
    IERC20(usdc).safeApprove(crvUsd, ~uint256(0) >> 2);
    IERC20(usdc).safeApprove(usdcpool, ~uint256(0) >> 2);
    IERC20(usdc_native).safeApprove(usdcpool, ~uint256(0) >> 2);
    IERC20(renCrvLp).safeApprove(bCrvRen, ~uint256(0) >> 2);
    //IERC20(bCrvRen).safeApprove(settPeak, ~uint256(0) >> 2);
    PERMIT_DOMAIN_SEPARATOR_WBTC = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("WBTC"),
        keccak256("1"),
        getChainId(),
        wbtc
      )
    );
    PERMIT_DOMAIN_SEPARATOR_USDC = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("USD Coin"),
        keccak256("1"),
        getChainId(),
        usdc
      )
    );
    PERMIT_DOMAIN_SEPARATOR_IBBTC = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("ibBTC"),
        keccak256("1"),
        getChainId(),
        ibbtc
      )
    );
  }

  function applyRatio(uint256 v, uint256 n) internal pure returns (uint256 result) {
    result = v.mul(n).div(uint256(1 ether));
  }

  function toWBTC(uint256 amount, bool useUnderlying) internal returns (uint256 amountOut) {
    if (useUnderlying) amountOut = ICurveInt128(renCrv).exchange_underlying(1, 0, amount, 1);
    else amountOut = ICurveInt128(renCrv).exchange(1, 0, amount, 1);
  }

  function toIBBTC(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256[2] memory amounts;
    amounts[0] = amountIn;
    ICurveFiRen(renCrv).add_liquidity(amounts, 0);
    ISett(bCrvRen).deposit(IERC20(renCrvLp).balanceOf(address(this)));
    amountOut = IBadgerSettPeak(settPeak).mint(0, IERC20(bCrvRen).balanceOf(address(this)), new bytes32[](0));
  }

  function toUSDC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 usdAmount = IERC20(av3Crv).balanceOf(address(this));
    uint256 wbtcAmount = toWBTC(amountIn, false);
    ICurveUInt256(tricrypto).exchange(1, 0, wbtcAmount, 1);
    usdAmount = IERC20(av3Crv).balanceOf(address(this)).sub(usdAmount);
    amountOut = ICurveFi(crvUsd).remove_liquidity_one_coin(usdAmount, 1, 1, true);
  }

  function toUSDCNative(uint256 amountIn) internal returns (uint256 amountOut) {
    amountOut = toUSDC(1, amountIn);
    amountOut = ICurveInt128(usdcpool).exchange(0, 1, amountOut, 1, address(this));
  }

  function quote() internal {
    (uint256 amountWavax, uint256 amountWBTC) = JoeLibrary.getReserves(factory, wavax, wbtc);
    uint256 amount = JoeLibrary.quote(1 ether, amountWavax, amountWBTC);
    renbtcForOneETHPrice = ICurveInt128(renCrv).get_dy(1, 0, amount);
  }

  function toRenBTC(uint256 amountIn, bool useUnderlying) internal returns (uint256 amountOut) {
    if (useUnderlying) amountOut = ICurveInt128(renCrv).exchange_underlying(0, 1, amountIn, 1);
    else amountOut = ICurveInt128(renCrv).exchange(0, 1, amountIn, 1);
  }

  function renBTCtoETH(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    uint256 wbtcAmount = toWBTC(amountIn, true);
    address[] memory path = new address[](2);
    path[0] = wbtc;
    path[1] = wavax;
    uint256[] memory amounts = IJoeRouter02(joeRouter).swapExactTokensForAVAX(
      wbtcAmount,
      minOut,
      path,
      out,
      block.timestamp + 1
    );
    amountOut = amounts[1];
  }

  function fromIBBTC(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 amountStart = IERC20(renbtc).balanceOf(address(this));
    IBadgerSettPeak(settPeak).redeem(0, amountIn);
    ISett(bCrvRen).withdraw(IERC20(bCrvRen).balanceOf(address(this)));
    ICurveFiRen(renCrv).remove_liquidity_one_coin(IERC20(renCrvLp).balanceOf(address(this)), 0, 0);
    amountOut = IERC20(renbtc).balanceOf(address(this)).sub(amountStart);
  }

  function fromUSDC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 wbtcAmount = IERC20(avWbtc).balanceOf(address(this));
    uint256[3] memory amounts;
    amounts[1] = amountIn;
    amountOut = ICurveFi(crvUsd).add_liquidity(amounts, 1, true);
    ICurveUInt256(tricrypto).exchange(0, 1, amountOut, 1);
    wbtcAmount = IERC20(avWbtc).balanceOf(address(this)).sub(wbtcAmount);
    amountOut = toRenBTC(wbtcAmount, false);
  }

  function fromUSDCNative(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 usdceAmountIn = ICurveInt128(usdcpool).exchange(1, 0, amountIn, 1, address(this));
    return fromUSDC(1, usdceAmountIn);
  }

  function fromETHToRenBTC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    address[] memory path = new address[](2);
    path[0] = wavax;
    path[1] = wbtc;

    uint256[] memory amounts = IJoeRouter02(joeRouter).swapExactAVAXForTokens{ value: amountIn }(
      minOut,
      path,
      address(this),
      block.timestamp + 1
    );
    amountOut = toRenBTC(amounts[1], true);
  }

  function toETH() internal returns (uint256 amountOut) {
    uint256 wbtcAmount = IERC20(wbtc).balanceOf(address(this));
    address[] memory path = new address[](2);
    path[0] = wbtc;
    path[1] = wavax;
    uint256[] memory amounts = IJoeRouter02(joeRouter).swapExactTokensForAVAX(
      wbtcAmount,
      1,
      path,
      address(this),
      block.timestamp + 1
    );
    amountOut = amounts[1];
  }

  receive() external payable {
    // no-op
  }

  function earn() public {
    quote();
    toWBTC(IERC20(renbtc).balanceOf(address(this)), true);
    toETH();
    uint256 balance = address(this).balance;
    if (balance > ETH_RESERVE) {
      uint256 output = balance - ETH_RESERVE;
      uint256 toGovernance = applyRatio(output, governanceFee);
      address payable governancePayable = address(uint160(governance));
      governancePayable.transfer(toGovernance);
      address payable strategistPayable = address(uint160(strategist));
      strategistPayable.transfer(output.sub(toGovernance));
    }
  }

  function computeRenBTCGasFee(uint256 gasCost, uint256 gasPrice) internal view returns (uint256 result) {
    result = gasCost.mul(tx.gasprice).mul(renbtcForOneETHPrice).div(uint256(1 ether));
  }

  function deductMintFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, fee, multiplier));
  }

  function deductIBBTCMintFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyIBBTCFee(amountIn, fee, multiplier));
  }

  function deductBurnFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, burnFee, multiplier));
  }

  function deductIBBTCBurnFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyIBBTCFee(amountIn, burnFee, multiplier));
  }

  function applyFee(
    uint256 amountIn,
    uint256 _fee,
    uint256 multiplier
  ) internal view returns (uint256 amount) {
    amount = computeRenBTCGasFee(GAS_COST.add(keeperReward.div(tx.gasprice)), tx.gasprice).add(
      applyRatio(amountIn, _fee)
    );
  }

  function applyIBBTCFee(
    uint256 amountIn,
    uint256 _fee,
    uint256 multiplier
  ) internal view returns (uint256 amount) {
    amount = computeRenBTCGasFee(IBBTC_GAS_COST.add(keeperReward.div(tx.gasprice)), tx.gasprice).add(
      applyRatio(amountIn, _fee)
    );
  }

  struct LoanParams {
    address to;
    address asset;
    uint256 nonce;
    uint256 amount;
    address module;
    address underwriter;
    bytes data;
    uint256 minOut;
    uint256 _mintAmount;
    uint256 gasDiff;
  }

  function toTypedDataHash(LoanParams memory params) internal view returns (bytes32 result) {
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256(
            "TransferRequest(address asset,uint256 amount,address underwriter,address module,uint256 nonce,bytes data)"
          ),
          params.asset,
          params.amount,
          params.underwriter,
          params.module,
          params.nonce,
          keccak256(params.data)
        )
      )
    );
    return digest;
  }

  function repay(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public returns (uint256 amountOut) {
    require(msg.data.length <= 516, "too much calldata");
    uint256 _gasBefore = gasleft();
    LoanParams memory params;
    {
      require(
        module == wbtc || module == usdc || module == renbtc || module == address(0x0) || module == usdc_native,
        "!approved-module"
      );
      params = LoanParams({
        to: to,
        asset: asset,
        amount: amount,
        nonce: nonce,
        module: module,
        underwriter: underwriter,
        data: data,
        minOut: 1,
        _mintAmount: 0,
        gasDiff: computeCalldataGasDiff()
      });
      if (data.length > 0) (params.minOut) = abi.decode(data, (uint256));
    }
    bytes32 digest = toTypedDataHash(params);

    params._mintAmount = IGateway(btcGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    {
      amountOut = module == wbtc ? toWBTC(deductMintFee(params._mintAmount, 1), true) : module == address(0x0)
        ? renBTCtoETH(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : module == usdc
        ? toUSDC(params.minOut, deductMintFee(params._mintAmount, 1))
        : module == usdc_native
        ? toUSDCNative(deductMintFee(params._mintAmount, 1))
        : deductMintFee(params._mintAmount, 1);
    }
    {
      if (module != address(0x0)) IERC20(module).safeTransfer(to, amountOut);
    }
    {
      tx.origin.transfer(
        Math.min(
          _gasBefore.sub(gasleft()).add(REPAY_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function computeBurnNonce(BurnLocals memory params) internal view returns (uint256 result) {
    result = uint256(
      keccak256(
        abi.encodePacked(params.asset, params.amount, params.deadline, params.nonce, params.data, params.destination)
      )
    );
    while (result < block.timestamp) {
      // negligible probability of this
      result = uint256(keccak256(abi.encodePacked(result)));
    }
  }

  function computeERC20PermitDigest(bytes32 domainSeparator, BurnLocals memory params)
    internal
    view
    returns (bytes32 result)
  {
    result = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        keccak256(abi.encode(PERMIT_TYPEHASH, params.to, address(this), params.nonce, computeBurnNonce(params), true))
      )
    );
  }

  struct BurnLocals {
    address to;
    address asset;
    uint256 amount;
    uint256 deadline;
    uint256 nonce;
    bytes data;
    uint256 minOut;
    uint256 burnNonce;
    uint256 gasBefore;
    uint256 gasDiff;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes destination;
    bytes signature;
  }

  function burn(
    address to,
    address asset,
    uint256 amount,
    uint256 deadline,
    bytes memory data,
    bytes memory destination,
    bytes memory signature
  ) public returns (uint256 amountToBurn) {
    require(msg.data.length <= 580, "too much calldata");
    BurnLocals memory params = BurnLocals({
      to: to,
      asset: asset,
      amount: amount,
      deadline: deadline,
      data: data,
      nonce: 0,
      burnNonce: 0,
      v: uint8(0),
      r: bytes32(0),
      s: bytes32(0),
      destination: destination,
      signature: signature,
      gasBefore: gasleft(),
      minOut: 1,
      gasDiff: 0
    });
    {
      params.gasDiff = computeCalldataGasDiff();
      if (params.data.length > 0) (params.minOut) = abi.decode(params.data, (uint256));
    }
    require(block.timestamp < params.deadline, "!deadline");

    if (params.asset == wbtc) {
      params.nonce = nonces[to];
      nonces[params.to]++;
      require(
        params.to == ECDSA.recover(computeERC20PermitDigest(PERMIT_DOMAIN_SEPARATOR_WBTC, params), params.signature),
        "!signature"
      ); //  wbtc does not implement ERC20Permit
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
        amountToBurn = toRenBTC(deductBurnFee(params.amount, 1), true);
      }
    } else if (asset == usdc_native) {
      {
        params.nonce = IERC2612Permit(params.asset).nonces(params.to);
        params.burnNonce = computeBurnNonce(params);
      }
      {
        (params.v, params.r, params.s) = SplitSignatureLib.splitSignature(params.signature);
        IERC2612Permit(params.asset).permit(
          params.to,
          address(this),
          params.amount,
          params.burnNonce,
          params.v,
          params.r,
          params.s
        );
      }
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
        amountToBurn = deductBurnFee(fromUSDCNative(params.amount), 1);
      }
    } else if (params.asset == renbtc) {
      {
        params.nonce = IERC2612Permit(params.asset).nonces(params.to);
        params.burnNonce = computeBurnNonce(params);
      }
      {
        (params.v, params.r, params.s) = SplitSignatureLib.splitSignature(params.signature);
        IERC2612Permit(params.asset).permit(
          params.to,
          address(this),
          params.nonce,
          params.burnNonce,
          true,
          params.v,
          params.r,
          params.s
        );
      }
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(params.amount, 1);
    } else if (params.asset == usdc) {
      params.nonce = noncesUsdc[to];
      noncesUsdc[params.to]++;
      require(
        params.to == ECDSA.recover(computeERC20PermitDigest(PERMIT_DOMAIN_SEPARATOR_USDC, params), params.signature),
        "!signature"
      ); //  usdc.e does not implement ERC20Permit
      {
        IERC20(params.asset).transferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(fromUSDC(params.minOut, params.amount), 1);
    } else revert("!supported-asset");
    {
      IGateway(btcGateway).burn(params.destination, amountToBurn);
    }
    {
      tx.origin.transfer(
        Math.min(
          params.gasBefore.sub(gasleft()).add(BURN_GAS_DIFF).add(params.gasDiff).mul(tx.gasprice).add(keeperReward),
          address(this).balance
        )
      );
    }
  }

  function burnETH(uint256 minOut, bytes memory destination) public payable returns (uint256 amountToBurn) {
    amountToBurn = fromETHToRenBTC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(btcGateway).burn(destination, amountToBurn);
  }

  function burnApproved(
    address from,
    address asset,
    uint256 amount,
    uint256 minOut,
    bytes memory destination
  ) public payable returns (uint256 amountToBurn) {
    require(asset == wbtc || asset == usdc || asset == renbtc || asset == address(0x0), "!approved-module");
    if (asset != address(0x0)) IERC20(asset).transferFrom(msg.sender, address(this), amount);
    amountToBurn = asset == wbtc ? toRenBTC(amount.sub(applyRatio(amount, burnFee)), true) : asset == usdc
      ? fromUSDC(minOut, amount.sub(applyRatio(amount, burnFee)))
      : asset == renbtc
      ? amount
      : fromETHToRenBTC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(btcGateway).burn(destination, amountToBurn);
  }

  function fallbackMint(
    address underwriter,
    address to,
    address asset,
    uint256 amount,
    uint256 actualAmount,
    uint256 nonce,
    address module,
    bytes32 nHash,
    bytes memory data,
    bytes memory signature
  ) public {
    LoanParams memory params = LoanParams({
      to: to,
      asset: asset,
      amount: amount,
      nonce: nonce,
      module: module,
      underwriter: underwriter,
      data: data,
      minOut: 1,
      _mintAmount: 0,
      gasDiff: 0
    });
    bytes32 digest = toTypedDataHash(params);
    uint256 _actualAmount = IGateway(btcGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    IERC20(asset).safeTransfer(to, _actualAmount);
  }
}