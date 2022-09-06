// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";
import "IGenesisLiquidityPool.sol";
import "IGeminonOracle.sol";
import "IERC20ElasticSupply.sol";
import "TradePausable.sol";
import "TimeLocks.sol";



/**
* @title GenesisLiquidityPool
* @author Geminon Protocol
* @notice Smart liquidity pool with Liquidity Bootstrapping capacity.
*/
contract GenesisLiquidityPool is Ownable, TradePausable, TimeLocks, IGenesisLiquidityPool {

    IERC20ElasticSupply internal immutable GEX;
    IERC20 private immutable collateral;

    IGeminonOracle internal oracleGeminon;
    AggregatorV3Interface private collatPriceFeed;
        
    address public scMinter;
    address public treasuryLender;
    address public arbitrageur;
    address private feesCollector;
    
    bool public isInitialized;
    uint64 public oracleAge;
    
    uint256 public initPoolPrice;
    uint256 public initMintedAmount;
    uint256 public targetSupply;
    uint256 public poolSupply;
    uint16 public poolWeight;

    uint32 public minMintRate;
    uint32 public minBurnRate;
    
    uint32 public baseMintFee;
    uint32 public baseRedeemFee;
    
    int256 public mintedGEX;
    uint256 public balanceCollateral;
    uint256 public balanceGEX;
    uint256 public balanceLent;
    uint256 internal balanceFees;

    uint64 public blockTimestampLast;
    uint256 public lastCollatPrice;
    uint256 public meanPrice;
    uint256 public lastPrice;
    uint256 public meanVolume;
    uint256 public lastVolume;
    
    bool public isMigrationRequested;
    bool public isRemoveRequested;
    uint64 public timestampMigrationRequest;
    address public migrationPool;



    /// @param gexToken address of the GEX token contract
    /// @param collatToken address of the collateral token contract
    /// @param poolWeight_ integer percentage 3 decimals [1, 1000] (1e3)
    /// @param initPoolPrice_ must be in 1e18 USD units
    constructor(
        address gexToken, 
        address collatToken,
        uint16 poolWeight_,
        uint256 initPoolPrice_
    ) {
        GEX = IERC20ElasticSupply(gexToken);
        collateral = IERC20(collatToken);
        
        initPoolPrice = initPoolPrice_;
        poolWeight = poolWeight_;
        
        meanPrice = initPoolPrice;
        lastPrice = meanPrice;

        targetSupply = 100000000*1e18;
        poolSupply = (targetSupply * poolWeight) / 1e3;

        minMintRate = 1e6;
        minBurnRate = 1e6;
        baseMintFee = 1000;
        baseRedeemFee = 2000;

        isInitialized = false;
        _pauseMint();
    }

    
    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                          INITIALIZATION                            +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Initializes the pool. Only the priceFeed address is mandatory for
    /// the initialization. Other addresses can be set later as they are not
    /// needed for the pool to work. 
    /// @param initMintShare integer percentage 3 decimals [1, 1000] (1e3)
    /// @param oracle address of the Geminon's internal oracle
    /// @param priceFeed address of the collateral token price feed contract
    /// @param scMinter_ address of the stablecoin minter contract
    /// @param treasuryLender_ address of the treasury lending contract
    /// @param feesCollector_ address of the fees collector contract
    /// @param arbitrageur_ address of the protocol arbitrage operator
    function initialize(
        uint16 initMintShare, 
        address oracle,
        address priceFeed,
        address scMinter_,
        address treasuryLender_,
        address feesCollector_,
        address arbitrageur_
    ) 
        external onlyOwner 
    {
        require(!isInitialized); // dev: Already initialized
        require(initPoolPrice != 0); // dev: init pool price is zero
        require(poolSupply != 0); // dev: pool supply is zero
        require(priceFeed != address(0)); // dev: price feed required

        oracleGeminon = IGeminonOracle(oracle);
        if (oracle != address(0))
            oracleAge = uint64(block.timestamp);
        collatPriceFeed = AggregatorV3Interface(priceFeed);
        scMinter = scMinter_;
        treasuryLender = treasuryLender_;
        feesCollector = feesCollector_;
        arbitrageur = arbitrageur_;

        initMintedAmount = (initMintShare * poolSupply) / 1e3;
        if (initMintedAmount > 0)
            GEX.mint(address(this), initMintedAmount);
        mintedGEX = _toInt256(initMintedAmount);
        balanceGEX = initMintedAmount;
        meanVolume = initMintedAmount;

        blockTimestampLast = uint64(block.timestamp);
        lastCollatPrice = collateralPrice();

        isInitialized = true;
    }

    
    /// @dev Initializes the address of the stablecoin minter. 
    /// This function can only be used if the address has not been
    /// already initialized.
    function setSCMinter(address scMinter_) external onlyOwner {
        require(scMinter == address(0)); // dev: already set
        scMinter = scMinter_;
    }

    /// @dev Initializes the address of the Geminon oracle.
    /// This function can only be used if the address has not been 
    /// already initialized.
    function setOracle(address oracle) external onlyOwner {
        require(address(oracleGeminon) == address(0)); // dev: already set
        oracleGeminon = IGeminonOracle(oracle);
        oracleAge = uint64(block.timestamp);
    }

    /// @dev Initializes the address of the treasury lending and borrowing contract.
    /// This function can only be used if the address has not been
    /// already initialized.
    function setLender(address treasuryLender_) external onlyOwner {
        require(treasuryLender == address(0)); // dev: already set
        treasuryLender = treasuryLender_;
    }

    /// @dev Set the address of the fees collector contract.
    /// This function can be used anytime as it has no impact on the
    /// pool or the users. Can be reset to 0.
    function setCollector(address feesCollector_) external onlyOwner {
        feesCollector = feesCollector_;
    }

    /// @dev Set the address of the arbitrage operator.
    /// This function can be used anytime as it has no impact on the
    /// pool or the users. Can be reset to 0.
    function setArbitrageur(address arbitrageur_) external onlyOwner {
        arbitrageur = arbitrageur_;
    }

    
    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                       PARAMETERS CHANGES                           +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    /// @notice Changes the value of the base mint fee
    /// Max allowed value is 0.5% 
    function setMintFee(uint32 value) external onlyOwner {
        require(value <= 5000);
        baseMintFee = value;
    }

    /// @notice Changes the value of the base redeem fee
    /// Max allowed value is 0.5%
    function setRedeemFee(uint32 value) external onlyOwner {
        require(value <= 5000);
        baseRedeemFee = value;
    }

    /// @notice Changes the weight of the pool in the GEX collateralization
    /// The difference with the previous weight can not be higher than 5%
    /// The difference with the actual weight can not be higher than 10%
    /// Can't be rised if migration or removal has been requested.
    function setPoolWeight(uint16 weight) external onlyOwner {
        require(weight > 0); // dev: invalid weight value
        require(weight != poolWeight); // dev: weight is the same
        if (weight > poolWeight) {
            require(!isMigrationRequested); // dev: migration requested
            require(!isRemoveRequested); // dev: remove requested
        }

        uint256 absDiff = weight > poolWeight ? weight - poolWeight : poolWeight - weight;
        require(absDiff <= 50); // dev: weight change too big

        uint256 actualWeight = (getCollateralValue() *1e3) / oracleGeminon.getTotalCollatValue();
        absDiff = weight > actualWeight ? weight - actualWeight : actualWeight - weight;
        require(absDiff <= 100); // dev: oracle weight change too big
        
        poolWeight = weight;
        poolSupply = (targetSupply * poolWeight) / 1e3;
    }

    /// @notice Changes slightly the terminal rate of mint / burn of the pool. 
    /// It is only allowed to input values that make the pool deflationary.
    function setMintRates(uint32 mintRate, uint32 burnRate) external onlyOwner {
        require(mintRate <= 1e6); // dev: mintRate too high
        require(mintRate >= 95*1e4);  // dev: mintRate too low
        require(burnRate >= 1e6); // dev: burnRate too low
        require(burnRate <= 105*1e4);  // dev: burnRate too high

        minMintRate = mintRate;
        minBurnRate = burnRate;
    }



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +             SMART CONTRACTS INFRASTRUCTURE CHANGES                 +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Apply the change in the price feed address proposed using
    /// the requestAddressChange() function. This function can only be called
    /// 7 days after the request of the change. Price feed is not critical for
    /// this contract to work or for its safety.
    function applyPriceFeedChange() external onlyOwner {
        require(changeRequests[address(collatPriceFeed)].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[address(collatPriceFeed)].timestampRequest > 7 days);  // dev: Time elapsed
        require(changeRequests[address(collatPriceFeed)].newAddressRequested != address(0)); // dev: Address zero

        changeRequests[address(collatPriceFeed)].changeRequested = false;
        collatPriceFeed = AggregatorV3Interface(changeRequests[address(collatPriceFeed)].newAddressRequested);
    }

    /// @dev Apply the change in the stablecoin minter address proposed using
    /// the requestAddressChange() function. This function can only be called
    /// 30 days after the request of the change.
    function applySCMinterChange() external onlyOwner {
        require(changeRequests[scMinter].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[scMinter].timestampRequest > 30 days); // dev: Time elapsed
        require(changeRequests[scMinter].newAddressRequested != address(0)); // dev: Address zero

        changeRequests[scMinter].changeRequested = false;
        scMinter = changeRequests[scMinter].newAddressRequested;
    }

    /// @dev Apply the change in the GEX oracle address proposed using
    /// the requestAddressChange() function. This function can only be called
    /// 30 days after the request of the change.
    function applyOracleChange() external onlyOwner {
        require(!isMigrationRequested); // dev: migration requested
        require(!isRemoveRequested); // dev: remove pool requested
        require(changeRequests[address(oracleGeminon)].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[address(oracleGeminon)].timestampRequest > 30 days); // dev: Time elapsed
        require(changeRequests[address(oracleGeminon)].newAddressRequested != address(0)); // dev: Address zero

        changeRequests[address(oracleGeminon)].changeRequested = false;
        oracleGeminon = IGeminonOracle(changeRequests[address(oracleGeminon)].newAddressRequested);
        oracleAge = uint64(block.timestamp);
    }

    /// @dev Apply the change in the treasury lender address proposed using
    /// the requestAddressChange() function. This function can only be called
    /// 30 days after the request of the change. Can be reset to 0.
    function applyLenderChange() external onlyOwner {
        require(changeRequests[treasuryLender].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[treasuryLender].timestampRequest > 30 days); // dev: Time elapsed

        changeRequests[treasuryLender].changeRequested = false;
        treasuryLender = changeRequests[treasuryLender].newAddressRequested;
    }
    


    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                          POOL MIGRATION                            +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Register a request to migrate the pool.
    /// Previously the pool weight needs to have been reduced to
    /// less than 5%.
    /// Begins a timelock of 30 days before enable the migration.
    /// The new pool needs to have been added to the oracle more than
    /// 7 days ago. Pauses the mint of GEX in this pool. It can't be unpaused 
    /// unless migration is cancelled. The oracle needs to have been used by  
    /// this pool for at least 30 days.
    function requestMigration(address newPool) external onlyOwner {
        require(!isMigrationRequested); // dev: migration already requested
        require(!isRemoveRequested); // dev: remove already requested
        require(newPool != address(this)); // dev: same pool
        require(address(oracleGeminon) != address(0)); // dev: oracle is not set
        require(block.timestamp - oracleAge > 30 days); // dev: oracle too new
        require(!oracleGeminon.isAnyPoolMigrating()); // dev: another pool is migrating
        require(!oracleGeminon.isAnyPoolRemoving()); // dev: another pool is removing
        require(!oracleGeminon.isMigratingPool(address(this))); // dev: migration already requested
        require(!oracleGeminon.isRemovingPool(address(this))); // dev: migration already requested
        require(block.timestamp - oracleGeminon.poolAge(newPool) > 7 days); // dev: pool too new
        require(poolWeight < 50); // dev: pool weight too high
        require((getCollateralValue() *1e3) / oracleGeminon.getTotalCollatValue() < 50); // dev: actual pool weight too high
        
        isMigrationRequested = true;
        timestampMigrationRequest = uint64(block.timestamp);
        migrationPool = newPool;
        _pauseMint();
        oracleGeminon.requestMigratePool(newPool);
    }

    /// @dev Register a request to withdraw the remaining pool liquidity.
    /// Previously the pool weight needs to have been reduced to
    /// less than 5%.
    /// Begins a timelock of 30 days before enabling the withdrawal.
    /// Pauses the mint of GEX in this pool. It can't be unpaused 
    /// unless remove is cancelled. The oracle needs to have been used by 
    /// this pool for at least 30 days.
    function requestRemove() external onlyOwner {
        require(!isMigrationRequested); // dev: migration already requested
        require(!isRemoveRequested); // dev: remove already requested
        require(address(oracleGeminon) != address(0)); // dev: oracle is not set
        require(block.timestamp - oracleAge > 30 days); // dev: oracle too new
        require(!oracleGeminon.isAnyPoolMigrating()); // dev: another pool is migrating
        require(!oracleGeminon.isAnyPoolRemoving()); // dev: another pool is removing
        require(!oracleGeminon.isMigratingPool(address(this))); // dev: migration already requested
        require(!oracleGeminon.isRemovingPool(address(this))); // dev: migration already requested
        require(poolWeight < 50); // dev: pool weight too high
        require((getCollateralValue() *1e3) / oracleGeminon.getTotalCollatValue() < 50); // dev: actual pool weight too high

        isRemoveRequested = true;
        timestampMigrationRequest = uint64(block.timestamp);
        _pauseMint();
        oracleGeminon.requestRemovePool();
    }

    
    /// @dev Transfer all liquidity of the pool to another pool.
    /// This pool needs to have reduced its weight to less than 2%.
    /// Removes this pool from the Geminon Oracle list. The pool gets blocked and
    /// can't be used again after this action because the require(balance > 0)
    /// statements of the mint and redeem functions will revert.
    function migratePool() external virtual onlyOwner whenMintPaused {
        require(isMigrationRequested); // dev: migration not requested
        require(address(oracleGeminon) != address(0)); // dev: oracle is not set
        require(block.timestamp - oracleAge > 60 days); // dev: oracle too new
        require(oracleGeminon.isMigratingPool(address(this))); // dev: migration not requested
        require(block.timestamp - timestampMigrationRequest > 30 days); // dev: timelock
        require(poolWeight < 20); // dev: pool weight too high
        require((getCollateralValue() *1e3) / oracleGeminon.getTotalCollatValue() < 20); // dev: actual pool weight too high
        
        uint256 amountGEX = GEX.balanceOf(address(this)) - balanceFees;
        uint256 amountCollateral = collateral.balanceOf(address(this));
        
        balanceGEX = 0;
        balanceCollateral = 0;
        mintedGEX -= _toInt256(balanceGEX);

        isMigrationRequested = false;

        GEX.approve(migrationPool, amountGEX);
        collateral.approve(migrationPool, amountCollateral);

        IGenesisLiquidityPool(migrationPool).receiveMigration(amountGEX, amountCollateral, initMintedAmount);
        
        oracleGeminon.setMigrationDone();
    }

    /// @dev Withdraw the remaining liquidity of the pool. Prior to this action the
    /// pool needs to have reduced its weight to less than 1% and this has to be requested
    /// at least 30 days before. 
    /// Removes this pool from the Geminon Oracle list. The pool gets blocked and
    /// can't be used again after this action.
    function removePool() external virtual onlyOwner whenMintPaused {
        require(isRemoveRequested); // dev: remove not requested
        require(address(oracleGeminon) != address(0)); // dev: oracle is not set
        require(block.timestamp - oracleAge > 60 days); // dev: oracle too new
        require(oracleGeminon.isRemovingPool(address(this))); // dev: remove not requested
        require(block.timestamp - timestampMigrationRequest > 30 days); // dev: timelock
        require(poolWeight < 10); // dev: pool weight too high
        require((getCollateralValue() *1e3) / oracleGeminon.getTotalCollatValue() < 10); // dev: actual pool weight too high
        
        balanceGEX = 0;
        balanceCollateral = 0;
        
        isRemoveRequested = false;

        require(GEX.transfer(owner(), GEX.balanceOf(address(this))));
        require(collateral.transfer(owner(), collateral.balanceOf(address(this))));
        
        oracleGeminon.setRemoveDone();
    }


    /// @dev Receive the funds of another pool that is migrating.
    function receiveMigration(uint256 amountGEX, uint256 amountCollateral, uint256 initMintedAmount_) external {
        require(isInitialized); // dev: not initialized
        require(address(oracleGeminon) != address(0)); // dev: oracle is not set
        require(oracleGeminon.isPool(msg.sender)); // dev: sender is not pool
        require(oracleGeminon.isMigratingPool(msg.sender)); // dev: migration not requested

        if (initMintedAmount == 0) {
            require(initMintedAmount_ != 0); // dev: null init minted amount
            initMintedAmount = initMintedAmount_;
        }
        balanceGEX += amountGEX;
        balanceCollateral += amountCollateral;
        mintedGEX += _toInt256(amountGEX);

        require(GEX.transferFrom(msg.sender, address(this), amountGEX));
        require(collateral.transferFrom(msg.sender, address(this), amountCollateral));
    }


    /// @notice Cancels any pending request for changes in the smart contract
    function cancelChangeRequests() external onlyOwner {
        
        if (changeRequests[address(0)].changeRequested)
            changeRequests[address(0)].changeRequested = false;

        if (changeRequests[address(collatPriceFeed)].changeRequested)
            changeRequests[address(collatPriceFeed)].changeRequested = false;
        
        if (changeRequests[scMinter].changeRequested)
            changeRequests[scMinter].changeRequested = false;

        if (changeRequests[address(oracleGeminon)].changeRequested)
            changeRequests[address(oracleGeminon)].changeRequested = false;
        
        if (changeRequests[treasuryLender].changeRequested)
            changeRequests[treasuryLender].changeRequested = false;
        
        if (isMigrationRequested) {
            isMigrationRequested = false;
            _unpauseMint();
            oracleGeminon.cancelMigration();
        }

        if (isRemoveRequested) {
            isRemoveRequested = false;
            _unpauseMint();
            oracleGeminon.cancelRemove();
        }
        
    }



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                          USER FUNCTIONS                            +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @notice Swaps Collateral for GEX. Mints a percentage of the
    /// amount of GEX tokens as new supply.
    function mintSwap(uint256 inCollatAmount, uint256 minOutGEXAmount) external virtual whenMintNotPaused {
        require(balanceGEX > 0); // dev: pool not initialized
        
        uint256 outGEXAmount = amountOutGEX(inCollatAmount);
        uint256 fee = amountFeeMint(outGEXAmount);
        require(outGEXAmount - fee >= minOutGEXAmount, "Max slippage");
        uint256 amountMinted = amountMint(outGEXAmount);

        balanceFees += fee;
        balanceCollateral += inCollatAmount;
        balanceGEX += amountMinted;
        balanceGEX -= outGEXAmount;
        mintedGEX += _toInt256(amountMinted);

        _updateOracle(outGEXAmount);
        outGEXAmount -= fee;

        require(collateral.transferFrom(msg.sender, address(this), inCollatAmount));
        
        if (outGEXAmount == amountMinted)
            GEX.mint(msg.sender, amountMinted);
        else {
            GEX.mint(address(this), amountMinted);
            require(GEX.transfer(msg.sender, outGEXAmount));
        }
    }
    

    /// @notice Swaps GEX for Collateral. Burns a percentage of the
    /// amount of GEX tokens to reduce supply.
    function redeemSwap(uint256 inGEXAmount, uint256 minOutCollatAmount) external virtual {
        require(balanceCollateral > 0);

        uint256 fee = amountFeeRedeem(inGEXAmount);
        uint256 outCollateralAmount = amountOutCollateral(inGEXAmount - fee);
        require(outCollateralAmount >= minOutCollatAmount, "Max slippage");
        uint256 amountBurned = amountBurn(inGEXAmount);

        balanceFees += fee;
        balanceGEX += inGEXAmount;
        balanceGEX -= fee + amountBurned;
        balanceCollateral -= outCollateralAmount;
        mintedGEX -= _toInt256(amountBurned);

        _updateOracle(inGEXAmount);

        if (inGEXAmount == amountBurned)
            GEX.burn(msg.sender, amountBurned);
        else {
            GEX.burn(address(this), amountBurned);
            require(GEX.transferFrom(msg.sender, address(this), inGEXAmount));
        }
        require(collateral.transfer(msg.sender, outCollateralAmount));
    }
    


    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                        PROTOCOL FUNCTIONS                          +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    /// @dev Pauses GEX mint in the pool. Redeems can not be paused.
    function pauseMint() external onlyOwner whenMintNotPaused {
        _pauseMint();
    }

    /// @dev Unpauses GEX mint in the pool. Can not unpause if migration or remove
    /// has been requested as those actions pause the pool as security measure.
    function unpauseMint() external onlyOwner whenMintPaused {
        require(!isMigrationRequested); // dev: migration requested
        require(!isRemoveRequested); // dev: remove requested
        _unpauseMint();
    }

    /// @dev Forces the contract balance to match the address balance.
    /// This should not be necessary unless someone sends tokens directly
    /// to the smart contract address. This can only be done if the error
    /// in the balances is less than 1% to avoid disrupting the pool.
    function matchBalances() virtual external onlyOwner {
        uint256 amountAddrGEX = GEX.balanceOf(address(this));
        uint256 amountAddrCollat = collateral.balanceOf(address(this));
        require(amountAddrGEX != balanceGEX + balanceFees || amountAddrCollat != balanceCollateral); // dev: Balances match
        
        uint256 ratioError1 = (amountAddrGEX * 1e3) / (balanceGEX + balanceFees);
        uint256 ratioError2 = (amountAddrCollat * 1e3) / (balanceCollateral);
        require(ratioError1 < 990 && ratioError1 < 1010); // dev: difference too big
        require(ratioError2 < 990 && ratioError2 < 1010); // dev: difference too big

        balanceCollateral = amountAddrCollat;
        balanceGEX = amountAddrGEX - balanceFees;
    }


    /// @notice Transfer GEX tokens to the stablecoin minter contract in case it
    /// has not enough funds to serve the stablecoin redemptions. The max amount per
    /// transfer is limited to 5% of the pool balance to avoid large price disruptions.
    function bailoutMinter() external returns(uint256 bailoutAmount) {
        require(balanceGEX > 0); // dev: pool empty
        require(scMinter != address(0)); // dev: scminter not set
        require(address(oracleGeminon) != address(0)); // dev: oracle not set
        require(block.timestamp - oracleGeminon.ageSCMinter() > 7 days); // dev: scminter too new
        require(block.timestamp - oracleAge > 30 days); // dev: oracle too new
        require(msg.sender == scMinter || msg.sender==owner()); // dev: invalid caller address
        require(oracleGeminon.getLockedAmountGEX() < balanceGEX*5/100); // dev: scminter over balance threshold

        if (mintedGEX > 0)
            bailoutAmount = balanceGEX/100 > uint256(mintedGEX)/100 ? balanceGEX/100 : uint256(mintedGEX)/100;
        else
            bailoutAmount = balanceGEX/100;

        bailoutAmount = bailoutAmount > (balanceGEX*5)/100 ? (balanceGEX*5)/100 : bailoutAmount;

        balanceGEX -= bailoutAmount;
        
        GEX.approve(scMinter, bailoutAmount);

        return bailoutAmount;
    }

    
    /// @notice Transfer collateral tokens to the lending contract. Max amount is limited
    /// to 50% of the total value of the GEX locked in other smart contracts or 25% of the
    /// collateral balance of this pool. Lent amount is not substracted from pool balance 
    /// to avoid disrupting the price.
    function lendCollateral(uint256 amount) external virtual returns(uint256) {
        require(amount > 0); // dev: null amount
        require(balanceCollateral > 0); // dev: pool empty
        require(treasuryLender != address(0)); // dev: lender not set
        require(address(oracleGeminon) != address(0)); // dev: oracle not set
        require(block.timestamp - oracleGeminon.ageTreasuryLender() > 7 days); // dev: lender too new
        require(block.timestamp - oracleAge > 30 days); // dev: oracle too new
        require(scMinter != address(0)); // dev: scMinter not set
        require(msg.sender == treasuryLender); // dev: invalid caller address
        require(!isMigrationRequested); // dev: migration requested
        require(!isRemoveRequested); // dev: remove requested

        uint256 amountEqLocked = (oracleGeminon.getLockedAmountGEX() * GEXQuote() * poolWeight) / 1e21;
        require(amountEqLocked > 0); // dev: null amount locked on scminter

        uint256 amountBorrowed = amount + balanceLent <= 5*amountEqLocked/10 ? amount : 5*amountEqLocked/10 - balanceLent;
        amountBorrowed = amountBorrowed + balanceLent <= 25*balanceCollateral/100 ? amountBorrowed : 25*balanceCollateral/100 - balanceLent;
        
        require(amountBorrowed > 0);  // dev: amount borrowed null
        balanceLent += amountBorrowed;

        collateral.approve(treasuryLender, amountBorrowed);

        return amountBorrowed;
    }

    /// @notice Get back collateral tokens from the lending contract
    function repayCollateral(uint256 amount) external returns(uint256) {
        require(balanceLent > 0); // dev: Nothing to repay
        require(msg.sender == treasuryLender); // dev: invalid caller address

        uint256 amountRepaid = amount <= balanceLent ? amount : balanceLent;
        
        balanceLent -= amountRepaid;

        require(collateral.transferFrom(treasuryLender, address(this), amountRepaid));
        collateral.approve(treasuryLender, 0);

        return amountRepaid;
    }

    /// @dev Collects the fees generated by this contract
    function collectFees() external returns(uint256) {
        require(balanceFees > 0); // dev: Nothing to collect
        require(feesCollector != address(0)); // dev: collector not set
        require(address(oracleGeminon) != address(0)); // dev: oracle not set
        require(oracleGeminon.feesCollector() != address(0)); //dev: collector not set in oracle
        require(block.timestamp - oracleGeminon.ageFeesCollector() > 7 days); // dev: collector too new
        require(block.timestamp - oracleAge > 30 days); // dev: oracle too new
        require(msg.sender == feesCollector || msg.sender==owner()); // dev: invalid caller address
        
        uint256 feesCollected = balanceFees;
        balanceFees = 0;
        
        require(GEX.transfer(feesCollector, feesCollected));
        return feesCollected;
    }
    

    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                     INFORMATIVE FUNCTIONS                          +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @notice Get collateral token price in USD using an external oracle
    /// @dev Price feed gives answer with 8 decimals, we need 10 more to have 18
    function collateralPrice() public view returns(uint256) {
        (, int256 answer, , , ) = collatPriceFeed.latestRoundData();
        return uint256(answer * 1e10);
    }
    
    /// @notice Get the price of collateral relative to GEX
    function collateralQuote() public view returns(uint256) {
        if (balanceCollateral == 0) 
            return (collateralPrice() * 1e18) / initPoolPrice;
        
        return (balanceGEX * 1e18) / balanceCollateral;
    }


    /// @notice Gives the last GEX price of the liquidity pool in USD
    function GEXPrice() public view returns(uint256) {
        if (balanceCollateral == 0) 
            return initPoolPrice;
        else 
            return (collateralPrice() * balanceCollateral) / balanceGEX; 
    }

    /// @notice Get the price of GEX relative to collateral token
    function GEXQuote() public view returns(uint256) {
        if (balanceGEX == 0)
            return 0;
        else
            return (balanceCollateral * 1e18) / balanceGEX;
    }


    /// @notice Calculate the amount of the fee for minting GEX
    function amountFeeMint(uint256 amountGEX) public view returns(uint256) {
        return (amountGEX * variableFee(amountGEX, baseMintFee)) / 1e6;
    }

    /// @notice Calculate the amount of the fee for redeeming GEX
    function amountFeeRedeem(uint256 amountGEX) public view returns(uint256) {
        return (amountGEX * variableFee(amountGEX, baseRedeemFee)) / 1e6;
    }


    /// @notice Gives all mintSwap info at once. Reduces front-end RPC calls.
    /// All return values have 18 decimals except fee and priceImpact that have 6.
    function getMintInfo(uint256 inCollatAmount) public view returns(
        uint256 collateralPriceUSD, 
        uint256 initGEXPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outGEXAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    ) {
        collateralPriceUSD = collateralPrice();
        initGEXPriceUSD = GEXPrice();
        collatQuote = collateralQuote();
        gexQuote = GEXQuote();
        
        outGEXAmount = amountOutGEX(inCollatAmount);
        fee = variableFee(outGEXAmount, baseMintFee);
        feeAmount = amountFeeMint(outGEXAmount);
        outGEXAmount -= feeAmount;
        finalGEXPriceUSD = (collateralPriceUSD*inCollatAmount) / outGEXAmount;
        
        if (finalGEXPriceUSD >= initGEXPriceUSD)
            priceImpact = ((finalGEXPriceUSD - initGEXPriceUSD) * 1e6) / initGEXPriceUSD;
        else 
            priceImpact = ((initGEXPriceUSD - finalGEXPriceUSD) * 1e6) / initGEXPriceUSD;
    }

    /// @notice Gives all redeemSwap info at once. Reduces front-end RPC calls.
    /// All return values have 18 decimals except fee and priceImpact that have 6.
    function getRedeemInfo(uint256 inGEXAmount) public view returns(
        uint256 collateralPriceUSD, 
        uint256 initGEXPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outCollatAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    ) {
        collateralPriceUSD = collateralPrice();
        initGEXPriceUSD = GEXPrice();
        collatQuote = collateralQuote();
        gexQuote = GEXQuote();
        
        fee = variableFee(inGEXAmount, baseRedeemFee);
        feeAmount = amountFeeRedeem(inGEXAmount);
        outCollatAmount = amountOutCollateral(inGEXAmount - feeAmount);
        finalGEXPriceUSD = (collateralPriceUSD*outCollatAmount) / inGEXAmount;
        
        if (finalGEXPriceUSD >= initGEXPriceUSD)
            priceImpact = ((finalGEXPriceUSD - initGEXPriceUSD) * 1e6) / initGEXPriceUSD;
        else 
            priceImpact = ((initGEXPriceUSD - finalGEXPriceUSD) * 1e6) / initGEXPriceUSD;
    }


    /// @notice Get total collateral value in USD using an external oracle
    function getCollateralValue() public view returns(uint256) {
        return (collateralPrice() * balanceCollateral) / 1e18;
    }



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                         CORE FUNCTIONS                             +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @notice Calculate out amount of the GEX token
    function amountOutGEX(uint256 inCollatAmount) public view returns(uint256 outGEXAmount) {
        if (balanceCollateral == 0)
            outGEXAmount = _initOutGEXAmount(inCollatAmount);

        else {
            uint256 halfInCollatAmount = inCollatAmount / 2;
            uint256 k1 = balanceCollateral * balanceGEX;
            outGEXAmount = balanceGEX - k1 / (balanceCollateral + halfInCollatAmount);

            uint256 updatedBalanceGEX = (balanceGEX + amountMint(outGEXAmount)) - outGEXAmount;
            uint256 updatedBalanceCollat = balanceCollateral + halfInCollatAmount;
            uint256 k2 = updatedBalanceCollat * updatedBalanceGEX;
            outGEXAmount += updatedBalanceGEX - k2 / (balanceCollateral + inCollatAmount);
        }
        return outGEXAmount; 
    }
        

    /// @notice Calculate out amount of collateral token
    function amountOutCollateral(uint256 inGEXAmount) public view returns(uint256 outCollatAmount) {
        if (balanceCollateral == 0)
            outCollatAmount = 0;

        else {
            uint256 halfInGEXAmount = inGEXAmount / 2;
            uint256 k1 = balanceCollateral * balanceGEX;
            outCollatAmount = balanceCollateral - k1 / (balanceGEX + halfInGEXAmount);

            uint256 updatedBalanceGEX = (balanceGEX + halfInGEXAmount) - amountBurn(halfInGEXAmount);
            uint256 updatedBalanceCollat = balanceCollateral - outCollatAmount;
            uint256 k2 = updatedBalanceCollat * updatedBalanceGEX;
            outCollatAmount += updatedBalanceCollat - k2 / (updatedBalanceGEX + halfInGEXAmount);
        }
        
        return outCollatAmount;
    }
    

    /// @dev Calculates amount of GEX to mint
    function amountMint(uint256 outGEXAmount) public view returns(uint256) {
        return (_mintRatio()* outGEXAmount) / 1e6;
    }

    /// @dev Calculates amount of GEX to burn
    function amountBurn(uint256 inGEXAmount) public view returns(uint256) {
        uint256 amountBurned = (_burnRatio() * inGEXAmount) / 1e6;

        if (balanceGEX <= initMintedAmount)
            amountBurned = 0;
        
        else if (amountBurned + initMintedAmount >= balanceGEX + 99*inGEXAmount/100)
            amountBurned = 0;

        return amountBurned;
    }

    /// @notice Calculate the percentage of the fee over GEX depending on
    /// the amount. The higher the amount, the higher the fee.
    /// The arbitrageur of the protocol does not pay fees to allow perfect matching
    /// of the price between pools.
    function variableFee(uint256 amountGEX, uint256 baseFee) public view returns(uint256 fee) {
        if (msg.sender == arbitrageur) return 0;

        uint256 usdAmount = (amountGEX * lastPrice) / 1e18;

        if (usdAmount < 1000*1e18) 
            fee = baseFee;
        
        else if (usdAmount < 10000*1e18) 
            fee = baseFee + 500 * (usdAmount - 1000*1e18) / 9000 / 1e18;
        
        else if (usdAmount < 100000*1e18) 
            fee = baseFee + 500 + 500 * (usdAmount - 10000*1e18) / 90000 / 1e18;
        
        else if (usdAmount < 1000000*1e18) 
            fee = baseFee + 1000 + 1000 * (usdAmount - 100000*1e18) / 900000 / 1e18;
        
        else 
            fee = baseFee + 2000;
    }


    /// @dev Updates the internal oracle that tracks price and amount of
    /// the trades. 
    function _updateOracle(uint256 amount) internal {
        uint256 elapsedTime = block.timestamp - blockTimestampLast;
        uint256 price = (lastCollatPrice * GEXQuote()) / 1e18;

        if (elapsedTime > 0) {
            uint256 alpha = (meanVolume * 1e6) / (1 + lastVolume);
            alpha = alpha > 1e6 ? 1e6 : alpha;
            meanPrice = (alpha*lastPrice + (1e6-alpha)*meanPrice) / 1e6;
            
            blockTimestampLast = uint64(block.timestamp);
            lastCollatPrice = collateralPrice();
        } 
        
        uint256 beta = (meanVolume * 1e6) / (1 + amount);
        beta = beta > 1e6 ? 1e6 : beta;
        lastPrice = (beta*price + (1e6-beta)*lastPrice) / 1e6;
        
        lastVolume = amount;
        meanVolume = amount/1000 + (999*meanVolume)/1000;
    }

    
    /// @dev safe casting of uint256 to int256 to avoid overflow
    function _toInt256(uint256 value) internal pure returns(int256) {
        require(value <= uint256(type(int256).max)); // dev: Unsafe casting
        return int256(value);
    }


    /// @dev Calculates the ratio to mint GEX. Uses 6 decimals.
    function _mintRatio() private view returns(uint256) {
        uint256 mintRatio = (_supplyRatio() * 1e6) / _poolWeightRatio();
        
        mintRatio = mintRatio > minMintRate ? mintRatio : minMintRate;
        mintRatio = mintRatio < 2e6 ? mintRatio : 2e6;
        
        return mintRatio;
    }

    /// @dev Calculates the ratio to burn GEX. Uses 6 decimals.
    function _burnRatio() private view returns(uint256) {
        uint256 burnRatio = (_supplyRatio() * _poolWeightRatio()) / 1e6;
        
        burnRatio = burnRatio > minBurnRate ? burnRatio : minBurnRate;
        burnRatio = burnRatio < 2e6 ? burnRatio : 2e6;
        
        return burnRatio;
    }

    /// @dev Modifies the amount to mint / burn to keep linear growth against
    /// the amount of collateral in the pool. Uses 6 decimals.
    function _supplyRatio() private view returns(uint256 supplyRatio) {
        if (address(oracleGeminon) == address(0)) {
            int256 poolSupply_ = _toInt256(poolSupply);
            supplyRatio = uint256(1e6 + ((poolSupply_ - mintedGEX) * 1e6) / poolSupply_);
        } else {
            uint256 totalMinted = oracleGeminon.getTotalMintedGEX();
            uint256 surplus = targetSupply > totalMinted ? targetSupply - totalMinted : 0;
            supplyRatio = 1e6 + (surplus * 1e6) / targetSupply;
        }
        
        supplyRatio =  supplyRatio > 1e6 ? supplyRatio : 1e6;
        supplyRatio =  supplyRatio < 2e6 ? supplyRatio : 2e6;
    }

    /// @dev Modifies the amount to mint / burn to keep collateral weight between 
    /// pools. Uses 6 decimals.
    function _poolWeightRatio() private view returns(uint256) {
        uint256 totalValue = oracleGeminon.getTotalCollatValue();
        uint256 poolValue = getCollateralValue();
        
        if (totalValue == 0 || poolValue == 0) 
            return 1e6;
        
        uint256 actualWeight = (poolValue * 1e3) / totalValue;
        uint256 weightRatio = (actualWeight * 1e6) / poolWeight;
        
        weightRatio = weightRatio > 75*1e4 ? weightRatio : 75*1e4;
        weightRatio = weightRatio < 125*1e4 ? weightRatio : 125*1e4;
        
        return weightRatio;
    }
    

    /// @dev Calculates out GEX amount for the first trade in the pool
    function _initOutGEXAmount(uint256 inCollatAmount) private view returns (uint256 outGEXAmount) {
        require(msg.sender == arbitrageur); // dev: Anti sniper bots

        uint256 collatPrice = collateralPrice();
        outGEXAmount = inCollatAmount * collatPrice / initPoolPrice;
        
        if (outGEXAmount > initMintedAmount) {
            outGEXAmount = initMintedAmount;
            uint256 spentCollatAmount = outGEXAmount * initPoolPrice / collatPrice;
            uint256 k = spentCollatAmount * outGEXAmount;
            outGEXAmount += outGEXAmount - (k / inCollatAmount);
        }

        return outGEXAmount;
    }
}