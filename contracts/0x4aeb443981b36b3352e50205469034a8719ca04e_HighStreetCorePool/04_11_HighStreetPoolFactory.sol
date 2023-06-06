// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IPool.sol";

/**
 * @title HighStreet Pool Factory
 *
 * @notice HIGH Pool Factory manages HighStreet Yield farming pools, provides a single
 *      public interface to access the pools, provides an interface for the pools
 *      to mint yield rewards, access pool-related info, update weights, etc.
 *
 * @notice The factory is authorized (via its owner) to register new pools, change weights
 *      of the existing pools, removing the pools (by changing their weights to zero)
 *
 * @dev The factory requires ROLE_TOKEN_CREATOR permission on the HIGH token to mint yield
 *      (see `mintYieldTo` function)
 *
 */
contract HighStreetPoolFactory is Ownable {
    /**
     * @dev Smart contract unique identifier, a random number
     * @dev Should be regenerated each time smart contact source code is changed
     *      and changes smart contract itself is to be redeployed
     * @dev Generated using https://www.random.org/bytes/
     */
    uint256 public constant FACTORY_UID = 0x484a992416a6637667452c709058dccce100b22b278536f5a6d25a14b6a1acdb;

    /// @dev Link to HIGH STREET ERC20 Token instance
    address public immutable HIGH;

    /// @dev Auxiliary data structure used only in getPoolData() view function
    struct PoolData {
        // @dev pool token address (like HIGH)
        address poolToken;
        // @dev pool address (like deployed core pool instance)
        address poolAddress;
        // @dev pool weight (200 for HIGH pools, 800 for HIGH/ETH pools - set during deployment)
        uint256 weight;
        // @dev flash pool flag
        bool isFlashPool;
    }

    /**
     * @dev HIGH/block determines yield farming reward base
     *      used by the yield pools controlled by the factory
     */
    uint256 public highPerBlock;

    /**
     * @dev The yield is distributed proportionally to pool weights;
     *      total weight is here to help in determining the proportion
     */
    uint256 public totalWeight;

    /**
     * @dev HIGH/block decreases by 3% every blocks/update (set to 91252 blocks during deployment);
     *      an update is triggered by executing `updateHighPerBlock` public function
     */
    uint256 public immutable blocksPerUpdate;

    /**
     * @dev End block is the last block when HIGH/block can be decreased;
     *      it is implied that yield farming stops after that block
     */
    uint256 public endBlock;

    /**
     * @dev Each time the HIGH/block ratio gets updated, the block number
     *      when the operation has occurred gets recorded into `lastRatioUpdate`
     * @dev This block number is then used to check if blocks/update `blocksPerUpdate`
     *      has passed when decreasing yield reward by 3%
     */
    uint256 public lastRatioUpdate;

    /// @dev Maps pool token address (like HIGH) -> pool address (like core pool instance)
    mapping(address => address) public pools;

    /// @dev Keeps track of registered pool addresses, maps pool address -> exists flag
    mapping(address => bool) public poolExists;

    /**
     * @dev Fired in createPool() and registerPool()
     *
     * @param _by an address which executed an action
     * @param poolToken pool token address (like HIGH)
     * @param poolAddress deployed pool instance address
     * @param weight pool weight
     * @param isFlashPool flag indicating if pool is a flash pool
     */
    event PoolRegistered(
        address indexed _by,
        address indexed poolToken,
        address indexed poolAddress,
        uint256 weight,
        bool isFlashPool
    );

    /**
     * @dev Fired in changePoolWeight()
     *
     * @param _by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param weight new pool weight
     */
    event WeightUpdated(address indexed _by, address indexed poolAddress, uint256 weight);

    /**
     * @dev Fired in updateHighPerBlock()
     *
     * @param _by an address which executed an action
     * @param newHighPerBlock new HIGH/block value
     */
    event HighRatioUpdated(address indexed _by, uint256 newHighPerBlock);

    /**
     * @dev Fired in mintYieldTo()
     *
     * @param _to an address to mint tokens to
     * @param amount amount of HIGH tokens to mint
     */
    event MintYield(address indexed _to, uint256 amount);

    /**
     * @dev Creates/deploys a factory instance
     *
     * @param _high HIGH ERC20 token address
     * @param _highPerBlock initial HIGH/block value for rewards
     * @param _blocksPerUpdate how frequently the rewards gets updated (decreased by 3%), blocks
     * @param _initBlock block number to measure _blocksPerUpdate from
     * @param _endBlock block number when farming stops and rewards cannot be updated anymore
     */
    constructor(
        address _high,
        uint256 _highPerBlock,
        uint256 _blocksPerUpdate,
        uint256 _initBlock,
        uint256 _endBlock
    ) {
        // verify the inputs are set
        require(_high != address(0) , "HIGH is invalid");
        require(_highPerBlock > 0, "HIGH/block not set");
        require(_blocksPerUpdate > 0, "blocks/update not set");
        require(_initBlock > 0, "init block not set");
        require(_endBlock > _initBlock, "invalid end block: must be greater than init block");

        // save the inputs into internal state variables
        HIGH = _high;
        highPerBlock = _highPerBlock;
        blocksPerUpdate = _blocksPerUpdate;
        lastRatioUpdate = _initBlock;
        endBlock = _endBlock;
    }

    /**
     * @notice Given a pool token retrieves corresponding pool address
     *
     * @dev A shortcut for `pools` mapping
     *
     * @param poolToken pool token address (like HIGH) to query pool address for
     * @return pool address for the token specified
     */
    function getPoolAddress(address poolToken) external view returns (address) {
        // read the mapping and return
        return pools[poolToken];
    }

    /**
     * @notice Reads pool information for the pool defined by its pool token address,
     *      designed to simplify integration with the front ends
     *
     * @param _poolToken pool token address to query pool information for
     * @return pool information packed in a PoolData struct
     */
    function getPoolData(address _poolToken) external view returns (PoolData memory) {
        // get the pool address from the mapping
        address poolAddr = pools[_poolToken];

        // throw if there is no pool registered for the token specified
        require(poolAddr != address(0), "pool not found");

        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        bool isFlashPool = IPool(poolAddr).isFlashPool();
        uint256 weight = IPool(poolAddr).weight();

        // create the in-memory structure and return it
        return PoolData({ poolToken: _poolToken, poolAddress: poolAddr, weight: weight, isFlashPool: isFlashPool });
    }

    /**
     * @dev Verifies if `blocksPerUpdate` has passed since last HIGH/block
     *      ratio update and if HIGH/block reward can be decreased by 3%
     *
     * @return true if enough time has passed and `updateHighPerBlock` can be executed
     */
    function shouldUpdateRatio() public view returns (bool) {
        // if yield farming period has ended
        if (blockNumber() > endBlock) {
            // HIGH/block reward cannot be updated anymore
            return false;
        }

        // check if blocks/update (91252 blocks) have passed since last update
        return blockNumber() >= lastRatioUpdate + blocksPerUpdate;
    }

    /**
     * @dev Registers an already deployed pool instance within the factory
     *
     * @dev Can be executed by the pool factory owner only
     *
     * @param poolAddr address of the already deployed pool instance
     */
    function registerPool(address poolAddr) external onlyOwner {
        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(poolAddr).poolToken();
        bool isFlashPool = IPool(poolAddr).isFlashPool();
        uint256 weight = IPool(poolAddr).weight();

        // ensure that the pool is not already registered within the factory
        require(pools[poolToken] == address(0), "this pool is already registered");

        // create pool structure, register it within the factory
        pools[poolToken] = poolAddr;
        poolExists[poolAddr] = true;
        // update total pool weight of the factory
        totalWeight += weight;

        // emit an event
        emit PoolRegistered(msg.sender, poolToken, poolAddr, weight, isFlashPool);
    }

    /**
     * @notice Decreases HIGH/block reward by 3%, can be executed
     *      no more than once per `blocksPerUpdate` blocks
     */
    function updateHighPerBlock() external {
        // checks if ratio can be updated i.e. if blocks/update (91252 blocks) have passed
        require(shouldUpdateRatio(), "too frequent");

        // decreases HIGH/block reward by 3%
        highPerBlock = (highPerBlock * 97) / 100;

        // set current block as the last ratio update block
        lastRatioUpdate = blockNumber();

        // emit an event
        emit HighRatioUpdated(msg.sender, highPerBlock);
    }

    /**
     * @dev Mints HIGH tokens; executed by HIGH Pool only
     *
     * @dev Requires factory to have ROLE_TOKEN_CREATOR permission
     *      on the HIGH ERC20 token instance
     *
     * @param _to an address to mint tokens to
     * @param _amount amount of HIGH tokens to mint
     */
    function mintYieldTo(address _to, uint256 _amount) external {
        // verify that sender is a pool registered withing the factory
        require(poolExists[msg.sender], "access denied");

        // transfer HIGH tokens as required
        transferHighToken(_to, _amount);

        emit MintYield(_to, _amount);
    }

    /**
     * @dev Changes the weight of the pool;
     *      executed by the pool itself or by the factory owner
     *
     * @param poolAddr address of the pool to change weight for
     * @param weight new weight value to set to
     */
    function changePoolWeight(address poolAddr, uint256 weight) external {
        // verify function is executed either by factory owner or by the pool itself
        require(msg.sender == owner() || poolExists[msg.sender]);

        // recalculate total weight
        totalWeight = totalWeight + weight - IPool(poolAddr).weight();

        // set the new pool weight
        IPool(poolAddr).setWeight(weight);

        // emit an event
        emit WeightUpdated(msg.sender, poolAddr, weight);
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override block number in helper test smart contracts
     *
     * @return `block.number` in mainnet, custom values in testnets (if overridden)
     */
    function blockNumber() public view virtual returns (uint256) {
        // return current block number
        return block.number;
    }

    /**
     * @dev Executes SafeERC20.safeTransfer on a HIGH token
     *
     */
    function transferHighToken(address _to, uint256 _value) internal {
        // just delegate call to the target
        SafeERC20.safeTransfer(IERC20(HIGH), _to, _value);
    }

}