pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

struct CommonAddresses {
        address vault;
        address router;
        address manager;
    }

abstract contract AbstractStrategy is Ownable, Pausable {

    // common addresses for the strategy
    address public vault;
    address public router;
    address public manager;

    event SetVault(address vault);
    event SetRouter(address unirouter);
    event SetManager(address manager);

    //Modifier to restrict access to only vault
    function onlyVault() public view {
        require(msg.sender == owner() || msg.sender == vault, "!vault");
    }

    constructor(
        CommonAddresses memory _commonAddresses
    ) {
        vault = _commonAddresses.vault;
        router = _commonAddresses.router;
        manager = _commonAddresses.manager;
    }

    // checks that caller is either owner or manager.
    function onlyManager() public view {
        require(msg.sender == owner() || msg.sender == manager, "!manager");
    }

    // set new vault (only for strategy upgrades)
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
        emit SetVault(_vault);
    }

    // set new router
    function setRouter(address _router) external onlyOwner {
        router = _router;
        emit SetRouter(_router);
    }

    // set new manager to manage strat
    function setManager(address _manager) external {
        onlyManager();
        manager = _manager;
        emit SetManager(_manager);
    }

}