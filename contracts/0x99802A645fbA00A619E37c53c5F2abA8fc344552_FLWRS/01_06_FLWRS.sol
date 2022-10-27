// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

////////////////////////////////////////////////////////////////////////////////
//                                    ,//@,,                                  //
//                                   @////@,,                                 //
//                                  %//////&,,                                //
//                                  /,//////,,                                //
//                                 /,///////,,,                               //
//              %@,,,,.           (/////////@,,               @               //
//              @,////@,,,        #,////////#,,          @/,///,,             //
//               @,///////,,,     /,/////////,,       /*,/////,,,             //
//                @*////////@,,   /,/////////,,    /*,///(///,,,              //
//                  /,/////////,,,/,/////////,, @/,////(////,,                //
//                   @*////(/////,@/////////@,@/,/////////*,,                 //
//                     @,////(//////////////,/,/////////@,,                   //
//                       @/,///(////////////////(/////,,,                     //
//          /////////@@     /,/////////////////////@,,  @@/////////@          //
//          ,,////////////*,////////////////////@//,,////////////,,,          //
//            ,,,@///////(//////////////////////////(////////@,,,             //
//                 ,,,,@///////////////////////////////(@,,,,                 //
//                        ,,,////////////////////(,,,                         //
//                       /,,//(/////@,@//,&//////////@                        //
//                    /,//////@,,,,,  @//,  ,,,@/////////                     //
//                     ,,,,,,%%%%%%%%%@//%%%%%%%%%%,,,,,,                     //
//                          ,%##@#((((((((((((#@##@&                          //
//                           @%%%%%%%%%%%%%%%%%%%%%                           //
//                            @**#@@%%%%%%@@@#####                            //
//                             **################                             //
//                             @**##@%#####@%####                             //
//                              **##@%#####@@###                              //
//                              @*/############@                              //
//                               /*############                               //
//                                  @@#####%@                                 //
////////////////////////////////////////////////////////////////////////////////

contract FLWRS is ERC721A, Ownable {
  // general
  uint256 public mintPrice = 0.0777 ether;
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

  // allowlistOg
  bool public isAllowlistOgMintEnabled;
  uint256 public allowlistOgSaleTime;
  uint256 public maxPerTxnAllowlistOg;
  uint256 public maxPerWalletAllowlistOg;
  bytes32 private merkleRootOg;

  constructor() payable ERC721A('FLWRS', 'FLWRS') {
    maxSupply = 8888;
    maxPerTxnPublic = 5;
    maxPerWalletPublic = 5;
    maxPerTxnAllowlist = 5;
    maxPerWalletAllowlist = 5;
    maxPerTxnAllowlistOg = 5;
    maxPerWalletAllowlistOg = 5;
    publicSaleTime = 1666999200; // (October 28, 4:20 PM PDT / 7:20pm EDT / 11:20pm UTC)
    allowlistSaleTime = 1666826400; // (October 26, 4:20 PM PDT / 7:20pm EDT / 11:20pm UTC)
    allowlistOgSaleTime = 1666826400; // (October 26, 4:20 PM PDT / 7:20pm EDT / 11:20pm UTC)
    mainWallet = payable(address(0xcE59360120b2b3D25a05AA958C04D5a30Ee3A54e));
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
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

  function setIsAllowlistOgMintEnabled(bool isAllowlistOgMintEnabled_)
    external
    onlyOwner
  {
    isAllowlistOgMintEnabled = isAllowlistOgMintEnabled_;
  }

  function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
    merkleRoot = merkleRoot_;
  }

  function setMerkleRootOg(bytes32 merkleRootOg_) external onlyOwner {
    merkleRootOg = merkleRootOg_;
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

  function setAllowlistOgSaleTime(uint256 setAllowlistOgSaleTime_)
    external
    onlyOwner
  {
    allowlistOgSaleTime = setAllowlistOgSaleTime_;
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

  function setMaxPerTxnPublic(uint256 maxPerTxnPublic_) external onlyOwner {
    maxPerTxnPublic = maxPerTxnPublic_;
  }

  function setMaxPerWalletAllowlist(uint256 maxPerWalletAllowlist_)
    external
    onlyOwner
  {
    maxPerWalletAllowlist = maxPerWalletAllowlist_;
  }

  function setMaxPerWalletAllowlistOg(uint256 maxPerWalletAllowlistOg_)
    external
    onlyOwner
  {
    maxPerWalletAllowlistOg = maxPerWalletAllowlistOg_;
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

  function setMaxPerTxnAllowlistOg(uint256 maxPerTxnAllowlistOg_)
    external
    onlyOwner
  {
    maxPerTxnAllowlistOg = maxPerTxnAllowlistOg_;
  }

  function setMainWallet(address mainWallet_) external onlyOwner {
    mainWallet = payable(mainWallet_);
  }

  function withdraw(uint256 amount_) external onlyOwner {
    require(
      amount_ <= address(this).balance,
      'requested amount is more than ETH contained within contract'
    );
    (bool success, ) = mainWallet.call{ value: amount_ }('');
    require(success, 'failed to withdraw money');
  }

  function withdrawAll() external onlyOwner {
    (bool success, ) = mainWallet.call{ value: address(this).balance }('');
    require(success, 'failed to withdraw money');
  }

  function transferOneAirdropPerAddress(
    uint256[] calldata tokenIds_,
    address[] calldata airdropAddresses_
  ) external onlyOwner {
    uint256 tokenIdsLength = tokenIds_.length;
    uint256 airdropAddressesLength = airdropAddresses_.length;
    require(
      tokenIdsLength == airdropAddressesLength,
      'tokenIds and airdropAddresses not same length'
    );
    for (uint256 i = 0; i < tokenIdsLength; i++) {
      transferFrom(msg.sender, airdropAddresses_[i], tokenIds_[i]);
    }
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

  function mintAllowlist(
    uint256 quantity_,
    bytes32[] calldata proof_,
    bytes32[] calldata proofOg_
  ) public payable {
    require(
      block.timestamp >= allowlistSaleTime,
      'not allowlist sale time yet'
    );
    require(isAllowlistMintEnabled, 'minting not enabled');
    require(tx.origin == msg.sender, 'contracts not allowed');
    require(msg.value == getPrice(quantity_), 'wrong value');
    require(
      checkAllowlist(proof_) || checkAllowlistOg(proofOg_),
      'address supplied is not on the allowlist'
    );
    require(
      _numberMinted(msg.sender) + quantity_ <= maxPerWalletAllowlist,
      'exceeds max wallet allowlist'
    );
    require(totalSupply() < maxSupply, 'sold out');
    require(totalSupply() + quantity_ <= maxSupply, 'exceeds max supply');
    require(quantity_ <= maxPerTxnAllowlist, 'exceeds max per txn');

    _safeMint(msg.sender, quantity_);
  }

  function mintAllowlistOg(uint256 quantity_, bytes32[] calldata ogProof_)
    public
    payable
  {
    require(
      block.timestamp >= allowlistOgSaleTime,
      'not allowlist og sale time yet'
    );
    require(isAllowlistOgMintEnabled, 'minting not enabled');
    require(tx.origin == msg.sender, 'contracts not allowed');
    require(msg.value == getPrice(quantity_), 'wrong value');
    require(
      checkAllowlistOg(ogProof_),
      'address supplied is not on the OG allowlist'
    );
    require(
      _numberMinted(msg.sender) + quantity_ <= maxPerWalletAllowlistOg,
      'exceeds max wallet allowlist og'
    );
    require(totalSupply() < maxSupply, 'sold out');
    require(totalSupply() + quantity_ <= maxSupply, 'exceeds max supply');
    require(quantity_ <= maxPerTxnAllowlistOg, 'exceeds max per txn');

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

  function checkAllowlistOg(bytes32[] calldata proof_)
    public
    view
    returns (bool)
  {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    return MerkleProof.verify(proof_, merkleRootOg, leaf);
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
    uint256 tokenIdsLength = tokenIds_.length;
    for (uint256 i = 0; i < tokenIdsLength; i++) {
      safeTransferFrom(from_, to_, tokenIds_[i], data_);
    }
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return _ownershipOf(tokenId);
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
        abi.encodePacked(baseTokenUri, _toString(tokenId_), baseTokenUriExt)
      );
  }

  /**
   * @dev Returns an array of token IDs owned by `owner`.
   *
   * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
   * It is meant to be called off-chain.
   *
   * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
   * multiple smaller scans if the collection is large enough to cause
   * an out-of-gas error (10K collections should be fine).
   */
  function tokensOfOwner(address owner_)
    external
    view
    virtual
    returns (uint256[] memory)
  {
    unchecked {
      uint256 tokenIdsIdx;
      address currOwnershipAddr;
      uint256 tokenIdsLength = balanceOf(owner_);
      uint256[] memory tokenIds = new uint256[](tokenIdsLength);
      TokenOwnership memory ownership;
      for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
        ownership = _ownershipAt(i);
        if (ownership.burned) {
          continue;
        }
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == owner_) {
          tokenIds[tokenIdsIdx++] = i;
        }
      }
      return tokenIds;
    }
  }
}