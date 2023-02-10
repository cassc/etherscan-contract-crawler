//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IControlledRegistry.sol";

contract Controller is Ownable {
    // Storage

    IControlledRegistry public registry;

    // Constructor

    constructor(IControlledRegistry registry_, address admin) {
        registry = registry_;
        _transferOwnership(admin);
    }

    // External

    function setAmmPair(address account, bool isPair) public onlyOwner {
        registry.setAmmPair(account, isPair);
    }

    function setTransferLimited(address account, bool isLimited)
        external
        onlyOwner
    {
        registry.setTransferLimited(account, isLimited);
    }

    function setSaleLimited(bool isLimited) external onlyOwner {
        registry.setSaleLimited(isLimited);
    }

    // External View

    function isAmmPair(address addr) external view returns (bool) {
        return registry.isAmmPair(addr);
    }

    function isTransferLimited(address addr) external view returns (bool) {
        return registry.isTransferLimited(addr);
    }

    function isSaleLimited() external view returns (bool) {
        return registry.isSaleLimited();
    }

    function ammPairs() external view returns (address[] memory) {
        return registry.getAmmPairs();
    }

    function transferLimitedAccounts()
        external
        view
        returns (address[] memory)
    {
        return registry.getTransferLimited();
    }
}