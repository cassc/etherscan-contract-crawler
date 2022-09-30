// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDomaniDex} from "./interfaces/IDomaniDex.sol";
import {IController} from "../interfaces/IController.sol";
import {IDomani} from "../interfaces/IDomani.sol";
import {IBasicIssuanceModule} from "../interfaces/IBasicIssuanceModule.sol";
import {IWNative} from "./interfaces/IWNative.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {PreciseUnitMath} from "../lib/PreciseUnitMath.sol";
import {ExplicitERC20} from "../lib/ExplicitERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {DelegateCall} from "./lib/DelegateCall.sol";
import {DomaniDexConstants} from "./lib/DomaniDexConstants.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DomaniDex
 * @author Domani Protocol
 *
 * DomaniDex is a smart contract used to swap generic ERC20 with Domani funds
 * using multiple dex supported
 *
 */
contract DomaniDex is IDomaniDex, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for IDomani;
  using PreciseUnitMath for uint256;
  using SafeCast for int256;
  using Address for address payable;
  using DelegateCall for address;

  string private constant EXACT_INPUT_SIG =
    "swapExactInput(bytes,(uint256,uint256,bytes,bool,uint256,address))";

  string private constant EXACT_OUTPUT_SIG =
    "swapExactOutput(bytes,(uint256,uint256,bytes,bool,uint256,address))";

  IController public immutable override controller;

  IWNative public immutable override wNative;

  IBasicIssuanceModule public override basicIssuanceModule;

  mapping(bytes32 => Implementation) private idToImplementation;

  modifier onlyValidFund(IDomani _fund) {
    require(controller.isSet(address(_fund)), "Must be a valid Domani fund");
    _;
  }

  /**
   * Set initial variables
   * @param _controller Address of controller contract
   * @param _basicIssuanceModule Address issuance module
   * @param _wNative Wrapper of the native token of the blockchain
   * @param _owner Owner of the dex
   */
  constructor(
    IController _controller,
    IBasicIssuanceModule _basicIssuanceModule,
    IWNative _wNative,
    address _owner
  ) {
    controller = _controller;
    _setBasicIssuanceModule(_basicIssuanceModule, _controller);
    wNative = _wNative;
    transferOwnership(_owner);
  }

  receive() external payable {}

  /**
   * Change the issuance module used
   * @param _basicIssuanceModule Address of the new issuance module
   */
  function setBasicIssuanceModule(IBasicIssuanceModule _basicIssuanceModule) external onlyOwner {
    _setBasicIssuanceModule(_basicIssuanceModule, controller);
  }

  /**
   * Register the specific implementation for a dex
   * @param _identifier Name of dex identifier to register
   * @param _dexAddr Address of the dex implementation to register
   * @param _dexInfo Specific info of the dex that will be used in the swaps
   */
  function registerImplementation(
    string calldata _identifier,
    address _dexAddr,
    bytes calldata _dexInfo
  ) external onlyOwner() {
    require(_dexAddr != address(0), "Implementation address can not be the 0x00");
    Implementation storage implementation = idToImplementation[keccak256(abi.encode(_identifier))];
    implementation.dexAddr = _dexAddr;
    implementation.dexInfo = _dexInfo;
    emit ImplementationRegistered(_identifier, _dexAddr, _dexInfo);
  }

  /**
   * Remove a registered implementation
   * @param _identifier Name of dex identifier to remove
   */
  function removeImplementation(string calldata _identifier) external onlyOwner() {
    bytes32 identifierHash = keccak256(abi.encode(_identifier));
    require(
      idToImplementation[identifierHash].dexAddr != address(0),
      "Implementation with this id is not registered"
    );
    delete idToImplementation[identifierHash];
    emit ImplementationRemoved(_identifier);
  }

  /**
   * Swap a generic ERC20 for a quantity of a Domani fund
   * @param _inputDexParams See InputDexParams in IDomaniDex
   * @return inputAmountUsed Amount of the ERC20 used for buying the fund
   */
  function buyDomaniFund(InputDexParams calldata _inputDexParams)
    external
    payable
    override
    nonReentrant
    onlyValidFund(_inputDexParams.fund)
    returns (uint256 inputAmountUsed)
  {
    require(block.timestamp <= _inputDexParams.expiration, "Transaction expired");
    bool isNativeInput = address(_inputDexParams.swapToken) == DomaniDexConstants.NATIVE_ADDR;

    if (!isNativeInput) {
      require(msg.value == 0, "ETH not required for an ERC20 transfer");
      ExplicitERC20.transferFrom(
        _inputDexParams.swapToken,
        msg.sender,
        address(this),
        _inputDexParams.maxOrMinSwapTokenAmount
      );
    }

    uint256 startingAmount = isNativeInput ? msg.value : _inputDexParams.maxOrMinSwapTokenAmount;

    uint256 remainingInputAmount = startingAmount;

    (address[] memory components, uint256[] memory notionalUnits) = getRequiredComponents(
      _inputDexParams.fund,
      _inputDexParams.fundQuantity,
      true
    );
    uint256 componentsNumber = components.length;
    require(componentsNumber == _inputDexParams.swaps.length, "Wrong number of input swaps");

    for (uint256 i = 0; i < componentsNumber; i++) {
      if (address(_inputDexParams.swapToken) == components[i]) {
        remainingInputAmount = remainingInputAmount.sub(notionalUnits[i]);
      } else if (isNativeInput && components[i] == address(wNative)) {
        wNative.deposit{value: notionalUnits[i]}();
        remainingInputAmount = remainingInputAmount.sub(notionalUnits[i]);
      } else {
        Swap memory swap = _inputDexParams.swaps[i];
        Implementation storage implementation = idToImplementation[
          keccak256(abi.encode(swap.identifier))
        ];
        address dexAddress = implementation.dexAddr;
        require(dexAddress != address(0), "Implementation not supported");
        SwapParams memory swapParams = SwapParams(
          notionalUnits[i],
          remainingInputAmount,
          swap.swapData,
          isNativeInput,
          _inputDexParams.expiration,
          address(this)
        );
        bytes memory result = dexAddress.functionDelegateCall(
          abi.encodeWithSignature(EXACT_OUTPUT_SIG, implementation.dexInfo, swapParams)
        );
        ReturnValues memory returnValues = abi.decode(result, (ReturnValues));
        require(
          returnValues.inputToken == address(_inputDexParams.swapToken) &&
            returnValues.outputToken == components[i],
          "Wrong input or output token in the swap"
        );

        remainingInputAmount = remainingInputAmount.sub(returnValues.inputAmount);
      }
      IERC20(components[i]).safeApprove(address(basicIssuanceModule), notionalUnits[i]);
    }

    if (remainingInputAmount > 0) {
      if (isNativeInput) {
        msg.sender.sendValue(remainingInputAmount);
      } else {
        _inputDexParams.swapToken.safeTransfer(msg.sender, remainingInputAmount);
      }
    }

    basicIssuanceModule.issue(
      _inputDexParams.fund,
      _inputDexParams.fundQuantity,
      _inputDexParams.recipient
    );

    inputAmountUsed = startingAmount.sub(remainingInputAmount);

    emit DomaniSwap(
      msg.sender,
      address(_inputDexParams.swapToken),
      inputAmountUsed,
      _inputDexParams.recipient,
      address(_inputDexParams.fund),
      _inputDexParams.fundQuantity
    );
  }

  /**
   * Swap a quantity of a Domani fund for a generic ERC20
   * @param _inputDexParams See InputDexParams in IDomaniDex
   * @return outputAmountReceived Amount of the ERC20 received from the fund selling
   */
  function sellDomaniFund(InputDexParams calldata _inputDexParams)
    external
    override
    nonReentrant
    onlyValidFund(_inputDexParams.fund)
    returns (uint256 outputAmountReceived)
  {
    require(block.timestamp <= _inputDexParams.expiration, "Transaction expired");

    ExplicitERC20.transferFrom(
      _inputDexParams.fund,
      msg.sender,
      address(this),
      _inputDexParams.fundQuantity
    );

    (address[] memory components, uint256[] memory notionalUnits) = getRequiredComponents(
      _inputDexParams.fund,
      _inputDexParams.fundQuantity,
      false
    );
    uint256 componentsNumber = components.length;
    require(componentsNumber == _inputDexParams.swaps.length, "Wrong number of input swaps");

    basicIssuanceModule.redeem(_inputDexParams.fund, _inputDexParams.fundQuantity, address(this));

    bool isNativeOutput = address(_inputDexParams.swapToken) == DomaniDexConstants.NATIVE_ADDR;

    address dexAddress;
    bytes memory result;
    for (uint256 i = 0; i < componentsNumber; i++) {
      if (address(_inputDexParams.swapToken) == components[i]) {
        outputAmountReceived = outputAmountReceived.add(notionalUnits[i]);
        _inputDexParams.swapToken.safeTransfer(_inputDexParams.recipient, notionalUnits[i]);
      } else if (isNativeOutput && components[i] == address(wNative)) {
        wNative.withdraw(notionalUnits[i]);
        outputAmountReceived = outputAmountReceived.add(notionalUnits[i]);
        payable(_inputDexParams.recipient).sendValue(notionalUnits[i]);
      } else {
        Swap memory swap = _inputDexParams.swaps[i];
        Implementation storage implementation = idToImplementation[
          keccak256(abi.encode(swap.identifier))
        ];
        dexAddress = implementation.dexAddr;
        require(dexAddress != address(0), "Implementation not supported");
        SwapParams memory swapParams = SwapParams(
          notionalUnits[i],
          0,
          swap.swapData,
          isNativeOutput,
          _inputDexParams.expiration,
          _inputDexParams.recipient
        );

        result = dexAddress.functionDelegateCall(
          abi.encodeWithSignature(EXACT_INPUT_SIG, implementation.dexInfo, swapParams)
        );

        ReturnValues memory returnValues = abi.decode(result, (ReturnValues));
        require(
          returnValues.inputToken == components[i] &&
            returnValues.outputToken == address(_inputDexParams.swapToken),
          "Wrong input or output token in the swap"
        );
        outputAmountReceived = outputAmountReceived.add(returnValues.outputAmount);
      }
    }

    require(
      outputAmountReceived >= _inputDexParams.maxOrMinSwapTokenAmount,
      "Amount received less than minimum"
    );

    emit DomaniSwap(
      msg.sender,
      address(_inputDexParams.fund),
      _inputDexParams.fundQuantity,
      _inputDexParams.recipient,
      address(_inputDexParams.swapToken),
      outputAmountReceived
    );
  }

  /**
   * Swap a quantity of a Domani fund for a generic ERC20
   * @param _token Address of the token to sweep (for native token use NATIVE_ADDR)
   * @param _recipient Address receiving the amount of token
   * @return Amount of token received
   */
  function sweepToken(IERC20 _token, address payable _recipient)
    external
    override
    nonReentrant
    returns (uint256)
  {
    bool isETH = address(_token) == DomaniDexConstants.NATIVE_ADDR;
    uint256 balance = isETH ? address(this).balance : _token.balanceOf(address(this));
    if (balance > 0) {
      if (isETH) {
        _recipient.sendValue(balance);
      } else {
        _token.safeTransfer(_recipient, balance);
      }
    }
    return balance;
  }

  /**
   * Get address and info of a supported dex
   * @param _identifier Name of dex identifier to get
   * @return See Implementation struct in IDomaniDexGeneral
   */
  function getImplementation(string calldata _identifier)
    external
    view
    override
    returns (Implementation memory)
  {
    return idToImplementation[keccak256(abi.encode(_identifier))];
  }

  /**
   * Get the dummy address to identify native token
   * @return Address used fot native token
   */
  function nativeTokenAddress() external pure override returns (address) {
    return DomaniDexConstants.NATIVE_ADDR;
  }

  /**
   * Get addresses and amounts of the components of a Domani fund
   * @param _fund Address of the fund
   * @param _quantity Qunatity of the fund
   * @param _isIssue True for fund buying, false for fund selling
   * @return Addresses and amounts of the components for the specific quantity of the fund
   */
  function getRequiredComponents(
    IDomani _fund,
    uint256 _quantity,
    bool _isIssue
  ) public view override onlyValidFund(_fund) returns (address[] memory, uint256[] memory) {
    address[] memory components = _fund.getComponents();

    uint256[] memory notionalUnits = new uint256[](components.length);

    uint256 singleUnit;
    for (uint256 i = 0; i < components.length; i++) {
      singleUnit = _fund.getDefaultPositionRealUnit(components[i]).toUint256();
      notionalUnits[i] = _isIssue
        ? singleUnit.preciseMulCeil(_quantity)
        : singleUnit.preciseMul(_quantity);
    }

    return (components, notionalUnits);
  }

  function _setBasicIssuanceModule(
    IBasicIssuanceModule _basicIssuanceModule,
    IController _controller
  ) internal {
    require(_controller.isModule(address(_basicIssuanceModule)), "Module not valid");
    basicIssuanceModule = _basicIssuanceModule;
  }
}