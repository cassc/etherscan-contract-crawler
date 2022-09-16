// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./access/InheritedOwner.sol";

contract ERC721Initializable is ERC721, InheritedOwner, Initializable
{
    constructor() ERC721("__", "__") {}

    // Token name
    string private __name;
    // Token symbol
    string private __symbol;

    function _initializeERC721(
        string memory name_,
        string memory symbol_
    )
        virtual
        internal
    {
        __name = name_;
        __symbol = symbol_;
    }

    function name()
        virtual override
        public view
        returns (string memory)
    {
        return __name;
    }

    function symbol()
        virtual override
        public view
        returns (string memory)
    {
        return __symbol;
    }

}