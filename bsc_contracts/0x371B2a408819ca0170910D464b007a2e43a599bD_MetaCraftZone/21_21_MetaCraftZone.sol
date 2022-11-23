// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC20.sol";
import "./ERC20Votes.sol";

/**
 * @title MetaCraftZone (MCZ)
 * @author Victor Han
 * @notice Implements a basic ERC20 token.
 */
contract MetaCraftZone is ERC20, Pausable, AccessControl, ERC20Votes {
    using SafeMath for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private immutable maxSupply = 1000000000000 * 10 ** decimals(); // the total supply

    constructor() ERC20("MetaCraftZone", "MCZ") ERC20Permit("MetaCraftZone") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }

    function setPool(address _pool) public onlyRole(MINTER_ROLE) {
        pool = _pool;
    }

    function setFee(uint256 _fee) public onlyRole(MINTER_ROLE) {
        fee = _fee;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(
        address to,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) returns (bool) {
        if (amount.add(totalSupply()) > maxSupply) {
            return false;
        }
        _mint(to, amount);
        return true;
    }

    function burn(uint256 amount) public onlyRole(MINTER_ROLE) {
        _burn(_msgSender(), amount);
    }

    function burnFrom(
        address account,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}