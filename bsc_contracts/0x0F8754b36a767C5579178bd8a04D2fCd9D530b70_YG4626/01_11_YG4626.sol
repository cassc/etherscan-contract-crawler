// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.8.10 <0.9.0;

import "ERC4626.sol";
import "PartiallyUpgradable.sol";

/// @notice Yagger ERC4646 tokenized vault implementation.
/// @author kader 

contract YG4626 is ERC4626, PartiallyUpgradable {

    event LockStatus(bool _status);
    event WhiteList(address _contract, bool _status);

    bool public isLocked;
    uint256 public lockPeriod;
    mapping (address=>bool) public whiteList; // contracts which are whitelisted for receiving locked funds
    mapping (address=>uint256) public lockedTimestamp;

    /// @notice Creates a new vault that accepts a specific underlying token.
    /// @param _underlying The ERC20 compliant token the vault should accept.
    /// @param _name The name for the vault token.
    /// @param _symbol The symbol for the vault token.
    
    constructor(
        ERC20 _underlying,
        string memory _name,
        string memory _symbol
    ) ERC4626(address(_underlying), _name, _symbol) {
        isLocked = true;
        lockPeriod = 7776000;
    }

    function setLock(bool _status) external onlyOwner {
        isLocked = _status;
        emit LockStatus(_status);
    }
    
    function lock(address _account, uint256 timestamp) public onlyOwner {
        lockedTimestamp[_account] = timestamp;
    }

    function setWhiteList(address _contract, bool _status) external onlyOwner {
        if (_status) {
            whiteList[_contract] = _status;
        } else {
            delete whiteList[_contract];
        }
        emit WhiteList(_contract, _status);
    }
    
    function setLockPeriod(uint256 _lockPeriod) public onlyOwner {
        lockPeriod = _lockPeriod;
    }

    /**
     * @dev similar to ERC20 balanceOf but returns 
     * the balance of the account reflected in wrapped Token (underlying token)
     */
    function rbalanceOf(address _account) public view returns (uint256) {
        return assetsOf(_account);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        super._beforeTokenTransfer(from_, to_, amount_);

        if (isLocked) {
            if (from_ != address(0)) {
                // This is a transfer or burn
                if (whiteList[to_] == false) {
                    require(lockedTimestamp[from_]<=block.timestamp, "Token is locked");
                }
            } else {
                // this is a mint
            }
        }   
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        super._afterTokenTransfer(from_, to_, amount_);

        if (to_ != address(0)) {
            if (from_ == address(0)) {
                // mint
                if (whiteList[to_] == false) {
                    lockedTimestamp[to_] = block.timestamp + lockPeriod;
                }
            }          
        }
    }
}