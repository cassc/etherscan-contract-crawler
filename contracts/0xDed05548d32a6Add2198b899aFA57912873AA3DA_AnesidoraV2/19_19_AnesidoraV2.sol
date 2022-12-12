// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;
pragma abicoder v2;
 
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

interface IAnesidora {
  function ownerOf(uint256 tokenId) external view returns (address);
}

contract AnesidoraV2 is AccessControl, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, EIP712{
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  string private constant SIGNING_DOMAIN = "AnesidoraV2-Voucher";
  string private constant SIGNATURE_VERSION = "1";
  uint256 public constant MAX_SUPPLY = 10000;
  address private _tokenContractAddress;
  mapping (address => uint256) pendingWithdrawals;

  constructor(address payable admin,address tokenAddress) ERC721("AnesidoraV2", "ANSDR2") EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
    _setupRole(ADMIN_ROLE, admin);
    _setupRole(MINTER_ROLE, admin);
    _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
    _setTokenContract(tokenAddress);
  }

  struct NFTVoucher {
    uint16 id;
    uint256 minPrice;
    string uri;
    uint64 expiry;
    bool unlock;
    bytes signature;
  }

  function _setTokenContract(address contractAddress) private {
    require(hasRole(MINTER_ROLE, msg.sender), "unauthorized account");
    _tokenContractAddress = contractAddress;
  }
  
  function getTokenContract() public view returns (address) {
    return _tokenContractAddress;
  }

  function ownerOfV1(uint256 id) private view returns (address) {
    IAnesidora iansdr = IAnesidora(_tokenContractAddress);
    return iansdr.ownerOf(id);
  }

  function redeem(address redeemer, NFTVoucher calldata voucher) public payable {
    address signer = _verify(voucher); 
    require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");
    if(voucher.unlock != true){
      require(ownerOfV1(voucher.id) == msg.sender, "Corresponding V1 NFT is required");
    }
    require(block.timestamp < voucher.expiry, "Expired voucher");
    require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");
    require(_ownerOf(voucher.id) == address(0), "Invalid token ID");
    require(totalSupply() < MAX_SUPPLY, "Total supply has reached the MAX_SUPPLY");
    _mint(signer, voucher.id);
    _setTokenURI(voucher.id, voucher.uri);
    _transfer(signer, redeemer, voucher.id);
    pendingWithdrawals[signer] += msg.value;
  }

  function withdraw() public {
    require(hasRole(MINTER_ROLE, msg.sender), "Only an authorized account can withdraw");
    address payable receiver = payable(msg.sender);
    uint amount = pendingWithdrawals[receiver];
    pendingWithdrawals[receiver] = 0;
    receiver.transfer(amount);
  }

  function availableToWithdraw() public view returns (uint256) {
    return pendingWithdrawals[msg.sender];
  }

  function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("NFTVoucher(uint16 id,uint256 minPrice,string uri,uint64 expiry,bool unlock)"),
      voucher.id,
      voucher.minPrice,
      keccak256(bytes(voucher.uri)),
      voucher.expiry,
      voucher.unlock
    )));
  }

  function _verify(NFTVoucher calldata voucher) internal view returns (address) {
    bytes32 digest = _hash(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

}