// SPDX-License-Identifier: UNLICENSED
/*pragma solidity 0.8.9;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

contract RAMStaking is OwnableUpgradeable {

    address public immutable ramTokenAddress;

    uint256[] public contributionsByRef;
    mapping(address => bool) public rootOf;
    mapping(address => UserInfo) public userInfoOf;

    event Register(address indexed refAddress, address account);

    struct UserInfo {
        address refAddress;
        uint256 inviteNum;
        uint256 contribution;

        // calc reward...
        uint256 stakedAmount;
        uint256 lastUpdateTime;
    }

    // modifier updateReward(address account) {
    //     uint256 lastUpdateTime = userInfoOf[account].lastUpdateTime;
    //     userInfoOf[account].lastUpdateTime = block.timestamp;


    // }

    constructor(
        address _ramTokenAddress
    ) {
        ramTokenAddress = _ramTokenAddress;
    }

    function register(address _refAddress) external {
        require(userInfoOf[msg.sender].refAddress == address(0), 'RAMStaking: already registered.');
        require(
            userInfoOf[_refAddress].refAddress != address(0) || rootOf[_refAddress],
                'RAMStaking: the ref address invalid.'
        );

        userInfoOf[_refAddress].inviteNum++;
        userInfoOf[msg.sender].refAddress = _refAddress;

        // address currentRef = _refAddress;
        // uint256 contributionDistributeLength = contributionsByRef.length;
        // for (uint256 index; index < contributionDistributeLength; index++) {
        //     userInfoOf[currentRef].contribution += contributionsByRef[index];
        //     currentRef = userInfoOf[currentRef].refAddress;

        //     if (currentRef == address(0)) break;
        // }

        emit Register(_refAddress, msg.sender);
    }

    function stake(uint256 _amount) external {
        require(
            userInfoOf[msg.sender].refAddress != address(0) || rootOf[msg.sender],
                'RAMStaking: not a valid address.'
        );

        uint256 _stakedAmount = userInfoOf[msg.sender].stakedAmount;
        // if (expression) {
            
        // }
    }

//    function _rewardRate(uint256 _account) private view returns (uint256) {
//        uint256 con
//        uint256 rewardPerDay = userInfoOf[_account].stakedAmount;
//    }
}*/