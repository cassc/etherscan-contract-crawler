// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { UniswapV2Library } from "../libraries/UniswapV2Library.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";
import { IERC2612Permit } from "../interfaces/IERC2612Permit.sol";
import { SplitSignatureLib } from "../libraries/SplitSignatureLib.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { IGateway } from "../interfaces/IGateway.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/cryptography/ECDSA.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";

contract RenZECController is EIP712Upgradeable {
  using SafeERC20 for IERC20;
  using SafeMath for *;
  uint256 public fee;
  address public governance;
  address public strategist;

  address constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address constant renzec = 0x1C5db575E2Ff833E46a2E9864C22F4B22E0B37C2;
  address constant zecGateway = 0xc3BbD5aDb611dd74eCa6123F05B18acc886e122D;
  address constant routerv3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  address constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
  uint24 constant uniswapv3Fee = 500;
  uint256 public governanceFee;
  bytes32 constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
  uint256 constant GAS_COST = uint256(23e4);
  bytes32 constant LOCK_SLOT = keccak256("upgrade-v1");
  uint256 constant ETH_RESERVE = uint256(5 ether);
  uint256 internal renzecForOneETHPrice;
  uint256 internal burnFee;
  uint256 public keeperReward;
  uint256 public constant REPAY_GAS_DIFF = 41510;
  uint256 public constant BURN_GAS_DIFF = 41118;
  bytes32 internal PERMIT_DOMAIN_SEPARATOR_USDT;
  mapping(address => uint256) public noncesUsdt;

  function setStrategist(address _strategist) public {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
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
    IERC20(weth).safeApprove(routerv3, ~uint256(0) >> 2);
    IERC20(usdc).safeApprove(routerv3, ~uint256(0) >> 2);
    IERC20(usdt).safeApprove(routerv3, ~uint256(0) >> 2);
    IERC20(weth).safeApprove(router, ~uint256(0) >> 2);
    IERC20(renzec).safeApprove(router, ~uint256(0) >> 2);
    PERMIT_DOMAIN_SEPARATOR_USDT = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("USDT"),
        keccak256("1"),
        getChainId(),
        usdt
      )
    );
  }

  function postUpgrade() public {
    bool isLocked;
    bytes32 upgradeSlot = LOCK_SLOT;

    assembly {
      isLocked := sload(upgradeSlot)
    }

    require(!isLocked, "already upgraded");
    PERMIT_DOMAIN_SEPARATOR_USDT = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("USDT"),
        keccak256("1"),
        getChainId(),
        usdt
      )
    );
    IERC20(usdc).safeApprove(routerv3, ~uint256(0) >> 2);
    IERC20(usdt).safeApprove(routerv3, ~uint256(0) >> 2);

    isLocked = true;
    assembly {
      sstore(upgradeSlot, isLocked)
    }
  }

  function applyRatio(uint256 v, uint256 n) internal pure returns (uint256 result) {
    result = v.mul(n).div(uint256(1 ether));
  }

  function quote() internal {
    (uint256 amountWeth, uint256 amountRenZEC) = UniswapV2Library.getReserves(factory, weth, renzec);
    renzecForOneETHPrice = UniswapV2Library.quote(uint256(1 ether), amountWeth, amountRenZEC);
  }

  function renZECtoETH(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    address[] memory path = new address[](2);
    path[0] = renzec;
    path[1] = weth;
    uint256[] memory amounts = new uint256[](2);
    amounts = IUniswapV2Router02(router).swapExactTokensForETH(amountIn, minOut, path, out, block.timestamp + 1);
    return amounts[1];
  }

  function fromETHToRenZEC(uint256 minOut, uint256 amountIn) internal returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = weth;
    path[1] = renzec;
    uint256[] memory amounts = new uint256[](2);
    amounts = IUniswapV2Router02(router).swapExactETHForTokens{ value: amountIn }(
      minOut,
      path,
      address(this),
      block.timestamp + 1
    );
    return amounts[1];
  }

  function fromUSDC(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    bytes memory path = abi.encodePacked(usdc, uniswapv3Fee, weth);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: amountIn,
      amountOutMinimum: 1,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput(params);
    IWETH(weth).withdraw(amountOut);
    amountOut = fromETHToRenZEC(minOut, amountOut);
  }

  function fromUSDT(uint256 minOut, uint256 amountIn) internal returns (uint256 amountOut) {
    bytes memory path = abi.encodePacked(usdt, uniswapv3Fee, weth);
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: address(this),
      deadline: block.timestamp + 1,
      amountIn: amountIn,
      amountOutMinimum: 1,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput(params);
    IWETH(weth).withdraw(amountOut);
    amountOut = fromETHToRenZEC(minOut, amountOut);
  }

  function toUSDC(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    bytes memory path = abi.encodePacked(weth, uniswapv3Fee, usdc);
    amountOut = renZECtoETH(1, amountIn, address(this));
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: out,
      deadline: block.timestamp + 1,
      amountIn: amountOut,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput{ value: amountOut }(params);
  }

  function toUSDT(
    uint256 minOut,
    uint256 amountIn,
    address out
  ) internal returns (uint256 amountOut) {
    bytes memory path = abi.encodePacked(weth, uniswapv3Fee, usdt);
    amountOut = renZECtoETH(1, amountIn, address(this));
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      recipient: out,
      deadline: block.timestamp + 1,
      amountIn: amountOut,
      amountOutMinimum: minOut,
      path: path
    });
    amountOut = ISwapRouter(routerv3).exactInput{ value: amountOut }(params);
  }

  function toETH() internal returns (uint256 amountOut) {
    address[] memory path = new address[](2);
    path[0] = renzec;
    path[1] = weth;
    uint256[] memory amounts = new uint256[](2);
    IUniswapV2Router02(router).swapExactTokensForETH(
      IERC20(renzec).balanceOf(address(this)),
      1,
      path,
      address(this),
      block.timestamp + 1
    );
  }

  receive() external payable {
    // no-op
  }

  function earn() public {
    quote();
    toETH();
    uint256 balance = address(this).balance;
    if (balance > ETH_RESERVE) {
      uint256 output = balance - ETH_RESERVE;
      uint256 toGovernance = applyRatio(output, governanceFee);
      address payable governancePayable = address(uint160(governance));
      require(governancePayable.send(toGovernance), "error on send");
      address payable strategistPayable = address(uint160(strategist));
      require(strategistPayable.send(output.sub(toGovernance)), "error on send");
    }
  }

  function computeRenZECGasFee(uint256 gasCost, uint256 gasPrice) internal view returns (uint256 result) {
    result = gasCost.mul(tx.gasprice).mul(renzecForOneETHPrice).div(uint256(1 ether));
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
    amount = computeRenZECGasFee(GAS_COST.add(keeperReward.div(tx.gasprice)), tx.gasprice).add(
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
      require(module == usdc || module == usdt || module == address(0x0) || module == renzec, "!approved-module");
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

    params._mintAmount = IGateway(zecGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );

    {
      amountOut = module == address(0x0)
        ? renZECtoETH(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : module == usdc
        ? toUSDC(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : module == usdt
        ? toUSDT(params.minOut, deductMintFee(params._mintAmount, 1), to)
        : deductMintFee(params._mintAmount, 1);
    }
    {
      if (module == renzec) IERC20(module).safeTransfer(to, amountOut);
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

  function burnETH(uint256 minOut, bytes memory destination) public payable returns (uint256 amountToBurn) {
    amountToBurn = fromETHToRenZEC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(zecGateway).burn(destination, amountToBurn);
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
    if (params.asset == renzec) {
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
        IERC20(params.asset).safeTransferFrom(params.to, address(this), params.amount);
      }
      amountToBurn = deductBurnFee(fromUSDC(params.minOut, params.amount), 1);
    } else if (params.asset == usdt) {
      params.nonce = noncesUsdt[to];
      noncesUsdt[params.to]++;
      require(
        params.to == ECDSA.recover(computeERC20PermitDigest(PERMIT_DOMAIN_SEPARATOR_USDT, params), params.signature),
        "!signature"
      ); //  usdt does not implement ERC20Permit
      {
        (bool success, ) = params.asset.call(
          abi.encodeWithSelector(IERC20.transferFrom.selector, params.to, address(this), params.amount)
        );
        require(success, "!usdt");
      }
      amountToBurn = deductBurnFee(fromUSDT(params.minOut, params.amount), 1);
    } else revert("!supported-asset");
    {
      IGateway(zecGateway).burn(params.destination, amountToBurn);
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

  function burnApproved(
    address from,
    address asset,
    uint256 amount,
    uint256 minOut,
    bytes memory destination
  ) public payable returns (uint256 amountToBurn) {
    require(asset == renzec || asset == address(0x0), "!approved-module");
    if (asset != address(0x0)) IERC20(asset).transferFrom(msg.sender, address(this), amount);
    amountToBurn = asset == renzec ? amount : fromETHToRenZEC(minOut, msg.value.sub(applyRatio(msg.value, burnFee)));
    IGateway(zecGateway).burn(destination, amountToBurn);
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
    uint256 _actualAmount = IGateway(zecGateway).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    IERC20(asset).safeTransfer(to, _actualAmount);
  }
}