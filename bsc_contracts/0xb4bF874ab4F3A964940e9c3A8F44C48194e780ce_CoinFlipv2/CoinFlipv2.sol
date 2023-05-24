/**
 *Submitted for verification at BscScan.com on 2023-05-23
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-23
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract CoinFlipv2 is ReentrancyGuard {
    address payable public owner;
    uint256 public betAmount = 0.03 ether;
    uint256 public payoutAmount = 0.05 ether;
    uint256 public houseEdge = 0.01 ether;
    uint256 public accumulatedHouseEdge = 0;

    uint256 public totalGamesPlayed;
    uint256 public totalWins;
    uint256 public totalLosses;
    uint256 public totalBNBCollected;
    uint256 public totalBNBDistributed;

    event GamePlayed(address indexed player, bool indexed win);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    constructor() {
        owner = payable(msg.sender);
    }

    function flipCoin() public payable returns (bool) {
        require(msg.value == betAmount, "Incorrect bet amount");

        totalGamesPlayed++;
        totalBNBCollected += msg.value;

        uint256 kasd92h = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    block.number,
                    blockhash(block.number - 1),
                    msg.sender
                )
            )
        );
        uint256 n8ya93hka = uint256(
            keccak256(abi.encodePacked(kasd92h, block.timestamp))
        );
        uint256 a93bfdka3fgaj2g = uint256(
            keccak256(abi.encodePacked(n8ya93hka, block.number))
        );
        uint256 yq3qi34iiyg = uint256(
            keccak256(
                abi.encodePacked(
                    a93bfdka3fgaj2g,
                    blockhash(block.number - 1)
                )
            )
        );
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(yq3qi34iiyg, msg.sender))
        );

        bool result = randomNumber % 2 == 0 ? true : false;
        if (result) {
            payable(msg.sender).transfer(payoutAmount);
            accumulatedHouseEdge += houseEdge;
            totalWins++;
            totalBNBDistributed += payoutAmount;
        } else {
            accumulatedHouseEdge += msg.value;
            totalLosses++;
        }

        emit GamePlayed(msg.sender, result);

        if (accumulatedHouseEdge >= 0.1 ether) {
            uint256 toTransfer = accumulatedHouseEdge;
            accumulatedHouseEdge = 0;
            owner.transfer(toTransfer);
        }

        return result;
    }

    function fundContract() public payable {
        require(
            msg.sender == owner,
            "Only owner can execute an emergency withdrawal"
        );
        require(msg.value == 0.2 ether, "You must send exactly 0.2 BNB");
        // the sent BNB is automatically added to the contract's balance
    }


    function claimFees() public {
        require(msg.sender == owner, "Only owner can claim fees");
        uint256 toTransfer = accumulatedHouseEdge;
        accumulatedHouseEdge = 0;
        owner.transfer(toTransfer);
    }

    function emergencyWithdraw() public {
        require(
            msg.sender == owner,
            "Only owner can execute an emergency withdrawal"
        );
        uint256 balance = address(this).balance;
        owner.transfer(balance);
    }
}