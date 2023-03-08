// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IAdmin {
    function isAdmin(address user) external view returns (bool);
}


contract ArborswapPublicAirdrop {
    using SafeMath for uint256;

    struct AirdropInfo{
        uint256 startTime;
        uint256 totalAmountToAirdrop;
        uint256 totalAmountDistributed;
        uint256 numberWLAddresses;
        uint256 numberOfParticipants;
        bool isPrivate;
        address token;
        string[] description; //logoImage, describtion, tags, website, twitter, linkedin, github, name
    }

    AirdropInfo public airdropInfo;


    uint256 public portionSize;
    uint256 public totalPortions; 
    uint256 public portionsLeft;
    

    bool public airDropStarted;
    bool public airdropCancelled;
    bool public airdropEmpty;

    address public owner;
    IAdmin public admin;

    mapping(address => bool) public isAirdropClaimed;
    mapping(address => bool) public isOwner;

    
    event LogClaimed(address user, uint256 amount);
    event LogCancelAirdrop(uint256 time, uint256 amountRefunded);
    event LogStartAirdrop(uint256 _startTime, uint256 totalToAirdrop);


    // Restricting calls only to airdrop owner or Admin
    modifier onlyAirdropOwnerOrAdmin() {
        require(
            msg.sender == owner || admin.isAdmin(msg.sender),
            "Restricted to airdrop owner and admin."
        );
        _;
    }
    
    // Restricting calls only to airdrop owner
    modifier onlyAirdropOwner() {
        require(msg.sender == owner, "Restricted to airdrop owner.");
        _;
    }

   

    constructor(address _admin, address _owner, address _token, string[] memory _description){
        require(_token != address(0), "Token can't be address 0");
        require(_admin != address(0), "Admin can't be address 0");
        require(_owner != address(0), "Owner can't be address 0");
        
        airdropInfo.token = _token;
        for(uint i = 0; i<_description.length; i++){
            airdropInfo.description.push(_description[i]);
        }
        admin = IAdmin(_admin);
        owner = _owner;
        airdropInfo.isPrivate = false;
        isOwner[owner] = true;
    }


    function getInfo() external view returns(AirdropInfo memory){
        return airdropInfo;
    }

    function start(uint256 _startTime, uint256 _totalPortions, uint256 _portionSize) external onlyAirdropOwner{
        require(airDropStarted != true, "Already started");
        require(_portionSize != 0, "Portion size can't be 0");
        require(_totalPortions != 0, "Portions amount can't be 0");
        require(_startTime >= block.timestamp, "Start time should be in the future");

        airdropInfo.startTime = _startTime;
        airdropInfo.totalAmountToAirdrop = _portionSize.mul(_totalPortions);
        portionSize = _portionSize;
        totalPortions = _totalPortions;
        portionsLeft = _totalPortions;
        airDropStarted = true;

        require(IERC20(airdropInfo.token).allowance(owner, address(this)) >= airdropInfo.totalAmountToAirdrop, 'Insufficient allowance');

        IERC20(airdropInfo.token).transferFrom(owner, address(this), airdropInfo.totalAmountToAirdrop);

        emit LogStartAirdrop(airdropInfo.startTime, airdropInfo.totalAmountToAirdrop);
    }

    function cancelAirdrop() external onlyAirdropOwnerOrAdmin{
        require(airdropCancelled != true, "Already cancelled");

        airdropCancelled = true;

        uint256 amount = IERC20(airdropInfo.token).balanceOf(address(this));
        
        if(amount > 0){
            IERC20(airdropInfo.token).transfer(owner, amount);
        }

        emit LogCancelAirdrop(block.timestamp, amount);
    }

    function claim() external{
        require(!isAirdropClaimed[msg.sender], "Already claimed");
        require(airdropCancelled != true, "Airdrop cancelled");
        require(airdropEmpty != true, "Airdrop empty");
        require(airDropStarted == true, "Airdrop haven't started yet");

        airdropInfo.totalAmountDistributed = airdropInfo.totalAmountDistributed.add(portionSize);

        if(airdropInfo.totalAmountDistributed == airdropInfo.totalAmountToAirdrop){
            airdropEmpty = true;
        }

        isAirdropClaimed[msg.sender] = true;

        airdropInfo.numberOfParticipants++;
        portionsLeft = totalPortions - airdropInfo.numberOfParticipants;

        IERC20(airdropInfo.token).transfer(msg.sender, portionSize);

        emit LogClaimed(msg.sender, portionSize);
    }

    function isAirdropActive() public view returns(bool){
        if(airdropCancelled == true || airdropEmpty == true){
            return false;
        }else{
            return true;
        }
    }

}