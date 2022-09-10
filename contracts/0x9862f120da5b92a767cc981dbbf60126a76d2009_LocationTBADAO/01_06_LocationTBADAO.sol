// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';

error NahYoureBoundToMe();

contract LocationTBADAO is Ownable, ERC721A {
    using Address for address;

    uint256 public maxSupply = 4;
    string private _baseTokenURI;

    constructor() ERC721A('LocationTBADAO', 'TBADAO') {
        _mint(msg.sender, 1);
    }

    function airdrop(address receiver) external onlyOwner {
        _mint(receiver, 1);
    }

    function mint() public {
        _mint(msg.sender, 1);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (from != address(0)) revert NahYoureBoundToMe();
    }

    function updateMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}