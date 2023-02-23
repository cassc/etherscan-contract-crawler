// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity 0.8.9;

import "IERC721ABurnable.sol";
import "Ownable.sol";
import "ERC721A.sol";

abstract contract ERC721ABurnable is ERC721A, IERC721ABurnable, Ownable {
    modifier isWhitelisted(address _addr) {
        require(whitelist[_addr], "You need to be whitelisted to burn assets");
        _;
    }

    mapping(address => bool) public whitelist;

    function whiteListChange(address _addr, bool isWhiteListed)
        public
        onlyOwner
    {
        whitelist[_addr] = isWhiteListed;
    }

    function burn(uint256 tokenId)
        public
        virtual
        override
        isWhitelisted(msg.sender)
    {
        _burn(tokenId, true);
    }
}