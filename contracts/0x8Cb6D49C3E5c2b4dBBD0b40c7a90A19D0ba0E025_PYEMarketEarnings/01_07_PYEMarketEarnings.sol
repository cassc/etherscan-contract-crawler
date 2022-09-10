// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IPYEMarket.sol";
import "./interfaces/ITOPIA.sol";
import "./interfaces/IHub.sol";

contract PYEMarketEarnings is Ownable, ReentrancyGuard {

	ITOPIA public TOPIAToken;
    IHub public HUB;
    IPYEMarket public PYEMarket;

	uint256 public foodieAdjuster = 222;
	uint256 public shopOwnerAdjuster = 111;

	struct Earnings {
		uint256 unadjustedClaimed;
		uint256 adjustedClaimed;
	}
	mapping(uint16 => Earnings) public foodie;
	mapping(uint16 => Earnings) public shopOwner;
	mapping(uint16 => uint8) public genesisType;

	uint256 public totalTOPIAEarned;

	event FoodieClaimed(uint256 indexed tokenId, uint256 earned);
	event ShopOwnerClaimed(uint256 indexed tokenId, uint256 earned);

	constructor(address _topia, address _hub, address _market) {
    	TOPIAToken = ITOPIA(_topia);
    	HUB = IHub(_hub);
    	PYEMarket = IPYEMarket(_market);
    }

    function updateContracts(address _topia, address _hub, address _market) external onlyOwner {
    	TOPIAToken = ITOPIA(_topia);
    	HUB = IHub(_hub);
    	PYEMarket = IPYEMarket(_market);
    }

    function updateAdjusters(uint256 _foodie, uint256 _shopOwner) external onlyOwner {
    	foodieAdjuster = _foodie;
    	shopOwnerAdjuster = _shopOwner;
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
				owed += claimFoodieEarnings(tokenIds[i]);
			} else if (genesisType[tokenIds[i]] == 3) {
				owed += claimShopOwnerEarnings(tokenIds[i]);
			} else if (genesisType[tokenIds[i]] == 0) {
				revert('invalid token id');
			}
		}
		totalTOPIAEarned += owed;
	    TOPIAToken.mint(msg.sender, owed);
	    HUB.emitTopiaClaimed(msg.sender, owed);
	}

	function claimFoodieEarnings(uint16 _tokenId) internal returns (uint256) {
		uint256 unclaimed = PYEMarket.getUnclaimedGenesis(_tokenId);
		if(unclaimed <= foodie[_tokenId].unadjustedClaimed) { return 0; }
		uint256 adjustedEarnings = unclaimed * foodieAdjuster / 100;
		uint256 owed = adjustedEarnings - foodie[_tokenId].unadjustedClaimed;	
		foodie[_tokenId].unadjustedClaimed += unclaimed;
		foodie[_tokenId].adjustedClaimed += adjustedEarnings;
		emit FoodieClaimed(_tokenId, owed);
		return owed;
	}

	function claimShopOwnerEarnings(uint16 _tokenId) internal returns (uint256) {
		uint256 unclaimed = PYEMarket.getUnclaimedGenesis(_tokenId);
		if(unclaimed <= shopOwner[_tokenId].unadjustedClaimed) { return 0; }
		uint256 adjustedEarnings = unclaimed * shopOwnerAdjuster / 100;
		uint256 owed = adjustedEarnings - shopOwner[_tokenId].unadjustedClaimed;	
		shopOwner[_tokenId].unadjustedClaimed += unclaimed;
		shopOwner[_tokenId].adjustedClaimed += adjustedEarnings;
		emit ShopOwnerClaimed(_tokenId, owed);
		return owed;
	}

	function getUnclaimedGenesis(uint16 _tokenId) external view returns (uint256) {
		uint256 unclaimed = PYEMarket.getUnclaimedGenesis(_tokenId);
		if(genesisType[_tokenId] == 2) {
			if(unclaimed <= foodie[_tokenId].unadjustedClaimed) { return 0; }
			uint256 adjustedEarnings = unclaimed * foodieAdjuster / 100;
			uint256 owed = adjustedEarnings - foodie[_tokenId].unadjustedClaimed;	
			return owed;
		} else if(genesisType[_tokenId] == 3) {
			if(unclaimed <= shopOwner[_tokenId].unadjustedClaimed) { return 0; }
			uint256 adjustedEarnings = unclaimed * shopOwnerAdjuster / 100;
			uint256 owed = adjustedEarnings - shopOwner[_tokenId].unadjustedClaimed;	
			return owed;
		} else {
			return 0;
		}
	}
}