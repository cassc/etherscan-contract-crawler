// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ElonAITradingCards is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 2121;
    uint256 public mintPrice = 0 ether;
    uint256 public maxPerTransaction = 4;
    bool public paused = true;
    string private baseTokenUri = "";
    string public hiddenTokenUri =
        "ipfs//Qme9N6MPhwydq8wKvjWMsDRpLMqmmUdqZnZqW5wiaVqvEW/unrevealed.json";
    mapping(address => uint256) public mintedPerAddress;
    bool public isRevealed;

    constructor() ERC721A("Elon AI Trading Cards", "EATC") {}

    function mint(uint256 _quantity) external payable {
        require(!paused, "Contract is paused.");
        require(
            (totalSupply() + _quantity) <= maxSupply,
            "Max supply exceeded."
        );
        require(
            (mintedPerAddress[msg.sender] + _quantity) <= maxPerTransaction,
            "Max mint per wallet exceeded."
        );
        require(msg.value >= (mintPrice * _quantity), "Wrong mint price.");

        mintedPerAddress[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
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

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        maxSupply = _newSupply;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed.");
    }
}