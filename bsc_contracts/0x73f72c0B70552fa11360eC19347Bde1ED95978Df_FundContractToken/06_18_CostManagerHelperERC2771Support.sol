// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CostManagerBase.sol";
import "@artman325/trustedforwarder/contracts/TrustedForwarder.sol";

/**
* used for instances that have created(cloned) by factory with ERC2771 supports
*/
abstract contract CostManagerHelperERC2771Support is CostManagerBase, TrustedForwarder {
    function _sender() internal override view returns(address){
        return _msgSender();
    }
}