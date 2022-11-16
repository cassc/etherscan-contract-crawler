// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./utils/Initializable.sol";
import "./proxy/UUPSUpgradeable.sol";
import "./utils/Ownable.sol";
import "./bridging/OERC20.sol";
import "./interfaces/IUSX.sol";

contract USX is Initializable, UUPSUpgradeable, Ownable, OERC20, IUSX {
    function initialize(address _lzEndpoint) public initializer {
        __ERC20_init("USX", "USX");
        __OERC20_init(_lzEndpoint);
        __Ownable_init();      /// @dev No constructor, so initialize Ownable explicitly.
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}    /// @dev Required by the UUPS module.

    function mint(address _account, uint256 _amount) public {
        require(treasuries[msg.sender].mint, "Unauthorized.");
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public {
        require(treasuries[msg.sender].burn, "Unauthorized.");
        _burn(_account, _amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage slots in the inheritance chain.
     * Storage slot management is necessary, as we're using an upgradable proxy contract.
     * For details, see: https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}