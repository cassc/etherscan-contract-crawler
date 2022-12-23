// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HelpMeHackThis is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 333;
    uint256 public mintPrice = .005 ether;
    uint256 public maxPerWallet = 2;
    bool public paused = true;
    string public baseURI;
    mapping(address => uint256) public mintPerWallet;

    constructor(string memory initBaseURI) ERC721A("HelpMeHackThis", "HACK") {
        baseURI = initBaseURI;
    }

    function mint(uint256 _quantity) external payable {
        require(!paused, "***ERROR*** MINT PAUSED!");
        require(
            (totalSupply() + _quantity) <= maxSupply,
            "***WARNING*** MAX SUPPLY EXCEEDED!"
        );
        require(
            msg.value >= (mintPrice * _quantity),
            "***WARNING*** WRONG MINT PRICE!"
        );
        require(
            (mintPerWallet[msg.sender] + _quantity) <= maxPerWallet,
            "***WARNING*** MAX PER WALLET EXCEEDED!"
        );

        mintPerWallet[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function reserveMint(address receiver, uint256 mintAmount)
        external
        onlyOwner
    {
        _safeMint(receiver, mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function startSale() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}