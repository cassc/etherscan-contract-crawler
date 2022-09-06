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


contract SushiClanStaking is Ownable, IERC721Receiver,ReentrancyGuard {
    ERC721ABurnable public nft;
    IERC20 public token;

    bool public isStakingAllowed = false;



    //Rewards Per Level 
    uint256  public levelZeroRewardsPerSecond  =   11574074074074;
    uint256  public levelOneRewardsPerSecond   =   38541666666666;
    uint256  public levelTwoRewardsPerSecond   =   77083333333333;
    uint256  public levelThreeRewardsPerSecond =   385416666666666;

    //Burning Incentive
    uint256  public _perBurnReward = 33 ether;


    //Price For Upgrades
    uint256  public levelOneUpgradePrice =   33 ether;
    uint256  public levelTwoUpgradePrice =   66 ether;
    uint256  public levelThreeUpgradePrice = 99 ether;
    uint256  public levelThreeAltUpgradePrice = 333 ether;
    uint256 public numberOfLevels = 3;

    

    struct vault {
        address owner;
        uint256 stakedAt;
        uint256 levelDuringStake;
        bool isStaked;
    }


    mapping(uint256 => vault) public Vault;
    mapping(uint256 => uint256) public NFTLevels;


    constructor(ERC721ABurnable _nft, IERC20 _token) {
        nft = _nft;
        token = _token;
    }


    function _stake(uint256 _tokenId) internal {
        require(nft.ownerOf(_tokenId) == msg.sender,"Only Owner can Stake the NFT");
        require(!Vault[_tokenId].isStaked,"NFT is already Staked");
        nft.transferFrom(msg.sender, address(this), _tokenId);
        Vault[_tokenId] = vault({
            owner: msg.sender,
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
        uint256 const = _tokenIds.length;
        
        if(const == 1){
            _stake(_tokenIds[0]);
        }
        else{
            for(uint256 i=0;i<const;i++){
                _stake(_tokenIds[i]);
            }

        }
    }

    function unStake(uint256[] calldata _tokenIds) external nonReentrant{
        for(uint256 i=0;i<_tokenIds.length;i++){
            _unstake(_tokenIds[i]);
        }
        
    }

    function claim(uint256[] calldata _tokenIds,bool _alsoUnstake) external nonReentrant{
        for(uint256 i=0;i<_tokenIds.length;i++){
            _claim(_tokenIds[i],_alsoUnstake);
        }
    }



    function upgradeNFT(uint256 tokenID) external nonReentrant {
        vault memory _vault = Vault[tokenID];
        
        uint256 currentLevel = NFTLevels[tokenID];
        if(_vault.isStaked){
            require(_vault.owner == msg.sender, "You are not the owner,If it's staked, unstake and upgrade.");
            _claim(tokenID, true); // Claim and Unstake if the token is staked , so that they get updated rewards from going on
        }
        else{
            require(nft.ownerOf(tokenID) == msg.sender, "You are not the owner,If it's staked, unstake and upgrade.");
        }
        require(currentLevel < 2,"Use Mythic function to upgrade to Level 3");   
        uint256 priceToLevelUp = getUpgradePrice(currentLevel);
            
        token.transferFrom(msg.sender, address(this), priceToLevelUp);
        NFTLevels[tokenID] = currentLevel +1;
       
    }


    function mythicUpgrade(uint256 tokenID, uint256[] calldata _burns) public nonReentrant {
        uint256 _burnCount = _burns.length;
        require(_burnCount == 2 || _burnCount == 5,"Invalid Burn Options");
        require(isOwnerofAllorSameToken(tokenID,_burns,msg.sender),"You are not the owner of all the tokens passed");
        for(uint256 i=0;i<_burnCount;i++){
            nft.burn(_burns[i]);
        }
        vault memory _vault = Vault[tokenID];
        uint256 currentLevel = NFTLevels[tokenID];
        if(_vault.isStaked){
            require(_vault.owner == msg.sender, "You are not the owner,If it's staked, unstake and upgrade.");
            _claim(tokenID, true); // Claim and Unstake if the token is staked , so that they get updated rewards from going on
        }
        else{
            require(nft.ownerOf(tokenID) == msg.sender, "You are not the owner,If it's staked, unstake and upgrade.");
        }
        require(currentLevel == 2,"You can only upgrade level two nft to Mythic");
        uint256 upgradePrice = levelThreeUpgradePrice;
        if(_burnCount == 2){
            upgradePrice = levelThreeAltUpgradePrice;
        }
        token.transferFrom(msg.sender, address(this), upgradePrice);
        NFTLevels[tokenID] = currentLevel +1;
    }

    function burnSushiForKril(uint256[] calldata _tokenIds) public nonReentrant{
        for(uint256 i=0;i<_tokenIds.length;i++){
            nft.burn(_tokenIds[i]);
            token.transfer(msg.sender, _perBurnReward);
        }        
    }
    

    function upgradeNFTAdmin(uint256 tokenId,uint256 toLevel) public onlyOwner{
        require(toLevel <= numberOfLevels,"You cannot upgrade to level more than 3");
        NFTLevels[tokenId] = toLevel;
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

    function isOwnerofAllorSameToken(uint256 tokenToUpgrade,uint256[] calldata _tokens,address owner) internal view  returns(bool){
        bool isOwner = true;
        for(uint256 i=0;i<_tokens.length;i++){
            if(nft.ownerOf(_tokens[i]) != owner || _tokens[i] == tokenToUpgrade){
                isOwner = false;
            }

        }
        return isOwner;

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

    function rescueKrill() public onlyOwner{
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function changeRewards(uint256 levelOne,uint256 levelTwo,uint256 levelThree) public onlyOwner{
        levelOneRewardsPerSecond = levelOne;
        levelTwoRewardsPerSecond = levelTwo;
        levelThreeRewardsPerSecond = levelThree;
    }



    function changeUpgradePrice(uint256 levelOne,uint256 levelTwo,uint256 levelThree,uint256 levelThreeAlt) public onlyOwner{
        levelOneUpgradePrice = levelOne;
        levelTwoUpgradePrice = levelTwo;
        levelThreeUpgradePrice = levelThree;
        levelThreeAltUpgradePrice = levelThreeAlt;
    }


    function setBurnIncentive(uint256 _newReward) public onlyOwner{
        _perBurnReward = _newReward;
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