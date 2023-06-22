// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact [email protected]
contract TickleMyPickle is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable,
    ERC721Burnable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _tierAmountCounter;

    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public BATCH_MINT;
    string private _baseTokenURI;

    uint256 public tokenPrice = 0.05 ether;

    mapping(uint256 => uint256) public tierAmount;

    constructor() payable ERC721("Tickle My Pickle", "TMP") {}

    function _baseURI() internal pure override returns (string memory) {
        return
            "ipfs://bafybeih2vgdf4rfizdhe3m6hsvghejkbqkpaesrx75o7w5qucddqwokv7a/";
    }

    function tokenURI(uint256 tokenId)
        public
        pure
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json")
            );
    }

    function setTokenPrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }

    function leftToMint() public view returns (uint256) {
        return BATCH_MINT - totalSupply();
    }

    function setBatchMintAmount(uint256 _newTierSupply) public onlyOwner {
        require(
            BATCH_MINT + _newTierSupply <= MAX_SUPPLY,
            "amount exceeds max supply"
        );
        require(
            totalSupply() + _newTierSupply <= MAX_SUPPLY,
            "amount exceeds max supply"
        );
        tierAmount[_tierAmountCounter.current()] = _newTierSupply;
        BATCH_MINT += _newTierSupply;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    modifier _checkLimits(uint256 amount) {
        require(MAX_SUPPLY > totalSupply(), "Exceeds  mint limit");
        require(
            totalSupply() + amount <= BATCH_MINT,
            "Exceeds batch mint limit"
        );
        _;
    }

    function mint(address to) public payable _checkLimits(1) {
        require(msg.value >= tokenPrice, "Payment not enough");
        _tokenIdCounter.increment();
        _mint(to, _tokenIdCounter.current());
    }

    function mint(address to, uint256 amount)
        public
        payable
        _checkLimits(amount)
    {
        require(msg.value >= tokenPrice, "Payment not enough");
        for (uint256 i = 0; i < amount; i++) {
            _tokenIdCounter.increment();
            _mint(to, _tokenIdCounter.current());
        }
    }

    function safeMint(address to) public _checkLimits(1) onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}