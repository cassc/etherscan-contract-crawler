//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

error TwoLevelReferral__TransferFailed();
error TwoLevelReferral__InvalidDenomination();
error TwoLevelReferral__InvalidReferralDecimal();
error TwoLevelReferral__InvalidReferralPercentage();
error TwoLevelReferral__ContractAddressNotAllowed();

interface IPrevTwoLevelReferral {
    function getAllReferralKeys() external view returns (address[] memory);

    function referralMap(address _referral) external view returns (address);
}

contract TwoLevelReferral is Ownable {
    /** @dev Decimal is 1000 so first level percentage will be 0.5%, second level percentage will be 0.1%,
     * and root owner percentages will 0.4%, 0.5%, and 1%;
     */

    uint16 public decimal = 10**3; // 1000
    uint8 public firstLevelPercentage = 5;
    uint8 public secondLevelPercentage = 1;
    uint8 public totalFee = 10;
    uint8[3] public rootOwnerPercentage = [4, 5, 10];

    address[] public allReferralKeys;
    address[] public allowedToPayContractsArray;

    bool public allowAnyonePay = false;

    mapping(address => address) public referralMap; // key (playing user) -> value (refferer)
    mapping(address => bool) public depositorAdded;
    mapping(address => bool) public allowedToPayMap;

    event FirstLevelReferral(address indexed depositor, address referrer, uint256 reward);
    event SecondLevelReferral(address indexed depositor, address referrer, address secondLevelReferrer, uint256 reward);

    function saveDepositor(address _depositor, address _referrerAddress) external {
        if (!allowedToPayMap[msg.sender] && !allowAnyonePay) {
            revert TwoLevelReferral__ContractAddressNotAllowed();
        }

        if (!depositorAdded[_depositor]) {
            allReferralKeys.push(_depositor);
            depositorAdded[_depositor] = true;
            referralMap[_depositor] = _referrerAddress;
        } else {
            if (referralMap[_depositor] == address(0)) {
                referralMap[_depositor] = _referrerAddress;
            }
        }
    }

    function getSecondLevel(address _referrerAddress) external view returns (address) {
        if (referralMap[_referrerAddress] != address(0)) {
            return referralMap[_referrerAddress];
        } else {
            return address(0);
        }
    }

    function calculateFirstLevelPay(uint256 _denomination) external view returns (uint256) {
        uint256 firstLevelReward = (_denomination * firstLevelPercentage) / decimal;
        return firstLevelReward;
    }

    function calculateSecondLevelPay(uint256 _denomination) external view returns (uint256) {
        uint256 secLevelReward = (_denomination * secondLevelPercentage) / decimal;
        return secLevelReward;
    }

    function getRootOwnerPercentage(uint256 _index) external view returns (uint8) {
        return rootOwnerPercentage[_index];
    }

    function getDecimal() external view returns (uint16) {
        return decimal;
    }

    function getTotalFee() public view returns (uint8) {
        return totalFee;
    }

    function getAllReferralKeys() external view returns (address[] memory) {
        return allReferralKeys;
    }

    function getAllAllowedToPayContractsArray() external view returns (address[] memory) {
        return allowedToPayContractsArray;
    }

    function getAllReferralMap() external view returns (address[] memory, address[] memory) {
        address[] memory keyAddresses = new address[](allReferralKeys.length);
        address[] memory valueAddresses = new address[](allReferralKeys.length);

        for (uint256 i = 0; i < allReferralKeys.length; i++) {
            address refKey = allReferralKeys[i];
            keyAddresses[i] = refKey;
            valueAddresses[i] = referralMap[refKey];
        }
        return (keyAddresses, valueAddresses);
    }

    function getAllUserFirstLevel(address _userAddress) public view returns (address[] memory) {
        address[] memory firstLevel = new address[](allReferralKeys.length);
        uint256 lvIndex = 0;
        for (uint256 i = 0; i < allReferralKeys.length; i++) {
            address refKey = allReferralKeys[i];
            if (referralMap[refKey] == _userAddress) {
                firstLevel[lvIndex] = refKey;
                lvIndex++;
            }
        }

        return firstLevel;
    }

    function getAllUserSecondLevel(address _userAddress) public view returns (address[] memory) {
        address[] memory secondLevel = new address[](allReferralKeys.length);
        uint256 lvIndex = 0; //just leave empty items in the back of the array

        for (uint256 i = 0; i < allReferralKeys.length; i++) {
            address firstLevel = referralMap[allReferralKeys[i]]; //value is first level refferer
            if (referralMap[firstLevel] == _userAddress) {
                secondLevel[lvIndex] = allReferralKeys[i];
                lvIndex++;
            }
        }

        return secondLevel;
    }

    function addAllowedToPayContractAddress(address _contractAllowed) external onlyOwner {
        allowedToPayContractsArray.push(_contractAllowed);
        allowedToPayMap[_contractAllowed] = true;
    }

    function toggleAllowAnyonePay(bool _allowAnyAddress) external onlyOwner {
        allowAnyonePay = _allowAnyAddress;
    }

    function removeAllowedContractAddress(address _contractAllowed) external onlyOwner {
        require(allowedToPayMap[_contractAllowed], "Token not added");

        uint256 indexToDelete = 2**256 - 1;

        for (uint256 i = 0; i < allowedToPayContractsArray.length; i++) {
            if (allowedToPayContractsArray[i] == _contractAllowed) {
                indexToDelete = i;
            }
        }

        allowedToPayContractsArray[indexToDelete] = allowedToPayContractsArray[allowedToPayContractsArray.length - 1];
        allowedToPayContractsArray.pop();
        allowedToPayMap[_contractAllowed] = false;
    }

    function setFirstLevelPercentage(uint8 _firstLevelPercentage) external onlyOwner {
        firstLevelPercentage = _firstLevelPercentage;
    }

    function setSecondLevelPercentage(uint8 _secondLevelPercentage) external onlyOwner {
        secondLevelPercentage = _secondLevelPercentage;
    }

    function setRootOwnerPercentage(uint8[3] memory _rootOwnerPercentage) external onlyOwner {
        rootOwnerPercentage = _rootOwnerPercentage;
        totalFee = _rootOwnerPercentage[2];
    }

    function migrateReferrals(address previousContract) external onlyOwner {
        IPrevTwoLevelReferral prevTwoLevelReferral = IPrevTwoLevelReferral(previousContract);
        address[] memory referralKeys = prevTwoLevelReferral.getAllReferralKeys();

        for (uint256 i = 0; i < referralKeys.length; i++) {
            address referralKey = referralKeys[i];
            referralMap[referralKey] = prevTwoLevelReferral.referralMap(referralKey);
            allReferralKeys.push(referralKey);
        }
    }
}