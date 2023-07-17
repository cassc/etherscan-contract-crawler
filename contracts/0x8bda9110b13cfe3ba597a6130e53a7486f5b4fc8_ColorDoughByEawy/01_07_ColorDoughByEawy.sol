// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//    ___      _                 ___                  _     
//   / __\___ | | ___  _ __     /   \___  _   _  __ _| |__  
//  / /  / _ \| |/ _ \| '__|   / /\ / _ \| | | |/ _` | '_ \ 
// / /__| (_) | | (_) | |     / /_// (_) | |_| | (_| | | | |
// \____/\___/|_|\___/|_|    /___,' \___/ \__,_|\__, |_| |_|
//                                              |___/       
                                                                                                                 

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ColorDoughByEawy is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 333;
    uint256 public mintPrice = .003 ether;
    uint256 public maxPerWallet = 3;
    bool public paused = true;
    string public baseURI = "ipfs://QmS82YYXdpjGARCR58bm7gExCN8QnzSBNNjgArU5je77ek/";

    constructor() ERC721A("Color Dough by Eawy", "CD") {}

    function mint(uint256 amount) external payable {
        require(!paused, "Minting is not active");
        require((totalSupply() + amount) <= maxSupply, "All tokens are gone");
        require(amount <= maxPerWallet, "Exceeded max mints allowed");
        require(msg.value >= (mintPrice * amount), "Incorrect amount of ether sent");

        _safeMint(msg.sender, amount);
    }

    function teamMint(address receiver, uint256 mintAmount)
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

    function setValue(uint256 newValue) external onlyOwner {
        maxSupply = newValue;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }
}