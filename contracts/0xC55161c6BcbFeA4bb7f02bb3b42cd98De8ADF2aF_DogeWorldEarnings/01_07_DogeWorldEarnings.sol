// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDogeWorld.sol";
import "./interfaces/ITOPIA.sol";
import "./interfaces/IHub.sol";

contract DogeWorldEarnings is Ownable, ReentrancyGuard {

	ITOPIA public TOPIAToken;
    IHub public HUB;
    IDogeWorld public DogeWorld;

	uint256 public dogAdjuster = 2500;
	uint256 public veterinarianAdjuster = 833;

	struct Earnings {
		uint256 unadjustedClaimed;
		uint256 adjustedClaimed;
	}
	mapping(uint16 => Earnings) public dog;
	mapping(uint16 => Earnings) public veterinarian;
	mapping(uint16 => uint8) public genesisType;

	uint256 public totalTOPIAEarned;

	event DogClaimed(uint256 indexed tokenId, uint256 earned);
	event VeterinarianClaimed(uint256 indexed tokenId, uint256 earned);

	constructor(address _topia, address _hub, address _dogeworld) {
    	TOPIAToken = ITOPIA(_topia);
    	HUB = IHub(_hub);
    	DogeWorld = IDogeWorld(_dogeworld);
    }

    function updateContracts(address _topia, address _hub, address _dogeworld) external onlyOwner {
    	TOPIAToken = ITOPIA(_topia);
    	HUB = IHub(_hub);
    	DogeWorld = IDogeWorld(_dogeworld);
    }

    function updateAdjusters(uint256 _dog, uint256 _veterinarian) external onlyOwner {
    	dogAdjuster = _dog;
    	veterinarianAdjuster = _veterinarian;
    }

    // mass update the nftType mapping
    function setBatchNFTType(uint16[] calldata tokenIds, uint8[] calldata _types) external onlyOwner {
        require(tokenIds.length == _types.length , " _idNumbers.length != _types.length: Each token ID must have exactly 1 corresponding type!");
        for (uint16 i = 0; i < tokenIds.length; i++) {
            require(_types[i] == 2 || _types[i] == 3, "Invalid nft type - must be 2 or 3");
            genesisType[tokenIds[i]] = _types[i];
        }
    }

	function claimMany(uint16[] calldata tokenIds) external nonReentrant {
		require(tx.origin == msg.sender, "Only EOA");
		uint256 owed = 0;
		for(uint i = 0; i < tokenIds.length; i++) {
			if (genesisType[tokenIds[i]] == 2) {
				owed += claimDogEarnings(tokenIds[i]);
			} else if (genesisType[tokenIds[i]] == 3) {
				owed += claimVeterinarianEarnings(tokenIds[i]);
			} else if (genesisType[tokenIds[i]] == 0) {
				revert('invalid token id');
			}
		}
		totalTOPIAEarned += owed;
	    TOPIAToken.mint(msg.sender, owed);
	    HUB.emitTopiaClaimed(msg.sender, owed);
	}

	function claimDogEarnings(uint16 _tokenId) internal returns (uint256) {
		uint256 unclaimed = DogeWorld.getUnclaimedGenesis(_tokenId);
		if(unclaimed <= dog[_tokenId].unadjustedClaimed) { return 0; }
		uint256 adjustedEarnings = unclaimed - dog[_tokenId].unadjustedClaimed;
		uint256 owed = adjustedEarnings * dogAdjuster / 100;	
		dog[_tokenId].unadjustedClaimed += unclaimed;
		dog[_tokenId].adjustedClaimed += owed;
		emit DogClaimed(_tokenId, owed);
		return owed;
	}

	function claimVeterinarianEarnings(uint16 _tokenId) internal returns (uint256) {
		uint256 unclaimed = DogeWorld.getUnclaimedGenesis(_tokenId);
		if(unclaimed <= veterinarian[_tokenId].unadjustedClaimed) { return 0; }
		uint256 adjustedEarnings = unclaimed - veterinarian[_tokenId].unadjustedClaimed;
		uint256 owed = adjustedEarnings * veterinarianAdjuster / 100;	
		veterinarian[_tokenId].unadjustedClaimed += unclaimed;
		veterinarian[_tokenId].adjustedClaimed += owed;
		emit VeterinarianClaimed(_tokenId, owed);
		return owed;
	}

	function getUnclaimedGenesis(uint16 _tokenId) external view returns (uint256) {
		uint256 unclaimed = DogeWorld.getUnclaimedGenesis(_tokenId);
		if(genesisType[_tokenId] == 2) {
			if(unclaimed <= dog[_tokenId].unadjustedClaimed) { return 0; }
			uint256 adjustedEarnings = unclaimed - dog[_tokenId].unadjustedClaimed;
			uint256 owed = adjustedEarnings * dogAdjuster / 100;	
			return owed;
		} else if(genesisType[_tokenId] == 3) {
			if(unclaimed <= veterinarian[_tokenId].unadjustedClaimed) { return 0; }
			uint256 adjustedEarnings = unclaimed - veterinarian[_tokenId].unadjustedClaimed;
			uint256 owed = adjustedEarnings * veterinarianAdjuster / 100;	
			return owed;
		} else {
			return 0;
		}
	}
}