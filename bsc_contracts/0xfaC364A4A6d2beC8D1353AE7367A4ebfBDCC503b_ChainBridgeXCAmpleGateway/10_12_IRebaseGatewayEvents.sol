// SPDX-License-Identifier: GPL-3.0-or-later

interface IRebaseGatewayEvents {
    // Logged on the base chain gateway (ethereum) when rebase report is propagated out
    event XCRebaseReportOut(
        // epoch from the Ampleforth Monetary Policy on the base chain
        uint256 globalAmpleforthEpoch,
        // totalSupply of AMPL ERC-20 contract on the base chain
        uint256 globalAMPLSupply
    );

    // Logged on the satellite chain gateway (tron, acala, near) when bridge reports most recent rebase
    event XCRebaseReportIn(
        // new value coming in from the base chain
        uint256 globalAmpleforthEpoch,
        // new value coming in from the base chain
        uint256 globalAMPLSupply,
        // existing value on the satellite chain
        uint256 recordedGlobalAmpleforthEpoch,
        // existing value on the satellite chain
        uint256 recordedGlobalAMPLSupply
    );
}