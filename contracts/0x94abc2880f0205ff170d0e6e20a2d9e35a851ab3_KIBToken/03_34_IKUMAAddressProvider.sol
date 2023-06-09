// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IKUMAAddressProvider {
    event AccessControllerSet(address accessController);
    event KBCTokenSet(address KBCToken);
    event KIBTokenSet(address KIBToken, bytes4 indexed currency, bytes32 indexed issuer, uint64 indexed term);
    event KUMABondTokenSet(address KUMABondToken);
    event KUMAFeeCollectorSet(
        address KUMAFeeCollector, bytes4 indexed currency, bytes32 indexed issuer, uint64 indexed term
    );
    event KUMASwapSet(address KUMASwap, bytes4 indexed currency, bytes32 indexed issuer, uint64 indexed term);
    event RateFeedSet(address rateFeed);

    function initialize(IAccessControl accessController) external;

    function setKUMABondToken(address KUMABondToken) external;

    function setKBCToken(address KBCToken) external;

    function setRateFeed(address rateFeed) external;

    function setKIBToken(bytes4 currency, bytes32 issuer, uint64 term, address KIBToken) external;

    function setKUMASwap(bytes4 currency, bytes32 issuer, uint64 term, address KUMASwap) external;

    function setKUMAFeeCollector(bytes4 currency, bytes32 issuer, uint64 term, address feeCollector) external;

    function getAccessController() external view returns (IAccessControl);

    function getKUMABondToken() external view returns (address);

    function getRateFeed() external view returns (address);

    function getKBCToken() external view returns (address);

    function getKIBToken(bytes32 riskCategory) external view returns (address);

    function getKUMASwap(bytes32 riskCategory) external view returns (address);

    function getKUMAFeeCollector(bytes32 riskCategory) external view returns (address);
}