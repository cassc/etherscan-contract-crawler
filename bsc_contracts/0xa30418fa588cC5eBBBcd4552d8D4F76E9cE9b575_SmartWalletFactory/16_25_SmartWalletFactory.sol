// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {ISmartWallet} from "./interface/ISmartWallet.sol";
import {ISmartWalletFactory} from "./interface/ISmartWalletFactory.sol";
import {IReferrals} from "./interface/IReferrals.sol";
import {IAlphaWhitelist} from "./interface/IAlphaWhitelist.sol";

contract SmartWalletFactory is ISmartWalletFactory, OwnableUpgradeable {
    event Created(
        address indexed owner,
        address indexed smartWallet,
        address indexed sponsor
    );
    event DailyWithdrawLimitUpdated(uint256 dailyWithdrawLimit);

    mapping(address => address) public override getSmartWallet;
    mapping(address => bool) public override isWhitelisted;

    address public limitOrderBook;
    address public clearingHouse;
    address public beacon;
    IReferrals public referrals;
    IAlphaWhitelist public alphaWhitelist;
    uint256 public override dailyWithdrawLimit;

    modifier onlyWhitelisted() {
        require(
            address(alphaWhitelist) == address(0) ||
                alphaWhitelist.isWhitelisted(_msgSender()),
            "SmartWalletFactory: not whitelisted"
        );
        _;
    }

    function initialize(
        address _beacon,
        address _clearingHouse,
        address _limitOrderBook,
        address _referrals
    ) external initializer {
        __Ownable_init();

        beacon = _beacon;
        clearingHouse = _clearingHouse;
        limitOrderBook = _limitOrderBook;
        referrals = IReferrals(_referrals);
    }

    /*
     * @notice Create and deploy a smart wallet for the user and stores the address
     */
    function spawn(address _sponsor)
        external
        onlyWhitelisted
        returns (address smartWallet)
    {
        require(
            getSmartWallet[msg.sender] == address(0),
            "SmartWalletFactory: Already has smart wallet"
        );

        smartWallet = address(
            new BeaconProxy(
                beacon,
                abi.encodeWithSelector(
                    ISmartWallet.initialize.selector,
                    clearingHouse,
                    limitOrderBook,
                    msg.sender
                )
            )
        );

        _sponsor = referrals.sponsor(msg.sender);

        emit Created(msg.sender, smartWallet, _sponsor);

        getSmartWallet[msg.sender] = smartWallet;
    }

    function addToWhitelist(address _contract) external onlyOwner {
        isWhitelisted[_contract] = true;
    }

    function removeFromWhitelist(address _contract) external onlyOwner {
        isWhitelisted[_contract] = false;
    }

    function setAlphaWhitelist(address _alphaWhitelist) external onlyOwner {
        alphaWhitelist = IAlphaWhitelist(_alphaWhitelist);
    }

    function setDailyWithdrawLimit(uint256 _dailyWithdrawLimit)
        external
        onlyOwner
    {
        dailyWithdrawLimit = _dailyWithdrawLimit;

        emit DailyWithdrawLimitUpdated(_dailyWithdrawLimit);
    }
}