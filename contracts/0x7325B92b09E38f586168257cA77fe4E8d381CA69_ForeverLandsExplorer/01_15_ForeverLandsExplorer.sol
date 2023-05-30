//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @author: Paulius Uza - Upheaver

import "./AdminControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "hardhat/console.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   ______                            _                     _     
//   |  ___|                          | |                   | |    
//   | |_ ___  _ __ _____   _____ _ __| |     __ _ _ __   __| |___ 
//   |  _/ _ \| '__/ _ \ \ / / _ \ '__| |    / _` | '_ \ / _` / __|
//   | || (_) | | |  __/\ V /  __/ |  | |___| (_| | | | | (_| \__ \
//   \_| \___/|_|  \___| \_/ \___|_|  \_____/\__,_|_| |_|\__,_|___/ . xyz
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract ForeverLandsExplorer is ReentrancyGuard, AdminControl, ERC1155 {

    struct Reward {
        address recipient;
        uint256 amount;
    }
    
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;

    uint256 constant private _TOKEN_ID = 1;
    uint256 constant public FULL_PRICE = 160000000000000000;
    uint256 constant public PRESALE_PRICE = 128000000000000000;

    uint256 constant public MAX_EXPLORERS = 65536;
    uint256 constant public FOUNDERS_RESERVE = 1024;
    uint256 constant public SHARDS_RESERVE = 3360;
    uint256 constant public MAX_EXPLORERS_PRESALE = 16384;
    uint256 constant public MAX_EXPLORERS_CLAIMABLE = MAX_EXPLORERS - SHARDS_RESERVE - FOUNDERS_RESERVE;

    bool public publicSaleActive;
    bool public presaleActive;

    uint256 public claimedExplorers;
    uint256 public publicActiveTimestamp;
    uint256 public publicEndTimestamp;
    uint256 public presaleActiveTimestamp;
    uint256 public presaleEndTimestamp;

    address public partnerContract;
    uint256 public partnerTokenId;
    uint256 public partnerThreshold;

    event ActivatePresale();
    event DeactivatePresale();
    event ActivatePublicSale();
    event DeactivatePublicSale();

    constructor() ERC1155("https://www.foreverlands.xyz/api/explorer-mainnet/{id}.json") {
        console.log("Deploying ForeverLands Explorer");
    }

    /**
     * @dev Activate presale
     */
    function activatePresale(uint256 startTime, uint256 presaleInterval, address partnerContract_, uint256 partnerTokenId_, uint256 partnerThreshold_) external adminRequired {
        require(!presaleActive, "Already active");
        presaleActive = true;
        presaleActiveTimestamp = startTime;
        presaleEndTimestamp = presaleActiveTimestamp+presaleInterval;
        partnerContract = partnerContract_;
        partnerTokenId = partnerTokenId_;
        partnerThreshold = partnerThreshold_;
        emit ActivatePresale();
    }

    /**
     * @dev Activate public sale
     */
    function activatePublicSale(uint256 startTime, uint256 publicSaleInterval) external adminRequired {
        require(!publicSaleActive, "Already active");
        publicSaleActive = true;
        publicActiveTimestamp = startTime;
        publicEndTimestamp = publicActiveTimestamp+publicSaleInterval;
        emit ActivatePublicSale();
    }

     /**
     * @dev Claim explorers (main sale)
     */
    function claimExplorers(uint256 amount) external payable nonReentrant {
        require(publicSaleActive && block.timestamp >= publicActiveTimestamp && block.timestamp <= publicEndTimestamp, "Inactive");

        // Can only claim 500 at a time
        require(amount <= 500, "Too many requested");
        claimedExplorers += amount;

        require(claimedExplorers <= MAX_EXPLORERS_CLAIMABLE, "Too many requested");
        require(amount > 0 && msg.value == amount*FULL_PRICE, "Invalid eth sent");
        _mint(msg.sender, _TOKEN_ID, amount, "");
    }

    /**
     * @dev Claim explorers (pre-sale)
     */
    function claimExplorersPresale(uint256 amount) external payable nonReentrant {
        require(presaleActive && block.timestamp >= presaleActiveTimestamp && block.timestamp <= presaleEndTimestamp, "Inactive");

        // Check if user has whitelist tokens
        require(IERC1155(partnerContract).balanceOf(msg.sender, partnerTokenId) >= partnerThreshold, "Not eligible for the presale");

        // Can only claim 500 at a time
        require(amount <= 500, "Too many requested");
        claimedExplorers += amount;

        require(claimedExplorers <= MAX_EXPLORERS_PRESALE, "Too many requested");
        require(amount > 0 && msg.value == amount*PRESALE_PRICE, "Invalid eth sent");
        _mint(msg.sender, _TOKEN_ID, amount, "");
    }

    /**
     * @dev Distribute explorers. Only available after public sale completion
     */
     
    function distributeExplorers(Reward[] memory rewards) external adminRequired {
        require(publicEndTimestamp > 0 && block.timestamp > publicEndTimestamp, "Can run only after sale end");
        for (uint i = 0; i < rewards.length; i++) {
            claimedExplorers += rewards[i].amount;
            require(claimedExplorers <= MAX_EXPLORERS, "Too many requested");
            _mint(rewards[i].recipient, _TOKEN_ID, rewards[i].amount, "");
        }
    }

    /**
     * @dev Deactivate presale
     */
    function deactivatePresale() external adminRequired {
        presaleActive = false;
        presaleEndTimestamp = block.timestamp;
        emit DeactivatePresale();
    }

    /**
     * @dev Deactivate public sale
     */
    function deactivatePublicSale() external adminRequired {
        publicSaleActive = false;
        publicEndTimestamp = block.timestamp;
        emit DeactivatePublicSale();
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        require(claimedExplorers == MAX_EXPLORERS_CLAIMABLE, "Transfer locked");
        super._safeTransferFrom(from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(claimedExplorers == MAX_EXPLORERS_CLAIMABLE, "Transfer locked");
        super._safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Change the URI
     */
    function setURI(string memory newuri) external adminRequired {
        _setURI(newuri);
    }

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
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
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