/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

////////////////////////////////////////////////////////////////////////

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

////////////////////////////////////////////////////////////////////////

interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

////////////////////////////////////////////////////////////////////////

contract RaFFLeZ is Ownable {
    IERC20 public token = IERC20(0xACB3F64AA4B8e25c07320b476342Cd6152f561aE);

    uint256 public ticketPrice = 100000000000000000000000000;
    uint256 public maxPool = 10000000000000000000000000000;
    address public feeReceiver;
    uint256 public rafflePool;
    uint256 public timeLimit;
    uint256 public endTime;
    uint256 public winner;
    uint256 public totalTickets;
    uint256 public seed = 1337;
    bool public raffleLive = false;
    bool public winnerPicked = false;

    mapping(uint256 => address) public ticketHolders;

    event TicketsBought(address indexed buyer, uint256 amount, uint256 payment);
    event WinnerPicked(address winner, uint256 prize);

    constructor() {
        feeReceiver = msg.sender;
    }

    function startRaffle(uint256 _timeLimit, uint256 _ticketPrice) external onlyOwner {
        require(!raffleLive, "Raffle is already live");
        require(rafflePool == 0, "Raffle still in progress");

        timeLimit = _timeLimit;
        ticketPrice = _ticketPrice;
        endTime = block.timestamp + timeLimit;
        raffleLive = true;
        winnerPicked = false;
    }

    function buyTickets(uint256 _amount) public {
        require(raffleLive, "Raffle is not currently live");
        require(_amount > 0, "Invalid amount");
        uint256 payment = _amount * ticketPrice;
        require(rafflePool + payment <= maxPool, "Raffle pool limit reached");
        require(token.balanceOf(msg.sender) >= payment, "Insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= payment, "Insufficient token allowance");
        require(token.transferFrom(msg.sender, address(this), payment), "Transfer failed");

        for (uint256 i = 0; i < _amount; i++) {
            uint256 ticketNumber = totalTickets + 1;
            ticketHolders[ticketNumber] = msg.sender;
            totalTickets++;
        }
        rafflePool += payment;
        emit TicketsBought(msg.sender, _amount, payment);

        if (rafflePool == maxPool) {
            drawTicket();
            claim();
        }
    }

    function drawTicket() public {
        require(raffleLive, "Raffle is not currently live");
        require(block.timestamp >= endTime || rafflePool == maxPool, "Raffle still in progress");
        require(totalTickets > 0, "No tickets sold");
        require(!winnerPicked, "Winner already picked");
        
        uint256 winningTicket = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, rafflePool, totalTickets, seed))) % totalTickets + 1;
        winner = winningTicket;
        seed = winner;
        emit WinnerPicked(ticketHolders[winner], rafflePool * 95 / 100);

        winnerPicked = true;
        claim(); 
    }


    function claim() public {
        require(winner > 0, "Winner not determined");
        require(block.timestamp >= endTime || rafflePool >= maxPool, "Raffle still in progress");
        uint256 winnings = rafflePool * 95 / 100;
        rafflePool = 0;
        require(token.transfer(ticketHolders[winner], winnings), "Token transfer failed");
        uint256 remainingBalance = token.balanceOf(address(this));
        require(token.transfer(feeReceiver, remainingBalance), "Token transfer to feeReceiver failed");
        winner = 0;
        for (uint256 i = 0; i < totalTickets; i++) {
            delete ticketHolders[i];
        }
        totalTickets = 0;
        raffleLive = false;
    }

}