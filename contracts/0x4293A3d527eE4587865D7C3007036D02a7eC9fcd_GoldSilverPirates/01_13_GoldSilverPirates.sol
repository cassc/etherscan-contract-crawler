// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GoldSilverPirates is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    uint256 public maxSupply;
    string private _baseTokenURI = "";
    
    event Mint(
        address indexed _address,
        uint256 _quantity
    );

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseTokenURI_,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        _baseTokenURI = baseTokenURI_;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }
    
    function mintForSelf(uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _mintLoop(msg.sender, _mintAmount);
        emit Mint(msg.sender ,_mintAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
        address currentTokenOwner = ownerOf(currentTokenId);

        if (currentTokenOwner == _owner) {
            ownedTokenIds[ownedTokenIndex] = currentTokenId;

            ownedTokenIndex++;
        }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : "";
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function setBaseURILink(string memory _baseURILink) external onlyOwner {
        _baseTokenURI = _baseURILink;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}