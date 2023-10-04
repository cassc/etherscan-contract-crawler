// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WEbdEXSwapBookV3 is Ownable {
    uint256 internal ownerValue;

    using Counters for Counters.Counter;

    Counters.Counter internal _swapIds;

    mapping(address => mapping(uint256 => Swap)) internal swaps;

    Swap[] internal allSwaps;

    enum Status {
        PENDING,
        CANCELED,
        SOLD
    }

    struct Swap {
        uint256 id;
        address seller;
        address leftToken;
        uint256 leftTokenAmount;
        address rightToken;
        uint256 rightTokenAmount;
        Status status;
    }

    struct SwapInfo {
        uint256 id;
        address seller;
        address leftToken;
        uint256 leftTokenAmount;
        address rightToken;
        uint256 rightTokenAmount;
    }

    event Transaction(
        address indexed from,
        address indexed to,
        string method,
        uint256 timeStamp,
        uint256 value
    );

    constructor(uint256 ownerValue_) {
        ownerValue = ownerValue_;
    }

    function createSwap(
        address leftToken,
        uint256 leftTokenAmount,
        address rightToken,
        uint256 rightTokenAmount
    ) public payable {
        require(msg.value == ownerValue, "The sent value must be exactly");
        require(leftTokenAmount > 0, "Amount1 must be greater than 0");
        require(rightTokenAmount > 0, "Amount2 must be greater than 0");
        ERC20 leftTokenContract = ERC20(leftToken);
        require(
            leftTokenContract.allowance(msg.sender, address(this)) >=
                leftTokenAmount,
            "Contract not approved to spend user's tokens"
        );

        _swapIds.increment();
        uint256 newSwapId = _swapIds.current();

        Swap memory newSwap = Swap(
            newSwapId,
            msg.sender,
            leftToken,
            leftTokenAmount,
            rightToken,
            rightTokenAmount,
            Status.PENDING
        );

        leftTokenContract.transferFrom(
            msg.sender,
            address(this),
            leftTokenAmount
        );
        swaps[msg.sender][newSwapId] = newSwap;
        allSwaps.push(newSwap);

        emit Transaction(
            msg.sender,
            address(this),
            "Create Swap",
            block.timestamp,
            msg.value
        );
    }

    function swapTokens(address seller, uint256 swapId) public payable {
        require(msg.value == ownerValue, "The sent value must be exactly");
        require(
            swaps[seller][swapId].status == Status.PENDING,
            "Swap status is not PENDING"
        );
        Swap memory currentSwap = swaps[seller][swapId];
        ERC20 leftTokenContract = ERC20(currentSwap.leftToken);
        ERC20 rightTokenContract = ERC20(currentSwap.rightToken);
        require(
            rightTokenContract.allowance(msg.sender, address(this)) >=
                currentSwap.rightTokenAmount,
            "Contract not approved to spend user's tokens"
        );

        rightTokenContract.transferFrom(
            msg.sender,
            address(this),
            currentSwap.rightTokenAmount
        );
        leftTokenContract.transfer(msg.sender, currentSwap.leftTokenAmount);
        rightTokenContract.transfer(
            currentSwap.seller,
            currentSwap.rightTokenAmount
        );
        swaps[seller][swapId].status = Status.SOLD;

        emit Transaction(
            msg.sender,
            currentSwap.seller,
            "Swap Tokens",
            block.timestamp,
            msg.value
        );
    }

    function cancelSwap(uint256 swapId) public {
        require(
            swaps[msg.sender][swapId].status == Status.PENDING,
            "Swap status is not PENDING"
        );

        Swap memory currentSwap = swaps[msg.sender][swapId];

        ERC20 leftTokenContract = ERC20(currentSwap.leftToken);

        leftTokenContract.transfer(msg.sender, currentSwap.leftTokenAmount);
        swaps[msg.sender][swapId].status = Status.CANCELED;

        emit Transaction(
            msg.sender,
            address(this),
            "Cancel Swap",
            block.timestamp,
            0
        );
    }

    function getPendingSwaps() public view returns (SwapInfo[] memory) {
        uint256 pendingCount = 0;
        uint256 length = allSwaps.length;

        for (uint256 i = 0; i < length; i++) {
            if (
                swaps[allSwaps[i].seller][allSwaps[i].id].status ==
                Status.PENDING
            ) {
                pendingCount++;
            }
        }

        SwapInfo[] memory currentSwaps = new SwapInfo[](pendingCount);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < length; i++) {
            if (
                swaps[allSwaps[i].seller][allSwaps[i].id].status ==
                Status.PENDING
            ) {
                currentSwaps[currentIndex] = SwapInfo(
                    swaps[allSwaps[i].seller][allSwaps[i].id].id,
                    swaps[allSwaps[i].seller][allSwaps[i].id].seller,
                    swaps[allSwaps[i].seller][allSwaps[i].id].leftToken,
                    swaps[allSwaps[i].seller][allSwaps[i].id].leftTokenAmount,
                    swaps[allSwaps[i].seller][allSwaps[i].id].rightToken,
                    swaps[allSwaps[i].seller][allSwaps[i].id].rightTokenAmount
                );
                currentIndex++;
            }
        }

        return currentSwaps;
    }

    function getOwnerValue() public view returns (uint256) {
        return ownerValue;
    }

    function withdrawFees() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}