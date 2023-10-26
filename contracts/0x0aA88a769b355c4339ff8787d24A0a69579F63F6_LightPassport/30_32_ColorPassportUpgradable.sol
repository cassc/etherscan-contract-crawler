// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./PassportUpgradable.sol";
import "./PassportRegistry.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract ColorPassportUpgradable is Initializable, PassportUpgradable {

    PassportUpgradable specialPassport;
    using AddressUpgradeable for address;

    function __ColorPassport_init(
        address defaultAdmin_,
        string[] memory levels_,
        uint256 maxSupply_,
        string memory name_,
        string memory symbol_,
        PassportUpgradable specialPassport_,
        PassportRegistry passportRegistry_) onlyInitializing internal {
        __Passport_init(defaultAdmin_, levels_, maxSupply_, name_, symbol_, passportRegistry_);

        require(address(specialPassport_) != address(0), "ColorPassport: specialPassport is the zero address");
        require(address(specialPassport_).isContract(), "ColorPassport: specialPassport address is not a contract address");
        specialPassport = specialPassport_;
    }

    function setSpecialPassport(PassportUpgradable specialPassport_) external onlyOwner {
        require(address(specialPassport_) != address(0), "ColorPassport: specialPassport is the zero address");
        require(address(specialPassport_).isContract(), "ColorPassport: specialPassport address is not a contract address");
        specialPassport = specialPassport_;
    }

    function safeMint(address to) public override {
        require(specialPassport.totalSupply() == specialPassport.maxSupply(), "ColorPassport: Special Passport has not reached Max Supply yet");
        super.safeMint(to);
    }

}