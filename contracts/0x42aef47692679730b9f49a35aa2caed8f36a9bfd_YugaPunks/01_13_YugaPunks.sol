// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import '@openzeppelin/contracts/access/Ownable.sol';
import './ERC721ABurnable.sol';

contract YugaPunks is Ownable, ERC721A, ERC721ABurnable {

    using Strings for uint256;

    uint256 public collectionSize = 311;
    string private baseTokenURI;
    bool public saleIsActive;

    constructor() ERC721A("Yuga Punks", "YP") {}

    function mint() external {
        require(
            saleIsActive,
            "Sale is not active"
        );
        require(
            _getAux(_msgSender()) == 0,
            "You have already minted"
        );
        require(
            _totalMinted() + 1 <= collectionSize,
            "Exceeds max supply"
        );
        require(
            tx.origin == _msgSender(),
            "Not allowing contracts"
        );

        _setAux(_msgSender(), 1);
        _safeMint(_msgSender(), 1);
    }

    function ownerMint(uint256 _amount) external onlyOwner {
        require(
            _totalMinted() == 0,
            "Owner has already minted"
        );

        _safeMint(_msgSender(), _amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}