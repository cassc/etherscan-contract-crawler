// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import './libraries/Math.sol';
import './interfaces/IBribe.sol';
import './interfaces/IBribeFactory.sol';
import './interfaces/IGauge.sol';
import './interfaces/IGaugeFactory.sol';
import './interfaces/IERC20.sol';
import './interfaces/IMinter.sol';
import './interfaces/IPair.sol';
import './interfaces/IPairFactory.sol';
import './interfaces/IVoter.sol';
import './interfaces/IVotingEscrow.sol';
import "../lz/interfaces/ILayerZeroEndpoint.sol";
import "./SidechainPool.sol";
import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract VoterV2_1 is IVoter, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    ILayerZeroEndpoint public constant lzEndpoint = ILayerZeroEndpoint(0x3c2269811836af69497E5F486A85D7316753cf62);

    address public _ve; // the ve token that governs these contracts
    address public factory; // the PairFactory
    address internal base;
    address public proxyOFT;
    address public gaugefactory;
    address public bribefactory;
    uint internal constant DURATION = 7 days; // rewards are released over 7 days
    address public minter;
    address public governor; // should be set to an IGovernor
    address public emergencyCouncil; // credibly neutral party similar to Curve's Emergency DAO

    uint internal index;
    mapping(address => uint) internal supplyIndex;
    mapping(address => uint) public claimable;

    uint public totalWeight; // total voting weight

    address[] public pools; // all pools viable for incentives
    mapping(address => address) public gauges; // pool => gauge
    mapping(address => uint) public gaugeChain; // gauge => uint
    mapping(uint16 => address) public sidechainManager; // chain => gauge manager
    mapping(uint16 => address[]) public chainGauges; // chain => gauge list
    mapping(uint => mapping(address => uint)) public epochBridgeData; // epoch => gauge => claimable
    mapping(address => uint) public gaugesDistributionTimestmap;
    mapping(address => address) public poolForGauge; // gauge => pool
    mapping(address => address) public internal_bribes; // gauge => internal bribe (only fees)
    mapping(address => address) public external_bribes; // gauge => external bribe (real bribes)
    mapping(address => uint256) public weights; // pool => weight
    mapping(uint => mapping(address => uint256)) public votes; // nft => pool => votes
    mapping(uint => address[]) public poolVote; // nft => pools
    mapping(uint => uint) public usedWeights;  // nft => total voting weight of user
    mapping(uint => uint) public lastVoted; // nft => timestamp of last vote, to ensure one vote per epoch
    mapping(address => bool) public isGauge;
    mapping(address => bool) public isAlive;

    event GaugeCreated(address indexed gauge, address creator, address internal_bribe, address indexed external_bribe, address indexed pool);
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event Voted(address indexed voter, uint tokenId, uint256 weight);
    event Abstained(uint tokenId, uint256 weight);
    event Deposit(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event Withdraw(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event NotifyReward(address indexed sender, address indexed reward, uint amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint amount);
    event Attach(address indexed owner, address indexed gauge, uint tokenId);
    event Detach(address indexed owner, address indexed gauge, uint tokenId);

    constructor() {}

    function initialize(
        address __ve, 
        address _factory, 
        address  _gauges, 
        address _bribes,
        address _proxyOFT
    ) initializer public {
        __Ownable_init();
        __ReentrancyGuard_init();
        _ve = __ve;
        factory = _factory;
        base = IVotingEscrow(__ve).token();
        proxyOFT = _proxyOFT;
        gaugefactory = _gauges;
        bribefactory = _bribes;
        minter = msg.sender;
        governor = msg.sender;
        emergencyCouncil = msg.sender;
    }      

    function _initialize(address _minter) external {
        require(msg.sender == minter || msg.sender == emergencyCouncil);
        minter = _minter;
    }

    function setMinter(address _minter) external {
        require(msg.sender == emergencyCouncil);
        minter = _minter;
    }

    function setGovernor(address _governor) public {
        require(msg.sender == governor);
        governor = _governor;
    }

    function setEmergencyCouncil(address _council) public {
        require(msg.sender == emergencyCouncil);
        emergencyCouncil = _council;
    }

    function reset(uint _tokenId) external nonReentrant {
        //require((block.timestamp / DURATION) * DURATION > lastVoted[_tokenId], "TOKEN_ALREADY_VOTED_THIS_EPOCH");
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        lastVoted[_tokenId] = block.timestamp;
        _reset(_tokenId);
        IVotingEscrow(_ve).abstain(_tokenId);
    }

    function _reset(uint _tokenId) internal {
        address[] storage _poolVote = poolVote[_tokenId];
        uint _poolVoteCnt = _poolVote.length;
        uint256 _totalWeight = 0;

        for (uint i = 0; i < _poolVoteCnt; i ++) {
            address _pool = _poolVote[i];
            uint256 _votes = votes[_tokenId][_pool];

            if (_votes != 0) {
                _updateFor(gauges[_pool]);
                weights[_pool] -= _votes;
                votes[_tokenId][_pool] -= _votes;
                if (_votes > 0) {
                    IBribe(internal_bribes[gauges[_pool]])._withdraw(uint256(_votes), _tokenId);
                    IBribe(external_bribes[gauges[_pool]])._withdraw(uint256(_votes), _tokenId);
                    _totalWeight += _votes;
                } else {
                    _totalWeight -= _votes;
                }
                emit Abstained(_tokenId, _votes);
            }
        }
        totalWeight -= uint256(_totalWeight);
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];
    }

    function poke(uint _tokenId) external nonReentrant {
        //require((block.timestamp / DURATION) * DURATION > lastVoted[_tokenId], "TOKEN_ALREADY_VOTED_THIS_EPOCH");
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        address[] memory _poolVote = poolVote[_tokenId];
        uint _poolCnt = _poolVote.length;
        uint256[] memory _weights = new uint256[](_poolCnt);

        for (uint i = 0; i < _poolCnt; i ++) {
            _weights[i] = votes[_tokenId][_poolVote[i]];
        }

        _vote(_tokenId, _poolVote, _weights);
    }

    function _vote(uint _tokenId, address[] memory _poolVote, uint256[] memory _weights) internal {
        _reset(_tokenId);
        uint _poolCnt = _poolVote.length;
        uint256 _weight = IVotingEscrow(_ve).balanceOfNFT(_tokenId);
        uint256 _totalVoteWeight = 0;
        uint256 _totalWeight = 0;
        uint256 _usedWeight = 0;

        for (uint i = 0; i < _poolCnt; i++) {
            _totalVoteWeight += _weights[i];
        }

        for (uint i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];

            if (isGauge[_gauge]) {
                uint256 _poolWeight = _weights[i] * _weight / _totalVoteWeight;
                require(votes[_tokenId][_pool] == 0);
                require(_poolWeight != 0);
                _updateFor(_gauge);

                poolVote[_tokenId].push(_pool);

                weights[_pool] += _poolWeight;
                votes[_tokenId][_pool] += _poolWeight;
                IBribe(internal_bribes[_gauge])._deposit(uint256(_poolWeight), _tokenId);
                IBribe(external_bribes[_gauge])._deposit(uint256(_poolWeight), _tokenId);
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                emit Voted(msg.sender, _tokenId, _poolWeight);
            }
        }
        if (_usedWeight > 0) IVotingEscrow(_ve).voting(_tokenId);
        totalWeight += uint256(_totalWeight);
        usedWeights[_tokenId] = uint256(_usedWeight);
    }


    function vote(uint _tokenId, address[] calldata _poolVote, uint256[] calldata _weights) external nonReentrant {
        //require((block.timestamp / DURATION) * DURATION > lastVoted[_tokenId], "TOKEN_ALREADY_VOTED_THIS_EPOCH");
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        require(_poolVote.length == _weights.length);
        lastVoted[_tokenId] = block.timestamp;
        _vote(_tokenId, _poolVote, _weights);
    }

    function createGauge(address _pool, uint16 chainId) external returns (address) {
        require(msg.sender == governor, "Only governor");

        if(chainId > 0) {
            // create dummy token -- only placeholder
            _pool = address(new SidechainPool());
        }

        require(gauges[_pool] == address(0x0), "exists");
        address[] memory allowedRewards = new address[](3);
        address[] memory internalRewards = new address[](2);
        bool isPair = factory != address(0) && IPairFactory(factory).isPair(_pool);
        address tokenA;
        address tokenB;

        if (isPair) {
            (tokenA, tokenB) = IPair(_pool).tokens();
            allowedRewards[0] = tokenA;
            allowedRewards[1] = tokenB;
            internalRewards[0] = tokenA;
            internalRewards[1] = tokenB;

            if (base != tokenA && base != tokenB) {
              allowedRewards[2] = base;
            }
        }

        string memory _type =  string.concat("MF LP Fees: ", IERC20(_pool).symbol() );
        address _internal_bribe = IBribeFactory(bribefactory).createBribe(owner(), tokenA, tokenB, _type);

        _type = string.concat("MF Bribes: ", IERC20(_pool).symbol() );
        address _external_bribe = IBribeFactory(bribefactory).createBribe(owner(), tokenA, tokenB, _type);

        address _gauge = IGaugeFactory(gaugefactory).createGaugeV2(base, _ve, _pool, address(this), _internal_bribe, _external_bribe, address(0), isPair);
        
        if(chainId > 0) {
            gaugeChain[_gauge] = chainId;
            chainGauges[chainId].push(_gauge);
        }

        IERC20(base).approve(_gauge, type(uint).max);
        internal_bribes[_gauge] = _internal_bribe;
        external_bribes[_gauge] = _external_bribe;
        gauges[_pool] = _gauge;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;
        isAlive[_gauge] = true;
        _updateFor(_gauge);
        pools.push(_pool);
        emit GaugeCreated(_gauge, msg.sender, _internal_bribe, _external_bribe, _pool);
        return _gauge;
    }

    function killGauge(address _gauge) external {
        require(msg.sender == emergencyCouncil, "not emergency council");
        require(isAlive[_gauge], "gauge already dead");
        isAlive[_gauge] = false;
        claimable[_gauge] = 0;
        emit GaugeKilled(_gauge);
    }

    function reviveGauge(address _gauge) external {
        require(msg.sender == emergencyCouncil, "not emergency council");
        require(!isAlive[_gauge], "gauge already alive");
        isAlive[_gauge] = true;
        emit GaugeRevived(_gauge);
    }

    function attachTokenToGauge(uint tokenId, address account) external {
        require(isGauge[msg.sender]);
        require(isAlive[msg.sender]); // killed gauges cannot attach tokens to themselves
        if (tokenId > 0) IVotingEscrow(_ve).attach(tokenId);
        emit Attach(account, msg.sender, tokenId);
    }

    function emitDeposit(uint tokenId, address account, uint amount) external {
        require(isGauge[msg.sender]);
        require(isAlive[msg.sender]);
        emit Deposit(account, msg.sender, tokenId, amount);
    }

    function detachTokenFromGauge(uint tokenId, address account) external {
        require(isGauge[msg.sender]);
        if (tokenId > 0) IVotingEscrow(_ve).detach(tokenId);
        emit Detach(account, msg.sender, tokenId);
    }

    function emitWithdraw(uint tokenId, address account, uint amount) external {
        require(isGauge[msg.sender]);
        emit Withdraw(account, msg.sender, tokenId, amount);
    }

    function length() external view returns (uint) {
        return pools.length;
    }

    function poolVoteLength(uint tokenId) external view returns(uint) { 
        return poolVote[tokenId].length;
    }


    function notifyRewardAmount(uint amount) external {
        _safeTransferFrom(base, msg.sender, address(this), amount); // transfer the distro in
        uint256 _ratio = amount * 1e18 / totalWeight; // 1e18 adjustment is removed during claim
        if (_ratio > 0) {
            index += _ratio;
        }
        emit NotifyReward(msg.sender, base, amount);
    }

    function updateFor(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i++) {
            _updateFor(_gauges[i]);
        }
    }

    function updateForRange(uint start, uint end) public {
        for (uint i = start; i < end; i++) {
            _updateFor(gauges[pools[i]]);
        }
    }

    function updateAll() external {
        updateForRange(0, pools.length);
    }

    function updateGauge(address _gauge) external {
        _updateFor(_gauge);
    }

    function _updateFor(address _gauge) internal {
        address _pool = poolForGauge[_gauge];
        uint256 _supplied = weights[_pool];
        if (_supplied > 0) {
            uint _supplyIndex = supplyIndex[_gauge];
            uint _index = index; // get global index0 for accumulated distro
            supplyIndex[_gauge] = _index; // update _gauge current position to global position
            uint _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (_delta > 0) {
                uint _share = uint(_supplied) * _delta / 1e18; // add accrued difference for each supplied token
                if (isAlive[_gauge]) {
                    claimable[_gauge] += _share;
                }
            }
        } else {
            supplyIndex[_gauge] = index; // new users are set to the default global state
        }
    }

    function claimRewards(address[] memory _gauges, address[][] memory _tokens) external {
        for (uint i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
        }
    }

    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        for (uint i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    function claimFees(address[] memory _fees, address[][] memory _tokens, uint _tokenId) external {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        for (uint i = 0; i < _fees.length; i++) {
            IBribe(_fees[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }


    function distributeFees(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i++) {
            if (IGauge(_gauges[i]).isForPair()){
                IGauge(_gauges[i]).claimFees();
            }
        }
    }

    function distributeSidechainAll(uint16 chainId, uint256 period, uint256 dstGasLimit) external payable {
        distributeSidechain(chainId, period, dstGasLimit, 0, chainGauges[chainId].length);
    }

    function distributeSidechain(uint16 chainId, uint256 period, uint256 dstGasLimit, uint256 from, uint256 to) public payable {
        require(chainId > 0, "invalid chainId");
        address _gauge;
        uint256 _totalClaimable;
        uint256 gaugesToProcess = to - from;
        uint256[] memory _claimable = new uint256[](gaugesToProcess);
        address[] memory _gauges = new address[](gaugesToProcess);
        for (uint i = from; i < to; i++) {
            _gauge = chainGauges[chainId][i];
            _gauges[i] = _gauge;
            _claimable[i] = epochBridgeData[period][_gauge];
            _totalClaimable += epochBridgeData[period][_gauge];
            epochBridgeData[period][_gauge] = 0;
        }

        if (_totalClaimable > 0) {
            // Bridge rewards & array with claimable amounts per gauge using LZ
            bytes memory lzPayload = abi.encode(IMinter(minter).active_period(), _totalClaimable, _gauges, _claimable);

            bytes memory trustedPath = abi.encodePacked(sidechainManager[chainId], address(this));
            bytes memory adapterParams = abi.encodePacked(uint16(1), dstGasLimit); // has to be at least 200_000

            lzEndpoint.send{value: msg.value}(chainId, trustedPath, lzPayload, payable(msg.sender), address(0), adapterParams);

            // We also need to send tokens to ProxyOFT contract on main chain
            IERC20(base).transfer(proxyOFT, _totalClaimable);
        }
    }

    function distribute(address _gauge) public nonReentrant {
        IMinter(minter).update_period();
        _updateFor(_gauge); // should set claimable to 0 if killed
        uint _claimable = claimable[_gauge];
        
        uint lastTimestamp = gaugesDistributionTimestmap[_gauge];
        uint currentTimestamp = IMinter(minter).active_period();
        // distribute only if claimable is > 0 and currentEpoch != lastepoch
        if (_claimable > 0 && lastTimestamp < currentTimestamp) {
            claimable[_gauge] = 0;
            if (gaugeChain[_gauge] == 0) {
                IGauge(_gauge).notifyRewardAmount(base, _claimable);
                emit DistributeReward(msg.sender, _gauge, _claimable);
            } else {
                // save for later bridging in bulk
                epochBridgeData[currentTimestamp][_gauge] = _claimable; 
            }
            gaugesDistributionTimestmap[_gauge] = currentTimestamp;
        }
    }

    function distributeAll() external {
        distribute(0, pools.length);
    }

    function distribute(uint start, uint finish) public {
        for (uint x = start; x < finish; x++) {
            distribute(gauges[pools[x]]);
        }
    }

    function distribute(address[] memory _gauges) external {
        for (uint x = 0; x < _gauges.length; x++) {
            distribute(_gauges[x]);
        }
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function setBribeFactory(address _bribeFactory) external {
        require(msg.sender == emergencyCouncil);
        bribefactory = _bribeFactory;
    }

    function setGaugeFactory(address _gaugeFactory) external {
        require(msg.sender == emergencyCouncil);
        gaugefactory = _gaugeFactory;
    }

    function setPairFactory(address _factory) external {
        require(msg.sender == emergencyCouncil);
        factory = _factory;
    }

    function setSidechainManager(uint16 _chainId, address _manager) external {
        require(msg.sender == governor, "Only governor");
        sidechainManager[_chainId] = _manager;
    }

    function killGaugeTotally(address _gauge) external {
        require(msg.sender == emergencyCouncil, "not emergency council");
        require(isAlive[_gauge], "gauge already dead");
        isAlive[_gauge] = false;
        claimable[_gauge] = 0;
        address _pool = poolForGauge[_gauge];
        internal_bribes[_gauge] = address(0);
        external_bribes[_gauge] = address(0);
        gauges[_pool] = address(0);
        poolForGauge[_gauge] = address(0);
        isGauge[_gauge] = false;
        isAlive[_gauge] = false;
        claimable[_gauge] = 0;
        emit GaugeKilled(_gauge);
    }

    function initGauges(address[] memory _gauges, address[] memory _pools) public {
        require(msg.sender == emergencyCouncil);
        uint256 i = 0;
        for(i; i < _pools.length; i++){
            address _pool = _pools[i];
            address _gauge = _gauges[i];
            address tokenA;
            address tokenB;
            (tokenA, tokenB) = IPair(_pool).tokens();

            string memory _type =  string.concat("MF LP Fees: ", IERC20(_pool).symbol() );
            address _internal_bribe = IBribeFactory(bribefactory).createBribe(owner(), tokenA, tokenB, _type);
            _type = string.concat("MF Bribes: ", IERC20(_pool).symbol() );
            address _external_bribe = IBribeFactory(bribefactory).createBribe(owner(), tokenA, tokenB, _type);
            IERC20(base).approve(_gauge, type(uint).max);
            internal_bribes[_gauge] = _internal_bribe;
            external_bribes[_gauge] = _external_bribe;
            gauges[_pool] = _gauge;
            poolForGauge[_gauge] = _pool;
            isGauge[_gauge] = true;
            isAlive[_gauge] = true;
            _updateFor(_gauge);
            pools.push(_pool);
            emit GaugeCreated(_gauge, msg.sender, _internal_bribe, _external_bribe, _pool);
        }
    }

    function increaseGaugeApprovals(address _gauge) external {
        require(msg.sender == emergencyCouncil);
        require(isGauge[_gauge] = true);
        IERC20(base).approve(_gauge, 0);
        IERC20(base).approve(_gauge, type(uint).max);
    }

    function setNewBribe(address _gauge, address _internal, address _external) external {
        require(msg.sender == emergencyCouncil);
        require(isGauge[_gauge] = true);
        internal_bribes[_gauge] = _internal;
        external_bribes[_gauge] = _external;
    }

    function poolsList() external view returns(address[] memory, address[] memory, uint16[] memory){
        address[] memory gaugeList = new address[](pools.length);
        uint16[] memory chainIdList = new uint16[](pools.length);
        for (uint i = 0; i < pools.length; i++) {
            gaugeList[i] = gauges[pools[i]];
            chainIdList[i] = uint16(gaugeChain[gauges[pools[i]]]);
        }

        return (pools, gaugeList, chainIdList);
    }

    function chainGaugesList(uint16 _chainId) external view returns(address[] memory){
        return chainGauges[_chainId];
    }
    
}