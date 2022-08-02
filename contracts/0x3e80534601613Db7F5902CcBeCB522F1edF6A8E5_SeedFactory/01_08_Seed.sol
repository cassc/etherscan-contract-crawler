/*

██████╗░██████╗░██╗███╗░░░███╗███████╗██████╗░░█████╗░░█████╗░
██╔══██╗██╔══██╗██║████╗░████║██╔════╝██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██║██╔████╔██║█████╗░░██║░░██║███████║██║░░██║
██╔═══╝░██╔══██╗██║██║╚██╔╝██║██╔══╝░░██║░░██║██╔══██║██║░░██║
██║░░░░░██║░░██║██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░

*/

// SPDX-License-Identifier: GPL-3.0
// PrimeDAO Seed contract. Smart contract for seed phases of liquid launch.
// Copyright (C) 2021 PrimeDao

// solium-disable operator-whitespace
/* solhint-disable space-after-comma */
/* solhint-disable max-states-count */
// solium-disable linebreak-style
pragma solidity 0.8.9;

import "openzeppelin-contracts-sol8/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-sol8/token/ERC20/utils/SafeERC20.sol";
/**
 * @title PrimeDAO Seed contract
 * @dev   Smart contract for seed phases of liquid launch.
 */
contract Seed {
    using SafeERC20 for IERC20;
    // Locked parameters
    address public beneficiary;
    address public admin;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public seedAmountRequired; // Amount of seed required for distribution
    uint256 public feeAmountRequired; // Amount of seed required for fee
    uint256 public startTime;
    uint256 public endTime; // set by project admin, this is the last resort endTime to be applied when
    //     maximumReached has not been reached by then
    bool public permissionedSeed;
    uint32 public vestingCliff;
    IERC20 public seedToken;
    IERC20 public fundingToken;
    bytes public metadata; // IPFS Hash

    uint256 internal constant MAX_FEE = 45 / 100 * 10**18; // Max fee expressed as a % (e.g. 45 / 100 * 10**18 = 45% fee)
    uint256 internal constant PRECISION = 10**18; // used for precision e.g. 1 ETH = 10**18 wei; toWei("1") = 10**18

    // Contract logic
    bool public closed; // is the distribution closed
    bool public paused; // is the distribution paused
    bool public isFunded; // distribution can only start when required seed tokens have been funded
    bool public initialized; // is this contract initialized [not necessary that it is funded]
    bool public minimumReached; // if the softCap[minimum limit of funding token] is reached
    bool public maximumReached; // if the hardCap[maximum limit of funding token] is reached

    uint256 public totalFunderCount; // Total funders that have contributed.
    uint256 public seedRemainder; // Amount of seed tokens remaining to be distributed
    uint256 public seedClaimed; // Amount of seed token claimed by the user.
    uint256 public feeRemainder; // Amount of seed tokens remaining for the fee
    uint256 public fundingCollected; // Amount of funding tokens collected by the seed contract.
    uint256 public fundingWithdrawn; // Amount of funding token withdrawn from the seed contract.
    uint256 public feeClaimed; //Amount of all fee claimed when the seed was claimed.

    uint256 private minimalPrice;
    uint256 private fee;

    ContributorClass[] public classes; // Array of contributor classes

    mapping(address => bool) public whitelisted; // funders that are whitelisted and allowed to contribute
    mapping(address => FunderPortfolio) public funders; // funder address to funder portfolio

    event SeedsPurchased(address indexed recipient, uint256 amountPurchased);
    event TokensClaimed(
        address indexed recipient,
        uint256 amount,
        address indexed beneficiary,
        uint256 feeAmount
    );
    event FundingReclaimed(address indexed recipient, uint256 amountReclaimed);
    event MetadataUpdated(bytes indexed metadata);

    struct FunderPortfolio {
        uint8   class; // Contibutor class id
        uint256 totalClaimed; // Total amount of seed tokens claimed
        uint256 fundingAmount; // Total amount of funding tokens contributed
    }

    struct ContributorClass {
        uint256 classCap; // Amount of tokens that can be donated for class
        uint256 individualCap; // Amount of tokens that can be donated by specific contributor
        uint256 price; // Price of seed tokens for class, expressed in fundingTokens, with precision of 10**18
        uint256 vestingDuration; // Vesting duration for class
        uint256 classVestingStartTime;
        uint256 classFee; // Fee of class
        uint256 classFundingCollected; // Total amount of staked tokens        
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Seed: caller should be admin");
        _;
    }

    modifier isActive() {
        require(!closed, "Seed: should not be closed");
        require(!paused, "Seed: should not be paused");
        _;
    }

    modifier classRestriction(uint256 _classVestingStartTime, uint256 _classFee, uint256 _classCap) {
        require(
            endTime < _classVestingStartTime,
            "Seed: vesting start time can't be less than endTime"
        );
        require(block.timestamp < startTime,
            "Seed: vesting is already started"
        );
        require(!closed, "Seed: should not be closed");
        require(
            _classFee < MAX_FEE,
            "Seed: fee cannot be more than 45%"
        );
        require(_classCap > 0,
            "Seed: class Cap should be bigger then 0"
        );
        _;
    }

    function calculateSeedAndFee(uint256 _price, uint256 _classFee, uint256 _classCap) internal {
        if(_classFee > fee){
            fee = _classFee;
        }
        if(_price < minimalPrice){
            seedAmountRequired = (((hardCap - _classCap) * PRECISION) / minimalPrice)
                + (_classCap * PRECISION) / _price;
            minimalPrice = _price;
        }
        feeAmountRequired = (seedAmountRequired * fee) / PRECISION;
        seedRemainder = seedAmountRequired;
        feeRemainder = feeAmountRequired;
    }

    function _addClass(
        uint256 _classCap,
        uint256 _individualCap,
        uint256 _price,
        uint256 _vestingDuration,
        uint256 _classVestingStartTime,
        uint256 _classFee
    ) internal classRestriction(_classVestingStartTime, _classFee, _classCap){
        calculateSeedAndFee(_price, _classFee, _classCap);

        // the maximum possible classCap is calculated.
        classes.push( ContributorClass(
                _classCap,
                _individualCap,
                _price,
                _vestingDuration,
                _classVestingStartTime,
                _classFee,
                0));
    }

    /**
      * @dev                          Initialize Seed.
      * @param _beneficiary           The address that recieves fees.
      * @param _admin                 The address of the admin of this contract. Funds contract
                                      and has permissions to whitelist users, pause and close contract.
      * @param _tokens                Array containing two params:
                                        - The address of the seed token being distributed.
      *                                 - The address of the funding token being exchanged for seed token.
      * @param _softHardThresholds    Array containing two params:
                                        - the minimum funding token collection threshold in wei denomination.
                                        - the highest possible funding token amount to be raised in wei denomination.
      * @param _price                 price of a SeedToken, expressed in fundingTokens, with precision of 10**18
      * @param _startTime             Distribution start time in unix timecode.
      * @param _endTime               Distribution end time in unix timecode.
      * @param _vestingDuration       Vesting period duration in seconds.
      * @param _vestingCliff          Cliff duration in seconds.
      * @param _permissionedSeed      Set to true if only whitelisted adresses are allowed to participate.
      * @param _fee                   Success fee expressed as a % (e.g. 10**18 = 100% fee, toWei('1') = 100%)
    */
    function initialize(
        address _beneficiary,
        address _admin,
        address[] memory _tokens,
        uint256[] memory _softHardThresholds,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint32 _vestingDuration,
        uint32 _vestingCliff,
        bool _permissionedSeed,
        uint256 _fee
    ) external {
        require(!initialized, "Seed: contract already initialized");
        initialized = true;

        // parameter check
        require(
            _tokens[0] != _tokens[1],
            "SeedFactory: seedToken cannot be fundingToken"
        );
        require(
            _softHardThresholds[1] >= _softHardThresholds[0],
            "SeedFactory: hardCap cannot be less than softCap"
        );
        require(
            _vestingDuration >= _vestingCliff,
            "SeedFactory: vestingDuration cannot be less than vestingCliff"
        );
        require(
            _endTime > _startTime,
            "SeedFactory: endTime cannot be less than equal to startTime"
        );
        require(
            _fee < MAX_FEE,
            "SeedFactory: fee cannot be more than 45%"
        );

        beneficiary = _beneficiary;
        admin = _admin;
        softCap = _softHardThresholds[0];
        hardCap = _softHardThresholds[1];
        startTime = _startTime;
        endTime = _endTime;
        uint256 vestingStartTime = endTime + 1;
        vestingCliff = _vestingCliff;
        permissionedSeed = _permissionedSeed;
        seedToken = IERC20(_tokens[0]);
        fundingToken = IERC20(_tokens[1]);
        fee = _fee;
        minimalPrice = _price;
        
        feeClaimed = 0;

        seedAmountRequired = (hardCap * PRECISION) / _price;
        // (seedAmountRequired*fee) / (100*FEE_PRECISION) = (seedAmountRequired*fee) / PRECISION
        //  where FEE_PRECISION = 10**16
        feeAmountRequired = (seedAmountRequired * fee) / PRECISION;
        // Adding default class of contributors(specifically for non-whitelisted seed)
        _addClass( hardCap, hardCap, _price, _vestingDuration, vestingStartTime, _fee);
        seedRemainder = seedAmountRequired;
        feeRemainder = feeAmountRequired;
    }

    /**
     * @dev                       Add contributor class.
     * @param _classCap           The total cap of the contributor class.
     * @param _individualCap      The personal cap of each contributor in this class.
     * @param _price              The token price for the addresses in this clas.
     * @param _vestingDuration    The vesting duration for this contributors class.
     * @param _classVestingStartTime The class vesting start time for the contributor class.
     * @param _classFee           The fee for the contributor class.
     */
    function addClass(
        uint256 _classCap,
        uint256 _individualCap,
        uint256 _price,
        uint256 _vestingDuration,
        uint256 _classVestingStartTime,
        uint256 _classFee
    ) onlyAdmin external {
        require(
            classes.length + 1 < 256,
            "Seed: can't add more then 256 classes"
        );

        _addClass(
            _classCap,
            _individualCap,
            _price,
            _vestingDuration,
            _classVestingStartTime,
            _classFee );
    }

    /**
     * @dev                       Set contributor class.
     * @param _address            Address of the contributor.
     * @param _class              Class of the contributor.
     */
    function setClass(
        address _address,
        uint8 _class
    ) onlyAdmin public {
        require(_class < classes.length, "Seed: incorrect class chosen");
        require(!closed, "Seed: should not be closed");
        require(block.timestamp < startTime,
            "Seed: vesting is already started"
        );
        funders[_address].class = _class;
    }

    /**
     * @dev                       Set contributor classes.
     * @param _addresses          Addresses of the contributors.
     * @param _classes            Classes of the contributor.
     */
    function setClassBatch(
        address[] memory _addresses,
        uint8[] memory _classes
    ) onlyAdmin external {
        require(_classes.length == _addresses.length, "Seed: incorrect data passed");
        for(uint256 i = 0; i < _addresses.length; i++){
            setClass(_addresses[i],_classes[i] );
        }
    }

    /**
     * @dev                       Change parameters in the class.
     * @param _class              Class for changing.
     * @param _classCap           The total cap of the contributor class.
     * @param _individualCap      The personal cap of each contributor in this class.
     * @param _price              The token price for the addresses in this clas.
     * @param _vestingDuration    The vesting duration for this contributors class.
     * @param _classVestingStartTime The class vesting start time for the contributor class.
     * @param _classFee           The fee for the contributor class.
     */
    function changeClass(
        uint8   _class,
        uint256 _classCap,
        uint256 _individualCap,
        uint256 _price,
        uint256 _vestingDuration,
        uint256 _classVestingStartTime,
        uint256 _classFee
    ) onlyAdmin external classRestriction(_classVestingStartTime, _classFee, _classCap){
        require(_class < classes.length, "Seed: incorrect class chosen");

        calculateSeedAndFee(_price, _classFee, _classCap);

        classes[_class].classCap = _classCap;
        classes[_class].individualCap = _individualCap;
        classes[_class].price = _price;
        classes[_class].vestingDuration = _vestingDuration;
        classes[_class].classVestingStartTime = _classVestingStartTime;
        classes[_class].classFee = _classFee;
    }

    /**
     * @dev                        Add contributor class batch.
     * @param _classCaps                The total caps of the contributor class.
     * @param _individualCaps        The personal caps of each contributor in this class.
     * @param _prices              The token prices for the addresses in this clas.
     * @param _vestingDurations    The vesting durations for this contributors class.
     * @param _classVestingStartTime The class vesting start time for the contributor class.
     * @param _classFee             The fee for the contributor class.
     */
    function addClassBatch(
        uint256[] memory _classCaps,
        uint256[] memory _individualCaps,
        uint256[] memory _prices,
        uint256[] memory _vestingDurations,
        uint256[] memory _classVestingStartTime,
        uint256[] memory _classFee
    ) onlyAdmin external {
        require(_classCaps.length <= 100, "Seed: Can't add batch with more then 100 classes");
        require(
            classes.length + _classCaps.length < 256,
            "Seed: can't add more then 256 classes"
        );
        require(_classCaps.length == _individualCaps.length &&
                _classCaps.length == _prices.length &&
                _classCaps.length == _vestingDurations.length &&
                _classCaps.length == _classVestingStartTime.length &&
                _classCaps.length == _classFee.length,
            "Seed: All provided arrays should be same size");
        for(uint8 i = 0; i < _classCaps.length; i++){
            calculateSeedAndFee(_prices[i], _classFee[i], _classCaps[i]);
            _addClass(
                _classCaps[i],
                _individualCaps[i],
                _prices[i],
                _vestingDurations[i],
                _classVestingStartTime[i],
                _classFee[i]);
        }
    }

    /**
     * @dev                     Buy seed tokens.
     * @param _fundingAmount    The amount of funding tokens to contribute.
     */
    function buy(uint256 _fundingAmount)
        external
        isActive
        returns (uint256, uint256)
    {
        require(
            !permissionedSeed || whitelisted[msg.sender],
            "Seed: sender has no rights"
        );

        ContributorClass memory userClass = classes[funders[msg.sender].class];
        require(!maximumReached, "Seed: maximum funding reached");
        require(_fundingAmount > 0, "Seed: cannot buy 0 tokens");
        // Checks if contributor has exceeded his personal or class cap.
        require((userClass.classFundingCollected + _fundingAmount) <= userClass.classCap,
            "Seed: maximum class funding reached");

        require((funders[msg.sender].fundingAmount + _fundingAmount) <= userClass.individualCap,
            "Seed: maximum personal funding reached");

        require(
            endTime >= block.timestamp && startTime <= block.timestamp,
            "Seed: only allowed during distribution period"
        );

        if (!isFunded) {
            require(
                // classSeedAmountRequired is an amount which is needed to be sold
                // So when it's reached, for others will their balance be bigger or not - doesn't matter anymore.
                seedToken.balanceOf(address(this)) >=
                    seedAmountRequired + feeAmountRequired,
                "Seed: sufficient seeds not provided"
            );
            isFunded = true;
        }

        // fundingAmount is an amount of fundingTokens required to buy _seedAmount of SeedTokens
        uint256 seedAmount = (_fundingAmount * PRECISION) / userClass.price;

        // feeAmount is an amount of fee we are going to get in seedTokens
        uint256 feeAmount = (seedAmount * classes[funders[msg.sender].class].classFee) / PRECISION;

        // total fundingAmount should not be greater than the hardCap
        require(
            fundingCollected + _fundingAmount <= hardCap,
            "Seed: amount exceeds contract sale hardCap"
        );

        fundingCollected += _fundingAmount;
        classes[funders[msg.sender].class].classFundingCollected += _fundingAmount;
        // the amount of seed tokens still to be distributed
        seedRemainder = seedRemainder - seedAmount;
        feeRemainder = feeRemainder - feeAmount;
        if (fundingCollected >= softCap) {
            minimumReached = true;
        }

        if (fundingCollected >= hardCap) {
            maximumReached = true;
            for(uint8 i = 0; i < classes.length; i++){
                classes[i].classVestingStartTime = block.timestamp + (classes[i].classVestingStartTime - endTime);
            }
        }

        //functionality of addFunder
        if (funders[msg.sender].fundingAmount == 0) {
            totalFunderCount++;
        }
        funders[msg.sender].fundingAmount += _fundingAmount;

        // Here we are sending amount of tokens to pay for seed tokens to purchase

        fundingToken.safeTransferFrom(
            msg.sender,
            address(this),
            _fundingAmount
        );

        emit SeedsPurchased(msg.sender, seedAmount);

        return (seedAmount, feeAmount);
    }

    /**
     * @dev                     Claim vested seed tokens.
     * @param _funder           Address of funder to calculate seconds and amount claimable
     * @param _claimAmount      The amount of seed token a users wants to claim.
     */
    function claim(address _funder, uint256 _claimAmount)
        external
        returns (uint256)
    {
        require(minimumReached, "Seed: minimum funding amount not met");
        FunderPortfolio memory tokenFunder = funders[_funder];
        uint8 currentId = tokenFunder.class;
        ContributorClass memory claimed = classes[currentId];
        uint256 currentClassVestingStartTime = claimed.classVestingStartTime;
        require(
            endTime < block.timestamp || maximumReached,
            "Seed: the distribution has not yet finished"
        );
        require(
            currentClassVestingStartTime < block.timestamp,
            "Seed: vesting start time for this class is not started yet"
        );
        uint256 amountClaimable;

        amountClaimable = calculateClaim(_funder);
        require(amountClaimable > 0, "Seed: amount claimable is 0");
        require(
            amountClaimable >= _claimAmount,
            "Seed: request is greater than claimable amount"
        );
        uint256 currentClassFee = claimed.classFee;
        uint256 feeAmountOnClaim = (_claimAmount * currentClassFee) / PRECISION;        

        funders[_funder].totalClaimed += _claimAmount;

        seedClaimed += _claimAmount;    
        feeClaimed += feeAmountOnClaim; 

        seedToken.safeTransfer(beneficiary, feeAmountOnClaim);
        seedToken.safeTransfer(_funder, _claimAmount);

        emit TokensClaimed(
            _funder,
            _claimAmount,
            beneficiary,
            feeAmountOnClaim
        );

        return feeAmountOnClaim;
    }

    /**
     * @dev         Returns funding tokens to user.
     */
    function retrieveFundingTokens() external returns (uint256) {
        require(
            startTime <= block.timestamp,
            "Seed: distribution haven't started"
        );
        require(!minimumReached, "Seed: minimum funding amount met");
        FunderPortfolio storage tokenFunder = funders[msg.sender];
        uint256 fundingAmount = tokenFunder.fundingAmount;
        require(fundingAmount > 0, "Seed: zero funding amount");
        seedRemainder += seedAmountForFunder(msg.sender);
        feeRemainder += feeForFunder(msg.sender);
        totalFunderCount--;
        tokenFunder.fundingAmount = 0;
        fundingCollected -= fundingAmount;
        classes[tokenFunder.class].classFundingCollected -= fundingAmount;

        fundingToken.safeTransfer(msg.sender, fundingAmount);
        
        emit FundingReclaimed(msg.sender, fundingAmount);

        return fundingAmount;
    }

    // ADMIN ACTIONS

    /**
     * @dev                     Pause distribution.
     */
    function pause() external onlyAdmin isActive {
        paused = true;
    }

    /**
     * @dev                     Unpause distribution.
     */
    function unpause() external onlyAdmin {
        require(closed != true, "Seed: should not be closed");
        require(paused == true, "Seed: should be paused");

        paused = false;
    }

    /**
      * @dev                Shut down contributions (buying).
                            Supersedes the normal logic that eventually shuts down buying anyway.
                            Also shuts down the admin's ability to alter the whitelist.
    */
    function close() external onlyAdmin {
        // close seed token distribution
        require(!closed, "Seed: should not be closed");
        closed = true;
        paused = false;
    }

    /**
     * @dev                     retrieve remaining seed tokens back to project.
     * @param _refundReceiver   refund receiver address
     */
    function retrieveSeedTokens(address _refundReceiver) external onlyAdmin {
        // transfer seed tokens back to admin
        /*
            Can't withdraw seed tokens until buying has ended and
            therefore the number of distributable seed tokens can no longer change.
        */
        require(
            closed || maximumReached || block.timestamp >= endTime,
            "Seed: The ability to buy seed tokens must have ended before remaining seed tokens can be withdrawn"
        );
        if (!minimumReached) {
            require( seedToken.balanceOf(address(this)) > 0,"Seed: Failed to transfer Seed Token");
            seedToken.safeTransfer(
                _refundReceiver,
                seedToken.balanceOf(address(this)));
        } else {
            // seed tokens to transfer = balance of seed tokens - totalSeedDistributed
            uint256 totalSeedDistributed = (seedAmountRequired +
                feeAmountRequired) - (seedRemainder + feeRemainder);
            uint256 amountToTransfer = seedToken.balanceOf(address(this)) -
                totalSeedDistributed;
            seedToken.safeTransfer(_refundReceiver, amountToTransfer);
        }
    }

    /**
     * @dev                     Add address to whitelist.
     * @param _buyer            Address which needs to be whitelisted
     * @param _class            Class to which buyer will be assigned
     */
    function whitelist(address _buyer, uint8 _class) external onlyAdmin {
        require(_class < classes.length, "Seed: incorrect class chosen");
        require(!closed, "Seed: should not be closed");
        require(permissionedSeed == true, "Seed: seed is not whitelisted");

        whitelisted[_buyer] = true;
        funders[_buyer].class = _class;
    }

    /**
     * @dev                     Add multiple addresses to whitelist.
     * @param _buyers           Array of addresses to whitelist addresses in batch
     * @param _classes          Array of classes assigned in batch
     */
    function whitelistBatch(address[] memory _buyers, uint8[] memory _classes) external onlyAdmin {
        require(!closed, "Seed: should not be closed");
        require(permissionedSeed == true, "Seed: seed is not whitelisted");
        for (uint256 i = 0; i < _buyers.length; i++) {
            require(_classes[i] < classes.length, "Seed: incorrect class chosen");
            whitelisted[_buyers[i]] = true;
            funders[_buyers[i]].class = _classes[i];
        }
    }

    /**
     * @dev                     Remove address from whitelist.
     * @param buyer             Address which needs to be unwhitelisted
     */
    function unwhitelist(address buyer) external onlyAdmin {
        require(!closed, "Seed: should not be closed");
        require(permissionedSeed == true, "Seed: seed is not whitelisted");

        whitelisted[buyer] = false;
    }

    /**
     * @dev                     Withdraw funds from the contract
     */
    function withdraw() external onlyAdmin {
        /*
            Admin can't withdraw funding tokens until buying has ended and
            therefore contributors can no longer withdraw their funding tokens.
        */
        require(
            maximumReached || (minimumReached && block.timestamp >= endTime),
            "Seed: cannot withdraw while funding tokens can still be withdrawn by contributors"
        );
        fundingWithdrawn = fundingCollected;
        // Send the entire seed contract balance of the funding token to the sale’s admin
        fundingToken.safeTransfer(msg.sender, fundingToken.balanceOf(address(this)));
    }

    /**
     * @dev                     Updates metadata.
     * @param _metadata         Seed contract metadata, that is IPFS Hash
     */
    function updateMetadata(bytes memory _metadata) external {
        require(
            initialized != true || msg.sender == admin,
            "Seed: contract should not be initialized or caller should be admin"
        );
        metadata = _metadata;
        emit MetadataUpdated(_metadata);
    }

    // GETTER FUNCTIONS
    /**
     * @dev                     Calculates the maximum claim
     * @param _funder           Address of funder to find the maximum claim
     */
    function calculateClaim(address _funder) public view returns (uint256) {
        FunderPortfolio memory tokenFunder = funders[_funder];
        uint8 currentId = tokenFunder.class;
        ContributorClass memory claimed = classes[currentId];
        uint256 currentClassVestingStartTime = claimed.classVestingStartTime;
  
        if (block.timestamp < currentClassVestingStartTime) {
            return 0;
        }

        // Check cliff was reached
        uint256 elapsedSeconds = block.timestamp - currentClassVestingStartTime;
        if (elapsedSeconds < vestingCliff) {
            return 0;
        }

        uint256 currentVestingDuration = claimed.vestingDuration;
        // If over vesting duration, all tokens vested
        if (elapsedSeconds >= currentVestingDuration) {
            return seedAmountForFunder(_funder) - tokenFunder.totalClaimed;
        } else {
            uint256 amountVested = (elapsedSeconds *
                seedAmountForFunder(_funder)) / currentVestingDuration;
            return amountVested - tokenFunder.totalClaimed;
        }
    }

    /**
     * @dev                     get fee claimed for funder
     * @param _funder           address of funder to check fee claimed
     */
    function feeClaimedForFunder(address _funder)
        external
        view
        returns (uint256)
    {
        FunderPortfolio memory tokenFunder = funders[_funder];
        uint8 currentId = tokenFunder.class;
        uint256 currentFee = classes[currentId].classFee; 

        return (funders[_funder].totalClaimed * currentFee) / PRECISION;
    }

    /**
     * @dev                     get fee for funder
     * @param _funder           address of funder to check fee
     */
    function feeForFunder(address _funder) public view returns (uint256) {
        FunderPortfolio memory tokenFunder = funders[_funder];
        uint8 currentId = tokenFunder.class;
        uint256 currentFee = classes[currentId].classFee; 

        return (seedAmountForFunder(_funder) * currentFee) / PRECISION;
    }

    /**
     * @dev                     get seed amount for funder
     * @param _funder           address of funder to seed amount
     */
    function seedAmountForFunder(address _funder)
        public
        view
        returns (uint256)
    {
        return (funders[_funder].fundingAmount * PRECISION) / classes[funders[_funder].class].price;
    }
}