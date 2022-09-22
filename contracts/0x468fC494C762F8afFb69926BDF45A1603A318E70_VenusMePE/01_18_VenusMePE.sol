//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------------------------------------------------------
// This is the only contract file we added on top of
// standard contracts by openzeppelin
// ------------------------------------------------------------
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract VenusMePE is ERC721, ERC721Royalty, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // 555 NFTS available on Ethereum blockchain.
    uint256 public constant MAX_SUPPLY = 555;

    // We Reserve tokens to reward people who supported us
    uint256 public constant RESERVED_TOKENS = 10;

    // Price initially set to 5.5 ETH (around 5.555€ at time of deployment)
    uint256 public price = 5.5 ether;

    // Base address for the metadata
    bool public lockedBaseTokenUri = false;
    string public baseTokenURI;

    // Addresses for withdrawals
    bool public lockedAddressCharity = false;
    address public addressCharity;
    address public addressJuanjo;
    address public addressTokomo;

    constructor(string memory baseURI) ERC721("VenusMePE", "VenusMePE") {
        setBaseURI(baseURI);

        // Set royalty of all NFTs to 10%
        _setDefaultRoyalty(address(this), 1000);
    }

    // Reserve NFTs
    function reserveNFTs() public onlyOwner {
        uint256 totalMinted = _tokenIds.current();

        require(
            totalMinted.add(RESERVED_TOKENS) < MAX_SUPPLY,
            "Not enough NFTs left to reserve"
        );

        for (uint256 i = 0; i < RESERVED_TOKENS; i++) {
            _mintSingleNFT();
        }
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Set new baseTokenUri as long it is not locked
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        require(!lockedBaseTokenUri, "baseTokenURI is already locked.");
        baseTokenURI = _baseTokenURI;
    }

    // Lock baseTokenUri ::: no change possible after calling this
    function lockBaseTokenUri() public onlyOwner {
        lockedBaseTokenUri = true;
    }

    // Set new addressCharity as long it is not locked
    // ------------------------------------------------------------
    // We need to be flexible until The Giving Block team has verified
    // the donation address on twitter. Once this is done, we will lock
    // the variable via "lockAddressCharity" function.
    function setAddressCharity(address _addressCharity) public onlyOwner {
        require(!lockedAddressCharity, "addressCharity is already locked.");
        addressCharity = _addressCharity;
    }

    // Lock addressCharity ::: no return possible after calling this
    // ------------------------------------------------------------
    // With this function we lock in the charity address.
    // Once the variable "lockedAddressCharity" is set to true,
    // we cannot use the "setAddressCharity" function anymore
    // to set the variable "addressCharity" other than the address
    // that is verified by The Giving Blocks team on twitter.
    function lockAddressCharity() public onlyOwner {
        lockedAddressCharity = true;
    }

    // Set a different price in case ETH changes drastically
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    // The function to mint NFTs
    function mintNFTs(uint256 _count) public payable {
        uint256 totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(
            msg.value >= price.mul(_count),
            "Not enough funds to purchase NFTs."
        );

        for (uint256 i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    // Mint NFT and increment the tokenId
    function _mintSingleNFT() private {
        uint256 newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    // Set team addresses to stay flexible
    function setAddresses(address[] memory _a) public onlyOwner {
        addressTokomo = _a[0];
        addressJuanjo = _a[1];
    }

    // Withdraw funds
    // ------------------------------------------------------------
    // By reviewing this publicly transparent and unchangable smart contract,
    // everyone able to read read a smart contract, can verify that this is the only
    // function to withdraw the funds.
    // Once the "addressCharity" is locked and the address is verified by
    // The Giving Block's team, this guarantees in a trustless manner,
    // that we cannot do anything else with the funds than donate 95% percent
    // with each withdrawal.
    // ------------------------------------------------------------
    // Follow @VenusMe14 on twitter or visit https://venusme.love for more info
    // and updates!
    function withdraw(uint256 amount) public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds left to withdraw");

        uint256 percent = amount / 100;
        require(payable(addressCharity).send(percent * 95)); // 95% for charity
        require(payable(addressJuanjo).send((percent * 5) / 2)); // 2,5% for juanjo
        require(payable(addressTokomo).send((percent * 5) / 2)); // 2,5% for tokomo
    }

    // ------------------------------------------------------------
    // The following functions are overrides required by Solidity.
    // ------------------------------------------------------------
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Royalty)
    {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
}