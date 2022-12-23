// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//    _____ __
//   / ___// /_  ___  ___  ____  ___  ____ ______
//   \__ \/ __ \/ _ \/ _ \/ __ \/ _ \/ __ `/ ___/
//  ___/ / / / /  __/  __/ /_/ /  __/ /_/ (__  )
// /____/_/ /_/\___/\___/ .___/\___/\__, /____/
//                     /_/         /____/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Sheepegs is ERC721A, Ownable {
    uint256 public maxSupply = 4050;
    uint256 public mintPrice = 0.002 ether;
    uint256 public maxMintPerTx = 10;
    uint256 public maxFreeMintPerWallet = 1;
    bool public mintStarted = false;

    using Strings for uint256;
    string public baseURI =
        "ipfs://QmQxCkyMCGp26oBycBQpqgck3GJg3tGU4FnbM45pxJwDoo/";
    mapping(address => uint256) private _mintedFreeAmount;
    mapping(address => uint256) private _mintedPerWallet;

    constructor() ERC721A("Sheepegs", "SHEEP") {}

    function mint(uint256 count) external payable {
        require(mintStarted, "Minting is not live yet.");

        uint256 cost = (msg.value == 0 &&
            (_mintedFreeAmount[msg.sender] + count <= maxFreeMintPerWallet))
            ? 0
            : mintPrice;

        require(
            _mintedPerWallet[msg.sender] + count <= maxMintPerTx,
            "Max per wallet reached."
        );
        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count <= maxSupply, "Sold out!");

        require(count <= maxMintPerTx, "Max per txn reached.");

        if (cost == 0) {
            _mintedFreeAmount[msg.sender] += count;
        } else {
            _mintedPerWallet[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
    }

    function walletRemainingFreeMint(address wallet)
        public
        view
        returns (uint256)
    {
        return maxFreeMintPerWallet - _mintedFreeAmount[wallet];
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
        mintStarted = !mintStarted;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setMaxFreeMint(uint256 _newMaxFreeMint) external onlyOwner {
        maxFreeMintPerWallet = _newMaxFreeMint;
    }

    function teamMint(address receiver, uint256 _number) external onlyOwner {
        _safeMint(receiver, _number);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}