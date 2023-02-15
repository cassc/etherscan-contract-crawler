//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {GameMainFacet} from "./GameMainFacet.sol";
import {GameInternalFacet} from "./GameInternalFacet.sol";
import "./LibStorage.sol";
import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import {ERC1155DInternal} from "./ERC1155D/ERC1155DInternal.sol";

contract GameOpenEditionFacet is UsingDiamondOwner, WithStorage, ReentrancyGuard, ERC1155DInternal, GameInternalFacet {
	event OpenEditionMinted(address indexed minter, uint64 amount);
	
	function mintOpenEdition(uint64 amount) external payable nonReentrant {
		require(openEditionStarted(), "BabylonGameOpenEditionFacet: Open edition has not started yet");
		require(!openEditionEnded(), "BabylonGameOpenEditionFacet: Open edition has ended");
		require(oes().pricePerToken * amount == msg.value, "BabylonGameOpenEditionFacet: Wrong amount of ETH sent");
        require(!oes().paused, "BabylonGameOpenEditionFacet: Open edition is paused");
		
		_mint(msg.sender, slugToTokenId(oes().tokenSlug), amount, "");

		oes().totalMinted += amount;
		emit OpenEditionMinted(msg.sender, amount);
	}
	
	function startOpenEdition(uint64 startTime, uint64 duration, uint pricePerToken, string calldata tokenSlug) external onlyRole(ADMIN) {
		require(!openEditionStarted() || openEditionEnded(), "BabylonGameOpenEditionFacet: Open edition already started");
		require(findIdBySlugOrRevert(tokenSlug) > 0, "BabylonGameOpenEditionFacet: Token slug not found");
		require(duration > 10 minutes, "BabylonGameOpenEditionFacet: Duration must be at least 10 minutes");
        require(startTime == 0 || startTime >= block.timestamp, "BabylonGameOpenEditionFacet: Start time must be in the future");
        require(pricePerToken > 0, "BabylonGameOpenEditionFacet: Price per token must be greater than 0");
		
		oes().startTime = startTime > 0 ? startTime : uint64(block.timestamp);
		oes().duration = duration;
		oes().pricePerToken = pricePerToken;
		oes().tokenSlug = tokenSlug;
		oes().totalMinted = 0;
		oes().paused = false;
	}
    
    function setOpenEditionPauseState(bool newState) external onlyRole(ADMIN) {
        oes().paused = newState;
    }
	
	function openEditionStarted() public view returns (bool) {
		return oes().startTime != 0 && block.timestamp >= oes().startTime;
	}
    
    function openEditionEnded() public view returns (bool) {
        return openEditionStarted() && block.timestamp > openEditionEndTime();
    }
	
	function openEditionEndTime() public view returns (uint64) {
		return oes().startTime + oes().duration;
	}
	
	function getOpenEditionStruct() external pure returns (GameOpenEditionStorage memory) {
		return oes();
	}
    
    function airDrop(string calldata slug, address[] calldata recipients, uint8[] calldata amounts) external nonReentrant onlyRole(ADMIN) {
        uint id = findIdBySlugOrRevert(slug);
        uint len = recipients.length;
        require(len == amounts.length, "Length mismatch");
        
        for (uint i; i < len; ++i) {
            _mint(recipients[i], id, amounts[i], "");
        }
    }
}