// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheAppleth is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 2000;
    uint256 public maxFreeSupply = 500;
    uint256 public cost = 0.002 ether;
    uint256 public maxPerTx = 10;
    uint256 public maxFree = 1;
    uint256 public mintedFreeSupply = 0;
    bool public sale;
    bool public isRevealed;

    string private baseTokenUri;
    string private hiddenTokenUri = "ipfs://QmcpjHUaYjhYT7bYhgxgkjRsEnMWWN529Js4vRHa3xcHUZ/unrevealed.json";
    mapping(address => uint256) private _mintedFreeAmount;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerTxReached();
    error MaxFreeSupplyReached();
    error NotEnoughETH();

    constructor() ERC721A("TheAppleth", "TAETH") {}

    function mint(uint256 _amount) external payable {
        if (!sale) revert SaleNotActive();

        uint256 _cost = (msg.value == 0 &&
            (_mintedFreeAmount[msg.sender] + _amount <= maxFree))
            ? 0
            : cost;

        if (_cost == 0 && mintedFreeSupply >= maxFreeSupply)
            revert MaxFreeSupplyReached();
        if (_amount > maxPerTx) revert MaxPerTxReached();
        if (msg.value < _cost * _amount) revert NotEnoughETH();
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();

        if (_cost == 0) {
            _mintedFreeAmount[msg.sender] += _amount;
            mintedFreeSupply += 1;
        }

        _mint(msg.sender, _amount);
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

    function setBaseTokenUri(string memory _baseTokenUri) public onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setHiddenTokenUri(string memory _hiddenTokenUri) public onlyOwner {
        hiddenTokenUri = _hiddenTokenUri;
    }

    function startSale() external onlyOwner {
        sale = !sale;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxFreeMint(uint256 _maxFree) external onlyOwner {
        maxFree = _maxFree;
    }

    function setMaxFreeSupply(uint256 _maxFreeSupply) external onlyOwner {
        maxFreeSupply = _maxFreeSupply;
    }

    function teamMint(address receiver, uint256 _amount) external onlyOwner {
        _safeMint(receiver, _amount);
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}