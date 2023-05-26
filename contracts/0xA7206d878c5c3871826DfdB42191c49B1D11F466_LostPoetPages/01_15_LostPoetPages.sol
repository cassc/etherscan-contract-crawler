// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Pak
/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//  `7MMF'        .g8""8q.    .M"""bgd MMP""MM""YMM `7MM"""Mq.   .g8""8q. `7MM"""YMM MMP""MM""YMM  .M"""bgd  //
//    MM        .dP'    `YM. ,MI    "Y P'   MM   `7   MM   `MM..dP'    `YM. MM    `7 P'   MM   `7 ,MI    "Y  //
//    MM        dM'      `MM `MMb.          MM        MM   ,M9 dM'      `MM MM   d        MM      `MMb.      //
//    MM        MM        MM   `YMMNq.      MM        MMmmdM9  MM        MM MMmmMM        MM        `YMMNq.  //
//    MM      , MM.      ,MP .     `MM      MM        MM       MM.      ,MP MM   Y  ,     MM      .     `MM  //
//    MM     ,M `Mb.    ,dP' Mb     dM      MM        MM       `Mb.    ,dP' MM     ,M     MM      Mb     dM  //
//  .JMMmmmmMMM   `"bmmd"'   P"Ybmmd"     .JMML.    .JMML.       `"bmmd"' .JMMmmmmMMM   .JMML.    P"Ybmmd"   //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract LostPoetPages is ReentrancyGuard, AdminControl, ERC1155 {

    struct Reward {
        address recipient;
        uint256 amount;
    }

    uint256 constant public maxPages = 65536;
    uint256 public claimedPages;
    bool public active;
    uint256 public privateActiveTimestamp;
    uint256 public publicActiveTimestamp;
    uint256 public endTimestamp;
    address public ashContract;
    uint256 public ashThreshold;

    uint256 constant private _tokenId = 1;
    uint256 private _price = 320000000000000000;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;

    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    event Activate();
    event Deactivate();

    constructor() ERC1155("https://arweave.net/Fx_J8h0B1q6BQYBEeB2bi2Cp4kdTepgM73SpDqK1iAU") {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC1155) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
               || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /**
     * @dev Withdraw funds
     */
    function withdraw(uint256 amount) external adminRequired {
        require(_royaltyRecipient != address(0x0), "Must set royalty recipient");
        _royaltyRecipient.transfer(amount);
    }

    /**
     * @dev Activate public sale
     */
    function activate(uint256 startTime, uint256 privateSaleInterval, uint256 publicSaleInterval, address ashContract_, uint256 ashThreshold_) external adminRequired {
        require(!active, "Already active");
        active = true;
        privateActiveTimestamp = startTime;
        publicActiveTimestamp = startTime+privateSaleInterval;
        endTimestamp = publicActiveTimestamp+publicSaleInterval;
        ashContract = ashContract_;
        ashThreshold = ashThreshold_;
        emit Activate();
    }

    /**
     * @dev Deactivate public sale
     */
    function deactivate() external adminRequired {
        active = false;
        emit Deactivate();
    }

    /**
     * @dev Change the URI
     */
    function setURI(string memory newuri) external adminRequired {
        _setURI(newuri);
    }

    /**
     * @dev Reward pages. Only available before activation
     */
    function rewardPages(Reward[] memory rewards) external adminRequired {
        require(!active && endTimestamp == 0, "Can only reward while inactive");
        for (uint i = 0; i < rewards.length; i++) {
            claimedPages += rewards[i].amount;
            require(claimedPages <= maxPages, "Too many requested");
            _mint(rewards[i].recipient, _tokenId, rewards[i].amount, "");
        }
    }

    /**
     * @dev Distribute remainder. Only available after sale completion
     */
    function distributeRemainder(Reward[] memory rewards) external adminRequired {
        require(endTimestamp > 0 && block.timestamp > endTimestamp, "Can only distribute remainder after sale end");
        for (uint i = 0; i < rewards.length; i++) {
            claimedPages += rewards[i].amount;
            require(claimedPages <= maxPages, "Too many requested");
            _mint(rewards[i].recipient, _tokenId, rewards[i].amount, "");
        }
    }

    /**
     * @dev Claim pages
     */
    function claimPages(uint256 amount) external payable nonReentrant {
        require(active && block.timestamp >= privateActiveTimestamp && block.timestamp <= endTimestamp, "Inactive");
        if (block.timestamp < publicActiveTimestamp) {
            // Private sale, check if individual has appropriate balance
            require(IERC20(ashContract).balanceOf(msg.sender) >= ashThreshold, "You do not have enough ASH to participate in the private sale");
        }

        // Can only claim 1000 at a time
        require(amount <= 1000, "Too many requested");

        // Bonus pages: one page for every 6 claimed
        uint256 totalPages = amount + calculateBonusPages(amount);

        claimedPages += totalPages;
        require(claimedPages <= maxPages, "Too many requested");
        require(amount > 0 && msg.value == amount*_price, "Invalid eth sent");

        _mint(msg.sender, _tokenId, totalPages, "");
    }

    /**
     * @dev calculate bonus pages
     */
    function calculateBonusPages(uint256 amount) public view returns(uint256) {
        uint256 remainder = 1;
        if (maxPages > claimedPages) {
            remainder = maxPages-claimedPages;
        }
        return amount*remainder/(maxPages*3);
    }

    /**
     * @dev calculate minimum number of pages to get one bonus page
     */
    function pagesPerBonus() public view returns(uint256) {
        uint256 remainder = 1;
        if (maxPages > claimedPages) {
            remainder = maxPages-claimedPages;
        }
        return (100*3*maxPages)/remainder+1;
    }

    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        require(claimedPages == maxPages, "Transfer locked");
        super._safeTransferFrom(from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(claimedPages == maxPages, "Transfer locked");
        super._safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

}