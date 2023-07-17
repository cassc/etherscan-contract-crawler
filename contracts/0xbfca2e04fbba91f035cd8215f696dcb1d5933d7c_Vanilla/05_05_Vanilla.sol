// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Vanilla is ERC20 {
    address public admin;
    address public receiver;
    address public distributor;
    address public vanilla721;
    address public auction;
    address public locker;
    address public treasury;
    address public trader;
    address public ticket;
    address public loan;
    address public reinforcer;
    address public randomTable;
    address public interestRate;

    mapping(address => bool) public minters;
    mapping(address => bool) public allowed721;

    event NewAdmin(address indexed newAdmin);
    event NewReceiver(address indexed newReceiver);
    event NewDistributor(address indexed newDistributor);
    event NewVanilla721(address indexed newVanilla721);
    event NewAuction(address indexed newAuction);
    event NewLocker(address indexed newLocker);
    event NewTreasury(address indexed newTreasury);
    event NewTrader(address indexed newTrader);
    event NewTicket(address indexed newTicket);
    event NewLoan(address indexed newLoan);
    event NewReinforcer(address indexed newReinforcer);
    event NewRandomTable(address indexed newRandomTable);
    event NewInterestRate(address indexed newInterestRate);
    event NewMinter(address indexed newMinter, bool isMinter);
    event NewAllowed721(address indexed newAllowed721, bool isAllowed);

    constructor(
        address newAdmin,
        address newReceiver,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        require(
            newAdmin != address(0) && newReceiver != address(0),
            "Vanilla: zero address"
        );
        admin = newAdmin;
        receiver = newReceiver;
    }

    function setMinter(address newMinter) public {
        require(msg.sender == admin, "Vanilla: admin");
        minters[newMinter] = !minters[newMinter];
        emit NewMinter(newMinter, minters[newMinter]);
    }

    function setAdmin(address newAdmin) external {
        require(msg.sender == admin, "Vanilla: admin");
        require(newAdmin != address(0), "Vanilla: zero address");
        admin = newAdmin;
        emit NewAdmin(admin);
    }

    function setReceiver(address newReceiver) external {
        require(msg.sender == admin, "Vanilla: admin");
        require(newReceiver != address(0), "Vanilla: zero address");
        receiver = newReceiver;
        emit NewReceiver(receiver);
    }

    function setDistributor(address newDistributor) external {
        require(msg.sender == admin, "Vanilla: admin");
        require(newDistributor != address(0), "Vanilla: zero address");

        setMinter(distributor);
        distributor = newDistributor;
        setMinter(distributor);

        emit NewDistributor(distributor);
    }

    function setVanilla721(address newVanilla721) external {
        require(msg.sender == admin, "Vanilla: admin");
        require(newVanilla721 != address(0), "Vanilla: zero address");

        setAllowed721(vanilla721);
        vanilla721 = newVanilla721;
        setAllowed721(vanilla721);

        emit NewVanilla721(vanilla721);
    }

    function setAuction(address newAuction) external {
        require(msg.sender == admin, "Vanilla: admin");
        require(newAuction != address(0), "Vanilla: zero address");
        auction = newAuction;

        emit NewAuction(auction);
    }

    function setLocker(address newLocker) external {
        require(msg.sender == admin, "Vanilla: admin");
        require(newLocker != address(0), "Vanilla: zero address");
        locker = newLocker;

        emit NewLocker(locker);
    }

    function setTreasury(address newTreasury) external {
        require(msg.sender == admin, "Vanilla: admin");
        require(newTreasury != address(0), "Vanilla: zero address");
        treasury = newTreasury;

        emit NewTreasury(treasury);
    }

    function setTrader(address newTrader) external {
        require(msg.sender == admin, "Vanilla: admin");
        require(newTrader != address(0), "Vanilla: zero address");
        trader = newTrader;

        emit NewTrader(trader);
    }

    function setLoan(address newLoan) external {
        require(msg.sender == admin, "Vanilla: admin");
        require(newLoan != address(0), "Vanilla: zero address");
        loan = newLoan;

        emit NewLoan(loan);
    }

    function setReinforcer(address newReinforcer) external {
        require(msg.sender == admin, "Vanilla: admin");
        require(newReinforcer != address(0), "Vanilla: zero address");
        reinforcer = newReinforcer;

        emit NewReinforcer(reinforcer);
    }

    function setRandomTable(address newRandomTable) external {
        require(msg.sender == admin, "Vanilla: admin");
        require(newRandomTable != address(0), "Vanilla: zero address");
        randomTable = newRandomTable;

        emit NewRandomTable(randomTable);
    }

    function setInterestRate(address newInterestRate) external {
        require(msg.sender == admin, "Vanilla: admin");
        require(newInterestRate != address(0), "Vanilla: zero address");
        interestRate = newInterestRate;

        emit NewInterestRate(interestRate);
    }

    function setTicket(address newTicket) external {
        require(msg.sender == admin, "Vanilla: admin");
        require(newTicket != address(0), "Vanilla: zero address");

        setMinter(ticket);
        ticket = newTicket;
        setMinter(ticket);

        emit NewTicket(ticket);
    }

    function setAllowed721(address newAllowed721) public {
        require(msg.sender == admin, "Vanilla: admin");

        allowed721[newAllowed721] = !allowed721[newAllowed721];

        emit NewAllowed721(newAllowed721, allowed721[newAllowed721]);
    }

    function mint(address to, uint amount) external {
        require(minters[msg.sender], "Vanilla: minter");
        _mint(to, amount);
    }

    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }
}