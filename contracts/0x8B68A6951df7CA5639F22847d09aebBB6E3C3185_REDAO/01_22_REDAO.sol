// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @custom:security-contact [email protected]
contract REDAO is
    Initializable,
    ERC20Upgradeable,
    ERC20SnapshotUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable
{
    uint256 private _deployTimestamp;
    mapping(address => uint256[25]) public addressTimelock;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _foundationWallet,
        address _employeesVestingWallet,
        address _investorVestingWallet
    ) public initializer {
        __ERC20_init("REDAO", "REDAO");
        __ERC20Snapshot_init();
        __Ownable_init();
        __Pausable_init();
        __ERC20Permit_init("REDAO");
        _deployTimestamp = block.timestamp;
        _mint(_foundationWallet, 75000000 * 10 ** decimals());
        _mint(_employeesVestingWallet, 75000000 * 10 ** decimals());
        _mint(_investorVestingWallet, 150000000 * 10 ** decimals());
        _setTransferTimelock(
            _employeesVestingWallet,
            1,
            75000000 * 10 ** decimals()
        );
        _setTransferTimelock(
            _investorVestingWallet,
            6,
            150000000 * 10 ** decimals()
        );
    }

    function _setTransferTimelock(
        address _lockAddress,
        uint256 _step,
        uint256 _initialAmount
    ) internal {
        uint256 amountPerStep = _initialAmount / Math.ceilDiv(25, _step);
        for (uint256 i = 0; i < 25; i++) {
            addressTimelock[_lockAddress][i] =
                _initialAmount -
                (amountPerStep * (Math.ceilDiv((i + 1), _step)));
        }
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _checkTimelock(
        address _from,
        uint256 _transferAmount
    ) internal view returns (bool) {
        uint256 month = (block.timestamp - _deployTimestamp) / 30 days;
        uint256 lockedAmount = addressTimelock[_from][month];
        uint256 oldBalance = balanceOf(_from);
        if (oldBalance < _transferAmount) {
            return true;
        }
        uint256 newBalance = balanceOf(_from) - _transferAmount;
        return newBalance >= lockedAmount;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
        whenNotPaused
    {
        require(_checkTimelock(from, amount), "Exceed time locked amount");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }
}