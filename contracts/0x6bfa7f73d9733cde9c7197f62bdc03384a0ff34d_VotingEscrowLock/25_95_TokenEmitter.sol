//SPDX-License-Identifier: GPL-3.0
// This contract referenced Sushi's MasterChef.sol logic
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../../core/emission/interfaces/ITokenEmitter.sol";
import "../../../core/emission/interfaces/IMiningPool.sol";
import "../../../core/emission/interfaces/IMiningPoolFactory.sol";
import "../../../core/emission/libraries/PoolType.sol";
import "../../../core/governance/Governed.sol";
import "../../../core/dividend/interfaces/IDividendPool.sol";
import "../../../utils/IERC20Mintable.sol";
import "../../../utils/Utils.sol";
import "../../../utils/ERC20Recoverer.sol";

contract TokenEmitter is
    Governed,
    ReentrancyGuard,
    ITokenEmitter,
    Initializable,
    ERC20Recoverer
{
    using ERC165Checker for address;
    using SafeMath for uint256;
    using Utils for bytes4[];

    uint256 public constant override DENOMINATOR = 10000;
    uint256 public constant override EMISSION_PERIOD = 1 weeks;
    uint256 private _INITIAL_EMISSION;
    uint256 private _FOUNDER_SHARE_DENOMINATOR;

    address private _token;
    uint256 private _minEmissionRatePerWeek = 60; // 0.006 per week ~= 36% yearly inflation
    uint256 private _emissionCutRate = 3000; // 30%
    uint256 private _emission;

    address private _initialContributorPool;
    address private _initialContributorShare;
    address private _treasury;
    address private _protocolPool;
    uint256 private _startDelay;

    mapping(bytes4 => address) private _factories;

    mapping(address => bytes4) private _poolTypes;

    EmissionWeight private _emissionWeight;

    uint256 private _emissionStarted;

    uint256 private _emissionWeekNum;

    uint256 private _projId;

    function initialize(EmitterConfig memory params) public initializer {
        require(params.treasury != address(0), "Should not be zero");
        Governed.initialize(msg.sender);
        // set params
        _projId = params.projId;
        _INITIAL_EMISSION = params.initialEmission;
        _emission = params.initialEmission;
        _minEmissionRatePerWeek = params.minEmissionRatePerWeek;
        _emissionCutRate = params.emissionCutRate;
        _protocolPool = params.protocolPool;
        _startDelay = params.startDelay;
        // set contract addresses
        _token = params.token;
        setTreasury(params.treasury);
        require(params.founderShareRate < DENOMINATOR);
        _FOUNDER_SHARE_DENOMINATOR = params.founderShareRate != 0
            ? DENOMINATOR / params.founderShareRate
            : 0;
        ERC20Recoverer.initialize(params.gov, new address[](0));
        setFactory(params.erc20BurnMiningFactory);
        setFactory(params.erc20StakeMiningFactory);
        setFactory(params.erc721StakeMiningFactory);
        setFactory(params.erc1155StakeMiningFactory);
        setFactory(params.erc1155BurnMiningFactory);
        setFactory(params.initialContributorShareFactory);
        address initialContributorPool_ =
            newPool(PoolType.InitialContributorShare, params.contributionBoard);
        _initialContributorPool = initialContributorPool_;
        _initialContributorShare = params.contributionBoard;
        Governed.setGovernance(params.gov);
    }

    /**
     * StakeMiningV1:
     */
    function newPool(bytes4 poolType, address token_) public returns (address) {
        address factory = _factories[poolType];
        require(factory != address(0), "Factory not exists");
        address _pool =
            IMiningPoolFactory(factory).getPool(address(this), token_);
        if (_pool == address(0)) {
            _pool = IMiningPoolFactory(factory).newPool(address(this), token_);
        }
        require(
            _pool.supportsInterface(poolType),
            "Does not have the given pool type"
        );
        require(
            _pool.supportsInterface(IMiningPool(0).allocate.selector),
            "Cannot allocate reward"
        );
        require(_poolTypes[_pool] == bytes4(0), "Pool already exists");
        _poolTypes[_pool] = poolType;
        emit NewMiningPool(poolType, token_, _pool);
        return _pool;
    }

    function setEmission(MiningConfig memory config) public governed {
        require(config.treasuryWeight < 1e4, "prevent overflow");
        require(config.callerWeight < 1e4, "prevent overflow");
        // starting the summation with treasury and caller weights
        uint256 _sum = config.treasuryWeight + config.callerWeight;
        // prepare list to store
        address[] memory _pools = new address[](config.pools.length);
        uint256[] memory _weights = new uint256[](config.pools.length);
        // deploy pool if not the pool exists and do the weight summation
        // udpate the pool & weight arr on memory
        for (uint256 i = 0; i < config.pools.length; i++) {
            address _pool =
                _getOrDeployPool(
                    config.pools[i].poolType,
                    config.pools[i].baseToken
                );
            require(
                _poolTypes[_pool] != bytes4(0),
                "Not a deployed mining pool"
            );
            require(config.pools[i].weight < 1e4, "prevent overflow");
            _weights[i] = config.pools[i].weight;
            _pools[i] = _pool;
            _sum += config.pools[i].weight; // doesn't overflow
        }
        // compute the founder share
        uint256 _dev =
            _FOUNDER_SHARE_DENOMINATOR != 0
                ? _sum / _FOUNDER_SHARE_DENOMINATOR
                : 0; // doesn't overflow;
        _sum += _dev;
        // compute the protocol share
        uint256 _protocol = _protocolPool == address(0) ? 0 : _sum / 33;
        _sum += _protocol;
        // store the updated emission weight
        _emissionWeight = EmissionWeight(
            _pools,
            _weights,
            config.treasuryWeight,
            config.callerWeight,
            _protocol,
            _dev,
            _sum
        );
        emit EmissionWeightUpdated(_pools.length);
    }

    function setFactory(address factory) public governed {
        bytes4[] memory interfaces = new bytes4[](2);
        interfaces[0] = IMiningPoolFactory(0).newPool.selector;
        interfaces[1] = IMiningPoolFactory(0).poolType.selector;
        require(
            factory.supportsAllInterfaces(interfaces),
            "Not a valid factory"
        );
        bytes4 _sig = IMiningPoolFactory(factory).poolType();
        require(_factories[_sig] == address(0), "Factory already exists.");
        _factories[_sig] = factory;
    }

    function setTreasury(address treasury_) public governed {
        _treasury = treasury_;
    }

    function start() public override governed {
        require(_emissionStarted == 0, "Already started");
        _emissionStarted = block.timestamp.add(_startDelay).sub(1 weeks);
        emit Start();
    }

    function setEmissionCutRate(uint256 rate) public governed {
        require(
            1000 <= rate && rate <= 9000,
            "Emission cut should be greater than 10% and less than 90%"
        );
        _emissionCutRate = rate;
        emit EmissionCutRateUpdated(rate);
    }

    function setMinimumRate(uint256 rate) public governed {
        require(
            rate <= 134,
            "Protect from the superinflationary(99.8% per year) situation"
        );
        _minEmissionRatePerWeek = rate;
        emit EmissionRateUpdated(rate);
    }

    function distribute() public override nonReentrant {
        // current week from the mining start;
        uint256 weekNum =
            block.timestamp.sub(_emissionStarted).div(EMISSION_PERIOD);
        // The first token token drop will be started a week after the "start" func called.
        require(
            weekNum > _emissionWeekNum,
            "Already minted or not started yet."
        );
        // update emission week num
        _emissionWeekNum = weekNum;
        // allocate to mining pools
        uint256 weightSum = _emissionWeight.sum;
        uint256 prevSupply = IERC20(_token).totalSupply();
        for (uint256 i = 0; i < _emissionWeight.pools.length; i++) {
            require(i < _emissionWeight.pools.length, "out of index");
            uint256 weighted =
                _emissionWeight.weights[i].mul(_emission).div(weightSum);
            _mintAndNotifyAllocation(_emissionWeight.pools[i], weighted);
        }
        // Caller
        IERC20Mintable(_token).mint(
            msg.sender,
            _emissionWeight.caller.mul(_emission).div(weightSum)
        );
        if (_treasury != address(0)) {
            // Protocol fund(protocol treasury)
            IERC20Mintable(_token).mint(
                _treasury,
                _emissionWeight.treasury.mul(_emission).div(weightSum)
            );
        }
        // Protocol
        if (_protocolPool != address(0)) {
            IERC20Mintable(_token).mint(
                _protocolPool,
                _emissionWeight.protocol.mul(_emission).div(weightSum)
            );
            // balance diff automatically distributed. no approval needed
            IDividendPool(_protocolPool).distribute(_token, 0);
        }
        if (_initialContributorPool != address(0)) {
            // Founder
            _mintAndNotifyAllocation(
                _initialContributorPool,
                _emission.sub(IERC20(_token).totalSupply().sub(prevSupply))
            );
        }
        emit TokenEmission(_emission);
        _updateEmission();
    }

    function getNumberOfPools() public view returns (uint256) {
        return _emissionWeight.pools.length;
    }

    function getPoolWeight(uint256 poolIndex) public view returns (uint256) {
        return _emissionWeight.weights[poolIndex];
    }

    function token() public view override returns (address) {
        return _token;
    }

    function minEmissionRatePerWeek() public view override returns (uint256) {
        return _minEmissionRatePerWeek;
    }

    function emissionCutRate() public view override returns (uint256) {
        return _emissionCutRate;
    }

    function emission() public view override returns (uint256) {
        return _emission;
    }

    function initialContributorPool() public view override returns (address) {
        return _initialContributorPool;
    }

    function initialContributorShare() public view override returns (address) {
        return _initialContributorShare;
    }

    function treasury() public view override returns (address) {
        return _treasury;
    }

    function protocolPool() public view override returns (address) {
        return _protocolPool;
    }

    function pools(uint256 index) public view override returns (address) {
        return _emissionWeight.pools[index];
    }

    function emissionWeight()
        public
        view
        override
        returns (EmissionWeight memory)
    {
        return _emissionWeight;
    }

    function emissionStarted() public view override returns (uint256) {
        return _emissionStarted;
    }

    function emissionWeekNum() public view override returns (uint256) {
        return _emissionWeekNum;
    }

    function projId() public view override returns (uint256) {
        return _projId;
    }

    function poolTypes(address pool) public view override returns (bytes4) {
        return _poolTypes[pool];
    }

    function factories(bytes4 poolType) public view override returns (address) {
        return _factories[poolType];
    }

    function INITIAL_EMISSION() public view override returns (uint256) {
        return _INITIAL_EMISSION;
    }

    function FOUNDER_SHARE_DENOMINATOR()
        public
        view
        override
        returns (uint256)
    {
        return _FOUNDER_SHARE_DENOMINATOR;
    }

    function _mintAndNotifyAllocation(address miningPool, uint256 amount)
        private
    {
        IERC20Mintable(_token).mint(address(miningPool), amount);
        try IMiningPool(miningPool).allocate(amount) {
            // success
        } catch {
            // pool does not handled the emission
        }
    }

    function _updateEmission() private returns (uint256) {
        // Minimum emission 0.05% per week will make 2.63% of inflation per year
        uint256 minEmission =
            IERC20(_token).totalSupply().mul(_minEmissionRatePerWeek).div(
                DENOMINATOR
            );
        // Emission will be continuously halved until it reaches to its minimum emission. It will be about 10 weeks.
        uint256 cutEmission =
            _emission.mul(DENOMINATOR.sub(_emissionCutRate)).div(DENOMINATOR);
        _emission = Math.max(cutEmission, minEmission);
        return _emission;
    }

    function _getOrDeployPool(bytes4 poolType, address baseToken)
        internal
        returns (address _pool)
    {
        address _factory = _factories[poolType];
        require(_factory != address(0), "Factory not exists");
        // get predicted pool address
        _pool = IMiningPoolFactory(_factory).poolAddress(
            address(this),
            baseToken
        );
        if (_poolTypes[_pool] == poolType) {
            // pool is registered successfully
            return _pool;
        } else {
            // try to deploy new pool and register
            return newPool(poolType, baseToken);
        }
    }
}