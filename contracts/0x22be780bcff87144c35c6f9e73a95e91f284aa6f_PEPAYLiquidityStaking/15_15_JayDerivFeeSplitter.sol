//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract PEPAYFeeSplitter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;

    address private TEAM_WALLET;
    address private STAKER_WALLET;
    address private OP_WALLET;

    uint256 public MIN;

    uint16 public STAKER_FEE = 500;
    uint16 public OP_FEE = 250;
    uint16 public TEAM_FEE = 250;
    uint16 public constant FEE_BASE_1000 = 1000;

    event TeamWalletChanged(address teamWallet);
    event StakeWalletChanged(address teamWallet);
    event OPWalletChanged(address teamWallet);
    event MinValueChanged(uint256 min);

    constructor(address _rewardToken) {
        require(_rewardToken != address(0x0), "cannot set to 0x0 address");
        rewardToken = IERC20(_rewardToken);
        MIN = 1000000 * 10 ** 18;
    }

    /*
     * Name: splitFees
     * Purpose: Tranfer ETH to staking contracts and team
     * Parameters: n/a
     * Return: n/a
     */
    function splitFees() external nonReentrant {
        uint256 eth = rewardToken.balanceOf(address(this));
        if (eth > MIN) {
            sendEth(TEAM_WALLET, (eth * TEAM_FEE) / FEE_BASE_1000);
            sendEth(STAKER_WALLET, (eth * STAKER_FEE) / FEE_BASE_1000);
            sendEth(OP_WALLET, (eth * OP_FEE) / FEE_BASE_1000);
        }
    }

    function setTEAMWallet(address _address) external onlyOwner {
        require(_address != address(0x0), "cannot set to 0x0 address");
        TEAM_WALLET = _address;
    }

     function setSTAKERWallet(address _address) external onlyOwner {
        require(_address != address(0x0));
        STAKER_WALLET = payable(_address);
        emit StakeWalletChanged(_address);
    }

    function setOPWallet(address _address) external onlyOwner {
        require(_address != address(0x0));
        OP_WALLET = payable(_address);
        emit OPWalletChanged(_address);
    }
     function setMin(uint256 min) external onlyOwner {
        MIN = min;
        emit MinValueChanged(min);
    }

    /*
     * Name: sendEth
     * Purpose: Tranfer ETH tokens
     * Parameters:
     *    - @param 1: Address
     *    - @param 2: Value
     * Return: n/a
     */
    function sendEth(address _address, uint256 _value) internal {
        rewardToken.safeTransfer(_address, _value);
    }
}