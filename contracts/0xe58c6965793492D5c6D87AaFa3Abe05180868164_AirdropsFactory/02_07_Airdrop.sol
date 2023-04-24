// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



interface IAdmin1 {
    function isAdmin(address user) external view returns (bool);
}


contract ArborswapAirdrop {
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

    bool public airDropStarted;
    bool public airdropCancelled;
    bool public airdropEmpty;

    address public owner;
    IAdmin1 public admin;

    mapping(address => bool) public isWL;
    mapping(address => Participation) public userToParticipation;
    mapping(address => bool) public isOwner;

    struct Participation{
       uint256 allocation;
       bool claimed;
    }

    event LogSetAllocation(address user, uint256 amount);
    event LogClaimed(address user, uint256 amount);
    event LogCancelAirdrop(uint256 time, uint256 amountRefunded);
    event LogStartAirdrop(uint256 _startTime, uint256 totalToAirdrop);
    event LogRemoveAllocation(address user);


    // Restricting calls only to sale owner or Admin
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
        admin = IAdmin1(_admin);
        owner = _owner;
        airdropInfo.isPrivate = true;
        isOwner[owner] = true;
    }

    function getInfo() external view returns(AirdropInfo memory){
        return airdropInfo;
    }

    function setAllocation(address user, uint256 _allocation) private {
        require(_allocation != 0, "Allocation can't be 0");
        require(user != address(0), "Zero address validation");
        Participation memory p = Participation({
            allocation: _allocation,
            claimed: false
        });
        airdropInfo.numberWLAddresses = airdropInfo.numberWLAddresses.add(1);
        airdropInfo.totalAmountToAirdrop = airdropInfo.totalAmountToAirdrop.add(_allocation);
        userToParticipation[user] = p;
        isWL[user] = true;
        emit LogSetAllocation(user, _allocation);
    }

    function setAllocations(address[] memory addys, uint256[] memory allocations) external onlyAirdropOwner{
        require(airDropStarted != true, "Airdrop already started");
        require(addys.length == allocations.length, "Invalid input");

        for (uint256 i = 0; i < addys.length; i++) {
            setAllocation(addys[i], allocations[i]);
        }
    }

    function removeAllocations(address[] memory addys) external onlyAirdropOwner{
        require(airDropStarted != true, "Airdrop already started");

        for (uint256 i = 0; i < addys.length; i++) {
            removeAllocation(addys[i]);
        }
    }

    function removeAllocation(address user) private {
        require(user != address(0), "Zero address validation");
        require(isWL[user] == true, "Address not whitelisted");

        Participation storage p = userToParticipation[msg.sender];
        uint256 previosAllocation = p.allocation;
        airdropInfo.totalAmountToAirdrop = airdropInfo.totalAmountToAirdrop.sub(previosAllocation);

        p.allocation = 0;
        userToParticipation[user] = p;
        isWL[user] = false;
        airdropInfo.numberWLAddresses = airdropInfo.numberWLAddresses.sub(1);

        emit LogRemoveAllocation(user);
    }

    function start(uint256 _startTime) external onlyAirdropOwner{
        require(airDropStarted != true, "Already started");
        require(_startTime >= block.timestamp, "Start time should be in the future");

        airdropInfo.startTime = _startTime;
        airDropStarted = true;

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
        require(isWL[msg.sender], "Only for whitelisted");
        Participation storage p = userToParticipation[msg.sender];
        require(p.claimed != true, "Already claimed");
        require(airdropEmpty!= true, "Airdrop Empty");
        require(airdropCancelled != true, "Airdrop cancelled");
        require(airDropStarted == true, "Airdrop haven't started yet");

        uint256 amount = p.allocation;
        p.claimed = true;
        airdropInfo.totalAmountDistributed = airdropInfo.totalAmountDistributed.add(amount);
        airdropInfo.numberOfParticipants++;

        if(airdropInfo.totalAmountDistributed == airdropInfo.totalAmountToAirdrop){
            airdropEmpty = true;
        }

        IERC20(airdropInfo.token).transfer(msg.sender, amount);

        emit LogClaimed(msg.sender, amount);
    }

    function isAirdropActive() public view returns(bool){
        if(airdropCancelled == true || airdropEmpty == true){
            return false;
        }else{
            return true;
        }
    }
    
    function getParticipation(address _user)
        external
        view
        returns (
            uint256,
            bool
        )
    {
        Participation memory p = userToParticipation[_user];
        return (
            p.allocation,
            p.claimed
        );
    }

}