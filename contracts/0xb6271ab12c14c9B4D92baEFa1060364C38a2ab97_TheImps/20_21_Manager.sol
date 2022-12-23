// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Manager is Ownable {
    mapping(address => bool) burnerAddresses;
    mapping(address => bool) minterAddresses;
    mapping(address => bool) spenderAddresses;
    mapping(address => bool) private signers;

    address public minterContract;
    address public purgeContract;
    address public bloodDiaomondsContract;
    address public devilsLeanContract;
    address public theImpsContract;
    address public impTailContract;
    address public theGoldenKeyContract;

    uint256 public waitingTime = 86400;

    uint256 public minRewardingTime = 24 * 60 * 60;
    uint256 public stakingRewards = 3;

    constructor() {
        burnerAddresses[0x5b1DD51f29064Aa92025fFD0044B66E490F162Fd] = true;
        burnerAddresses[msg.sender] = true;
        minterAddresses[msg.sender] = true;
    }

    function setStakingRewards(uint256 _rewards) external onlyOwner {
        stakingRewards = _rewards;
    }

    function setRewardingTime(uint256 _time) external onlyOwner {
        minRewardingTime = _time;
    }

    function setWaitingTime(uint256 newTime) external onlyOwner {
        waitingTime = newTime;
    }

    function setGoldenKey(address _goldenKey) external onlyOwner {
        theGoldenKeyContract = _goldenKey;
    }

    function setImpTail(address _impTailContract) external onlyOwner {
        impTailContract = _impTailContract;
    }

    function setPurger(address _purger) external onlyOwner {
        purgeContract = _purger;
    }

    function setBloodDiamonds(address _bld) external onlyOwner {
        bloodDiaomondsContract = _bld;
    }

    function setDevilsLean(address _dvl) external onlyOwner {
        devilsLeanContract = _dvl;
    }

    function setTheImps(address _imp) external onlyOwner {
        theImpsContract = _imp;
    }

    function addMinter(address minter) external onlyOwner {
        minterAddresses[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        minterAddresses[minter] = false;
    }

    function isSpender(address spender) external view returns (bool) {
        return spenderAddresses[spender];
    }

    function addSpender(address spender) external onlyOwner {
        spenderAddresses[spender] = true;
    }

    function removeSpender(address spender) external onlyOwner {
        spenderAddresses[spender] = false;
    }

    function isMinter(address minter) external view returns (bool) {
        return minterAddresses[minter];
    }

    function addBurner(address burner) external onlyOwner {
        burnerAddresses[burner] = true;
    }

    function removeBurner(address burner) external onlyOwner {
        burnerAddresses[burner] = false;
    }

    function isBurner(address minter) external view returns (bool) {
        return burnerAddresses[minter];
    }

    function addSigner(address signer) external onlyOwner {
        signers[signer] = true;
    }

    function removeSigner(address signer) external onlyOwner {
        signers[signer] = false;
    }

    function isSigner(address signer) external view returns (bool) {
        return signers[signer];
    }
}