// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";
import { IERC20 } from "oz410/token/ERC20/ERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { IZeroMeta } from "../interfaces/IZeroMeta.sol";
import { IZeroModule } from "../interfaces/IZeroModule.sol";
import { ZeroUnderwriterLock } from "../underwriter/ZeroUnderwriterLock.sol";
import { ZeroLib } from "../libraries/ZeroLib.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ControllerUpgradeable } from "./ControllerUpgradeable.sol";
import { EIP712 } from "oz410/drafts/EIP712.sol";
import { ECDSA } from "oz410/cryptography/ECDSA.sol";
import { FactoryLib } from "../libraries/factory/FactoryLib.sol";
import { SplitSignatureLib } from "../libraries/SplitSignatureLib.sol";
import { ZeroUnderwriterLockBytecodeLib } from "../libraries/bytecode/ZeroUnderwriterLockBytecodeLib.sol";
import { IGateway } from "../interfaces/IGateway.sol";
import { IGatewayRegistry } from "../interfaces/IGatewayRegistry.sol";
import { IStrategy } from "../interfaces/IStrategy.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";
import { LockForImplLib } from "../libraries/LockForImplLib.sol";
import { IERC2612Permit } from "../interfaces/IERC2612Permit.sol";
import "../interfaces/IConverter.sol";
import { ZeroControllerTemplate } from "./ZeroControllerTemplate.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "hardhat/console.sol";

/**
@title upgradeable contract which determines the authority of a given address to sign off on loans
@author raymondpulver
*/
contract ZeroController is ZeroControllerTemplate {
  using SafeMath for uint256;
  using SafeERC20 for *;

  function getChainId() internal view returns (uint8 response) {
    assembly {
      response := chainid()
    }
  }

  function setFee(uint256 _fee) public {
    require(msg.sender == governance, "!governance");
    fee = _fee;
  }

  function approveModule(address module, bool isApproved) public virtual {
    require(msg.sender == governance, "!governance");
    approvedModules[module] = isApproved;
  }

  function setBaseFeeByAsset(address _asset, uint256 _fee) public {
    require(msg.sender == governance, "!governance");
    baseFeeByAsset[_asset] = _fee;
  }

  function deductFee(uint256 _amount, address _asset) internal view returns (uint256 result) {
    result = _amount.mul(uint256(1 ether).sub(fee)).div(uint256(1 ether)).sub(baseFeeByAsset[_asset]);
  }

  function addFee(uint256 _amount, address _asset) internal view returns (uint256 result) {
    result = _amount.mul(uint256(1 ether).add(fee)).div(uint256(1 ether)).add(baseFeeByAsset[_asset]);
  }

  function initialize(address _rewards, address _gatewayRegistry) public {
    __Ownable_init_unchained();
    __Controller_init_unchained(_rewards);
    __EIP712_init_unchained("ZeroController", "1");
    gatewayRegistry = _gatewayRegistry;
    underwriterLockImpl = FactoryLib.deployImplementation(
      ZeroUnderwriterLockBytecodeLib.get(),
      "zero.underwriter.lock-implementation"
    );

    maxGasPrice = 100e9;
    maxGasRepay = 250000;
    maxGasLoan = 500000;
  }

  modifier onlyUnderwriter() {
    require(ownerOf[uint256(uint160(address(lockFor(msg.sender))))] != address(0x0), "must be called by underwriter");
    _;
  }

  function setGasParameters(
    uint256 _maxGasPrice,
    uint256 _maxGasRepay,
    uint256 _maxGasLoan,
    uint256 _maxGasBurn
  ) public {
    require(msg.sender == governance, "!governance");
    maxGasPrice = _maxGasPrice;
    maxGasRepay = _maxGasRepay;
    maxGasLoan = _maxGasLoan;
    maxGasBurn = _maxGasBurn;
  }

  function balanceOf(address _owner) public view override returns (uint256 result) {
    result = _balanceOf(_owner);
  }

  function lockFor(address underwriter) public view returns (ZeroUnderwriterLock result) {
    result = LockForImplLib.lockFor(address(this), underwriterLockImpl, underwriter);
  }

  function mint(address underwriter, address vault) public virtual {
    address lock = FactoryLib.deploy(underwriterLockImpl, bytes32(uint256(uint160(underwriter))));
    ZeroUnderwriterLock(lock).initialize(vault);
    ownerOf[uint256(uint160(lock))] = msg.sender;
  }

  function _typedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
    ZeroLib.LoanParams memory params = ZeroLib.LoanParams({
      to: to,
      asset: asset,
      amount: amount,
      nonce: nonce,
      module: module,
      data: data
    });
    bytes32 digest = toTypedDataHash(params, underwriter);
    require(loanStatus[digest].status == ZeroLib.LoanStatusCode.UNINITIALIZED, "loan already exists");
    uint256 _actualAmount = IGateway(IGatewayRegistry(gatewayRegistry).getGatewayByToken(asset)).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    delete (loanStatus[digest]);
    IERC20(asset).safeTransfer(to, _actualAmount);
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
  ) public {
    uint256 _gasBefore = gasleft();
    ZeroLib.LoanParams memory params = ZeroLib.LoanParams({
      to: to,
      asset: asset,
      amount: amount,
      nonce: nonce,
      module: module,
      data: data
    });
    bytes32 digest = toTypedDataHash(params, underwriter);
    require(loanStatus[digest].status == ZeroLib.LoanStatusCode.UNPAID, "loan is not in the UNPAID state");

    ZeroUnderwriterLock lock = ZeroUnderwriterLock(lockFor(msg.sender));
    lock.trackIn(actualAmount);
    uint256 _mintAmount = IGateway(IGatewayRegistry(gatewayRegistry).getGatewayByToken(asset)).mint(
      keccak256(abi.encode(params.to, params.nonce, params.module, params.data)),
      actualAmount,
      nHash,
      signature
    );
    IZeroModule(module).repayLoan(params.to, asset, _mintAmount, nonce, data);
    depositAll(asset);
    uint256 _gasRefund = Math.min(_gasBefore.sub(gasleft()), maxGasLoan).mul(maxGasPrice);
    IStrategy(strategies[params.asset]).permissionedEther(tx.origin, _gasRefund);
  }

  function depositAll(address _asset) internal {
    // deposit all of the asset in the vault
    uint256 _balance = IERC20(_asset).balanceOf(address(this));
    IERC20(_asset).safeTransfer(strategies[_asset], _balance);
  }

  function toTypedDataHash(ZeroLib.LoanParams memory params, address underwriter)
    internal
    view
    returns (bytes32 result)
  {
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256(
            "TransferRequest(address asset,uint256 amount,address underwriter,address module,uint256 nonce,bytes data)"
          ),
          params.asset,
          params.amount,
          underwriter,
          params.module,
          params.nonce,
          keccak256(params.data)
        )
      )
    );
    return digest;
  }

  function toMetaTypedDataHash(ZeroLib.MetaParams memory params, address underwriter)
    internal
    view
    returns (bytes32 result)
  {
    result = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256("MetaRequest(address asset,address underwriter,address module,uint256 nonce,bytes data)"),
          params.asset,
          underwriter,
          params.module,
          params.nonce,
          keccak256(params.data)
        )
      )
    );
  }

  function convertGasUsedToRen(uint256 _gasUsed, address asset) internal view returns (uint256 gasUsedInRen) {
    address converter = converters[IStrategy(strategies[asset]).nativeWrapper()][
      IStrategy(strategies[asset]).vaultWant()
    ];
    gasUsedInRen = IConverter(converter).estimate(_gasUsed); //convert txGas from ETH to wBTC
    gasUsedInRen = IConverter(converters[IStrategy(strategies[asset]).vaultWant()][asset]).estimate(gasUsedInRen);
    // ^convert txGas from wBTC to renBTC
  }

  function loan(
    address to,
    address asset,
    uint256 amount,
    uint256 nonce,
    address module,
    bytes memory data,
    bytes memory userSignature
  ) public onlyUnderwriter {
    require(approvedModules[module], "!approved");
    uint256 _gasBefore = gasleft();
    ZeroLib.LoanParams memory params = ZeroLib.LoanParams({
      to: to,
      asset: asset,
      amount: amount,
      nonce: nonce,
      module: module,
      data: data
    });
    bytes32 digest = toTypedDataHash(params, msg.sender);
    require(ECDSA.recover(digest, userSignature) == params.to, "invalid signature");
    require(loanStatus[digest].status == ZeroLib.LoanStatusCode.UNINITIALIZED, "already spent this loan");
    loanStatus[digest] = ZeroLib.LoanStatus({ underwriter: msg.sender, status: ZeroLib.LoanStatusCode.UNPAID });
    uint256 actual = params.amount.sub(params.amount.mul(uint256(25e15)).div(1e18));

    ZeroUnderwriterLock(lockFor(msg.sender)).trackOut(params.module, actual);
    uint256 _txGas = maxGasPrice.mul(maxGasRepay.add(maxGasLoan));
    _txGas = convertGasUsedToRen(_txGas, params.asset);
    // ^convert txGas from ETH to renBTC
    uint256 _amountSent = IStrategy(strategies[params.asset]).permissionedSend(
      module,
      deductFee(params.amount, params.asset).sub(_txGas)
    );
    IZeroModule(module).receiveLoan(params.to, params.asset, _amountSent, params.nonce, params.data);
    uint256 _gasRefund = Math.min(_gasBefore.sub(gasleft()), maxGasLoan).mul(maxGasPrice);
    IStrategy(strategies[params.asset]).permissionedEther(tx.origin, _gasRefund);
  }

  struct MetaLocals {
    uint256 gasUsed;
    uint256 gasUsedInRen;
    bytes32 digest;
    uint256 txGas;
    uint256 gasAtStart;
    uint256 gasRefund;
    uint256 balanceBefore;
    uint256 renBalanceDiff;
  }

  function meta(
    address from,
    address asset,
    address module,
    uint256 nonce,
    bytes memory data,
    bytes memory signature
  ) public onlyUnderwriter returns (uint256 gasValueAndFee) {
    require(approvedModules[module], "!approved");
    MetaLocals memory locals;
    locals.gasAtStart = gasleft();
    ZeroLib.MetaParams memory params = ZeroLib.MetaParams({
      from: from,
      asset: asset,
      module: module,
      nonce: nonce,
      data: data
    });

    ZeroUnderwriterLock lock = ZeroUnderwriterLock(lockFor(msg.sender));
    locals.digest = toMetaTypedDataHash(params, msg.sender);
    address recovered = ECDSA.recover(locals.digest, signature);
    require(recovered == params.from, "invalid signature");
    IZeroMeta(module).receiveMeta(from, asset, nonce, data);
    address converter = converters[IStrategy(strategies[params.asset]).nativeWrapper()][
      IStrategy(strategies[params.asset]).vaultWant()
    ];

    //calculate gas used
    locals.gasUsed = Math.min(locals.gasAtStart.sub(gasleft()), maxGasLoan);
    locals.gasRefund = locals.gasUsed.mul(maxGasPrice);
    locals.gasUsedInRen = convertGasUsedToRen(locals.gasRefund, params.asset);
    //deduct fee on the gas amount
    gasValueAndFee = addFee(locals.gasUsedInRen, params.asset);
    //loan out gas
    console.log(asset);
    IStrategy(strategies[params.asset]).permissionedEther(tx.origin, locals.gasRefund);
    locals.balanceBefore = IERC20(params.asset).balanceOf(address(this));
    console.log(locals.balanceBefore);
    lock.trackIn(gasValueAndFee);
    IZeroMeta(module).repayMeta(gasValueAndFee);
    locals.renBalanceDiff = IERC20(params.asset).balanceOf(address(this)).sub(locals.balanceBefore);
    console.log(IERC20(params.asset).balanceOf(address(this)));
    require(locals.renBalanceDiff >= locals.gasUsedInRen, "not enough provided for gas");
    depositAll(params.asset);
  }

  function toERC20PermitDigest(
    address token,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline
  ) internal view returns (bytes32 result) {
    result = keccak256(
      abi.encodePacked(
        "\x19\x01",
        IERC2612Permit(token).DOMAIN_SEPARATOR(),
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, IERC2612Permit(token).nonces(owner), deadline))
      )
    );
  }

  function computeBurnNonce(
    address asset,
    uint256 amount,
    uint256 deadline,
    uint256 nonce,
    bytes memory destination
  ) public view returns (uint256 result) {
    result = uint256(keccak256(abi.encodePacked(asset, amount, deadline, nonce, destination)));
    while (result < block.timestamp) {
      // negligible probability of this
      result = uint256(keccak256(abi.encodePacked(result)));
    }
  }

  function burn(
    address to,
    address asset,
    uint256 amount,
    uint256 deadline,
    bytes memory destination,
    bytes memory signature
  ) public onlyUnderwriter {
    require(block.timestamp < deadline, "!deadline");
    {
      (uint8 v, bytes32 r, bytes32 s) = SplitSignatureLib.splitSignature(signature);
      uint256 nonce = IERC2612Permit(asset).nonces(to);
      IERC2612Permit(asset).permit(
        to,
        address(this),
        nonce,
        computeBurnNonce(asset, amount, deadline, nonce, destination),
        true,
        v,
        r,
        s
      );
    }
    IERC20(asset).transferFrom(to, address(this), amount);
    uint256 gasUsed = maxGasPrice.mul(maxGasRepay.add(maxGasBurn));
    IStrategy(strategies[asset]).permissionedEther(tx.origin, gasUsed);
    uint256 gasInRen = convertGasUsedToRen(gasUsed, asset);
    uint256 actualAmount = deductFee(amount.sub(gasInRen), asset);
    IGateway gateway = IGatewayRegistry(gatewayRegistry).getGatewayByToken(asset);
    require(IERC20(asset).approve(address(gateway), actualAmount), "!approve");
    gateway.burn(destination, actualAmount);
    depositAll(asset);
  }
}