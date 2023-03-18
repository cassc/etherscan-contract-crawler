// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// Third Party
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PausableCloneableERC20 is
    ERC20PausableUpgradeable,
    OwnableUpgradeable
{
    function initialize(
        string calldata _name,
        string calldata _symbol,
        uint256 _initialSupply,
        address _owner
    ) public initializer {
        __ERC20_init(_name, _symbol);
        __Pausable_init();
        __Ownable_init();
        _mint(_owner, _initialSupply * 1e18);
        transferOwnership(_owner);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}