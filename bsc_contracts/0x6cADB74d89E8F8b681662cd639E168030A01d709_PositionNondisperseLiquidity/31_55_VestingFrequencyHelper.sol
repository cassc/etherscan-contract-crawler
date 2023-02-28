library VestingFrequencyHelper {
    enum Frequency {
        Daily, // 1 days
        Weekly, // 7 days
        Monthly, // 30 days
        Bimonthly, // 2 months
        Quarterly, // 3 months
        Biannually // 6 months
    }

    function toTimestamp(Frequency _freq) internal view returns (uint256) {
        if (_freq == Frequency.Daily) {
            return block.timestamp + 86400;
        } else if (_freq == Frequency.Weekly) {
            return block.timestamp + 604800;
        } else if (_freq == Frequency.Monthly) {
            return block.timestamp + 2592000;
        } else if (_freq == Frequency.Bimonthly) {
            return block.timestamp + 5184000;
        } else if (_freq == Frequency.Quarterly) {
            return block.timestamp + 7776000;
        } else if (_freq == Frequency.Biannually) {
            return block.timestamp + 182 days;
        }
        return 0;
    }

}