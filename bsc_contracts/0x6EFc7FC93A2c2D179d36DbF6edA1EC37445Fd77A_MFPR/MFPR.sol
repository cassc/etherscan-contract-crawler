/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBEP20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address, address, uint) external returns (bool);
}
contract MFPR {

    struct Participant {
        address participantAddress;
        uint allocationAmount;
    }

    address public recipient = 0x85cADD0b4be3124984077c6e9C094F09d77Ee558; 
    
    IBEP20 public immutable usdtToken;
    uint public totalAmount; 
    address public owner;
    mapping (address => uint ) public alocationAmount; // store participant's contribution amount
    mapping(address => bool) inserted;
    address[] participants;
    bool public started = true;
    event DonationReceived(address indexed donor,  uint256 amount);

    constructor(address _usdtAddress) {
        usdtToken = IBEP20(_usdtAddress);
        owner = msg.sender;
    }

    function contribute( uint _amount) public {
        require(started , "ICO paused");
        require( totalAmount + _amount <= (670000 * 10**18), "Alocation ended" );
        require((_amount >= 5 * 10 **18) && (_amount <= 5000 * 10 **18), "Over the allowed range");
        bool success = usdtToken.transferFrom(msg.sender,address(this), _amount);
        require(success, "Transfer failed");

        if (inserted[msg.sender]) {
            alocationAmount[msg.sender] += _amount;
        } else {
            inserted[msg.sender] = true;
            alocationAmount[msg.sender] = _amount; 
            participants.push(msg.sender);
        }
        totalAmount += _amount;
        emit DonationReceived(msg.sender, _amount);
    }

    function getParticipants() public view returns (Participant[] memory) {
        Participant[] memory result = new Participant[](participants.length);
        for (uint i = 0; i < participants.length; i++) {
            result[i] = Participant(participants[i],  alocationAmount[participants[i]]);
        }
        return result;
    }

    function getUSDTbalance() public view returns(uint){
        return usdtToken.balanceOf(address(this));
    }

    function pause() public {
        require(msg.sender == owner, "Only the owner can pause the ico");
        started = !started; 
    }

    function withdraw( uint _amount) public {
        require(msg.sender == owner, "Only the owner can withdraw tokens");
        require(_amount <= usdtToken.balanceOf(address(this)), "Insufficient balance");
        usdtToken.transfer(recipient, _amount);
    }
}