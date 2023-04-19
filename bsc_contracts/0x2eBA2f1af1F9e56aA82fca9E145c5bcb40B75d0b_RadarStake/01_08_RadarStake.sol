// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/iRadarStake.sol";
import "./interfaces/iRadarToken.sol";
import "./interfaces/iRadarStakingLogic.sol";

contract RadarStake is iRadarStake, Ownable, ReentrancyGuard {

    constructor(address radarTokenContractAddr) {
        require(address(radarTokenContractAddr) != address(0), "RadarStake: Token contract not set");
        radarTokenContract = iRadarToken(radarTokenContractAddr);
    }

    /** EVENTS */
    event AddedToStake(address indexed owner, uint256 amount);
    event RemovedFromStake(address indexed owner, uint256 amount);
    event CooldownTriggered(address indexed owner, uint256 cooldownSeconds);

    /** PUBLIC VARS */
    // interface of our ERC20 RADAR token
    iRadarToken public radarTokenContract;
    // interface of the staking logic smart contract (stateless)
    iRadarStakingLogic public radarStakingLogicContract;
    // keeps track of all staked tokens at all times
    uint256 public totalStaked;
    // duration of the cooldown before a user can unstake
    uint256 public cooldownSeconds = 30 days; // e.g. 86_400 = 1 day
    // all APRs over time with their respective start and end times
    Apr[] public allAprs;

    /** PRIVATE VARS */
    // all data needed to calculate staking rewards and for keeping tack of users staked funds
    mapping(address => Stake) private _stakedTokens;

    /** MODIFIERS */
    modifier onlyStakingLogicContract() {
        require(_msgSender() == address(radarStakingLogicContract), "RadarStake: Only the StakingLogic contract can call this");
        _;
    }

    /** PUBLIC */
    // allow to fetch all APRs so the staking contract can fetch all of them with one call
    function getAllAprs() external view returns(Apr[] memory) {
        return allAprs;
    }

    // get one stake represening onr user
    function getStake(address addr) external view returns (Stake memory) {
        return _stakedTokens[addr];
    }

    /** ONLY STAKING LOGIC CONTRACT */
    // add to your stake & reset counters - allow amount == 0, so you can reset timers without having to add tokens to your stake
    function addToStake(uint256 amount, address addr) external onlyStakingLogicContract {
        require(amount >= 0, "RadarStake: Amount has to be 0 or higher");
        require(addr != address(0), "RadarStake: Cannot use the null address");
        require(allAprs.length > 0, "RadarStake: No APR set");

        // storage variable used multiple times thus storing it into memory and using the new one from now on
        uint256 _totalStaked = totalStaked;

        Stake memory myStake = _stakedTokens[addr];
        if (myStake.totalStaked > 0 && _totalStaked >= myStake.totalStaked) {
            // subtract the current stake from the total counter (memory)
            _totalStaked -= myStake.totalStaked;
        }

        // save new Stake
        _stakedTokens[addr] = Stake({
            totalStaked: myStake.totalStaked + amount,
            lastStakedTimestamp: block.timestamp,
            cooldownSeconds: 0, // reset cooldown
            cooldownTriggeredAtTimestamp: 0 // reset cooldown
        });

        // add to total staked amount (memory)
        _totalStaked += myStake.totalStaked + amount;
        // store this variable back to storage
        totalStaked = _totalStaked;

        emit AddedToStake(addr, amount);
    }

    // start the cooldown period before user can unstake when calling unstake() later
    function triggerUnstake(address addr) external onlyStakingLogicContract {
        require(addr != address(0), "RadarStake: Cannot use the null address");
        require(cooldownSeconds > 0, "RadarStake: Cooldown seconds must be bigger than 0");

        Stake memory myStake = _stakedTokens[addr];
        require(myStake.totalStaked >= 0, "RadarStake: You have no stake yet");
        require(myStake.cooldownTriggeredAtTimestamp == 0, "RadarStake: Cooldown is already in progress - cannot trigger it again");

        // set the amount of seconds that have to pass before user can unstake
        myStake.cooldownSeconds = cooldownSeconds;
        // store the current time to calculate if the cooldown has passed
        myStake.cooldownTriggeredAtTimestamp = block.timestamp;
        // store the updated Stake to permantent storage
        _stakedTokens[addr] = myStake;

        emit CooldownTriggered(addr, cooldownSeconds);
    }

    // remove from your stake
    function removeFromStake(uint256 amount, address addr) external onlyStakingLogicContract {
        require(amount >= 0, "RadarStake: Amount cannot be lower than 0");
        require(addr != address(0), "RadarStake: Cannot use the null address");
        Stake memory myStake = _stakedTokens[addr];
        require(myStake.cooldownSeconds >= 0, "RadarStake: CooldownSeconds cannot be lower than 0");
        require(myStake.totalStaked >= amount, "RadarStake: You cannot unstake more than you have staked");
        require(totalStaked >= amount, "RadarStake: Cannot unstake more than is staked in total");

        if (myStake.totalStaked == amount) {
            delete(_stakedTokens[addr]); // clean memory when the whole stake is being taken out
        } else {
            // save new Stake
            _stakedTokens[addr] = Stake({
                totalStaked: myStake.totalStaked - amount, // deduct the amount from the current stake
                lastStakedTimestamp: block.timestamp, // reset stake timestamp because we always harvest rewards before unstaking
                cooldownSeconds: 0, // reset cooldown
                cooldownTriggeredAtTimestamp: 0 // reset cooldown
            });
        }
        
        totalStaked -= amount; // subtract from total staked amount

        emit RemovedFromStake(addr, amount);
    }

    /** ONLY OWNER */
    // called when we deploy a new version of our staking rewards logic (new features etc.)
    function setContracts(address radarStakingLogicContractAddr) external onlyOwner {
        require(radarStakingLogicContractAddr != address(0), "RadarStake: Cannot use the null address");
        radarStakingLogicContract = iRadarStakingLogic(radarStakingLogicContractAddr);
    }

    // e.g apr = 300 => 3% APR
    function changeApr(uint256 apr) external onlyOwner {
        require(apr >= 0, "RadarStake: APR cannot be lower than 0");

        // set endTime for previous APR to make rewards calculations easier later on
        if (allAprs.length > 0) {
            Apr storage previousApr = allAprs[allAprs.length - 1];
            previousApr.endTime = block.timestamp;
        }

        // add new APR to the array so rewards can start accruing for this new APR from now on
        allAprs.push(Apr({
            startTime: block.timestamp,
            endTime: 0,
            apr: apr
        }));
    }

    // this is needed so that our RadarStakingLogic contract is allowed to call transferFrom() in the name of this contract so that users can get their payout when they call RadarStakingLogic.harvest or RadarStakingLogic.unstake
    function allowTokenTransfers(uint256 amount) external onlyOwner {
        require(amount >= 0, "RadarStake: Amount cannot be lower than 0");

        radarTokenContract.approve(address(radarStakingLogicContract), amount);
    }

    // allow to change the cooldown period
    function setCooldownSeconds(uint256 number) external onlyOwner {
        require(number >= 0, "RadarStake: Amount must be above 0");
        cooldownSeconds = number;
    }

    // if someone sends RADAR to this contract by accident we want to be able to send it back to them
    function withdrawRewardTokens(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "RadarStake: Cannot use the null address");
        require(amount >= 0, "RadarStake: Amount cannot be lower than 0");
        uint256 radarBalance = radarTokenContract.balanceOf(address(this));
        require(radarBalance >= amount, "RadarStake: Cannot withdraw more than is available");
        require(radarBalance - amount >= totalStaked, "RadarStake: Cannot withdraw more than is staked");
        
        // approve this contract to move the amount of tokens
        radarTokenContract.approve(address(this), amount);
        // transfer those tokens to the given address
        radarTokenContract.transferFrom(address(this), to, amount);
    }

    // if someone sends ETH to this contract by accident we want to be able to send it back to them
    function withdraw() external onlyOwner {
        uint256 totalAmount = address(this).balance;

        bool sent;
        (sent, ) = owner().call{value: totalAmount}("");
        require(sent, "RadarStake: Failed to send funds");
    }
}