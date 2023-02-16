// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract whomisstheblur is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 444;
    uint256 public mintPrice = .004 ether;
    uint256 public maxPerWallet = 4;
    bool public paused = true;
    string public baseURI =
        "ipfs://QmcKWMPUWyMHPTPJogMoDzcnHzWhxyYQnJh7sj7nVctJQg/";

    constructor() ERC721A("who miss the blur", "wmtb") {}

    function mint(uint256 amount) external payable {
        require(!paused, "Mint paused");
        require((totalSupply() + amount) <= maxSupply, "Max supply reached");
        require(amount <= maxPerWallet, "Max mint per transaction reached");
        require(msg.value >= (mintPrice * amount), "Wrong mint price");

        _safeMint(msg.sender, amount);
    }

    function ownerMint(address receiver, uint256 amount) external onlyOwner {
        _safeMint(receiver, amount);
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

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setPaused() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transaction failed");
    }
}