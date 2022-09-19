//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NNFTv2 is OwnableUpgradeable, ERC721URIStorageUpgradeable, EIP712Upgradeable, UUPSUpgradeable {

  string private constant SIGNING_DOMAIN = "NNFT-Voucher";
  string private constant SIGNATURE_VERSION = "1";
  address minter;
  uint256[50] __gap;

 function initialize(

    address _minter

    ) public initializer  {
        
        
        __Ownable_init();
        __ERC721_init("Nuts-NFT", "NNFT");
        __ERC721URIStorage_init(); 
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        minter = _minter;

    }



    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}


  /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
  struct NFTVoucher {

    /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
    uint256 tokenId;

    /// @notice The address which sign the voucher at the first time.
    address recipient;
    /// @notice The metadata URI to associate with this token.
    string uri;

     /// @notice The level of this token.
    string level;
    
    /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
    bytes signature;
  }

  ///@dev the lock status of NFT 
  struct NFTstatus{

    uint256 tokenId;
    bool locked;
    string level;

  }
  
  event lockStatus(uint256 tokenId, bool locked);
  mapping (uint256 => NFTstatus) public nftStatus;

  /// @notice The balance of different level of RNFT of the address
  mapping (address => uint256) public SRbalance;
  mapping (address => uint256) public Rbalance;
  mapping (address => uint256) public Nbalance;


     function checkSR(address holder) public view returns(uint256){
      return SRbalance[holder];
    
  }
  /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
  /// @param redeemer The address of the account which will receive the NFT upon success.
  /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.



  function redeem(address redeemer, NFTVoucher calldata voucher) public returns (uint256) {

    // make sure signature is valid and get the address of the signer
    address signer = _verify(voucher);
    
    // make sure that the signer is authorized to mint NFTs
    require(signer == minter, "Signature invalid or unauthorized");

    // make sure that the redeemer is paying enough to cover the buyer's cost
    require(msg.sender == voucher.recipient, "address unauthorized");

    // first assign the token to the signer, to establish provenance on-chain
    _mint(signer, voucher.tokenId);
    _setTokenURI(voucher.tokenId, voucher.uri);
    
    NFTstatus storage status = nftStatus[voucher.tokenId];
    status.tokenId = voucher.tokenId;
    status.locked = true;
    status.level = voucher.level;
    if (keccak256(abi.encodePacked("SR")) == keccak256(abi.encodePacked(voucher.level))){
      SRbalance[redeemer] += 1;
    }
    else if (keccak256(abi.encodePacked("R")) == keccak256(abi.encodePacked(voucher.level))){
      Rbalance[redeemer] += 1;
    }
    else if (keccak256(abi.encodePacked("N")) == keccak256(abi.encodePacked(voucher.level))){
      Nbalance[redeemer] += 1;
    }
    else {
      revert();
    }
    // transfer the token to the redeemer
    _transfer(signer, redeemer, voucher.tokenId);

    return voucher.tokenId;
  }
    


  function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public override {
      
      require(nftStatus[id].locked == false, "NFT locked");
      NFTstatus storage status = nftStatus[id];
      if (keccak256(abi.encodePacked("SR")) == keccak256(abi.encodePacked(status.level))){
        SRbalance[to] += 1;
        SRbalance[from] -= 1;
      }
      else if (keccak256(abi.encodePacked("R")) == keccak256(abi.encodePacked(status.level))){
        Rbalance[to] += 1;
        Rbalance[from] -= 1;
      }
      else if (keccak256(abi.encodePacked("N")) == keccak256(abi.encodePacked(status.level))){
        Nbalance[to] += 1;
        Nbalance[from] -= 1;
      }
        super.safeTransferFrom(from, to, id, data);
  }


  function transferFrom(address from, address to, uint256 id) public override {

    require(nftStatus[id].locked == false, "NFT locked");
    NFTstatus storage status = nftStatus[id];
    if (keccak256(abi.encodePacked("SR")) == keccak256(abi.encodePacked(status.level))){
      SRbalance[to] += 1;
      SRbalance[from] -= 1;
    }
    else if (keccak256(abi.encodePacked("R")) == keccak256(abi.encodePacked(status.level))){
      Rbalance[to] += 1;
      Rbalance[from] -= 1;
    }
    else if (keccak256(abi.encodePacked("N")) == keccak256(abi.encodePacked(status.level))){
      Nbalance[to] += 1;
      Nbalance[from] -= 1;
    }
      super.transferFrom(from, to, id);
   }
  

  // burn the token by admin
  function burn(uint256 tokenId) public onlyOwner{
    address owner = ownerOf(tokenId);
    NFTstatus storage status = nftStatus[tokenId];
    if (keccak256(abi.encodePacked("SR")) == keccak256(abi.encodePacked(status.level))){
 
      SRbalance[owner] -= 1;
    }
    else if (keccak256(abi.encodePacked("R")) == keccak256(abi.encodePacked(status.level))){
  
      Rbalance[owner] -= 1;
    }
    else if (keccak256(abi.encodePacked("N")) == keccak256(abi.encodePacked(status.level))){
 
      Nbalance[owner] -= 1;
    }
    status.level = "";
    status.locked =true;

    _burn(tokenId);
        }
  


  // unlock the NFT to transfer
  function unlock(uint256 tokenId) onlyOwner public{
    _exists(tokenId);
    NFTstatus storage status = nftStatus[tokenId];
    status.locked = false;
    emit lockStatus(tokenId,status.locked);
  }

  function unlockBatch(uint256[] memory IdBatch) onlyOwner public{
    for(uint i = 0; i < IdBatch.length; i++){ 
        _exists(IdBatch[i]);
        NFTstatus storage status = nftStatus[IdBatch[i]];
        status.locked = false;
        emit lockStatus(IdBatch[i],status.locked);
      }
  }

  function lockBatch(uint256[] memory IdBatch) onlyOwner public{
    for(uint i = 0; i < IdBatch.length; i++){ 
        _exists(IdBatch[i]);
        NFTstatus storage status = nftStatus[IdBatch[i]];
        status.locked = true;
        emit lockStatus(IdBatch[i],status.locked);
      }
  }

  // lock the NFT 
    function lock(uint256 tokenId) onlyOwner public{
    _exists(tokenId);
    NFTstatus storage status = nftStatus[tokenId];
    status.locked = true;
    emit lockStatus(tokenId,status.locked);
  }


  /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
  /// @param voucher An NFTVoucher to hash.
  function _hash(NFTVoucher calldata voucher) public view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("NFTVoucher(uint256 tokenId,address recipient,string uri,string level)"),
      voucher.tokenId,
      voucher.recipient,
      keccak256(bytes(voucher.uri)),
      keccak256(bytes(voucher.level))
    )));
  }

  /// @notice Returns the chain id of the current blockchain.
  /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
  ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
  function getChainID() external view returns (uint256) {
    uint256 id;
    assembly {
        id := chainid()
    }
    return id;
  }

  /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
  /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
  /// @param voucher An NFTVoucher describing an unminted NFT.
  function _verify(NFTVoucher calldata voucher) public view returns (address) {
    bytes32 digest = _hash(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }


  // function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (bool) {
  //   return ERC721Upgradeable.supportsInterface(interfaceId) || ERC721URIStorageUpgradeable.supportsInterface(interfaceId);
  // }


}