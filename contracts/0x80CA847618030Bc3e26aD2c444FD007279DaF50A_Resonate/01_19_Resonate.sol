// SPDX-License-Identifier: GNU-GPL

pragma solidity >=0.8.0;

import "./interfaces/IERC4626.sol";
import "./interfaces/IRevest.sol";
import "./interfaces/IFNFTHandler.sol";
import "./interfaces/IAddressRegistry.sol";
import "./interfaces/IPriceProvider.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IResonate.sol";
import "./interfaces/ISmartWalletWhitelistV2.sol";

import "./interfaces/ISmartWallet.sol";
import "./interfaces/IPoolWallet.sol";
import "./interfaces/IResonateHelper.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@rari-capital/solmate/src/utils/Bytes32AddressLib.sol";

/** @title Resonate
 * @author RobAnon
 * @author 0xTraub
 * @author 0xTinder
 */
contract Resonate is IResonate, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using Bytes32AddressLib for address;
    using Bytes32Conversion for bytes32;

    ///
    /// Coefficients and Variable Declarations
    ///

    /// Precision for calculating rates
    uint private constant PRECISION = 1 ether;

    /// Denominator for fee calculations
    uint private constant DENOM = 100;

    /// Minimum deposit
    uint private constant MIN_DEPOSIT = 1E3;

    // uint32, address, address, address pack together to 64 bytes

    /// Minimum lockup period
    uint32 private constant MIN_LOCKUP = 1 days;

    /// The address to which fees are paid
    address private immutable DEV_ADDRESS;

    /// The Revest Address Registry
    address public immutable REGISTRY_ADDRESS;

    /// The OutputReceiver Proxy Address
    address public immutable PROXY_OUTPUT_RECEIVER;

    /// The fee numerator 
    uint32 private constant FEE = 5;

    /// The AddressLock Proxy Address
    address public immutable PROXY_ADDRESS_LOCK;

    /// The ResonateHelper address
    address public immutable override RESONATE_HELPER;

    /// The owner
    address public owner;

    /// Maps yield-farm address to adapter address
    mapping(address => address) public override vaultAdapters;

    /// Maps fnftIds to their relevant index
    mapping(uint => uint) public fnftIdToIndex;

    /// Contains all activated orders 
    mapping (uint => Active) public override activated;

    /// Mapping to residual interest for an interest-bearing FNFT
    mapping(uint => uint) public override residuals;

    /// Map poolIds to their respective configs
    mapping(bytes32 => PoolConfig) public override pools;

    /// Provider queue
    mapping(bytes32 => mapping(uint => Order)) public override providerQueue;

    /// Consumer queue
    mapping(bytes32 => mapping(uint => Order)) public override consumerQueue;

    /// Queue tracker mapping
    mapping(bytes32 => PoolQueue) public override queueMarkers;

    /// Maps contract address to assets it has approval to spend from this contract
    mapping (address => mapping (address => bool)) private _approvedContracts;

    /// The FNFTHandler address, immutable for increased decentralization
    IFNFTHandler private immutable FNFT_HANDLER;

    /// The SmartWalletWhitelist contract to control access
    ISmartWalletWhitelistV2 private immutable SMART_WALLET_WHITELIST;

    /// Oracle Tracker
    IPriceProvider private immutable PRICE_PROVIDER;

    /**
     * @notice the constructor for Resonate
     * @param _router the Revest AddressRegistry contract address
     * @param _proxyOutputReceiver the OutputReceiver proxy address to use for Resonate. 
     * @param _proxyAddressLock the AddressLock proxy address to use for Resonate. 
     * @param _resonateHelper the ResonateHelper address
     * @dev This should be called after the above three contracts have been deployed
     */
    constructor(
        address _router, 
        address _proxyOutputReceiver, 
        address _proxyAddressLock, 
        address _resonateHelper,
        address _smartWalletWhitelist,
        address _priceProvider,
        address _dev_address
    ) {
        require(
            _router != address(0) && 
            _proxyOutputReceiver != address(0) && 
            _proxyAddressLock != address(0) && 
            _resonateHelper != address(0) && 
            _smartWalletWhitelist != address(0) &&
            _priceProvider != address(0) &&
            _dev_address != address(0),
        'ER003');

        REGISTRY_ADDRESS = _router;

        PROXY_OUTPUT_RECEIVER = _proxyOutputReceiver;
        PROXY_ADDRESS_LOCK = _proxyAddressLock;
        RESONATE_HELPER = _resonateHelper;
        DEV_ADDRESS = _dev_address;
        FNFT_HANDLER = IFNFTHandler(IAddressRegistry(_router).getRevestFNFT());
        SMART_WALLET_WHITELIST = ISmartWalletWhitelistV2(_smartWalletWhitelist);
        PRICE_PROVIDER = IPriceProvider(_priceProvider);  

        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "ER024");
        _;
    }

    ///
    /// Transactional Functions
    ///

    /** 
     * @notice Creates a pool, only if it does not already exist
     * @param asset The payment asset for this pool. An oracle must exist if it is different than vaultAsset
     * @param vault The Vault to use. Should be the raw vault, not the adapter. If 4626, use the 4626 here
     * @param rate The upfront payout rate, in 1E18 precision
     * @param additionalRate The amount to add to the upfront rate to get the expected interest if fixed-income. Zero otherwise
     * @param lockupPeriod The amount of time the principal will be locked for if fixed-term. Zero otherwise
     * @param packetSize The standardized size of a single packet. Often measured in thousandths of a token
     * @param poolName The name of the pool. Will not be stored, only needed for Frontend display
     * @return poolId The poolId that the above parameters result in
     * @dev Cross-asset pools have more pre-conditions than others. This function will not deposit anything and follow-up operations are needed
     */
    function createPool(
        address asset,
        address vault, 
        uint128 rate,
        uint128 additionalRate,
        uint32 lockupPeriod, 
        uint packetSize,
        string calldata poolName
    ) external nonReentrant returns (bytes32 poolId) {
        address vaultAsset;
        {
            address adapter = vaultAdapters[vault];
            require(adapter != address(0), 'ER001');
            require(asset != address(0), 'ER001');
            require(packetSize > 0, 'ER023');
            require((lockupPeriod >= MIN_LOCKUP && additionalRate == 0) || (additionalRate > 0 && lockupPeriod == 0), 'ER008');
            vaultAsset = IERC4626(adapter).asset();
        }
        require(asset == vaultAsset || PRICE_PROVIDER.pairHasOracle(vaultAsset, asset), 'ER033');
        poolId = _initPool(asset, vault, rate, additionalRate, lockupPeriod, packetSize);
        _getWalletForPool(poolId);
        _getWalletForFNFT(poolId);
        emit PoolCreated(poolId, asset, vault, vaultAsset, rate, additionalRate, lockupPeriod, packetSize, lockupPeriod > 0 && additionalRate == 0, poolName, msg.sender);
    }

    /**
     * @notice This function allows a participant to enter a pool on the Issuer side
     * @param poolId the pool in which to enter
     * @param amount the amount of tokens to deposit to that side of the pool – will be rounded down to nearest packet
     * @dev Gas prices will be highly dependent on the presence of counter-parties on the opposite side of the pool 
     */
    function submitConsumer(bytes32 poolId, uint amount, bool shouldFarm) external nonReentrant {
        PoolConfig memory pool = pools[poolId];
        require(amount > MIN_DEPOSIT, 'ER043');
        require(amount % pool.packetSize <= 5, 'ER005'); //be within 10 gwei to handle round-offs
        require(_validRecipient(), 'ER034');
        
        bool hasCounterparty = !_isQueueEmpty(poolId, true); // 2506 gas operation
        address vaultAsset;
        address adapter = pool.adapter;
        {
            IERC4626 vault = IERC4626(adapter);
            vaultAsset = vault.asset();
        }
        Order memory consumerOrder = Order(amount / pool.packetSize, 0, msg.sender.fillLast12Bytes());
        if(hasCounterparty) {
            IPoolWallet wallet = _getWalletForPool(poolId); 
            uint currentExchange;
            if (pool.asset != vaultAsset) {
                currentExchange = PRICE_PROVIDER.getValueOfAsset(vaultAsset, pool.asset);
            }
            while(hasCounterparty && consumerOrder.packetsRemaining > 0) {
                // Pull object for counterparty at head of queue
                Order storage producerOrder = _peek(poolId, true); // Not sure if I can make this memory because of Reentrancy concerns
                if(pool.asset != vaultAsset) {
                    uint previousExchange = producerOrder.depositedShares;
                    if(currentExchange != previousExchange) { // This will almost always be true
                        uint maxPacketNumber = producerOrder.packetsRemaining * previousExchange / currentExchange; // 5
                        uint amountToRefund;
                        if(consumerOrder.packetsRemaining >= maxPacketNumber) {
                            if(currentExchange > previousExchange) {
                                // Position is partially or fully insolvent
                                amountToRefund = pool.rate * pool.packetSize / PRECISION * ((producerOrder.packetsRemaining  * currentExchange) - (maxPacketNumber * previousExchange)) / PRECISION;
                                amountToRefund /= consumerOrder.packetsRemaining;
                            } else {
                                // There will be a surplus in the position
                                amountToRefund = pool.rate * pool.packetSize / PRECISION * ((maxPacketNumber * previousExchange) - (producerOrder.packetsRemaining  * currentExchange)) / PRECISION;
                            }
                        }
                        
                        if(maxPacketNumber == 0) {
                            // Need to cancel the order because it is totally insolvent
                            // No storage update

                            amountToRefund = pool.rate * pool.packetSize * producerOrder.packetsRemaining / PRECISION * previousExchange / PRECISION;

                            address orderOwner = producerOrder.owner.toAddress();
                            _dequeue(poolId, true);
                            wallet.withdraw(amountToRefund, 0, pool.asset, orderOwner, address(0));

                            hasCounterparty = !_isQueueEmpty(poolId, true);
                            continue;
                        }
                        // Storage update
                        producerOrder.depositedShares = currentExchange;
                        producerOrder.packetsRemaining = maxPacketNumber;

                        if(amountToRefund > 0) {
                            wallet.withdraw(amountToRefund, 0, pool.asset, DEV_ADDRESS, address(0));
                            emit FeeCollection(poolId, amountToRefund);
                        }
                    }
                }
                if(producerOrder.owner.toAddress() == address(0)) {
                    // Order has previously been cancelled
                    // Dequeue and move on to next iteration
                    // No storage update
                    _dequeue(poolId, true);
                } else {
                    uint digestAmt;
                    {
                        uint consumerAmt = consumerOrder.packetsRemaining;
                        uint producerAmt = producerOrder.packetsRemaining;
                        digestAmt = producerAmt >= consumerAmt ? consumerAmt : producerAmt;
                    }
                    _activateCapital(ParamPacker(consumerOrder, producerOrder, false, pool.asset != vaultAsset, digestAmt, currentExchange, pool, adapter, poolId));
                    
                    consumerOrder.packetsRemaining -= digestAmt;
                    producerOrder.packetsRemaining -= digestAmt; 

                    amount -= (digestAmt * pool.packetSize);

                    // Handle _dequeue as needed 
                    if (producerOrder.packetsRemaining == 0) {
                        _dequeue(poolId, true);
                    }
                }
                // Check if queue is empty
                hasCounterparty = !_isQueueEmpty(poolId, true);
            }
        } 

        
        if(!hasCounterparty && consumerOrder.packetsRemaining > 0) {
            // No currently available trade, add this order to consumer queue
            _enqueue(poolId, false, shouldFarm, consumerOrder, amount, vaultAsset, adapter);
        }
    }

    /**
     * @notice Allows a participant to enter a pool on the Purchaser side
     * @param poolId The ID of the pool in which to enter
     * @param amount The amount of tokens to deposit into the pool – will be rounded down to nearest packet
     * @param shouldFarm Whether or not to deposit the asset into a farm while it is queued. Not relevant if counter-party present or cross-asset pool
     * @dev shouldFarm is included to allow protocols to choose not to dilute their own yield farms while utilizing Resonate. It does not work for cross-assets
     */
    function submitProducer(bytes32 poolId, uint amount, bool shouldFarm) external nonReentrant {
        PoolConfig memory pool = pools[poolId];
        require(amount > MIN_DEPOSIT, 'ER043');
        require(_validRecipient(), 'ER034');
        
        Order memory producerOrder;

        bool hasCounterparty = !_isQueueEmpty(poolId, false);
        address vaultAsset;
        address adapter = pool.adapter;
        uint producerPacket;
        uint sharesPerPacket;
        {
            IERC4626 vault = IERC4626(adapter);
            vaultAsset = vault.asset();
            if (vaultAsset == pool.asset) {
                sharesPerPacket = shouldFarm ? 1 : 0;
                producerPacket = pool.packetSize * pool.rate / PRECISION;
                require(amount % producerPacket < 5, 'ER006');
            } else { 
                shouldFarm = false;
                sharesPerPacket = PRICE_PROVIDER.getValueOfAsset(vaultAsset, pool.asset);
                producerPacket = pool.rate * pool.packetSize / PRECISION * sharesPerPacket / PRECISION; 
                amount = amount / producerPacket * producerPacket;
                require(amount > 0, "ER003");
            }
            // Have relocated where deposits are made, are now towards end of workflow
            producerOrder = Order(uint112(amount/ producerPacket), sharesPerPacket, msg.sender.fillLast12Bytes());
        }
        if (hasCounterparty) {
            while(hasCounterparty && producerOrder.packetsRemaining > 0) {
                // Pull object for counterparty at head of queue
                Order storage consumerOrder = _peek(poolId, false);
                // Check edge-case
                if(consumerOrder.owner.toAddress() == address(0)) {
                    // Order has previously been cancelled
                    // Dequeue and move on to next iteration
                    _dequeue(poolId, false);
                } else {
                    // Perform calculations in terms of number of packets
                    uint digestAmt;
                    {
                        uint producerAmt = producerOrder.packetsRemaining;
                        uint consumerAmt = consumerOrder.packetsRemaining;
                        digestAmt = producerAmt >= consumerAmt ? consumerAmt : producerAmt;
                    }
                    _activateCapital(
                        ParamPacker(
                            consumerOrder, 
                            producerOrder, 
                            true, 
                            vaultAsset != pool.asset, 
                            digestAmt, 
                            producerOrder.depositedShares, 
                            pool, 
                            adapter, 
                            poolId
                        )
                    );

                    consumerOrder.packetsRemaining -= digestAmt;
                    producerOrder.packetsRemaining -= digestAmt;
                    amount -= (digestAmt * producerPacket);

                    // Handle _dequeue as needed
                    if(consumerOrder.packetsRemaining == 0) {
                        _dequeue(poolId, false);
                    }
                }
                // Check if queue is empty
                hasCounterparty = !_isQueueEmpty(poolId, false);
            }
        }


        if(!hasCounterparty && producerOrder.packetsRemaining > 0) {
            // If farming is desired, deposit remaining funds to farm
            // No currently available trade, add this order to producer queue
            _enqueue(poolId, true, shouldFarm, producerOrder, amount, pool.asset, adapter);
        }
    } 

    /** 
     * @notice Allows a participant to modify an existing order in-queue. User must own the position they are attempting to modify
     * @param poolId the ID of the pool in which the order exists
     * @param amount the amount of packets to withdraw from the order - will be rounded down to nearest packet
     * @param position the position of the order within the queue
     * @param isProvider on which side of the queue the order exists --- CAN LIKELY DEPRECATE
     * @dev Allows for orders to be withdrawn early. All revenue generated if the order was farming will be passed along to Resonate
     */
    function modifyExistingOrder(bytes32 poolId, uint112 amount, uint64 position, bool isProvider) external nonReentrant {
        // This function can withdraw tokens from an existing queued order and remove that order entirely if needed
        // amount = number of packets for order
        // if amount == packets remaining then just go and null out the rest of the order
        // delete sets the owner address to zero which is an edge case handled elsewhere

        Order memory order = isProvider ? providerQueue[poolId][position] : consumerQueue[poolId][position];
        require(msg.sender == order.owner.toAddress(), "ER007");

        //State changes
        if (order.packetsRemaining == amount) {
            PoolQueue storage qm = queueMarkers[poolId]; 
            emit OrderWithdrawal(poolId, amount, true, msg.sender);

            if (isProvider) {
                if (position == qm.providerHead) {
                    qm.providerHead++;
                }
                else if (position == qm.providerTail) {
                    qm.providerTail--;
                }
                delete providerQueue[poolId][position];
            } else {
                if (position == qm.consumerHead) {
                    qm.consumerHead++;
                } else if (position == qm.consumerTail) { 
                    qm.consumerTail--;
                }
                delete consumerQueue[poolId][position];
            }
        } else {
            if (isProvider) {
                providerQueue[poolId][position].packetsRemaining -= amount;
            } else {
                consumerQueue[poolId][position].packetsRemaining -= amount;
            }
            emit OrderWithdrawal(poolId, amount, false, msg.sender);
        }

        PoolConfig memory pool = pools[poolId];

        address asset = IERC4626(pool.adapter).asset();
        
        uint amountTokens = isProvider ? amount * pool.packetSize * pool.rate / PRECISION : amount * pool.packetSize;
        bool isCrossAsset = asset != pool.asset;

        if(order.depositedShares > 0 && (!isProvider || !isCrossAsset)) {

            // If is a farming consumer OR if is a farming position on the purchaser side that is not cross-asset

            uint tokensReceived = _getWalletForPool(poolId).withdrawFromVault(
                order.depositedShares * amount / PRECISION, // Recover extra PRECISION
                address(this), 
                pool.adapter
            );
            uint fee;
            if(tokensReceived > amountTokens) {
                fee = tokensReceived - amountTokens;
                IERC20(asset).safeTransfer(DEV_ADDRESS, fee);
            }
            IERC20(asset).safeTransfer(msg.sender, tokensReceived - fee);
        } else {
            if(isCrossAsset && isProvider) {
                // Is cross-asset purchaser, non-farming
                uint producerPacket = pool.rate * pool.packetSize / PRECISION * order.depositedShares / PRECISION;      
                    _getWalletForPool(poolId).withdraw(producerPacket * amount, 0, pool.asset, msg.sender, address(0));
               
            } else {
                // Is normal non-farming purchaser or non-farming consumer
                // Provider side, just withdraw
                _getWalletForPool(poolId).withdraw(amountTokens, 0, pool.asset, msg.sender, address(0));
            }
        }
    }

    /**
     * @notice Allows for the batch-claiming of interest from interest-bearing FNFTs
     * @param fnftIds A 2D array of FNFT Ids to be claimed. Should be formatted as arrays of FNFT Ids specific to pools for greater gas efficiency.
     * @param recipient The address to which the interest will be sent
     * @dev This function will revert if an inner array of FNFTs contains an ID with a poolID different from the first element in that array
     */
    function batchClaimInterest(uint[][] memory fnftIds, address recipient) public nonReentrant {
        // Outer array is an array of all FNFTs segregated by pool
        // Inner array is array of FNFTs to claim interest on
        uint numberPools = fnftIds.length;
        require(numberPools > 0, 'ER003');

        // for each pool
        for(uint i; i < numberPools; ++i) {
            // save the list of ids for the pool
            uint[] memory fnftsByPool = fnftIds[i];
            require(fnftsByPool.length > 0, 'ER003');

            // get the first order, we commit one SLOAD here
            bytes32 poolId = activated[fnftIdToIndex[fnftsByPool[0]]].poolId;
            PoolConfig memory pool = pools[poolId];
            IERC4626 vault = IERC4626(pool.adapter);
            address asset = vault.asset();

            // set up global to track total shares
            uint totalSharesToRedeem;
            // for each id, should be for loop
            uint len = fnftsByPool.length;
            for(uint j; j < len; ++j) {
                {
                    Active memory active = activated[fnftIdToIndex[fnftsByPool[j]]];
                    require(active.poolId == poolId, 'ER039');
                    // save the individual id
                    uint fnftId = fnftsByPool[j];
                    require(msg.sender == PROXY_OUTPUT_RECEIVER || FNFT_HANDLER.getBalance(msg.sender, fnftId) > 0, 'ER010');
                    require(fnftId == active.principalId + 1, 'ER009');
                    uint prinPackets = FNFT_HANDLER.getSupply(active.principalId);
                    require(prinPackets > 0, 'ER016');
                    uint oldShares = active.sharesPerPacket * prinPackets;
                    uint newShares = vault.previewWithdraw(pool.packetSize * prinPackets) * PRECISION; 
                    require(oldShares > newShares, 'ER040'); // Shouldn't pass FNFTs into this method that aren't owed interest
                    {
                        // Calculate the maximum number of shares that will be redeemed
                        uint sharesRedeemed = oldShares - newShares;   
                        // add to cumulative total
                        totalSharesToRedeem += sharesRedeemed;
                        // Update existing sharesPerPacket
                        activated[fnftIdToIndex[fnftId]].sharesPerPacket = newShares / prinPackets;
                    }
                }
            }
            uint interest = _getWalletForFNFT(poolId).redeemShares(
                pool.adapter, 
                address(this), 
                totalSharesToRedeem / PRECISION // recover extra precision
            );
            uint fee = interest * FEE / DENOM;
            IERC20(asset).transfer(DEV_ADDRESS, fee);
            // Forward to recipient
            IERC20(asset).transfer(recipient, interest-fee);
            emit FeeCollection(poolId, fee); 
            emit BatchInterestClaimed(poolId, fnftsByPool, recipient, interest);
        }
    }

    /**
     * @notice Claims the interest for a given position
     * @param fnftId the ID of the FNFT to claim interest on
     * @param recipient where that interest should be sent
     * @dev this function can either be called directly by the FNFT holder or through the OutputReceiver Proxy using the update method
     */
    function claimInterest(uint fnftId, address recipient) external override {
        uint[][] memory fnftIds = new uint[][](1);
        uint[] memory fnftIDi = new uint[](1);
        fnftIDi[0] = fnftId;
        fnftIds[0] = fnftIDi;
        batchClaimInterest(fnftIds, recipient);
    }
    
    ///
    /// Revest OutputReceiver functions
    /// 

    /**
     * @notice Handles the withdrawal behavior for both interest- and principal-bearing FNFTs
     * @param fnftId the ID of the FNFT being withdrawn 
     * @param tokenHolder The address to whom the principal or interest should be sent, as they owned the FNFT
     * @param quantity How many FNFTs are being withdrawn within the series. Will always be 1 for interest-bearing FNFTs
     * @dev Can only be called by the OutputReceiver Proxy contract. The FNFT associated with the ID will have been burned at the point this is called
     */
    function receiveRevestOutput(
        uint fnftId,
        address,
        address payable tokenHolder,
        uint quantity
    ) external override nonReentrant {
        require(msg.sender == PROXY_OUTPUT_RECEIVER, "ER017");
        Active memory active = activated[fnftIdToIndex[fnftId]];
        PoolConfig memory pool = pools[active.poolId];
        uint prinPackets = FNFT_HANDLER.getSupply(active.principalId);        

        if(fnftId == active.principalId) {
            // This FNFT represents the principal
            // quantity = principalPackets
            // Need to withdraw principal, then record the residual interest owed
            uint amountUnderlying = quantity * pool.packetSize;
            bool leaveResidual = FNFT_HANDLER.getSupply(active.principalId + 1) > 0;
            address vaultAdapter = pool.adapter;
            
            // NB: Violation of checks-effects-interaction. Acceptable with nonReentrant
            uint residual = _getWalletForFNFT(active.poolId).reclaimPrincipal(
                vaultAdapter,
                tokenHolder, 
                amountUnderlying, 
                active.sharesPerPacket * quantity / PRECISION, // Recover our extra PRECISION here 
                leaveResidual
            );
            if(residual > 0) {
                residuals[fnftId + 1] += residual;
            }
            emit FNFTRedeemed(active.poolId, true, fnftId, quantity);
            emit InterestClaimed(active.poolId, fnftId, tokenHolder, residual);
            emit WithdrawERC20OutputReceiver(tokenHolder, IERC4626(vaultAdapter).asset(), amountUnderlying, fnftId, '0x0');
        } else {
            // This FNFT represents the interest
            require(quantity == 1, 'ER013');
            
            // Pass in totalShares, totalAmountPrincipal, derive interest and pull to this contract
            // Pull in any existing residuals within the same call – using residuals mapping?
            // Tell the vault to TRANSFER the residual (interest left when principal was pulled) 
            // plus WITHDRAW additional interest that has accrued
            // based on whatever principal remains within the vault 
            uint claimPerPacket;
            uint interest;
            
            {
                uint residual = residuals[fnftId];
                if(residual > 0) {
                    residuals[fnftId] = 0;
                }
                uint amountUnderlying = prinPackets * pool.packetSize;
                
                uint totalShares = active.sharesPerPacket * prinPackets / PRECISION; // Recover our extra PRECISION here

                // NB: Violation of checks-effects-interaction. Acceptable with nonReentrant
                (interest,claimPerPacket) = _getWalletForFNFT(active.poolId).reclaimInterestAndResidual(
                    pool.adapter, 
                    address(this), 
                    amountUnderlying, 
                    totalShares, 
                    residual
                );
            }

            if(prinPackets > 0) {
                // Add an extra PRECISION to avoid losing info
                claimPerPacket = claimPerPacket * PRECISION / prinPackets; 
                if(claimPerPacket <= active.sharesPerPacket) {
                    activated[fnftIdToIndex[fnftId]].sharesPerPacket = active.sharesPerPacket - claimPerPacket;
                } else {
                    activated[fnftIdToIndex[fnftId]].sharesPerPacket = 0;
                }
            }

            uint fee = interest * FEE / DENOM;
            address asset = IERC4626(pool.adapter).asset();

            IERC20(asset).safeTransfer(DEV_ADDRESS, fee);
            IERC20(asset).safeTransfer(tokenHolder, interest - fee);
            
            emit FNFTRedeemed(active.poolId, false, fnftId, 1);
            emit FeeCollection(active.poolId, fee);
            emit InterestClaimed(active.poolId, fnftId, tokenHolder, interest);
            // Remaining orphaned residual automatically goes to the principal FNFT holders
        }
        
        // Clean up mappings
        uint index = fnftIdToIndex[active.principalId];
        if(prinPackets == 0) {
            delete fnftIdToIndex[active.principalId];
        }
        if(FNFT_HANDLER.getSupply(active.principalId + 1) == 0) {
            delete fnftIdToIndex[active.principalId+1];
        }
        if(prinPackets == 0 && FNFT_HANDLER.getSupply(active.principalId + 1) == 0) { 
            delete activated[index];
        }
    }
        

    ///
    /// Utility Functions
    ///

    /**
     * @notice Takes two positions and matches them accordingly, creates FNFTs as-needed
     * @param packer Contains all the parameters needed for this operation
     * @dev If there was a deposit into the vault prior to capital activation for either order, claim that now and distribute
     */
    function _activateCapital(
        ParamPacker memory packer
    ) private returns (uint principalId) {
        // Double check in the future on the vaultAdapters
        IERC4626 vault = IERC4626(packer.adapter);
        address vaultAsset = vault.asset(); // The native asset
        // Fetch curPrice if necessary
        // State where it would be zero is when producer order is being submitted for non-farming position
        // Needs to come before FNFT creation, since curPrice is saved within that storage        

        // Need to withdraw from the vault for this operation if value was previously stored in it
        // Utilize this opportunity to charge fee on interest that has accumulated during dwell time
        uint amountFromConsumer = packer.quantityPackets * packer.pool.packetSize;
        uint amountToConsumer = packer.isCrossAsset ? amountFromConsumer * packer.pool.rate / PRECISION * packer.currentExchangeRate / PRECISION : amountFromConsumer * packer.pool.rate / PRECISION; //upfront?

        if(packer.isProducerNew) {
            {
                address consumerOwner = packer.consumerOrder.owner.toAddress();
                // The producer position is the new one, take value from them and transfer to consumer
                // Charge our fee on the upfront payment here
                uint fee = amountToConsumer * FEE / DENOM;
                IERC20(packer.pool.asset).safeTransferFrom(msg.sender, DEV_ADDRESS, fee);
                IERC20(packer.pool.asset).safeTransferFrom(msg.sender, consumerOwner, amountToConsumer-fee);
                emit FeeCollection(packer.poolId, fee);

                // Prepare the desired FNFTs
                principalId = _createFNFTs(packer.quantityPackets, packer.poolId, consumerOwner, packer.producerOrder.owner.toAddress());
            }
            
            // Order was previously farming
            {
                uint shares;
                if(packer.consumerOrder.depositedShares > 0) {
                    // Claim interest on the farming of the consumer's capital
                    (uint depositedShares, uint interest) = IPoolWallet(_getAddressForPool(packer.poolId)).activateExistingConsumerPosition(
                        amountFromConsumer, 
                        packer.quantityPackets * packer.consumerOrder.depositedShares / PRECISION, // Recover our extra precision
                        _getAddressForFNFT(packer.poolId), 
                        DEV_ADDRESS, 
                        packer.adapter
                    );
                    shares = depositedShares;
                    emit FeeCollection(packer.poolId, interest);
                } else {
                    // Position was not being farmed 
                    shares = IPoolWallet(_getAddressForPool(packer.poolId)).depositAndTransfer(
                        amountFromConsumer,
                        packer.adapter,
                        _getAddressForFNFT(packer.poolId)
                    );
                }
                // We want to avoid loss of information, so we multiply by 1E18 (PRECISION)
                shares = shares * PRECISION / packer.quantityPackets;

                Active storage active = activated[principalId];
                active.sharesPerPacket = shares;
                if(packer.pool.addInterestRate != 0) {
                    active.startingSharesPerPacket = shares;
                }
            }
        } else {
            // The consumer position is the new one, take stored producer value and transfer to them
            // If the producer was farming, we can detect this and charge our fee on interest

            address producerOwner = packer.producerOrder.owner.toAddress();

            // Need to deposit to vault from consumer and store in FNFT
            IERC20(vaultAsset).safeTransferFrom(msg.sender, address(this), amountFromConsumer);

            // Prepare the desired FNFTs
            principalId = _createFNFTs(packer.quantityPackets, packer.poolId, packer.consumerOrder.owner.toAddress(), producerOwner);
            {   
                Active storage active = activated[principalId];
                // We add an extra PRECISION to this to avoid losing data
                uint shares = vault.deposit(amountFromConsumer, _getAddressForFNFT(packer.poolId)) * PRECISION / packer.quantityPackets;
                active.sharesPerPacket = shares;
                if(packer.pool.addInterestRate != 0) {
                    active.startingSharesPerPacket = shares;
                }

            }
            

            // Need to then pay out to consumer from producer position
            if(packer.producerOrder.depositedShares > 0 && !packer.isCrossAsset) {
                
                uint interest = IPoolWallet(_getAddressForPool(packer.poolId)).activateExistingProducerPosition(
                    amountToConsumer, 
                    packer.quantityPackets * packer.producerOrder.depositedShares / PRECISION, // Recover our extra PRECISION here 
                    amountToConsumer * FEE / DENOM,
                    msg.sender, 
                    DEV_ADDRESS, 
                    packer.adapter
                );
                emit FeeCollection(packer.poolId, amountToConsumer * FEE / DENOM + interest);

            } else {
                uint fee = amountToConsumer * FEE / DENOM;
                IPoolWallet(_getAddressForPool(packer.poolId)).withdraw(amountToConsumer, fee, packer.pool.asset, msg.sender, DEV_ADDRESS);
            }
        } 
        emit CapitalActivated(packer.poolId, packer.quantityPackets, principalId);
        // Included to comply with IOutputReceiverV3 standard
        emit DepositERC20OutputReceiver(packer.consumerOrder.owner.toAddress(), vaultAsset, amountFromConsumer, principalId, '0x0');
    }

    /**
     * @notice Mints and distributes FNFTs, sends to each involved party
     * @param quantityPackets The number of packets being consumed by this order is the number of principal FNFTs to create
     * @param poolId The ID for the pool associated with these FNFTs
     * @param consumerOwner The owner of the Issuer's order, to whom the principal FNFTs will be minted
     * @param producerOwner The owner of the Purchaser's order, to whom the interest FNFT will be minted
     * @return principalId The ID of the principal-bearing FNFTs
     * @dev This function may be called multiple times for the creation of a single order with multiple counter-parties
     */
    function _createFNFTs(
        uint quantityPackets,
        bytes32 poolId,
        address consumerOwner, 
        address producerOwner
    ) private returns (uint principalId) {
        
        PoolConfig memory pool = pools[poolId];

        // We should know current deposit mul from previous work
        // Should have already deposited value by this point in workflow

        // Initialize base FNFT config
        IRevest.FNFTConfig memory fnftConfig;
        // Common method, both will reference this contract
        fnftConfig.pipeToContract = PROXY_OUTPUT_RECEIVER;
        // Further common components
        address[] memory recipients = new address[](1);
        uint[] memory quantities = new uint[](1);

        // Begin minting principal FNFTs

        quantities[0] = quantityPackets;
        recipients[0] = consumerOwner;

        if (pool.addInterestRate != 0) {
            // Mint Type 1 
            principalId = _getRevest().mintAddressLock(PROXY_ADDRESS_LOCK, "", recipients, quantities, fnftConfig);
        } else {
            // Mint Type 0
            principalId = _getRevest().mintTimeLock(block.timestamp + pool.lockupPeriod, recipients, quantities, fnftConfig);
        }

        // Begin minting interest FNFT

        // Interest FNFTs will always be singular
        // NB: Interest ID will always be +1 of principal ID
        quantities[0] = 1;
        recipients[0] = producerOwner;
        uint interestId;
        
        if (pool.addInterestRate != 0) {
            // Mint Type 1 
            interestId = _getRevest().mintAddressLock(PROXY_ADDRESS_LOCK, "", recipients, quantities, fnftConfig);  
        }  else {
            // Mint Type 0
            interestId = _getRevest().mintTimeLock(block.timestamp + pool.lockupPeriod, recipients, quantities, fnftConfig);
        }

        {

            activated[principalId] = Active(principalId, 1, 0, poolId);

            fnftIdToIndex[principalId] = principalId;
            fnftIdToIndex[interestId] = principalId;
        }

        emit FNFTCreation(poolId, true, principalId, quantityPackets);
        emit FNFTCreation(poolId, false, interestId, 1);
    }


    /**
     * @notice Add an order to the appropriate queue
     * @param poolId The ID of the pool to which this order should be added
     * @param isProvider Whether the order should be added to Purchaser queue (true) or Issuer queue (false)
     * @param shouldFarm Whether the user's tokens should be deposited into the underlying vault to farm in-queue
     * @param order The Order structure to add to the respective queue
     * @param amount The amount of tokens being deposited
     * @param asset The asset to deposit
     * @param vaultAdapter the ERC-4626 vault (adapter) to deposit into
     * @dev This should only be called once during either submitConsumer or submitProducer
     */
    function _enqueue(
        bytes32 poolId, 
        bool isProvider, 
        bool shouldFarm, 
        Order memory order, 
        uint amount, 
        address asset, 
        address vaultAdapter
    ) private {
        if(shouldFarm) {
            IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

            order.depositedShares = IERC4626(vaultAdapter).deposit(amount, _getAddressForPool(poolId)) * PRECISION / order.packetsRemaining;
            require(order.depositedShares > 0, 'ER003'); 
        } else {
            // Leaving depositedShares as zero signifies non-farming nature of order
            // Similarly stores value in pool smart wallet
            IERC20(asset).safeTransferFrom(msg.sender, _getAddressForPool(poolId), amount);
        }

        PoolQueue storage qm = queueMarkers[poolId];
        // Allow overflow to reuse indices 
        unchecked {
            uint64 tail;
            if(isProvider) {
                tail = qm.providerTail;
                providerQueue[poolId][qm.providerTail++] = order;
                emit EnqueueProvider(poolId, msg.sender, tail, shouldFarm, order);
                
            } else {
                tail = qm.consumerTail;
                consumerQueue[poolId][qm.consumerTail++] = order;
                emit EnqueueConsumer(poolId, msg.sender, tail, shouldFarm, order);
            }
        }
    }   

    /**
     * @notice Remove an order from the appropriate queue 
     * @param poolId The ID of the pool which the order should be dequeued from
     * @param isProvider Whether the order should be removed from the Purchaser queue (true) or the Issuer queue (false)
     * @dev This can be called multiple times during the matching of counterparties
     */ 
    function _dequeue(bytes32 poolId, bool isProvider) private {
        PoolQueue storage qm = queueMarkers[poolId];
        Order memory order = providerQueue[poolId][isProvider ? qm.providerHead : qm.consumerHead];
        unchecked{
            uint64 head;
            if(isProvider) {
                head = qm.providerHead;
                delete providerQueue[poolId][qm.providerHead++];
                emit DequeueProvider(poolId, msg.sender, order.owner.toAddress(), head, order);
            } else {
                head = qm.consumerHead;
                delete consumerQueue[poolId][qm.consumerHead++];
                emit DequeueConsumer(poolId, msg.sender, order.owner.toAddress(), head, order);
            }
        }
    }

    /// Use to initialize necessary values for a pool
    /**
     * @notice Helper method to initialize the necessary values for a pool
     * @param asset the payment asset for the pool
     * @param vault the raw vault address for the pool - if non-4626 will have an adapter in vaultAdapters
     * @param rate the upfront payout rate for the pool
     * @param _additional_rate the value to be added to the rate to get the interest needed for unlock. Zero if fixed-term
     * @param lockupPeriod the amount of time in seconds that the principal FNFT will be locked for. Zero if fixed-income
     * @param packetSize the standard packet size for the pool
     * @return poolId the resulting poolId from the given parameters
     */
    function _initPool(
        address asset,
        address vault, 
        uint128 rate, 
        uint128 _additional_rate,
        uint32 lockupPeriod, 
        uint packetSize
    ) private returns (bytes32 poolId) {
        address adapter = vaultAdapters[vault];
        poolId = _getPoolId(asset, vault, adapter, rate, _additional_rate, lockupPeriod, packetSize);
        require(pools[poolId].lockupPeriod == 0 && pools[poolId].addInterestRate == 0, 'ER002');
        queueMarkers[poolId] = PoolQueue(1, 1, 1, 1);
        pools[poolId] = PoolConfig(asset, vault, adapter, lockupPeriod, rate, _additional_rate, packetSize);
    }

    /**
     * @notice Fetches an instance of IPoolWallet, either by deploying or by instantiating an existing deployment
     * @param poolId The poolID to which this IPoolWallet is bound
     * @return wallet The instance of IPoolWallet associated with the passed-in poolId
     */
    function _getWalletForPool(bytes32 poolId) private returns (IPoolWallet wallet) {
        wallet = IPoolWallet(IResonateHelper(RESONATE_HELPER).getWalletForPool(poolId));
    }

    /**
     * @notice Fetches an instance of ISmartWallet, either by deploying or by instantiating an existing deployment
     * @param poolId The poolID to which this ISmartWallet is bound
     * @return wallet The instance of ISmartWallet associated with the passed-in poolId
     */
    function _getWalletForFNFT(bytes32 poolId) private returns (ISmartWallet wallet) {
        wallet = ISmartWallet(IResonateHelper(RESONATE_HELPER).getWalletForFNFT(poolId));
    }

    /**
     * @notice Checks whether a contract has approval to spend tokens from Resonate, approves if not so
     * @param spender The spender address to check, typically a smart wallet
     * @param asset The asset which will be spent
     */
    function _checkApproval(address spender, address asset) private {
        if(!_approvedContracts[spender][asset]) {
            IERC20(asset).safeApprove(spender, type(uint).max);
            _approvedContracts[spender][asset] = true;
        }
    }

    function _validRecipient() private view returns (bool canReceive) {
        uint size = msg.sender.code.length;
        bool isEOA = size == 0;
        canReceive = (msg.sender == tx.origin && isEOA) || SMART_WALLET_WHITELIST.check(msg.sender);
    }
     
    ///
    /// Admin Functions
    ///

    /**
     * @notice Used to match a vault with its adapter – can also be utilized for zero-ing out a vault
     * @param vault The raw vault which needs to be mapped to its adapter. If 4626, will be identical to adapter.
     * @param adapter The ERC-4626 adapter or vault to map to the baseline vault
     * @dev Protected function, vault MUST conform to ERC20 standard
     */
    function modifyVaultAdapter(address vault, address adapter) external onlyOwner {
        vaultAdapters[vault] = adapter;
        if(adapter != address(0)) {
            _checkApproval(adapter, IERC4626(adapter).asset());
            emit VaultAdapterRegistered(vault, adapter, IERC4626(adapter).asset());
        } else {
            emit VaultAdapterRegistered(vault, adapter, address(0));
        }
    }

    /**
     * @notice Transfer ownership to a new owner
     * @param newOwner The new owner to transfer control of admin functions to
     * @dev Protected function
     */
    function transferOwnership(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    ///
    /// View Functions
    ///

    /**
     * @notice Indicates whether a queue is empty on one side and therefore whether a counter-party is present
     * @param poolId The ID of the pool to check queues within
     * @param isProvider Whether to check the Purchaser queue (true) or the Issuer queue (false)
     * @return isEmpty Whether the queue being checked is empty or not
     */
    function _isQueueEmpty(bytes32 poolId, bool isProvider) private view returns (bool isEmpty) {
        PoolQueue memory qm = queueMarkers[poolId];
        isEmpty = isProvider ? qm.providerHead == qm.providerTail : qm.consumerHead == qm.consumerTail;
    }

    /**
     * @notice Retreive the poolId that a specified combination of inputs will produce
     * @param asset the payment asset for the pool
     * @param vault the raw vault address for the pool - if non-4626 will have an adapter in vaultAdapters
     * @param rate the upfront payout rate for the pool
     * @param _additional_rate the value to be added to the rate to get the interest needed for unlock. Zero if fixed-term
     * @param lockupPeriod the amount of time in seconds that the principal FNFT will be locked for. Zero if fixed-income
     * @param packetSize the standard packet size for the pool
     * @return poolId the result of applying keccak256 to the abi-encoded arguments passed in
     */
    function _getPoolId(
        address asset, 
        address vault, 
        address adapter,
        uint128 rate,
        uint128 _additional_rate,   
        uint32 lockupPeriod, 
        uint packetSize
    ) private pure returns (bytes32 poolId) {
        poolId = keccak256(abi.encodePacked(asset, vault, adapter, rate, _additional_rate, lockupPeriod, packetSize));
    }

    

    /**
     * @notice Returns the order at the head of the specified queue without removing it
     * @param poolId The poolId of the pool in which the queue exists
     * @param isProvider Whether to check the Purchaser queue (true) or the Issuer queue (false)
     * @return order The Order struct which is at the head of the specified queue
     */
    function _peek(bytes32 poolId, bool isProvider) private view returns (Order storage order) {
        if(isProvider) {
            order = providerQueue[poolId][queueMarkers[poolId].providerHead];
        } else {
            order = consumerQueue[poolId][queueMarkers[poolId].consumerHead];
        }
    }

    /**
     * @notice Returns the address of a pool smart wallet 
     */
    function _getAddressForPool(bytes32 poolId) private view returns (address smartWallet) {
        smartWallet = IResonateHelper(RESONATE_HELPER).getAddressForPool(poolId);
    }

    /**
     * @notice Returns the address of an FNFT pool smart wallet 
     */
    function _getAddressForFNFT(bytes32 poolId) private view returns (address smartWallet) {
        smartWallet = IResonateHelper(RESONATE_HELPER).getAddressForFNFT(poolId);
    }

    /// @notice Returns the IRevest entry point dictated by the Revest Address Registry
    function _getRevest() private view returns (IRevest) {
        return IRevest(IAddressRegistry(REGISTRY_ADDRESS).getRevest());
    }

}