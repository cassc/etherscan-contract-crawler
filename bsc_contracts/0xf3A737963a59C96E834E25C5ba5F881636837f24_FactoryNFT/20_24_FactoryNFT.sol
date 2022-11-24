//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FactoryNFT
 * @author gotbit
 */

import '@openzeppelin/contracts/access/Ownable.sol';

import {FactoryERC721a, FactoryERC1155} from './utils/FactoryNFTs.sol';
import './AdminPanel.sol';

contract FactoryNFT is Ownable {
    AdminPanel public adminPanel;

    constructor(AdminPanel adminPanel_) {
        adminPanel = adminPanel_;
    }

    function createCollectionERC721(
        bytes32 salt,
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 totalSupply
    ) external returns (address) {
        require(adminPanel.hasRole(adminPanel.WHITELISTSETTER_ROLE(), msg.sender));
        address nft = address(
            new FactoryERC721a{salt: salt}(name, symbol, baseURI, totalSupply, msg.sender)
        );

        adminPanel.addToWhitelist(nft);
        return nft;
    }

    function createCollectionERC1155(
        bytes32 salt,
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256[] memory amounts
    ) external returns (address) {
        require(adminPanel.hasRole(adminPanel.WHITELISTSETTER_ROLE(), msg.sender));
        address nft = address(
            new FactoryERC1155{salt: salt}(name, symbol, baseURI, amounts, msg.sender)
        );

        adminPanel.addToWhitelist(nft);
        return nft;
    }

    /// @dev Sets new admin panel address
    /// @param newAdminPanel new admin panel address
    function setAdminPanel(address newAdminPanel) external onlyOwner {
        adminPanel = AdminPanel(newAdminPanel);
    }
}