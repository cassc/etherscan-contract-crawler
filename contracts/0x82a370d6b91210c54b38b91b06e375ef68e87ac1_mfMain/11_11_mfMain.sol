// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../lib/erc721a/contracts/extensions/IERC721AQueryable.sol";
import "./interfaces/IMetaFlyers.sol";
import "./interfaces/IFewl.sol";


contract mfMain is Ownable, Pausable, ReentrancyGuard {

    // CONTRACTS 
    IFewl public fewlContract;
    IMetaFlyers public mfContract;

    constructor(address _mfContract, address _fewlContract){
        mfContract = IMetaFlyers(_mfContract);
        fewlContract = IFewl(_fewlContract);
        _pause();
    }    

    // EVENTS 
    event MetaFlyersMinted(address indexed owner, uint16[] tokenIds);
    event MetaFlyersLocked(address indexed owner, uint256[] tokenIds);
    event MetaFlyersClaimed(address indexed owner, uint256[] tokenIds);

    // ERRORS
    error InvalidAmount();
    error InvalidOwner();
    error MintingNotActive();
    error LockingInactive();
    error NotWhitelisted();
    error MaxAllowedPreSaleMints();    
    error MaxAllowedPublicSaleMints();

    // PUBLIC VARS 
    uint256 public MINT_PRICE = 0.047 ether;
    uint256 public DAILY_BASE_FEWL_RATE = 5 ether;
    uint256 public DAILY_TIER1_FEWL_RATE = 10 ether;
    uint256 public DAILY_TIER2_FEWL_RATE = 20 ether;
    uint256 public BONUS_FEWL_AMOUNT = 200 ether;

    // Time that must pass before a Locked Nft can receive bonus FEWL amount
    uint256 public MINIMUM_DAYS_TO_BONUS = 14 days;       

    bool public PRE_SALE_STARTED;
    bool public PUBLIC_SALE_STARTED;
    bool public LOCKING_STARTED;
    bool public TIER_EMISSIONS_STARTED;

    uint16 public MAX_PRE_SALE_MINTS = 5;   
    uint16 public MAX_PUBLIC_SALE_MINTS = 10;

    address public withdrawAddress;
    

    // PRIVATE VARS 
    mapping(address => bool) private _admins;
    mapping(address => uint8) private _publicSaleMints;
    mapping(uint256 => bool) private _tier1Tokens;
    mapping(uint256 => bool) private _tier2Tokens;
    mapping(address => bool) private _preSaleAddresses;
    mapping(address => uint8) private _preSaleMints;


    function mint(uint8 amount, bool lock) external payable whenNotPaused nonReentrant {
        if(!PRE_SALE_STARTED && !PUBLIC_SALE_STARTED) revert MintingNotActive();

        if (PRE_SALE_STARTED) {
            if(!_preSaleAddresses[_msgSender()]) revert NotWhitelisted();
            if(_preSaleMints[_msgSender()] + amount > MAX_PRE_SALE_MINTS) revert MaxAllowedPreSaleMints();
        } else {
            if(_publicSaleMints[_msgSender()] + amount > MAX_PUBLIC_SALE_MINTS) revert MaxAllowedPublicSaleMints();
        }
        //check for adequate value sent
        if (PRE_SALE_STARTED && _preSaleMints[_msgSender()] == 0){
            if(msg.value < (amount - 1) * MINT_PRICE) revert InvalidAmount();
        }
        else if(msg.value < amount * MINT_PRICE) revert InvalidAmount();
        

        if (PRE_SALE_STARTED) _preSaleMints[_msgSender()] += amount;
        else _publicSaleMints[_msgSender()] += amount;

        mfContract.mint(_msgSender(), amount);

        if(lock){
           uint256[] memory tokens = IERC721AQueryable(address(mfContract)).tokensOfOwner(_msgSender());
           for(uint16 i = 0; i < tokens.length; i++) {
            if(!mfContract.isLocked(tokens[i])){
                 mfContract.lock(tokens[i], _msgSender());
            }
           }
        }
    }

    function lockMetaFlyers(uint256[] memory tokenIds) external whenNotPaused nonReentrant {
        if(!LOCKING_STARTED) revert LockingInactive();

        for(uint16 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            if(IERC721AQueryable(address(mfContract)).ownerOf(tokenId) != _msgSender()) revert InvalidOwner();
            // lock MetaFlyer
            //reverts if nft is already locked
            mfContract.lock(tokenId, _msgSender());
        }

        emit MetaFlyersLocked(_msgSender(), tokenIds);
    }

    function claimMetaFlyers(uint256[] memory tokenIds, bool unlock) public whenNotPaused nonReentrant {
        uint256 stakingRewards;
        uint256 mintAmount;
        for(uint16 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if(IERC721AQueryable(address(mfContract)).ownerOf(tokenId) != _msgSender()) revert InvalidOwner();

            // pay out rewards
            stakingRewards = calculateLockingRewards(tokenId);
            mintAmount += stakingRewards;
            // unlock if the owner wishes to
            if (unlock) mfContract.unlock(tokenId, _msgSender());
            else mfContract.refreshLock(tokenId, stakingRewards);            
        }

        //mint claimed amount
        fewlContract.mint(_msgSender(), mintAmount);        

        emit MetaFlyersClaimed(_msgSender(), tokenIds);
    }

    function calculateAllLockingRewards(uint256[] memory tokenIds) public view returns(uint256 rewards) {
        for(uint16 i = 0; i < tokenIds.length; i++) {
            rewards += calculateLockingRewards(tokenIds[i]);
        }
    }

    function calculateLockingRewards(uint256 tokenId) public view returns(uint256 rewards) {
        //reverts if not locked
        IMetaFlyers.Locked memory myStake = mfContract.getLock(tokenId);
        uint256 lockDuration = block.timestamp - myStake.lockTimestamp;
        uint256 fewlRate = DAILY_BASE_FEWL_RATE;
        
        //calculate proper bonus rewards based on time locked
        rewards = lockDuration / MINIMUM_DAYS_TO_BONUS * BONUS_FEWL_AMOUNT;        

        //calculate tier emission rate
        if(TIER_EMISSIONS_STARTED){
            if(_tier1Tokens[tokenId]) fewlRate = DAILY_TIER1_FEWL_RATE;                
            if(_tier2Tokens[tokenId]) fewlRate = DAILY_TIER2_FEWL_RATE;                      
        } 

        //if tier emissions have not started all nfts get base rate
        rewards += lockDuration * fewlRate / 1 days;        

        if(rewards > myStake.claimedAmount){
            rewards -= myStake.claimedAmount;
        } else rewards = 0;               
        
    }

    function getPreSaleAddress(address user) external view returns (bool){
        return _preSaleAddresses[user];
    }

    function getPreSaleMints(address user) external view returns (uint256) {
        return _preSaleMints[user];
    }

    function getPublicSaleSaleMints(address user) external view returns (uint256) {
        return _publicSaleMints[user];
    }

    // OWNER ONLY FUNCTIONS 
    function setContracts(address _mfContract, address _fewlContract) external onlyOwner {
        mfContract = IMetaFlyers(_mfContract);
        fewlContract = IFewl(_fewlContract);
    }

    function mintForTeam(address receiver, uint16 amount) external whenNotPaused onlyOwner {        
        mfContract.mint(receiver, amount);        
    }

    function addToPresale(address[] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _preSaleAddresses[addresses[i]] = true;
        }
    }

    function withdraw() external {
        require(withdrawAddress != address(0x00), "Withdraw address not set");
        require(_msgSender() == withdrawAddress, "Withdraw address only");
        uint256 totalAmount = address(this).balance;
        bool sent;

        (sent, ) = withdrawAddress.call{value: totalAmount}("");
        require(sent, "Main: Failed to send funds");

    }

    function setWithdrawAddress(address addr) external onlyOwner {
        withdrawAddress = addr;
    }

    function setPreSaleStarted(bool started) external onlyOwner {
        PRE_SALE_STARTED = started;
        if (PRE_SALE_STARTED) PUBLIC_SALE_STARTED = false;
    }

    function setPublicSaleStarted(bool started) external onlyOwner {
        PUBLIC_SALE_STARTED = started;
        if (PUBLIC_SALE_STARTED) PRE_SALE_STARTED = false;
    }

    function setLockingStarted(bool started) external onlyOwner {
        LOCKING_STARTED = started;
    }

    function setTierEmissionStarted(bool started) external onlyOwner {
        TIER_EMISSIONS_STARTED = started;
    }

    function setMintPrice(uint256 number) external onlyOwner {
        MINT_PRICE = number;
    }

    function setMaxPublicSaleMints(uint16 number) external onlyOwner {
        MAX_PUBLIC_SALE_MINTS = number;
    }

    function setMaxPreSaleMints(uint16 number) external onlyOwner {
        MAX_PRE_SALE_MINTS = number;
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setDailyBaseFewlRate(uint256 number) external onlyOwner {
        DAILY_BASE_FEWL_RATE = number;
    }

    function setDailyTier1FewlRate(uint256 number) external onlyOwner {
        DAILY_TIER1_FEWL_RATE = number;
    }

    function setDailyTier2FewlRate(uint256 number) external onlyOwner {
        DAILY_TIER2_FEWL_RATE = number;
    }

    //Base = Tier 0, Agents= Tier 1, 1/1= Tier2
    function addTokensToTier(uint256[] memory tokenIds, uint8 tier) external onlyOwner {
        require(tier==1 || tier==2, "Tier must be 1 or 2");
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tier==1) _tier1Tokens[tokenIds[i]] = true;
                else _tier2Tokens[tokenIds[i]] = true;
        }
    }

    function setBonusFewlAmount(uint256 amount) external onlyOwner {
        BONUS_FEWL_AMOUNT = amount;
    }

    function setMinimumDaysToBonus(uint256 number) external onlyOwner {
        MINIMUM_DAYS_TO_BONUS = number;
    }

}