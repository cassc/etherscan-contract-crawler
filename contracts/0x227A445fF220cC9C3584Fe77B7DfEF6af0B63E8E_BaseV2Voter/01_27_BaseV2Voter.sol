// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {EIP712, Votes} from "@openzeppelin/contracts/governance/utils/Votes.sol";

import {IBribeV2} from "../interfaces/IBribeV2.sol";
import {IBribeFactory} from "../interfaces/IBribeFactory.sol";
import {IEmissionController} from "../interfaces/IEmissionController.sol";
import {IGauge} from "../interfaces/IGauge.sol";
import {IGaugeVoterV2} from "../interfaces/IGaugeVoterV2.sol";
import {IRegistry} from "../interfaces/IRegistry.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";
import {INFTStaker} from "../interfaces/INFTStaker.sol";
import {VersionedInitializable} from "../proxy/VersionedInitializable.sol";

// import "hardhat/console.sol";

/**
 * This contract is an extension of the BaseV1Voter that was originally written by Andre.
 * This contract allows delegation and captures voting power of a user overtime. This contract
 * is also compatible with openzepplin's Governor contract.
 */
contract BaseV2Voter is
    VersionedInitializable,
    ReentrancyGuard,
    Ownable,
    IGaugeVoterV2
{
    IRegistry public override registry;
    uint256 internal DURATION;
    uint256 public totalWeight; // total voting weight
    address[] public pools; // all pools viable for incentives
    mapping(address => address) public gauges; // pool => gauge
    mapping(address => address) public poolForGauge; // gauge => pool
    mapping(address => address) public bribes; // gauge => bribe
    mapping(address => int256) public weights; // pool => weight
    mapping(address => mapping(address => int256)) public votes; // nft => pool => votes
    mapping(address => address[]) public poolVote; // nft => pools
    mapping(address => uint256) public usedWeights; // nft => total voting weight of user
    mapping(address => bool) public isGauge;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public override attachments;
    mapping(address => uint256) internal supplyIndex;
    mapping(address => uint256) public claimable;
    uint256 internal index;

    modifier onlyGauge() {
        require(isGauge[msg.sender], "not gauge");
        _;
    }

    function initialize(address _registry, address _owner)
        external
        initializer
    {
        registry = IRegistry(_registry);
        DURATION = 14 days; // rewards are released over 14 days
        _transferOwnership(_owner);
    }

    function getRevision() public pure virtual override returns (uint256) {
        return 1;
    }

    function reset() external override {
        _reset(msg.sender);
    }

    function resetFor(address who) external override {
        require(msg.sender == registry.staker(), "not staker contract");
        _reset(who);
    }

    function _reset(address _who) internal {
        address[] storage _poolVote = poolVote[_who];
        uint256 _poolVoteCnt = _poolVote.length;
        int256 _totalWeight = 0;

        for (uint256 i = 0; i < _poolVoteCnt; i++) {
            address _pool = _poolVote[i];
            int256 _votes = votes[_who][_pool];

            if (_votes != 0) {
                _updateFor(gauges[_pool]);
                weights[_pool] -= _votes;
                votes[_who][_pool] -= _votes;
                if (_votes > 0) {
                    IBribeV2(bribes[gauges[_pool]])._withdraw(
                        uint256(_votes),
                        _who
                    );
                    _totalWeight += _votes;
                } else {
                    _totalWeight -= _votes;
                }
                emit Abstained(_who, _votes);
            }
        }
        totalWeight -= uint256(_totalWeight);
        usedWeights[_who] = 0;
        delete poolVote[_who];
    }

    function poke(address _who) external {
        address[] memory _poolVote = poolVote[_who];
        uint256 _poolCnt = _poolVote.length;
        int256[] memory _weights = new int256[](_poolCnt);

        for (uint256 i = 0; i < _poolCnt; i++) {
            _weights[i] = votes[_who][_poolVote[i]];
        }

        _vote(_who, _poolVote, _weights);
    }

    function _vote(
        address _who,
        address[] memory _poolVote,
        int256[] memory _weights
    ) internal {
        _reset(_who);

        uint256 _poolCnt = _poolVote.length;

        INFTStaker staker = INFTStaker(registry.staker());
        int256 _weight = int256(staker.getStakedBalance(_who));
        int256 _totalVoteWeight = 0;
        int256 _totalWeight = 0;
        int256 _usedWeight = 0;

        for (uint256 i = 0; i < _poolCnt; i++) {
            _totalVoteWeight += _weights[i] > 0 ? _weights[i] : -_weights[i];
        }

        for (uint256 i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];

            if (isGauge[_gauge]) {
                int256 _poolWeight = (_weights[i] * _weight) / _totalVoteWeight;
                require(votes[_who][_pool] == 0, "votes = 0");
                require(_poolWeight != 0, "poolweight = 0");
                _updateFor(_gauge);

                poolVote[_who].push(_pool);

                weights[_pool] += _poolWeight;
                votes[_who][_pool] += _poolWeight;
                if (_poolWeight > 0) {
                    IBribeV2(bribes[_gauge])._deposit(
                        uint256(_poolWeight),
                        _who
                    );
                } else {
                    _poolWeight = -_poolWeight;
                }
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                emit Voted(msg.sender, _who, _poolWeight);
            }
        }

        totalWeight += uint256(_totalWeight);
        usedWeights[_who] = uint256(_usedWeight);
    }

    function vote(address[] calldata _poolVote, int256[] calldata _weights)
        external
    {
        require(_poolVote.length == _weights.length, "invalid weights");
        _vote(msg.sender, _poolVote, _weights);
    }

    function toggleWhitelist(address what) external onlyOwner {
        whitelist[what] = !whitelist[what];
        emit Whitelisted(msg.sender, what, whitelist[what]);
    }

    function registerGaugeBribe(
        address _pool,
        address _bribe,
        address _gauge
    ) external onlyOwner returns (address) {
        registry.ensureNotPaused(); // ensure protocol is active

        require(gauges[_pool] == address(0x0), "gauge exists");

        // sanity checks
        require(whitelist[_pool], "pool not whitelisted");
        require(whitelist[_bribe], "bribe factory not whitelisted");
        require(whitelist[_gauge], "gauge factory not whitelisted");

        IERC20(registry.maha()).approve(_gauge, type(uint256).max);
        bribes[_gauge] = _bribe;
        gauges[_pool] = _gauge;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;

        _updateFor(_gauge);
        pools.push(_pool);

        emit GaugeCreated(_gauge, msg.sender, _bribe, _pool);
        return _gauge;
    }

    function updateGaugeBribe(
        address _pool,
        address _newbribe,
        address _newgauge
    ) external onlyOwner {
        registry.ensureNotPaused(); // ensure protocol is active

        require(gauges[_pool] != address(0x0), "gauge not registered");

        // sanity checks
        require(whitelist[_pool], "pool not whitelisted");
        require(whitelist[_newbribe], "bribe factory not whitelisted");
        require(whitelist[_newgauge], "gauge factory not whitelisted");

        address oldgauge = gauges[_pool];

        bribes[oldgauge] = address(0);
        gauges[_pool] = _newgauge;
        poolForGauge[oldgauge] = address(0);
        isGauge[oldgauge] = false;

        bribes[_newgauge] = _newbribe;
        poolForGauge[_newgauge] = _pool;
        isGauge[_newgauge] = true;

        // give allowance to the new gauge
        IERC20(registry.maha()).approve(oldgauge, 0);
        IERC20(registry.maha()).approve(_newgauge, type(uint256).max);

        _updateFor(_newgauge);
        emit GaugeUpdated(_newgauge, msg.sender, _newbribe, _pool);
    }

    function attachStakerToGauge(address account) external override onlyGauge {
        attachments[account] = attachments[account] + 1;
        emit Attach(account, msg.sender);
    }

    function detachStakerFromGauge(address who) external override onlyGauge {
        // prevent subtraction underflow
        if (attachments[who] > 0) attachments[who] = attachments[who] - 1;
        emit Detach(who, msg.sender);
    }

    function length() external view returns (uint256) {
        return pools.length;
    }

    function notifyRewardAmount(uint256 amount) external override {
        require(
            msg.sender == registry.emissionController(),
            "not emission controller"
        );
        uint256 _ratio = (amount * 1e18) / totalWeight; // 1e18 adjustment is removed during claim
        if (_ratio > 0) index += _ratio;
        emit NotifyReward(msg.sender, registry.maha(), amount);
    }

    function updateFor(address[] memory _gauges) external {
        for (uint256 i = 0; i < _gauges.length; i++) {
            _updateFor(_gauges[i]);
        }
    }

    function updateForRange(uint256 start, uint256 end) public {
        for (uint256 i = start; i < end; i++) {
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
        int256 _supplied = weights[_pool];
        if (_supplied > 0) {
            uint256 _supplyIndex = supplyIndex[_gauge];
            uint256 _index = index; // get global index0 for accumulated distro
            supplyIndex[_gauge] = _index; // update _gauge current position to global position
            uint256 _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (_delta > 0) {
                uint256 _share = (uint256(_supplied) * _delta) / 1e18; // add accrued difference for each address
                claimable[_gauge] += _share;
            }
        } else {
            supplyIndex[_gauge] = index; // new users are set to the default global state
        }
    }

    function _distribute(address _gauge) internal nonReentrant {
        if (IEmissionController(registry.emissionController()).callable())
            IEmissionController(registry.emissionController())
                .allocateEmission();

        _updateFor(_gauge);
        uint256 _claimable = claimable[_gauge];

        if (
            _claimable > IGauge(_gauge).left(registry.maha()) &&
            _claimable / DURATION > 0
        ) {
            claimable[_gauge] = 0;
            IGauge(_gauge).notifyRewardAmount(registry.maha(), _claimable);
            emit DistributeReward(msg.sender, _gauge, _claimable);
        }
    }

    function distribute(address _gauge) external override {
        _distribute(_gauge);
    }

    function distribute() external override {
        distribute(0, pools.length);
    }

    function distribute(uint256 start, uint256 finish) public {
        for (uint256 x = start; x < finish; x++) {
            _distribute(gauges[pools[x]]);
        }
    }

    function distribute(address[] memory _gauges) external override {
        for (uint256 x = 0; x < _gauges.length; x++) {
            _distribute(_gauges[x]);
        }
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0, "invalid token code");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "transferFrom failed"
        );
    }
}