// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

library EncodeSolanaDlnMessage {
    bytes8 public constant CLAIM_DESCRIMINATOR = 0x5951b44f8e9042fb;
    bytes8 public constant CANCEL_DESCRIMINATOR = 0x13617eeecc8d454c;

    function encodeInitWalletIfNeededInstruction(
        bytes32 _actionBeneficiary,
        bytes32 _orderGiveTokenAddress,
        uint64 _reward
    ) internal pure returns (bytes memory encodedData) {
        encodedData = abi.encodePacked(
            // Index 0: Field (8): Reward 1:
            // convert to Little Endian
            reverse(_reward),
            // Index 8: Const (86): "01f01d1f0000000000000000000101000000000000000100000000000000010000008c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f8590300000000000000000000002000000000000000"
            hex"01f01d1f0000000000000000000101000000000000000100000000000000010000008c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f8590300000000000000000000002000000000000000",
            // Index 94: Field (32): Action Beneficiary
            _actionBeneficiary,
            // Index 126: Const (56): "00000000200000000000000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9000000002000000000000000"
            hex"00000000200000000000000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9000000002000000000000000",
            // Index 182: Field (32): Give Token Address
            _orderGiveTokenAddress,
            // Index 214: Const (110): "00008c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f85906000000000000001968562fef0aab1b1d8f99d44306595cd4ba41d7cc899c007a774d23ad702ff601019f3d96f657370bf1dbb3313efba51ea7a08296ac33d77b949e1b62d538db37f20001"
            hex"00008c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f85906000000000000001968562fef0aab1b1d8f99d44306595cd4ba41d7cc899c007a774d23ad702ff601019f3d96f657370bf1dbb3313efba51ea7a08296ac33d77b949e1b62d538db37f20001",
            // Index 324: Field (32): Action Beneficiary
            _actionBeneficiary,
            // Index 356: Const (2): "0000"
            hex"0000",
            // Index 358: Field (32): Give Token Address
            _orderGiveTokenAddress,
            // Index 390: Const (79): "00000000000000000000000000000000000000000000000000000000000000000000000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a90000010000000000000001"
            hex"00000000000000000000000000000000000000000000000000000000000000000000000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a90000010000000000000001"
        );
    }

    function encodeClaimUnlockInstruction(
        uint256 _takeChainId,
        bytes32 _srcProgramId,
        bytes32 _actionBeneficiary,
        bytes32 _orderGiveTokenAddress,
        bytes32 _orderId,
        uint64 _reward2
    ) internal pure returns (bytes memory encodedClaimData) {
        return
            _encodeCall(
                _takeChainId,
                _srcProgramId,
                _actionBeneficiary,
                _orderGiveTokenAddress,
                _orderId,
                _reward2,
                CLAIM_DESCRIMINATOR
            );
    }

    function encodeClaimCancelInstruction(
        uint256 _takeChainId,
        bytes32 _srcProgramId,
        bytes32 _actionBeneficiary,
        bytes32 _orderGiveTokenAddress,
        bytes32 _orderId,
        uint64 _reward2
    ) internal pure returns (bytes memory encodedClaimData) {
        return
            _encodeCall(
                _takeChainId,
                _srcProgramId,
                _actionBeneficiary,
                _orderGiveTokenAddress,
                _orderId,
                _reward2,
                CANCEL_DESCRIMINATOR
            );
    }

    function _encodeCall(
        uint256 _takeChainId,
        bytes32 _srcProgramId,
        bytes32 _actionBeneficiary,
        bytes32 _orderGiveTokenAddress,
        bytes32 _orderId,
        uint64 _reward2,
        bytes8 _discriminator
    ) private pure returns (bytes memory encodedData) {
        {
            encodedData = abi.encodePacked(
                // Index 469: Field (8): Reward 2:
                // convert to Little Endian
                reverse(_reward2),
                // Index 477: Const (26): "0000000000010700000000000000020000000000000001000000"
                hex"0000000000010700000000000000020000000000000001000000",
                // Index 503: Field (32): Program Id
                _srcProgramId,
                // Index 535: Const (38): "0100000000000000000000000500000000000000535441544500030000000000000001000000"
                hex"0100000000000000000000000500000000000000535441544500030000000000000001000000",
                // Index 573: Field (32): Program Id
                _srcProgramId,
                // Index 605: Const (43): "0100000000000000000000000a00000000000000464545204c454447455200040000000000000001000000"
                hex"0100000000000000000000000a00000000000000464545204c454447455200040000000000000001000000",
                // Index 648: Field (32): Program Id
                _srcProgramId,
                // Index 680: Const (49): "02000000000000000000000011000000000000004645455f4c45444745525f57414c4c4554000000002000000000000000"
                hex"02000000000000000000000011000000000000004645455f4c45444745525f57414c4c4554000000002000000000000000",
                // Index 729: Field (32): Give Token Address
                _orderGiveTokenAddress,
                // Index 761: Const (13): "00060000000000000001000000"
                hex"00060000000000000001000000",
                // Index 774: Field (32): Program Id
                _srcProgramId,
                // Index 806: Const (48): "0200000000000000000000001000000000000000474956455f4f524445525f5354415445000000002000000000000000"
                hex"0200000000000000000000001000000000000000474956455f4f524445525f5354415445000000002000000000000000",
                // Index 854: Field (32): Order Id
                _orderId,
                // Index 886: Const (65): "000700000000000000010000008c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f8590300000000000000000000002000000000000000"
                hex"000700000000000000010000008c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f8590300000000000000000000002000000000000000",
                // Index 951: Field (32): Action Beneficiary
                _actionBeneficiary,
                // Index 983: Const (56): "00000000200000000000000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9000000002000000000000000"
                hex"00000000200000000000000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9000000002000000000000000",
                 // Index 1039: Field (32): Give Token Address
                _orderGiveTokenAddress,
                // Index 1071: Const (13): "00090000000000000001000000"
                hex"00090000000000000001000000",
                 // Index 1084: Field (32): Program Id
                _srcProgramId
            );
        }
        {
            encodedData = abi.encodePacked(
                encodedData,
                // Index 1116: Const (49): "0200000000000000000000001100000000000000474956455f4f524445525f57414c4c4554000000002000000000000000"
                hex"0200000000000000000000001100000000000000474956455f4f524445525f57414c4c4554000000002000000000000000",
                // Index 1165: Field (32): Order Id
                _orderId,
                // Index 1197: Const (13): "000b0000000000000001000000"
                hex"000b0000000000000001000000",
                // Index 1210: Field (32): Program Id
                _srcProgramId,
                // Index 1242: Const (56): "0200000000000000000000001800000000000000415554484f52495a45445f4e41544956455f53454e444552000000002000000000000000"
                hex"0200000000000000000000001800000000000000415554484f52495a45445f4e41544956455f53454e444552000000002000000000000000",
                // Index 1298: Field (32): Take Chain Id
                _takeChainId,
                // Index 1330: Const (2): "0000"
                hex"0000",
                // Index 1332: Field (32): Program Id
                _srcProgramId,
                // Index 1364: Const (280): "0d0000000000000062584959deb8a728a91cebdc187b545d920479265052145f31fb80c73fac5aea00001968562fef0aab1b1d8f99d44306595cd4ba41d7cc899c007a774d23ad702ff60101980176896e24d940ee6f0a89d0020e1cd53aa3d17be42270bb39223f6ed75c6300018c6ecc336484fb8f32871d3c1656d832cc86eb2465048fea348cde76ae57233100014026e8772b7640ce6fb9fd348473f43df344e3dcd89a43c93db81ee6efe08e67000106a7d517187bd16635dad40455fdc2c0c124c68f215675a5dbbacb5f080000000000107fe6a33e564217c5773c604a479581564c5e4c12465d65c9374ee2190f5ee400019f3d96f657370bf1dbb3313efba51ea7a08296ac33d77b949e1b62d538db37f20001"
                hex"0d0000000000000062584959deb8a728a91cebdc187b545d920479265052145f31fb80c73fac5aea00001968562fef0aab1b1d8f99d44306595cd4ba41d7cc899c007a774d23ad702ff60101980176896e24d940ee6f0a89d0020e1cd53aa3d17be42270bb39223f6ed75c6300018c6ecc336484fb8f32871d3c1656d832cc86eb2465048fea348cde76ae57233100014026e8772b7640ce6fb9fd348473f43df344e3dcd89a43c93db81ee6efe08e67000106a7d517187bd16635dad40455fdc2c0c124c68f215675a5dbbacb5f080000000000107fe6a33e564217c5773c604a479581564c5e4c12465d65c9374ee2190f5ee400019f3d96f657370bf1dbb3313efba51ea7a08296ac33d77b949e1b62d538db37f20001",
                // Index 1644: Field (32): Action Beneficiary
                _actionBeneficiary,
                // Index 1676: Const (36): "00011507b8f891ebbfc57577d4d2e6a2b52dc0a744eba2be503e686d0d07d19e6ec70001"
                hex"00011507b8f891ebbfc57577d4d2e6a2b52dc0a744eba2be503e686d0d07d19e6ec70001",
                // Index 1712: Field (32): Give Token Address
                _orderGiveTokenAddress,
                // Index 1744: Const (78): "0000efe9c4afa6dc798a27b0c18e3cf0b76ad3fe8cc93764f6cb3112f9397f2cd1c6000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a900002800000000000000"
                hex"0000efe9c4afa6dc798a27b0c18e3cf0b76ad3fe8cc93764f6cb3112f9397f2cd1c6000006ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a900002800000000000000",
                // Index 1822: Field (8): Discriminator
                _discriminator,
                // Index 1830: Field (32): Order Id
                _orderId
            );
        }
        return encodedData;
    }

    function reverse(uint64 input) private pure returns (uint64 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) | ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) | ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }
}