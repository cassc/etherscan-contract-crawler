// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../interface/IActivityERC721.sol";

contract ActivityERC721 is IActivityERC721, ERC721Enumerable {
    uint256 private _counters;
    string private _activityName;
    string private _activitySymbol;
    string public baseURI;
    address public factory;

    modifier onlyOwner() {
        require(msg.sender == factory, "caller is not the owner");
        _;
    }

    constructor() ERC721("", "") {
        factory = msg.sender;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) external {
        _activityName = _name;
        _activitySymbol = _symbol;
        baseURI = _uri;
    }

    function name() public view override returns (string memory) {
        return _activityName;
    }

    function symbol() public view override returns (string memory) {
        return _activitySymbol;
    }

    function safeMint(address to) public onlyOwner returns (uint256 tokenId) {
        tokenId = _counters++;
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return (
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toHexString(uint256(uint160(address(this))), 20),
                    "/",
                    Strings.toString(tokenId),
                    ".json"
                )
            )
        );
    }

    function setURI(string memory newuri) public onlyOwner {
        baseURI = newuri;
    }

    function setName(string memory _name) public onlyOwner {
        _activityName = _name;
    }

    function setSymbol(string memory _symbol) public onlyOwner {
        _activitySymbol = _symbol;
    }

    function setFactory(address _factory) public onlyOwner {
        require(_factory != address(0), "zero address");

        factory = _factory;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}