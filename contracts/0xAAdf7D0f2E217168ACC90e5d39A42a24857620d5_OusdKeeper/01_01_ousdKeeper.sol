pragma solidity 0.8.15;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract OusdKeeper is KeeperCompatibleInterface {
    address constant ousd_dripper = 0x80C898ae5e56f888365E235CeB8CEa3EB726CB58;
    address constant oeth_vault = 0x39254033945AA2E4809Cc2977E7087BEE48bd7Ab;
    address constant owner = 0xF14BBdf064E3F67f51cd9BD646aE3716aD938FDC;
    uint24 immutable windowStart; // seconds after start of day
    uint24 immutable windowEnd; // seconds after start of day
    uint256 lastRunDay = 0;

    constructor(uint24 windowStart_, uint24 windowEnd_) {
        windowStart = windowStart_;
        windowEnd = windowEnd_;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = _shouldRun();
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        require(_shouldRun());
        // write today, so that we only run once per day
        lastRunDay = (block.timestamp / 86400);

        // Both commands run and do not revert if they fail so that the last run
        // day is still written, and the keepers do not empty their gas running
        // the failing method over and over again.
        ousd_dripper.call(abi.encodeWithSignature("collectAndRebase()"));
        oeth_vault.call(abi.encodeWithSignature("rebase()"));
    }

    function _shouldRun() internal view returns (bool) {
        // Have we run today?
        uint256 day = block.timestamp / 86400;
        if (lastRunDay >= day) {
            return false;
        }

        // Are we in the window?
        uint256 daySeconds = block.timestamp % 86400;
        if (daySeconds < windowStart || daySeconds > windowEnd) {
            return false;
        }

        return true;
    }
}