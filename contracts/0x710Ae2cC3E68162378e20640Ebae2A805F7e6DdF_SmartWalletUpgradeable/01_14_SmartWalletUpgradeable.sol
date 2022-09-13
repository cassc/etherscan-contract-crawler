// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract SmartWalletUpgradeable is
  AccessControlEnumerableUpgradeable,
  OwnableUpgradeable
{
  using ECDSAUpgradeable for bytes32;

  bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
  bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");

  bytes4 public constant INTERFACE_ID_IERC20 = type(IERC20Upgradeable).interfaceId;

  event Transfer(bytes4 interfaceId, address indexed tokenAddress, address indexed from, address indexed to, uint256 amount);
  event ApproveTransaction(address indexed approver, bytes4 interfaceId, address indexed tokenAddress, address indexed to, uint256 amount, string nonce, uint256 expiration, string method);

  mapping(string => bool) internal usedNonces;
  
  mapping(address => uint256) internal maxAmountPerWithdraw;
  
  // Number of approvals required to execute a transaction
  uint256 internal threshold;
  // Threshold amount per token address that requires multisig
  mapping(address => uint256) internal thresholdAmounts;  
  // Mapping of all hashes that have been approved by an approver
  mapping(address => mapping(bytes32 => bool)) internal approvedHashes;
  // Mapping number of approvals for a hash
  mapping(bytes32 => uint256) internal approvedCounts;

  /***
   * Public functions
   */
  function initialize() initializer public {
    __AccessControlEnumerable_init();
    __Ownable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MODERATOR_ROLE, msg.sender);
    _setupRole(APPROVER_ROLE, msg.sender);
  }

  function getMaxAmountPerWithdraw(address tokenAddress) public view virtual returns (uint256) {
    return maxAmountPerWithdraw[tokenAddress];
  }
  
  function setMaxAmountPerWithdraw(address tokenAddress, uint256 maxAmount) public virtual onlyOwner {
    maxAmountPerWithdraw[tokenAddress] = maxAmount;
  }
  
  function getThreshold() public view virtual returns (uint256) {
    return threshold;
  }
  
  function setThreshold(uint256 number) public virtual onlyOwner {
    threshold = number;
  }
  
  function getThresholdAmount(address tokenAddress) public view virtual returns (uint256) {
    return thresholdAmounts[tokenAddress];
  }
  
  function setThresholdAmount(address tokenAddress, uint256 amount) public virtual onlyOwner {
    thresholdAmounts[tokenAddress] = amount;
  }
  
  function getApprovedCount(bytes32 hash) public view virtual returns (uint256) {
    return approvedCounts[hash];
  }
  
  function invalidateNonce(string memory nonce) public virtual {
    require(hasRole(MODERATOR_ROLE, msg.sender), "SmartWalletUpgradeable: must be moderator");

    if (!usedNonces[nonce])  usedNonces[nonce] = true;
  }
  
  function deposit(bytes4 interfaceId, address tokenAddress, uint256 amount) public virtual {
    address from = msg.sender;
    address to = address(this);
    _transfer(interfaceId, tokenAddress, from, to, amount);
  }
  
  function withdraw(bytes4 interfaceId, address tokenAddress, uint256 amount, string memory nonce, uint256 expiration, bytes memory signature) public virtual {
    address from = address(this);
    address to = msg.sender;
    string memory method = "withdraw";
    
    uint256 thresholdAmount = thresholdAmounts[tokenAddress];
    if (threshold > 0 && thresholdAmount > 0 && amount >= thresholdAmount) {
      bytes32 hash = hashToSign(interfaceId, tokenAddress, to, amount, nonce, expiration, method);
      uint256 approvedCount = approvedCounts[hash];
      require(approvedCount >= threshold, "SmartWalletUpgradeable: not enough approvers");
    }
    
    require(verifySignature(interfaceId, tokenAddress, to, amount, nonce, expiration, method, signature), "SmartWalletUpgradeable: unauthorized");
    
    _transfer(interfaceId, tokenAddress, from, to, amount);
  }
  
  function withdrawByModerator(bytes4 interfaceId, address tokenAddress, address to, uint256 amount) public virtual {
    require(hasRole(MODERATOR_ROLE, msg.sender), "SmartWalletUpgradeable: must be moderator");
    
    uint256 thresholdAmount = thresholdAmounts[tokenAddress];
    require(thresholdAmount == 0 || amount < thresholdAmount, "SmartWalletUpgradeable: high amount requires multisig");
    
    address from = address(this);
    _transfer(interfaceId, tokenAddress, from, to, amount);
  }
  
  function approveTransaction(bytes4 interfaceId, address tokenAddress, address to, uint256 amount, string memory nonce, uint256 expiration, string memory method) public virtual {
    require(hasRole(APPROVER_ROLE, msg.sender), "SmartWalletUpgradeable: must be an approver");    
    require(!usedNonces[nonce], "SmartWalletUpgradeable: nonce already used");
    require(expiration > block.timestamp, "SmartWalletUpgradeable: transaction had expired");

    address approver = msg.sender;
    bytes32 hash = hashToSign(interfaceId, tokenAddress, to, amount, nonce, expiration, method);
    require(approvedHashes[approver][hash] == false, "SmartWalletUpgradeable: already approved");
    
    approvedHashes[approver][hash] = true;
    approvedCounts[hash]++;
    
    emit ApproveTransaction(approver, interfaceId, tokenAddress, to, amount, nonce, expiration, method);
  }
    
  function verifySignature(bytes4 interfaceId, address tokenAddress, address to, uint256 amount, string memory nonce, uint256 expiration, string memory method, bytes memory signature) public virtual returns (bool) {
    require(!usedNonces[nonce], "SmartWalletUpgradeable: nonce already used");
    usedNonces[nonce] = true;

    require(expiration > block.timestamp, "SmartWalletUpgradeable: signature had expired");

    bytes32 hash = hashToSign(interfaceId, tokenAddress, to, amount, nonce, expiration, method);
    hash = ethSignedHash(hash);
    
    address signer = recoverSigner(hash, signature);
    require(signer != address(0) && hasRole(MODERATOR_ROLE, signer), "SmartWalletUpgradeable: unauthorized");

    return true;
  }
  
  function hashToSign(bytes4 interfaceId, address tokenAddress, address to, uint256 amount, string memory nonce, uint256 expiration, string memory method) public view virtual returns (bytes32) {
    uint256 chainId = block.chainid;
    address contractAddress = address(this);
    return keccak256(abi.encodePacked(interfaceId, tokenAddress, to, amount, nonce, expiration, method, chainId, contractAddress));
  }

  function ethSignedHash(bytes32 hash) public view virtual returns (bytes32) {
    return hash.toEthSignedMessageHash();
  }

  function recoverSigner(bytes32 hash, bytes memory signature) public view virtual returns (address) {
    return hash.recover(signature);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerableUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /***
   * Internal functions
   */  
   function _transfer(bytes4 interfaceId, address tokenAddress, address from, address to, uint256 amount) internal virtual {
     address contractAddress = address(this);
     
     if (interfaceId == INTERFACE_ID_IERC20) {
       // Withdraw
       if (from == contractAddress) {
         uint256 maxAmount = maxAmountPerWithdraw[tokenAddress];
         require(maxAmount == 0 || amount <= maxAmount, "SmartWalletUpgradeable: amount is greater than a limit");
         
         IERC20Upgradeable(tokenAddress).transfer(to, amount);
       }
       // Deposit
       else {
         IERC20Upgradeable(tokenAddress).transferFrom(from, to, amount);   
       }
     }
     else {
       revert("SmartWalletUpgradeable: token contract interface not supported");
     }

     emit Transfer(interfaceId, tokenAddress, from, to, amount);
   }
   
}