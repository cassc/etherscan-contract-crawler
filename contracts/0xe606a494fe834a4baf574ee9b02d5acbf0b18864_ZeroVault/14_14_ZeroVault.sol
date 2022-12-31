// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ZeroVault is
    ERC721HolderUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    string public version;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Initialization and Proxy Administration
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        version = "Version 0.1";
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * IERC721 functionality
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function safeTransfer(
        address _contract,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        IERC721(_contract).safeTransferFrom(address(this), to, tokenId);
    }

    function transfer(
        address _contract,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        IERC721(_contract).transferFrom(address(this), to, tokenId);
    }

    function approve(
        address _contract,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        IERC721(_contract).approve(to, tokenId);
    }

    function setApprovalForAll(
        address _contract,
        address operator,
        bool approved
    ) public onlyOwner {
        IERC721(_contract).setApprovalForAll(operator, approved);
    }
}