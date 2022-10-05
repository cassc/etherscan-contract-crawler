// SPDX-License-Identifier: GPL-3.0-or-later

interface ITransferGatewayEvents {
    // Logged on source chain when cross-chain transfer is initiated
    event XCTransferOut(
        // user sending funds
        address indexed sender,
        // user receiving funds, set to address(0) if unavailable
        address indexed recipientInTargetChain,
        // amount to be locked/burnt
        uint256 amount,
        // existing value on the current source chain
        uint256 recordedGlobalAMPLSupply
    );

    // Logged on target chain when cross-chain transfer is completed
    event XCTransferIn(
        // user sending funds, set to address(0) if unavailable
        address indexed senderInSourceChain,
        // user receiving funds
        address indexed recipient,
        // value on remote chain when transaction was initiated
        uint256 globalAMPLSupply,
        // amount to be unlocked/mint
        uint256 amount,
        // existing value on the current target chain
        uint256 recordedGlobalAMPLSupply
    );
}