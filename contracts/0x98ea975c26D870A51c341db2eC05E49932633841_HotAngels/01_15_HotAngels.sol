// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HotAngels is ERC721, ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant MINT_PRICE = 0.0035 ether;
    uint256 constant TOTAL_SUPPLY = 1222;
    uint256 public constant WHITELIST_DURATION = 1800; // 30 minutes in seconds

    uint256 public saleStartTimestamp;

    string private _baseUri;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) private mintedPerWallet;

    constructor() ERC721("Hot Angels", "HotAngel") {
        _pause();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function mint(address to, uint256 nftToMint) public payable whenNotPaused {
        if (isWhitelistActive()) {
            require(
                isWhitelisted(to),
                "You are not whitelisted to participate in the whitelist sale"
            );
            require(
                mintedPerWallet[to] + nftToMint <= 3 && nftToMint > 0,
                "Incorrect amount to mint"
            );
        } else {
            require(
                mintedPerWallet[to] + nftToMint <= 5 && nftToMint > 0,
                "Incorrect amount to mint"
            );
        }

        require(
            msg.value >= MINT_PRICE * nftToMint,
            "Not enough ETH sent: check price."
        );

        for (uint256 i; i < nftToMint; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            require(tokenId <= TOTAL_SUPPLY - 1, "Exceeds token supply");

            string memory uri = string.concat(
                Strings.toString(tokenId),
                ".json"
            );
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uri);
        }
        mintedPerWallet[msg.sender] += nftToMint;
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) whenNotPaused {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function addToWhitelist(
        address[] calldata toAddAddresses
    ) external onlyOwner {
        for (uint i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
        }
    }

    function removeFromWhitelist(
        address[] calldata toRemoveAddresses
    ) external onlyOwner {
        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
        }
    }

    function isWhitelisted(address userAddress) public view returns (bool) {
        return whitelist[userAddress];
    }

    function restartWhitelist() public onlyOwner {
        saleStartTimestamp = block.timestamp;
    }

    function startSale() public onlyOwner {
        if (saleStartTimestamp == 0) {
            restartWhitelist();
        }
        _unpause();
    }

    function pauseSale() public onlyOwner whenNotPaused {
        _pause();
    }

    function pauseAndReset() public onlyOwner whenNotPaused {
        saleStartTimestamp = 0;
        _pause();
    }

    function isWhitelistActive() public view returns (bool) {
        return (block.timestamp < saleStartTimestamp + WHITELIST_DURATION);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function tokensMinted() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getMintPrice() external pure returns (uint256) {
        return MINT_PRICE;
    }

    function setBaseUri(string memory uri) external onlyOwner {
        _baseUri = uri;
    }

    // Functions to receive Ether
    receive() external payable {}

    fallback() external payable {}
}