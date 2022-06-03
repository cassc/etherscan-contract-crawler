//SPDX-License-Identifier: MIT
// Deploy & code customizations by chmaro.eth

pragma solidity ^0.8.4;
pragma abicoder v2; // required to accept structs as function parameters

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract GodsOfTheSea is ERC721URIStorage, EIP712, AccessControl, Ownable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  string private constant SIGNING_DOMAIN = "GodsOfTheSea";
  string private constant SIGNATURE_VERSION = "1";
  mapping (address => uint) private whitelistedAddrs;
  string public baseUri;
  string public contractURI;
  bool public vouchersEnabled = true;

  constructor(address payable minter)
    ERC721("Gods of the Sea", "GotS")
    EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
      _setupRole(MINTER_ROLE, minter);
    }

  /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
  struct NFTVoucher {
    /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
    uint256 tokenId;
    address recipient;

    /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
    bytes signature;
  }


  /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
  /// @param redeemer The address of the account which will receive the NFT upon success.
  /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
  function redeem(address redeemer, NFTVoucher calldata voucher) public payable returns (uint256) {
    require(vouchersEnabled, "Voucher redeem is disabled");
    // make sure signature is valid and get the address of the signer
    address signer = _verify(voucher);
    // make sure that the signer is authorized to mint NFTs
    require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");
    require(voucher.recipient == msg.sender, "Voucher is for different caller");


    // first assign the token to the signer, to establish provenance on-chain
    _mint(redeemer, voucher.tokenId);

    return voucher.tokenId;
  }


  /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
  /// @param voucher An NFTVoucher to hash.
  function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("NFTVoucher(uint256 tokenId,address recipient)"),
      voucher.tokenId,
      voucher.recipient
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

  function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl, ERC721) returns (bool) {
    return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
  }

  function _baseURI() internal view override returns (string memory) {
      return baseUri;
  }

  function setBaseURI(string calldata _uri) public onlyOwner returns (string calldata) {
    baseUri = _uri;
    return _uri;
  }

  function setContractURI(string calldata _uri) public onlyOwner returns (string calldata) {
    contractURI = _uri;
    return _uri;
  }

  function setVouchersEnabled(bool _flag) public onlyOwner {
    vouchersEnabled = _flag;
  }

  function batchMint(uint256 [] calldata tokenIds, address [] calldata recipients) public onlyOwner {
    require(tokenIds.length == recipients.length, "tokenIds size and recipient size do not match");

    for(uint i = 0; i < tokenIds.length; i++) {
      _mint(recipients[i], tokenIds[i]);
    }
  }

  function batchAddWhitelist(address [] calldata recipients, uint [] calldata amount) public onlyOwner {
    require(amount.length == recipients.length, "amount size and recipient size do not match");

    for(uint i = 0; i < recipients.length; i++) {
      whitelistedAddrs[recipients[i]] = amount[i];
    }
  }

  function whitelistMint(uint256 [] calldata tokenIds) public {
    require(tokenIds.length > 0, "mint at least one");
    require(whitelistedAddrs[msg.sender] >= tokenIds.length, "not whitelsited");

    for(uint8 i = 0; i < tokenIds.length; i++) {
      _mint(msg.sender, tokenIds[i]);
    }

    whitelistedAddrs[msg.sender] = whitelistedAddrs[msg.sender] - tokenIds.length;
  }
}