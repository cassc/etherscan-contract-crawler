// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
  ______              _             ______                       
 (____  \            (_)           (____  \                      
  ____)  ) ___   ____ _ ____   ____ ____)  ) ____ ____  ____ ___ 
 |  __  ( / _ \ / ___) |  _ \ / _  |  __  ( / _  ) _  |/ ___)___)
 | |__)  ) |_| | |   | | | | ( ( | | |__)  | (/ ( ( | | |  |___ |
 |______/ \___/|_|   |_|_| |_|\_|| |______/ \____)_||_|_|  (___/ 
                             (_____|                             

*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BoringBears is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 5000;
    uint256 public maxFree = 1;
    uint256 public maxPerTx = 10;
    uint256 public cost = .002 ether;
    bool public sale;

    string private baseURI;

    mapping(address => uint256) public mintedFreeAmount;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerTxReached();
    error NotEnoughETH();

    constructor(string memory initBaseURI) ERC721A("BoringBears", "BB") {
        baseURI = initBaseURI;
    }

    function mint(uint256 amount) external payable {
        if (!sale) revert SaleNotActive();
        if (totalSupply() + amount > maxSupply) revert MaxSupplyReached();
        if (amount > maxPerTx) revert MaxPerTxReached();

        uint256 freeMintsLeft = maxFree - mintedFreeAmount[msg.sender];
        bool freeMint = msg.value == 0 && amount <= freeMintsLeft;

        if (freeMint) {
            mintedFreeAmount[msg.sender] += amount;
        } else {
            if (msg.value < cost * amount) revert NotEnoughETH();
        }

        _safeMint(msg.sender, amount);
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

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function startSale() external onlyOwner {
        sale = !sale;
    }

    function setPrice(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setMaxFreeMint(uint256 _maxFree) external onlyOwner {
        maxFree = _maxFree;
    }

    function setSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function teamMint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}