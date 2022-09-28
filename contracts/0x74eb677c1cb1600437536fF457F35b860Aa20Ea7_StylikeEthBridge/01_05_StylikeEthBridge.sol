// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import './IERC20Child.sol';
import './access/Ownable.sol';

contract StylikeEthBridge is Ownable {
  event BridgeInitialized(uint256 indexed timestamp);
  event TokensBridged(
    address indexed requester,
    bytes32 indexed mainDepositHash,
    uint256 amount,
    uint256 timestamp
  );
  event TokensReturned(
    address indexed requester,
    bytes32 indexed sideDepositHash,
    uint256 amount,
    uint256 timestamp
  );

  IERC20Child private ethToken;
  bool bridgeInitState;
  address gateway;

  constructor(address _gateway) {
    gateway = _gateway;
  }

  function initializeBridge(address ethTokenAddress) external onlyOwner {
    ethToken = IERC20Child(ethTokenAddress);
    bridgeInitState = true;
  }

  function bridgeTokens(
    address _requester,
    uint256 _bridgedAmount,
    bytes32 _mainDepositHash
  ) external verifyInitialization onlyGateway {
    ethToken.mint(_requester, _bridgedAmount);
    emit TokensBridged(
      _requester,
      _mainDepositHash,
      _bridgedAmount,
      block.timestamp
    );
  }

  function returnTokens(
    address _requester,
    uint256 _bridgedAmount,
    bytes32 _sideDepositHash
  ) external verifyInitialization onlyGateway {
    ethToken.burn(_bridgedAmount);
    emit TokensReturned(
      _requester,
      _sideDepositHash,
      _bridgedAmount,
      block.timestamp
    );
  }

  function updateBridgeStatus(bool status) external onlyOwner {
    bridgeInitState = status;
  }

  modifier verifyInitialization() {
    require(bridgeInitState, 'Bridge has not been initialized');
    _;
  }

  modifier onlyGateway() {
    require(msg.sender == gateway, 'Only gateway can execute this function');
    _;
  }
}