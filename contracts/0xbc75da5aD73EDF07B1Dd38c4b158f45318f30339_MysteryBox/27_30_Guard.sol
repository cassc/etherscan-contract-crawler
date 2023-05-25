// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;
import "../interfaces/IRights.sol";

abstract contract Guard {
    string constant NO_RIGHTS = "Guard: No rights";

    /// @notice only if person with rights calls the contract
    modifier haveRights() {
        require(_rights().haveRights(address(this), msg.sender), NO_RIGHTS);
        _;
    }

    /// @notice only if someone with rights calls the contract
    modifier haveRightsPerson(address who_) {
        require(_rights().haveRights(address(this), who_), NO_RIGHTS);
        _;
    }

    /// @notice only if person with rights calls the function
    modifier haveRightsExt(address target_, address who_) {
        require(_rights().haveRights(target_, who_), NO_RIGHTS);
        _;
    }

    function _rights() internal view virtual returns (IRights);

    function setRights(address rights_) external virtual;
}