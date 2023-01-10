// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Robogools is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 666;
    uint256 public mintPrice = .006 ether;
    uint256 public maxPerWallet = 5;
    bool public paused = true;
    string public baseURI = "ipfs://QmR58s1Y2kaAWevARKtqmb2Pb9pNTWt1yEHqv8421qRBdA/";

    constructor() ERC721A("Robogools", "ROBO") {}

    function mint(uint256 amount) external payable {
        require(!paused, "Mint is paused");
        require((totalSupply() + amount) <= maxSupply, "Max supply exceeded");
        require(amount <= maxPerWallet, "Max per transaction exceeded");
        require(
            msg.value >= (mintPrice * amount),
            "Wrong mint price"
        );
        _safeMint(msg.sender, amount);
    }

    function teamMint(address to, uint256 mintAmount)
        external
        onlyOwner
    {
        _safeMint(to, mintAmount);
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

    function setPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setValues(uint256 newAmount) external onlyOwner {
        maxSupply = newAmount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}