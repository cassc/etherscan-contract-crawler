// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// ==========================================
// |            ____  _ __       __         |
// |           / __ \(_) /______/ /_        |
// |          / /_/ / / __/ ___/ __ \       |
// |         / ____/ / /_/ /__/ / / /       |
// |        /_/   /_/\__/\___/_/ /_/        |
// |                                        |
// ==========================================
// ================= Pitch ==================
// ==========================================

// Authored by Pitch Research: [email protected]

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol"; 

contract GaugeIncentivesStash is OwnableUpgradeable, UUPSUpgradeable {
	using SafeERC20Upgradeable for IERC20Upgradeable;

	// Claim structure
	struct claimData {
		address token;
		uint256 index;
		uint256 amount;
		bytes32[] merkleProof;
	}

	// Refund structure
	struct refundData {
		address account;
		uint256 amount;
	}

	// Constants
	// Denominates weights, bps to %
	uint256 public constant DENOMINATOR = 10000;

	// Contract parameters
	address public feeAddress;
	uint256 public platformFee;

	// Stash state
	// Merkle root for each reward token
	mapping(address => bytes32) public merkleRoot;

	// Current claim period for each reward token
	mapping(address => uint256) public claimPeriod;

	// Packed array of boolean values to determine whether reward is claimed
	mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private claimedBitMap;

	// Reward Blacklist
	// Globally blacklisted addresses
	address[] public globalBlacklistedAddresses;

	// Addresses blacklisted for individual gauges
	mapping(address => address[]) public gaugeBlacklistedAddresses;

	// Token whitelist
	mapping(address => bool) public tokenWhitelist;

	/* =========== Initializer =========== */
	function initialize(address _feeAddress, uint256 _platformFee) public initializer {
		__Context_init_unchained();
		__Ownable_init_unchained();
		feeAddress = _feeAddress;
		platformFee = _platformFee;
	}

	/* =========== Public and External Functions =========== */
	function addReward(address _gauge, address _token, uint _amount, uint _pricePerToken) external returns (bool) {
		require(_amount > 0, "Reward amount must be greater than zero");
		require(_pricePerToken > 0, "Price per token must be greater than zero");
		require(tokenWhitelist[_token] == true, "Reward token is unlisted");

		IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);

		emit RewardAdded(_gauge, _token, msg.sender, _amount, _pricePerToken, block.timestamp);
		return true;
	}

	function isClaimed(address _token, uint256 _index) public view returns (bool) {
		uint256 claimedWordIndex = _index / 256;
		uint256 claimedBitIndex = _index % 256;
		uint256 claimedWord = claimedBitMap[_token][claimPeriod[_token]][claimedWordIndex];
		uint256 mask = (1 << claimedBitIndex);

		return claimedWord & mask == mask;
	}

	function claim(address _token, uint256 _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof) public {
		require(merkleRoot[_token] != 0, "Claims are frozen");
		require(!isClaimed(_token, _index), "Drop already claimed");

		// Verify the merkle proof
		bytes32 node = keccak256(abi.encodePacked(_index, _account, _amount));
		require(MerkleProof.verify(_merkleProof, merkleRoot[_token], node), "Invalid merkle proof");

		_setClaimed(_token, _index);
		IERC20Upgradeable(_token).safeTransfer(_account, _amount);

		emit RewardClaimed(_token, _account, _index, _amount, claimPeriod[_token]);
	}

	function claimMulti(address _account, claimData[] calldata claims) external {
		for (uint256 i = 0; i < claims.length; i++) {
			claim(claims[i].token, claims[i].index, _account, claims[i].amount, claims[i].merkleProof);
		}
	}

	/* =========== Private and Internal Functions =========== */
	function _setClaimed(address _token, uint256 _index) private {
		uint256 claimedWordIndex = _index / 256;
		uint256 claimedBitIndex = _index % 256;
		claimedBitMap[_token][claimPeriod[_token]][claimedWordIndex] = claimedBitMap[_token][claimPeriod[_token]][claimedWordIndex] | (1 << claimedBitIndex);
	}

	/* =========== Owner Only Functions =========== */
	// Used to upgrade contract
	function _authorizeUpgrade(address) internal override onlyOwner {}

	// Manage merkle root and refund
	function updateMerkleRoot(address _token, bytes32 _merkleRoot, uint256 _periodFee, refundData[] memory _refunds) public onlyOwner {
		// Increment the claim period
		claimPeriod[_token] += 1;

		// Set the new merkle root
		merkleRoot[_token] = _merkleRoot;

		for (uint256 i = 0; i < _refunds.length; i++) {
			IERC20Upgradeable(_token).safeTransfer(_refunds[i].account, _refunds[i].amount);
		}

		IERC20Upgradeable(_token).safeTransfer(feeAddress, _periodFee);

		emit MerkleRootUpdated(_token, _merkleRoot, claimPeriod[_token]);
	}


	// Manage token whitelist
	function listTokens(address[] memory _tokensToList) public onlyOwner {
		for (uint256 i = 0; i < _tokensToList.length; i++) {
			tokenWhitelist[_tokensToList[i]] = true;
			emit TokenListed(_tokensToList[i]);
		}
	}

	function unlistTokens(address[] memory _tokensToUnlist) public onlyOwner {
		for (uint256 i = 0; i < _tokensToUnlist.length; i++) {
			tokenWhitelist[_tokensToUnlist[i]] = false;
			emit TokenUnlisted(_tokensToUnlist[i]);
		}
	}

	// Manage blacklist
	function blacklistAddressGlobal(address _addressToBlacklist) external onlyOwner {
		globalBlacklistedAddresses.push(_addressToBlacklist);
	}

	function blacklistAddressGauge(address _gauge, address _addressToBlacklist) external onlyOwner {
		gaugeBlacklistedAddresses[_gauge].push(_addressToBlacklist);
	}

	function removeBlacklistAddressGlobal(address _addressToRemove) external onlyOwner {
		uint blacklistLength = globalBlacklistedAddresses.length;
		
		for (uint i = 0; i < blacklistLength; i++) {
			if (globalBlacklistedAddresses[i] == _addressToRemove) {
				globalBlacklistedAddresses[i] = globalBlacklistedAddresses[blacklistLength - 1];
				globalBlacklistedAddresses.pop();
				return;
			}
		}
	}

	function removeBlacklistAddressGauge(address _gauge, address _addressToRemove) external onlyOwner {
		uint blacklistLength = gaugeBlacklistedAddresses[_gauge].length;
		
		for (uint i = 0; i < blacklistLength; i++) {
			if (gaugeBlacklistedAddresses[_gauge][i] == _addressToRemove) {
				gaugeBlacklistedAddresses[_gauge][i] = gaugeBlacklistedAddresses[_gauge][blacklistLength - 1];
				gaugeBlacklistedAddresses[_gauge].pop();
				return;
			}
		}
	}

	/* =========== Events =========== */
	event MerkleRootUpdated(address indexed token, bytes32 indexed merkleRoot, uint256 indexed tokenClaimPeriod);
	event RewardClaimed(address indexed token, address indexed account, uint256 index, uint256 amount, uint256 indexed tokenClaimPeriod);
	event RewardAdded(address indexed gauge, address indexed token, address sender, uint256 amount, uint256 pricePerToken, uint256 time);
	event TokenListed(address token);
	event TokenUnlisted(address token);
}