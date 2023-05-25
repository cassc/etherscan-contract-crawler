// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../dependencies/openzeppelin/contracts/Ownable.sol";
import "../dependencies/erc721a/extensions/ERC721AQueryable.sol";

contract ParaSpaceNFT is ERC721AQueryable, Ownable {
    string metaDataURI;

    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {}

    function mintToAccounts(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], 1);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return metaDataURI;
    }

    function setMetaDataURI(string memory newURI) external onlyOwner {
        metaDataURI = newURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}