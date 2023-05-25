// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////#@@@@@(//////////////////////////////
///////////////////////////&@@@@@@**@@@@@//////////@@@&/////////////////////////
///////////////////////&@@/@@@@@@(////////@///%@//@/////@@@%////////////////////
////////////////////@@&////////@////////&@//%@/@/@@(@(/@@@/@%///////////////////
///////////////////@@/////////(&///////@@///@&@#/@&@&/@@@(/@#///////////////////
///////////////////@(/////////@////////%(///////////(/#//#/@@///////////////////
//////////////////@@///////////////(&@@@@@@@@@@@@@@@@@@@@@%(@#//////////////////
/////////////////#@////////@@@@@******************************#@@@//////////////
////////////////(@///#@@@%%%%%%&@***************&@@@@@@@@@&/*******%@@(/////////
///////////////(@@@@%%%%%%%%%%%%%@@*****%@@@@((((((((((((((@@/%@@@#****@@///////
//////////////////@@%%%%%%%%%%%@@((((((((((((((((((((((((((#@&//////%@@@@///////
//////////////////(@%%%%%%%%%@@((((((@@@@@(((((((((((((@@@@@@@//////////////////
//////////////////(@@@@@@@%%@@((&@@@@@@@@@@@&%&%##((((#/##&&&&@@@&//////////////
/////////////////@@((((((@@&@@@@//,  //....   .,,,* ......////@@@@//////////////
////////////////@@(@@@@@((((@@@@////  //....    ,,,,  .....///@@@@//////////////
///////////////(@@((((@@@((((@%@/////  //....    ,,,,, .....//@@@@//////////////
///////////////&@@((@@(@&(((((&@//////  */,...    ,*,*, ...../#@@&//////////////
///////////////%@&((((((((((((((((((///   //... (((@%(/, .....%@@(//////////////
////////////////@@((((((((((((((((((((((((////((((((((((/  #(((@@///////////////
////////////////(@@((((((((((((((((((((((((((((((((((((((@@(((@@#///////////////
//////////////////@@@(((((%(((((((((((((((((((((((((@((((@@@@@@/////////////////
////////////////////@@@@@@@@(((((((((((((((((((((#@@@@((%@&/////////////////////
///////////////////////////&@@(((((((((((((((((((((@@,@(@@//////////////////////
/////////////////////////////@@@@((((((((((((((((((((@ @%///////////////////////
////////////////////////////@@((@@@@((((((((((((((((@@@ %(//////////////////////
//////////////////////////(@@(((((((#@@@@@@@@@@@@@@#//@@ @//////////////////////
//////////////////(&@@@@&#@@((((((((((@@///////////////@##@/////////////////////
/////////////(@@#*******@@@((((((((((@@(////////////////////////////////////////
///////////@@*****@&***@@&((((((((((@@@@@///////////////////////////////////////
/////////&@**********(@@@@#((((((((@@&*@@@@/////////////////////////////////////
////////@@*****************@@@&@@@@@@@@@***@////////////////////////////////////
////////@/****************@@,&@@@@********@@////////////////////////////////////
///////#@&***************@&..,,[email protected]*********&@///////////////////////////////////
/////@@#&***************@#%@@@@************@@///////////////////////////////////
contract LoserClub is ERC721A, Ownable {
  // general
  uint256 public mintPrice = 0.088 ether;
  uint256 public maxSupply;
  string internal baseTokenUri;
  string internal baseTokenUriExt;
  string public provenance;
  address payable public mainWallet;

  // public
  uint256 public publicSaleTime;
  uint256 public maxPerTxnPublic;
  uint256 public maxPerWalletPublic;
  bool public isPublicMintEnabled;

  // allowlist
  bool public isAllowlistMintEnabled;
  uint256 public allowlistSaleTime;
  uint256 public maxPerTxnAllowlist;
  uint256 public maxPerWalletAllowlist;
  bytes32 private merkleRoot;

  constructor() payable ERC721A('Loser Club', 'LOSERCLUB') {
    maxSupply = 10000;
    maxPerTxnAllowlist = 2;
    maxPerWalletAllowlist = 2;
    maxPerTxnPublic = 5;
    maxPerWalletPublic = 5;
    publicSaleTime = 1646514000; // (March 5, 9:00 PM UTC)
    allowlistSaleTime = 1646427600; // (March 4, 9:00 PM UTC)
    mainWallet = payable(address(0x25eb3CCadc751E73bff53f1976C62E959D757D5f));
  }

  /**
   =========================================
   Owner Functions
   @dev these functions can only be called 
      by the owner of contract. some functions
      here are meant only for backup cases.
      separate maxpertxn and maxperwallet for
      max flexibility
   =========================================
  */
  function setIsPublicMintEnabled(bool isPublicMintEnabled_)
    external
    onlyOwner
  {
    isPublicMintEnabled = isPublicMintEnabled_;
  }

  function setIsAllowlistMintEnabled(bool isAllowlistMintEnabled_)
    external
    onlyOwner
  {
    isAllowlistMintEnabled = isAllowlistMintEnabled_;
  }

  function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
    merkleRoot = merkleRoot_;
  }

  function setPublicSaleTime(uint256 setPublicSaleTime_) external onlyOwner {
    publicSaleTime = setPublicSaleTime_;
  }

  function setAllowlistSaleTime(uint256 setAllowlistSaleTime_)
    external
    onlyOwner
  {
    allowlistSaleTime = setAllowlistSaleTime_;
  }

  function setBaseTokenUri(string calldata newBaseTokenUri_)
    external
    onlyOwner
  {
    baseTokenUri = newBaseTokenUri_;
  }

  function setBaseTokenUriExt(string calldata newBaseTokenUriExt_)
    external
    onlyOwner
  {
    baseTokenUriExt = newBaseTokenUriExt_;
  }

  function setPriceInWei(uint256 price_) external onlyOwner {
    mintPrice = price_;
  }

  function setMaxSupply(uint256 maxSupply_) external onlyOwner {
    maxSupply = maxSupply_;
  }

  function setMaxPerWalletPublic(uint256 maxPerWalletPublic_)
    external
    onlyOwner
  {
    maxPerWalletPublic = maxPerWalletPublic_;
  }

  function setMaxPerWalletAllowlist(uint256 maxPerWalletAllowlist_)
    external
    onlyOwner
  {
    maxPerWalletAllowlist = maxPerWalletAllowlist_;
  }

  function setMaxPerTxnPublic(uint256 maxPerTxnPublic_) external onlyOwner {
    maxPerTxnPublic = maxPerTxnPublic_;
  }

  function setProvenance(string calldata provenance_) external onlyOwner {
    provenance = provenance_;
  }

  function setMaxPerTxnAllowlist(uint256 maxPerTxnAllowlist_)
    external
    onlyOwner
  {
    maxPerTxnAllowlist = maxPerTxnAllowlist_;
  }

  function setMainWallet(address mainWallet_) external onlyOwner {
    mainWallet = payable(mainWallet_);
  }

  function withdraw() external onlyOwner {
    (bool success, ) = mainWallet.call{ value: address(this).balance }('');
    require(success, 'failed to withdraw money');
  }

  /**
   =========================================
   Mint Functions
   @dev these functions are relevant  
      for minting purposes only
   =========================================
  */
  function mintPublic(uint256 quantity_) public payable {
    require(block.timestamp >= publicSaleTime, 'not public sale time yet');
    require(isPublicMintEnabled, 'minting not enabled');
    require(tx.origin == msg.sender, 'contracts not allowed');
    require(msg.value == getPrice(quantity_), 'wrong value');
    require(
      _numberMinted(msg.sender) + quantity_ <= maxPerWalletPublic,
      'exceeds max wallet'
    );
    require(totalSupply() < maxSupply, 'sold out');
    require(totalSupply() + quantity_ <= maxSupply, 'exceeds max supply');
    require(quantity_ <= maxPerTxnPublic, 'exceeds max per txn');

    _safeMint(msg.sender, quantity_);
  }

  function mintAllowlist(uint256 quantity_, bytes32[] calldata proof_)
    public
    payable
  {
    require(
      block.timestamp >= allowlistSaleTime,
      'not allowlist sale time yet'
    );
    require(isAllowlistMintEnabled, 'minting not enabled');
    require(tx.origin == msg.sender, 'contracts not allowed');
    require(msg.value == getPrice(quantity_), 'wrong value');
    require(checkAllowlist(proof_), 'address supplied is not on the allowlist');
    require(
      _numberMinted(msg.sender) + quantity_ <= maxPerWalletAllowlist,
      'exceeds max wallet allowlist'
    );
    require(totalSupply() < maxSupply, 'sold out');
    require(totalSupply() + quantity_ <= maxSupply, 'exceeds max supply');
    require(quantity_ <= maxPerTxnAllowlist, 'exceeds max per txn');

    _safeMint(msg.sender, quantity_);
  }

  function mintOwner(uint256 quantity_) external onlyOwner {
    _safeMint(msg.sender, quantity_);
  }

  /**
   ============================================
   Public & External Functions
   @dev functions that can be called by anyone
   ============================================
  */
  function checkAllowlist(bytes32[] calldata proof_)
    public
    view
    returns (bool)
  {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    return MerkleProof.verify(proof_, merkleRoot, leaf);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function multiTransferFrom(
    address from_,
    address to_,
    uint256[] calldata tokenIds_
  ) public {
    uint256 tokenIdsLength = tokenIds_.length;
    for (uint256 i = 0; i < tokenIdsLength; i++) {
      transferFrom(from_, to_, tokenIds_[i]);
    }
  }

  function multiSafeTransferFrom(
    address from_,
    address to_,
    uint256[] calldata tokenIds_,
    bytes calldata data_
  ) public {
    for (uint256 i = 0; i < tokenIds_.length; i++) {
      safeTransferFrom(from_, to_, tokenIds_[i], data_);
    }
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

  function getPrice(uint256 quantity_) public view returns (uint256) {
    return mintPrice * quantity_;
  }

  function tokenURI(uint256 tokenId_)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId_), 'Token does not exist!');
    return
      string(
        abi.encodePacked(
          baseTokenUri,
          Strings.toString(tokenId_),
          baseTokenUriExt
        )
      );
  }
}