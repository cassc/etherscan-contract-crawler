// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract RMWFreedomTicket is ERC1155, ERC1155Burnable, ERC2981, Ownable {
    uint256 public tradableTokenId = 1;

    constructor(
        string memory _uri,
        address _feeAddress,
        uint96 _feeNumerator
    ) ERC1155(_uri) {
        _setDefaultRoyalty(_feeAddress, _feeNumerator);
    }

    function mint(address addr, uint256 quantity) external onlyOwner {
        _mint(addr, tradableTokenId, quantity, "");
    }

    function burn(address addr, uint256 amount) public onlyOwner {
        _burn(addr, tradableTokenId, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}