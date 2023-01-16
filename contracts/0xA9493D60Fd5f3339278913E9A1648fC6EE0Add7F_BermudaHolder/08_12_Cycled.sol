// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
contract Cycled is Ownable {

    mapping(address => uint256) public authorizedToIndexPlusOne;
    mapping(uint256 => address) public indexToAuthorized;
    uint256 public currentIndex;
    uint256 public indicesLen;
    bool public cycleMode; //Off by default. Convenient for testing. Make sure to enable once ready.

    modifier onlyAuthorized() {
        require(authorizedToIndexPlusOne[msg.sender] > 0 || owner() == msg.sender, "Not authorized");
        _;
    }

    modifier onlyCycledAuthorized() {
        if(!cycleMode)
        {
            require(authorizedToIndexPlusOne[msg.sender] > 0 || owner() == msg.sender, "Not authorized");
            _;
            return;
        }
        //currentIndex = currentIndex % maxIndex;
        address currentAuthorized = indexToAuthorized[currentIndex];
        require(currentAuthorized != address(0) && msg.sender == currentAuthorized, "Not currently authorized");
        currentIndex = (currentIndex + 1) % indicesLen;
        _;
    }

    function addAuthorized(address addressToAdd) onlyOwner public {
        require(addressToAdd != address(0), "Bad address");
        require(authorizedToIndexPlusOne[addressToAdd] == 0, "Address is already authorized");
        uint256 indexToAdd = indicesLen;
        authorizedToIndexPlusOne[addressToAdd] = indexToAdd + 1;
        indexToAuthorized[indexToAdd] = addressToAdd;
        indicesLen += 1;
    }

    function removeAuthorizedByIndex(uint256 indexToRemove) onlyOwner public {
        require(indexToRemove < indicesLen, "Index does not exist");
        address addressToRemove = indexToAuthorized[currentIndex];
        uint256 lastIndex = indicesLen - 1;
        address lastAddress = indexToAuthorized[lastIndex];
        authorizedToIndexPlusOne[lastAddress] = indexToRemove; //Swap with last address
        authorizedToIndexPlusOne[addressToRemove] = 0; //Remove from address mapping
        indexToAuthorized[indexToRemove] = lastAddress; //Swap with last index
        indexToAuthorized[lastIndex] = address(0); //Remove from index mapping
        indicesLen -= 1;
        if(indicesLen != 0) currentIndex = currentIndex % indicesLen;
        else currentIndex = 0;
    }

    function removeAuthorized(address addressToRemove) onlyOwner public {
        require(addressToRemove != address(0), "Bad address");
        require(authorizedToIndexPlusOne[addressToRemove] > 0, "Address is not authorized");
        removeAuthorizedByIndex(authorizedToIndexPlusOne[addressToRemove] - 1);
    }

    function setCycleMode(bool mode) onlyOwner public {
        cycleMode = mode;
    }

    function getCycledAuthorized() external view returns (address)
    {
        return indexToAuthorized[currentIndex];
    }

}