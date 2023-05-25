pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol';
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol";
import "./ERC20Swap.sol";

contract LTOToken is ERC20, ERC20Detailed, ERC20Burnable, ERC20Pausable, ERC20Swap {

  uint8 internal constant PENDING_BRIDGE = 1;
  uint8 internal constant PENDING_CONFIRM = 2;

  address public bridgeAddress;
  uint256 public bridgeBalance;
  mapping (address => uint8) public intermediatePending;
  mapping (address => bool) public intermediateAddresses;

  constructor(address _bridgeAddress, uint256 _maxSupply, ERC20Burnable _swap)
      ERC20Detailed("LTO Network Token", "LTO", 8)
      ERC20Swap(_swap) public {
    require(_bridgeAddress != 0);

    bridgeAddress = _bridgeAddress;
    bridgeBalance = _maxSupply;
  }

  modifier onlyBridge() {
    require(msg.sender == bridgeAddress);
    _;
  }

  function addIntermediateAddress(address _intermediate) external onlyBridge {
    require(_intermediate != address(0));

    if (intermediatePending[_intermediate] == PENDING_BRIDGE) {
      _addIntermediate(_intermediate);
    } else {
      intermediatePending[_intermediate] = PENDING_CONFIRM;
    }
  }

  function confirmIntermediateAddress() external {
    require(msg.sender != address(0));

    if (intermediatePending[msg.sender] == PENDING_CONFIRM) {
      _addIntermediate(msg.sender);
    } else {
      intermediatePending[msg.sender] = PENDING_BRIDGE;
    }
  }

  function _addIntermediate(address _intermediate) internal {
    intermediateAddresses[_intermediate] = true;
    delete intermediatePending[_intermediate];

    uint256 balance = balanceOf(_intermediate);
    if (balance > 0) {
      _burn(_intermediate, balance);
    }
  }

  function _transfer(address from, address to, uint256 value) internal {
    require(to != bridgeAddress);
    require(to != address(this));

    if (from == bridgeAddress) {
      require(!intermediateAddresses[to], "Bridge can't transfer to intermediate");

      _mint(from, value);
      super._transfer(from, to, value);
      return;
    }

    if (intermediateAddresses[to]) {
      super._transfer(from, to, value);
      _burn(to, value);
      return;
    }

    super._transfer(from, to, value);
  }

  function _mint(address account, uint256 value) internal {
    bridgeBalance = bridgeBalance.sub(value);
    super._mint(account, value);
  }

  function _burn(address account, uint256 value) internal {
    bridgeBalance = bridgeBalance.add(value);
    super._burn(account, value);
  }
}