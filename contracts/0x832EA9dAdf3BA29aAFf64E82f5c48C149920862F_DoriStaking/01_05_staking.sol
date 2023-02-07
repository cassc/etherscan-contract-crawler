// @author: @gizmolab_
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DoriStaking is Ownable {
    bool public stakingEnabled = false;
    bool public burnEnabled = false;
    uint256 public totalStaked;
    uint256 public baseReward = 5;
    address public doriGenesisContract;
    address public dori1776Contract;
    address public sweeperClubContract;

    struct Stake {
        address owner; // 32bits
        uint128 timestamp; // 32bits
    }

    struct Burn {
        address owner; // 32bits
        uint128 timestamp; // 32bits
    }

    mapping(address => mapping(uint256 => Stake)) public vault;
    mapping(address => mapping(address => uint256[])) public userStakeTokens;
    mapping(address => mapping(address => uint256[])) public userBurnTokens;
    mapping(address => bool) public isVaultContract;
    mapping(address => uint256) public vaultMultiplier;
    mapping(address => uint256) public burnClaimed;

    event NFTStaked(
        address owner,
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    );
    event NFTUnstaked(
        address owner,
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    );
    event NFTBurned(
        address owner,
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    );

    /*==============================================================
    ==                    User Staking Functions                  ==
    ==============================================================*/

    function stakeNfts(address _contract, uint256[] calldata tokenIds)
        external
    {
        require(stakingEnabled == true, "Staking is not enabled yet.");
        require(isVaultContract[_contract] == true, "Contract not allowed");

        IERC721 nftContract = IERC721(_contract);

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                nftContract.ownerOf(tokenIds[i]) == msg.sender,
                "You do not own this token"
            );
            nftContract.transferFrom(msg.sender, address(this), tokenIds[i]);
            vault[_contract][tokenIds[i]] = Stake(
                msg.sender,
                uint128(block.timestamp)
            );
            userStakeTokens[msg.sender][_contract].push(tokenIds[i]);
            emit NFTStaked(msg.sender, _contract, tokenIds[i], block.timestamp);
            totalStaked++;
        }
    }

    function unstakeNfts(address _contract, uint256[] calldata tokenIds)
        external
    {
        require(stakingEnabled == true, "Staking is not enabled yet.");
        require(isVaultContract[_contract] == true, "Contract not allowed");
        IERC721 nftContract = IERC721(_contract);

        for (uint256 i; i < tokenIds.length; i++) {
            bool isTokenOwner = false;
            uint256 tokenIndex = 0;

            for (
                uint256 j;
                j < userStakeTokens[msg.sender][_contract].length;
                j++
            ) {
                if (userStakeTokens[msg.sender][_contract][j] == tokenIds[i]) {
                    isTokenOwner = true;
                    tokenIndex = j;
                }
            }

            require(isTokenOwner == true, "You do not own this Token");

            nftContract.transferFrom(address(this), msg.sender, tokenIds[i]);

            delete vault[_contract][tokenIds[i]];
            totalStaked--;

            userStakeTokens[msg.sender][_contract][
                tokenIndex
            ] = userStakeTokens[msg.sender][_contract][
                userStakeTokens[msg.sender][_contract].length - 1
            ];
            userStakeTokens[msg.sender][_contract].pop();

            emit NFTUnstaked(
                msg.sender,
                _contract,
                tokenIds[i],
                block.timestamp
            );
        }
    }

    /*==============================================================
    ==                    Burn Function                           ==
    ==============================================================*/

    function burnNfts(uint256[] calldata tokenIds) external {
        require(burnEnabled, "Burn is not yet Live");
        require(dori1776Contract != address(0), "DoriGen2 Contract not set");
        IERC721 nftContract = IERC721(dori1776Contract);

        for (uint256 i; i < tokenIds.length; i++) {
            bool isTokenOwner = false;
            uint256 tokenIndex = 0;

            for (
                uint256 j;
                j < userStakeTokens[msg.sender][dori1776Contract].length;
                j++
            ) {
                if (
                    userStakeTokens[msg.sender][dori1776Contract][j] ==
                    tokenIds[i]
                ) {
                    isTokenOwner = true;
                    tokenIndex = j;
                }
            }

            require(isTokenOwner == true, "You do not own this Token");

            nftContract.transferFrom(address(this), address(0), tokenIds[i]);
            emit NFTBurned(
                msg.sender,
                dori1776Contract,
                tokenIds[i],
                block.timestamp
            );
            uint256 reward = _calculateReward(msg.sender, dori1776Contract);
            burnClaimed[msg.sender] += reward;

            delete vault[dori1776Contract][tokenIds[i]];
            totalStaked--;

            userBurnTokens[msg.sender][dori1776Contract].push(tokenIds[i]);
            userStakeTokens[msg.sender][dori1776Contract][
                tokenIndex
            ] = userStakeTokens[msg.sender][dori1776Contract][
                userStakeTokens[msg.sender][dori1776Contract].length - 1
            ];
            userStakeTokens[msg.sender][dori1776Contract].pop();
        }
    }

    /*==============================================================
    ==                    Public Get Functions                    ==
    ==============================================================*/

    function getStakedTokens(address _user, address _contract)
        external
        view
        returns (uint256[] memory)
    {
        return userStakeTokens[_user][_contract];
    }

    function getBurnedTokens(address _user, address _contract)
        external
        view
        returns (uint256[] memory)
    {
        return userBurnTokens[_user][_contract];
    }

    function getRewards(address _user, address[] calldata vaultContracts)
        external
        view
        returns (uint256)
    {
        uint256 reward = 0;
        uint256 i;
        for (i = 0; i < vaultContracts.length; i++) {
            reward += _calculateReward(_user, vaultContracts[i]);
        }
        if (burnClaimed[_user] > 0) {
            reward += burnClaimed[_user] * 1e18;
        }
        return reward;
    }

    function getBurnedRewards(address _user) external view returns (uint256) {
        return burnClaimed[_user];
    }

    /*==============================================================
    ==                    Owner Functions                         ==
    ==============================================================*/

    function addVault(address _contract, uint256 _multiplier) public onlyOwner {
        require(isVaultContract[_contract] == false, "Contract already added");
        isVaultContract[_contract] = true;
        vaultMultiplier[_contract] = _multiplier;
    }

    function setStakingEnabled(bool _enabled) external onlyOwner {
        stakingEnabled = _enabled;
    }

    function setBaseReward(uint256 _reward) external onlyOwner {
        baseReward = _reward;
    }

    function setMultiplier(address _contract, uint256 _multiplier)
        external
        onlyOwner
    {
        require(isVaultContract[_contract] == true, "Contract not added");
        vaultMultiplier[_contract] = _multiplier;
    }

    function setBurnEnabled(bool _enabled) external onlyOwner {
        burnEnabled = _enabled;
    }

    function setDori1776Contract(address _contract) external onlyOwner {
        dori1776Contract = _contract;
    }

    function setSweeperClubContract(address _contract) external onlyOwner {
        sweeperClubContract = _contract;
    }

    /*==============================================================
    ==                     Reward Calculate Functions             ==
    ==============================================================*/

    function _calculateReward(address _user, address _contract)
        internal
        view
        returns (uint256)
    {
        uint256 reward = 0;
        for (uint256 i; i < userStakeTokens[_user][_contract].length; i++) {
            uint256 token = userStakeTokens[_user][_contract][i];
            uint256 timeSinceStake = block.timestamp -
                vault[_contract][token].timestamp;
            uint256 rewardPerToken = baseReward * vaultMultiplier[_contract];
            reward += timeSinceStake * rewardPerToken * 1e18;
        }
        return reward / 86400;
    }
}