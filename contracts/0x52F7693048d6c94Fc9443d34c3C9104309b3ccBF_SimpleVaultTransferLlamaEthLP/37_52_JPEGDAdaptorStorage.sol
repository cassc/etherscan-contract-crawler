// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

library JPEGDAdaptorStorage {
    address internal constant JPEG =
        address(0xE80C0cd204D654CEbe8dd64A4857cAb6Be8345a3);
    address internal constant PETH =
        address(0x836A808d4828586A69364065A1e064609F5078c7);
    address internal constant CURVE_PETH_POOL =
        address(0x9848482da3Ee3076165ce6497eDA906E66bB85C5);
    address internal constant PETH_VAULT =
        address(0x56D1b6Ac326e152C9fAad749F1F4f9737a049d46);
    address internal constant PUSD =
        address(0x466a756E9A7401B5e2444a3fCB3c2C12FBEa0a54);
    address internal constant CURVE_PUSD_POOL =
        address(0x8EE017541375F6Bcd802ba119bdDC94dad6911A1);
    address internal constant PUSD_VAULT =
        address(0xF6Cbf5e56a8575797069c7A7FBED218aDF17e3b2);
    address internal constant TRI_CRYPTO_POOL =
        address(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46);
    address internal constant LP_FARMING =
        address(0xb271d2C9e693dde033d97f8A3C9911781329E4CA);

    int128 internal constant STABLE_PETH_INDEX = 1;
    int128 internal constant STABLE_ETH_INDEX = 0;
    int128 internal constant STABLE_PUSD_INDEX = 1;
    int128 internal constant STABLE_USDT_INDEX = 3;
    int128 internal constant TRI_WETH_INDEX = 2;
    int128 internal constant TRI_USDT_INDEX = 0;

    uint256 internal constant CURVE_BASIS = 10000000000;
    uint256 internal constant CURVE_FEE = 4000000;
    uint16 constant BASIS_POINTS = 10000;

    struct Layout {
        uint256 cumulativeJPEGPerShard;
        uint256 accruedJPEGFees;
        mapping(address account => uint256 amount) userJPEGYield;
        mapping(address account => uint256 amount) jpegDeductionsPerShard;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('insrt.contracts.storage.adaptors.JPEGD');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}