// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface ISanctionsList {
    function isSanctioned(address account) external view returns (bool);
}

interface IWhitelistManager is IAccessControlEnumerable {
    function setNewSanctionsOracle(address _newOracle) external;

    function isCustomerWhitelisted(address account) external view returns (bool);

    function isLPWhitelisted(address account) external view returns (bool);

    function isAllowed(
        address user,
        uint256 auctionId,
        bytes calldata callData
    ) external view returns (bytes4);
}