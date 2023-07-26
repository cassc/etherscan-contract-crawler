// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MuonV01.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface StandardToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external returns (uint8);
    function mint(address reveiver, uint256 amount) external returns (bool);
    function burn(address sender, uint256 amount) external returns (bool);
}

contract MuonPresale is Ownable{
    using ECDSA for bytes32;

    MuonV01 public muon;
    
    mapping (address => uint256) public balances;

    bool public running = true;

    uint256 public maxMuonDelay = 15 minutes;

    event Deposit(address token, uint256 tokenPrice, uint256 amount, 
        uint256 time, address fromAddress, address forAddress, 
        uint256 addressMaxCap);

    modifier isRunning(){
        require(running, "!running");
        _;
    }

    constructor(address _muon){
        muon = MuonV01(_muon);
    }

    function deposit(
        address token,
        uint256 tokenPrice,
        uint256 amount,
        uint256 time,
        address forAddress,
        uint256 addressMaxCap,
        bytes calldata _reqId, 
        bytes[] calldata sigs
    ) public payable isRunning{

        require(sigs.length > 1, "!sigs");

        bytes32 hash = keccak256(abi.encodePacked(token, tokenPrice, 
            amount, time, forAddress, addressMaxCap));
        hash = hash.toEthSignedMessageHash();

        bool verified = muon.verify(_reqId, hash, sigs);
        require(verified, '!verified');

        // check max
        uint256 usdAmount = amount * tokenPrice /
            (10 ** (token == address(0) ? 18 : StandardToken(token).decimals())
        );
        require(balances[forAddress] + usdAmount <= addressMaxCap, ">max");

        require(time + maxMuonDelay > block.timestamp, "muon: expired");

        if(token == address(0)){
            require(amount == msg.value, "amount err");
        }else{
            StandardToken tokenCon = StandardToken(token);
            tokenCon.transferFrom(address(msg.sender), address(this), amount);
        }

        balances[forAddress] = balances[forAddress] + usdAmount;
        emit Deposit(token, tokenPrice, amount, 
            time, msg.sender, forAddress, addressMaxCap);
    }

    function setMuonContract(address addr) public onlyOwner{
        muon = MuonV01(addr);
    }

    function setIsRunning(bool val) public onlyOwner{
        running = val;
    }

    function setMaxMuonDelay(uint256 delay) public onlyOwner{
        maxMuonDelay = delay;
    }

    function emergencyWithdrawETH(uint256 amount, address addr) public onlyOwner{
        require(addr != address(0));
        payable(addr).transfer(amount);
    }

    function emergencyWithdrawERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        StandardToken(_tokenAddr).transfer(_to, _amount);
    }
}