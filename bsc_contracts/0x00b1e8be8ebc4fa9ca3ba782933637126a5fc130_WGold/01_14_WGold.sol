// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./openzeppelin/ERC20Upgradeable.sol";
import "./openzeppelin/AccessControlUpgradeable.sol";
import "./openzeppelin/utils/Initializable.sol";
import "./openzeppelin/PausableUpgradeable.sol";
import "./interfaces/IWGold.sol";

contract WGold is
    Initializable,
    ERC20Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    IWGold
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _minter, address _burner) public initializer {
        __ERC20_init("Wrapped Gold", "wGOLD");
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, _minter);
        _grantRole(BURNER_ROLE, _burner);
    }

    function mint(address to, uint256 amount)
        external
        override
        whenNotPaused
        onlyRole(MINTER_ROLE)
    {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount)
        external
        override
        whenNotPaused
        onlyRole(BURNER_ROLE)
    {
        _burn(from, amount);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}