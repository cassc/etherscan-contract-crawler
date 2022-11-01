// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DevFeeManager is Ownable {
    struct TokenInfo {
        IERC20 lpToken;
        uint256 oldBalance;
        uint256 runningTotal;
    }

    TokenInfo[] public tokenInfo;
    address[] public users;
    address[] public usersTemp;
    uint256 public stageBlock;
    mapping(address => uint256) public allocation; //number between 0 and 10000 (0.00% and 100.00%)
    mapping(address => uint256) public allocationTemp; //number between 0 and 10000 (0.00% and 100.00%)
    mapping(address => bool) public addedTokens;
    mapping(uint256 => mapping(address => uint256)) tokensClaimed;
    address public multiSigOne = address(0);
    address public multiSigTwo = address(0);
    mapping(address => bool) public signed;

    modifier onlySigner() {
        require(msg.sender == multiSigOne || msg.sender == multiSigTwo);
        _;
    }

    constructor() {}

    function initialize(
        address[] memory _address,
        uint256[] memory _allocations,
        address _multiSigOne,
        address _multiSigTwo
    ) public onlyOwner {
        require(multiSigOne == address(0) && multiSigTwo == address(0));
        require(_multiSigOne != address(0) && multiSigTwo != address(0));
        require(verifyAllocations(_address, _allocations));
        for (uint256 i = 0; i < _allocations.length; i++) {
            allocation[_address[i]] = _allocations[i];
            users.push(_address[i]);
        }
        multiSigOne = _multiSigOne;
        multiSigTwo = _multiSigTwo;
    }

    function verifyAllocations(
        address[] memory _address,
        uint256[] memory _allocations
    ) public pure returns (bool) {
        if (_address.length != _allocations.length) {
            return false;
        }
        uint256 sum = 0;
        for (uint256 i = 0; i < _allocations.length; i++) {
            sum += _allocations[i];
        }
        return sum == 10000;
    }

    function Sign() public {
        require(msg.sender == multiSigOne || msg.sender == multiSigTwo);
        require(!signed[msg.sender]);
        require(block.number - stageBlock > 50);
        signed[msg.sender] = true;
    }

    function Unsign() public {
        require(msg.sender == multiSigOne || msg.sender == multiSigTwo);
        require(signed[msg.sender]);
        signed[msg.sender] = false;
    }

    function updateEarned() public {
        for (uint256 i = 0; i < tokenInfo.length; i++) {
            uint256 tokenBalance = tokenInfo[i].lpToken.balanceOf(
                address(this)
            );
            uint256 tokenEarned = tokenBalance - tokenInfo[i].oldBalance;
            tokenInfo[i].oldBalance = tokenBalance;
            tokenInfo[i].runningTotal += tokenEarned;
        }
    }

    function claimForUser(address user) private {
        claimForUserHelper(user, 0, tokenInfo.length);
    }

    function widthdraw() public {
        updateEarned();
        claimForUser(msg.sender);
    }

    function widthdrawAll() public {
        updateEarned();
        for (uint256 j = 0; j < users.length; j++) {
            claimForUser(users[j]);
        }
    }

    function claimForUserHelper(
        address user,
        uint256 tokensStart,
        uint256 tokensEnd
    ) private {
        for (uint256 i = tokensStart; i < tokensEnd; i++) {
            uint256 allocatedTokens = (allocation[user] *
                tokenInfo[i].runningTotal) /
                10000 -
                tokensClaimed[i][user];
            if (allocatedTokens != 0) {
                tokenInfo[i].lpToken.transfer(user, allocatedTokens);
                tokenInfo[i].oldBalance -= allocatedTokens;
                tokensClaimed[i][user] += allocatedTokens;
            }
        }
    }

    function widthdraw(uint256 tokensStart, uint256 tokensEnd) public {
        updateEarned();
        claimForUserHelper(msg.sender, tokensStart, tokensEnd);
    }

    function widthdrawAll(uint256 tokensStart, uint256 tokensEnd) public {
        updateEarned();
        for (uint256 j = 0; j < users.length; j++) {
            claimForUserHelper(users[j], tokensStart, tokensEnd);
        }
    }

    function stageUserAllocationChanges(
        address[] memory _address,
        uint256[] memory _allocations
    ) public onlyOwner {
        require(verifyAllocations(_address, _allocations));
        usersTemp = _address;
        for (uint256 i = 0; i < _allocations.length; i++) {
            allocationTemp[_address[i]] = _allocations[i];
        }
        signed[multiSigOne] = false;
        signed[multiSigTwo] = false;
        stageBlock = block.number;
    }

    function setUserAllocationChanges() public {
        require(signed[multiSigOne] && signed[multiSigTwo]);
        widthdrawAll();
        for (uint256 i = 0; i < tokenInfo.length; i++) {
            tokenInfo[i].runningTotal = 0;
            tokenInfo[i].oldBalance = 0;
            for (uint256 j = 0; j < users.length; j++) {
                tokensClaimed[i][users[j]] = 0;
            }
        }
        users = usersTemp;
        for (uint256 i = 0; i < usersTemp.length; i++) {
            allocation[users[i]] = allocationTemp[users[i]];
        }
        signed[multiSigOne] = false;
        signed[multiSigTwo] = false;
    }

    function setUserAllocationChangesNoWithdraw() public {
        require(signed[multiSigOne] && signed[multiSigTwo]);
        for (uint256 i = 0; i < tokenInfo.length; i++) {
            tokenInfo[i].runningTotal = 0;
            tokenInfo[i].oldBalance = 0;
            for (uint256 j = 0; j < users.length; j++) {
                tokensClaimed[i][users[j]] = 0;
            }
        }
        users = usersTemp;
        for (uint256 i = 0; i < usersTemp.length; i++) {
            allocation[users[i]] = allocationTemp[users[i]];
        }
        signed[multiSigOne] = false;
        signed[multiSigTwo] = false;
    }

    function addTokens(address[] memory _address) public onlySigner {
        for (uint256 i = 0; i < _address.length; i++) {
            require(!addedTokens[_address[i]], "cant add dupe Token");
            tokenInfo.push(
                TokenInfo({
                    lpToken: IERC20(_address[i]),
                    runningTotal: 0,
                    oldBalance: 0
                })
            );
            addedTokens[_address[i]] = true;
        }
    }
}