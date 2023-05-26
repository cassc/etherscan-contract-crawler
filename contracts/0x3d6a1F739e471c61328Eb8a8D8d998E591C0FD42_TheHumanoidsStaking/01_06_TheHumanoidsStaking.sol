// SPDX-License-Identifier: MIT

/*
                    ████████╗██╗  ██╗███████╗
                    ╚══██╔══╝██║  ██║██╔════╝
                       ██║   ███████║█████╗
                       ██║   ██╔══██║██╔══╝
                       ██║   ██║  ██║███████╗
                       ╚═╝   ╚═╝  ╚═╝╚══════╝
██╗  ██╗██╗   ██╗███╗   ███╗ █████╗ ███╗   ██╗ ██████╗ ██╗██████╗ ███████╗
██║  ██║██║   ██║████╗ ████║██╔══██╗████╗  ██║██╔═══██╗██║██╔══██╗██╔════╝
███████║██║   ██║██╔████╔██║███████║██╔██╗ ██║██║   ██║██║██║  ██║███████╗
██╔══██║██║   ██║██║╚██╔╝██║██╔══██║██║╚██╗██║██║   ██║██║██║  ██║╚════██║
██║  ██║╚██████╔╝██║ ╚═╝ ██║██║  ██║██║ ╚████║╚██████╔╝██║██████╔╝███████║
╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═════╝ ╚══════╝


The Humanoids Staking Contract

*/

pragma solidity =0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStakingReward.sol";

contract TheHumanoidsStaking is Ownable {
    bool public canStake;
    address public stakingRewardContract;

    IERC721 private constant _NFT_CONTRACT = IERC721(0x3a5051566b2241285BE871f650C445A88A970edd);

    struct Token {
        address owner;
        uint64 timestamp;
        uint16 index;
    }
    mapping(uint256 => Token) private _tokens;
    mapping(address => uint16[]) private _stakedTokens;

    constructor() {}

    function setStaking(bool _canStake) external onlyOwner {
        canStake = _canStake;
    }

    function setStakingRewardContract(address newStakingRewardContract) external onlyOwner {
        address oldStakingRewardContract = stakingRewardContract;
        require(newStakingRewardContract != oldStakingRewardContract, "New staking reward contract is same as old contract");
        if (oldStakingRewardContract != address(0)) {
            IStakingReward(oldStakingRewardContract).willBeReplacedByContract(newStakingRewardContract);
        }
        stakingRewardContract = newStakingRewardContract;
        if (newStakingRewardContract != address(0)) {
            IStakingReward(newStakingRewardContract).didReplaceContract(oldStakingRewardContract);
        }
    }


    function stakedTokensBalanceOf(address account) external view returns (uint256) {
        return _stakedTokens[account].length;
    }

    function stakedTokensOf(address account) external view returns (uint16[] memory) {
        return _stakedTokens[account];
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = _tokens[tokenId].owner;
        require(owner != address(0), "Token not staked");
        return owner;
    }

    function timestampOf(uint256 tokenId) external view returns (uint256) {
        uint256 timestamp = uint256(_tokens[tokenId].timestamp);
        require(timestamp != 0, "Token not staked");
        return timestamp;
    }


    function stake(uint16[] calldata tokenIds) external {
        require(canStake, "Staking not enabled");
        uint length = tokenIds.length;
        require(length > 0, "tokenIds array is empty");

        if (stakingRewardContract != address(0)) {
            IStakingReward(stakingRewardContract).willStakeTokens(msg.sender, tokenIds);
        }

        uint64 timestamp = uint64(block.timestamp);
        uint16[] storage stakedTokens = _stakedTokens[msg.sender];
        uint16 index = uint16(stakedTokens.length);
        unchecked {
            for (uint i=0; i<length; i++) {
                uint16 tokenId = tokenIds[i];
                _NFT_CONTRACT.transferFrom(msg.sender, address(this), tokenId);

                Token storage token = _tokens[tokenId];
                token.owner = msg.sender;
                token.timestamp = timestamp;
                token.index = index;
                index++;

                stakedTokens.push(tokenId);
            }
        }
    }

    function unstake(uint16[] calldata tokenIds) external {
        uint length = tokenIds.length;
        require(length > 0, "tokenIds array is empty");

        if (stakingRewardContract != address(0)) {
            IStakingReward(stakingRewardContract).willUnstakeTokens(msg.sender, tokenIds);
        }

        unchecked {
            uint16[] storage stakedTokens = _stakedTokens[msg.sender];

            for (uint i=0; i<length; i++) {
                uint256 tokenId = tokenIds[i];
                require(_tokens[tokenId].owner == msg.sender, "Token not staked or not owned");

                uint index = _tokens[tokenId].index;
                uint lastIndex = stakedTokens.length-1;
                if (index != lastIndex) {
                    uint16 lastTokenId = stakedTokens[lastIndex];
                    stakedTokens[index] = lastTokenId;
                    _tokens[lastTokenId].index = uint16(index);
                }

                stakedTokens.pop();

                delete _tokens[tokenId];
                _NFT_CONTRACT.transferFrom(address(this), msg.sender, tokenId);
            }
        }
    }

    function unstakeAll() external {
        uint16[] storage stakedTokens = _stakedTokens[msg.sender];
        uint length = stakedTokens.length;
        require(length > 0, "Nothing staked");

        if (stakingRewardContract != address(0)) {
            IStakingReward(stakingRewardContract).willUnstakeTokens(msg.sender, stakedTokens);
        }

        unchecked {
            for (uint i=0; i<length; i++) {
                uint256 tokenId = stakedTokens[i];
                delete _tokens[tokenId];
                _NFT_CONTRACT.transferFrom(address(this), msg.sender, tokenId);
            }
        }

        delete _stakedTokens[msg.sender];
    }
}