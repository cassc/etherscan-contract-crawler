//SPDX-License-Identifier: NONE
pragma solidity 0.8.17;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";


contract Paladin is ERC721URIStorage, EIP712, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private constant SIGNING_DOMAIN = "Paladin-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    uint256 public tokenIds;
    address public burnAddress= 0x951E0E875E6410Aa62110bdA2d8FadDdf78C7C11;
    address public t1 = 0x951E0E875E6410Aa62110bdA2d8FadDdf78C7C11;
    address public t2 = 0xA7de0063e7197009c4E67a4356A70d6473bD0589;
   
   constructor(address payable minter)ERC721("Paladin", "PLA") EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION){
        _setupRole(MINTER_ROLE, minter);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    struct NFTVoucher {
        uint256 nonce;
        uint256 minPrice;
        string uri;
        bytes signature;
    }

    mapping(string => bool) public tokenURIExists;

    function safeMint(address redeemer, NFTVoucher calldata voucher) public payable returns (uint256){
        address signer = _verify(voucher);
        require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");
        require(!tokenURIExists[voucher.uri], "token URI already exists");
        tokenIds ++;
        _safeMint(signer, tokenIds);
        _setTokenURI(tokenIds , voucher.uri);
        _safeTransfer(signer, redeemer, tokenIds, bytes(voucher.uri));
        tokenURIExists[voucher.uri] = true;
        return tokenIds;
    }


    function setBurnAddress(address newBurnAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        burnAddress = newBurnAddress;
    }


    function _burn(uint256 tokenId) internal override(ERC721URIStorage) {
        safeTransferFrom(msg.sender, burnAddress, tokenId);
    }


    function burn(uint256 tokenId, NFTVoucher calldata voucher) public payable virtual {
        require((ownerOf(tokenId) == msg.sender), "caller is not owner");
        address signer = _verify(voucher);
        require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");
        payable(address(t1)).transfer(voucher.minPrice);
        _burn(tokenId);
    }


    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("NFTVoucher(uint256 nonce,uint256 minPrice,string uri)"),
        voucher.nonce,
        voucher.minPrice,
        keccak256(bytes(voucher.uri))
        )));
    }


    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl, ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
    

    function withdraw() public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(address(t2)).transfer(address(this).balance);
    }
}