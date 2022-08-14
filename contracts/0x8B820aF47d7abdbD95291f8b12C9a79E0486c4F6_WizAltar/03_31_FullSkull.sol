// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract FullSkull is Ownable, ERC1155Pausable, ERC1155Burnable {
    using Strings for uint256;

    mapping(address => bool) private altarOfSacrifice;

    constructor(string memory a) ERC1155(a) {}

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public onlyAltars {
        _mint(to, id, amount, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addAltar(address a) public onlyOwner {
        altarOfSacrifice[a] = true;
    }

    function removeAltar(address a) public onlyOwner {
        altarOfSacrifice[a] = false;
    }

    modifier onlyAltars() {
        require(altarOfSacrifice[_msgSender()], 'Not an altar of sacrifice');
        _;
    }

    function isApprovedForAll(address account, address operator) public override view returns (bool) {
        if (altarOfSacrifice[operator]) {
            return true;
        }

        return super.isApprovedForAll(account, operator);
    }

    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory baseURI = super.uri(0);
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }
}