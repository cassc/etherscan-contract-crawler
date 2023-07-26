// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { NonblockingLzAppUpgradeable } from"@layerzerolabs/solidity-examples/contracts/contracts-upgradable/lzApp/NonblockingLzAppUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PendleVoteManagerBaseUpg } from "./PendleVoteManagerBaseUpg.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../interfaces/IPendleStaking.sol";
import "../libraries/math/Math.sol";
import "../interfaces/IVLPenpie.sol";
import "../interfaces/IPenpieBribeManager.sol";

/// @title PendleVoteManager Base contract, which include common functions for pendle voter on Ethereum and side chains
/// @notice Pendle Vote manager is designed with cross chain implication. vePendle only lives on main chain, but vlPNP which controls 
///         Penpie's vePendle voting power live on both Ethereum and Arbitrum, vlPNP voting status has to be cast back to Ethereum from Arbitrum.
///         
///         Bribe is designed as only lives on 1 chain, determined by which chain the corresponding liqudity is host on Pendle, for example, bribe for 
///         GLP will be on Arbitrum while bribe for anrkETH, stETH will be on Ethereum.
///
///         The market information PoolInfos stored HAS TO BE exact the same across all chains, except the bribe only lives on the chain
///         Where the underlying liquidity on pendle (ex: on arb for GLP, on eth for anrkETH) is host. The bribe address should be zero if for chains
///         That underlying liquidity is not on that chain. (ex: GLP will have pool on both Arbitrum and Ethereum, but arb pool will have bribe while eth pool bribe address should be zero)
///
/// @author Penpie Team
abstract contract PendleVoteManagerBaseUpg is NonblockingLzAppUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;
    
    /* ============ Structs ============ */

    struct Pool {       
        address market;  // the pendle market
        uint256 totalVoteInVlPenpie;
        uint256 chainId; // layer zero chainId (https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids) where bribe lives
        bool isActive;
    }

    struct UserVote {
        int256 weight;
        uint16 pid;
    }

    struct LzParams {
        address payable refundAddress;
        address zroPaymentAddress;
        bytes adapterParams;
    }

    /* ============ State Variables ============ */

    IPendleStaking public pendleStaking; //TODO: currently only used for harvesting vePendle from Pendle
    address public vlPenpie; // vlPenpie address
    address public bribeManager;

    Pool[] public poolInfos;   // IMPORTANT!!! Pool setup has to be exact the same order acrros all chains, this is an important assumption!!!
    mapping(address => uint256) public marketToPid;

    mapping(address => uint256) public userTotalVotedInVlPenpie; // unit = locked Penpie
    mapping(address => mapping(address => uint256)) public userVotedForPoolInVlPenpie; // unit = locked Penpie, key: [_user][_market]

    uint256 public totalVlPenpieInVote;
    uint256 public lastCastTime;

    uint256[50] private __gap;

    /* ============ Events ============ */

    event AddPool(address indexed market, uint256 _pid);
    event DeactivatePool(address indexed market, uint256 _pid);
    event VoteCasted(address indexed caster, uint256 timestamp);
    event Voted(uint256 indexed _epoch, address indexed _user, address _market, uint256 indexed _pid, int256 _weight);

    /* ============ Errors ============ */

    error PoolNotActive();
    error NotEnoughVote();
    error OutOfPoolIndex();
    error ZeroAddressError();     
    error OnlyBribeManager();                                                                  

    /* ============ Constructor ============ */

    function __PendleVoteManagerBaseUpg_init(IPendleStaking _pendleStaking, address _vlPenpie, address _endpoint) internal onlyInitializing {
        __NonblockingLzAppUpgradeable_init(_endpoint);
        __ReentrancyGuard_init();
        __Pausable_init();
        pendleStaking = _pendleStaking;
        vlPenpie = _vlPenpie;
    }
    
    modifier onlyBribeManager() {
        if (msg.sender != bribeManager) revert OnlyBribeManager();
        _;
    }

    /* ============ External Getters ============ */

    function isPoolActive(uint256 _pid) external view returns (bool) {
        return poolInfos[_pid].isActive;
    }

    function getUserVotable(address _user) public view returns (uint256) {
        return IVLPenpie(vlPenpie).getUserTotalLocked(_user);
    }

    function getUserVoteForPoolsInVlPenpie(
        address[] calldata markets,
        address _user
    ) public view returns (uint256[] memory votes) {
        uint256 length = markets.length;
        votes = new uint256[](length);
        for (uint256 i; i < length; i++) {
            votes[i] = userVotedForPoolInVlPenpie[_user][markets[i]];
        }
    }

    function getPoolsLength() external view returns (uint256) {
        return poolInfos.length;
    }

    function getVlPenpieVoteForPools(
        uint256[] calldata _pids
    ) public view returns (uint256[] memory vlPenpieVotes) {
        uint256 length = _pids.length;
        vlPenpieVotes = new uint256[](length);
        for (uint256 i; i < length; i++) {
            Pool storage pool = poolInfos[_pids[i]];
            vlPenpieVotes[i] = pool.totalVoteInVlPenpie;
        }
    }

    /* ============ External Getters For cross chain ============ */

    function estimateVoteFee(uint16 _dstChainId, address _user, UserVote[] memory _userVotes, bool _payInZRO, bytes calldata _adapterParam) public view returns (uint nativeFee, uint zroFee) {
        
        return lzEndpoint.estimateFees(_dstChainId, _user, encodeVote(_user, _userVotes), _payInZRO, _adapterParam);
    }

    function encodeVote(address user, UserVote[] memory userVotes) public pure returns (bytes memory) {
        bytes memory buffer = abi.encodePacked(user, uint16(userVotes.length));
        
        for(uint i = 0; i < userVotes.length; i++) {
            buffer = abi.encodePacked(buffer, userVotes[i].pid, userVotes[i].weight);
        }
        
        return buffer;
    }

    function decodeVote(bytes memory data) public pure returns (address user, UserVote[] memory userVotes) {
        uint256 offset = 0;
        user = _readAddress(data, offset);
        offset += 20;
        uint256 userVotesLength = uint256(_readUint16(data, offset));
        offset += 2;
        userVotes = new UserVote[](userVotesLength);
        for(uint i = 0; i < userVotesLength; i++) {
            UserVote memory uv;
            uv.pid = _readUint16(data, offset);
            offset += 2;
            uv.weight = int256(_readInt256(data, offset));
            offset += 32;
            userVotes[i] = uv;
        }
        return (user, userVotes);
    }

    /* ============ External Functions ============ */

    function vote(UserVote[] memory _votes) external virtual nonReentrant whenNotPaused {
        _updateVoteAndCheck(msg.sender, _votes);
        if (userTotalVotedInVlPenpie[msg.sender] > getUserVotable(msg.sender)) revert NotEnoughVote();
    }

    /* ============ Internal Functions ============ */

    function _updateVoteAndCheck(address _user, UserVote[] memory _userVotes) internal {
        uint256 length = _userVotes.length;
        int256 totalUserVote;

        for (uint256 i; i < length; i++) {
            if (_userVotes[i].pid >= poolInfos.length) revert PoolNotActive();
            Pool storage pool = poolInfos[_userVotes[i].pid];

            int256 weight = _userVotes[i].weight;
            totalUserVote += weight;

            if (weight != 0) {
                if (weight > 0) {
                    uint256 absVal = uint256(weight);
                    pool.totalVoteInVlPenpie += absVal;
                    userVotedForPoolInVlPenpie[_user][pool.market] += absVal;
                } else {
                    uint256 absVal = uint256(-weight);
                    pool.totalVoteInVlPenpie -= absVal;
                    userVotedForPoolInVlPenpie[_user][pool.market] -= absVal;
                }
            }

            _afterVoteUpdate(_user, pool.market, _userVotes[i].pid, weight);
        }
        
        // update user's total vote and all vlPNP vote
        if (totalUserVote > 0) {
            userTotalVotedInVlPenpie[_user] += uint256(totalUserVote);
            totalVlPenpieInVote += uint256(totalUserVote);
        } else {
            userTotalVotedInVlPenpie[_user] -= uint256(-totalUserVote);
            totalVlPenpieInVote -= uint256(-totalUserVote);
        }
    }

    // for sub inheretence to add customized logic
    function _afterVoteUpdate(address _user, address _market, uint256 _pid, int256 _weight) internal virtual {
        uint256 epoch = IPenpieBribeManager(bribeManager).exactCurrentEpoch();
        emit Voted(epoch, _user, _market, _pid, _weight);
    }

    function _readAddress(bytes memory data, uint256 offset) private pure returns (address result) {
        uint160 num = 0;
        for (uint i = 0; i < 20; i++) {
            num |= uint160(uint256(uint8(data[offset + i]))) << (8 * (19 - i));
        }
        return address(num);
    }

    function _readUint16(bytes memory data, uint256 offset) private pure returns (uint16 result) {
        for (uint i = 0; i < 2; i++) {
            result |= uint16(uint256(uint8(data[offset + i])) << (8 * (1 - i)));
        }
    }

    function _readInt256(bytes memory data, uint256 offset) private pure returns (int256 result) {
        for (uint i = 0; i < 32; i++) {
            result |= int256(uint256(uint8(data[offset + i])) << (8 * (31 - i)));
        }
    }    

    /* ============ Admin Functions ============ */

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

    function setBribeManager(address _bribeManager) external onlyOwner {
        bribeManager = _bribeManager;
    }

    function addPool(
        address _market,
        uint16 _chainId
    ) external onlyBribeManager {
        if (_market == address(0)) revert ZeroAddressError();
        Pool memory pool = Pool({
            market: _market,
            totalVoteInVlPenpie: 0,
            chainId: _chainId,
            isActive: true
        });
        poolInfos.push(pool);
        
        marketToPid[_market] = poolInfos.length -1 ;
        
        emit AddPool(_market, poolInfos.length - 1);
    }

    function removePool(uint256 _index) external onlyBribeManager {
        if (_index >= poolInfos.length) revert OutOfPoolIndex();
        poolInfos[_index].isActive = false;

        emit DeactivatePool(poolInfos[_index].market, _index);
    }
}