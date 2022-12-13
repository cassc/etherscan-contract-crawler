// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// ___________               ________   _____  _____.__       .__       .__   
// \_   _____/ ____ _____    \_____  \_/ ____\/ ____\__| ____ |__|____  |  |  
//  |    __)_ /    \\__  \    /   |   \   __\\   __\|  |/ ___\|  \__  \ |  |  
//  |        \   |  \/ __ \_ /    |    \  |   |  |  |  \  \___|  |/ __ \|  |__
// /_______  /___|  (____  / \_______  /__|   |__|  |__|\___  >__(____  /____/
//         \/     \/     \/          \/                     \/        \/      

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EnaOfficial is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 444;
    uint256 public mintPrice = .008 ether;
    uint256 public maxPerWallet = 2;
    bool public paused = true;
    string public baseURI;
    mapping(address => uint256) public mintPerWallet;

    constructor(string memory initBaseURI) ERC721A("Ena Official", "ENA") {
        baseURI = initBaseURI;
    }

    function mint(uint256 _quantity) external payable {
        require(!paused, "// Mint paused.");
        require(
            (totalSupply() + _quantity) <= maxSupply,
            "// Max supply exceeded."
        );
        require(
            (mintPerWallet[msg.sender] + _quantity) <= maxPerWallet,
            "// Max mint exceeded."
        );
        require(msg.value >= (mintPrice * _quantity), "// Wrong mint price.");

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

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}