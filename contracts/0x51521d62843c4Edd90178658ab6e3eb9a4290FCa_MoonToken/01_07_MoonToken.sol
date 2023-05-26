// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAlphieWhales {
    function balanceGenesisWhales(address owner) external view returns(uint256);
}

contract MoonToken is ERC20, Ownable {

    IAlphieWhales public AlphieWhales;

    uint256 constant public GENESIS_BASE_RATE = 5 ether;
    uint256 constant public INITIAL_ISSUANCE = 50 ether;

	// Mon, Feb 3 2032 12:00 AM GMT 
	uint256 constant public END = 1959379200;
    bool private rewardPaused = false;

    uint256 constant INIT_AMOUNT_RESERVE = 57680900 ether;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    mapping(address => bool) public allowedAddresses;

    event RewardClaimed(address indexed _user, uint256 _reward);

    constructor(address whaleAddress, address daoMultiSigWallet) ERC20("Moon", "MOON") {
        AlphieWhales = IAlphieWhales(whaleAddress);

        allowedAddresses[daoMultiSigWallet] = true;        

        _mint(daoMultiSigWallet, INIT_AMOUNT_RESERVE);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

    function updateRewardOnMint(address _user, uint256 _amount) external {
        require(msg.sender == address(AlphieWhales)); // only AlphieWhales contract can call this function
		uint256 time = min(block.timestamp, END);
		uint256 timerUser = lastUpdate[_user];

		if (timerUser > 0) {
			rewards[_user] += getPendingReward(_user) + (_amount * INITIAL_ISSUANCE);
        } else {
			rewards[_user] += _amount * INITIAL_ISSUANCE;
            lastUpdate[_user] = time;
        }
	}
    function updateReward(address from, address to) external {
        require(msg.sender == address(AlphieWhales)); // only AlphieWhales contract can call this function
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
        require(!rewardPaused, "Claiming reward has been paused"); 
        _mint(msg.sender, rewards[msg.sender] + getPendingReward(msg.sender));
        emit RewardClaimed(msg.sender, rewards[msg.sender] + getPendingReward(msg.sender));

        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

    // !ooh
    function claimLaboratoryExperimentRewards(address _address, uint256 _amount) external {
        require(!rewardPaused, "Claiming reward has been paused"); 
        require(allowedAddresses[msg.sender], "Address does not have permission to distrubute tokens");
        _mint(_address, _amount);
    }

    function burn(address _user, uint256 _amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(AlphieWhales), "Address does not have permission to burn");
        _burn(_user, _amount);
    }

    function getTotalClaimable(address _user) external view returns(uint256) {
        return rewards[_user] + getPendingReward(_user);
    }

    function getPendingReward(address _user) internal view returns(uint256) {
        uint256 time = min(block.timestamp, END);
		uint256 timerUser = lastUpdate[_user];
        uint256 delta = time == END ? 0 : time - timerUser;

        // *** updated_amount = (balances(user) * BASE_RATE * delta / 86400) + amount * initial rate
        uint256 genesisPendingReward = AlphieWhales.balanceGenesisWhales(_user) * GENESIS_BASE_RATE * delta / 86400;

        return genesisPendingReward;
    }

    function setAllowedAddresses(address _address, bool _access) public {
        require(allowedAddresses[msg.sender], "Address does not have permission");
        allowedAddresses[_address] = _access;
    }

    function toggleReward() public {
        require(allowedAddresses[msg.sender], "Address does not have permission");
        rewardPaused = !rewardPaused;
    }
}