// SPDX-License-Identifier: MIT
// FIO Protocol ERC20 and Oracle Contract
// Adam Androulidakis 2/2021
// Prototype: Do not use in production

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract WFIO is ERC20Burnable, ERC20Pausable, AccessControl {

    uint256 constant MINTABLE = 1e18;

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");

    enum ApprovalType {
        Wrap,
        AddOracle,
        RemoveOracle,
        AddCustodian,
        RemoveCustodian
    }

    struct pending {
      mapping (address => bool) approved;
      uint32 approvals;
      address account;
      uint256 amount;
      bool complete;
    }

    uint32 custodian_count;
    uint32 oracle_count;

    event unwrapped(string fioaddress, uint256 amount);
    event wrapped(address account, uint256 amount, string obtid);
    event custodian_unregistered(address account, bytes32 indexhash);
    event custodian_registered(address account, bytes32 indexhash);
    event oracle_unregistered(address account, bytes32 indexhash);
    event oracle_registered(address account, bytes32 indexhash);
    event consensus_activity(string signer, address account, string obtid, bytes32 indexhash);

    address[] oraclelist;
    address[] custodianlist;

    mapping ( bytes32 => pending) approvals; // bytes32 hash can be any obtid

    constructor(uint256 _initialSupply, address[] memory newcustodians ) ERC20("FIO Protocol", "wFIO") {
      require(newcustodians.length == 10, "wFIO cannot deploy without 10 custodians");
      _mint(msg.sender, _initialSupply);
      _grantRole(OWNER_ROLE, msg.sender);

      for (uint8 i = 0; i < 10; i++ ) {
        require(!hasRole(CUSTODIAN_ROLE, newcustodians[i]), "Custodian already registered");
        require(!hasRole(OWNER_ROLE, newcustodians[i]), "Owner role cannot be custodian");
        _grantRole(CUSTODIAN_ROLE, newcustodians[i]);
        custodianlist.push(newcustodians[i]);
      }
      custodian_count = 10;
      oracle_count = 0;
    }

    function pause() external onlyRole(CUSTODIAN_ROLE) whenNotPaused{
        _pause();
    }

    function unpause() external onlyRole(CUSTODIAN_ROLE)whenPaused{
        _unpause();
    }

    //Precondition: Roles must be checked in parent functions. This should only be called by authorized oracle or custodian
    function getConsensus(bytes32 hash, uint8 Type, address account, uint256 amount) internal returns (bool){
      require(!approvals[hash].complete, "Approval already complete");

      uint32 APPROVALS_NEEDED = oracle_count;
      if (Type == 1) {
        APPROVALS_NEEDED = custodian_count * 2 / 3 + 1;
      }
      if (approvals[hash].approvals == 0) {
        approvals[hash].amount = amount;
        approvals[hash].account = account;
      }
      if (approvals[hash].approvals < APPROVALS_NEEDED) {
        require(!approvals[hash].approved[msg.sender], "oracle has already approved this hash");
        approvals[hash].approved[msg.sender] = true;
        approvals[hash].approvals++;
         //moving this if block after the parent if block will allow the execution to take place immediately instead of requiring a subsequent call
        if (approvals[hash].approvals >= APPROVALS_NEEDED) {
          require(approvals[hash].approved[msg.sender], "An approving oracle must execute");
          approvals[hash].complete = true;
          return approvals[hash].complete;
        }
      }
      return approvals[hash].complete;
    }


    function wrap(address account, uint256 amount, string memory obtid) external onlyRole(ORACLE_ROLE) whenNotPaused{
      require(amount < MINTABLE);
      require(bytes(obtid).length > 0, "Invalid obtid");
      require(account != address(0), "Invalid account");
      require(oracle_count >= 3, "Oracles must be 3 or greater");
      bytes32 indexhash = keccak256(bytes(abi.encode(ApprovalType.Wrap, obtid, amount, account)));

      if (getConsensus(indexhash, 0, account, amount)) {
         _mint(account, amount);
         emit wrapped(account, amount, obtid);
      }

      emit consensus_activity("oracle", msg.sender, obtid, indexhash);

    }

    function unwrap(string memory fioaddress, uint256 amount) external whenNotPaused{
      require(bytes(fioaddress).length > 3 && bytes(fioaddress).length <= 64, "Invalid FIO Address");
      _burn(msg.sender, amount);
      emit unwrapped(fioaddress, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Pausable) {
        require(to != address(this), "Contract cannot receive tokens");
        super._beforeTokenTransfer(from, to, amount);
    }


    function getCustodian(address account) external view returns (bool, uint32) {
      require(account != address(0), "Invalid address");
      return (hasRole(CUSTODIAN_ROLE, account), custodian_count);
    }

    function getOracle(address account) external view returns (bool, uint32) {
      require(account != address(0), "Invalid address");
      return (hasRole(ORACLE_ROLE, account), uint32(oraclelist.length));
    }

    function getOracles() external view returns(address[] memory) {
      return oraclelist;
    }


    function getApproval(bytes memory indexhash) external view returns (uint32, address, uint256, address[] memory) {
      require(indexhash.length > 0, "Invalid obtid");
      address[] memory approvedOracles = new address[](approvals[bytes32(indexhash)].approvals);
      uint32 c = 0;
      for(uint32 i = 0; i < oraclelist.length; i++) {
        if (approvals[bytes32(indexhash)].approved[oraclelist[i]]) {
          approvedOracles[c] = oraclelist[i];
          c++;
        }
      }
      return (approvals[bytes32(indexhash)].approvals, approvals[bytes32(indexhash)].account, approvals[bytes32(indexhash)].amount, approvedOracles);
    }

    function regoracle(address account) external onlyRole(CUSTODIAN_ROLE)  {
      require(account != address(0), "Invalid address");
      require(account != msg.sender, "Cannot register self");
      require(!hasRole(ORACLE_ROLE, account), "Oracle already registered");
      bytes32 indexhash = keccak256(bytes(abi.encode(ApprovalType.AddOracle,account )));
      if (getConsensus(indexhash, 1, account, 0)){
        _grantRole(ORACLE_ROLE, account);
        oracle_count++;
        oraclelist.push(account);
        emit oracle_registered(account, indexhash);
      }
      emit consensus_activity("custodian", msg.sender, "", indexhash);
    }

    function unregoracle(address account) external onlyRole(CUSTODIAN_ROLE) {
      require(account != address(0), "Invalid address");
      require(oracle_count > 3, "Minimum 3 oracles required");
      bytes32 indexhash = keccak256(bytes(abi.encode(ApprovalType.RemoveOracle,account)));
      require(hasRole(ORACLE_ROLE, account), "Oracle not registered");
      if ( getConsensus(indexhash, 1, account, 0)) {
          _revokeRole(ORACLE_ROLE, account);
          oracle_count--;
          for(uint16 i = 0; i < oraclelist.length; i++) {
            if(oraclelist[i] == account) {
              oraclelist[i] = oraclelist[oraclelist.length - 1];
              oraclelist.pop();
              break;
            }
          }
          emit oracle_unregistered(account, indexhash);
      }
      emit consensus_activity("custodian", msg.sender, "", indexhash);

    } // unregoracle

    function regcust(address account) external onlyRole(CUSTODIAN_ROLE) {
      require(account != address(0), "Invalid address");
      require(account != msg.sender, "Cannot register self");
      bytes32 indexhash = keccak256(bytes(abi.encode(ApprovalType.AddCustodian,account)));
      require(!hasRole(CUSTODIAN_ROLE, account), "Already registered");
      if (getConsensus(indexhash, 1, account, 0)) {
        _grantRole(CUSTODIAN_ROLE, account);
        custodian_count++;
        custodianlist.push(account);
        emit custodian_registered(account, indexhash);
      }
      emit consensus_activity("custodian", msg.sender, "", indexhash);
    }

    function unregcust(address account) external onlyRole(CUSTODIAN_ROLE) {
      require(account != address(0), "Invalid address");
      require(hasRole(CUSTODIAN_ROLE, account), "Custodian not registered");
      require(custodian_count > 7, "Must contain 7 custodians");
      bytes32 indexhash = keccak256(bytes(abi.encode(ApprovalType.RemoveCustodian,account)));
      require(hasRole(CUSTODIAN_ROLE, account), "Already unregistered");
      if (getConsensus(indexhash, 1, account, 0)) {
          _revokeRole(CUSTODIAN_ROLE, account);
          custodian_count--;
          for(uint16 i = 0; i < custodianlist.length; i++) {
            if(custodianlist[i] == account) {
              custodianlist[i] = custodianlist[custodianlist.length - 1];
              custodianlist.pop();
              break;
            }
          }
          emit custodian_unregistered(account, indexhash);
      }
      emit consensus_activity("custodian", msg.sender, "", indexhash);
    } //unregcustodian

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    receive () external payable {
        revert();
    }

    function changeOwner(address account) external onlyRole(OWNER_ROLE) {
      _revokeRole(OWNER_ROLE, msg.sender);
      _grantRole(OWNER_ROLE, account);
    }

    function decimals() public view virtual override returns (uint8) {
      return 9;
    }
}