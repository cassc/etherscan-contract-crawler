// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

// modified https://github.com/MihanixA/SummingPriorityQueue/blob/master/contracts/SummingPriorityQueue.sol
library FSushiBarPriorityQueue {
    error QueueEmpty();

    struct Snapshot {
        uint256 assets;
        uint256 power;
        uint256 shares;
    }

    struct Heap {
        uint256[] timestamps;
        mapping(uint256 => Snapshot) snapshots;
    }

    modifier notEmpty(Heap storage self) {
        if (self.timestamps.length == 1) revert QueueEmpty();
        _;
    }

    function top(Heap storage self) internal view notEmpty(self) returns (uint256) {
        return self.timestamps[1];
    }

    /**
     * @dev average time complexity: O(log n), worst-case time complexity: O(n)
     */
    function enqueued(Heap storage self, uint256 timestamp)
        internal
        view
        returns (
            uint256 assets,
            uint256 power,
            uint256 shares
        )
    {
        return _dfs(self, timestamp, 1);
    }

    function _dfs(
        Heap storage self,
        uint256 timestamp,
        uint256 i
    )
        private
        view
        returns (
            uint256 assets,
            uint256 power,
            uint256 shares
        )
    {
        if (i >= self.timestamps.length) return (0, 0, 0);
        if (self.timestamps[i] > timestamp) return (0, 0, 0);

        Snapshot memory snapshot = self.snapshots[self.timestamps[i]];
        assets = snapshot.assets;
        power = snapshot.power;
        shares = snapshot.shares;

        (uint256 assetsLeft, uint256 powerLeft, uint256 sharesLeft) = _dfs(self, timestamp, i * 2);
        (uint256 assetsRight, uint256 powerRight, uint256 sharesRight) = _dfs(self, timestamp, i * 2 + 1);
        return (assets + assetsLeft + assetsRight, power + powerLeft + powerRight, shares + sharesLeft + sharesRight);
    }

    function enqueue(
        Heap storage self,
        uint256 timestamp,
        uint256 assets,
        uint256 power,
        uint256 shares
    ) internal {
        if (self.timestamps.length == 0) self.timestamps.push(0); // initialize

        self.timestamps.push(timestamp);
        uint256 i = self.timestamps.length - 1;

        while (i > 1 && self.timestamps[i / 2] > self.timestamps[i]) {
            (self.timestamps[i / 2], self.timestamps[i]) = (timestamp, self.timestamps[i / 2]);
            i /= 2;
        }

        self.snapshots[timestamp] = Snapshot(assets, power, shares);
    }

    function dequeue(Heap storage self)
        internal
        notEmpty(self)
        returns (
            uint256 timestamp,
            uint256 assets,
            uint256 power,
            uint256 shares
        )
    {
        if (self.timestamps.length == 1) revert QueueEmpty();

        timestamp = top(self);
        self.timestamps[1] = self.timestamps[self.timestamps.length - 1];
        self.timestamps.pop();

        uint256 i = 1;

        while (i * 2 < self.timestamps.length) {
            uint256 j = i * 2;

            if (j + 1 < self.timestamps.length)
                if (self.timestamps[j] > self.timestamps[j + 1]) j++;

            if (self.timestamps[i] < self.timestamps[j]) break;

            (self.timestamps[i], self.timestamps[j]) = (self.timestamps[j], self.timestamps[i]);
            i = j;
        }

        Snapshot memory snapshot = self.snapshots[timestamp];
        delete self.snapshots[timestamp];

        return (timestamp, snapshot.assets, snapshot.power, snapshot.shares);
    }

    function drain(Heap storage self, uint256 timestamp)
        internal
        returns (
            uint256 assetsDequeued,
            uint256 powerDequeued,
            uint256 sharesDequeued
        )
    {
        while (self.timestamps.length > 1 && top(self) < timestamp) {
            (, uint256 assets, uint256 power, uint256 shares) = dequeue(self);
            assetsDequeued += assets;
            powerDequeued += power;
            sharesDequeued += shares;
        }
    }
}