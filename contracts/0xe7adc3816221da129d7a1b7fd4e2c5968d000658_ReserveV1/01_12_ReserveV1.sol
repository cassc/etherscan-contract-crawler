// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ReserveV1 is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    uint availableReserves;
    uint totalReserved;
    uint maxPerWallet;
    uint reservePrice;

    mapping(address => uint) reserves;
    address[] wallets;

    mapping(address => uint) balances;
    uint balance;

    event MeerkatReserved(address wallet, uint amount, uint totalReserve);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint _maxPerWallet,
        uint _reservePrice
    ) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        reservePrice = _reservePrice;
        maxPerWallet = _maxPerWallet;
    }

    function reserve(uint amount) external payable whenNotPaused {
        require(amount > 0, "reserve amount should be more than zero");
        require(
            totalReserved + amount <= availableReserves,
            "not enought reserves available"
        );
        require(
            reserves[msg.sender] + amount <= maxPerWallet,
            "reserve amount is too big"
        );
        require(msg.value == amount * reservePrice, "invalid payment amount");

        if (reserves[msg.sender] == 0) {
            wallets.push(msg.sender);
        }
        reserves[msg.sender] += amount;
        totalReserved += amount;

        balances[msg.sender] += msg.value;
        balance += msg.value;

        emit MeerkatReserved(msg.sender, amount, reserves[msg.sender]);
    }

    struct State {
        uint reserved;
        uint left;
        uint availableReserves;
        uint totalReserved;
        uint maxPerWallet;
        uint reservePrice;
    }

    function state() external view returns (State memory) {
        return
            State({
                reserved: reserves[msg.sender],
                left: availableReserves - totalReserved,
                availableReserves: availableReserves,
                totalReserved: totalReserved,
                maxPerWallet: maxPerWallet,
                reservePrice: reservePrice
            });
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function addAvailableReserves(uint newReserves) external onlyOwner {
        availableReserves += newReserves;
    }

    function setReservePrice(uint newReservePrice) external onlyOwner {
        reservePrice = newReservePrice;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    struct reservePerUser {
        address wallet;
        uint reserve;
        uint paid;
    }

    function getReserves()
        external
        view
        onlyOwner
        returns (reservePerUser[] memory)
    {
        reservePerUser[] memory reservesPerUser = new reservePerUser[](
            wallets.length
        );
        for (uint i = 0; i < wallets.length; i++) {
            reservesPerUser[i] = reservePerUser({
                wallet: wallets[i],
                reserve: reserves[wallets[i]],
                paid: balances[wallets[i]]
            });
        }

        return reservesPerUser;
    }
}