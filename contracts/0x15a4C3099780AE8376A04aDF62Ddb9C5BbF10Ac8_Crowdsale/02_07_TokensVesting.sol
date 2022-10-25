// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./EcoGames.sol";

contract TokensVesting {
    
    event Received(address, uint);
    event UnlockVest(address indexed holder, uint256 amount);

    EcoGames public ecoGamesContract;
    address public crowdsaleAddress;

    bool locked; // against re-entrancy attacks
    bool startVesting;
    address owner_;
    address[] vesters;

    uint256 public initialPeriod = 90 days;
    uint256 public vestPeriod = 30 days;

    struct vestCore {
        uint256 totalVest;
        uint256 round1;
        uint256 round2;
        uint256 round3;
        uint256 lockedAmount; // remaining vest after initial unlock
        uint256 unlockedAmount;
        uint256 unlockDate;
    }

    mapping(address => vestCore) public vests;

    modifier onlyWhenStarted() {
        require(startVesting, "Vesting: Crowdsale has not ended yet");
        _;
    }

    modifier onlyCrowdsale() {
        require(msg.sender == crowdsaleAddress, "Vesting: Only crowdsale contract can call this function");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner_, "Vesting: Caller is not the owner");
        _;
    }

    constructor(address payable _ecoGamesContract) {
        owner_ = msg.sender;
        ecoGamesContract = EcoGames(_ecoGamesContract);
    }

    function setCrowdsaleAddress(address _crowdsaleAddress) public onlyOwner {
        crowdsaleAddress = _crowdsaleAddress;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner_ = newOwner;
    }
    
    function initiateVesting() public onlyCrowdsale {
        require(!startVesting, "TokensVesting: already initiated!");
        startVesting = true;
    }

    function _vest(address to, uint256 amount, uint256 round) 
        public onlyCrowdsale returns (bool)
    {
        vestCore storage vest = vests[to];
        if (vest.totalVest == 0) {
            vesters.push(to);
        }

        if (round == 0) {
            vest.round1 += amount;
        } else if (round == 1) {
            vest.round2 += amount;
        } else {
            vest.round3 += amount;
        }

        vest.totalVest += amount;
        return true;
    }
    
    function initialUnlock() public onlyWhenStarted noReentrant returns (bool) {
        
        vestCore memory vest = vests[msg.sender];
        require(vest.lockedAmount == 0, "Initial unlock has already been done");
        uint256 transferAmount;

        transferAmount += vest.round1 / 20; // 5%
        transferAmount += vest.round2 * 75 / 1000; // 7.5%
        transferAmount += vest.round3 / 10; // 10%

        bool success = ecoGamesContract.transfer(msg.sender, transferAmount);
        require(success, "Transfer has failed");

        vest.round1 = 0;
        vest.round2 = 0;
        vest.round3 = 0;

        vest.lockedAmount = vest.totalVest - transferAmount;
        vest.unlockDate = block.timestamp + initialPeriod;
        
        vests[msg.sender] = vest;
        emit UnlockVest(msg.sender, transferAmount);
        return true;
    }

    function monthlyUnlock() public onlyWhenStarted noReentrant returns (bool) {

        vestCore memory vest = vests[msg.sender];
        require(vest.lockedAmount > 0, "Initial unlock has not been completed");
        require(vest.unlockDate <= block.timestamp, "Unlock date has not passed");

        uint256 unlockAmount = vest.lockedAmount / 21;
        vest.unlockedAmount += unlockAmount;
        require(vest.unlockedAmount <= vest.lockedAmount, "All vests have been unlocked");
        
        bool success = ecoGamesContract.transfer(msg.sender, unlockAmount);
        require(success, "Transfer has failed");

        vest.unlockDate = block.timestamp + vestPeriod;
        vests[msg.sender] = vest;

        emit UnlockVest(msg.sender, unlockAmount);
        return true;
    }

    function setInitialPeriod(uint256 newPeriod) public onlyOwner {
        initialPeriod = newPeriod;
    }

    function setVestPeriod(uint256 newPeriod) public onlyOwner {
        vestPeriod = newPeriod;
    }

    function getMyVest() public view returns (vestCore memory) {
        return vests[msg.sender];
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    } 

    function withdraw() public onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "Contract has no balance.");
        (bool success, ) = payable(msg.sender).call{value: bal}("");
        require(success, "Withdrawal has failed.");
    }

}