// contracts/HouseToken.sol
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract HouseToken is Ownable, ERC721URIStorage {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    string public baseURI;
    string public uriSuffix;
    string public hiddenMetadataUri;
    bool public revealed;
    address public minter;
    modifier onlyMinter{
        require(msg.sender == minter || msg.sender == owner());
        _;
    }

    constructor() ERC721("HouseToken", "HOUSE") {}

    function mint(address to)
        public
        onlyMinter
        returns (uint256)
    {
        require(to != address(0), "HouseToken: to can't be zero address");
        _tokenIdTracker.increment();
        uint256 newTokenId = _tokenIdTracker.current();
        _mint(to, newTokenId);
        return newTokenId;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(_tokenId);

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
    }

    function setMinter(address _minter) public onlyOwner{
        require(_minter != address(0), "HouseToken: minter can't be zero address");
        minter = _minter;
    }

    function setRevealed(bool _state) public onlyOwner{
        revealed = _state;
    }

    function setBaseURI(string memory uri) public onlyOwner{
        baseURI = uri;
    }

    function setHiddenMetadataUri(string memory uri) public onlyOwner{
        hiddenMetadataUri = uri;
    }

    function setUriSuffix(string memory fix) public onlyOwner{
        uriSuffix = fix;
    }
}