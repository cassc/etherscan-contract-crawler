// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Sidus_Party_Xenna is Ownable, Pausable {
    address payable public beneficiary;
    uint256 public activeAfter; // date of start presale
    uint256 public closedAfter; // date of end presalr
    bool public whitelistMode;
    mapping(address => bool) public userWhiteList;
    uint public priceForCard;

    event Purchase(
        address indexed user,
        address indexed destinationAddress,
        uint amount
    );

    struct GiftStruct {
        address sender;
        uint amount;
    }

    mapping(address => uint) public userBalances;
    // reveiver -> gifts
    mapping(address => GiftStruct[]) public gifts;
    // receiver -> count of gifts
    mapping(address => uint) public giftsSendersCount;

    constructor(
        address _beneficiary,
        uint256 _activeAfter,
        uint256 _closedAfter
    ) {
        require(_beneficiary != address(0), "No zero addess");
        beneficiary = payable(_beneficiary);
        activeAfter = _activeAfter;
        closedAfter = _closedAfter;
    }

    function registerForPreSale(address destinationAddress, uint amount)
        external
        payable
        whenNotPaused
    {
        require(block.timestamp >= activeAfter, "Cant buy before start");
        require(block.timestamp <= closedAfter, "Cant buy after closed");
        if (whitelistMode) {
            require(userWhiteList[msg.sender], "you are not in whitelist");
        }
        uint userDebt = amount * priceForCard;
        emit Purchase(msg.sender, destinationAddress, amount);

        require(msg.value == userDebt, "not enought eth");
        beneficiary.transfer(msg.value);
        if (destinationAddress == msg.sender) {
            userBalances[msg.sender] += amount;
        } else {
            uint sendersLen = giftsSendersCount[destinationAddress];
            uint foundSender;
            for (uint i; i < sendersLen; ) {
                if (gifts[destinationAddress][i].sender == msg.sender) {
                    gifts[destinationAddress][i].amount += amount;
                    foundSender = 1;
                    break;
                }
                unchecked {
                    i++;
                }
            }
            if (foundSender == 0) {
                // new gift
                GiftStruct memory newGift = GiftStruct(msg.sender, amount);
                gifts[destinationAddress].push(newGift);
                giftsSendersCount[destinationAddress] += 1;
            }
        }
    }

    ///////////////////////////////////////////////////////////////////
    /////  Owners Functions ///////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////

    function setStartStop(uint256 _activeAfter, uint256 _closedAfter)
        external
        onlyOwner
    {
        activeAfter = _activeAfter;
        closedAfter = _closedAfter;
    }

    function setBeneficiary(address payable _beneficiary) external onlyOwner {
        require(_beneficiary != address(0), "No zero addess");
        beneficiary = _beneficiary;
    }

    function setETHPrice(uint256 _newPriceValue) external onlyOwner {
        priceForCard = _newPriceValue;
    }

    function setWhitelist(address user, bool value) external onlyOwner {
        userWhiteList[user] = value;
    }

    function addToWhitelist(address[] calldata _user) external onlyOwner {
        uint arrLen = _user.length;
        for (uint i; i < arrLen; ) {
            userWhiteList[_user[i]] = true;
            unchecked {
                i++;
            }
        }
    }

    function deleteFromWhitelist(address[] calldata _user) external onlyOwner {
        uint arrLen = _user.length;
        for (uint i; i < arrLen; ) {
            unchecked {
                i++;
            }
            userWhiteList[_user[i]] = false;
        }
    }

    function whitelistChangeMode(bool _newValue) external onlyOwner {
        whitelistMode = _newValue;
    }
}