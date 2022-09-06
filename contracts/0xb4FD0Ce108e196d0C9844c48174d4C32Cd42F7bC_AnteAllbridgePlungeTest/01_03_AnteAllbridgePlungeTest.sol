// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

import "../AnteTest.sol";

/// @title Allbridge doesn't rug on mainnet test
/// @notice Ante test to check if Allbride loses most of it's ETH or something terrible happens (at the time of deployment)

contract AnteAllbridgePlungeTest is AnteTest(" Allbridge mainnet bridge doesn't drop under 15% of its ETH") {
    // https://etherscan.io/address/0xBBbD1BbB4f9b936C3604906D7592A644071dE884
    address public constant allbridgeBridgeAddr = 0xBBbD1BbB4f9b936C3604906D7592A644071dE884;

    // threshold amount for the test to fail
    uint256 public immutable threshold;

    /// @notice percent drop threshold (set to 15%)
    uint256 public constant PERCENT_DROP_THRESHOLD = 15;

    uint256 public immutable etherBalanceAtDeploy;

    constructor() {
        protocolName = "Allbridge";
        testedContracts = [allbridgeBridgeAddr];

        etherBalanceAtDeploy = allbridgeBridgeAddr.balance;

        threshold = etherBalanceAtDeploy * (PERCENT_DROP_THRESHOLD / 100);
    }

    /// @notice test to check balance of eth
    /// @return true if bridge doesn't drop under 15% of the balance at the time of deployment
    function checkTestPasses() external view override returns (bool) {
        return (allbridgeBridgeAddr.balance > threshold);
    }
}