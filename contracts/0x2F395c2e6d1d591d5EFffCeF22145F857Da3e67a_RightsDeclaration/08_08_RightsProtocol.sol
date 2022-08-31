// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RightsProtocol is Ownable {

  /**
   * @dev Emitted when rights are declared for the token `tokenID` of contract `contractAddr`
   */
  event RightsDeclared(address indexed contractAddr, uint256 indexed tokenID, uint256 rightsID, string indexed rightsURI, address declarer);

  /** 
   * @dev Emitted when Rights Authority for tokens in the contract `contractAddr` is transferred from the old Rights Authority (`oldAuthority`) 
   * to a new Rights Authority (`newAuthority`)
   */
  event ContractAuthorityTransferred(address indexed oldAuthority, address indexed newAuthority, address indexed contractAddr);

  /**
   * @dev Emitted when declarations for the contract `contractAddr` are frozen
   */
  event ContractDeclarationsFrozen(address indexed contractAddr, address indexed declarer);
   
  /** 
   * @dev Emitted when Rights Authority (`rightsAuthority`) approves an Operator (`operator`) to declare rights for tokens of the contract 
   * `contractAddr` 
   */
  event ContractOperatorApproved(address indexed rightsAuthority, address indexed operator, address indexed contractAddr);

  /** 
   * @dev Emitted when Rights Authority (`rightsAuthority`) revokes the Operator (`operator`) to declare rights for tokens of the contract 
   * `contractAddr` 
   */
  event ContractOperatorRevoked(address indexed rightsAuthority, address indexed operator, address indexed contractAddr);

  /** 
   * @dev Emitted when Rights Authority for the token `tokenID` of contract `contractAddr` is transferred from the old Rights Authority 
   * (`oldAuthority`) to a new Rights Authority (`newAuthority`) 
   */
  event TokenAuthorityTransferred(address oldAuthority, address indexed newAuthority, address indexed contractAddr, uint256 indexed tokenID);

  /**
   * @dev Emitted when declarations for the token `tokenID` of contract `contractAddr` are frozen
   */
  event TokenDeclarationsFrozen(address indexed contractAddr, uint256 indexed tokenID, address indexed declarer);

  /**
   * @dev Emitted when Rights Authority (`rightsAuthority`) approves an Operator (`operator`) to declare rights for the token `tokenID` of 
   * contract `contractAddr`
   */
  event TokenOperatorApproved(address rightsAuthority, address indexed operator, address indexed contractAddr, uint256 indexed tokenID);

  /**
   * @dev Emitted when Rights Authority (`rightsAuthority`) revokes the Operator (`operator`) to declare rights for the token `tokenID` of 
   * contract `contractAddr`
   */
  event TokenOperatorRevoked(address rightsAuthority, address indexed operator, address indexed contractAddr, uint256 indexed tokenID);

  // Rights Status information
  struct RightsStatus { 
    address authority;
    address operator;
    uint256 authorityDate;
    uint256 frozenDate;
  }

  using Counters for Counters.Counter;
  Counters.Counter private _id;

  bool private _useAllowlist;

  // List of addresses that can make declarations using this contract
  mapping(address => bool) _allowlist;

  // Maps Rights ID to Rights URI
  mapping(uint256 => string) private _rights;

  // Maps NFT (Smart Contract address / Token ID) to the list of Rights IDs
  mapping(address => mapping(uint256 => uint256[])) private _ids;

  // Maps NFT Smart Contract address to Rights Status information (contract-level)
  mapping(address => RightsStatus) private _contractStatus;

  // Maps NFT (Smart Contract address / Token ID) to Rights Status information (token-level)
  mapping(address => mapping(uint256 => RightsStatus)) private _tokenStatus;

  constructor() {
    _useAllowlist = true; 
  }

  /*
   * Disable allowlist 
   */
  function disableAllowlist() public onlyOwner {
    _useAllowlist = false;
  }

  /*
   * Returns a boolean indicating if allowlist is enabled
   */
  function useAllowlist() public view returns (bool) {
    return _useAllowlist;
  }

  /*
   * Throws error if caller is not in the allowed list
   */
  modifier onlyAllowed() {
    if (_useAllowlist) {
      require(_allowlist[msg.sender] == true || _allowlist[tx.origin] == true, "RightsProtocol: caller is not allowed");
    }
    _;
  }
  
  /*
   * Add address to the allowed list
   */
  function addAllowed(address addr) public onlyOwner {
    _allowlist[addr] = true;
  }

  /*
   * Remove address from the allowed list
   */
  function removeAllowed(address addr) public onlyOwner {
    _allowlist[addr] = false;
  }

  /*
   * Declare Rights for a NFT
   */
  function declare(address contractAddr, uint256 tokenID, string calldata rightsURI_, bool freeze) public onlyAllowed returns (uint256) {
    require(contractAddr != address(0), "RightsProtocol: NFT Smart Contract address can not be empty");
    require(tokenID > 0, "RightsProtocol: Token ID can not be empty");
    require(bytes(rightsURI_).length > 0, "RightsProtocol: Rights URI can not be empty");

    // Check if declarations are frozen for the token
    require(isTokenFrozen(contractAddr, tokenID) == false, "RightsProtocol: Rights declarations frozen for the contract or for the token");

    // Check if the user is approved to attach declarations
    require(_canManageToken(contractAddr, tokenID), "RightsProtocol: Caller is not Rights Authority or approved Operator for the token");

    // Increment Rights ID
    _id.increment();
    uint256 rightsID = _id.current();

    // Store Rights data
    _rights[rightsID] = rightsURI_;
    _ids[contractAddr][tokenID].push(rightsID);

    // Handle freezing
    if (freeze) {
      _tokenStatus[contractAddr][tokenID].frozenDate = block.timestamp;
      emit TokenDeclarationsFrozen(contractAddr, tokenID, tx.origin);
    }

    // Emit event
    emit RightsDeclared(contractAddr, tokenID, rightsID, rightsURI_, tx.origin); 

    return rightsID;
  }

  /*
   * Returns a list of Rights IDs associated with the token
   */
  function ids(address contractAddr, uint256 tokenID) public view returns (uint256[] memory) {
    return _ids[contractAddr][tokenID];
  }

  /*
   * Returns the Rights URI associated with the Rights ID
   */
  function rightsURI(uint256 rightsID) public view returns (string memory) {
    require(rightsID <= _id.current(), "RightsProtocol: Query for nonexistent Rights ID");
    return _rights[rightsID];
  }

  /*
   * Returns a list of Rights URI associated with the token
   */
  function rightsURIs(address contractAddr, uint256 tokenID) public view returns (string[] memory) {
    uint256[] memory rightsIDs = ids(contractAddr, tokenID);
    string[] memory uris = new string[](rightsIDs.length);
    for (uint i = 0; i < rightsIDs.length; i++) {
      string memory rightsURI_ = rightsURI(rightsIDs[i]);
      uris[i]= rightsURI_;
    }
    return uris;
  }

  /*
   * Freeze declarations for a contract
   */
  function freezeContract(address contractAddr) public onlyAllowed {
    require(isContractFrozen(contractAddr) == false, "RightsProtocol: Rights declarations are already frozen for the contract");
    require(_canManageContract(contractAddr) == true, "RightsProtocol: Caller is not Rights Authority or approved Operator for the contract");

    RightsStatus storage contractStatus = _contractStatus[contractAddr];
    contractStatus.frozenDate = block.timestamp;

    emit ContractDeclarationsFrozen(contractAddr, tx.origin);
  }

  /*
   * Freeze declarations for a token
   */
  function freezeToken(address contractAddr, uint256 tokenID) public onlyAllowed {
    require(isTokenFrozen(contractAddr, tokenID) == false, "RightsProtocol: Rights declarations are already frozen for the token");
    require(_canManageToken(contractAddr, tokenID) == true, "RightsProtocol: Caller is not Rights Authority or approved Operator for the token");

    RightsStatus storage tokenStatus = _tokenStatus[contractAddr][tokenID];
    tokenStatus.frozenDate = block.timestamp;

    emit TokenDeclarationsFrozen(contractAddr, tokenID, tx.origin);
  }

  /* 
   * Check if contract declarations are frozen
   */
  function isContractFrozen(address contractAddr) public view returns (bool) {
    return _contractStatus[contractAddr].frozenDate > 0;
  }

  /*
   * Check if token declarations are frozen:
   * 1. The token declarations were frozen
   * 2. The contract declarations were frozen and the token-level authority was NOT set before
   */
  function isTokenFrozen(address contractAddr, uint256 tokenID) public view returns (bool) {
    RightsStatus storage tokenStatus = _tokenStatus[contractAddr][tokenID];
    if (tokenStatus.frozenDate > 0) {
      return true;
    }

    // Check if token-level authority was set before the freezing
    RightsStatus storage contractStatus = _contractStatus[contractAddr];
    if (contractStatus.frozenDate > 0) {
      if (tokenStatus.authorityDate > 0 && tokenStatus.authorityDate < contractStatus.frozenDate) {
        return false;
      } else {
        return true;
      }
    } 

    return false;
  }

  /*
   * Approve contract-level operator
   * This function should be called directly by the contract-level authority
   */
  function approveContractOperator(address contractAddr, address operator) public onlyAllowed {
    require(isContractFrozen(contractAddr) == false, "RightsProtocol: Operator can not be approved if declarations are frozen for the contract");
    require(_isContractAuthority(contractAddr, false) == true, "RightsProtocol: Caller is not contract-level Rights Authority");
        
    _contractStatus[contractAddr].operator = operator;
    emit ContractOperatorApproved(msg.sender, operator, contractAddr);
  }

  /*
   * Revoke contract-level operator
   * This function should be called directly by the contract-level authority
   */
  function revokeContractOperator(address contractAddr) public onlyAllowed {
    require(isContractFrozen(contractAddr) == false, "RightsProtocol: Operator can not be revoked if declarations are frozen for the contract");
    require(_isContractAuthority(contractAddr, false) == true, "RightsProtocol: Caller is not contract-level Rights Authority");

    address operator = _contractStatus[contractAddr].operator;
    _contractStatus[contractAddr].operator = address(0);
    emit ContractOperatorRevoked(msg.sender, operator, contractAddr);
  }

  /*
   * Approve token-level operator
   * This function should be called directly by the token-level authority
   */
  function approveTokenOperator(address contractAddr, uint256 tokenID, address operator) public onlyAllowed {
    require(isTokenFrozen(contractAddr, tokenID) == false, "RightsProtocol: Operator can not be approved if declarations are frozen for the token");
    require(_isTokenAuthority(contractAddr, tokenID, false) == true , "RightsProtocol: Caller is not (token-level and contract-level) Rights Authority");

    _tokenStatus[contractAddr][tokenID].operator = operator; 
    emit TokenOperatorApproved(msg.sender, operator, contractAddr, tokenID);
  }

  /*
   * Revoke token-level operator
   * This function should be called directly by the token-level authority
   */
  function revokeTokenOperator(address contractAddr, uint256 tokenID) public onlyAllowed {
    require(isTokenFrozen(contractAddr, tokenID) == false, "RightsProtocol: Operator can not be revoked if declarations are frozen for the token");
    require(_isTokenAuthority(contractAddr, tokenID, false) == true , "RightsProtocol: Caller is not (token-level and contract-level) Rights Authority");

    address operator = _tokenStatus[contractAddr][tokenID].operator;
    _tokenStatus[contractAddr][tokenID].operator = address(0); 
    emit TokenOperatorRevoked(msg.sender, operator, contractAddr, tokenID);
  }

  /*
   * Transfer contract-level Rights Authority
   */
  function transferContractAuthority(address contractAddr, address newAuthority) public onlyAllowed {
    require(isContractFrozen(contractAddr) == false, "RightsProtocol: Rights Authority can not be transferred if contract declarations are frozen");
    require(_isContractAuthority(contractAddr, false) == true, "RightsProtocol: Caller is not contract-level Rights Authority");

    RightsStatus storage contractStatus = _contractStatus[contractAddr];
    contractStatus.authority = newAuthority;
    contractStatus.authorityDate = block.timestamp;

    emit ContractAuthorityTransferred(msg.sender, newAuthority, contractAddr);
  }

  /*
   * Transfer token-level Rights Authority
   */
  function transferTokenAuthority(address contractAddr, uint256 tokenID, address newAuthority) public onlyAllowed {
    require(isTokenFrozen(contractAddr, tokenID) == false, "RightsProtocol: Rights Authority can not be transferred if token declarations are frozen");
    require(_isTokenAuthority(contractAddr, tokenID, false) == true, "RightsProtocol: Caller is not (token-level and contract-level) Rights Authority");
    
    RightsStatus storage tokenStatus = _tokenStatus[contractAddr][tokenID];
    tokenStatus.authority = newAuthority;
    tokenStatus.authorityDate = block.timestamp;

    emit TokenAuthorityTransferred(msg.sender, newAuthority, contractAddr, tokenID);
  }

  /*
   * Check if user of caller is approved to make contract declarations
   */
  function _canManageContract(address contractAddr) internal view returns (bool) {
    return _isContractAuthority(contractAddr, true) || _isContractOperator(contractAddr);
  }

  /*
   * Check if user or caller is approved to make token declarations
   */
  function _canManageToken(address contractAddr, uint256 tokenID) internal view returns (bool) {
    return _isTokenAuthority(contractAddr, tokenID, true) || _isTokenOperator(contractAddr, tokenID);
  }
  
  /*
   * Check if user or caller is a contract-level Rights Authority
   */
  function _isContractAuthority(address contractAddr, bool origin) internal view returns (bool) {
    // Use transaction origin or direct caller?
    address caller;
    if (origin) {
      caller = tx.origin;
    } else {
      caller = msg.sender;
    }

    // The contract authority was explicitly set, check if it's the caller
    address contractAuthority = _contractStatus[contractAddr].authority;
    if (contractAuthority != address(0)) {
      return contractAuthority == caller;
    }

    // The contract itself is the direct caller
    if (msg.sender == contractAddr) {
      return true;
    }

    // The owner of the contract is the caller
    address contractOwner = Ownable(contractAddr).owner();
    return contractOwner == caller;
  }

  /*
   * Check if transaction origin or message sender is a token-level Rights Authority
   */
  function _isTokenAuthority(address contractAddr, uint256 tokenID, bool origin) internal view returns (bool) {
    address caller;
    if (origin) {
      caller = tx.origin;
    } else {
      caller = msg.sender;
    }
    
    // The token authority was explicitly set, check if it's the caller
    address tokenAuthority = _tokenStatus[contractAddr][tokenID].authority;
    if (tokenAuthority != address(0)) {
      return tokenAuthority == caller;
    }

    // The contract authority was explicitly set, check if it's the caller
    address contractAuthority = _contractStatus[contractAddr].authority;
    if (contractAuthority != address(0)) {
      return contractAuthority == caller;
    }

    // The contract itself is the direct caller
    if (msg.sender == contractAddr) {
      return true;
    }

    // The owner of the contract is the caller
    address contractOwner = Ownable(contractAddr).owner();
    return contractOwner == caller;
  }

  /*
   * Check if caller (transaction origin) is contract Operator
   */
  function _isContractOperator(address contractAddr) internal view returns (bool) {
    address contractOperator = _contractStatus[contractAddr].operator;
    return contractOperator == tx.origin;
  } 

  /*
   * Check if caller (transaction origin) is token Operator
   */
  function _isTokenOperator(address contractAddr, uint256 tokenID) internal view returns (bool) {
    address tokenOperator = _tokenStatus[contractAddr][tokenID].operator;
    if (tokenOperator != address(0)) {
      return tokenOperator == tx.origin;
    }

    address contractOperator = _contractStatus[contractAddr].operator;
    if (contractOperator != address(0)) {
      return contractOperator == tx.origin;
    }

    return false;
  }
}