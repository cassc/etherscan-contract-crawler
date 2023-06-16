// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owner.sol";
import "./token/ERC721Enumerable.sol";
import "./Interface/IFloppy.sol";
import "./Interface/IHumach.sol";
import "./Interface/IMachinieLevel.sol";
contract Machinie is ERC721Enumerable, Ownable
{
    mapping(uint256 => uint256) private level;
    mapping(uint256 => uint256) private stakeTime;
    mapping(uint256 => uint256) private humachId;
    mapping(uint256 => uint256) private stakeRate;
    mapping(uint256 => string) private idName;
    mapping(uint256 => string) private idDescription; 
    uint256 private changeNameFee = 35 ether;
    uint256 private changeDescFee = 35 ether;
    uint256 public constant maxSupply = 888;
    string private uri = "https://api.machinienft.com/api/machinie/";
    address private floppy = 0x9F3dDF3309D501FfBDC4587ab11e9D61ADD3126a; 
    address private humach;
    address private machinieLevel = 0xb96E968b177D0A31b7aaDf9B39093ea217EFEB23; 
    address public constant blackHole = 0x000000000000000000000000000000000000dEaD;
    uint16 private maximumNameLength = 20;
    uint16 private maximumDescLength = 300;
    bool private enableStake;
    constructor() ERC721("Machinie", "MACH")
    {
        stakeRate[1] = 8 * 11574 * (10**9);  
        stakeRate[2] = 9 * 11574 * (10**9);
        stakeRate[3] = 10 * 11574 * (10**9);
        stakeRate[4] = 11 * 11574 * (10**9);
        stakeRate[5] = 12 * 11574 * (10**9);
        _admin[0x714FdF665698837f2F31c57A3dB2Dd23a4Efe84c] = true;

    }

    function mintMachinie( address to_,uint256 tokenId_) external onlyWorker {
        require(tokenId_ < maxSupply, "Machinie : Over Supply");
        level[tokenId_] = IMachinieLevel(machinieLevel).getLevel(tokenId_);    
        _safeMint(to_ ,tokenId_);
    }


    function stakeMachinie(uint256[] memory machinieIds_,uint256[] memory hamachIds_) external {
        require(enableStake, "Machinie : Stake function is disable");
        for(uint8 _i=0; _i< machinieIds_.length; _i++){
            require(ownerOf(machinieIds_[_i]) == _msgSender() , "Machinie : owner query for nonexistent machinie token");
            require(IHumach(humach).ownerOf(hamachIds_[_i]) == _msgSender() , "Machinie : owner query for nonexistent humach token");
            require(!staking[machinieIds_[_i]]  , "Machinie : MachinieID is staking");
            require(!IHumach(humach).isStaking(hamachIds_[_i]) , "Machinie : HumachID is staking");
            staking[machinieIds_[_i]] = true;
            stakeTime[machinieIds_[_i]] = block.timestamp;
            humachId[machinieIds_[_i]] = hamachIds_[_i];
            IHumach(humach).updateStakStatus( hamachIds_[_i] , true);
        }
    }

    function unStakeMachinie(uint256[] memory machinieIds_) external returns(uint256) {
        uint256 _totalReward = 0;
        for(uint8 _i=0; _i< machinieIds_.length; _i++){
            require(ownerOf(machinieIds_[_i]) == _msgSender() , "Machinie : owner query for nonexistent machinie token");
            require(staking[machinieIds_[_i]] , "Machinie : MachinieID is not staking");
            uint256 _reward = getStakeReward(machinieIds_[_i]);
            _totalReward = _totalReward + _reward;
            IHumach(humach).updateStakStatus(humachId[machinieIds_[_i]], false);
            staking[machinieIds_[_i]] = false;
            stakeTime[machinieIds_[_i]] = 0;
            humachId[machinieIds_[_i]] = 0;
        }
        if(_totalReward > 0){
            IFloppy(floppy).mint(_msgSender(), _totalReward);
        }
        return(_totalReward);
    }

    function claimFloppy(uint256[] memory machinieIds_) external returns(uint256){
        uint256 _totalReward = 0;
        for(uint8 _i=0; _i< machinieIds_.length; _i++){
            require(ownerOf(machinieIds_[_i]) == _msgSender() , "Machinie : owner query for nonexistent machinie token");
            require(staking[machinieIds_[_i]] , "Machinie : MachinieID is not staking");
            uint256 _reward = getStakeReward(machinieIds_[_i]);
            _totalReward = _totalReward + _reward;
            stakeTime[machinieIds_[_i]] = block.timestamp;
        }
        if(_totalReward > 0){
            IFloppy(floppy).mint(_msgSender(), _totalReward);
        }
        return(_totalReward);
    }
    function getStakeReward(uint256 machinieId_) public view returns(uint256){
        if(!staking[machinieId_] )
            return 0;
        if(stakeTime[machinieId_] == 0)
            return 0;
        uint256 _rate = stakeRate[level[machinieId_]];
        uint256 _reward = (block.timestamp - stakeTime[machinieId_] ) * _rate;
        return _reward;
    }

    function updateTokenName (uint256 tokenId_ ,string memory name_ ) external  {
        require(ownerOf(tokenId_) == _msgSender() , "Machinie : owner query for nonexistent machinie token");
        require(IERC20(floppy).balanceOf(_msgSender()) >= changeNameFee, "Machinie : BalanceOf Floppy is not enought");
        require(IERC20(floppy).allowance(_msgSender(), address(this)) >= changeNameFee, "Machinie : allowance Floppy isnot enought");
        require(bytes(name_).length <= maximumNameLength, "Machinie : Name length is over Limit");

        IERC20(floppy).transferFrom(_msgSender(), blackHole, changeNameFee);
        idName[tokenId_] = name_;
        emit changeName(tokenId_ , name_, idDescription[tokenId_]);
    }

    function updateTokenDescription (uint256 tokenId_  ,string memory description_ ) external  {
        require(ownerOf(tokenId_) == _msgSender() , "Machinie : owner query for nonexistent machinie token");
        require(IERC20(floppy).balanceOf(_msgSender()) >= changeDescFee, "Machinie : BalanceOf Floppy is not enought");
        require(IERC20(floppy).allowance(_msgSender(), address(this)) >= changeDescFee, "Machinie : allowance Floppy isnot enought");
        require(bytes(description_).length <= maximumDescLength, "Machinie : Description length is over Limit");

        IERC20(floppy).transferFrom(_msgSender(), blackHole, changeDescFee);
        idDescription[tokenId_] = description_;
        emit changeName(tokenId_ , idName[tokenId_], description_);
    }

    function burnMachinie(uint256 tokenId_) external {
        require(ownerOf(tokenId_) == _msgSender() , "Machinie : owner query for nonexistent machinie token");
        _burn(tokenId_);
    }

    function updateEnableStake(bool status_) external onlyAdmin{
        enableStake = status_;
    }
    
    function updateLevel(uint256 [] memory tokenId_, uint8 level_) external onlyAdmin{
        for(uint _i =0; _i<tokenId_.length; _i++)
        {
            level[tokenId_[_i]] = level_;
        }
    }

    function updateStakStatus(uint256 tokenId_,bool status_) external onlyWorker {
        staking[tokenId_] = status_;
    }

    function updateStakeTime (uint256 tokenId_ ,uint256 stakeTime_) external onlyWorker {
        stakeTime[tokenId_] = stakeTime_;
    }

    function updateStakeRate(uint256 level_,uint256 rate_) external onlyAdmin  {
        stakeRate[level_] = rate_;  
    }

    function updateChangeNameFee(uint256 changeName_,uint256 changeDesc_) external onlyAdmin {
        changeNameFee = changeName_;
        changeDescFee = changeDesc_;
    }

    function updateNameLength (uint16 nameLength_, uint16 descLength_) external onlyAdmin {
        maximumNameLength = nameLength_;
        maximumDescLength = descLength_;
    }

    function updateContractFloppy (address newContract) external onlyOwner {
        floppy = newContract;
    }
    
    function updateContractHumach (address newAddress_)external onlyOwner  {
        humach = newAddress_;
    }

    function updateBaseURI(string memory baseURI_)external onlyAdmin{
        uri = baseURI_;
    }

    function withdraw() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdraw(uint256 amount_) external payable onlyOwner {
        require(payable(msg.sender).send(amount_));
    }


    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 _i; _i < tokenCount; _i++){
            tokensId[_i] = tokenOfOwnerByIndex(_owner, _i);
        }
        return tokensId;
    }

    function isLevel (uint256 tokenId_) external view returns(uint256){
        return level[tokenId_];
    }
    
    function isStaking (uint256 tokenId_) external view returns(bool){
        return staking[tokenId_];
    }
    
    function getStakeTime (uint256 tokenId_) external view returns (uint256){
        return stakeTime[tokenId_];
    }
    
    function getTokenIdName(uint256 tokenId_) external view returns(string memory, string memory){
        return(idName[tokenId_],idDescription[tokenId_]);
    }

    function  getChangeDataFee() external view returns (uint256,uint256){
        return (changeNameFee,changeDescFee);       
    }
    
    function getStakeRate(uint256 level_) external view returns(uint256){
        return stakeRate[level_];
    }

    function getHumachTokenId(uint256 machinieId_) external view returns(uint256){
        return humachId[machinieId_];
    }

    function getEnableStake() external view returns (bool){
        return enableStake;
    }

    function getNameLength () external view returns(uint16,uint16) {
        return (maximumNameLength,maximumDescLength);
    }

    function getContractFloppy() external view returns(address){
        return floppy;
    }

    function getContractHumach() external view returns(address){
        return humach;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }
    

    event changeName(uint256 tokenId_ , string  name_, string  description_);
    
    receive() external payable{
        
    }

}