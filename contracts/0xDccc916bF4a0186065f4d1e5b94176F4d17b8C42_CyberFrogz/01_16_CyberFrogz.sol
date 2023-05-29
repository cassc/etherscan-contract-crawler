/*
 /$$$$$$$$                                /$$$$$$                  /$$           /$$   /$$ /$$$$$$$$ /$$$$$$$$
|_____ $$                                /$$__  $$                | $$          | $$$ | $$| $$_____/|__  $$__/
     /$$/   /$$$$$$   /$$$$$$   /$$$$$$ | $$  \__/  /$$$$$$   /$$$$$$$  /$$$$$$ | $$$$| $$| $$         | $$
    /$$/   /$$__  $$ /$$__  $$ /$$__  $$| $$       /$$__  $$ /$$__  $$ /$$__  $$| $$ $$ $$| $$$$$      | $$
   /$$/   | $$$$$$$$| $$  \__/| $$  \ $$| $$      | $$  \ $$| $$  | $$| $$$$$$$$| $$  $$$$| $$__/      | $$
  /$$/    | $$_____/| $$      | $$  | $$| $$    $$| $$  | $$| $$  | $$| $$_____/| $$\  $$$| $$         | $$
 /$$$$$$$$|  $$$$$$$| $$      |  $$$$$$/|  $$$$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$ \  $$| $$         | $$
|________/ \_______/|__/       \______/  \______/  \______/  \_______/ \_______/|__/  \__/|__/         |__/

Drop Your NFT Collection With ZERO Coding Skills at https://zerocodenft.com
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract CyberFrogz is ERC721, EIP712, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    enum SaleStatus {
		PAUSED,
		PRESALE,
		PUBLIC
	}

    Counters.Counter private _tokenIds;

    uint public constant COLLECTION_SIZE = 5555;
    uint public constant MINT_PRICE = 0.1 ether;
    uint public constant PRESALE_MINT_PRICE = 0.1 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    bool public canReveal = false;
    
    string private _placeholderUri;
    string private _baseUri;
    address private immutable _txSigner;
    mapping(address => uint) private _mintedCount;
    mapping(address => uint) private _whitelistMintedCount;

    constructor(string memory placeholderUri, address txSigner) 
    ERC721("CyberFrogz", "CF")
    EIP712("CyberFrogz", "1")
    {
        _placeholderUri = placeholderUri;
        _txSigner = txSigner;
    }

    /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
    struct NFTVoucher {
        address redeemer;
        bool whitelisted;
        uint256 numberOfTokens;
    }

    function totalSupply() external view returns (uint) {
        return _tokenIds.current();
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function airdrop(address to, uint count) external onlyOwner {
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "Exceeds collection size");
        _mintTokens(to, count);
    }

    /// @notice Set hidden metadata uri
    function setHiddenUri(string memory uri) external onlyOwner {
        _placeholderUri = uri;
    }

    /// @notice Set sales status
	function setSaleStatus(SaleStatus status) external onlyOwner {
		saleStatus = status;
	}

    /// @notice Reveal metadata for all the tokens
    function reveal(string memory baseUri) external onlyOwner {
        require(!canReveal, "Already revealed");
        _baseUri = baseUri;
        canReveal = true;
    }

    /// @notice Get token's URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return canReveal 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : _placeholderUri;
    }

    /// @notice Withdraw's contract's balance to the minter's address
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance");

        payable(owner()).transfer(balance);
    }

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param voucher An NFTVoucher that describes the NFT to be redeemed.
    /// @param signature An EIP712 signature of the voucher, produced by the NFT creator.
    function redeem(NFTVoucher calldata voucher, bytes memory signature) external payable {

        require(_verify(_hash(voucher), signature), "Transaction is not authorized (invalid signature)");
        require(saleStatus != SaleStatus.PAUSED, "Sales are off");
        require(_tokenIds.current() != COLLECTION_SIZE, "All tokens have been minted");
        require(_tokenIds.current() + voucher.numberOfTokens <= COLLECTION_SIZE, "Number of requested tokens will exceed collection size");

        if(saleStatus == SaleStatus.PRESALE) {
            require(voucher.whitelisted, "Presale is only open to whitelisted users");
            require(msg.value >= voucher.numberOfTokens * PRESALE_MINT_PRICE, "Ether value sent is not sufficient");
            require(_whitelistMintedCount[voucher.redeemer] + voucher.numberOfTokens <= 2, "You've already minted all tokens available to you");
            _whitelistMintedCount[voucher.redeemer] += voucher.numberOfTokens;
        }
        else {
            require(msg.value >= voucher.numberOfTokens * MINT_PRICE, "Ether value sent is not sufficient");
            require(_mintedCount[voucher.redeemer] == 0, "You've already minted all tokens available to you");
            _mintedCount[voucher.redeemer] += voucher.numberOfTokens;
        }

        _mintTokens(voucher.redeemer, voucher.numberOfTokens);
    }

    /// @dev perform actual minting of the tokens
    function _mintTokens(address to, uint count) internal {
        for(uint index = 0; index < count; index++) {

            _tokenIds.increment();
            uint newItemId = _tokenIds.current();

            _safeMint(to, newItemId);
        }
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher)
    internal view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFTVoucher(address redeemer,bool whitelisted,uint256 numberOfTokens)"),
            voucher.redeemer,
            voucher.whitelisted,
            voucher.numberOfTokens
        )));
    }

    function _verify(bytes32 digest, bytes memory signature)
    internal view returns (bool)
    {
        return SignatureChecker.isValidSignatureNow(_txSigner, digest, signature);
    }
}