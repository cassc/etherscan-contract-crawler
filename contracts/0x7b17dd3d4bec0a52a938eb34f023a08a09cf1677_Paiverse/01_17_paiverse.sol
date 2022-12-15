//SPDX-License-Identifier: NONE
pragma solidity 0.8.17;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract Paiverse is ERC721URIStorage, EIP712, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private constant SIGNING_DOMAIN = "Paiverse-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    address public t1 = 0xA7de0063e7197009c4E67a4356A70d6473bD0589;
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor(address payable minter)ERC721("Paiverse - Infinite Possibilities", "PAI") EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION){
        _setupRole(MINTER_ROLE, minter);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    struct NFTVoucher {
        uint256 nonce;
        uint256 minPrice;
        address buyer;
        string uri;
        bytes signature;
    }

    mapping(string => bool) public tokenURIExists;

    function safeMint(address redeemer, NFTVoucher calldata voucher) public payable {
        address signer = _verify(voucher);
        require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");
        require(!tokenURIExists[voucher.uri], "token URI already exists");
        _tokenIdCounter.increment();
        _safeMint(signer, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current() , voucher.uri);
        _safeTransfer(signer, redeemer, _tokenIdCounter.current(), bytes(voucher.uri));
        tokenURIExists[voucher.uri] = true;
        payable(address(t1)).transfer(msg.value);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function burn(uint256 tokenId, NFTVoucher calldata voucher) public payable virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
        address signer = _verify(voucher);
        require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");
        payable(address(t1)).transfer(voucher.minPrice);
        _burn(tokenId);
    }

    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("NFTVoucher(uint256 nonce,uint256 minPrice,address buyer,string uri)"),
        voucher.nonce,
        voucher.minPrice,
        voucher.buyer,
        keccak256(bytes(voucher.uri))
        )));
    }

    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool){
    return super.supportsInterface(interfaceId);
    } 
}