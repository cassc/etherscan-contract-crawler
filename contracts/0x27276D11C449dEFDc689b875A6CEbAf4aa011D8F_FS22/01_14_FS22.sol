// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title: a16z Crypto Founders Summit 2022
/// @author: Michael Blau and Nassim Eddequiouaq

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

contract FS22 is ERC1155, Ownable, CantBeEvil(LicenseVersion.PUBLIC) {

    // =================== CUSTOM ERRORS =================== //

    error NonTransferableToken();
    error NonexistentToken();
    error AlreadyMinted();


    string internal tokenURI;

    constructor() ERC1155("") {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, CantBeEvil)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            CantBeEvil.supportsInterface(interfaceId);
    }

    /**
     * @notice Batch mint FS22 NFTs. One NFT per address.
     */
    function mint(address [] calldata _founders) external onlyOwner {
        for(uint256 i = 0; i < _founders.length; i++){
            if (balanceOf(_founders[i], 1) > 0) revert AlreadyMinted();
            _mint(_founders[i], 1, 1, "");
        }
    }

    /**
     * @notice You can burn the NFT.
     */
    function burn() external {
        _burn(msg.sender, 1, 1);
    }

    /**
     * @notice The NFT is non-transferable.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        if (from != address(0) && to != address(0)) {
            revert NonTransferableToken();
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     */
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (_tokenId != 1) revert NonexistentToken();
        return tokenURI;
    }


    // =================== ADMIN FUNCTIONS =================== //

    function setTokenURI(string memory _newTokenURI) external onlyOwner {
        tokenURI = _newTokenURI;
    }
}