// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IPlantRenderer.sol";

contract OnchainPlants is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 2929;
    uint256 public maxFree = 1;
    uint256 public maxPerTx = 10;
    uint256 public cost = .003 ether;
    bool public sale;
    bool public isRevealed;
    string private baseTokenUri;
    string private hiddenTokenUri;

    // On-chain connection
    IPlantRenderer public renderer;

    mapping(address => uint256) private _mintedFreeAmount;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerTxReached();
    error NotEnoughETH();

    constructor(string memory initHiddenTokenUri)
        ERC721A("On-chain Plants", "Plant")
    {
        hiddenTokenUri = initHiddenTokenUri;
    }

    function mint(uint256 _amount) external payable {
        if (!sale) revert SaleNotActive();

        uint256 _cost = (msg.value == 0 &&
            (_mintedFreeAmount[msg.sender] + _amount <= maxFree))
            ? 0
            : cost;

        if (_amount > maxPerTx) revert MaxPerTxReached();
        if (msg.value < _cost * _amount) revert NotEnoughETH();
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();

        if (_cost == 0) {
            _mintedFreeAmount[msg.sender] += _amount;
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

        if (!isRevealed) {
            return hiddenTokenUri;
        }

        // Plant renderer
        return
            bytes(baseTokenUri).length > 0
                ? renderer.tokenUri(uint16(tokenId))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseTokenUri(string memory baseTokenUri_) public onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function setHiddenTokenUri(string memory _hiddenTokenUri)
        external
        onlyOwner
    {
        hiddenTokenUri = _hiddenTokenUri;
    }

    function startSale() external onlyOwner {
        sale = !sale;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        cost = _newPrice;
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        maxSupply = _newSupply;
    }

    function setMaxFreeMint(uint256 _maxFree) external onlyOwner {
        maxFree = _maxFree;
    }

    function ownerMint(address _receiver, uint256 _amount) external onlyOwner {
        _mint(_receiver, _amount);
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}