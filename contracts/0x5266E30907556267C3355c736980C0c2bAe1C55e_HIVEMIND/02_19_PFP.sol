pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./HIVEMIND.sol";
import "./ZeroDay.sol";

contract PFP is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 1000;
    string public constant BASE_URI = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    uint256 public nextTokenIdForHivemind = 1000;
    uint256 public nextTokenIdForZeroDay = 0;

    HIVEMIND private _hivemind;
    ZeroDay private _zeroDay;

    constructor(address hivemindAddress, address zeroDayAddress) ERC721("Personality Fluidity Protocol", "PFP") {
        _hivemind = HIVEMIND(hivemindAddress);
        _zeroDay = ZeroDay(zeroDayAddress);
    }

    function setHivemindAddress(address hivemindAddress) public onlyOwner {
        _hivemind = HIVEMIND(hivemindAddress);
    }

    function setZeroDayAddress(address zeroDayAddress) public onlyOwner {
        _zeroDay = ZeroDay(zeroDayAddress);
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            result[i] = tokenOfOwnerByIndex(owner, i);
        }

        return result;
    }

    function createPFP(uint256[] calldata tokenIds) public {
    require(tokenIds.length == 4, "Incorrect number of HIVEMIND tokens provided");

    uint256 mintStartTimestamp = _hivemind.getMintStartTimestamp();
    require(block.timestamp >= mintStartTimestamp + 30 days, "It is not time for the fusion yet.");

    // Check the ownership of all tokens before burning
    for (uint256 i = 0; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];
        require(_hivemind.ownerOf(tokenId) == msg.sender, "Caller is not the owner of the token");
    }

    // Burn the tokens
    for (uint256 i = 0; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];
        _hivemind.burn(tokenId);
    }

    _safeMint(msg.sender, nextTokenIdForHivemind);
    nextTokenIdForHivemind++;
}


function hackPFP(uint256[] calldata tokenIds) public {
    require(tokenIds.length == 4, "Incorrect number of ZeroDay tokens provided");

    for (uint256 i = 0; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];
        require(_zeroDay.ownerOf(tokenId) == msg.sender, "Caller is not the owner of the token");
    }

    _zeroDay.bruteF0rce(tokenIds); // Pass the entire tokenIds array to bruteF0rce

    _safeMint(msg.sender, nextTokenIdForZeroDay);
    nextTokenIdForZeroDay++;
}



    // Add the burn function to allow burning of PFP tokens
    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner of the token");
        _burn(tokenId);
    }
}