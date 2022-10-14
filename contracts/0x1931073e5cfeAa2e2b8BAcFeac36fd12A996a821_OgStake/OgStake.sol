/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

contract OgStake is ERC721TokenReceiver {


    bool enabled;
    uint256 timeBetweenRewards;
    uint256 rewardPerToken;
    uint256 minimumStakeTime;
    uint256 startTime;
    Stake[] stakings;

    struct StakeInfo {
        bool enabled;
        uint256 timeBetweenRewards;
        uint256 rewardPerToken;
        uint256 minimumStakeTime;
    }

    struct Stake
    {
        address holder;
        uint256 tokenId;
        uint256 stakeTime;
        uint256 lastClaimTime;
        uint256 unstakeTime;
    }

    struct StakedNftInfo
    {
        uint256 tokenId;
        string uri;
        uint256 stakeTime;
        uint256 owed;
        uint256 lastClaimed;
        uint256 timeUntilNextReward;
    }

    address public owner;
    uint256 private nonce;
    mapping (address => uint256[]) private ownerStakings;
    mapping (uint256 => uint256) private indexMap;
    
    IERC721Metadata private _nftContract;
    IERC20 private _rewardToken;

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }

    modifier whenEnabled() {
        require(enabled || msg.sender == owner, "staking not enabled");
        _;
    }

    constructor() {
        owner = msg.sender;

        if (block.chainid == 1) {
            _nftContract = IERC721Metadata(0x5b9D7Ee3Ba252c41a07C2D6Ec799eFF8858bf117);
            _rewardToken = IERC20(0xBeC5938FD565CbEc72107eE39CdE1bc78049537d);
        } else if (block.chainid == 3 || block.chainid == 4  || block.chainid == 97 || block.chainid == 5) {
            _nftContract = IERC721Metadata(0xb48408795A879d7e64A356bB71a2a22adE7a75eF);
            _rewardToken = IERC20(0x2891372D5c2727aC939BF111C45333735d537f09);
        } else {
            revert("Unknown Chain ID");
        }

        enabled = true;
        timeBetweenRewards = 1 days;
        startTime = block.timestamp;
        rewardPerToken = 8 * 10 ** 18;
        minimumStakeTime = 7 days;

    }

    function info() external view returns (
        StakedNftInfo[] memory stakedNfts,
        address rewardToken,
        address nftContract,
        StakeInfo memory settings
    ) {
        uint256 totalStaked = ownerStakings[msg.sender].length;
        stakedNfts = new StakedNftInfo[](totalStaked);
        for (uint256 i = 0; i < totalStaked; i ++) {

            uint256 index = indexMap[ownerStakings[msg.sender][i]];
            Stake storage s = stakings[index];

            (uint256 owed,) = rewardsOwed(s);
            stakedNfts[i] = StakedNftInfo(
                s.tokenId,
                _nftContract.tokenURI(s.tokenId),
                s.stakeTime,
                owed,
                s.lastClaimTime,
                timeUntilReward(s)
             );
        }

        rewardToken = address(_rewardToken);
        nftContract = address(_nftContract);

        settings = StakeInfo(
            enabled, 
            timeBetweenRewards, 
            rewardPerToken, 
            minimumStakeTime
        );
    }

    function stake(uint256 tokenId) external whenEnabled() {
        require(_nftContract.getApproved(tokenId) == address(this), "Must approve this contract as an operator");
        _nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
        Stake memory s = Stake(msg.sender, tokenId, block.timestamp, block.timestamp, 0);
        indexMap[tokenId] = stakings.length;
        stakings.push(s);
        ownerStakings[msg.sender].push(tokenId);
    }

    function unstake(uint256 tokenId) external {

        uint256 index = indexMap[tokenId];
        Stake storage s = stakings[index];

        require(s.unstakeTime == 0, "This NFT has already been unstaked");
        require(s.holder == msg.sender || msg.sender == owner, "You do not own this token");

        if (enabled) {
            claimWalletRewards(s.holder);
        }

        _nftContract.safeTransferFrom(address(this), s.holder, tokenId);
        s.unstakeTime = block.timestamp;
        removeOwnerStaking(s.holder, tokenId);
    }
 
    function claimRewards() external whenEnabled() {
        claimWalletRewards(msg.sender);
    }


    // Admin Methods

    function removeEth() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
    
    function removeTokens(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner, balance);
    }

    function forceUnstake(uint256 tokenId) external onlyOwner {
        uint256 index = indexMap[tokenId];
        Stake storage s = stakings[index];
        _nftContract.safeTransferFrom(address(this), s.holder, tokenId);
    }

    function setOwner(address who) external onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }

    function setEnabled(bool on) external onlyOwner {
        enabled = on;
    }

    function configureStake(uint256 _timeBetweenRewards, uint256 _rewardPerToken, uint256 _minimumStakeTime) external onlyOwner {
        timeBetweenRewards = _timeBetweenRewards;
        rewardPerToken = _rewardPerToken;
        minimumStakeTime = _minimumStakeTime;
    }


    // Private Methods

    function removeOwnerStaking(address holder, uint256 tokenId) private {
        bool found;
        uint256 index = 0;
        for (index; index < ownerStakings[holder].length; index++) {
            if (ownerStakings[holder][index] == tokenId) {
                found = true;
                break;
            } 
        }

        if (found) {
            if (ownerStakings[holder].length > 1) {
                ownerStakings[holder][index] = ownerStakings[holder][ownerStakings[holder].length-1];
            }
            ownerStakings[holder].pop();
        }
    }

    function claimWalletRewards(address wallet) private {
        uint256 totalOwed;
        
        for (uint256 i = 0; i < ownerStakings[wallet].length; i ++) {
            
            uint256 index = indexMap[ownerStakings[wallet][i]];
            (uint256 owed, uint256 time) = rewardsOwed(stakings[index]);
            if (owed > 0) {
                totalOwed += owed;
                stakings[index].lastClaimTime = stakings[index].lastClaimTime + time;
            }
        }

        if (totalOwed > 0) {
            _rewardToken.transfer(wallet, totalOwed);
        }
    }

    function timeUntilReward(Stake storage stakedToken) private view returns (uint256) {

        if (block.timestamp - stakedToken.stakeTime < minimumStakeTime) {
            return minimumStakeTime - (block.timestamp - stakedToken.stakeTime);
        }

        uint256 lastClaimTime = stakedToken.stakeTime;
        if (startTime > lastClaimTime) {
            lastClaimTime = startTime;
        } else if (stakedToken.lastClaimTime > lastClaimTime) {
            lastClaimTime = stakedToken.lastClaimTime;
        }

        if (block.timestamp - lastClaimTime >= timeBetweenRewards) {
            return timeBetweenRewards - ((block.timestamp - lastClaimTime) % timeBetweenRewards);
        }

        return timeBetweenRewards - (block.timestamp - lastClaimTime);
    }

    function rewardsOwed(Stake storage stakedToken) private view returns (uint256, uint256) {

        uint256 unstakeTime = block.timestamp;
        if (stakedToken.unstakeTime > 0) {
            unstakeTime = stakedToken.unstakeTime;
        }

        if (unstakeTime - stakedToken.stakeTime >= minimumStakeTime) {
            uint256 lastClaimTime = stakedToken.stakeTime;
            if (startTime > lastClaimTime) {
                lastClaimTime = startTime;
            } else if (stakedToken.lastClaimTime > lastClaimTime) {
                lastClaimTime = stakedToken.lastClaimTime;
            }

            if (unstakeTime - lastClaimTime >= timeBetweenRewards) {
                uint256 multiplesOwed = (unstakeTime - lastClaimTime) / timeBetweenRewards;
                return (
                    multiplesOwed * rewardPerToken,
                    multiplesOwed * timeBetweenRewards
                );
            }
        }

        return (0, 0);
    }

    function onERC721Received(address, address, uint256, bytes memory) public pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

}