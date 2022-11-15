// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WorldCupVote is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable
{
    using IterableMapping for IterableMapping.Map;
    enum MatchStatus {
        init,
        voting,
        finshed
    }

    enum VoteResult {
        draw,
        poolA_win,
        poolB_win
    }
    struct MatchRecord {
        uint256 startVoteTime;
        uint256 endVoteTime;
        MatchStatus status;
    }

    address private PEX_TOKEN_ADDRESS;
    uint256 public VOTE_FEE;
    mapping(uint16 => IterableMapping.Map) private PoolA;
    mapping(uint16 => IterableMapping.Map) private PoolB;
    mapping(uint16 => uint256) private PoolAShare;
    mapping(uint16 => uint256) private PoolBShare;
    mapping(uint16 => MatchRecord) public MatchRecordMap;
    mapping(address => uint256) public rank;
    mapping(uint16 => uint256) public participants;
    uint16[] private matchIdList;

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        VOTE_FEE = 10 ether;
    }

    function setAddress(address tokenAddr) external onlyOwner {
        PEX_TOKEN_ADDRESS = tokenAddr;
    }

    function getMatchIdList() external view returns (uint16[] memory list) {
        return matchIdList;
    }

    function getPoolRatioById(uint16 id)
        external
        view
        returns (uint256[2] memory list)
    {
        list[0] = PoolAShare[id];
        list[1] = PoolBShare[id];
        return list;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function createMatch(
        uint16 id,
        uint256 startVoteTime,
        uint256 endVoteTime
    ) external onlyOwner {
        require(MatchRecordMap[id].status == MatchStatus.init, "id exists");

        MatchRecord memory t;
        t.status = MatchStatus.voting;
        t.startVoteTime = startVoteTime;
        t.endVoteTime = endVoteTime;
        MatchRecordMap[id] = t;
        matchIdList.push(id);
    }

    function deleteMatch(uint16 id) external onlyOwner {
        delete MatchRecordMap[id];

        uint256 idx;
        while(matchIdList[idx] != id) {
            idx++;
        }
        matchIdList[idx] = matchIdList[matchIdList.length - 1];
        matchIdList.pop();
    }

    event Rank(address indexed userAddr, uint256 score);

    function setVoteResult(uint16 id, VoteResult value) external onlyOwner {
        require(
            MatchRecordMap[id].status == MatchStatus.voting,
            "Match is not available"
        );

        require(
            block.timestamp >= MatchRecordMap[id].endVoteTime,
            "can not vote"
        );
        if (value == VoteResult.draw) {
            for (uint256 i = 0; i < PoolA[id].size(); i++) {
                uint256 awardVol = VOTE_FEE * PoolA[id].get(PoolA[id].getKeyAtIndex(i));
                IERC20(PEX_TOKEN_ADDRESS).transfer(
                    PoolA[id].getKeyAtIndex(i),
                    awardVol
                );
                emit BetResult(id, PoolA[id].getKeyAtIndex(i), awardVol);
            }

            for (uint256 i = 0; i < PoolB[id].size(); i++) {
                uint256 awardVol = VOTE_FEE * PoolB[id].get(PoolB[id].getKeyAtIndex(i));
                IERC20(PEX_TOKEN_ADDRESS).transfer(
                    PoolB[id].getKeyAtIndex(i),
                    awardVol
                );
                emit BetResult(id, PoolB[id].getKeyAtIndex(i), awardVol);
            }
        } else if (value == VoteResult.poolA_win) {
            for (uint256 i = 0; i < PoolA[id].size(); i++) {
                uint256 awardVol;
                awardVol =
                    (((PoolAShare[id] + PoolBShare[id]) * VOTE_FEE) /
                        PoolAShare[id]) *
                    PoolA[id].get(PoolA[id].getKeyAtIndex(i));
                IERC20(PEX_TOKEN_ADDRESS).transfer(
                    PoolA[id].getKeyAtIndex(i),
                    awardVol
                );

                rank[PoolA[id].getKeyAtIndex(i)] =
                    rank[PoolA[id].getKeyAtIndex(i)] +
                    PoolA[id].get(PoolA[id].getKeyAtIndex(i));
                emit Rank(
                    PoolA[id].getKeyAtIndex(i),
                    rank[PoolA[id].getKeyAtIndex(i)] +
                        PoolA[id].get(PoolA[id].getKeyAtIndex(i))
                );
                emit BetResult(id, PoolA[id].getKeyAtIndex(i), awardVol);
            }
        } else if (value == VoteResult.poolB_win) {
            for (uint256 i = 0; i < PoolB[id].size(); i++) {
                uint256 awardVol;
                awardVol =
                    (((PoolAShare[id] + PoolBShare[id]) * VOTE_FEE) /
                        PoolBShare[id]) *
                    PoolB[id].get(PoolB[id].getKeyAtIndex(i));
                IERC20(PEX_TOKEN_ADDRESS).transfer(
                    PoolB[id].getKeyAtIndex(i),
                    awardVol
                );

                rank[PoolB[id].getKeyAtIndex(i)] =
                    rank[PoolB[id].getKeyAtIndex(i)] +
                    PoolB[id].get(PoolB[id].getKeyAtIndex(i));
                emit Rank(
                    PoolB[id].getKeyAtIndex(i),
                    rank[PoolB[id].getKeyAtIndex(i)] +
                        PoolB[id].get(PoolB[id].getKeyAtIndex(i))
                );
                emit BetResult(id, PoolB[id].getKeyAtIndex(i), awardVol);
            }
        }
        MatchRecordMap[id].status = MatchStatus.finshed;
    }

    event BetResult(uint16 indexed _id, address indexed _addr, uint256 _amount);

    function vote(
        uint16 id,
        bool isPoolA,
        uint8 copies
    ) external {
        require(
            block.timestamp >= MatchRecordMap[id].startVoteTime &&
                block.timestamp <= MatchRecordMap[id].endVoteTime,
            "can not vote"
        );

        require(copies >= 1 && copies <= 100, "copies limit");

        require(
            MatchRecordMap[id].status == MatchStatus.voting,
            "Match is not available"
        );

        IERC20(PEX_TOKEN_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            VOTE_FEE * copies
        );

        if (PoolA[id].get(msg.sender) == 0 && PoolB[id].get(msg.sender) == 0) {
            participants[id]++;
        }

        if (isPoolA) {
            uint256 t;
            t = PoolA[id].get(msg.sender);
            PoolA[id].set(msg.sender, t + copies);
            PoolAShare[id] = PoolAShare[id] + copies;
        } else {
            uint256 t;
            t = PoolB[id].get(msg.sender);
            PoolB[id].set(msg.sender, t + copies);
            PoolBShare[id] = PoolBShare[id] + copies;
        }

        emit BetHistory(id, msg.sender, isPoolA, copies, block.timestamp);
    }

    event BetHistory(uint16 indexed _id, address indexed _addr, bool _isPoolA, uint8 _copies, uint _timestamp);
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}