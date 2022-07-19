// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC721Upgradeable as IERC721 } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./interfaces/IROOLAH.sol";

contract RooStaking is OwnableUpgradeable, PausableUpgradeable {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
  using ECDSAUpgradeable for bytes32;

  IROOLAH public roolahToken;

  EnumerableSetUpgradeable.AddressSet enabledTokens;
  mapping(address => string) public enabledTokenConditions; // Function signature of the condition

  // Staking-related fields and events:
  mapping(address => mapping(address => EnumerableSetUpgradeable.UintSet)) stakedTokens; // stakedTokens[tokenAddress][userAddress]

  mapping(address => mapping(uint => uint)) public stakedAt; // stakedAt[tokenAddress][tokenId]

  event Staked(address token, uint tokenId, address owner, uint stakedAt);
  event Unstaked(address token, uint tokenId, address owner, uint stakedAt, uint unstakedAt);

  // Claiming-related fields and events:
  mapping(address => uint) public lastNonce;

  struct ClaimTransaction {
    uint id;
    address wallet;
    uint nonce;
    uint expiry;
    uint amount;
  }

  address public authorizedSigner;

  event TransactionClaimed(uint id, address wallet, uint amount, uint nonce);

  constructor() {}

  function initialize() public initializer {
    __Pausable_init();
    __Ownable_init();
  }

  // === ADMINISTRATION ===
  function getEnabledTokens() external view returns (address[] memory) {
    return enabledTokens.values();
  }

  function isTokenEnabled(address token) public view returns (bool) {
    return enabledTokens.contains(token);
  }

  function isTokenStakeable(address token, uint tokenId) public view returns (bool) {
    string storage condition = enabledTokenConditions[token];

    if (bytes(condition).length == 0) return true;

    (bool success, bytes memory result) = token.staticcall(abi.encodeWithSignature(condition, tokenId));
    if (!success) return false;
    (bool isStakeable) = abi.decode(result, (bool));

    return isStakeable;
  }

  function enableToken(address token) public onlyOwner {
    require(token != address(0));
    require(enabledTokens.add(token), "Token is already enabled");
  }

  function setTokenCondition(address token, string memory condition) public onlyOwner {
    enabledTokenConditions[token] = condition;
  }

  function enableTokenWithCondition(address token, string calldata condition) external onlyOwner {
    enableToken(token);
    setTokenCondition(token, condition);
  }

  function disableToken(address token) external onlyOwner {
    require(token != address(0));
    require(enabledTokens.remove(token), "Token is not enabled");
    setTokenCondition(token, "");
  }

  function setSigner(address newSigner) external onlyOwner {
    authorizedSigner = newSigner;
  }

  function setRoolahToken(address newRoolahToken) external onlyOwner {
    roolahToken = IROOLAH(newRoolahToken);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  // === STAKING ===
  function getStakedTokens(address token) external view returns (uint[] memory) {
    return stakedTokens[token][msg.sender].values();
  }

  function isStaked(address user, address token, uint tokenId) public view returns (bool) {
    return stakedTokens[token][user].contains(tokenId);
  }

  function stakeToken(address token, uint tokenId) public whenNotPaused {
    require(isTokenEnabled(token), "Token is not enabled");

    IERC721 tokenContract = IERC721(token);
    require(tokenContract.ownerOf(tokenId) == address(msg.sender), "Token must be owned by sender");
    require(!isStaked(msg.sender, token, tokenId), "Token is already staked");

    require(isTokenStakeable(token, tokenId), "Token does not meet staking conditions");

    require(tokenContract.isApprovedForAll(msg.sender, address(this)), "Token is not approved for staking");

    require(stakedTokens[token][msg.sender].add(tokenId), "Failed to stake token");
    stakedAt[token][tokenId] = block.timestamp;

    tokenContract.transferFrom(msg.sender, address(this), tokenId);

    emit Staked(token, tokenId, msg.sender, block.timestamp);
  }

  function batchStakeTokens(address[] calldata tokens, uint[] calldata tokenIds) external whenNotPaused {
    require(tokens.length == tokenIds.length, "Arrays must be the same length");

    for (uint i = 0; i < tokenIds.length; i++) {
      stakeToken(tokens[i], tokenIds[i]);
    }
  }

  function unstakeToken(address token, uint tokenId) public {
    require(isStaked(msg.sender, token, tokenId), "Token is not staked");

    require(stakedTokens[token][msg.sender].remove(tokenId), "Failed to unstake token");
    stakedAt[token][tokenId] = 0;

    IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);

    emit Unstaked(token, tokenId, msg.sender, stakedAt[token][tokenId], block.timestamp);
  }

  function batchUnstakeTokens(address[] calldata tokens, uint[] calldata tokenIds) external {
    require(tokens.length == tokenIds.length, "Arrays must be the same length");

    for (uint i = 0; i < tokenIds.length; i++) {
      unstakeToken(tokens[i], tokenIds[i]);
    }
  }

  function claimAndUnstakeTokens(bytes calldata callData, bytes memory signature, address[] calldata tokens, uint[] calldata tokenIds) external whenNotPaused {
    require(tokens.length == tokenIds.length, "Arrays must be the same length");

    ClaimTransaction memory claimTransaction = _extractClaimTransaction(callData, signature);

    _claimRewards(claimTransaction);

    for (uint i = 0; i < tokenIds.length; i++) {
      unstakeToken(tokens[i], tokenIds[i]);
    }
  }

  // === REWARDS ===
  function floorTimestampToNearestWeek(uint timestamp) public pure returns (uint) {
    return timestamp - (timestamp % (7 * 24 * 60 * 60));
  }

  function _extractClaimTransaction(bytes calldata callData, bytes memory signature) internal view returns (ClaimTransaction memory) {
    address signer = keccak256(callData).toEthSignedMessageHash().recover(signature);
    require(signer != address(0), "Invalid signature");
    require(signer == authorizedSigner, "Invalid signer");

    (ClaimTransaction memory claimTransaction) = abi.decode(callData, (ClaimTransaction));

    return claimTransaction;
  }

  function _claimRewards(ClaimTransaction memory claimTransaction) internal {
    require(claimTransaction.wallet == msg.sender, "Invalid claim address");
    require(claimTransaction.expiry > block.timestamp, "Claim has expired");
    require(claimTransaction.nonce == lastNonce[msg.sender] + 1, "Invalid nonce");
    require(address(roolahToken) != address(0), "Roolah token is not set");

    lastNonce[msg.sender] += 1;

    require(claimTransaction.amount > 0, "No rewards to claim");

    roolahToken.mint(msg.sender, claimTransaction.amount);

    emit TransactionClaimed(claimTransaction.id, claimTransaction.wallet, claimTransaction.amount, claimTransaction.nonce);
  }

  function claimRewards(bytes calldata callData, bytes memory signature) external whenNotPaused {
    _claimRewards(_extractClaimTransaction(callData, signature));
  }

  // === OTHERS ===
  function balanceOf(address owner) public view returns (uint) {
    uint balance = 0;

    uint tokenCount = enabledTokens.length();
    for (uint i = 0; i < tokenCount; i++) {
      balance += stakedTokens[enabledTokens.at(i)][owner].length();
    }

    return balance;
  }

  function isApprovedForAll(address, address) public pure returns (bool) {
    return false;
  }
}