// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

contract Love is 
    Initializable, 
    UUPSUpgradeable, 
    ERC20Upgradeable, 
    ERC20BurnableUpgradeable
{
    address public _owner;

    modifier onlyAdmin() {
        require(
            msg.sender == _owner,
            "Only Admin can call this!"
        );
        _;
    }

    function initialize(uint256 _initialSupply) external initializer {
        __ERC20_init("LOVE", "LOVE");
        __ERC20Burnable_init();
        _owner = msg.sender;
        mint(_owner, _initialSupply);
    }

    function mint(address to, uint256 amount) internal onlyAdmin {
        _mint(to, amount);
    }

    function burn(uint256 amount) public virtual override onlyAdmin {
        _burn(_msgSender(), amount);
    }   

    function _authorizeUpgrade(address _newImplementation) internal onlyAdmin override {}


}