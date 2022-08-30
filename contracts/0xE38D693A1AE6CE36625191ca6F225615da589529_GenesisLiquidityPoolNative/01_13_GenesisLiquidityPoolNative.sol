// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "GenesisLiquidityPool.sol";
import "IGenesisLiquidityPoolNative.sol";



contract GenesisLiquidityPoolNative is GenesisLiquidityPool {

    /// @param gexToken address of the GEX token contract
    /// @param poolWeight_ integer percentage 3 decimals [1, 1000] (1e3)
    /// @param initPoolPrice_ must be in 1e18 USD units
    constructor(
        address gexToken, 
        uint16 poolWeight_,
        uint256 initPoolPrice_
    ) 
    GenesisLiquidityPool(
        gexToken, 
        address(0),
        poolWeight_,
        initPoolPrice_
    ) {}

    

    /// @dev Transfer all liquidity of the pool to another pool.
    /// This pool needs to have reduced its weight to less than 2%.
    /// Removes this pool from the Geminon Oracle list. The pool gets blocked and
    /// can't be used again after this action because the require(balance > 0)
    /// statements of the mint and redeem functions will revert.
    function migratePool() external override onlyOwner whenMintPaused {
        require(isMigrationRequested); // dev: migration not requested
        require(address(oracleGeminon) != address(0)); // dev: oracle is not set
        require(block.timestamp - oracleAge > 60 days); // dev: oracle too new
        require(oracleGeminon.isMigratingPool(address(this))); // dev: migration not requested
        require(block.timestamp - timestampMigrationRequest > 30 days); // dev: timelock
        require(poolWeight < 20); // dev: pool weight too high
        require((getCollateralValue() *1e3) / oracleGeminon.getTotalCollatValue() < 20); // dev: actual pool weight too high
        
        uint256 amountGEX = GEX.balanceOf(address(this)) - balanceFees;
        uint256 amountCollateral = balanceCollateral;
        
        balanceGEX = 0;
        balanceCollateral = 0;
        mintedGEX -= _toInt256(balanceGEX);

        isMigrationRequested = false;

        GEX.approve(migrationPool, amountGEX);
        
        IGenesisLiquidityPoolNative(migrationPool).receiveMigrationNative{value: amountCollateral}(amountGEX, initMintedAmount);
        
        oracleGeminon.setMigrationDone();
    }
 
    /// @dev Withdraw the remaining liquidity of the pool. Prior to this action the
    /// pool needs to have reduced its weight to less than 1% and this has to be requested
    /// at least 30 days before. 
    /// Removes this pool from the Geminon Oracle list. The pool gets blocked and
    /// can't be used again after this action.
    function removePool() external override onlyOwner whenMintPaused {
        require(isRemoveRequested); // dev: remove not requested
        require(address(oracleGeminon) != address(0)); // dev: oracle is not set
        require(block.timestamp - oracleAge > 60 days); // dev: oracle too new
        require(oracleGeminon.isRemovingPool(address(this))); // dev: remove not requested
        require(block.timestamp - timestampMigrationRequest > 30 days); // dev: timelock
        require(poolWeight < 10); // dev: pool weight too high
        require((getCollateralValue() *1e3) / oracleGeminon.getTotalCollatValue() < 10); // dev: pool weight too high
        
        balanceGEX = 0;
        balanceCollateral = 0;

        isRemoveRequested = false;

        require(GEX.transfer(owner(), GEX.balanceOf(address(this))));
        payable(owner()).transfer(address(this).balance);
        
        oracleGeminon.setRemoveDone();
    }

    /// @dev Receive the funds of another pool that is migrating.
    function receiveMigrationNative(uint256 amountGEX, uint256 initMintedAmount_) external payable {
        require(isInitialized); // dev: not initialized
        require(address(oracleGeminon) != address(0)); // dev: oracle is not set
        require(oracleGeminon.isPool(msg.sender)); // dev: sender is not pool
        require(oracleGeminon.isMigratingPool(msg.sender)); // dev: migration not requested

        if (initMintedAmount == 0) {
            require(initMintedAmount_ != 0); // dev: null init minted amount
            initMintedAmount = initMintedAmount_;
        }
        balanceGEX += amountGEX;
        balanceCollateral += msg.value;
        mintedGEX += _toInt256(amountGEX);

        require(GEX.transferFrom(msg.sender, address(this), amountGEX));
    }



    /// @dev mintSwap function from the parent class can't be overriden by a 
    /// payable function. We override it with a dummy to avoid it's use. 
    function mintSwap(uint256 inCollatAmount, uint256 minOutGEXAmount) external pure override {
        require(inCollatAmount == 0);
        require(minOutGEXAmount == 0);
        revert();
    }
    
    /// @notice Swaps Collateral for GEX. Mints a percentage of the
    /// amount of GEX tokens as new supply.
    function mintSwapNative(uint256 minOutGEXAmount) external payable whenMintNotPaused {
        require(balanceGEX > 0);
        
        uint256 outGEXAmount = amountOutGEX(msg.value);
        uint256 fee = amountFeeMint(outGEXAmount);
        require(outGEXAmount - fee >= minOutGEXAmount, "Max slippage");
        uint256 amountMinted = amountMint(outGEXAmount);
        
        balanceFees += fee;
        balanceCollateral += msg.value;
        balanceGEX += amountMinted;
        balanceGEX -= outGEXAmount;
        mintedGEX += _toInt256(amountMinted);

        _updateOracle(outGEXAmount);
        outGEXAmount -= fee;

        if (outGEXAmount == amountMinted)
            GEX.mint(msg.sender, amountMinted);
        else {
            GEX.mint(address(this), amountMinted);
            require(GEX.transfer(msg.sender, outGEXAmount));
        }
    }

    /// @notice Swaps GEX for Collateral. Burns a percentage of the
    /// amount of GEX tokens to reduce supply.
    function redeemSwap(uint256 inGEXAmount, uint256 minOutCollatAmount) external override {
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
        payable(msg.sender).transfer(outCollateralAmount);
    }


    
    /// @dev Forces the contract balance to match the address balance.
    /// This should not be necessary unless someone sends tokens directly
    /// to the smart contract address. This can only be done if the error
    /// in the balances is less than 1% to avoid disrupting the pool.
    function matchBalances() override external onlyOwner {
        uint256 amountAddrGEX = GEX.balanceOf(address(this));
        uint256 amountAddrCollat = address(this).balance;
        require(amountAddrGEX != balanceGEX + balanceFees || amountAddrCollat != balanceCollateral); // dev: Balances match
        
        uint256 ratioError1 = (amountAddrGEX * 1e3) / (balanceGEX + balanceFees);
        uint256 ratioError2 = (amountAddrCollat * 1e3) / (balanceCollateral);
        require(ratioError1 < 990 && ratioError1 < 1010); // dev: difference too big
        require(ratioError2 < 990 && ratioError2 < 1010); // dev: difference too big

        balanceCollateral = amountAddrCollat;
        balanceGEX = amountAddrGEX - balanceFees;
    }


    /// @notice Transfer collateral tokens to the lending contract. Max amount is limited
    /// to 50% of the total value of the GEX locked in other smart contracts or 25% of the
    /// collateral balance of this pool. Lent amount is not substracted from pool balance 
    /// to avoid disrupting the price.
    function lendCollateral(uint256 amount) external override returns(uint256) {
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

        payable(treasuryLender).transfer(amountBorrowed);

        return amountBorrowed;
    }

    /// @notice Get back collateral tokens from the lending contract
    function repayCollateralNative() external payable returns(uint256) {
        require(balanceLent > 0); // dev: Nothing to repay
        require(msg.sender == treasuryLender); // dev: invalid caller address

        uint256 amount = msg.value;
        uint256 amountRepaid = amount <= balanceLent ? amount : balanceLent;
        
        balanceLent -= amountRepaid;

        return amountRepaid;
    }
}