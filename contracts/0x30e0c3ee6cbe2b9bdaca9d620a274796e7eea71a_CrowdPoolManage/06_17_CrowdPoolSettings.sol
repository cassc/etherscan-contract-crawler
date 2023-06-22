// SPDX-License-Identifier: UNLICENSED
// @Credits Unicrypt Network 2021

// Settings to initialize crowdpool contracts and edit fees.

pragma solidity ^0.8.0;

interface ILpLocker {
    function price() external pure returns (uint256);
}

contract CrowdPoolSettings {
    address private owner;
    address private manage;
    ILpLocker locker;

    struct SettingsInfo {
        uint256 raised_fee; // divided by 100
        uint256 sold_fee; // divided by 100
        uint256 referral_fee; // divided by 100
        uint256 crowdpool_create_fee; // divided by 100
        address payable raise_fee_address;
        address payable sole_fee_address;
        address payable referral_fee_address; // if this is not address(0), there is a valid referral
        address payable create_fee_address; // if this is not address(0), there is a valid referral
    }

    SettingsInfo public info;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyManager() {
        require(manage == msg.sender, "Ownable: caller is not the manager");
        _;
    }

    event setRaiseFeeAddrSuccess(address indexed addr);
    event setRaisedFeeSuccess(uint256 num);
    event setSoleFeeAddrSuccess(address indexed addr);
    event setSoldFeeSuccess(uint256 num);
    event setReferralFeeAddrSuccess(address addr);
    event setReferralFeeSuccess(uint256 num);
    event setCreateFeeAddrSuccess(address addr);
    event setCreateFeeSuccess(uint256 num);
    event setFeeInfoSuccess(uint256);

    constructor(
        address _manage,
        address _owner,
        address lockaddr
    ) public {
        owner = _owner;
        manage = _manage;
        locker = ILpLocker(lockaddr);
    }

    function init(
        address payable _crowdpool_create_fee_addr,
        uint256 _crowdpool_create_fee,
        address payable _raise_fee_addr,
        uint256 _raised_fee,
        address payable _sole_fee_address,
        uint256 _sold_fee,
        address payable _referral_fee_address,
        uint256 _referral_fee
    ) public onlyManager {
        info.crowdpool_create_fee = _crowdpool_create_fee;
        info.raise_fee_address = _raise_fee_addr;
        info.raised_fee = _raised_fee;
        info.sole_fee_address = _sole_fee_address;
        info.sold_fee = _sold_fee;
        info.referral_fee_address = _referral_fee_address;
        info.referral_fee = _referral_fee;
        info.create_fee_address = _crowdpool_create_fee_addr;
    }

    function getRaisedFeeAddress()
        external
        view
        returns (address payable _raise_fee_addr)
    {
        return info.raise_fee_address;
    }

    function setRaisedFeeAddress(address payable _raised_fee_addr)
        external
        onlyOwner
    {
        info.raise_fee_address = _raised_fee_addr;
        emit setRaiseFeeAddrSuccess(info.raise_fee_address);
    }

    function getRasiedFee() external view returns (uint256) {
        return info.raised_fee;
    }

    function setRaisedFee(uint256 _raised_fee) external onlyOwner {
        info.raised_fee = _raised_fee;
        emit setRaisedFeeSuccess(info.raised_fee);
    }

    function getSoleFeeAddress()
        external
        view
        returns (address payable _sole_fee_address)
    {
        return info.sole_fee_address;
    }

    function setSoleFeeAddress(address payable _sole_fee_address)
        external
        onlyOwner
    {
        info.sole_fee_address = _sole_fee_address;
        emit setSoleFeeAddrSuccess(info.sole_fee_address);
    }

    function getSoldFee() external view returns (uint256) {
        return info.sold_fee;
    }

    function setSoldFee(uint256 _sold_fee) external onlyOwner {
        info.sold_fee = _sold_fee;
        emit setSoldFeeSuccess(info.sold_fee);
    }

    function getReferralFeeAddress() external view returns (address payable) {
        return info.referral_fee_address;
    }

    function setReferralFeeAddress(address payable _referral_fee_address)
        external
        onlyOwner
    {
        info.sole_fee_address = _referral_fee_address;
        emit setReferralFeeAddrSuccess(info.referral_fee_address);
    }

    function getRefferralFee() external view returns (uint256) {
        return info.referral_fee;
    }

    function setRefferralFee(uint256 _referral_fee) external onlyOwner {
        info.referral_fee = _referral_fee;
        emit setReferralFeeSuccess(info.referral_fee);
    }

    function getLockFee() external view returns (uint256) {
        return locker.price();
    }

    function getCrowdPoolCreateFee() external view returns (uint256) {
        return info.crowdpool_create_fee;
    }

    function setSetCrowdPoolCreateFee(uint256 _crowdpool_create_fee)
        external
        onlyOwner
    {
        info.crowdpool_create_fee = _crowdpool_create_fee;
        emit setCreateFeeSuccess(info.crowdpool_create_fee);
    }

    function getCreateFeeAddress() external view returns (address payable) {
        return info.create_fee_address;
    }

    function setCreateFeeAddress(address payable _create_fee_address)
        external
        onlyOwner
    {
        info.create_fee_address = _create_fee_address;
        emit setReferralFeeAddrSuccess(info.create_fee_address);
    }

    function setFeeInfo(
        address payable _create_address,
        address payable _raise_address,
        address payable _sold_address,
        uint256 _create_fee,
        uint256 _raise_fee,
        uint256 _sold_fee
    ) external onlyOwner {
        info.create_fee_address = _create_address;
        info.raise_fee_address = _raise_address;
        info.sole_fee_address = _sold_address;

        info.crowdpool_create_fee = _create_fee;
        info.raised_fee = _raise_fee;
        info.sold_fee = _sold_fee;

        emit setFeeInfoSuccess(1);
    }
}