// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;
import "../interfaces/IRights.sol";
import "../utils/Guard.sol";

contract GuardExtension is Guard {
    IRights private _rightsContract;

    string private constant SAME_VALUE = "Guard: same value";
    string private constant ZERO_ADDRESS = "Guard: zero address";

    constructor(address rights_) {
        require(rights_ != address(0), ZERO_ADDRESS);
        _rightsContract = IRights(rights_);
    }

    function _rights() internal view virtual override returns (IRights) {
        return _rightsContract;
    }

    function setRights(address rights_) external virtual override haveRights {
        require(address(_rightsContract) != rights_, SAME_VALUE);
        _rightsContract = IRights(rights_);
    }
}