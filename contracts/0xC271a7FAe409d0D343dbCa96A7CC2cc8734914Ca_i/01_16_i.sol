// SPDX-License-Identifier: No License
// Copyright 404.zero x Han, 2022

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract i is ERC721, ERC721Enumerable, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public constant MANIFEST = (
        '  i i i i i i i i i i i i i i i i i i i i i i i i i i' '\n'
        'i i i   i   i i i i i i i i i i i i i i i i i i i i i' '\n'
        'i i i i i   i i i i i i i i i i i i i   i i i i i i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i i i i i i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i i i i i i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i i i i i i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i i i i i i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i i i i i i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i i i i i i i' '\n'
        'i i i i i i i i i i i i             i i i i i i i i i' '\n'
        'i i i i i i i i i i i i             i i i i i i i i i' '\n'
        'i i i i i i i i i i i i             i i i i i   i i i' '\n'
        'i i i i i i i i i i i i             i i i i i i i i i' '\n'
        'i i i i i i i i i i i i             i i i i i i i i i' '\n'
        'i i i i i i i i i i i i             i i i i i i i i i' '\n'
        'i i i i i     i i i     i i i i i i i i i i i i i i i' '\n'
        'i i i i i i i i i i     i i i i i i i i i i i i i i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i i i i i i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i i i i i i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i i i i i i i' '\n'
        'i i i i i i i   i i i   i i i   i i i   i       i i i' '\n'
        'i i i i i i i   i i i   i i i   i i i   i       i i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i         i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i       i i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i i i i i i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i i i i i i i' '\n'
        'i i i i i i i i i i i i i i i i i i i i i i i i i i i' '\n'
    );

    struct Params {
        uint8 brightness;
        uint8 frequency;
        uint8 amplitude;
    }

    struct Coords {
        int32 latitude;
        int32 longitude;
        int32 altitude;
    }

    uint256 public constant MAX_SUPPLY = 660;
    uint256 public constant PRESALE_MINT_PRICE = 1 ether;
    uint256 public constant PUBLIC_SALE_MINT_PRICE = 2 ether;

    string public baseURI;
    string public baseJS;

    mapping(uint256 => Params) public params;
    mapping(uint256 => Coords) public coords;

    bool public presaleOpen;
    bool public publicSaleOpen;

    mapping(address => uint256) public presaleList;

    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this token");
        _;
    }

    modifier validParamValue(uint8 value) {
        require(value >= 0 && value <= 100, "Value should be greater than 0 and less than 100");
        _;
    }

    event TweakParam(uint256 indexed tokenId, string paramName, uint8 newValue);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }

    function mintPresale() public payable nonReentrant {
        uint256 tokenId = totalSupply();

        require(presaleOpen, "Sale is not active");
        require(tokenId < MAX_SUPPLY, "Purchase would exceed max supply");
        require(presaleList[msg.sender] > 0, "Exceeded max available to purchase");
        require(msg.value >= PRESALE_MINT_PRICE, "Ether value is too small");

        _safeMint(msg.sender, tokenId);
        _synthesizeParams(block.number, tokenId);

        presaleList[msg.sender]--;
    }

    function mintPublicSale() public payable nonReentrant {
        uint256 tokenId = totalSupply();

        require(publicSaleOpen, "Sale is not active");
        require(tokenId < MAX_SUPPLY, "Purchase would exceed max supply");
        require(msg.value >= PUBLIC_SALE_MINT_PRICE, "Ether value is too small");
        require(msg.sender == tx.origin, "Purchase is forbidden");

        _safeMint(msg.sender, tokenId);
        _synthesizeParams(block.number, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function tokenHTML(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        bytes memory liveJS = abi.encodePacked(
            'live({'
                'brightness:', uint256(params[tokenId].brightness).toString(), ','
                'frequency:', uint256(params[tokenId].frequency).toString(), ','
                'amplitude:', uint256(params[tokenId].amplitude).toString(), ','
            '});'
        );

        return string(abi.encodePacked(
            '<!DOCTYPE html>'
            '<html>'
                '<head>'
                    '<title>', 'i#', tokenId.toString(), '</title>'
                '</head>'

                '<body style="background:#000;margin:0;padding:0;overflow:hidden;">'
                    '<script type="application/javascript">', baseJS, liveJS,'</script>'
                '</body>'
            '</html>'

            '\n'
            '<!--'
            '\n', MANIFEST,
            '-->'
            '\n'
        ));
    }

    function tweakBrightness(uint256 tokenId, uint8 newValue) public onlyTokenOwner(tokenId) validParamValue(newValue) {
        params[tokenId].brightness = newValue;

        emit TweakParam(tokenId, 'brightness', newValue);
    }

    function tweakAmplitude(uint256 tokenId, uint8 newValue) public onlyTokenOwner(tokenId) validParamValue(newValue) {
        params[tokenId].amplitude = newValue;

        emit TweakParam(tokenId, 'amplitude', newValue);
    }

    function tweakFrequency(uint256 tokenId, uint8 newValue) public onlyTokenOwner(tokenId) validParamValue(newValue) {
        params[tokenId].frequency = newValue;

        emit TweakParam(tokenId, 'frequency', newValue);
    }

    function setBaseURI(string calldata newValue) public onlyOwner {
        baseURI = newValue;
    }

    function setBaseJS(string calldata newValue) public onlyOwner {
        baseJS = newValue;
    }

    function setCoords(uint256[] calldata tokenIds, Coords[] calldata coordsData) public onlyOwner {
        for (uint256 k = 0; k < tokenIds.length; k++) {
            coords[tokenIds[k]] = coordsData[k];
        }
    }

    function setPresaleList(address[] calldata addresses, uint256[] calldata remainings) public onlyOwner {
        for (uint256 k = 0; k < addresses.length; k++) {
            presaleList[addresses[k]] = remainings[k];
        }
    }

    function setRoyalty(address recipient, uint96 fraction) public onlyOwner {
        _setDefaultRoyalty(recipient, fraction);
    }

    function lfgPresale(bool open) public onlyOwner {
        presaleOpen = open;
    }

    function lfgPublicSale(bool open) public onlyOwner {
        publicSaleOpen = open;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        require(success, "Failed to transfer the funds");
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _synthesizeParams(uint256 blockNumber, uint256 tokenId) private {
        params[tokenId] = Params({
            brightness: uint8((((blockNumber + (tokenId * 13)) % (24 + (tokenId * 7)) % 51) + 50) % 101),
            frequency: uint8((blockNumber + (tokenId * 33)) % (31 + (tokenId * 17)) % 101),
            amplitude: uint8((((blockNumber + (tokenId * 11)) % (19 + (tokenId * 3)) % 51) + 50) % 101)
        });
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}