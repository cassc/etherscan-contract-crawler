// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OrderedSet.sol";

/**
 * @title RankedSet
 * @dev Ranked data structure using two ordered sets, a mapping of scores to
 * boundary values and counter, a mapping of last ranked scores, and a highest
 * score.
 */
library RankedSet {
    using OrderedSet for OrderedSet.Set;

    struct RankGroup {
        uint256 count;
        uint256 start;
        uint256 end;
    }

    struct Set {
        uint256 highScore;
        mapping(uint256 => RankGroup) rankgroups;
        mapping(uint256 => uint256) scores;
        OrderedSet.Set rankedScores;
        OrderedSet.Set rankedItems;
    }

    /**
     * @dev Add an item at the end of the set
     */
    function add(Set storage set, uint256 item) internal {
        set.rankedItems.append(item);
        set.rankgroups[0].end = item;
        set.rankgroups[0].count += 1;
        if (set.rankgroups[0].start == 0) {
            set.rankgroups[0].start = item;
        }
    }

    /**
     * @dev Remove an item
     */
    function remove(Set storage set, uint256 item) internal {
        uint256 score = set.scores[item];
        delete set.scores[item];

        RankGroup storage rankgroup = set.rankgroups[score];
        if (rankgroup.count > 0) {
            rankgroup.count -= 1;
        }

        if (rankgroup.count == 0) {
            rankgroup.start = 0;
            rankgroup.end = 0;
            if (score == set.highScore) {
                set.highScore = set.rankedScores.next(score);
            }
            if (score > 0) {
                set.rankedScores.remove(score);
            }
        } else {
            if (rankgroup.start == item) {
                rankgroup.start = set.rankedItems.next(item);
            }
            if (rankgroup.end == item) {
                rankgroup.end = set.rankedItems.prev(item);
            }
        }

        set.rankedItems.remove(item);
    }

    /**
     * @dev Returns the head
     */
    function head(Set storage set) internal view returns (uint256) {
        return set.rankedItems._next[0];
    }

    /**
     * @dev Returns the tail
     */
    function tail(Set storage set) internal view returns (uint256) {
        return set.rankedItems._prev[0];
    }

    /**
     * @dev Returns the length
     */
    function length(Set storage set) internal view returns (uint256) {
        return set.rankedItems.count;
    }

    /**
     * @dev Returns the next value
     */
    function next(Set storage set, uint256 _value) internal view returns (uint256) {
        return set.rankedItems._next[_value];
    }

    /**
     * @dev Returns the previous value
     */
    function prev(Set storage set, uint256 _value) internal view returns (uint256) {
        return set.rankedItems._prev[_value];
    }

    /**
     * @dev Returns true if the value is in the set
     */
    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set.rankedItems._next[0] == value ||
               set.rankedItems._next[value] != 0 ||
               set.rankedItems._prev[value] != 0;
    }

    /**
     * @dev Returns a value's score
     */
    function scoreOf(Set storage set, uint256 value) internal view returns (uint256) {
        return set.scores[value];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Set storage set) internal view returns (uint256[] memory) {
        uint256[] memory _values = new uint256[](set.rankedItems.count);
        uint256 value = set.rankedItems._next[0];
        uint256 i = 0;
        while (value != 0) {
            _values[i] = value;
            value = set.rankedItems._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Return an array with n values in the set, starting after "from"
     */
    function valuesFromN(Set storage set, uint256 from, uint256 n) internal view returns (uint256[] memory) {
        uint256[] memory _values = new uint256[](n);
        uint256 value = set.rankedItems._next[from];
        uint256 i = 0;
        while (i < n) {
            _values[i] = value;
            value = set.rankedItems._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Rank new score
     */
    function rankScore(Set storage set, uint256 item, uint256 newScore) internal {
        RankGroup storage rankgroup = set.rankgroups[newScore];

        if (newScore > set.highScore) {
            remove(set, item);
            rankgroup.start = item;
            set.highScore = newScore;
            set.rankedItems.add(item);
            set.rankedScores.add(newScore);
        } else {
            uint256 score = set.scores[item];
            uint256 prevScore = set.rankedScores.prev(score);

            if (set.rankgroups[score].count == 1) {
                score = set.rankedScores.next(score);
            }

            remove(set, item);

            while (prevScore > 0 && newScore > prevScore) {
                prevScore = set.rankedScores.prev(prevScore);
            }

            set.rankedItems.insert(
                set.rankgroups[prevScore].end,
                item,
                set.rankgroups[set.rankedScores.next(prevScore)].start
            );

            if (rankgroup.count == 0) {
                set.rankedScores.insert(prevScore, newScore, score);
                rankgroup.start = item;
            }
        }

        rankgroup.end = item;
        rankgroup.count += 1;

        set.scores[item] = newScore;
    }
}