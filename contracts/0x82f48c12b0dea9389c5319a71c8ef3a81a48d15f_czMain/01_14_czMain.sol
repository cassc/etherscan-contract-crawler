// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/iczNft.sol";
import "./interfaces/iczRoar.sol";
import "./interfaces/iczSpecialEditionTraits.sol";

contract czMain is Ownable, Pausable, ReentrancyGuard {

    constructor() {
        _pause();

        // define trait categories
        traitCategory[2] = 2;  // Headwear
        traitCategory[3] = 2;  // Headwear
        traitCategory[4] = 2;  // Headwear
        traitCategory[6] = 2;  // Headwear
        traitCategory[9] = 2;  // Headwear
        traitCategory[11] = 2; // Headwear
        traitCategory[12] = 2; // Headwear

        traitCategory[1] = 1;  // Mouth
        traitCategory[5] = 1;  // Mouth
        traitCategory[8] = 1;  // Mouth

        traitCategory[7] = 3;  // Neckwear
        traitCategory[10] = 3; // Neckwear
    }

    /** CONTRACTS */
    iczNft public nftContract;
    iczRoar public roarContract;
    iczSpecialEditionTraits public setContract;

    /** EVENTS */
    event ManyGenesisMinted(address indexed owner, uint16[] tokenIds);
    event ManyGenesisStaked(address indexed owner, uint16[] tokenIds);
    event ManyGenesisClaimed(address indexed owner, uint16[] tokenIds);
    event ManySpecialTraitsMinted(address indexed owner, uint16 traitId, uint16 amount);
    event GenesisFusedWithTrait(address indexed owner, uint256 tokenId, uint16 traitId);

    /** PUBLIC VARS */
    bool public TRAIT_SALE_STARTED;
    // traitId => traitCategory
    mapping(uint16 => uint16) public traitCategory;

    uint256 public MINT_PRICE_GENESIS = 0.09 ether;

    bool public PRE_SALE_STARTED;

    bool public PUBLIC_SALE_STARTED;
    uint16 public MAX_PUBLIC_SALE_MINTS = 3;

    bool public STAKING_STARTED;
    uint256 public DAILY_ROAR_RATE = 5 ether;
    uint256 public DAILY_TRAIT_ROAR_RATE = 5 ether;
    uint256 public MINIMUM_DAYS_TO_EXIT = 1 days;

    address public wallet1Address;
    address public wallet2Address;

    /** PRIVATE VARS */
    mapping(address => bool) private _admins;
    mapping(address => uint8) private _preSaleAddresses;
    mapping(address => uint8) private _preSaleMints;
    mapping(address => uint8) private _publicSaleMints;
    mapping(address => uint8) private _specialTraitMints;
    
    /** MODIFIERS */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "Main: Only admins can call this");
        _;
    }

    modifier onlyEOA() {
        require(tx.origin == _msgSender(), "Main: Only EOA");
        _;
    }

    modifier requireVariablesSet() {
        require(address(nftContract) != address(0), "Main: Nft contract not set");
        require(address(roarContract) != address(0), "Main: Roar contract not set");
        require(address(setContract) != address(0), "Main: Special Edition Traits contract not set");
        require(wallet1Address != address(0), "Main: Withdrawal address wallet1Address must be set");
        require(wallet2Address != address(0), "Main: Withdrawal address wallet2Address must be set");
        _;
    }

    /** PUBLIC FUNCTIONS */
    function mintSpecialEditionTrait(uint16 traitId, uint16 amount) external payable whenNotPaused nonReentrant onlyEOA {
        require(TRAIT_SALE_STARTED, "Main: Trait sale has not started");
        iczSpecialEditionTraits.Trait memory _trait = setContract.getTrait(traitId);
        require(_trait.traitId == traitId, "Main: Trait does not exist");
        require(msg.value >= amount * _trait.price, "Main: Invalid payment amount");
        require(_specialTraitMints[_msgSender()] + amount <= 3, "Main: You cannot mint more Traits");

        for (uint i = 0; i < amount; i++) {
            _specialTraitMints[_msgSender()]++;
            setContract.mint(traitId, _msgSender());
        }

        emit ManySpecialTraitsMinted(_msgSender(), traitId, amount);
    }

    function fuseTraitWithZilla(uint16 nftTokenId, uint16 setTokenId) external whenNotPaused onlyEOA { // nonReentrant removed due to call to claimManyGenesis()
        require(nftContract.ownerOf(nftTokenId) == _msgSender(), "Main: You are not the owner of this zilla");
        require(setContract.ownerOf(setTokenId) == _msgSender(), "Main: You are not the owner of this trait");

        iczSpecialEditionTraits.Token memory setToken = setContract.getToken(setTokenId);
        uint16 traitId = setToken.traitId;
        uint16 traitCategoryNew = traitCategory[traitId];

        uint16[] memory fusedTraits = nftContract.getSpecialTraits(nftTokenId);
        for (uint i = 0; i < fusedTraits.length; i++) {
            if (fusedTraits[i] == traitId) require(false, "Main: Cannot fuse the same trait twice");
            
            uint16 traitCategoryExisting = traitCategory[fusedTraits[i]];
            if (traitCategoryNew == traitCategoryExisting) require(false, "Main: Cannot fuse the same trait category twice");
        }

        // burn the trait nft
        setContract.burn(setTokenId);

        // claim ROAR to not inflate the earnings by fusing a trait - call this BEFORE fusing the trait with the NFT
        if (nftContract.isStaked(nftTokenId)) {
            uint16[] memory tokenIds = new uint16[](1);
            tokenIds[0] = uint16(nftTokenId);
            claimManyGenesis(tokenIds, false);
        }

        // add trait to zilla permanently
        nftContract.addToSpecialTraits(nftTokenId, traitId);

        emit GenesisFusedWithTrait(_msgSender(), nftTokenId, traitId);
    }

    function mint(uint256 amount) external payable whenNotPaused nonReentrant onlyEOA {
        require(PRE_SALE_STARTED || PUBLIC_SALE_STARTED, "Main: Genesis sale has not started yet");
        if (PRE_SALE_STARTED) {
            require(_preSaleAddresses[_msgSender()] > 0, "Main: You are not on the whitelist");
            require(_preSaleMints[_msgSender()] + amount <= _preSaleAddresses[_msgSender()], "Main: You cannot mint more Genesis during pre-sale");
        } else {
            require(_publicSaleMints[_msgSender()] + amount <= MAX_PUBLIC_SALE_MINTS, "Main: You cannot mint more Genesis");
        }
        require(msg.value >= amount * MINT_PRICE_GENESIS, "Main: Invalid payment amount");

        uint16[] memory tokenIds = new uint16[](amount);

        for (uint i = 0; i < amount; i++) {
            if (PRE_SALE_STARTED) {
                _preSaleMints[_msgSender()]++;
            } else {
                _publicSaleMints[_msgSender()]++;
            }

            nftContract.mint(_msgSender());
            tokenIds[i] = nftContract.totalMinted();
        }

        emit ManyGenesisMinted(_msgSender(), tokenIds);
    }

    function stakeManyGenesis(uint16[] memory tokenIds) external whenNotPaused nonReentrant onlyEOA {
        require(STAKING_STARTED, "Main: Staking did not yet start");

        for(uint16 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nftContract.ownerOf(tokenId) == _msgSender(), "Main: You are not the owner of this zilla");
            require(!nftContract.isStaked(tokenId), "Main: One token is already staked");

            // now inform the staking contract that the staking period has started (lockType = 1)
            nftContract.lock(tokenId, 1);
        }

        emit ManyGenesisStaked(_msgSender(), tokenIds);
    }

    function claimManyGenesis(uint16[] memory tokenIds, bool unstake) public whenNotPaused nonReentrant onlyEOA {
        for(uint16 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nftContract.ownerOf(tokenId) == _msgSender(), "Main: You are not the owner of this zilla");
            require(nftContract.isStaked(tokenId), "Main: Token is not staked");

            iczNft.Locked memory myStake = nftContract.getLock(tokenId);
            require(myStake.lockType == 1, "Main: One or more tokens are not staked but bridged");

            // pay out rewards
            uint256 stakingRewards = calculateGenesisStakingRewards(tokenId);
            roarContract.mint(_msgSender(), stakingRewards);

            // unstake if the owner wishes to
            if (unstake) {    
                require((block.timestamp - myStake.lockTimestamp) >= MINIMUM_DAYS_TO_EXIT, "Main: Must remain staked for at least 24h after staking/claiming");

                // now inform the staking contract that the staking period has started
                nftContract.unlock(tokenId);
            } else {
                // refresh stake (reentrancy already checked above)
                nftContract.refreshLock(tokenId);
            }
            
        }

        emit ManyGenesisClaimed(_msgSender(), tokenIds);
    }

    function calculateAllGenesisStakingRewards(uint256[] memory tokenIds) public view returns(uint256 rewards) {
        for(uint16 i = 0; i < tokenIds.length; i++) {
            rewards += calculateGenesisStakingRewards(tokenIds[i]);
        }
    }

    function calculateGenesisStakingRewards(uint256 tokenId) public view returns(uint256 rewards) {
        require(nftContract.isStaked(tokenId), "Main: Token is not staked");
        
        iczNft.Locked memory myStake = nftContract.getLock(tokenId);
        rewards += (block.timestamp - myStake.lockTimestamp) * DAILY_ROAR_RATE / 1 days;

        // extra rewards for golden traits fused with zilla
        uint16[] memory specialTraits = nftContract.getSpecialTraits(tokenId);
        rewards += (block.timestamp - myStake.lockTimestamp) * specialTraits.length * DAILY_TRAIT_ROAR_RATE / 1 days;

        return rewards;
    }

    /** OWNER ONLY FUNCTIONS */
    function setContracts(address _nftContract, address _roarContract, address _setContract) external onlyOwner {
        nftContract = iczNft(_nftContract);
        roarContract = iczRoar(_roarContract);
        setContract = iczSpecialEditionTraits(_setContract);
    }

    function setPaused(bool _paused) external requireVariablesSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function mintForTeam(address receiver, uint256 amount) external whenNotPaused onlyOwner {
        for (uint i = 0; i < amount; i++) {
            nftContract.mint(receiver);
        }
    }

    function withdraw() external onlyOwner {
        uint256 totalAmount = address(this).balance;
        
        uint256 amountWallet1 = totalAmount * 47/100;
        uint256 amountWallet2 = totalAmount - amountWallet1;

        bool sent;
        (sent, ) = wallet1Address.call{value: amountWallet1}("");
        require(sent, "Main: Failed to send funds to wallet1Address");

        (sent, ) = wallet2Address.call{value: amountWallet2}("");
        require(sent, "Main: Failed to send funds to wallet2Address");
    }
    
    function addToPresale(address[] memory addresses, uint8 allowedToMint) external onlyOwner {
         for (uint i = 0; i < addresses.length; i++) {
            _preSaleAddresses[addresses[i]] = allowedToMint;
         }
    }

    function setWallet1Address(address addr) external onlyOwner {
        wallet1Address = addr;
    }

    function setWallet2Address(address addr) external onlyOwner {
        wallet2Address = addr;
    }

    function addAdmin(address addr) external onlyOwner {
        _admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        delete _admins[addr];
    }

    function setMintPriceGenesis(uint256 number) external onlyOwner {
        MINT_PRICE_GENESIS = number;
    }

    function setTraitSaleStarted(bool started) external onlyOwner {
        TRAIT_SALE_STARTED = started;
    }

    function setPreSaleStarted(bool started) external onlyOwner {
        PRE_SALE_STARTED = started;
        if (PRE_SALE_STARTED) PUBLIC_SALE_STARTED = false;
    }

    function setPublicSaleStarted(bool started) external onlyOwner {
        PUBLIC_SALE_STARTED = started;
        if (PUBLIC_SALE_STARTED) PRE_SALE_STARTED = false;
    }

    function setStakingStarted(bool started) external onlyOwner {
        STAKING_STARTED = started;
    }

    function setMaxPublicSaleMints(uint16 number) external onlyOwner {
        MAX_PUBLIC_SALE_MINTS = number;
    }
    
    function setDailyRoarRate(uint256 number) external onlyOwner {
        DAILY_ROAR_RATE = number;
    }

    function setDailyTraitRoarRate(uint256 number) external onlyOwner {
        DAILY_TRAIT_ROAR_RATE = number;
    }

    function setMinimumDaysToExit(uint256 number) external onlyOwner {
        MINIMUM_DAYS_TO_EXIT = number;
    }
}