pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SharesToken is ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {

    error CallerIsNotStrategyRouter();

    address private strategyRouter;

    modifier onlyStrategyRouter() {
        if (msg.sender != strategyRouter) revert CallerIsNotStrategyRouter();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // lock implementation
        _disableInitializers();
    }

    function initialize(address _strategyRouter) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ERC20_init("Clip-Finance Shares", "CF");
        strategyRouter = _strategyRouter;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Helper 'transferFrom' function that don't require user approval
    /// @dev Only callable by strategy router.
    function transferFromAutoApproved(
        address from,
        address to,
        uint256 amount
    ) external onlyStrategyRouter {
        _transfer(from, to, amount);
    }

    function mint(address to, uint256 amount) external onlyStrategyRouter {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyStrategyRouter {
        _burn(from, amount);
    }
}