// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./PassportUpgradable.sol";
import "./PassportRegistry.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract AmbassadorPassport is Initializable, PassportUpgradable {

    function initialize(address defaultAdmin_, string[] memory levels_, uint256 maxSupply_,
        PassportRegistry passportRegistry_) initializer public {
        __Passport_init(defaultAdmin_, levels_, maxSupply_, "Ambassador Passport", "QTAPASS", passportRegistry_);
    }

}