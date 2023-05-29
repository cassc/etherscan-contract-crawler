// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "@oz/access/Ownable.sol";
import {ERC1155, ERC1155Burnable} from "@oz/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Supply} from "@oz/token/ERC1155/extensions/ERC1155Supply.sol";
import {Strings} from "@oz/utils/Strings.sol";
import {Address} from "@oz/utils/Address.sol";

abstract contract AbstractERC1155 is ERC1155Supply, ERC1155Burnable, Ownable {
    string private baseURI;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) ERC1155("") {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @notice Name of the token
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @notice Symbol of the token
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Base URI of the token
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @notice Return the base uri of the ERC1155
     * @param tokenId Token id to observe
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @notice Withdraw any ether in the contract (redundant for the most part)
     */
    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }
}