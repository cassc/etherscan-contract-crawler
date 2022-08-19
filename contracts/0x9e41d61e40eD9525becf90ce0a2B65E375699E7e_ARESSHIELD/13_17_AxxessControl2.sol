// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AxxessControl2DATA.sol";

/**
 * @title AxxessControl2
 */
abstract contract AxxessControl2 is AxxessControl2DATA {


  constructor() {

    MasterAddress[0]     = msgSender();
    MasterAddress[1]     = msgSender();
    AdminAddress         = msgSender();
    OperatorAddress[0]   = msgSender();
    OperatorAddress[1]   = msgSender();

  }


  function msgSender() public view virtual returns (address) {
      return msg.sender;
  }

  function msgData() public view virtual returns (bytes calldata) {
      return msg.data;
  }




  /**
   * @dev Modifier to make a function only callable by the Master
   */
  modifier onlyMaster() {
    require(msgSender() == MasterAddress[0] || msgSender() == MasterAddress[1], "AC: c.i.n.  Master");
    _;
  }

  /**
   * @dev Modifier to make a function only callable by the Admin
   */
  modifier onlyAdmin() {
    require(msgSender() == AdminAddress, "AC: c.i.n.  Admin");
    _;
  }

  /**
   * @dev Modifier to make a function only callable by the Operator
   */
  modifier onlyOperator() {
    require(msgSender() == OperatorAddress[0] || msgSender() == OperatorAddress[1], "AC: c.i.n.  Operator");
    _;
  }

  /**
   * @dev Modifier to make a function only callable by C-level execs
   */
  modifier onlyChiefLevel() {
    require(
      msgSender() == OperatorAddress[0] || msgSender() == OperatorAddress[1] ||
      msgSender() == MasterAddress[0] || msgSender() == MasterAddress[1] ||
      msgSender() == AdminAddress
    , "AC: c.i.n.  Master nor Admin nor Operator");
    _;
  }

  /**
   * @dev Modifier to make a function only callable by Master or Operator
   */

  modifier onlyMasterOrOperator() {
    require(
      msgSender() == OperatorAddress[0] || msgSender() == OperatorAddress[1] ||
      msgSender() == MasterAddress[0] || msgSender() == MasterAddress[1]
    , "AC: c.i.n.  Master nor Operator");
    _;
  }

  /**
   * @notice Sets a new Master
   * @param _newMaster - the address of the new Master
   */
  function setMaster(address _newMaster,uint level) external {
    require(_newMaster != address(0), "ad is null");
    require( level <2, "wrong level");
    require( msgSender() == MasterAddress[level], "AC: c.i.n. Master");
    MasterAddress[level] = _newMaster;
  }


  /**
   * @notice Sets a new Admin
   * @param _newAdmin - the address of the new Admin
   */
  function setAdmin(address _newAdmin) external onlyMasterOrOperator {
    require(_newAdmin != address(0), "ad is null");
    AdminAddress = _newAdmin;
  }

  /**
   * @notice Sets a new Operator
   * @param _newOperator - the address of the new Operator
   */
  function setOperator(address _newOperator, uint level) external {
    require(_newOperator != address(0), "ad is null");
    require( level <2, "wrong level");
    require( msgSender() == OperatorAddress[level], "AC: c.i.n. Master");
    OperatorAddress[level] = _newOperator;
  }


  // test access
  function getAccess(address testAddress) public view  returns (bool [4] memory) {
     address caller = testAddress;
     return [
       caller == MasterAddress[0] || caller == MasterAddress[1] || caller == AdminAddress || caller == OperatorAddress[0] || caller == OperatorAddress[1],
       caller == MasterAddress[0] || caller == MasterAddress[1],
       caller == AdminAddress,
       caller == OperatorAddress[0] || caller == OperatorAddress[1]
     ];
   }

  // show access
  function getAccessWallets() public view  returns (address [5] memory) {
    return [
      MasterAddress[0],
      MasterAddress[1],
      AdminAddress,
      OperatorAddress[0],
      OperatorAddress[1]
     ];
   }
}