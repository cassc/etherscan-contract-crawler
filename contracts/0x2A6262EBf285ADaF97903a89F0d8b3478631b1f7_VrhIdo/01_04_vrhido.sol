// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "SafeMath.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    //function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function burn(uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
}

interface USDT {
    function decimals() external view returns (uint);
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

struct LockedBalance{
    int128 amount;
    uint256 end;
}

interface VotingEscrow {
    function create_lock_for(address _for, uint256 _value, uint256 _unlock_time) external;
    function deposit_for(address _addr, uint256 _value) external;
    function locked(address arg0) external returns(LockedBalance memory);
}

contract VrhIdo is Ownable {
    using SafeMath for uint256;


    event Purchase(address indexed buyer,uint256 indexed round, uint256 paymentAmount, uint256 vrhAmount, uint256 lockedVrhAmount, uint256 lockedEnd, uint256 ratio);

    struct IdoRound{
        uint256 startTime;
        uint256 endTime;
        uint256 idoRoundSupply;
        uint256 ratio;// for example: usdt 10**6 can buy token 5x(10**18)  then ratio = 5x(10**18)
        uint256 salesVolume;
        uint256 burnVolume;
    }

    IdoRound[] private idoRoundList;
    uint256 private MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private YEAR = 86400 * 365;
    uint256 private WEEK = 7 * 86400;

    address public vrhTokenAddress;
    address public quoteTokenAddress;
    address public votingEscrowAddress;
    address public fundAddress;

    uint256 public lockedVrhRatio;

    uint256 public quoteTokenDecimals;


    constructor(address _vrhTokenAddress, address _quoteTokenAddress, address _votingEscrowAddress, address _fundAddress, uint256 _lockedVrhRatio) {

        vrhTokenAddress = _vrhTokenAddress;
        quoteTokenAddress = _quoteTokenAddress;
        votingEscrowAddress = _votingEscrowAddress;
        fundAddress = _fundAddress;

        lockedVrhRatio = _lockedVrhRatio;

        if(_quoteTokenAddress == address(0)){
            quoteTokenDecimals = 18;
        }else{
            quoteTokenDecimals = USDT(quoteTokenAddress).decimals();
        }

        IERC20(vrhTokenAddress).approve(votingEscrowAddress, MAX_INT);
    }

    function setFundAddress(address _fundAddress) external onlyOwner {
        require(_fundAddress != address(0));
        fundAddress = _fundAddress;
    }

    function addIdoRound(uint256 _startTime, uint256 _endTime, uint256 _idoRoundSupply, uint256 _ratio) external onlyOwner {

        require(_startTime > block.timestamp, "startTime error");
        require(_endTime > _startTime, "endTime error");
        require(_idoRoundSupply > 0, "idoRoundSupply error");
        require(_ratio > 0, "ratio error");

        if(idoRoundList.length > 0){
            IdoRound memory lastIdoRound = idoRoundList[idoRoundList.length - 1];
            require(_startTime >= lastIdoRound.endTime, "startTime error");
        }

        IdoRound memory idoRound = IdoRound(_startTime, _endTime, _idoRoundSupply, _ratio, 0, 0);

        idoRoundList.push(idoRound);

    }

    function burn(uint256 index) external onlyOwner {

        IdoRound memory idoRound = idoRoundList[index];

        require(idoRound.idoRoundSupply > 0, "index error");
        require(idoRound.burnVolume == 0, "already burned");
        require(idoRound.idoRoundSupply > idoRound.salesVolume, "nothing to burn");
        require(block.timestamp > idoRound.endTime, "idoRound ongoing");

        uint256 burnVolume = idoRound.idoRoundSupply.sub(idoRound.salesVolume);

        IERC20(vrhTokenAddress).burn(burnVolume);

        idoRoundList[index].burnVolume = burnVolume;

    }



    function purchase(uint256 amount, uint256 yearCount) external payable {

        require(amount > 0, "amount error");
        require(idoRoundList.length > 0, "no idoRound");
        require(yearCount > 0 && yearCount <= 4, "yearCount error");

        uint256 index = MAX_INT;
        for(uint256 i=0;i<idoRoundList.length;i++){
            if(block.timestamp >= idoRoundList[i].startTime && block.timestamp < idoRoundList[i].endTime){
                index = i;
                break;
            }
        }
        require(index < MAX_INT, "no active idoRound");

        IdoRound memory idoRound = idoRoundList[index];

        uint256 totalVrhAmount ;

        if(quoteTokenAddress == address(0)){
            require(msg.value == amount, "amount error");

            totalVrhAmount = amount.mul(idoRound.ratio).div(10**18);

            payable(fundAddress).transfer(msg.value);
        }else{
            //require(msg.value == 0, "return eth");
            USDT(quoteTokenAddress).transferFrom(msg.sender, fundAddress, amount);

            totalVrhAmount = amount.mul(idoRound.ratio).div(10**quoteTokenDecimals);
        }

        require(idoRound.idoRoundSupply.sub(idoRound.salesVolume) >= totalVrhAmount, "vrh insufficient");

        uint256 lockedVrhAmount = totalVrhAmount.mul(lockedVrhRatio).div(10000);
        uint256 vrhAmount = totalVrhAmount.sub(lockedVrhAmount);


        IERC20(vrhTokenAddress).transfer(msg.sender, vrhAmount);

        uint256 end;

        LockedBalance memory lockedBalance = VotingEscrow(votingEscrowAddress).locked(msg.sender);

        if(lockedBalance.amount > 0){
            end = lockedBalance.end;
            VotingEscrow(votingEscrowAddress).deposit_for(msg.sender, lockedVrhAmount);
        }else{
            end = block.timestamp.add(yearCount.mul(YEAR)).div(WEEK).mul(WEEK);
            VotingEscrow(votingEscrowAddress).create_lock_for(msg.sender, lockedVrhAmount, end);
        }

        idoRoundList[index].salesVolume += totalVrhAmount;

        emit Purchase(msg.sender, index, amount, vrhAmount, lockedVrhAmount, end, idoRound.ratio);
    }

    function withdrawToken(address token, address to) external onlyOwner{
        IERC20 iERC20 = IERC20(token);
        uint256 balance = iERC20.balanceOf(address(this));
        require(balance > 0, "token insufficient");
        iERC20.transfer(to==address(0)?msg.sender:to, balance);
    }

    function withdraw(address to) external onlyOwner{
        uint256 balance = address(this).balance;
        payable(to==address(0)?msg.sender:to).transfer(balance);
    }

    function getIdoRound(uint256 index) public view returns (IdoRound memory){
        IdoRound memory idoRound;
        if(index < idoRoundList.length){
            return idoRoundList[index];
        }
        return idoRound;
    }
}