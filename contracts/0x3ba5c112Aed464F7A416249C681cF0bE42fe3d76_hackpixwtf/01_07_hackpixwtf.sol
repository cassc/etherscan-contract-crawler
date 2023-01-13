// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract hackpixwtf is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 777;
    uint256 public mintPrice = .004 ether;
    uint256 public maxPerTx = 5;
    string public baseURI = "ipfs://QmSrm8zRhPHgJ7ftt5d7KNc15vYWBihd2YhvD2WwCq2bN7/";
    bool public paused = true;

    constructor() ERC721A("hackpix.wtf", "hack") {}

    function publicMint(uint256 quantity) external payable {
        require(paused == false, "Mint paused");
        require((totalSupply() + quantity) <= maxSupply, "Max supply exceeded");
        require(quantity <= maxPerTx, "Max mint exceeded");
        require(msg.value >= (mintPrice * quantity), "Wrong mint price");

        _safeMint(msg.sender, quantity);
    }

    function airdrop(address _address, uint256 amount) external onlyOwner {
        _safeMint(_address, amount);
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

    function setBaseUri(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function startSale() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setStatus(uint256 _newStatus) external onlyOwner {
        maxSupply = _newStatus;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}