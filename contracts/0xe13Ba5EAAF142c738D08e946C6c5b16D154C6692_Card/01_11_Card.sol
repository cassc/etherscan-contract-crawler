//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./utils/Warded.sol";

contract Card is ERC721, Warded {

    using Strings for uint256;

    event NewCard(address indexed owner, uint256 id);

    struct CardInfo {
        string name;
        string symbol;
        uint256 id;
        address owner;
        string description;
        string image;
    }

    modifier onlyOwner(uint256 id) {
        require(wards[msg.sender] == 1 || msg.sender == ownerOf(id), "Card/not-owner");
        _;
    }

    string private baseURI;

    uint256 public lastId;
    mapping(uint256 => string) public description;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        relyOnSender();
        baseURI = "https://chimes-giraffe-eb4x.squarespace.com";
    }

    function mintNext(address usr, string memory desc) public auth returns (uint256) {
        lastId += 1;

        _safeMint(usr, lastId);
        if (bytes(desc).length > 0) {
            description[lastId] = desc;
        }

        emit NewCard(usr, lastId);

        return lastId;
    }

    function mintMultiple(address[] memory users) external auth {
        for (uint i = 0; i < users.length; i++) {
            mintNext(users[i], "");
        }
    }

    function setDescription(uint256 id, string memory desc) external auth {
        require(id <= lastId, "Card/not-existing");
        description[id] = desc;
    }

    function burn(uint256 id) external auth {
        _burn(id);
    }

    function setBaseURI(string memory newURI) external auth {
        baseURI = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function info(uint256 id) external view returns (CardInfo memory) {
        string memory baseURI = _baseURI();
        string memory image = string(abi.encodePacked(baseURI, "/s/card-", id.toString(), ".png"));
        return CardInfo({
        name : name(),
        symbol : symbol(),
        id : id,
        owner : ownerOf(id),
        description : description[id],
        image : image
        });
    }

    function image(uint256 id) external view returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, "/s/card-", id.toString(), ".png"));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(wards[msg.sender] == 1, "Only admin can transfer");
    }

}