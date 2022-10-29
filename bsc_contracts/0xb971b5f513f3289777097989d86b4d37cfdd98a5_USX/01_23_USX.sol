// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./utils/Initializable.sol";
import "./proxy/UUPSUpgradeable.sol";
import "./utils/Ownable.sol";
import "./bridging/OERC20.sol";
import "./interfaces/IUSX.sol";

contract USX is Initializable, UUPSUpgradeable, Ownable, OERC20, IUSX {
    struct Privileges {
        bool mint;
        bool burn;
    }

    mapping(address => Privileges) public treasuries;

    function initialize(address _lzEndpoint) public initializer {
        __ERC20_init("USX", "USX");
        __OERC20_init(_lzEndpoint);
        __Ownable_init(); // @dev as there is no constructor, we need to initialise the Ownable explicitly
    }

    // @dev required by the UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function mint(address _account, uint256 _amount) public {
        require(treasuries[msg.sender].mint, "Unauthorized.");
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public {
        require(treasuries[msg.sender].burn, "Unauthorized.");
        _burn(_account, _amount);
    }

    function manageTreasuries(address treasury, bool _mint, bool _burn) public onlyOwner {
        treasuries[treasury] = Privileges(_mint, _burn);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[50] private __gap;
}