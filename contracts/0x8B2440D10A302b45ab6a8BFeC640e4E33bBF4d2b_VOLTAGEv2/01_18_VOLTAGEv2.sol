pragma solidity ^0.8.0;
/**
 * @title VOLTAGE contract
 * @dev ERC20
 */

 /**
 *  SPDX-License-Identifier: UNLICENSED
 */

/*
  \ \
   \ \
  __\ \
  \  __\
   \ \
  __\ \
  \  __\
   \ \
    \ \
     \/   $VOLT'
 */

import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";

interface ISupDucksV2 {
	function balanceOf(address owner) external view returns(uint256);
}

contract VOLTAGEv2 is ERC20PresetMinterPauserUpgradeable () {
	uint256 public FERTILITY_RATE;
	uint256 public START;

	mapping(address => uint256) public rewards;
	mapping(address => uint256) public lastUpdate;

	ISupDucksV2 public SupDucks;
	bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");

	// called on SupDuck transfers
	function updateReward(address from, address to) external {
		require(msg.sender == address(SupDucks));

		if(from != address(0)){
			rewards[from] += getPendingReward(from);
			lastUpdate[from] = block.timestamp;
		}
		if(to != address(0)){
			rewards[to] += getPendingReward(to);
			lastUpdate[to] = block.timestamp;
		}
	}

	function claimReward() external {
		rewards[msg.sender] += getPendingReward(msg.sender);
		_mint(msg.sender, rewards[msg.sender]);
		rewards[msg.sender] = 0;
		lastUpdate[msg.sender] = block.timestamp;
	}

	function spend(address user, uint256 amount) external {
		require(hasRole(SPENDER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have spender role to spend tokens");
		_burn(user, amount);
	}

	function getTotalClaimable(address user) external view returns(uint256) {
		return rewards[user] + getPendingReward(user);
	}

	function getPendingReward(address user) internal view returns(uint256) {
		if (infertile) {
			if (lastUpdate[user] > STOP) return 0;
			return SupDucks.balanceOf(user) * FERTILITY_RATE * (STOP - (lastUpdate[user] >= START ? lastUpdate[user] : START));
		}
		else {
			return SupDucks.balanceOf(user) * FERTILITY_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START));
		}
	}

	function setSupDucks(address supAddy) external {
		require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to set SupDucks addy");
		SupDucks = ISupDucksV2(supAddy);
	}

	function fertilize(uint256 fertility) external {
		require(false, "Deprecated");
		require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to fertilize");
		FERTILITY_RATE = fertility;
	}

	function initialize() initializer public {
		__ERC20PresetMinterPauser_init("VOLTAGE", "VOLT");
		_setupRole(SPENDER_ROLE, _msgSender());

		// ~10 tokens per day 
		FERTILITY_RATE = 115740740740740;
		START = block.timestamp - (10 days);
    }

	uint256 public STOP;
	bool infertile;
	
	function stopDistribution() external {
		require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role");
		require(!infertile, "Must not be already stopped");
		STOP = block.timestamp;
		infertile = true;
	}
}