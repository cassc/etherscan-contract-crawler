//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract RNFT is OwnableUpgradeable, ERC721URIStorageUpgradeable, EIP712Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  string private constant SIGNING_DOMAIN = "RNFT-Voucher";
  string private constant SIGNATURE_VERSION = "1";
 

 function initialize(

    address minter

    ) public initializer  {
        
        
        __Ownable_init();
        __ERC721_init("R-NFT", "RNFT");
        __ERC721URIStorage_init(); 
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        _setupRole(MINTER_ROLE, minter);

        // TokenCounter = 0;
    }



    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}


  /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
  struct NFTVoucher {
    /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
    uint256 tokenId;

    // /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
    // uint256 minPrice;

/// @notice The address which sign the voucher at the first time.
    address recipient;
    /// @notice The metadata URI to associate with this token.
    string uri;

    /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
    bytes signature;
  }

  ///@dev the lock status of NFT 
  struct NFTstatus{

    uint256 tokenId;
    bool locked;

  }
  
  event lockStatus(uint256 tokenId, bool locked);
  mapping (uint256 => NFTstatus) public nftStatus;

  /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
  /// @param redeemer The address of the account which will receive the NFT upon success.
  /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
  function redeem(address redeemer, NFTVoucher calldata voucher) public returns (uint256) {
    // make sure signature is valid and get the address of the signer
    address signer = _verify(voucher);

    // make sure that the signer is authorized to mint NFTs
    require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");

    // make sure that the redeemer is paying enough to cover the buyer's cost
    require(msg.sender == voucher.recipient, "address unauthorized");

    // first assign the token to the signer, to establish provenance on-chain
    _mint(signer, voucher.tokenId);
    _setTokenURI(voucher.tokenId, voucher.uri);
    NFTstatus storage status = nftStatus[voucher.tokenId];
    status.tokenId = voucher.tokenId;
    status.locked = true;
    // transfer the token to the redeemer
    _transfer(signer, redeemer, voucher.tokenId);

    return voucher.tokenId;
  }
  

  function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public override {
      
      require(nftStatus[id].locked == false, "NFT locked");
      super.safeTransferFrom(from, to, id, data);
  }


  function transferFrom(address from, address to, uint256 id) public override {

    require(nftStatus[id].locked == false, "NFT locked");
      super.transferFrom(from, to, id);
  }
  
  // burn the token by admin
  function burn(uint256 tokenId)
        public onlyOwner{
        _burn(tokenId);
        }
  


  // unlock the NFT to transfer
  function unlock(uint256 tokenId) onlyOwner public{
    NFTstatus storage status = nftStatus[tokenId];
    status.locked = false;
    emit lockStatus(tokenId,status.locked);
  }


  // lock the NFT 
    function lock(uint256 tokenId) onlyOwner public{
    NFTstatus storage status = nftStatus[tokenId];
    status.locked = true;
    emit lockStatus(tokenId,status.locked);
  }


  /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
  /// @param voucher An NFTVoucher to hash.
  function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("NFTVoucher(uint256 tokenId,address recipient,string uri)"),
      voucher.tokenId,
      voucher.recipient,
      keccak256(bytes(voucher.uri))
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
  function _verify(NFTVoucher calldata voucher) internal view returns (address) {
    bytes32 digest = _hash(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }


  function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControlUpgradeable, ERC721Upgradeable) returns (bool) {
    return ERC721Upgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
  }


}