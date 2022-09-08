// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IWhitelist.sol";

/* solhint-disable */

///This whitelist is for test updating whitelistProxy to allow any address to transfer
contract TestWhitelist is IWhitelist {
    function canTransfer(address) external pure override returns (bool) {
        return true;
    }
}