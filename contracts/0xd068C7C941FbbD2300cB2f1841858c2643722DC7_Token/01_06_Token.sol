// SPDX-License-Identifier: MIT
//
// https://dgnapp.ai/
// https://t.me/dgnapp
// https://twitter.com/FollowAltcoins

pragma solidity ^0.8.0;

import "./BaseERC20Token.sol";

contract Token is BaseERC20Token {
    struct Fees {
        uint8 burnFee;
        uint8 marketingFee;
        uint8 summedFee;
    }

    Fees public fees;
    Fees public zeroFees;

    enum TransferType {MOVE, BUY, SELL}

    address public routerAddress;
    address public burnAddress;
    address public marketingAddress;
    address public teamAddress1;
    address public teamAddress2;
    address public operationAddress1;
    address public operationAddress2;

    mapping(address => bool) private taxFreeAddresses;

    constructor(
        address _teamAddress1,
        address _teamAddress2,
        address _operationAddress1,
        address _operationAddress2,
        address _marketingAddress
    ) {
        // erc-20 fields
        _name = "DGNAPP.AI";
        _symbol = "DEGAI";
        _totalSupply = 1_000_000_000 * 10 ** decimals();

        // fees
        fees.burnFee = 3;
        fees.marketingFee = 2;
        fees.summedFee = fees.burnFee + fees.marketingFee;

        // addresses
        burnAddress = address(0xdEaD);
        teamAddress1 = _teamAddress1;
        teamAddress2 = _teamAddress2;
        operationAddress1 = _operationAddress1;
        operationAddress2 = _operationAddress2;
        marketingAddress = _marketingAddress;

        taxFreeAddresses[address(this)] = true;
        taxFreeAddresses[marketingAddress] = true;
        taxFreeAddresses[owner()] = true;

        // coins distribution
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        return transferCoins(spender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        return transferCoins(from, to, amount);
    }

    function transferCoins(address from, address to, uint256 amount) internal returns (bool) {
        TransferType transferType;
        Fees memory transferFees;
        (transferType, transferFees) = getTransferTypeAndFees(from, to);

        if (transferFees.summedFee != 0) {
            uint256 burnFeeAmount = (amount * transferFees.burnFee) / 100;
            _transfer(from, burnAddress, burnFeeAmount);

            uint256 marketingFeeAmount = (amount * transferFees.marketingFee) / 100;
            _transfer(from, marketingAddress, marketingFeeAmount);

            amount -= burnFeeAmount;
            amount -= marketingFeeAmount;
        }

        _transfer(from, to, amount);

        return true;
    }

    function getTransferTypeAndFees(address from, address to) internal view returns (TransferType, Fees memory) {
        if (from == routerAddress)
            return (TransferType.BUY, zeroFees);
        else if (to == routerAddress)
            if (taxFreeAddresses[from] || taxFreeAddresses[to])
                return (TransferType.SELL, zeroFees);
            else
                return (TransferType.SELL, fees);
        else
            return (TransferType.MOVE, zeroFees);
    }

    function setRouterAddress(address _routerAddress) public onlyOwner {
        routerAddress = _routerAddress;
    }
}