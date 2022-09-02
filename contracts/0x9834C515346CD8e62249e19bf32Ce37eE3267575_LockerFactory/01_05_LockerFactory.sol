// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Locker.sol";


contract LockerFactory is Ownable {

    uint public lockerCount;    

    uint public lockerFee = 0.1 ether;
    uint public updateLockerFee = 0.05 ether;

    mapping(address => address[]) private lockersListByTokenAddress;
    mapping(address => address[]) private lockersListByOwnerAddress;
    mapping(uint256 => address)   private lockersList;

    event LockerCreated (uint id, address owner, address token, address lockerAddress);
    event FundsWithdrawn (uint funds, uint timestamp);
    event FundsReceived (address sender, uint funds, uint timestamp);

    function createLocker(IERC20 _token, uint _numOfTokens, uint _unlockTime) payable public {

        require(msg.value >= lockerFee, "Please pay the fee");
        require(_unlockTime > 0, "The unlock time should in future");
        lockerCount++;
        
        Locker locker = new Locker(lockerCount, _msgSender(), _token, _numOfTokens, _unlockTime, updateLockerFee);
        _token.transferFrom(_msgSender(), address(locker), _numOfTokens);

        lockersListByOwnerAddress[_msgSender()].push(address(locker));
        lockersListByTokenAddress[address(_token)].push(address(locker));
        lockersList[lockerCount] = address(locker);

        emit LockerCreated (lockerCount, _msgSender(), address(_token), address(locker) );

    }

    function getLockersListbyToken(address _tokenAddress) public view returns (address[] memory) {
        return lockersListByTokenAddress[_tokenAddress];
    }

    function getLockersListbyOwner(address _owner) public view returns (address[] memory) {
        return lockersListByOwnerAddress[_owner];
    }
    function getLockerById(uint256 _id) public view returns (address) {
        require(_id <= lockerCount && _id > 0, "Locker ID out of range");
        return lockersList[_id];
    }

    function updateFees(uint _lockerFee, uint _updatingFee) public onlyOwner {
        lockerFee = _lockerFee;
        updateLockerFee = _updatingFee;
    }

    function withdrawFunds() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        bool transfer = payable(owner()).send(balance);
        require(transfer, "unable to transfer ETHs");
        emit FundsWithdrawn (balance, block.timestamp);
    }

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value, block.timestamp);
    }

}