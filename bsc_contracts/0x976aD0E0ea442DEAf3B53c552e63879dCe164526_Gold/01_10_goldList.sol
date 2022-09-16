//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-0.8/utils/Counters.sol";
import "./utils/AccessProtected.sol";

contract Gold is Ownable, AccessProtected, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    address public token;
    address public payment;
    Counters.Counter public goldNumber;

    mapping(address => bool) public goldList;

    address[] public goldMembers;

    constructor(address _token, address _payment) {
        require(_token.isContract(), "Invalid native Token Address");
        require(_payment.isContract(), "Invalid payment Token Address");
        token = _token;
        payment = _payment;
    }

    function addGoldList(address _address, bool status) public onlyAdmin {
        require(_address != address(0), "Can't add 0 address");
        goldList[_address] = status;
        goldNumber.increment();

        emit goldListAddition(_address, status);
    }

    function addBatchGoldList(address[] memory goldAddresses, bool[] memory status) public onlyAdmin {
        require(goldAddresses.length == status.length, "Length mismatch!");

        for (uint256 i = 0; i < goldAddresses.length; i++) {
        addGoldList(goldAddresses[i], status[i]);
        goldNumber.increment();
        }

        emit batchGoldListAddition(goldAddresses, status);
    }

    function revokeGoldList() public onlyOwner {
        for(uint256 i; i < goldNumber.current(); i++) {
            address member = goldMembers[i];
            goldList[member] = false;
        }

        goldNumber._value = 0;
        emit goldListRevoked();
    }

    function claimTokens(uint256 amount) public payable nonReentrant {
        require(amount > 0, "Cannot mint 0 Tokens");
        require(goldList[_msgSender()], "Caller is not in Gold list");
        
        IERC20(token).approve(address(this), amount);
        IERC20(token).transferFrom(_msgSender(), address(this), amount.mul(100));
        IERC20(token).transfer(_msgSender(), amount);

        emit tokensClaimed(amount);
    }

    event goldListAddition(address _address, bool status);
    event batchGoldListAddition(address[] addresses, bool[] status);
    event goldListRevoked();
    event tokensClaimed(uint256 amount);

    receive() external payable {}
}