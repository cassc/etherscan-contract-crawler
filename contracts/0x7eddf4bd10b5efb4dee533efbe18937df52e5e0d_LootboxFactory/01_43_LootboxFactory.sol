// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {ERC677ReceiverInterface} from '@chainlink/contracts/src/v0.8/interfaces/ERC677ReceiverInterface.sol';
import {IVRFV2Wrapper} from './interfaces/IVRFV2Wrapper.sol';
import {ILootboxFactory} from './interfaces/ILootboxFactory.sol';
import {Lootbox} from './Lootbox.sol';
import {LootboxView} from './LootboxView.sol';

//  $$$$$$\  $$\   $$\  $$$$$$\  $$$$$$\ $$\   $$\  $$$$$$\   $$$$$$\  $$$$$$$$\ $$$$$$$$\ 
// $$  __$$\ $$ |  $$ |$$  __$$\ \_$$  _|$$$\  $$ |$$  __$$\ $$  __$$\ $$  _____|$$  _____|
// $$ /  \__|$$ |  $$ |$$ /  $$ |  $$ |  $$$$\ $$ |$$ /  \__|$$ /  $$ |$$ |      $$ |      
// $$ |      $$$$$$$$ |$$$$$$$$ |  $$ |  $$ $$\$$ |\$$$$$$\  $$$$$$$$ |$$$$$\    $$$$$\    
// $$ |      $$  __$$ |$$  __$$ |  $$ |  $$ \$$$$ | \____$$\ $$  __$$ |$$  __|   $$  __|   
// $$ |  $$\ $$ |  $$ |$$ |  $$ |  $$ |  $$ |\$$$ |$$\   $$ |$$ |  $$ |$$ |      $$ |      
// \$$$$$$  |$$ |  $$ |$$ |  $$ |$$$$$$\ $$ | \$$ |\$$$$$$  |$$ |  $$ |$$ |      $$$$$$$$\ 
//  \______/ \__|  \__|\__|  \__|\______|\__|  \__| \______/ \__|  \__|\__|      \________|                                                                                                                                                                              
                                                                                        
// $$\       $$$$$$\   $$$$$$\ $$$$$$$$\ $$$$$$$\   $$$$$$\  $$\   $$\ $$$$$$$$\  $$$$$$\  
// $$ |     $$  __$$\ $$  __$$\\__$$  __|$$  __$$\ $$  __$$\ $$ |  $$ |$$  _____|$$  __$$\ 
// $$ |     $$ /  $$ |$$ /  $$ |  $$ |   $$ |  $$ |$$ /  $$ |\$$\ $$  |$$ |      $$ /  \__|
// $$ |     $$ |  $$ |$$ |  $$ |  $$ |   $$$$$$$\ |$$ |  $$ | \$$$$  / $$$$$\    \$$$$$$\  
// $$ |     $$ |  $$ |$$ |  $$ |  $$ |   $$  __$$\ $$ |  $$ | $$  $$<  $$  __|    \____$$\ 
// $$ |     $$ |  $$ |$$ |  $$ |  $$ |   $$ |  $$ |$$ |  $$ |$$  /\$$\ $$ |      $$\   $$ |
// $$$$$$$$\ $$$$$$  | $$$$$$  |  $$ |   $$$$$$$  | $$$$$$  |$$ /  $$ |$$$$$$$$\ \$$$$$$  |
// \________|\______/  \______/   \__|   \_______/  \______/ \__|  \__|\________| \______/

/// @title Lootbox Factory
/// @author ChainSafe Systems: Oleksii (Functionality) Sneakz (Natspec assistance)
/// @notice This factory contract holds lootbox functions used in Chainsafe's SDK, Documentation can be found here: https://docs.gaming.chainsafe.io/current/lootboxes
/// @dev Contract that deploys lootbox contracts and manages fees. All function calls are tested and have been implemented in ChainSafe's SDK

contract LootboxFactory is ILootboxFactory, ERC677ReceiverInterface, Ownable {
  using Address for address payable;
  using SafeERC20 for IERC20;
  using Clones for address;

  /*//////////////////////////////////////////////////////////////
                                STATE
  //////////////////////////////////////////////////////////////*/

  address public immutable LINK;
  address public immutable LOOTBOX;

  uint public feePerDeploy = 0;
  mapping(address lootbox => uint feePerUnit) private fees;
  mapping(address deployer => mapping(uint id => address lootbox)) private lootboxes;

  /*//////////////////////////////////////////////////////////////
                                EVENTS
  //////////////////////////////////////////////////////////////*/
  
  event Payment(address lootbox, uint value);
  event PaymentLINK(address lootbox, uint amount);
  event Withdraw(address token, address to, uint amount);
  event Deployed(address lootbox, address owner, uint payment);
  event FeePerDeploySet(uint value);
  event FeePerUnitSet(address lootbox, uint value);

  error InsufficientPayment();
  error AcceptingOnlyLINK();
  error AlreadyDeployed();

  /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor(
    address _link,
    address _lootbox
  ) {
    LINK = _link;
    LOOTBOX = _lootbox;
  }

  /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /// @notice Deploys a lootbox to an address.
  /// @param _uri The uri of the lootbox being deployed.
  /// @param _id The id of the lootbox being deployed.
  /// @return address The lootbox address.
  function deployLootbox(string calldata _uri, uint _id) external payable returns (address) {
    if (msg.value < feePerDeploy) revert InsufficientPayment();
    if (lootboxes[_msgSender()][_id] != address(0)) revert AlreadyDeployed();
    address lootbox = LOOTBOX.cloneDeterministic(keccak256(abi.encodePacked(_msgSender(), _id)));
    Lootbox(lootbox).initialize(_uri, _msgSender());
    lootboxes[_msgSender()][_id] = lootbox;
    emit Deployed(lootbox, _msgSender(), msg.value);
    return lootbox;
  }

  /// @notice The default fee to deploy a lootbox.
  /// @return uint The default fee.
  function defaultFeePerUnit() external view returns (uint) {
    return fees[address(0)];
  }

  /// @notice The fee per unit to deploy a lootbox.
  /// @param _lootbox The lootbox being queried.
  /// @return uint The fee for the lootbox being queried.
  function feePerUnit(address _lootbox) external view override returns (uint) {
    uint fee = fees[_lootbox];
    if (fee > 0) {
      return fee;
    }
    return fees[address(0)];
  }

  /// @notice Sets the fee to deploy each lootbox.
  /// @param _feePerDeploy The fee per deployment.
  function setFeePerDeploy(uint _feePerDeploy) external onlyOwner() {
    feePerDeploy = _feePerDeploy;
    emit FeePerDeploySet(_feePerDeploy);
  }

  /// @notice Sets the fee per unit to deploy specific lootboxes.
  /// @param _lootbox The address of the lootbox to change the fee of.
  /// @param _value The value of each fee unit.
  function setFeePerUnit(address _lootbox, uint _value) external onlyOwner() {
    fees[_lootbox] = _value;
    emit FeePerUnitSet(_lootbox, _value);
  }

  /// @notice Withdraws tokens stored in the contract.
  /// @param _token The address of the tokens being withdrawn.
  /// @param _to The address to send tokens to.
  /// @param _amount The amount of tokens to send.
  function withdraw(address _token, address payable _to, uint _amount) external onlyOwner() {
    emit Withdraw(_token, _to, _amount);
    if (_token == address(0)) {
      _to.sendValue(_amount);
      return;
    }
    IERC20(_token).safeTransfer(_to, _amount);
  }

  /// @notice Payable receive function that emits an event.
  receive() external payable override {
    emit Payment(msg.sender, msg.value);
  }

  /// @notice Checks if the sender is the LINK address, reverts if false.
  /// @param _lootbox The lootbox address.
  /// @param _amount The amount being sent.
  function onTokenTransfer(address _lootbox, uint _amount, bytes calldata) external override {
    if (msg.sender != LINK) revert AcceptingOnlyLINK();
    emit PaymentLINK(_lootbox, _amount);
  }

  /// @notice Queries lootbox deployer and id.
  /// @param _deployer The deploying address of the lootbox.
  /// @param _id The id of the lootbox being queried.
  /// @return address The lootbox by deployer and id.
  function getLootbox(address _deployer, uint _id) external view returns (address) {
    return lootboxes[_deployer][_id];
  }
}