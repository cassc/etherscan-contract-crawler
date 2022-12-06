// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";

import "IGenesisLiquidityPool.sol";
import "ISCMinter.sol";

import "IGeminonBridge.sol";
import "TimeLocks.sol";


/**
* @title GeminonOracle
* @author Geminon Protocol
* @notice Protocol oracle. Performs both information
* functions, coordination functions and safety functions.
*/
contract GeminonOracle is Ownable, TimeLocks {
    
    bool public isAnyPoolMigrating;
    bool public isAnyPoolRemoving;

    address public scMinter;
    address public bridge;
    address public treasuryLender;
    address public feesCollector;
    address[] public pools;

    uint64 public ageSCMinter;
    uint64 public ageBridge;
    uint64 public ageTreasuryLender;
    uint64 public ageFeesCollector;

    bool public isMigratingMinter;
    address public newMinter;

    mapping(address => bool) public isPool;
    mapping(address => bool) public isMigratingPool;
    mapping(address => bool) public isRemovingPool;
    mapping(address => uint64) public poolAge;


    modifier onlyPool {
        require(isPool[msg.sender]);
        _;
    }

    modifier onlyMinter {
        require(msg.sender == scMinter);
        _;
    }


    constructor(address[] memory _pools) {
        for (uint16 i=0; i<_pools.length; i++) {
            _addPool(_pools[i]);
            poolAge[_pools[i]] = uint64(block.timestamp);
        }

        ageSCMinter = type(uint64).max;
        ageBridge = type(uint64).max;
        ageTreasuryLender = type(uint64).max;
        ageFeesCollector = type(uint64).max;
    }


    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                          INITIALIZATION                            +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    /// @notice Initializes the address of the stablecoin minter
    /// @dev this function can only be used once as it requires that the
    /// address hasn't been already initialized. To update the address 
    /// use the requestAddressChange() and applyMinterChange() functions.
    function setSCMinter(address scMinter_) external onlyOwner {
        require(scMinter == address(0));
        require(scMinter_ != address(0));

        scMinter = scMinter_;
        ageSCMinter = uint64(block.timestamp);
    }

    /// @notice Initializes the address of the bridge
    /// @dev this function can only be used once as it requires that the
    /// address hasn't been already initialized. To update the address 
    /// use the requestAddressChange() and applyMinterChange() functions.
    function setBridge(address bridge_) external onlyOwner {
        require(bridge == address(0));
        require(bridge_ != address(0));

        bridge = bridge_;
        ageBridge = uint64(block.timestamp);
    }

    /// @notice Initializes the address of the treasury lender.
    /// @dev this function can only be used once as it requires that the
    /// address hasn't been already initialized. To update the address 
    /// use the requestAddressChange() and applyLenderChange() functions.
    function setTreasuryLender(address lender) external onlyOwner {
        require(treasuryLender == address(0));
        require(lender != address(0));
        
        treasuryLender = lender;
        ageTreasuryLender = uint64(block.timestamp);
    }

    /// @dev Set the address of the fees collector contract.
    /// This function can be used anytime as it has no impact on the
    /// pool or the users. Can be reset to 0.
    function setCollector(address feesCollector_) external onlyOwner {
        feesCollector = feesCollector_;
        ageFeesCollector = uint64(block.timestamp);
    }

    
    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                         POOLS MIGRATION                            +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    /// @dev Adds a new liquitidty pool to the oracle. Timelock 7 days.
    function addPool(address newPool) external onlyOwner {
        require(changeRequests[address(0)].changeRequested); // dev: Not requested
        require(changeRequests[address(0)].timestampRequest != 0); // dev: Timestamp request zero
        require(block.timestamp - changeRequests[address(0)].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[address(0)].newAddressRequested != address(0)); // dev: Address zero
        require(changeRequests[address(0)].newAddressRequested == newPool); // dev: Address not requested

        changeRequests[address(0)].changeRequested = false;
        changeRequests[address(0)].newAddressRequested = address(0);
        changeRequests[address(0)].timestampRequest = type(uint64).max;

        _addPool(newPool);
    }

    /// @notice Removes a liquitidty pool from the oracle. Timelock 7 days.
    function removePool(address pool) external onlyOwner {
        require(changeRequests[pool].changeRequested); // dev: Not requested
        require(changeRequests[pool].timestampRequest != 0); // dev: Timestamp request zero
        require(block.timestamp - changeRequests[pool].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[pool].newAddressRequested == address(0)); // dev: New address not zero

        changeRequests[pool].changeRequested = false;
        changeRequests[pool].newAddressRequested = pool;
        changeRequests[pool].timestampRequest = type(uint64).max;

        _removePool(pool);
    }


    /// @dev Register a request to migrate a pool. The owner must
    /// register a changeAddress request 7 days prior to execute
    /// the migration request.
    /// This function can only be called from a valid pool
    /// contract. It is called from the requestMigration()
    /// function. 
    function requestMigratePool(address newPool) external onlyPool {
        require(!isAnyPoolMigrating);
        require(!isMigratingPool[msg.sender]);
        require(isPool[newPool]);
        require(changeRequests[msg.sender].changeRequested); // dev: Not requested
        require(changeRequests[msg.sender].timestampRequest != 0); // dev: Timestamp request zero
        require(block.timestamp - changeRequests[msg.sender].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[msg.sender].newAddressRequested != msg.sender); // dev: Same address
        require(changeRequests[msg.sender].newAddressRequested == newPool); // dev: Address not requested

        changeRequests[msg.sender].changeRequested = false;
        changeRequests[msg.sender].newAddressRequested = msg.sender;
        changeRequests[msg.sender].timestampRequest = type(uint64).max;

        isAnyPoolMigrating = true;
        isMigratingPool[msg.sender] = true;
    }

    /// @dev Notifies the oracle that the pool migration
    /// has been done and removes the pool from the list of pools.
    function setMigrationDone() external onlyPool {
        require(isAnyPoolMigrating);
        require(isMigratingPool[msg.sender]);

        isAnyPoolMigrating = false;
        isMigratingPool[msg.sender] = false;
        _removePool(msg.sender);
    }

    /// @dev Cancels a requested pool migration
    function cancelMigration() external onlyPool {
        isAnyPoolMigrating = false;
        isMigratingPool[msg.sender] = false;
    }


    /// @dev Register a request to remove a pool.
    /// This function can only be called from a valid pool
    /// contract. It is called from the requestRemove()
    /// function. 
    function requestRemovePool() external onlyPool {
        require(!isAnyPoolRemoving);
        require(!isRemovingPool[msg.sender]);
        require(changeRequests[msg.sender].changeRequested); // dev: Not requested
        require(changeRequests[msg.sender].timestampRequest != 0); // dev: Timestamp request zero
        require(block.timestamp - changeRequests[msg.sender].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[msg.sender].newAddressRequested != msg.sender); // dev: Same address
        require(changeRequests[msg.sender].newAddressRequested == address(0)); // dev: Address not requested

        changeRequests[msg.sender].changeRequested = false;
        changeRequests[msg.sender].newAddressRequested = msg.sender;
        changeRequests[msg.sender].timestampRequest = type(uint64).max;

        isAnyPoolRemoving = true;
        isRemovingPool[msg.sender] = true;
    }

    /// @notice Notifies the oracle that the pool removal
    /// has been done and removes the pool from the list of pools.
    function setRemoveDone() external onlyPool {
        require(isAnyPoolRemoving);
        require(isRemovingPool[msg.sender]);

        isAnyPoolRemoving = false;
        isRemovingPool[msg.sender] = false;
        _removePool(msg.sender);
    }

    /// @notice Cancels a requested pool migration
    function cancelRemove() external onlyPool {
        isAnyPoolRemoving = false;
        isRemovingPool[msg.sender] = false;
    }


    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                         MINTER MIGRATION                           +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Register a request to migrate the stablecoin minter. The owner must
    /// register a changeAddress request 7 days prior to execute
    /// the migration request.
    function requestMigrateMinter(address newMinter_) external onlyMinter {
        require(!isMigratingMinter);
        require(changeRequests[scMinter].changeRequested); // dev: Not requested
        require(changeRequests[scMinter].timestampRequest != 0); // dev: Timestamp request zero
        require(block.timestamp - changeRequests[scMinter].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[scMinter].newAddressRequested != scMinter); // dev: Same address
        require(changeRequests[scMinter].newAddressRequested == newMinter_); // dev: Address not requested

        changeRequests[scMinter].changeRequested = false;
        changeRequests[scMinter].newAddressRequested = scMinter;
        changeRequests[scMinter].timestampRequest = type(uint64).max;

        isMigratingMinter = true;
        newMinter = newMinter_;
    }

    /// @dev Notifies the oracle that the minter migration
    /// has been done and sets the new stablecoin minter.
    function setMinterMigrationDone() external onlyMinter {
        require(isMigratingMinter);

        scMinter = newMinter;
        ageSCMinter = uint64(block.timestamp);
        isMigratingMinter = false;
    }

    /// @notice Cancels a requested stablecoin minter migration
    function cancelMinterMigration() external onlyMinter {
        isMigratingMinter = false;
        newMinter = address(0);
    }


    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                     INFORMATIVE FUNCTIONS                          +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    /// @dev All pools must be initialized or this function will revert
    function getTotalCollatValue() public view returns(uint256 totalValue) {
        for (uint16 i=0; i<pools.length; i++)
            totalValue += IGenesisLiquidityPool(pools[i]).getCollateralValue();
        return totalValue;
    }

    /// @dev All pools must be initialized or this function will revert. Uses 18 decimals.
    function getPoolCollatWeight(address pool) public view returns(uint256 weight) {
        require(isPool[pool]); // dev: address is not pool
        
        uint256 totalValue = getTotalCollatValue();
        if (totalValue == 0)
            weight = uint256(IGenesisLiquidityPool(pool).poolWeight()) * 1e15;
        else
            weight = (IGenesisLiquidityPool(pool).getCollateralValue() * 1e18) / totalValue;
        
        return weight;
    }
    

    /// @dev All pools must be initialized or this function will revert
    function getSafePrice() public view returns(uint256) {
        uint256 wprice;
        uint256 weight;
        for (uint16 i=0; i<pools.length; i++) {
            weight = getPoolCollatWeight(pools[i]);
            wprice += (IGenesisLiquidityPool(pools[i]).meanPrice() * weight)/1e18;
        }
        return wprice;
    }

    function getLastPrice() public view returns(uint256) {
        uint256 price;
        for (uint16 i=0; i<pools.length; i++) 
            price += IGenesisLiquidityPool(pools[i]).lastPrice();
        
        return price / pools.length;
    }

    function getMeanVolume() public view returns(uint256) {
        uint256 volume;
        for (uint16 i=0; i<pools.length; i++) 
            volume += IGenesisLiquidityPool(pools[i]).meanVolume();
        
        return volume / pools.length;
    }

    function getLastVolume() public view returns(uint256) {
        uint256 volume;
        for (uint16 i=0; i<pools.length; i++) 
            volume += IGenesisLiquidityPool(pools[i]).lastVolume();
        
        return volume / pools.length;
    }
    
    function getTotalMintedGEX() public view returns(uint256) {
        int256 totalSupply;
        for (uint16 i=0; i<pools.length; i++)
            totalSupply += IGenesisLiquidityPool(pools[i]).mintedGEX();
        
        totalSupply += int256(getExternalMintedGEX());
        return totalSupply < 0 ? 0 : uint256(totalSupply);
    }

    /// @notice Gets the amount of GEX minted in the other blockchains
    function getExternalMintedGEX() public view returns(uint256) {
        if(bridge == address(0))
            return 0;
        else
            return IGeminonBridge(bridge).externalTotalSupply();
    }

    function getLockedAmountGEX() public view returns(uint256) {
        require(scMinter != address(0)); // dev: scMinter not set
        return ISCMinter(scMinter).getBalanceGEX();
    }

    function getHighestGEXPool() public view returns(address maxAddress) {
        uint256 balance;
        uint256 maxBalance;
        for (uint16 i=0; i<pools.length; i++) {
            balance = IGenesisLiquidityPool(pools[i]).balanceGEX();
            if (balance > maxBalance) {
                maxBalance = balance;
                maxAddress = address(pools[i]);
            }
        }
        return maxAddress;
    }


    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                        INTERNAL FUNCTIONS                          +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Adds a new liquitidty pool to the oracle
    function _addPool(address newPool) private {
        require(newPool != address(0));
        pools.push(newPool);
        isPool[newPool] = true;
        poolAge[newPool] = uint64(block.timestamp);
    }

    /// @dev Removes a liquitidty pool from the oracle
    function _removePool(address pool) private {
        require(isPool[pool]);
        uint16 numPools = uint16(pools.length);
        
        for (uint16 i; i < numPools; i++) {
            if (pools[i] == pool) {
                pools[i] = pools[numPools - 1];
                pools.pop();
                break;
            }
        }
        isPool[pool] = false;
        poolAge[pool] = type(uint64).max;
    }
}