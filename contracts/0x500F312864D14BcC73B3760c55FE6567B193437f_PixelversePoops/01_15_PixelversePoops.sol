// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

interface IShitPlunger {
    function burn(address who, uint32 amount) external;
}

contract PixelversePoops is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    IERC721 public immutable _shit;
    IShitPlunger public immutable _shitPlunger;

    uint32 public immutable _smashLimit = 5;
    uint32 public immutable _maxSupply = 8888;

    bool public _started;
    string public _metadataURI = "https://lambda.pieceofshit.wtf/pixelverse-poops/metadata/";
    mapping(uint32 => uint32) public _smashTimes;

    constructor(address shit, address shitPlunger) ERC721A("PixelversePoops", "PP") {
        _shit = IERC721(shit);
        _shitPlunger = IShitPlunger(shitPlunger);
        setFeeNumerator(750);
    }

    function smash(uint32[] memory poopIds, uint32[] memory smashTimes) external {
        require(_started, "PixelversePoops: Not Started");
        require(poopIds.length == smashTimes.length, "PixelversePoops: Tokens and times not match");

        uint32 totalSmash = 0;
        for (uint i = 0; i < smashTimes.length; ) {
            require(_shit.ownerOf(poopIds[i]) == msg.sender, "PixelversePoops: You need to smash your own poops");
            totalSmash += smashTimes[i];
            _smashTimes[poopIds[i]] += smashTimes[i];
            require(_smashTimes[poopIds[i]] <= _smashLimit, "PixelversePoops: Exceed smash times limit");
            unchecked { i++; }
        }

        require(totalSmash + _totalMinted() <= _maxSupply, "PixelversePoops: Exceed max supply");
        require(totalSmash > 0, "PixelversePoops: Smash something plz");
        _shitPlunger.burn(msg.sender, totalSmash);

        _safeMint(msg.sender, totalSmash);
    }

    function batchGetSmashTimes(uint32[] memory poopIds) external view returns (uint32[] memory) {
        uint32[] memory times = new uint32[](poopIds.length);
        for (uint i = 0; i < poopIds.length; i++) times[i] = _smashTimes[poopIds[i]];
        return times;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }
}