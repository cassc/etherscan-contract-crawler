// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./Awoo.sol";

interface IWulfz {
    function getWulfzType(uint256 _tokenId) external view returns (uint256);
}

contract StakingPool is IERC721Receiver, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    event StakeStarted(address indexed user, uint256 indexed tokenId);
    event StakeStopped(address indexed user, uint256 indexed tokenId);
    event UtilityAddrSet(address from, address addr);

    uint256[] private STAKE_REWARD_BY_TYPE = [10, 5, 50];

    IWulfz private _wulfzContract;
    UtilityToken private _utilityToken;

    struct StakedInfo {
        uint256 wType;
        uint256 lastUpdate;
    }

    mapping(uint256 => StakedInfo) private tokenInfo;
    mapping(address => EnumerableSet.UintSet) private stakedWulfz;

    modifier masterContract() {
        require(
            msg.sender == address(_wulfzContract),
            "Master Contract can only call Staking Contract"
        );
        _;
    }

    constructor(address _wulfzAddr) {
        _wulfzContract = IWulfz(_wulfzAddr);
    }

    function setUtilitytoken(address _addr) external onlyOwner {
        _utilityToken = UtilityToken(_addr);
        emit UtilityAddrSet(address(this), _addr);
    }

    function startStaking(address _user, uint256 _tokenId)
        external
        masterContract
    {
        require(!stakedWulfz[_user].contains(_tokenId), "Already staked");
        tokenInfo[_tokenId].wType = _wulfzContract.getWulfzType(_tokenId);
        tokenInfo[_tokenId].lastUpdate = block.timestamp;
        stakedWulfz[_user].add(_tokenId);

        emit StakeStarted(_user, _tokenId);
    }

    function stopStaking(address _user, uint256 _tokenId)
        external
        masterContract
    {
        require(stakedWulfz[_user].contains(_tokenId), "You're not the owner");

        uint256 wType = tokenInfo[_tokenId].wType;
        uint256 rewardBase = STAKE_REWARD_BY_TYPE[wType];
        uint256 interval = block.timestamp - tokenInfo[_tokenId].lastUpdate;
        uint256 reward = ((rewardBase * interval) *
            10**_utilityToken.decimals()) / 86400;

        _utilityToken.reward(_user, reward);
        delete tokenInfo[_tokenId];
        stakedWulfz[_user].remove(_tokenId);

        emit StakeStopped(_user, _tokenId);
    }

    function stakedTokensOf(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokens = new uint256[](stakedWulfz[_user].length());
        for (uint256 i = 0; i < stakedWulfz[_user].length(); i++) {
            tokens[i] = stakedWulfz[_user].at(i);
        }
        return tokens;
    }

    function getClaimableToken(address _user) public view returns (uint256) {
        uint256[] memory tokens = stakedTokensOf(_user);
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 wType = tokenInfo[tokens[i]].wType;
            uint256 rewardBase = STAKE_REWARD_BY_TYPE[wType];
            uint256 interval = block.timestamp -
                tokenInfo[tokens[i]].lastUpdate;
            uint256 reward = ((rewardBase * interval) *
                10**_utilityToken.decimals()) / 86400;

            totalAmount += reward;
        }

        return totalAmount;
    }

    function getReward() external {
        _utilityToken.reward(msg.sender, getClaimableToken(msg.sender));
        for (uint256 i = 0; i < stakedWulfz[msg.sender].length(); i++) {
            uint256 tokenId = stakedWulfz[msg.sender].at(i);
            tokenInfo[tokenId].lastUpdate = block.timestamp;
        }
    }

    /**
     * ERC721Receiver hook for single transfer.
     * @dev Reverts if the caller is not the whitelisted NFT contract.
     */
    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /* tokenId */
        bytes calldata /*data*/
    ) external view override returns (bytes4) {
        require(
            address(_wulfzContract) == msg.sender,
            "You can stake only Wulfz"
        );
        return this.onERC721Received.selector;
    }
}