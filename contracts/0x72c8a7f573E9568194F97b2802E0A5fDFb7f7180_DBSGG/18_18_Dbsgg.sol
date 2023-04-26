// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

contract DBSGG is ERC20Upgradeable, ERC20PermitUpgradeable, AccessControlUpgradeable {
    uint256 public constant VERSION = 14;

    uint8 private _decimals;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
     }

    function initialize(string memory _name, string memory _symbol, uint256 initialSupply)
        public
        virtual
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        __ERC20_init(_name, _symbol);
        _decimals = 6;

        _mint(_msgSender(), initialSupply);

        __ERC20Permit_init(_name);
    }

    function decimals() public view override virtual returns (uint8) {
        return _decimals;
    }

    function mint(address _account, uint256 _amount)
        external
        onlyRole(MINTER_ROLE)
    {
        _mint(_account, _amount);
    }

    function burn(uint256 _amount)
        external
        onlyRole(MINTER_ROLE)
    {
        _burn(_msgSender(), _amount);
    }

}