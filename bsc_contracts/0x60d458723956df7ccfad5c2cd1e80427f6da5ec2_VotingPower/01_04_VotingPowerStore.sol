// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVotingPower.sol";

contract VotingPower is Ownable, IVotingPower {
    mapping(string => uint256) private votingPower;
    mapping(string => uint256) private multiplier;
    uint256 private divisor = 100;
    uint256 private minimumVotingPower = 5000;

    constructor() {
        votingPower["2"] =  500000;
        votingPower["3"] =  500000;
        votingPower["4"] =  500000;
        votingPower["5"] =  500000;
        votingPower["6"] =  500000;
        votingPower["7"] =  500000;
        votingPower["8"] =  500000;
        votingPower["9"] =  500000;
        votingPower["10"] =  500000;

        votingPower["J"] = 1000000;
        votingPower["D"] = 1000000;
        votingPower["K"] = 1000000;
        votingPower["A"] = 1000000;
        votingPower["Joker"] = 1000000;

        multiplier["onePair"] = 105;
        multiplier["twoPair"] = 115;
        multiplier["threeOfAKind"] = 127;
        multiplier["straight"] = 145;
        multiplier["flush"] = 167;
        multiplier["fullHouse"] = 190;
        multiplier["fourOfAKind"] = 218;
        multiplier["straightFlush"] = 248;
        multiplier["royalFlush"] = 300;


    }
    /**
     * Voting Power update function accepts type of card and votingPower 
     */
    function setVotingPower(string memory card, uint256 _votingPower) external override onlyOwner {
        votingPower[card] = _votingPower;
    }

    /**
     * Get Voting Power of card 
     */
    function getVotingPower(string memory card) public view override returns (uint256 _votingPower) {
        return votingPower[card];
    }

    /**
     * Multiplier update function accepts sequence name and multiplier value 
     */
    function setMultiplier(string memory sequenceName, uint256 _multiplier) external override onlyOwner {
        multiplier[sequenceName] = _multiplier;
    }

    /**
     * Get the Multiplier for sequence
     */
    function getMultiplier(string memory sequenceName) public view override returns(uint256 _multiplier){
        return multiplier[sequenceName];
    }

    /**
     * set and get divisor - that is the decimal point of multiplier 
     * example a multiplier is 1.01 * 100 = 101 now the divisor would be 100 so that you can get 1.01
     */
    function setDivisor(uint256 _divisor) external override onlyOwner {
        divisor = _divisor;
    }

    function getDivisor() external view override returns (uint256 _divisor) {
        return divisor;
    }

    /**
     * Set and get Limit for minimum voting power required for creating polling proposal
     */
    function setMinimumVotingPower(uint256 power) external override onlyOwner {
        minimumVotingPower = power;
    }

    function getMinimumVotingPower() public view override returns(uint256 _minimumVotingPower) {
        return minimumVotingPower;
    }
    
}