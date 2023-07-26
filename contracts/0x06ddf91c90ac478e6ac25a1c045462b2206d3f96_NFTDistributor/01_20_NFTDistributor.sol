// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./libs/Adminable.sol";
import "./interfaces/IERC721A.sol";

contract NFTDistributor is Initializable, ReentrancyGuardUpgradeable, PausableUpgradeable, Adminable {
    address public NFT_ADDRESS;
    address public NFT_BANK;
    mapping(address => uint64) public WHITELIST_COUNT_MAPPING;
    uint64[] public TOKEN_IDS;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function setTokenIds(uint64[] memory ids_) public onlyAdmin {
        TOKEN_IDS = ids_;
    }

    function initialize(address nft_address, address nft_bank) public initializer {
        require(nft_address != address(0), "NFTDistributor: nftAddress_ must not be zero address");

        NFT_ADDRESS = nft_address;
        NFT_BANK = nft_bank;
        _setAdmin(msg.sender);
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    function setNFTBank(address nft_bank) public onlyAdmin {
        NFT_ADDRESS = nft_bank;
    }

    function setWhiteList(address[] memory whitelist_addresses, uint64[] memory remain_number) public onlyAdmin {
        require(whitelist_addresses.length == remain_number.length, "NFTDistributor: mismatch length");
        for (uint i = 0; i < whitelist_addresses.length; i++) {
            WHITELIST_COUNT_MAPPING[whitelist_addresses[i]] = remain_number[i];
        }
    }

    function whitelistClaim(uint64 count_) public {
        require(TOKEN_IDS.length >= count_, "NFTDistributor: The balance of NFT is not enough");
        require(WHITELIST_COUNT_MAPPING[msg.sender] >= count_, "NFTDistributor: not able to claim");
        WHITELIST_COUNT_MAPPING[msg.sender] -= count_;
        for (uint i = 0; i < count_; i++) {
            uint256 tokenId = TOKEN_IDS[TOKEN_IDS.length - 1];
            require(IERC721A(NFT_ADDRESS).ownerOf(tokenId) == NFT_BANK);
            IERC721A(NFT_ADDRESS).safeTransferFrom(NFT_BANK, address(msg.sender), tokenId);
            TOKEN_IDS.pop();
        }
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }
}