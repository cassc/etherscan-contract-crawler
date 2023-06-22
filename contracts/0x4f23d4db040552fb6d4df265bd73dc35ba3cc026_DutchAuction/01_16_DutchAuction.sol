/**
 * @title Dutch Auction Contract
 * @author arod.studio and Fingerprints DAO
 * @notice This contract implements a Dutch Auction for NFTs (Non-Fungible Tokens).
 * The auction starts at a high price, decreasing over time until a bid is made or
 * a reserve price is reached. Users bid for a quantity of NFTs. They can withdraw
 * their funds after the auction, or claim a refund if conditions are met.
 * Additionally, users can claim additional NFTs using their prospective refunds
 * while the auction is ongoing.
 * The auction can be paused, unpaused, and configured by an admin.
 * Security features like reentrancy guard, overflow/underflow checks,
 * and signature verification are included.
 *
 * NOTE: The original contract has been modified to support merkle tree based discounts
 * in the form of increasing the amount that a user eligible for a discount is refunded.
 *
 *
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IDelegateCash} from "./IDelegateCash.sol";

import "./IDutchAuction.sol";
import "./INFT.sol";

// import "hardhat/console.sol";

/**
 * @title Dutch Auction Contract
 * @dev This contract manages a dutch auction for NFT tokens. Users can bid,
 * claim refunds, claim tokens, and admins can refund users.
 * The contract is pausable and non-reentrant for safety.
 */
contract DutchAuction is IDutchAuction, AccessControl, Pausable, ReentrancyGuard {
  /// @notice EIP712 Domain Hash
  bytes32 public immutable eip712DomainHash;

  /// @notice NFT contract address
  INFT public nftContractAddress;

  /// @notice Signer address
  address public signerAddress;

  /// @notice Treasury address that will receive funds
  address public treasuryAddress;

  /// @dev Settled Price in wei
  uint256 private _settledPriceInWei;

  /// @dev Auction Config
  Config private _config;

  /// @dev Total minted tokens
  uint32 private _totalMinted;

  /// @dev Funds withdrawn or not
  bool private _withdrawn;

  /// @dev Mapping of user address to User data
  mapping(address => User) private _userData;

  /// @dev Mapping of user address to nonce
  mapping(address => uint256) private _nonces;

  /// @dev Merkle root holding allowed discount addresses
  bytes32 public discountMerkleRoot;

  /// @dev Delegate cash contract address
  IDelegateCash public delegateCash;

  modifier validConfig() {
    if (_config.startTime == 0) revert ConfigNotSet();
    _;
  }

  modifier validTime() {
    Config memory config = _config;
    if (block.timestamp > config.endTime || block.timestamp < config.startTime)
      revert InvalidStartEndTime(config.startTime, config.endTime);
    _;
  }

  /// @notice DutchAuction Constructor
  /// @param _nftAddress NFT contract address
  /// @param _signerAddress Signer address
  /// @param _treasuryAddress Treasury address
  /// @param _discountMerkleRoot Merkle root for discounts
  /// @param _delegateCash Delegate cash address
  constructor(
    address _nftAddress,
    address _signerAddress,
    address _treasuryAddress,
    bytes32 _discountMerkleRoot,
    address _delegateCash
  ) {
    nftContractAddress = INFT(_nftAddress);
    signerAddress = _signerAddress;
    treasuryAddress = _treasuryAddress;
    discountMerkleRoot = _discountMerkleRoot;
    delegateCash = IDelegateCash(_delegateCash);

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    eip712DomainHash = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("Fingerprints DAO Dutch Auction")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  /// @notice Set auction config
  /// @dev Only admin can set auction config
  /// @param startAmountInWei Auction start amount in wei
  /// @param endAmountInWei Auction end amount in wei
  /// @param limitInWei Maximum amount users can use to purchase NFTs
  /// @param refundDelayTime Delay time which users need to wait to claim refund after the auction ends
  /// @param startTime Auction start time
  /// @param endTime Auction end time
  function setConfig(
    uint256 startAmountInWei,
    uint256 endAmountInWei,
    uint216 limitInWei,
    uint32 refundDelayTime,
    uint64 startTime,
    uint64 endTime
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_config.startTime != 0 && _config.startTime <= block.timestamp) revert ConfigAlreadySet();

    if (startTime == 0 || startTime >= endTime) revert InvalidStartEndTime(startTime, endTime);
    if (startAmountInWei == 0 || startAmountInWei <= endAmountInWei) revert InvalidAmountInWei();
    if (limitInWei == 0) revert InvalidAmountInWei();

    _config = Config({
      startAmountInWei: startAmountInWei,
      endAmountInWei: endAmountInWei,
      limitInWei: limitInWei,
      refundDelayTime: refundDelayTime,
      startTime: startTime,
      endTime: endTime
    });
  }

  /**
   * @dev Sets the merkle root for discounts.
   *
   * Requirements:
   * - Caller must have the DEFAULT_ADMIN_ROLE.
   *
   * @param root The new merkle root.
   */
  function setDiscountMerkleRoot(bytes32 root) external onlyRole(DEFAULT_ADMIN_ROLE) {
    discountMerkleRoot = root;
  }

  /**
   * @dev Sets the address of the NFT contract.
   *
   * Requirements:
   * - Caller must have the DEFAULT_ADMIN_ROLE.
   * - New address must not be the zero address.
   *
   * @param newAddress The address of the new NFT contract.
   */
  function setNftContractAddress(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(newAddress != address(0), "Invalid address: zero address not allowed");
    nftContractAddress = INFT(newAddress);
  }

  /**
   * @dev Sets the signer address.
   *
   * Requirements:
   * - Caller must have the DEFAULT_ADMIN_ROLE.
   * - New address must not be the zero address.
   *
   * @param newAddress The address of the new signer.
   */
  function setSignerAddress(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(newAddress != address(0), "Invalid address: zero address not allowed");
    signerAddress = newAddress;
  }

  /// @notice Sets treasury address
  /// @param _treasuryAddress New treasury address
  function setTreasuryAddress(address _treasuryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_treasuryAddress != address(0), "Invalid address: zero address not allowed");
    treasuryAddress = _treasuryAddress;
  }

  /// @notice Pause the auction
  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  /// @notice Unpause the auction
  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  /// @notice Get auction config
  /// @return config Auction config
  function getConfig() external view returns (Config memory) {
    return _config;
  }

  /// @notice Get user data
  /// @param user User address
  /// @return User struct
  function getUserData(address user) external view returns (User memory) {
    return _userData[user];
  }

  /// @notice Get auction's settled price
  /// @return price Auction's settled price
  function getSettledPriceInWei() external view returns (uint256) {
    return _settledPriceInWei;
  }

  /// @notice Get auction's current price
  /// @return price Auction's current price
  function getCurrentPriceInWei() public view returns (uint256) {
    Config memory config = _config; // storage to memory
    // Return startAmountInWei if auction not started
    if (block.timestamp <= config.startTime) return config.startAmountInWei;
    // Return endAmountInWei if auction ended
    if (block.timestamp >= config.endTime) return config.endAmountInWei;

    // Declare variables to derive in the subsequent unchecked scope.
    uint256 duration;
    uint256 elapsed;
    uint256 remaining;

    // Skip underflow checks as startTime <= block.timestamp < endTime.
    unchecked {
      // Derive the duration for the order and place it on the stack.
      duration = config.endTime - config.startTime;

      // Derive time elapsed since the order started & place on stack.
      elapsed = block.timestamp - config.startTime;

      // Derive time remaining until order expires and place on stack.
      remaining = duration - elapsed;
    }

    return (config.startAmountInWei * remaining + config.endAmountInWei * elapsed) / duration;
  }

  /// @notice Get user's nonce for signature verification
  /// @param user User address
  /// @return nonce User's nonce
  function getNonce(address user) external view returns (uint256) {
    return _nonces[user];
  }

  /// @dev Return user's current nonce and increase it
  /// @param user User address
  /// @return current Current nonce
  function useNonce(address user) internal returns (uint256 current) {
    current = _nonces[user];
    ++_nonces[user];
  }

  /// @notice Make bid to purchase NFTs
  /// @param qty Amount of tokens to purchase
  /// @param deadline Timestamp when the signature expires
  /// @param signature Signature to verify user's purchase
  /// @param vaultAddress Address of vault being delegated for
  function bid(
    uint32 qty,
    uint256 deadline,
    bytes memory signature,
    address vaultAddress
  ) external payable nonReentrant whenNotPaused validConfig validTime {
    address requester = msg.sender;

    if (vaultAddress != address(0) && vaultAddress != msg.sender) {
      bool isDelegateValid = delegateCash.checkDelegateForContract(
        msg.sender,
        vaultAddress,
        address(nftContractAddress)
      );
      require(isDelegateValid, "invalid delegate-vault pairing");
      requester = vaultAddress;
    }

    if (block.timestamp > deadline) revert BidExpired(deadline);
    if (qty < 1) revert InvalidQuantity();

    bytes32 hashStruct = keccak256(
      abi.encode(
        keccak256("Bid(address account,uint32 qty,uint256 nonce,uint256 deadline)"),
        requester,
        qty,
        useNonce(requester),
        deadline
      )
    );

    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));

    address recoveredSigner = ECDSA.recover(hash, signature);
    if (signerAddress != recoveredSigner) revert InvalidSignature();

    uint32 available = nftContractAddress.maxSupply() - uint16(nftContractAddress.totalSupply());

    if (qty > available) {
      revert MaxSupplyReached();
    }

    uint256 price = getCurrentPriceInWei();
    uint256 payment = qty * price;
    if (msg.value < payment) revert NotEnoughValue();

    User storage bidder = _userData[requester]; // get user's current bid total
    bidder.contribution = bidder.contribution + uint216(payment);
    bidder.tokensBidded = bidder.tokensBidded + qty;

    if (bidder.contribution > _config.limitInWei) revert PurchaseLimitReached();

    _totalMinted += qty;

    // _settledPriceInWei is always the minimum price of all the bids' unit price
    if (price < _settledPriceInWei || _settledPriceInWei == 0) {
      _settledPriceInWei = price;
    }

    if (msg.value > payment) {
      uint256 refundInWei = msg.value - payment;
      (bool success, ) = requester.call{value: refundInWei}("");
      if (!success) revert TransferFailed();
    }
    // mint tokens to user
    _mintTokens(requester, qty);

    emit Bid(requester, qty, price);
  }

  /// @notice Return user's claimable tokens count
  /// @param user User address
  /// @return claimable Claimable tokens count
  function getClaimableTokens(address user) public view returns (uint32 claimable) {
    User storage bidder = _userData[user]; // get user's current bid total
    uint256 price = getCurrentPriceInWei();
    claimable = uint32(bidder.contribution / price) - bidder.tokensBidded;
    uint32 available = nftContractAddress.maxSupply() - uint16(nftContractAddress.totalSupply());
    if (claimable > available) claimable = available;
  }

  /// @notice Claim additional NFTs without additional payment
  /// @param amount Number of tokens to claim
  /// @param vaultAddress Address to check
  function claimTokens(
    uint32 amount,
    address vaultAddress
  ) external nonReentrant whenNotPaused validConfig validTime {
    address requester = msg.sender;

    if (vaultAddress != address(0) && vaultAddress != msg.sender) {
      bool isDelegateValid = delegateCash.checkDelegateForContract(
        msg.sender,
        vaultAddress,
        address(nftContractAddress)
      );
      require(isDelegateValid, "invalid delegate-vault pairing");
      requester = vaultAddress;
    }

    User storage bidder = _userData[requester]; // get user's current bid total
    uint256 price = getCurrentPriceInWei();
    uint32 claimable = getClaimableTokens(requester);
    if (amount > claimable) amount = claimable;
    if (amount == 0) revert NothingToClaim();

    bidder.tokensBidded = bidder.tokensBidded + amount;
    _totalMinted += amount;

    // _settledPriceInWei is always the minimum price of all the bids' unit price
    if (price < _settledPriceInWei) {
      _settledPriceInWei = price;
    }

    _mintTokens(requester, amount);

    emit Claim(requester, amount);
  }

  /// @notice Admin withdraw funds
  /// @dev Only admin can withdraw funds
  function withdrawFunds() external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_config.endTime >= block.timestamp) revert NotEnded();

    (bool success, ) = treasuryAddress.call{value: address(this).balance}("");
    if (!success) revert TransferFailed();
  }

  /**
   * @notice Allows a participant to claim their refund after the auction ends.
   * Refund is calculated based on the difference between their contribution and the final settled price.
   * This function can only be called after the refund delay time has passed post-auction end.
   * Note: If the function reverts with 'ClaimRefundNotReady', it means the refund delay time has not passed yet.
   */
  function claimRefund(
    address vaultAddress,
    bytes32[] calldata proof
  ) external nonReentrant whenNotPaused validConfig onlyRole(DEFAULT_ADMIN_ROLE) {
    Config memory config = _config;
    if (config.endTime + config.refundDelayTime >= block.timestamp) revert ClaimRefundNotReady();

    _claimRefund(vaultAddress, proof);
  }

  /**
   * @notice Admin-enforced claim of refunds for a list of user addresses.
   * This function is identical to `claimRefund` but allows an admin to force
   * users to claim their refund.
   * Note: If the function reverts with 'ClaimRefundNotReady', it means the refund delay time has not passed yet.
   * @param accounts An array of addresses for which refunds will be claimed.
   */
  function refundUsers(
    address[] memory accounts,
    bytes32[][] calldata proofs
  ) external nonReentrant whenNotPaused validConfig onlyRole(DEFAULT_ADMIN_ROLE) {
    if (accounts.length != proofs.length) revert InvalidProofsLength();

    uint256 length = accounts.length;
    for (uint256 i; i != length; ++i) {
      _claimRefund(accounts[i], proofs[i]);
    }
  }

  /**
   * @dev Internal function for applying discounts.
   * The function returns the discounted final cost for the user, effectively increasing their rebate.
   * @param buyer Address of the user receiving the discount.
   * @param cost Total, non discounted cost for the user.
   * @param proof Merkle proof for the user's address and discount.
   * @return discountedCost Discounted cost for the user.
   */
  function _applyDiscount(
    address buyer,
    uint256 cost,
    bytes32[] calldata proof
  ) internal view returns (uint256) {
    require(discountMerkleRoot != bytes32(0), "Merkle root not set");

    uint256 discountedCost = cost;

    uint16[5] memory discountBps = [2500, 2250, 2000, 1500, 1000];

    for (uint256 i = 0; i < discountBps.length; i++) {
      bytes32 leaf = keccak256(abi.encodePacked(buyer, discountBps[i]));
      if (MerkleProof.verify(proof, discountMerkleRoot, leaf)) {
        uint256 discount = (cost * discountBps[i]) / 10000;
        discountedCost = cost - discount;
        break;
      }
    }

    return discountedCost;
  }

  /**
   * @dev Internal function for processing refunds.
   * The function calculates the refund as the user's total contribution minus the amount spent on bidding.
   * It then sends the refund (if any) to the user's account.
   * Note: If the function reverts with 'UserAlreadyClaimed', it means the user has already claimed their refund.
   * @param account Address of the user claiming the refund.
   */
  function _claimRefund(address account, bytes32[] calldata proof) internal {
    User storage user = _userData[account];
    if (user.refundClaimed) revert UserAlreadyClaimed();
    user.refundClaimed = true;
    uint256 refundInWei = user.contribution -
      _applyDiscount(account, (_settledPriceInWei * user.tokensBidded), proof);
    if (refundInWei > 0) {
      (bool success, ) = account.call{value: refundInWei}("");
      if (!success) revert TransferFailed();
      emit ClaimRefund(account, refundInWei);
    }
  }

  /**
   * @dev Internal function to mint a specified quantity of NFTs for a recipient.
   * This function mints 'qty' number of NFTs to the 'to' address.
   * @param to Recipient address.
   * @param qty Number of NFTs to mint.
   */
  function _mintTokens(address to, uint32 qty) internal {
    for (uint32 i; i != qty; ++i) {
      nftContractAddress.mint(to);
    }
  }
}