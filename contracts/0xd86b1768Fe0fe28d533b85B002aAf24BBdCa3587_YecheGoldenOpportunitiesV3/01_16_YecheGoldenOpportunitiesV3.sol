// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./../DefaultOperatorFilterer.sol";

contract YecheGoldenOpportunitiesV3 is ERC1155, Ownable, DefaultOperatorFilterer, ERC2981 {
    struct Giveaway {
        uint256 startTime;
        uint256 endTime;
        uint256 maxSupply;
        uint256 currentSupply;
        uint256 numEligibleAnyone;
        string baseURI;
        address[] whitelistedProjects;
        mapping(address => uint256) whitelistedNumEligible;
        bool mintPaused;
    }

    uint96 private royaltyBps = 1000;
    address public split;

    uint256 public numGiveaways;

    mapping(uint256 => Giveaway) public giveaways;
    mapping(uint256 => mapping(address => bool)) private claimedGiveaways;
    mapping(address => bool) private gifters;


    modifier onlyGifter() {
        require(gifters[_msgSender()] || owner() == _msgSender(), "Not a gifter");
        _;
    }

    constructor() ERC1155("") {}

    function addGiveaway(
        uint256 startTime,
        uint256 endTime,
        uint256 numEligibleAnyone,
        uint256 maxSupply,
        string memory baseURI
    ) public onlyOwner {
        require(endTime > startTime, "End time must be after start time");
        require(maxSupply > 0, "Max supply must be greater than 0");

        uint256 giveawayId = numGiveaways;
        Giveaway storage giveaway = giveaways[giveawayId];
        giveaway.numEligibleAnyone = numEligibleAnyone;
        giveaway.startTime = startTime;
        giveaway.endTime = endTime;
        giveaway.maxSupply = maxSupply;
        giveaway.currentSupply = 0;
        giveaway.baseURI = baseURI;

        numGiveaways += 1;
    }

    function setSplitAddress(address _address) public onlyOwner {
        split = _address;
        _setDefaultRoyalty(split, royaltyBps);
    }

    function updateMintPause(uint256 giveawayId, bool paused) public onlyOwner {
        require(giveawayId >= 0 && giveawayId < numGiveaways, "Invalid giveawayId");

        giveaways[giveawayId].mintPaused = paused;
    }

    function updateStartTime(uint256 giveawayId, uint256 newStartTime) public onlyOwner {
        require(giveawayId >= 0 && giveawayId < numGiveaways, "Invalid giveawayId");
        require(newStartTime < giveaways[giveawayId].endTime, "New start time must be before end time");

        giveaways[giveawayId].startTime = newStartTime;
    }

    function updateEndTime(uint256 giveawayId, uint256 newEndTime) public onlyOwner {
        require(giveawayId >= 0 && giveawayId < numGiveaways, "Invalid giveawayId");
        require(newEndTime > giveaways[giveawayId].startTime, "New end time must be after start time");

        giveaways[giveawayId].endTime = newEndTime;
    }

    function updateMaxSupply(uint256 giveawayId, uint256 newMaxSupply) public onlyOwner {
        require(giveawayId >= 0 && giveawayId < numGiveaways, "Invalid giveawayId");
        require(newMaxSupply > giveaways[giveawayId].currentSupply, "New max supply must be greater than current supply");

        giveaways[giveawayId].maxSupply = newMaxSupply;
    }

    function updateBaseURI(uint256 giveawayId, string memory newBaseURI) public onlyOwner {
        require(giveawayId >= 0 && giveawayId < numGiveaways, "Invalid giveawayId");

        giveaways[giveawayId].baseURI = newBaseURI;
    }

    function addWhitelistedProject(uint256 giveawayId, address project, uint256 numEligible) public onlyOwner {
        Giveaway storage giveaway = giveaways[giveawayId];
        giveaway.whitelistedProjects.push(project);
        giveaway.whitelistedNumEligible[project] = numEligible;
    }

    function updateWhitelistedNumEligible(uint256 giveawayId, address project, uint256 numEligible) public onlyOwner {
        require(giveawayId >= 0 && giveawayId < numGiveaways, "Invalid giveawayId");
        require(project != address(0), "Invalid project address");

        bool projectExists = false;
        for (uint256 i = 0; i < giveaways[giveawayId].whitelistedProjects.length; i++) {
            if (giveaways[giveawayId].whitelistedProjects[i] == project) {
                projectExists = true;
                break;
            }
        }

        require(projectExists, "Project not found in the whitelist");

        giveaways[giveawayId].whitelistedNumEligible[project] = numEligible;
    }

    function updateNumEligibleAnyone(uint256 giveawayId, uint256 numEligible) public onlyOwner {
        require(giveawayId >= 0 && giveawayId < numGiveaways, "Invalid giveawayId");

        giveaways[giveawayId].numEligibleAnyone = numEligible;
    }

    function maxEligibleToMint(address wallet, uint256 giveawayId) public view returns (uint256) {
        uint256 maxEligible = giveaways[giveawayId].numEligibleAnyone;

        for(uint256 i = 0; i < giveaways[giveawayId].whitelistedProjects.length; i++) {
            address project = giveaways[giveawayId].whitelistedProjects[i];
            uint256 numEligible = giveaways[giveawayId].whitelistedNumEligible[project];
            uint256 balance = IERC721(project).balanceOf(wallet);

            if(balance > 0 && numEligible > maxEligible) {
                maxEligible = numEligible;
            }
        }

        return maxEligible;
    }

    function mintGiveaway(uint256 giveawayId) public {
        require(giveawayId >= 0 && giveawayId < numGiveaways, "Invalid giveawayId");
        Giveaway storage giveaway = giveaways[giveawayId];
        require(block.timestamp >= giveaway.startTime && block.timestamp <= giveaway.endTime, "Giveaway not active");
        require(!claimedGiveaways[giveawayId][_msgSender()], "Already claimed");
        require(!giveaway.mintPaused, "Minting is paused");

        uint256 maxEligible = maxEligibleToMint(_msgSender(), giveawayId);
        require(maxEligible > 0, "Not eligible for giveaway");
        require(giveaway.currentSupply + maxEligible <= giveaway.maxSupply, "Max supply reached");

        _mint(_msgSender(), giveawayId, maxEligible, "");
        claimedGiveaways[giveawayId][_msgSender()] = true;
        giveaway.currentSupply += maxEligible;
    }

    function addGifter(address gifter) public onlyOwner {
        gifters[gifter] = true;
    }

    function giftGiveaway(uint256 giveawayId, address[] memory recipients) public onlyGifter {
        Giveaway storage giveaway = giveaways[giveawayId];

        uint256 totalRequiredSupply = giveaway.currentSupply + recipients.length;

        require(totalRequiredSupply <= giveaway.maxSupply, "Max supply reached");

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], giveawayId, 1, "");

            giveaway.currentSupply += 1;
        }
    }

    function uri(uint256 giveawayId) public view override returns (string memory) {
        return giveaways[giveawayId].baseURI;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}