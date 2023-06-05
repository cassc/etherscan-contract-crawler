// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MultiSigProxy.sol";

// @author: miinded.com

abstract contract ShareProxy is MultiSigProxy {

    address public shareContract;

    function setShareContract(address _shareContract) public {
        MultiSigProxy.validate("setShareContract");

        _setShareContract(_shareContract);
    }

    function _setShareContract(address _shareContract) internal {
        shareContract = _shareContract;
    }
    function withdraw() public onlyOwnerOrAdmins {
        (bool success, ) = shareContract.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}