// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../base/interface/IController.sol";
import "../base/interface/IBookkeeper.sol";
import "../base/interface/ISmartVault.sol";
import "../openzeppelin/Initializable.sol";
import "../base/governance/ControllableV2.sol";

contract HardWorkResolver is ControllableV2 {

  // --- CONSTANTS ---

  string public constant VERSION = "1.0.0";
  uint public constant DELAY_RATE_DENOMINATOR = 100_000;

  // --- VARIABLES ---

  address public owner;
  address public pendingOwner;
  uint public delay;
  uint public maxGas;
  uint public maxHwPerCall;

  mapping(address => uint) public lastHW;
  mapping(address => uint) public delayRate;
  mapping(address => bool) public operators;

  // --- INIT ---

  function init(
    address controller_
  ) external initializer {
    ControllableV2.initializeControllable(controller_);

    owner = msg.sender;
    delay = 1 days;
    maxGas = 35 gwei;
    maxHwPerCall = 3;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "!owner");
    _;
  }

  // --- OWNER FUNCTIONS ---

  function offerOwnership(address value) external onlyOwner {
    pendingOwner = value;
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner, "!pendingOwner");
    owner = pendingOwner;
    pendingOwner = address(0);
  }

  function setDelay(uint value) external onlyOwner {
    delay = value;
  }

  function setMaxGas(uint value) external onlyOwner {
    maxGas = value;
  }

  function setMaxHwPerCall(uint value) external onlyOwner {
    maxHwPerCall = value;
  }

  function setDelayRate(address vault, uint value) external onlyOwner {
    delayRate[vault] = value;
  }

  function changeOperatorStatus(address operator, bool status) external onlyOwner {
    operators[operator] = status;
  }

  // --- MAIN LOGIC ---

  function call(address[] memory vaults) external returns (uint amountOfCalls){
    require(operators[msg.sender], "!operator");

    IController __controller = IController(_controller());
    uint _delay = delay;
    uint _maxHwPerCall = maxHwPerCall;
    uint vaultsLength = vaults.length;
    uint counter;
    for (uint i; i < vaultsLength; ++i) {
      address vault = vaults[i];
      if (
        !ISmartVault(vault).active()
      || lastHW[vault] + _delay > block.timestamp
      ) {
        continue;
      }

      __controller.doHardWork(vault);
      lastHW[vault] = block.timestamp;
      counter++;
      if (counter >= _maxHwPerCall) {
        break;
      }
    }

    return counter;
  }

  function checker() external view returns (bool canExec, bytes memory execPayload) {
    if (tx.gasprice > maxGas) {
      return (false, bytes("Too high gas"));
    }

    IBookkeeper _bookkeeper = IBookkeeper(IController(_controller()).bookkeeper());
    uint _delay = delay;
    uint vaultsLength = _bookkeeper.vaultsLength();
    address[] memory vaults = new address[](vaultsLength);
    uint counter;
    for (uint i; i < vaultsLength; ++i) {
      address vault = _bookkeeper._vaults(i);
      if (ISmartVault(vault).active()) {

        uint delayAdjusted = _delay;
        uint _delayRate = delayRate[vault];
        if (_delayRate != 0) {
          delayAdjusted = _delay * _delayRate / DELAY_RATE_DENOMINATOR;
        }

        if (lastHW[vault] + _delay < block.timestamp) {
          vaults[i] = vault;
          counter++;
        }
      }
    }
    if (counter == 0) {
      return (false, bytes("No ready vaults"));
    } else {
      address[] memory vaultsResult = new address[](counter);
      uint j;
      for (uint i; i < vaultsLength; ++i) {
        if (vaults[i] != address(0)) {
          vaultsResult[j] = vaults[i];
          ++j;
        }
      }
      return (true, abi.encodeWithSelector(HardWorkResolver.call.selector, vaultsResult));
    }
  }

}