// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*

___________ _______  __________________   
\_   _____/ \      \ \____    /\_____  \  
 |    __)_  /   |   \  /     /  /   |   \ 
 |        \/    |    \/     /_ /    |    \
/_______  /\____|__  /_______ \\_______  /
        \/         \/        \/        \/ 

Twitter: https://twitter.com/EnzoCollection
Website: https://www.enzonft.xyz/

*/

contract EnzoCollection is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 5000;
    uint256 public maxPerTx = 25;
    uint256 public maxFree = 1;
    uint256 public cost = .004 ether;
    bool public isRevealed;
    bool public sale;

    string private baseURI;
    string public hiddenURI;

    mapping(address => uint256) public mintedFreeAmount;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerTxReached();
    error NotEnoughETH();

    constructor(string memory initHiddenURI) ERC721A("Enzo Collection", "ENZO") {
        hiddenURI = initHiddenURI;
    }

    function mint(uint256 _amount) external payable {
        if (!sale) revert SaleNotActive();

        uint256 _cost = (msg.value == 0 &&
            (mintedFreeAmount[msg.sender] + _amount <= maxFree))
            ? 0
            : cost;

        if (_amount > maxPerTx) revert MaxPerTxReached();
        if (msg.value < _cost * _amount) revert NotEnoughETH();
        if (totalSupply() + _amount > maxSupply) revert MaxSupplyReached();

        if (_cost == 0) {
            mintedFreeAmount[msg.sender] += _amount;
        }

        _safeMint(msg.sender, _amount);
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

        if (!isRevealed) {
            return hiddenURI;
        }
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setHiddenURI(string memory _newHiddenURI) external onlyOwner {
        hiddenURI = _newHiddenURI;
    }

    function setReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function startSale() external onlyOwner {
        sale = !sale;
    }

    function setPrice(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function teamMint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}