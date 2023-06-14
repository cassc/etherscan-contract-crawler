pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";


contract RaffleAccessControl is AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  string public minterOf;

  // Events
  event MinterAdded(address indexed account, string minterOf);
  event MinterRemoved(address indexed account, string minterOf);

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin role");
    _;
  }
  
  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, msg.sender), "Only minter role");
    _;
  }

  /**
   * @dev Constructor Add the given account both as the main Admin of the smart contract and a checkpoint minter
   * @param mainMinter The account that will be added as mainMinter
   */
  constructor (address mainMinter, string memory _minterOf) {
    require(
      mainMinter != address(0),
      "Main minter should be a valid address"
    );

    minterOf = _minterOf;
    _setupRole(DEFAULT_ADMIN_ROLE, mainMinter);
    _setupRole(MINTER_ROLE, mainMinter);

    emit MinterAdded(mainMinter, minterOf);
  }

  /**
   * @dev checks if the given account is a minter
   * @param account The account that will be checked
   */
  function isMinter(address account) public view returns (bool) {
    return hasRole(MINTER_ROLE, account);
  }
  
  /**
   * @dev Adds a new account to the minter role
   * @param account The account that will have the minter role
   */
  function addMinter(address account) public onlyMinter virtual {
    grantRole(MINTER_ROLE, account);
    
    emit MinterAdded(account, minterOf);
  }

  /**
   * @dev Removes the sender from the list the minter role
   */
  function renounceMinter() public {
    renounceRole(MINTER_ROLE, msg.sender);

    emit MinterRemoved(msg.sender, minterOf);
  }

  /**
   * @dev Removes the given account from the minter role, if msg.sender is admin
   * @param minter The account that will have the minter role removed
   */
  function removeMinter(address minter) public {
    revokeRole(MINTER_ROLE, minter);

    emit MinterRemoved(minter, minterOf);
  }
}