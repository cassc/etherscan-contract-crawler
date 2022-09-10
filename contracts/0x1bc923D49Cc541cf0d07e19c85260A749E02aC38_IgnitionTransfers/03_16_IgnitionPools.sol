// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./IgnitionAccess.sol";

// First 2 are moon and galaxy which are the standard pools on every IDO
// the other ones are any other pools that needs to be added to the IDO

/**
* @title IGNITION Pools Contract
* @author Luis Sanchez / Alfredo Lopez: PAID Network 2021.4
*/
contract IgnitionPools is IgnitionAccess {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LibPool for LibPool.PoolTokenModel;

    event LogPoolToken(
        address indexed baseAsset,
        uint8 indexed pool,
        address admin,
        address quoteAsset,
        address indexed pplSuppAsset,
        uint256 startDate,
        uint256 endDate,
        uint256 rate,
        uint256 baseTier,
        uint256 pplAmount,
        uint256 sndAmount,
        uint256 tokenTotalAmount, // Total of Token in the pool
        uint256 maxRaiseAmount // Max Amount of (ETH/USDT/USDC) to Raise
    );

    event LogRatePool(
        address indexed baseAsset,
        uint8 indexed pool,
        uint256 oldRate,
        uint256 newRate
    );

    event LogBaseTier(
        address indexed baseAsset,
        uint8 pool,
        uint256 newbaseTier
    );

    event LogStartDatePool(
        address indexed baseAsset,
        uint8 indexed pool,
        uint256 oldStartDate,
        uint256 newStartDate
    );

    event LogEndDatePool(
        address indexed baseAsset,
        uint8 indexed pool,
        uint256 oldEndDate,
        uint256 newEndDate
    );

    event LogPausePool(
        address indexed baseAsset,
        uint8 indexed pool,
        bool indexed isPaused
    );

    event LogTokenTotalAmount(
        address indexed baseAsset,
        uint8 indexed pool,
        uint256 oldTotalAmount,
        uint256 newTotalAmount
    );

    event LogPrivAndAutoTxPool(
        address indexed baseAsset,
        uint8 indexed pool,
        address indexed quoteAsset,
        bool privatePool,
        bool autoTranfer,
        uint256 maxRaiseAmount // Max Amount of (ETH/USDT/USDC) to Raise
    );

    event LogQuoteAsset(
        address indexed baseAsset,
        uint8 indexed pool,
        address indexed quoteAsset,
        uint8 quoteAssetDecimals,
        address admin,
        uint256 rate,
        uint256 tokenTotalAmount, // Total of Token in the pool
        uint256 maxRaiseAmount // Max Amount of (ETH/USDT/USDC) to Raise
    );

    event LogDisablePool(
        address indexed baseAsset,
        uint8 indexed pool,
        address quoteAsset,
        address indexed admin,
        uint256 soldAmount, // Tokens Sold
        uint256 tokenTotalAmount, // Total of Token in the pool
        uint256 totalRaise // Total of (ETH/USDT/USDC, etc) Raised
    );    

    mapping(address => mapping(uint8 => uint256)) private _timepaused;

    /**
     * Add CrownSale Pool Token
     *
     * @dev Only Admin
     * @dev Error IGN22 - Token Pool Exist
     * @dev Error IGN26 - Must be set Secondary Project Token Amount more than Zero
     * @dev Error IGN27 - Don't support the Value
     * @dev Error IGN47 - Unsuported address
     * @dev Error IGN49 - Start Date must be after current time and before end date
     * @param _address[0] {address _baseAsset},
     * @param _address[1] {address _quoteAsset} Address of the QuoteAsset of Pool
     * @param _address[2] {address _pplSuppAsset} Main token adddress to hold (eg PAID)
     * @param _address[3] {address _sndSuppAsset} Optional token address to hold
     * @param _args[0] {uint256 _startDate} Start Date of Pool
     * @param _args[1] {uint256 _endDate}End Date of Pool
     * @param _args[2] {uint256 _pool} Pool into the IDO (CrownSale)
     * @param _args[3] {uint256 _rate} rate based on QuoteAsset used in the Pool
     * @param _args[4] {uint256 _baseTier} floor or base of the Tier Structure in the Pool
     * @param _args[5] {uint256 _pplAmount} Principal Support Project Amount Limit for Participate in the Pool
     * @param _args[6] {uint256 _sndAmount} Secondary Support Project Amount Limit for Participate in the Pool
     * @param _args[7] {uint256 _tokenTotalAmount},
     * @param _args[8] {uint256 _maxRaiseAmount},
     * @param _args[9] {uint256(boolean)}: Private Pool active/inactive
     * @param _args[10] {uint256(boolean)}: Auto Transfer Active / Inactive in the Pool
     * @param _args[11] {uint256 _baseAssetDecimals} Decimals Presicion for Base Asset
     * @param _args[12] {uint256 _QuoteAssetDecimals} Decimals Presicion for Quote Asset
     * @param _args[13] {uint256 _pplSuppAssetDecimals} Decimals Presicion for Pricipal Support Asset
     * @param _args[14] {uint256 _sndSuppAsset Decimals} Decimals Presicion for Secondary Support Asset
     */
    function addTokenToPool(address[4] calldata _address, uint256[15] calldata _args)
    external virtual whenNotPaused {
        require(
            _address[0] != address(0) &&
            _address[2] != address(0), "IGN47"
        );
        _isAdmin(_address[0]);
        require(!poolTokens[_address[0]][uint8(_args[2])].valid, "IGN22");
        require(
            block.timestamp < _args[0] &&
            _args[0] < _args[1],
            "IGN49"
        );
        require(_args[7] > uint(0), "IGN51");

        uint256 _packageData = LibPool.generatePackage(_address[0], _args);

        // Verify Secondary Project Token Amount not Zero, when the Secondary Project token 
        // address is different address(0)
        if (_address[3] != address(0)) {
            require(_args[6] > uint(0), "IGN26");
        }

        // Add mapping for ERC20 Decimals
        for (uint256 i = 0; i < 4; i++) {
            require(_args[11+i] <= uint(18), "IGN27");
            if (!erc20Decimals[_address[i]].active) {
                erc20Decimals[_address[i]].active = true;
                erc20Decimals[_address[i]].decimals = _args[11+i];
            }
        }

        uint256 _pplAmount = _args[5] /
            LibPool.getDecimals(erc20Decimals[_address[2]].decimals);

        uint256 _sndAmount = _args[6] /
            LibPool.getDecimals(erc20Decimals[_address[3]].decimals);

        uint256 _tokenTotalAmount = _args[7] /
            LibPool.getDecimals(erc20Decimals[_address[0]].decimals);

        uint256 _maxRaiseAmount = _args[8] /
            LibPool.getDecimals(erc20Decimals[_address[1]].decimals);

        fallBacks[_address[0]][uint8(_args[2])] = LibPool.FallBackModel({
            fbck_finalize: 0,
            fbck_endDate: 0,
            fbck_account: address(0)
        });

        poolTokens[_address[0]][uint8(_args[2])] = LibPool.PoolTokenModel({
            valid: true,
            quoteAsset: _address[1],
            pplSuppAsset: _address[2],
            sndSuppAsset: _address[3],
            packageData: _packageData,
            rate: _args[3],
            baseTier: _args[4],
            pplAmount: _pplAmount,
            sndAmount: _sndAmount,
            soldAmount: 0,
            tokenTotalAmount: _tokenTotalAmount,
            totalRaise: 0,
            maxRaiseAmount: _maxRaiseAmount
        });

        emit LogPoolToken(
            _address[0],
            uint8(_args[2]),
            idoManagers[_address[0]],
            _address[1],
            _address[2],
            _args[0],
            _args[1],
            _args[3],
            _args[4],
            _pplAmount,
            _sndAmount,
            _tokenTotalAmount,
            _maxRaiseAmount
        );
    }

    /**
    * @notice Set Rate for the collateral in the pool    *
    * 1 QuoteAsset (e.g. ETH/WETH/USDC/USDT) = ?  BaseAsset Token
    * Example: 1 Ether = 30 Token
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @param _rate Rate of the Token According with the Coin Used in the CrowdSale
    */
    function setRate(uint8 _pool, address _poolAddr, uint256 _rate)
    external virtual whenNotPaused isAdmin(_poolAddr) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];
        require(pt.valid == true, "IGN38");

        uint256 oldRate = pt.rate;
        pt.rate = _rate;
        emit LogRatePool(_poolAddr, _pool, oldRate, _rate);
    }

    /**
    * change Base Tier
    * @notice Method to change to the Base Tier and Paid Amount of the Pool
    * @dev Only Owner or Project Owner
    * @dev Error IGN27 - Don't support the Value
    * @dev Error IGN28 - Pool Token Sale has already started
    * @dev Error IGN29 - Must be set Secondary Project Token Amount more than Zero
    * @dev Error IGN47 - Unsuported address
    * @dev Error IGN48 - _pplAmount must be greater than zero
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @param _baseTier Tier 1
    * @param _ppalAddress Main support address asset
    * @param _sndAddresss Secondary support address asset
    * @param _pplAmount Main amount need to be holding
    * @param _sndAmount Secondary amount need to be holding
    * @param _decimalsPpl Main decimals on holding asset
    * @param _decimalsSnd Secondary decimals on holding asset
    */
    function setBaseTier(
        uint8 _pool,
        address _poolAddr,
        uint256 _baseTier,
        address _ppalAddress,
        address _sndAddresss,
        uint256 _pplAmount,
        uint256 _sndAmount,
        uint256 _decimalsPpl,
        uint256 _decimalsSnd
    ) external virtual whenNotPaused isAdmin(_poolAddr) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];

        require(block.timestamp < pt.getStartDate(), "IGN28");
        require(_ppalAddress != address(0), "IGN47");
        require(_decimalsPpl <= uint(18), "IGN27");

        if (!erc20Decimals[_ppalAddress].active) {
            erc20Decimals[_ppalAddress].active = true;
            erc20Decimals[_ppalAddress].decimals = _decimalsPpl;
        }

        if (_sndAddresss != address(0)) {
            require(_decimalsSnd <= uint(18), "IGN27");

            if (!erc20Decimals[_sndAddresss].active) {
                erc20Decimals[_sndAddresss].active = true;
                erc20Decimals[_sndAddresss].decimals = _decimalsSnd;
            }
        }

        pt.baseTier = _baseTier;
        pt.pplSuppAsset = _ppalAddress;
        pt.sndSuppAsset = _sndAddresss;
        pt.pplAmount = _pplAmount / LibPool.getDecimals(_decimalsPpl);
        pt.sndAmount = _sndAmount / LibPool.getDecimals(_decimalsSnd);

        emit LogBaseTier(_poolAddr, _pool, _baseTier);
    }

    /**
    * change Start Date of Pool
    *
    * @dev Only Owner or Project Owner
    * @dev Error IGN30 - Pool Token Sale has already started
    * @dev Error IGN49 - Start Date must be after current time and before end date
    * @notice Method to change to the Start of the Pool
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @param _newStartDate New start date
    */
    function setStartDate(uint8 _pool, address _poolAddr, uint256 _newStartDate)
    external virtual isAdmin(_poolAddr) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];

        // require(block.timestamp < pt.getStartDate(), "IGN30");
        require(
            block.timestamp < _newStartDate && _newStartDate < pt.getEndDate(),
            "IGN49"
        );

        uint256 oldDate = uint256(uint32(pt.packageData>>160));

        pt.setStartDate(_newStartDate, STATUS_BOOLEAN);

        emit LogStartDatePool(_poolAddr, _pool, oldDate, _newStartDate);
    }

    /**
    * @notice change End Date of Pool
    * @dev Only Owner or Project Owner
    * @dev Error IGN31 - Pool Token Sale End
    * @dev Error IGN50 - End Date must be after current time and Start Date
    * @notice Method to change to the EndDate of the Pool
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @param _newEndDate New end date
    */
    function setEndDate(uint8 _pool, address _poolAddr, uint256 _newEndDate)
    external virtual isAdmin(_poolAddr) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];

        // require(block.timestamp < pt.getEndDate(), "IGN31");
        require(
            block.timestamp <= _newEndDate && pt.getStartDate() < _newEndDate,
            "IGN50"
        );

        uint256 _packageData = pt.packageData;
        uint256 oldDate = uint256(uint32(_packageData>>192));

        pt.setEndDate(_newEndDate, STATUS_BOOLEAN);

        emit LogEndDatePool(_poolAddr, _pool, oldDate, _newEndDate);
    }

    /**
    * Paused of Pool
    * @dev Error IGN32 - Sale isn't active
    * @dev Only Owner
    * @notice Method to paused the Pool in any moment and the time paused is addition to the EndDate of the Pool
    * @param _pool Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    */
    function pausePool(uint8 _pool, address _poolAddr)
    external virtual isAdmin(_poolAddr) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];

        require(pt.isActive(), "IGN32");
        if (!pt.isPaused()) {
            _timepaused[_poolAddr][_pool] = block.timestamp;
            // paused = true
            poolTokens[_poolAddr][_pool].packageData = poolTokens[_poolAddr][_pool].packageData | (uint256(1)<<234);
            emit LogPausePool(_poolAddr, _pool, true);
        }
    }

    /**
    * Unpaused of Pool
    *
    * @dev Only Owner
    * @notice Method to unpaused the Pool in any moment and the time paused is addition to the EndDate of the Pool
    * @param _pool number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    */
    function unPausePool(uint8 _pool, address _poolAddr)
    external virtual isAdmin(_poolAddr) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];

        uint256 endDate = pt.getEndDate();
        if (pt.isPaused()) {
            endDate = endDate + block.timestamp - _timepaused[_poolAddr][_pool];
            pt.setEndDate(endDate, STATUS_BOOLEAN);
            // paused = false
            pt.packageData = pt.packageData & ~(uint256(1)<<234);
            emit LogPausePool(_poolAddr, _pool, false);
        }
    }

    /**
    * Change Total Amount of the BaseAsset Token in this Pool
    *
    * @dev Only Owner
    * @dev Error IGN33 - Pool Token Sale has already started or Finalized
    * @dev Error IGN51 - totalAmount can't be zero
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @param _newTotalAmount the new Total Amount of the BaseAsset Token in this Pool
    */
    function setTokenTotalAmount(
        uint8 _pool,
        address _poolAddr,
        uint256 _newTotalAmount
    ) external virtual whenNotPaused isAdmin(_poolAddr) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];

        // require(block.timestamp < pt.getStartDate(), "IGN33");
        require(_newTotalAmount > uint(0), "IGN51");

        uint256 oldTotalAmount = pt.tokenTotalAmount;

        pt.tokenTotalAmount = _newTotalAmount /
            LibPool.getDecimals(erc20Decimals[_poolAddr].decimals);

        emit LogTokenTotalAmount(_poolAddr, _pool, oldTotalAmount, _newTotalAmount);
    }

    /**
    * Arbitrary Manual Transfer Poll
    *
    * @dev Only Owner
    * @dev Error IGN35 - Pool Token Sale Origin has auto transfer pool actived
    * @dev Error IGN36 - Out of window for the Transfer
    * @dev Error IGN37 - Tokens of the Pool Origin was Withdrawn or moved to another Pool
    * @param _poolAddr The Token Address of the IDO
    * @param _frompool Pool Origin for Transfer the BaseAsset Token
    * @param _topool  Pool Destination for Transfer the BaseAsset Token
    */
    function transferPool(address _poolAddr, uint8 _frompool, uint8 _topool)
    external virtual isAdmin(_poolAddr) {
        LibPool.PoolTokenModel storage toPool = poolTokens[_poolAddr][_topool];
        LibPool.PoolTokenModel storage fromPool = poolTokens[_poolAddr][_frompool];

        toPool.poolIsValid();
        require(!fromPool.isAutoTransfer(), "IGN35");
        require(fromPool.tokenTotalAmount != uint(0), "IGN37");

        uint256 substrate = fromPool.tokenTotalAmount - fromPool.soldAmount;
        uint256 oldAmount = toPool.tokenTotalAmount;
        // isFinalized = true;
        fromPool.packageData = fromPool.packageData | (uint256(1)<<233);
        toPool.tokenTotalAmount = toPool.tokenTotalAmount + substrate;
        fromPool.tokenTotalAmount = fromPool.tokenTotalAmount - substrate;

        emit LogTokenTotalAmount(
            _poolAddr,
            _topool,
            oldAmount,
            toPool.tokenTotalAmount);
    }

    /**
    * @notice Setter for Enable te Private Pool
    * @notice Enable the Private Pool status after tho Add the Pool in the Smart Contract
    * @dev Only Owner can activate and only when the All Smart Contract is NOT Paused()
    * @dev Error IGN44 - Pool Token Sale has already started
    * @dev Error IGN45 - Max Raise Amount must not be Zero
    * @dev Error IGN23 - Must be set Max Raised Amount more than Zero to enable Private Pool
    * @param _pool Id of the pool (is important to clarify this number must be order by 
    * priority for handle the Auto Transfer function)
    * @param _poolAddr Address of the BaseAsset, and Index of the Mapping in the Smart Contract
    * @param _enablePrivatePool Value True or False for enable or disable the Private Pool 
    * feature in this Pool of the IDO
    * @param _enableAutoTx Value True or False for enable or disable the AutoTx Pool feature in this Pool of the IDO
    * @param _maxRaiseAmount Max Total Amount permitted (this value apply for Private Pool)
    */
    function setPrivAndAutoTxPool(
        uint8 _pool,
        address _poolAddr,
        bool _enablePrivatePool,
        bool _enableAutoTx,
        uint256 _maxRaiseAmount
    ) external virtual isAdmin(_poolAddr) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];

        require(block.timestamp < pt.getStartDate(), "IGN44");
        require(!(_enablePrivatePool && _maxRaiseAmount == uint(0)), "IGN45");

        pt.setPrivatePool(_enablePrivatePool);
        pt.setAutoFix(_enableAutoTx);
        pt.maxRaiseAmount = _maxRaiseAmount;

        emit LogPrivAndAutoTxPool(
            _poolAddr,
            _pool,
            pt.quoteAsset,
            _enablePrivatePool,
            _enableAutoTx,
            _maxRaiseAmount
        );
    }

    /**
    * @notice Set the Address for the Quote Asset
    * @notice in owner case have different option like e.g. USDT, USDC, DAI, BUSD, etc) and inclusive Wrapper ETH WETH
    * Set the Address of the ERC20 stable Coin or address(0) or "0x0000000000000000000000000000000000000000", for ETH
    * @dev Only Owner
    * @dev Error IGN46 - Don't support the Value
    * @dev Error IGN47 - Unsuported address
    * @param _pool Id of the pool (is important to clarify this number must be order 
    * by priority for handle the Auto Transfer function)
    * @param _poolAddr Address of the BaseAsset, and Index of the Mapping in the Smart Contract
    * @param _quoteAsset token ERC20 stable coin or wrapper ERC20, for but tokens in the CrownSale 
    * of the Pool in the IDO
    * @param _decimals Decimals precision for token
    */
    function setQuoteAsset(
        uint8 _pool,
        address _poolAddr,
        address _quoteAsset,
        uint8 _decimals
    ) external virtual isAdmin(_poolAddr) {
        require(_decimals <= uint(18), "IGN46");
        require(_quoteAsset != address(0), "IGN47");

        if (erc20Decimals[_quoteAsset].active) {
            erc20Decimals[_quoteAsset].decimals = _decimals;
        } else {
            erc20Decimals[_quoteAsset].active = true;
            erc20Decimals[_quoteAsset].decimals = _decimals;
        }

        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];
        require(pt.valid == true, "IGN38");

        pt.quoteAsset = _quoteAsset;

        emit LogQuoteAsset(
            _poolAddr,
            _pool,
            _quoteAsset,
            _decimals,
            idoManagers[_poolAddr],
            pt.rate,
            pt.tokenTotalAmount,
            pt.maxRaiseAmount
        );
    }

    /**
    * Disable of Pool Token
    *
    * @dev Only Admin
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    */
    function disablePool(uint8 _pool, address _poolAddr)
    external virtual isAdmin(_poolAddr) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];

        pt.valid = false;
        emit LogDisablePool(
            _poolAddr,
            _pool,
            pt.quoteAsset,
            idoManagers[_poolAddr],
            pt.soldAmount,
            pt.tokenTotalAmount,
            pt.totalRaise
        );
    }

    /**
    * @notice External function to get the Start Date of the Pool
    * @param _pool Id of the pool (is important to clarify this number must be order by
    * priority for handle the Auto Transfer function)
    * @param _poolAddr Address of the BaseAsset, and Index of the Mapping in the Smart Contract
    * @return Start Date of the Pool in Epoch Format
    */
    function getStartDate (uint8 _pool, address _poolAddr)
    external virtual view returns (uint256) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];
        pt.poolIsValid();
        return pt.getStartDate();
    }

    /**
    * @notice External function to get the End Date of the Pool
    * @param _pool Id of the pool (is important to clarify this number must be order by 
    * priority for handle the Auto Transfer function)
    * @param _poolAddr Address of the BaseAsset, and Index of the Mapping in the Smart Contract
    * @return End Date of the Pool in Epoch Format
    */
    function getEndDate (uint8 _pool, address _poolAddr)
    external virtual view returns (uint256) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];
        pt.poolIsValid();
        return pt.getEndDate();
    }

    /**
    * @notice External function to check if the Crowd Sale has already been started or not
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @return a boolean value according to the state of the Crowd Sale
    */
    function isActive(uint8 _pool, address _poolAddr) external virtual view returns (bool) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];
        pt.poolIsValid();
        return pt.isActive();
    }

    /**
    * @notice External function to check if the pool is paused
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @return a boolean value according to the state of the Crowd Sale
    */
    function isPoolPaused(uint8 _pool, address _poolAddr) external virtual view returns (bool) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];
        pt.poolIsValid();
        return pt.isPaused();
    }

    /**
    * @notice External function to check if the pool is Withdrawed
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @return a boolean value according to the state of the Crowd Sale
    */
    function isPoolWithdrawed(uint8 _pool, address _poolAddr) external virtual view returns (bool) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];
        pt.poolIsValid();
        return pt.isWithdrawed();
    }

    /**
    * @notice External function to check if the pool is finalized
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @return a boolean value according to the state of the Crowd Sale
    */
    function isPoolFinalized(uint8 _pool, address _poolAddr) external virtual view returns (bool) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];
        pt.poolIsValid();
        return pt.isFinalized();
    }

     /**
    * @notice External function to check if the pool is private
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @return a boolean value according to the state of the Crowd Sale
    */
    function isPoolPrivate(uint8 _pool, address _poolAddr) external virtual view returns (bool) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];
        pt.poolIsValid();
        return pt.isPrivPool();
    }

    /**
    * @notice External function to check if the pool is set to auto transfer
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @return a boolean value according to the state of the Crowd Sale
    */
    function isPoolAutoTransfer(uint8 _pool, address _poolAddr) external virtual view returns (bool) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];
        pt.poolIsValid();
        return pt.isAutoTransfer();
    }
}