// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


pragma solidity ^0.8.7;

interface WPInterFace {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom( 
        address from,
        address to,
        uint256 tokenId
    ) external;
    function totalMinted() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract WanderingPlanetStake is Ownable, ReentrancyGuard {    
    event Staked(address indexed owner, uint256 tokenID);
    event Reclaimed(address indexed owner, uint256 tokenID);
    event StakeInterrupted(uint256 indexed tokenId);
    event Withdraw(address indexed account, uint256 amount);
    event stakeTimeConfigChanged(Period config_);
    
    // Interface for Wandering Planet Contract
    WPInterFace WP_Contract;  

    struct Stake_Info{
        bool staked;
        address previous_owner;
        uint256 stake_time;
    }

    struct Period {
        uint256 startTime;
        uint256 endTime;
    }


    // Stake Data Sturcture
    mapping(uint256 => Stake_Info) public planetStakeInfo;
    // Mapping from owner to the list of staked token IDs(only for querying)
    mapping(address => uint256[]) private addressStakeList;
    // Mapping from token ID to index of the owner tokens list(support to operate the addressStakeList)
    mapping(uint256 => uint256) private addressStakeIndex;
    // List for all the tokens staked
    uint256 [] private allStakeList;
    // support to operate the allStake list
    mapping(uint256 => uint256) private allStakeIndex;

    Period public stakeTime;
    address public wandering_planet_address;
    uint256 public rewardPeriod = 1000;


    constructor(address wandering_planet_address_, Period memory stake_time_) {
        require(wandering_planet_address_ != address(0), "invalid contract address");
        wandering_planet_address = wandering_planet_address_;
        stakeTime = stake_time_;
        WP_Contract = WPInterFace(wandering_planet_address);
    }
        
    /***********************************|
    |                Core               |
    |__________________________________*/
    
    /**
    * @dev Pubilc function for owners to reclaim their plantes
    * @param tokenID uint256 ID list of the token to be reclaim
    */
    function reclaimPlanets(uint256 [] memory tokenID) external callerIsUser nonReentrant{
        for(uint256 i = 0; i < tokenID.length; i++){
            _reclaim(tokenID[i]);
        }
    }

    /**
    * @dev Private function to stake one planet and update the state variabies
    * The function will be called when users transfer their tokens via 'safeTransferFrom'
    * @param tokenID uint256 ID of the token to be staked
    */
    function _stake(address owner, uint256 tokenID) internal{
        require(isStakeEnabled(), "stake not enabled");
        Stake_Info storage status = planetStakeInfo[tokenID];
        require(status.staked == false, "token is staking");
        status.staked = true;
        status.previous_owner = owner;
        status.stake_time = block.number;
        addEnumeration(owner, tokenID);
        addAllEnmeration(tokenID);
        emit Staked(owner, tokenID);
    }

    /**
    * @dev Private function to reclaim one planet and update the state variabies
    * @param tokenID uint256 ID of the token to be reclaimed
    */
    function _reclaim(uint256 tokenID) internal{
        require(isStakeEnabled(), "stake not enabled");
        Stake_Info storage status = planetStakeInfo[tokenID];
        require(status.staked == true, "the planet is freedom");
        require(status.previous_owner == msg.sender, "you are not the owner");
        WP_Contract.safeTransferFrom(address(this), msg.sender, tokenID);
        status.staked = false;
        status.previous_owner = address(0);
        status.stake_time = 0;
        removeEnumeration(msg.sender, tokenID);
        removeAllEnmeration(tokenID);
        emit Reclaimed(msg.sender, tokenID);
    }

   /**
    * @dev Public function to batach stake this planets
    * Approval for all the WP balances is needed
    * @param tokenIDs list of the tokens to be reclaimed
    */
    function batchStake(uint256 [] memory tokenIDs) external callerIsUser nonReentrant(){
        require(WP_Contract.isApprovedForAll(msg.sender, address(this)), "no authority");
        if (tokenIDs.length == 0){
            tokenIDs = getOwnedPlanets(msg.sender);
        }
        for(uint256 i = 0; i < tokenIDs.length; i++){
            require(WP_Contract.ownerOf(tokenIDs[i]) == msg.sender, "not the owner");
            WP_Contract.safeTransferFrom(msg.sender, address(this), tokenIDs[i]);
        }
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param address_ representing the owner of the given token ID
     * @param tokenID uint256 ID of the token to be added to the tokens list
     */
    function addEnumeration(address address_, uint256 tokenID) internal {
        addressStakeIndex[tokenID] = addressStakeList[address_].length;
        addressStakeList[address_].push(tokenID);
    }

    /**
    * @dev Private function to remove a token from this extension's ownership-tracking data structures.
    * @param address_ representing the previous owner of the given token ID
    * @param tokenID uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeEnumeration(address address_, uint256 tokenID) internal {

        require(addressStakeList[address_].length > 0, "No token staked by this address");
        uint256 lastTokenIndex = addressStakeList[address_].length - 1;
        uint256 tokenIndex = addressStakeIndex[tokenID];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = addressStakeList[address_][lastTokenIndex];

            addressStakeList[address_][tokenIndex] = lastTokenId;
            addressStakeIndex[lastTokenId] = tokenIndex; 
        }
        addressStakeList[address_].pop();
    }

    /*
    * @dev Private function to add a token to this extension's token tracking data structures.
    * @param tokenID uint256 ID of the token to be added to the tokens list
    */
    function addAllEnmeration(uint256 tokenID) internal {
        allStakeIndex[tokenID] = allStakeList.length;
        allStakeList.push(tokenID);
    }

    /**
    * @dev Private function to remove a token from this extension's ownership-tracking data structures.
    * @param tokenID uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeAllEnmeration(uint256 tokenID) internal {
        require(allStakeList.length > 0, "No token staked");
        uint256 lastTokenIndex = allStakeList.length - 1;
        uint256 tokenIndex = allStakeIndex[tokenID];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = allStakeList[lastTokenIndex];

            allStakeList[tokenIndex] = lastTokenId;
            allStakeIndex[lastTokenId] = tokenIndex; 
        }
        allStakeList.pop();
    }


    /***********************************|
    |               State               |
    |__________________________________*/

    function isStakeEnabled() public view returns (bool){
        if (stakeTime.endTime > 0 && block.timestamp > stakeTime.endTime) {
            return false;
        }
        return stakeTime.startTime > 0 && 
            block.timestamp > stakeTime.startTime;
    }
    
    function getOwnedPlanets(address address_) public view returns (uint256 [] memory){
        uint256 max_tokenID = WP_Contract.totalMinted();
        uint256 balance = WP_Contract.balanceOf(address_);
        uint256 cnt = 0;
        uint256 [] memory ownedtokens = new uint256 [](balance);
        for(uint256 i = 0; i < max_tokenID; i++){
            if(WP_Contract.ownerOf(i) == address_){
                ownedtokens[cnt++] = i;
            }
        }
        return ownedtokens;
    }

    /**
    * @dev Public function to get the staked tokens of the given address
    * @param address_ representing owner address
    */
    function getStakeList(address address_) public view returns (uint256 [] memory){
        return addressStakeList[address_];
    }

    /**
    * @dev Public function to get all the stake list
    */
    function getAllStakeList() public view returns (uint256 [] memory){
        return allStakeList;
    }

    /**
    * @dev Public function to get all the staked tokens which satisify the condition of stake time
    */
    function getValidStakes() public view returns (uint256 [] memory, bool [] memory){
        uint256 stake_count = allStakeList.length;
        bool [] memory isvalidstake = new bool [](stake_count);
        for(uint256 i = 0; i < stake_count; i++){
            uint256 tokenID = allStakeList[i];
            Stake_Info memory status = planetStakeInfo[tokenID];
            if(status.staked && block.number - status.stake_time >= rewardPeriod){
                isvalidstake[i] = true;
            }
            else{
                isvalidstake[i] = false;
            }
        }
        return (allStakeList, isvalidstake);
    }

    function getStakeInfo(uint256 tokenID) public view returns (Stake_Info memory){
        return planetStakeInfo[tokenID];
    }



    /***********************************|
    |               Owner               |
    |__________________________________*/
    /**
    * @dev Owner function to write adward list
    */
    function setRewardPeriod(uint256 rewardPeriod_) external onlyOwner{
        require(rewardPeriod_ > 0, "invalid parameter");
        rewardPeriod = rewardPeriod_;
    }

    function setStakeTime(Period calldata config_) external onlyOwner {
        stakeTime = config_;
        emit stakeTimeConfigChanged(config_);
    }

    /**
     * This method is used to prevent some users from mistakenly using transferFrom (instead of safeTransferFrom) to transfer NFT into the contract.
     * @param tokenIds_ the tokenId list
     * @param accounts_ the address list
     */
    function transferUnstakingTokens(uint256[] calldata tokenIds_, address[] calldata accounts_) external onlyOwner {
        require(tokenIds_.length == accounts_.length, "tokenIds_ and accounts_ length mismatch");
        require(tokenIds_.length > 0, "no tokenId");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            address account = accounts_[i];
            require(planetStakeInfo[tokenId].stake_time == 0, "token is staking");
            WP_Contract.safeTransferFrom(address(this), account, tokenId);
        }
    }

    function stopStake(uint256[] calldata tokenIds_) external onlyOwner {
        for (uint256 i; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            _reclaim(tokenId);
            emit StakeInterrupted(tokenId);
        }
    }


    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }

    /***********************************|
    |              Modifier             |
    |__________________________________*/
    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }

    /***********************************|
    |                Hook               |
    |__________________________________*/
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes memory
    ) public returns (bytes4) {
        require(msg.sender == wandering_planet_address, "only for WP");
        _stake(_from, _tokenId);
        return this.onERC721Received.selector;
    }
}