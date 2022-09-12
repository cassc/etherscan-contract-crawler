// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface IRandomizer {
	function random(
		uint256 from,
		uint256 to,
		uint256 salty
	) external view returns (uint256);
}

interface ITOKE {
	function mint(address to, uint256 amount) external;

	function burn(address from, uint256 amount) external;

	function updateOriginAccess() external;

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);
}

interface ISTAC {
	function ownerOf(uint256 tokenId) external view returns (address owner);

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes calldata data
	) external;

	function getTokenTraits(uint256 tokenId) external view returns (bool, uint256);
}

contract TheGrowOperationV2 is Ownable, IERC721Receiver, ReentrancyGuard {
	uint8 public constant MAX_ALPHA = 10;
	uint256 public ALPHA_RATIO = 1000; //can ajust the alpha ratio of gains per alpha level if needed

	//store a stake's token, owner, and earning values
	struct Stake {
		uint256 tokenId;
		uint256 value;
		address owner;
	}

	event TokenStaked(address indexed owner, uint256 indexed tokenId, uint256 value);
	event FedApeClaimed(uint256 indexed tokenId, uint256 earned, bool unstaked);
	event StonedApeClaimed(uint256 indexed tokenId, uint256 earned, bool unstaked);

	// reference to the STAC NFT contract
	ISTAC public stac;
	ITOKE public toke;
	IRandomizer randomizer;

	address private devWallet;

	// maps tokenId to stake
	mapping(uint256 => Stake) public GrowOperation;

	// maps alpha to all Ape stakes
	mapping(uint256 => Stake[]) public dea;

	// tracks location of each Apes in DEA
	mapping(uint256 => uint256) public deaIndices;

	// total alpha scores staked
	uint256 public totalAlphaStaked = 0;
	// any rewards dialphaibuted when no Fed Apes are staked

	uint256 public unaccountedRewards = 0;

	// amount of $TOKE due for each alpha point staked
	uint256 public TokePerAlpha = 0;

	// Stoned Ape earn $TOKE per day
	uint256 public DAILY_TOKE_RATE = 10000 ether;

	// Stoned Pets earn $TOKE per day
	uint256 public  PETS_DAILY_TOKE_RATE = 2000 ether;

	// Pets start and end tokenId
	uint256 public petsStartTokenId = 7500;
	uint256 public petsEndTokenId = 10000;

	// Stoned Ape must have 2 days worth of $TOKE to unstake or else it's too cold
	uint256 public  MINIMUM_TO_EXIT = 2 days;

	// Fed Apes take a 20% tax on all $TOKE claimed
	uint256 public constant TOKE_CLAIM_TAX_PERCENTAGE = 20;

	// there will only ever be (roughly) 6 billion $TOKE earned through staking
	uint256 public MAXIMUM_GLOBAL_TOKE = 4200000000 ether;

	// amount of $TOKE earned so far
	uint256 public totalTOKEEarned;
	// number of Stoned Apes staked in the Grow Operation
	uint256 public totalStonedApesStaked;
	// the last time $TOKE was claimed
	uint256 public lastClaimTimestamp;

	// start of stake time
	uint256 public stakeStartTime = block.timestamp - 1;

	// emergency rescue to allow unstaking without any checks but without $TOKE
	bool public rescueEnabled = false;

	modifier onlyDev() {
		require(msg.sender == devWallet, "only dev");
		_;
	}

	constructor() {
		devWallet = msg.sender;
	}


	/** STAKING */

	/*
	 * adds Fed Ape and Stoned Ape to the Grow Operation
	 * requires allowance
	 * @param tokenId the ID of the Fed Ape or Stoned Ape to stake
	 */
	function stake(uint256[] calldata tokenIds) external nonReentrant {
		require(block.timestamp > stakeStartTime, "not live");

		for (uint256 i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];
			require(stac.ownerOf(tokenId) == msg.sender, "msg.sender not owner of tokenID");
			stac.transferFrom(msg.sender, address(this), tokenId);
			if (!isFed(tokenId)) {
				_addApeToGrowOperation(tokenId);
			} else {
				_addFedApeToDEA(tokenId);
			}
		}
	}

	/**
	 * adds a single Ape to the Grow Operation
	 * @param tokenId the ID of the Stoned Ape to add to the Grow Operation
	 */
	function _addApeToGrowOperation(uint256 tokenId) internal _updateEarnings {
		GrowOperation[tokenId] = Stake({ owner: msg.sender, tokenId: tokenId, value: block.timestamp });
		totalStonedApesStaked += 1;
		emit TokenStaked(msg.sender, tokenId, block.timestamp);
	}

	/**
	 * adds a single Fed Ape to the DEA
	 * @param tokenId the ID of the Fed Ape to add to the DEA
	 */
	function _addFedApeToDEA(uint256 tokenId) internal {
		uint256 alpha = _alphaForApe(tokenId);
		totalAlphaStaked += alpha;
		deaIndices[tokenId] = dea[alpha].length; // Store the location of the Fed Ape in the DEA
		dea[alpha].push(Stake({ owner: msg.sender, tokenId: tokenId, value: TokePerAlpha })); // Add the Fed Ape to the DEA
		emit TokenStaked(msg.sender, tokenId, TokePerAlpha);
	}

	/** CLAIMING / UNSTAKING */

	/**
	 * realize $TOKE earnings and optionally unstake tokens from the Grow Operation / DEA
	 * to unstake an Ape it will require it has 2 days worth of $TOKE unclaimed
	 * @param tokenIds the IDs of the tokens to claim earnings from
	 * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
	 */
	function claim(uint256[] calldata tokenIds, bool unstake) external _updateEarnings nonReentrant {
		uint256 owed = 0;
		for (uint256 i = 0; i < tokenIds.length; i++) {
			if (!isFed(tokenIds[i])) {
				//Stoned Ape pay Stoned Ape tax
				owed += _claimStonedApeFromGrowOperation(tokenIds[i], unstake);
			} else {
				//Stoned Ape realise earnings
				owed += _claimFedApeFromDEA(tokenIds[i], unstake);
			}
		}
		toke.updateOriginAccess();
		if (owed != 0) {
			toke.mint(msg.sender, owed);
		}
	}

	/**
	 * realize $TOKE earnings for a single Stoned Ape and optionally unstake it
	 * if not unstaking, pay a 20% tax to the staked Fed Apes
	 * if unstaking, there is a 50% chance all $TOKE is stolen
	 * @param tokenId the ID of the Stoned Ape to claim earnings from
	 * @param unstake whether or not to unstake the Stoned Ape
	 * @return owed - the amount of $TOKE earned
	 */
	function _claimStonedApeFromGrowOperation(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
		Stake memory _stake = GrowOperation[tokenId];
		require(_stake.owner == msg.sender, "msg.sender not stake.owner");
		require(
			!(unstake && block.timestamp - _stake.value < MINIMUM_TO_EXIT),
			"block.timestamp - stake.value < MINIMUM_TO_EXIT"
		);
		
		owed = getOwedToke(tokenId);

		if (unstake) {
			_payStonedApeTax((owed * TOKE_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked Feds
			owed = (owed * (100 - TOKE_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Stoned Ape owner

			stac.safeTransferFrom(address(this), msg.sender, tokenId, ""); // send back Stoned Ape
			delete GrowOperation[tokenId];
			totalStonedApesStaked -= 1;
		} else {
			_payStonedApeTax((owed * TOKE_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked Feds
			owed = (owed * (100 - TOKE_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Stoned Ape owner
			GrowOperation[tokenId] = Stake({
				owner: msg.sender,
				tokenId: uint256(tokenId),
				value: uint256(block.timestamp)
			}); // reset stake
		}
		emit StonedApeClaimed(tokenId, owed, unstake);
	}

	/**
	 * realize $TOKE earnings for a single Stoned Ape and optionally unstake it
	 * Wolves earn $TOKE proportional to their alpha rank
	 * @param tokenId the ID of the Stoned Ape to claim earnings from
	 * @param unstake whether or not to unstake the Stoned Ape
	 * @return owed - the amount of $TOKE earned
	 */
	function _claimFedApeFromDEA(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
		require(stac.ownerOf(tokenId) == address(this), "Fed Ape is not staked in the DEA");
		uint256 alpha = _alphaForApe(tokenId);
		Stake memory _stake = dea[alpha][deaIndices[tokenId]];
		require(_stake.owner == msg.sender, "msg.sender is not stake.owner");
		owed = getOwedToke(tokenId);
		if (unstake) {
			totalAlphaStaked -= alpha; // Remove alpha from total staked
			stac.safeTransferFrom(address(this), msg.sender, tokenId, ""); // Send back Fed Ape
			Stake memory lastStake = dea[alpha][dea[alpha].length - 1];
			dea[alpha][deaIndices[tokenId]] = lastStake; // Shuffle last Fed Ape to current position
			deaIndices[lastStake.tokenId] = deaIndices[tokenId];
			dea[alpha].pop(); // Remove duplicate
			delete deaIndices[tokenId]; // Delete old mapping
		} else {
			dea[alpha][deaIndices[tokenId]] = Stake({
				owner: msg.sender,
				tokenId: uint256(tokenId),
				value: uint256(TokePerAlpha)
			}); // reset stake
		}
		emit FedApeClaimed(tokenId, owed, unstake);
	}
	
	/**
	 * emergency unstake tokens
	 * @param tokenIds the IDs of the tokens to claim earnings from
	 */
	function rescue(uint256[] calldata tokenIds) external nonReentrant {
		require(rescueEnabled, "RESCUE DISABLED");
		uint256 tokenId;
		Stake memory _stake;
		Stake memory lastStake;
		uint256 alpha;
		for (uint256 i = 0; i < tokenIds.length; i++) {
			tokenId = tokenIds[i];
			if (!isFed(tokenId)) {
				_stake = GrowOperation[tokenId];
				require(_stake.owner == msg.sender, "msg.sender is not stake.owner");
				stac.safeTransferFrom(address(this), msg.sender, tokenId, ""); // send back Ape
				delete GrowOperation[tokenId];
				totalStonedApesStaked -= 1;
				emit StonedApeClaimed(tokenId, 0, true);
			} else {
				alpha = _alphaForApe(tokenId);
				_stake = dea[alpha][deaIndices[tokenId]];
				require(_stake.owner == msg.sender, "msg.sender is not stake.owner");
				totalAlphaStaked -= alpha; // Remove alpha from total staked
				stac.safeTransferFrom(address(this), msg.sender, tokenId, ""); // Send back Ape
				lastStake = dea[alpha][dea[alpha].length - 1];
				dea[alpha][deaIndices[tokenId]] = lastStake; // Shuffle last Ape to current position
				deaIndices[lastStake.tokenId] = deaIndices[tokenId];
				dea[alpha].pop(); // Remove duplicate
				delete deaIndices[tokenId]; // Delete old mapping
				emit FedApeClaimed(tokenId, 0, true);
			}
		}
	}

	/** ACCOUNTING */

	/**
	 * add $TOKE to claimable pot for the DEA
	 * @param amount $TOKE to add to the pot
	 */
	function _payStonedApeTax(uint256 amount) internal {
		if (totalAlphaStaked == 0) {
			// if there's no staked wolves
			unaccountedRewards += amount; // keep track of $TOKE due to wolves
			return;
		}
		// makes sure to include any unaccounted $TOKE
		TokePerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
		unaccountedRewards = 0;
	}

	/**
	 * tracks $TOKE earnings to ensure it stops once 2.4 billion is eclipsed
	 */
	modifier _updateEarnings() {
		if (totalTOKEEarned < MAXIMUM_GLOBAL_TOKE) {
			totalTOKEEarned +=
				((block.timestamp - lastClaimTimestamp) * totalStonedApesStaked * DAILY_TOKE_RATE) /
				1 days;
			lastClaimTimestamp = block.timestamp;
		}
		_;
	}

	/** ADMIN */

	/**
	 * allows owner to enable "rescue mode"
	 * simplifies accounting, prioritizes tokens out in emergency
	 */
	function setMinimumToExit(uint256 _amount) external onlyOwner {
		MINIMUM_TO_EXIT = _amount;
	}

    function setMaximumToke(uint256 _max) external onlyOwner {
        MAXIMUM_GLOBAL_TOKE = _max;
    }

	function setStakeStartTime(uint256 newTime) external onlyOwner {
		stakeStartTime = newTime;
	}

	function setDailyTokeRate(uint256 _newRate) external onlyOwner {
		DAILY_TOKE_RATE = _newRate;
	}

	function setPetsDailyTokeRate(uint256 _newRate) external onlyOwner {
		PETS_DAILY_TOKE_RATE = _newRate;
	}
	
	function setPetsStartTokenId(uint256 _tokenId) external onlyOwner {
		petsStartTokenId = _tokenId;
	}

	function setPetsEndTokenId(uint256 _tokenId) external onlyOwner {
		petsEndTokenId = _tokenId;
	}

	function setRescueEnabled(bool _enabled) external onlyDev {
		rescueEnabled = _enabled;
	}

	function setToke(address payable _toke) external onlyOwner {
		toke = ITOKE(_toke);
	}

	function setSTAC(address _stac) external onlyOwner {
		stac = ISTAC(_stac);
	}

	function setRandomizer(address _newRandomizer) external onlyOwner {
		randomizer = IRandomizer(_newRandomizer);
	}

	//if needed, economy tweaks
	function setalphaRatio(uint256 _newRatio) external onlyDev {
		ALPHA_RATIO = _newRatio;
	}

	/** READ ONLY */
	function isFed(uint256 tokenId) public view returns (bool _isFed) {
		(_isFed, ) = stac.getTokenTraits(tokenId);
		if(isPet(tokenId) && _isFed) {
			_isFed = false;
		}
	}

	function isPet(uint256 tokenId) public view returns (bool _isPet) {
		_isPet = (tokenId >= petsStartTokenId && tokenId <= petsEndTokenId);
	}

	/**
	 * gets the alphaengh score for a Stoned Ape (higher is better)
	 * @param tokenId the ID of the Stoned Ape to get the alpha score for
	 * @return the alpha score of the Stoned Ape
	 */
	function _alphaForApe(uint256 tokenId) internal view returns (uint256) {
		(, uint256 alphaIndex) = stac.getTokenTraits(tokenId);
		(tokenId);
		return alphaIndex; // higher is better
	}

	/**
	 * Chooses a random Fed Ape when a newly minted token is stolen
	 * @param seed a random value to choose a Stoned Ape from
	 * @return the owner of the randomly selected Fed Ape
	 */
	function randomFedApeOwner(uint256 seed) external view returns (address) {
		if (totalAlphaStaked == 0) return address(0x0);
		uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
		uint256 cumulative;
		seed >>= 32;
		// loop through each bucket of Feds with the same alpha score
		for (uint256 i = 1; i <= MAX_ALPHA; i++) {
			cumulative += dea[i].length * i;
			// if the value is not inside of that bucket, keep going
			if (bucket >= cumulative) continue;
			// get the address of a random Fed Ape with that alpha score
			return dea[i][seed % dea[i].length].owner;
		}
		return address(0x0);
	}

	/**
	 * Get owed $TOKE from staked tokenId
	 * @param tokenId staked token id
	 * @return owed in $TOKE
	 */
	function getOwedToke(uint256 tokenId) public view returns (uint256 owed) {
		require(stac.ownerOf(tokenId) == address(this), "Token is not staked.");

		Stake memory _stake = GrowOperation[tokenId]; // default to Grow Operation

		// for each Ape
		if (!isFed(tokenId)) {
			if (totalTOKEEarned < MAXIMUM_GLOBAL_TOKE && !isPet(tokenId)) {
				owed = ((block.timestamp - _stake.value) * DAILY_TOKE_RATE) / 1 days;
			} 
			else if (totalTOKEEarned < MAXIMUM_GLOBAL_TOKE && isPet(tokenId)) {
				owed = ((block.timestamp - _stake.value) * PETS_DAILY_TOKE_RATE) / 1 days;
			}
			else if (_stake.value > lastClaimTimestamp) {
				owed = 0; // $TOKE production stopped already
			} else {
				owed = ((lastClaimTimestamp - _stake.value) * DAILY_TOKE_RATE) / 1 days; // stop earning additional $TOKE if it's all been earned
			}

			return owed;
		}

		// for Fed Ape
		uint256 alpha = _alphaForApe(tokenId);
		_stake = dea[alpha][deaIndices[tokenId]];

		owed = ((alpha * ALPHA_RATIO) / 1000) * (TokePerAlpha - _stake.value); // Calculate portion of tokens based on alpha

		return owed;
	}

	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		return IERC721Receiver.onERC721Received.selector;
	}

	// withdrawal ETH (not used)
	function withdraw() external {
		uint256 totalBalance = address(this).balance;
		uint256 devFee = _calcPercentage(totalBalance, 500);
		payable(owner()).transfer(totalBalance - devFee);
		payable(devWallet).transfer(devFee);
	}

	function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	//300 = 3%, 1 = 0.01%
	function _calcPercentage(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
		require(basisPoints >= 0);
		return (amount * basisPoints) / 10000;
	}
}