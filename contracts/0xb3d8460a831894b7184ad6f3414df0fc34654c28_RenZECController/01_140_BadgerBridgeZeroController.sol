// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { UniswapV2Library } from "../libraries/UniswapV2Library.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";
import { IERC2612Permit } from "../interfaces/IERC2612Permit.sol";
import { IRenCrv } from "../interfaces/CurvePools/IRenCrv.sol";
import { SplitSignatureLib } from "../libraries/SplitSignatureLib.sol";
import { IBadgerSettPeak } from "../interfaces/IBadgerSettPeak.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { ICurveFi } from "../interfaces/ICurveFi.sol";
import { IGateway } from "../interfaces/IGateway.sol";
import { ICurveTricrypto } from "../interfaces/CurvePools/ICurveTricrypto.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IyVault } from "../interfaces/IyVault.sol";
import { ISett } from "../interfaces/ISett.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/cryptography/ECDSA.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";

contract BadgerBridgeZeroController is EIP712Upgradeable {
  using SafeERC20 for IERC20;
  using SafeMath for *;
  uint256 public fee;
  address public governance;
  address public strategist;

  address constant btcGateway = 0xe4b679400F0f267212D5D812B95f58C83243EE71;
  address constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address constant routerv3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  address constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address constant renbtc = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
  address constant renCrv = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
  address constant threepool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
  address constant tricrypto = 0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5;
  address constant renCrvLp = 0x49849C98ae39Fff122806C06791Fa73784FB3675;
  address constant bCrvRen = 0x6dEf55d2e18486B9dDfaA075bc4e4EE0B28c1545;
  address constant settPeak = 0x41671BA1abcbA387b9b2B752c205e22e916BE6e3;
  address constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  uint24 constant wethWbtcFee = 500;
  uint24 constant usdcWethFee = 500;
  uint256 public governanceFee;
  bytes32 constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
  bytes32 constant LOCK_SLOT = keccak256("upgrade-lock-v3");
  uint256 constant GAS_COST = uint256(42e4);
  uint256 constant ETH_RESERVE = uint256(5 ether);
  uint256 internal renbtcForOneETHPrice;
  uint256 internal burnFee;
  uint256 public keeperReward;
  uint256 public constant REPAY_GAS_DIFF = 41510;
  uint256 public constant BURN_GAS_DIFF = 41118;
  mapping(address => uint256) public nonces;
  bytes32 internal PERMIT_DOMAIN_SEPARATOR_WBTC;
  mapping(address => uint256) public noncesUsdt;
  bytes32 constant PERMIT_DOMAIN_SEPARATOR_USDT_SLOT = keccak256("usdt-permit");

  function getUsdtDomainSeparator() public view returns (bytes32) {
    bytes32 separator_slot = PERMIT_DOMAIN_SEPARATOR_USDT_SLOT;
    bytes32 separator;
    assembly {
      separator := sload(separator_slot)
    }
    return separator;
  }

  function setStrategist(address _strategist) public {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function approveUpgrade(bool lock) public {
    bool isLocked;
    bytes32 lock_slot = LOCK_SLOT;
    bytes32 permit_slot = PERMIT_DOMAIN_SEPARATOR_USDT_SLOT;

    assembly {
      isLocked := sload(lock_slot)
    }
    require(!isLocked, "cannot run upgrade function");

    IERC20(usdt).safeApprove(tricrypto, ~uint256(0) >> 2);
    bytes32 permit_usdt_separator = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("USDT"),
        keccak256("1"),
        getChainId(),
        usdt
      )
    );

    assembly {
      sstore(lock_slot, lock)
      sstore(permit_slot, permit_usdt_separator)
    }
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
    IERC20(renbtc).safeApprove(btcGateway, ~uint256(0) >> 2);
    IERC20(renbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(renCrv, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(tricrypto, ~uint256(0) >> 2);
    IERC20(usdt).safeApprove(tricrypto, ~uint256(0) >> 2);
    IERC20(wbtc).safeApprove(routerv3, ~uint256(0) >> 2);
    IERC20(usdc).safeApprove(routerv3, ~uint256(0) >> 2);
    PERMIT_DOMAIN_SEPARATOR_WBTC = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("WBTC"),
        keccak256("1"),
        getChainId(),
        wbtc
      )
    );
    bytes32 permit_separator_usdt = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("USDT"),
        keccak256("1"),
        getChainId(),
        usdt
      )
    );
    bytes32 permit_slot = PERMIT_DOMAIN_SEPARATOR_USDT_SLOT;
    assembly {
      sstore(permit_slot, permit_separator_usdt)
    }
  }

  function applyRatio(uint256 v, uint256 n) internal pure returns (uint256 result) {
    result = v.mul(n).div(uint256(1 ether));
  }

  function toWBTC(uint256 amount) internal returns (uint256 amountOut) {
    uint256 amountStart = IERC20(wbtc).balanceOf(address(this));
    (bool success, ) = renCrv.call(abi.encodeWithSelector(IRenCrv.exchange.selector, 0, 1, amount));
    amountOut = IERC20(wbtc).balanceOf(address(this)).sub(amountStart);
  }

  function toUSDC(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    uint256 wbtcAmountIn = toWBTC(amountIn);
    bytes memory path = abi.encodePacked(wbtc, wethWbtcFee, weth, usdcWethFee, usdc);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: out,
      deadline: block.timestamp + 1,
      amountIn: wbtcAmountIn,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput(params);
  }

  function quote() internal {
    (uint256 amountWeth, uint256 amountRenBTC) = UniswapV2Library.getReserves(factory, weth, renbtc);
    renbtcForOneETHPrice = UniswapV2Library.quote(uint256(1 ether), amountWeth, amountRenBTC);
  }

  function renBTCtoETH(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    uint256 wbtcAmountOut = toWBTC(amountIn);
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: wbtc,
      tokenOut: weth,
      fee: wethWbtcFee,
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: wbtcAmountOut,
      amountOutMinimum: minOut,
      sqrtPriceLimitX96: 0
    });
    amountOut = ISwapRouter(routerv3).exactInputSingle(params);
    IWETH(weth).withdraw(amountOut);
    address payable recipient = address(uint160(out));
    recipient.transfer(amountOut);
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
    amountToBurn = asset == wbtc ? toRenBTC(amount.sub(applyRatio(amount, burnFee))) : asset == usdc
      ? fromUSDC(minOut, amount.sub(applyRatio(amount, burnFee)))
      : asset == renbtc
      ? amount
      : fromETHToRenBTC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(btcGateway).burn(destination, amountToBurn);
  }

  function toRenBTC(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 balanceStart = IERC20(renbtc).balanceOf(address(this));
    (bool success, ) = renCrv.call(abi.encodeWithSelector(IRenCrv.exchange.selector, 1, 0, amountIn));
    amountOut = IERC20(renbtc).balanceOf(address(this)).sub(balanceStart);
  }

  function fromUSDC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    bytes memory path = abi.encodePacked(usdc, usdcWethFee, weth, wethWbtcFee, wbtc);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: amountIn,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput(params);
    amountOut = toRenBTC(amountOut);
  }

  function fromETHToRenBTC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 amountStart = IERC20(renbtc).balanceOf(address(this));
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: weth,
      tokenOut: wbtc,
      fee: wethWbtcFee,
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: amountIn,
      amountOutMinimum: minOut,
      sqrtPriceLimitX96: 0
    });
    amountOut = ISwapRouter(routerv3).exactInputSingle{ value: amountIn }(params);
    (bool success, ) = renCrv.call(abi.encodeWithSelector(IRenCrv.exchange.selector, 1, 0, amountOut, 1));
    require(success, "!curve");
    amountOut = IERC20(renbtc).balanceOf(address(this)).sub(amountStart);
  }

  function toETH() internal returns (uint256 amountOut) {
    uint256 wbtcStart = IERC20(wbtc).balanceOf(address(this));

    uint256 amountStart = address(this).balance;
    (bool success, ) = tricrypto.call(
      abi.encodeWithSelector(ICurveTricrypto.exchange.selector, 1, 2, wbtcStart, 0, true)
    );
    amountOut = address(this).balance.sub(amountStart);
  }

  function fromUSDT(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 wbtcIn = IERC20(wbtc).balanceOf(address(this));
    (bool success, ) = tricrypto.call(
      abi.encodeWithSelector(ICurveTricrypto.exchange.selector, 0, 1, amountIn, 0, false)
    );
    require(success, "!curve");
    wbtcIn = IERC20(wbtc).balanceOf(address(this)).sub(wbtcIn);
    amountOut = toRenBTC(wbtcIn);
  }

  function toUSDT(uint256 amountIn) internal returns (uint256 amountOut) {
    uint256 wbtcOut = toWBTC(amountIn);
    amountOut = IERC20(usdt).balanceOf(address(this));
    (bool success, ) = tricrypto.call(
      abi.encodeWithSelector(ICurveTricrypto.exchange.selector, 1, 0, wbtcOut, 0, false)
    );
    require(success, "!curve");
    amountOut = IERC20(usdt).balanceOf(address(this)).sub(amountOut);
  }

  receive() external payable {
    // no-op
  }

  function earn() public {
    quote();
    toWBTC(IERC20(renbtc).balanceOf(address(this)));
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

  function deductBurnFee(uint256 amountIn, uint256 multiplier) internal view returns (uint256 amount) {
    amount = amountIn.sub(applyFee(amountIn, burnFee, multiplier));
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
        module == wbtc || module == usdc || module == renbtc || module == usdt || module == address(0x0),
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
      amountOut = module == wbtc ? toWBTC(deductMintFee(params._mintAmount, 1)) : module == address(0x0)
        ? renBTCtoETH(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : module == usdt
        ? toUSDT(deductMintFee(params._mintAmount, 1))
        : module == usdc
        ? toUSDC(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : deductMintFee(params._mintAmount, 1);
    }
    {
      if (module != usdc && module != address(0x0)) IERC20(module).safeTransfer(to, amountOut);
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
        amountToBurn = toRenBTC(deductBurnFee(params.amount, 1));
      }
    } else if (params.asset == usdt) {
      params.nonce = noncesUsdt[to];
      noncesUsdt[params.to]++;
      require(
        params.to == ECDSA.recover(computeERC20PermitDigest(getUsdtDomainSeparator(), params), params.signature),
        "!signature"
      ); //  usdt does not implement ERC20Permit
      {
        (bool success, ) = params.asset.call(
          abi.encodeWithSelector(IERC20.transferFrom.selector, params.to, address(this), params.amount)
        );
        require(success, "!usdt");
      }
      amountToBurn = deductBurnFee(fromUSDT(params.amount), 1);
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