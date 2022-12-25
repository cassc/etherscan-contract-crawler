// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ProofOfPizza is ERC721A, Ownable {
    uint256 public maxSupply = 3333;
    uint256 public mintPrice = 0.001 ether;
    uint256 public maxMintPerTx = 10;
    uint256 public maxFreeMintPerWallet = 1;
    bool public paused = true;
    bool public isRevealed;

    using Strings for uint256;
    string private baseTokenUri = "";
    string public hiddenTokenUri =
        "ipfs://QmYqB5MezWV4TvGLqPx6pkiX8sBMmzZ8LH1ETfNrKFJPBm/unrevealed.json";
    mapping(address => uint256) private _mintedFreeAmount;
    mapping(address => uint256) private _mintedPerWallet;

    constructor() ERC721A("Proof of Pizza", "PIZZA") {}

    function mint(uint256 count) external payable {
        require(paused == false, "Minting is not live yet.");

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

    function teamMint(address receiver, uint256 amount) external onlyOwner {
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

        uint256 trueId = tokenId + 1;

        if (!isRevealed) {
            return hiddenTokenUri;
        }
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, trueId.toString(), ".json")
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function cutSupply(uint256 _newSupply) external onlyOwner {
        maxSupply = _newSupply;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed.");
    }
}