// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract JimmyIsPooping is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 333;
    uint256 public mintPrice = .005 ether;
    uint256 public maxPerTx = 3;
    string public baseURI = "ipfs://QmdChhKCpq3HGiA6uhAHhSdHZPhEYYdTJJzfmF9TMF9XhN/";
    bool public paused = true;
    mapping(address => uint256) public walletMintCount;

    constructor() ERC721A("Jimmy is Pooping", "JIMMY") {}

    function mint(uint256 _quantity) external payable {
        require(paused == false, "Mint paused");
        require(
            (totalSupply() + _quantity) <= maxSupply,
            "Max supply exceeded"
        );
        require(
            (walletMintCount[msg.sender] + _quantity) <= maxPerTx,
            "Max mint exceeded"
        );
        require(msg.value >= (mintPrice * _quantity), "Wrong mint price");

        walletMintCount[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
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

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}