// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//                      _                             _
//  _ _ _ ___ ___ _____|_|   ___ ___    ___ ___ _____|_|
// | | | | .'| . |     | |  | . |  _|  |   | . |     | |
// |_____|__,|_  |_|_|_|_|  |___|_|    |_|_|_  |_|_|_|_|
//           |___|                         |___|

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract wagmiorngmi is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 2000;
    uint256 public cost = .002 ether;
    uint256 public maxPerTx = 10;
    bool public sale = false;
    string private baseTokenUri;
    string private hiddenTokenUri;
    bool public isRevealed;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerTxReached();
    error NotEnoughETH();

    constructor(string memory initHiddenTokenUri)
        ERC721A("wagmiorngmi", "won")
    {
        hiddenTokenUri = initHiddenTokenUri;
    }

    function mint(uint256 _amount) external payable {
        if (!sale) revert SaleNotActive();
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
        if (_amount > maxPerTx) revert MaxPerTxReached();
        if (msg.value < cost * _amount) revert NotEnoughETH();

        _mint(msg.sender, _amount);
    }

    function ownerMint(address receiver, uint256 _amount) external onlyOwner {
        _mint(receiver, _amount);
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

    function setHiddenTokenUri(string memory _hiddenTokenUri)
        external
        onlyOwner
    {
        hiddenTokenUri = _hiddenTokenUri;
    }

    function toggleSale() external onlyOwner {
        sale = !sale;
    }

    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        maxSupply = _newSupply;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}