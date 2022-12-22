// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {
  Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
  OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
  PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IRegistrar} from "./interfaces/IRegistrar.sol";
import {
  MerkleProofUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract WapeSale is Initializable, OwnableUpgradeable, PausableUpgradeable {
  // zNS Registrar
  IRegistrar public zNSRegistrar;

  event RefundedEther(address buyer, uint256 amount);

  event SaleStarted(uint256 block);

  event SaleStopped(uint256 block);

  // The parent domain to mint sold domains under
  uint256 public parentDomainId;

  // Price of each domain to be sold
  uint256 public salePrice;

  // The wallet to transfer proceeds to
  address public sellerWallet;

  // Number of domains sold so far
  uint256 public domainsSold;

  // Indicating whether the sale has started or not
  bool public saleStarted;

  // The block number that a sale started on
  uint256 public saleStartBlock;

  // Time in blocks that the privatesale will occur
  uint256 public mintlistSaleDuration;

  // How many domains for sale during private sale
  uint256 public amountForSale;

  // The number with which to start the metadata index (e.g. number is 100, so indicies are 100, 101, ...)
  uint256 public startingMetadataIndex;

  // The ID of the folder group that has been set up for this sale - needs to be initialized in advance
  uint256 public folderGroupID;

  // Merkle root data to verify on mintlist
  bytes32 public mintlistMerkleRoot;

  // Mapping to keep track of how many domains an account has purchased so far in both private and public sale periods
  // This is a running total and will apply equally to the sale regardless of the phase and it's limit.
  // e.g. 5 purchased in the private sale means only 4 more can be bought in the public sale if the public limit is 9
  // If you are not in the private sale, your limit for the public sale will be 9.
  mapping(address => uint256) public domainsPurchasedByAccount;

  // The number of domains that can be purchased in the public sale.
  uint256 public publicSaleLimit;

  function __WapeSale_init(
    uint256 parentDomainId_,
    uint256 price_,
    IRegistrar zNSRegistrar_,
    address sellerWallet_,
    uint256 mintlistSaleDuration_,
    uint256 amountForSale_,
    bytes32 merkleRoot_,
    uint256 startingMetadataIndex_,
    uint256 folderGroupID_,
    uint256 publicSaleLimit_
  ) public initializer {
    __Ownable_init();

    parentDomainId = parentDomainId_;
    salePrice = price_;
    zNSRegistrar = zNSRegistrar_;
    sellerWallet = sellerWallet_;
    mintlistSaleDuration = mintlistSaleDuration_;
    mintlistMerkleRoot = merkleRoot_;
    startingMetadataIndex = startingMetadataIndex_;
    folderGroupID = folderGroupID_;
    amountForSale = amountForSale_;
    publicSaleLimit = publicSaleLimit_;
  }

  function setRegistrar(IRegistrar zNSRegistrar_) external onlyOwner {
    require(zNSRegistrar != zNSRegistrar_, "Same registrar");
    zNSRegistrar = zNSRegistrar_;
  }

  // Start the sale if not started
  function startSale() external onlyOwner {
    require(!saleStarted, "Sale already started");
    saleStarted = true;
    saleStartBlock = block.number;
    emit SaleStarted(saleStartBlock);
  }

  // Stop the sale if started
  function stopSale() external onlyOwner {
    require(saleStarted, "Sale not started");
    saleStarted = false;
    emit SaleStopped(block.number);
  }

  // Update the data that acts as the merkle root
  function setMerkleRoot(bytes32 root) external onlyOwner {
    require(mintlistMerkleRoot != root, "same root");
    mintlistMerkleRoot = root;
  }

  // Pause a sale
  function setPauseStatus(bool pauseStatus) external onlyOwner {
    require(paused() != pauseStatus, "No state change");
    if(pauseStatus){
      _pause();
    } else {
      _unpause();
    }
  }

  // Set the price of this sale
  function setSalePrice(uint256 price) external onlyOwner {
    require(salePrice != price, "No price change");
    salePrice = price;
  }

  function setSaleQuantity(uint256 amountForSale_) external onlyOwner {
    require(amountForSale_ != amountForSale, "No state change");
    amountForSale = amountForSale_;
  }

  // Modify the address of the seller wallet
  function setSellerWallet(address wallet) external onlyOwner {
    require(wallet != sellerWallet, "Same Wallet");
    sellerWallet = wallet;
  }

  // Modify parent domain ID of a domain
  function setParentDomainId(uint256 parentId) external onlyOwner {
    require(parentDomainId != parentId, "Same parent id");
    parentDomainId = parentId;
  }

  // Update the number of blocks that the sale will occur
  function setSaleDuration(uint256 durationInBlocks) external onlyOwner {
    require(mintlistSaleDuration != durationInBlocks, "No state change");
    mintlistSaleDuration = durationInBlocks;
  }

  // Set the number with which to start the metadata index (e.g. number is 100, so indicies are 100, 101, ...)
  function setStartIndex(uint256 index) external onlyOwner {
    require(index != startingMetadataIndex, "Cannot set to the same index");
    startingMetadataIndex = index;
  }

  // Set the folder group that the minted NFTs will reference. See registrar for more information.
  function setFolderGroupID(uint256 folderGroupID_) external onlyOwner {
    require(folderGroupID != folderGroupID_, "Cannot set to same folder group");
    folderGroupID = folderGroupID_;
  }

  function setPublicSaleLimit(uint256 limit_) external onlyOwner {
    require(publicSaleLimit != limit_, "Cannot set the same limit");
    publicSaleLimit = limit_;
  }

  // Remove a domain from this sale
  function releaseDomain() external onlyOwner {
    zNSRegistrar.transferFrom(address(this), owner(), parentDomainId);
  }

  // Purchase `count` domains
  // Note the `purchaseLimit` you provide must be
  // less than or equal to what is in the mintlist
  function purchaseDomains(
    uint256 count,
    uint256 index,
    uint256 purchaseLimit,
    bytes32[] calldata merkleProof
  ) public payable {
    _canAccountPurchase(msg.sender, count, purchaseLimit, true);
    _requireVariableMerkleProof(index, purchaseLimit, merkleProof);
    _purchaseDomains(count);
  }

  // Purchasing during the public sale
  function purchaseDomainsPublicSale(uint8 count) public payable {
    _canAccountPurchase(msg.sender, count, publicSaleLimit, false);
    _purchaseDomains(count);
  }

  function _canAccountPurchase(
    address account,
    uint256 count,
    uint256 purchaseLimit,
    bool privateSale
  ) internal view whenNotPaused {
    require(saleStarted, "Sale hasn't started or has ended");
    if(privateSale) {
      require(block.number <= saleStartBlock + mintlistSaleDuration, "Not in private sale");
    } else {
      require(block.number > saleStartBlock + mintlistSaleDuration, "Not in public sale");
    }
    require(count > 0, "Zero purchase count");
    require(domainsSold < amountForSale, "No domains left for sale");
    require(
        domainsPurchasedByAccount[account] + count <= purchaseLimit,
        "Purchasing beyond limit."
      );
    require(msg.value >= salePrice * count, "Not enough funds in purchase");
  }

  function _purchaseDomains(uint256 count) internal {
    uint256 numPurchased = _reserveDomainsForPurchase(count);
    uint256 proceeds = salePrice * numPurchased;
    _sendPayment(proceeds);
    _mintDomains(numPurchased);
  }

  function _reserveDomainsForPurchase(uint256 count) internal returns (uint256) {
    uint256 numPurchased = count;
    uint256 numForSale = amountForSale;
    // If we would are trying to purchase more than is available, purchase the remainder
    if (domainsSold + count > numForSale) {
      numPurchased = numForSale - domainsSold;
    }
    domainsSold += numPurchased;

    // Update number of domains this account has purchased
    // This is done before minting domains or sending any eth to prevent
    // a re-entrance attack through a recieve() or a safe transfer callback
    domainsPurchasedByAccount[msg.sender] =
      domainsPurchasedByAccount[msg.sender] +
      numPurchased;

    return numPurchased;
  }

  // Transfer funds to the buying user, refunding if necessary
  function _sendPayment(uint256 proceeds) internal {
    payable(sellerWallet).transfer(proceeds);

    // Send refund if neceesary for any unpurchased domains
    if (msg.value - proceeds > 0) {
      payable(msg.sender).transfer(msg.value - proceeds);
      emit RefundedEther(msg.sender, msg.value - proceeds);
    }
  }

  function _mintDomains(uint256 numPurchased) internal {
    // Mint the domains after they have been purchased
    uint256 startingIndex = startingMetadataIndex + domainsSold - numPurchased;

    // The sale contract will be the minter and own them at this point
    zNSRegistrar.registerDomainInGroupBulk(
      parentDomainId, //parentId
      folderGroupID, //groupId
      0, //namingOffset
      startingIndex, //startingIndex
      startingIndex + numPurchased, //endingIndex
      sellerWallet, //minter
      0, //royaltyAmount
      msg.sender //sendTo
    );
  }

  function _requireVariableMerkleProof(
    uint256 index,
    uint256 quantity,
    bytes32[] calldata merkleProof
  ) internal view {
    bytes32 node = keccak256(abi.encodePacked(index, msg.sender, quantity));
    require(
      MerkleProofUpgradeable.verify(merkleProof, mintlistMerkleRoot, node),
      "Invalid Merkle Proof"
    );
  }
}