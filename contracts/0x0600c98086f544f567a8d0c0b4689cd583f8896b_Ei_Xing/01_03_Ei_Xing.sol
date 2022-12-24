// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "erc721a/contracts/ERC721A.sol";

contract Ei_Xing is ERC721A {
    string public baseTokenURI;
    address public owner;
    uint256 constant MAX_SUPPLY = 100;
    uint256 constant PRICE = 0.03 ether;
    mapping(address => bool) minteds;

    constructor(string memory _baseTokenUri) ERC721A("Ei-Xing", "Ei-Xing") {
        baseTokenURI = _baseTokenUri;
        owner = msg.sender;
        _mint(msg.sender, 1);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function mint() external payable {
        require(totalSupply() < MAX_SUPPLY, "Sold out!");
        require(msg.value >= PRICE, "Not paying enough fees");
        require(!minteds[msg.sender], "Already been minted");
        minteds[msg.sender] = true;
        _mint(msg.sender, 1);
    }

    function ownerMint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Sold out!");
        _mint(to, amount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}