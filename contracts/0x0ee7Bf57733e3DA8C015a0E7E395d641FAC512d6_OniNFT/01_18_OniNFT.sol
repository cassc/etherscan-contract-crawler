// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

contract OniNFT is ERC721URIStorage, ERC721Pausable, ERC721Enumerable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public MAX_ELEMENTS = 275;
    uint256 public PRICE = 0.0666 ether;
    uint256 public MAX_BY_MINT = 1;

    address public creatorAddress;
    string public baseTokenURI;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    event CreateOni(uint256 indexed id);

    constructor(string memory _baseURI, address _creatorAddress) ERC721("Oni Squad", "OS") {
        creatorAddress = _creatorAddress;
        baseTokenURI = _baseURI;

        for (uint256 i = 0; i < 75; i++) {
            _mintAnElement(_creatorAddress);
        }
        
        _pause();
    }

    function setMAX_ELEMENTS(uint256 _maxElements) external onlyOwner {
        require(
            _maxElements < 6667,
            "You can't set the MAX ELEMENTS to be over 6666."
        );
        MAX_ELEMENTS = _maxElements;
    }

    function setMAX_BY_MINT(uint256 _maxByMint) external onlyOwner {
        require(
            _maxByMint <= 3 && _maxByMint > 0,
            "You can't set the MAX BY MINT to be over MAX_BY_MINT."
        );
        MAX_BY_MINT = _maxByMint;
    }

    function setPRICE(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(uint256 _numTokensToMint) public payable {
        uint256 total = _totalSupply();
        require(total + _numTokensToMint <= MAX_ELEMENTS, "Max limit");
        require(
            balanceOf(msg.sender) + _numTokensToMint <= MAX_BY_MINT,
            "Can't mint more than MAX_BY_MINT NFTs to this address"
        );
        require(total <= MAX_ELEMENTS, "This sale has ended");
        require(
            msg.value >= price(_numTokensToMint),
            "Value paid is below price"
        );

        for (uint256 i = 0; i < _numTokensToMint; i++) {
            _mintAnElement(msg.sender);
        }
    }

    function _mintAnElement(address _to) private {
        uint256 id = _totalSupply() + 1;
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateOni(id);
    }

    function price(uint256 _count) public view returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function pause() public onlyOwner {
        _pause();
        return;
    }

    function unpause() public onlyOwner {
        _unpause();
        return;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // function withdrawAll() public payable onlyOwner {
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(creatorAddress, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        revert("Don't burn your ONI");
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    modifier onlyOwner() {
        require(
            msg.sender == creatorAddress,
            "Only owner can perform this action"
        );
        _;
    }
}