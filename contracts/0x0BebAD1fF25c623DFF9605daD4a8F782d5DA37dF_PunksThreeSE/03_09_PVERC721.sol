// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@rari-capital/solmate/src/auth/Owned.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PVERC721 is ERC721, Owned {
    using Strings for uint256;

    uint256 tokenCounter;
    string uri;

    uint256 immutable MAX_SUPPLY;

    error notExists();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) Owned(msg.sender) {
        uri = _uri;

        MAX_SUPPLY = _maxSupply;
    }

    function _mintMany(address _account, uint256 _amount) internal {
        for (uint256 i; i < _amount; ) {
            _internalMint(_account);

            unchecked {
                i++;
            }
        }
    }

    function _internalMint(address _account) internal {
        require(tokenCounter < MAX_SUPPLY, "Max supply reached");

        ++tokenCounter;
        _mint(_account, tokenCounter);
    }

    function setURI(string memory _uri) external onlyOwner {
        uri = _uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (tokenCounter < tokenId) {
            revert notExists();
        }

        return uri;
    }
}