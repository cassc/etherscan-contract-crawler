//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import './ProxyApprovable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IFeeManager {
  function calculateFee(address, uint256) external view returns (uint256);
  function protocolFee() external view returns (uint256);
  function protocolFeeRecipient() external view returns(address payable);
  function MAX_PROTOCOL_FEE() external view returns (uint256);
}

contract FeeManager is Ownable, IFeeManager {
  address payable public protocolFeeRecipient;
  uint256 public MAX_PROTOCOL_FEE = 9500;
  uint256 public protocolFee = 0;

  constructor() {
    setProtocolFeeRecipient(payable(msg.sender));
    setProtocolFee(0);
  }

  function setProtocolFeeRecipient(address payable _protocolFeeRecipient) public onlyOwner {
    protocolFeeRecipient = _protocolFeeRecipient;
  }

  function setProtocolFee(uint256 _protocolFee) public onlyOwner {
    require(
      _protocolFee >= 0 && _protocolFee <= MAX_PROTOCOL_FEE, 
      "INVALID PROTOCOL FEE: VALID RANGE [0, 9500]"
    );
    protocolFee = _protocolFee;
  }

  function calculateFee(address sender, uint256 amount) public view returns (uint256 feeAmount) {
    feeAmount = (amount * protocolFee) / 10000;
  }
}