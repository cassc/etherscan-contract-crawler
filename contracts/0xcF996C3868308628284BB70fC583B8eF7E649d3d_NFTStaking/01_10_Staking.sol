// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.16;


interface IERC20 {
    function mint(uint256 amount) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract NFTStaking is Ownable, IERC721Receiver,ReentrancyGuard {
    ERC721ABurnable public nft;
    IERC20 public token;

    uint256 public totalStaked;
    bool public isStakingAllowed = false;



    //Rewards Per Level 
    uint256 private levelZeroRewardsPerSecond  =  11574074074074;
    uint256 private levelOneRewardsPerSecond   =   38541666666666;
    uint256 private levelTwoRewardsPerSecond   =   77083333333333;
    uint256 private levelThreeRewardsPerSecond = 385416666666666;


    //Price For Upgrades
    uint256 private levelOneUpgradePrice =   33000000000000000000;
    uint256 private levelTwoUpgradePrice =   66000000000000000000;
    uint256 private levelThreeUpgradePrice = 333000000000000000000;
    uint256 public numberOfLevels = 3;

    

    struct vault {
        uint256 tokenId;
        address owner;
        uint256 stakedAt;
        uint256 levelDuringStake;
        bool isStaked;
    }


    mapping(uint256 => vault) public Vault;
    mapping(address => uint256 ) public _userStaked;
    mapping(uint256 => uint256) public NFTLevels;

    event NFTStaked(address owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);
    event NFTUpgraded(address owner,uint256 tokenId);


    constructor(ERC721ABurnable _nft, IERC20 _token) {
        nft = _nft;
        token = _token;
    }


    function _stake(uint256 _tokenId) internal {
        console.log("TokenID",_tokenId);
        console.log("Owner",nft.ownerOf(_tokenId));
        console.log("msg.sender",msg.sender);
        require(nft.ownerOf(_tokenId) == msg.sender,"Only Owner can Stake the NFT");
        require(!Vault[_tokenId].isStaked,"NFT is already Staked");
        nft.transferFrom(msg.sender, address(this), _tokenId);
        emit NFTStaked(msg.sender, _tokenId, block.timestamp);

        Vault[_tokenId] = vault({
            owner: msg.sender,
            tokenId: _tokenId,
            stakedAt:block.timestamp,
            levelDuringStake : NFTLevels[_tokenId],
            isStaked:true
        });
    }

    function _unstake(uint256 _tokenId) internal  {
        require(Vault[_tokenId].isStaked,"NFT is not  Staked");
        require(Vault[_tokenId].owner == msg.sender,"Only Owner can Unstake");
        nft.transferFrom(address(this), msg.sender, _tokenId);
        delete Vault[_tokenId];
        emit NFTUnstaked(msg.sender, _tokenId, block.timestamp);
    }

    function _claim(uint256 _tokenId,bool _alsoUnstake) internal {
        vault storage _vault = Vault[_tokenId];
        require(_vault.isStaked,"NFT is not  Staked");
        require(_vault.owner == msg.sender,"Only Owner can Unstake");
        uint256 rewards = getRewardsPerSecond(_vault.levelDuringStake) * (block.timestamp - _vault.stakedAt);
        token.transfer(_vault.owner, rewards);
        _vault.stakedAt = block.timestamp;
        if(_alsoUnstake){
            delete Vault[_tokenId];
            nft.transferFrom(address(this), _vault.owner, _tokenId);
        }
    }

    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        require(isStakingAllowed,"Staking is Paused");
        for(uint256 i=0;i<_tokenIds.length;i++){
            _stake(_tokenIds[i]);
        }
        _userStaked[msg.sender]+=_tokenIds.length;
        totalStaked+=_tokenIds.length;
    }

    function unStake(uint256[] calldata _tokenIds) external nonReentrant{
        for(uint256 i=0;i<_tokenIds.length;i++){
            _unstake(_tokenIds[i]);
        }
        _userStaked[msg.sender]-=_tokenIds.length;
        totalStaked-=_tokenIds.length;
    }

    function claim(uint256[] calldata _tokenIds,bool _alsoUnstake) external nonReentrant{
        for(uint256 i=0;i<_tokenIds.length;i++){
            _claim(_tokenIds[i],_alsoUnstake);
        }
    }
    

    function secondsPassedSinceStaked(uint256 tokenId) public view returns(uint256){
        vault memory _vault = Vault[tokenId];
        require(_vault.isStaked,"Token is not staked");
        uint256 stakedAt = _vault.stakedAt;
        return (block.timestamp - stakedAt) ;
    }

    function totalAccumulated(uint256[] calldata tokenIds) public view returns(uint256) {
        uint256 totalRewardAccumulated = 0;
        for(uint256 i=0;i<tokenIds.length;i++){
            vault memory _vault = Vault[tokenIds[i]];
            totalRewardAccumulated += getRewardsPerSecond(_vault.levelDuringStake) * (block.timestamp - _vault.stakedAt);
        }
        return totalRewardAccumulated;
    }


    function upgradeNFT(uint256 tokenID) external {
        vault memory _vault = Vault[tokenID];
        
        uint256 currentLevel = NFTLevels[tokenID];
        if(_vault.isStaked){
            require(_vault.owner == msg.sender, "You are not the owner,If it's staked, unstake and upgrade.");
            _claim(tokenID, true); // Claim and Unstake if the token is staked , so that they get updated rewards from going on
        }
        else{
            require(nft.ownerOf(tokenID) == msg.sender, "You are not the owner,If it's staked, unstake and upgrade.");
        }
        require(currentLevel < 3,"You Have Reached Maximum Level");   
        uint256 priceToLevelUp = getUpgradePrice(currentLevel);
            
        token.transferFrom(msg.sender, address(this), priceToLevelUp);
        NFTLevels[tokenID] = currentLevel +1;
        emit NFTUpgraded(msg.sender,tokenID);
    }
    

    function getUpgradePrice(uint256 currentLevel) internal view returns(uint256){
        if(currentLevel == 0){
            return levelOneUpgradePrice;
        }
        else if(currentLevel == 1){
            return levelTwoUpgradePrice;
        }
        return levelThreeUpgradePrice;
    }

    function getRewardsPerSecond(uint256 _currentLevel) internal view returns(uint256) {
        if(_currentLevel == 0){
            return levelZeroRewardsPerSecond;
        }
        else if(_currentLevel == 1){
            return levelOneRewardsPerSecond;
        }
        else if(_currentLevel == 2){
            return levelTwoRewardsPerSecond;
        }
        return levelThreeRewardsPerSecond;
    }


    function toogleStakingAllowed() public onlyOwner {
        isStakingAllowed =  !isStakingAllowed; 
    }

    function mintRewards(uint256 amount) public onlyOwner{
        token.mint(amount);
    }

    function rescueTokens(uint256[] calldata tokenIds) public onlyOwner{
        for(uint256 i=0;i<tokenIds.length;i++){
            vault memory _vault = Vault[tokenIds[i]];
            address owner = _vault.owner;
            nft.transferFrom(address(this), owner, tokenIds[i]);
            delete Vault[tokenIds[i]];
        }

    }


    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}