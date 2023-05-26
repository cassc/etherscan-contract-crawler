// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

error TIMEAdmin__ContractFrozen();
error TIMEAdmin__DistributionPaused();
error TIMEAdmin__PayeeNotSet();

/**
 * @dev Contract module which implements admin functionalities for TIME Sites.
 *
 * - Freeze Contract
 * - Pause Distribution
 * - Manage Access Control through roles
 * - Set Royalty information (ERC2981)
 * - Set Payee and access to contract funds
 *
 * This module is used through inheritance. It will make available the modifier
 * `whenNotFrozen` and `whenDistributionNotPaused`, which can be applied to
 * restrict function access.
 */
abstract contract TIMEAdmin is Ownable, AccessControl, Pausable, ERC2981 {
    // Constants
    bytes32 public constant FINANCE_ROLE = keccak256("FINANCE_ROLE");

    // Variables
    bool private _frozen;
    address private _payee;

    // Events
    event ContractFrozen(address account);
    event DefaultRoyaltySet(
        uint96 royaltyPercentage,
        address receiver,
        address account
    );
    event FundWithdraw(address payee, uint256 amount, address account);
    event PayeeSet(address payee, address account);
    event TokenRoyaltyReset(uint256 tokenId, address account);
    event TokenRoyaltySet(
        uint256 tokenId,
        uint96 royaltyPercentage,
        address receiver,
        address account
    );

    // Modifiers
    modifier whenNotFrozen() {
        if (_frozen) {
            revert TIMEAdmin__ContractFrozen();
        }
        _;
    }

    modifier whenDistributionNotPaused() {
        if (isDistributionPaused()) {
            revert TIMEAdmin__DistributionPaused();
        }
        _;
    }

    // Distribution
    /**
     * @dev Pause or unpause distribution functionalities.
     *
     * Emits {Paused} or {Unpaused} event.
     */
    function setPauseDistribution(bool _shouldBePaused)
        external
        virtual
        whenNotFrozen
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_shouldBePaused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev Returns if distributions, mints and airdrops, are paused.
     */
    function isDistributionPaused() public view returns (bool) {
        return isContractFrozen() || paused();
    }

    // Contract
    /**
     * @dev Freeze contract and disable distributions, metadata updates,
     * and related admin configurations.
     *
     * Emits a {ContractFrozen} event.
     *
     * NOTE: Frozen contracts can NOT be unfreeze.
     */
    function freezeContract()
        external
        virtual
        whenNotFrozen
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _frozen = true;
        emit ContractFrozen(_msgSender());
    }

    /**
     * @dev Returns if contract is frozen.
     */
    function isContractFrozen() public view returns (bool) {
        return _frozen;
    }

    // Admin Role
    /**
     * @dev Grants the Admin role to the specified wallet address.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address _address)
        public
        override
        whenNotFrozen
        onlyOwner
    {
        _grantRole(role, _address);
    }

    /**
     * @dev Revokes the Admin role from the specified wallet address.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address _address)
        public
        override
        whenNotFrozen
        onlyOwner
    {
        _revokeRole(role, _address);
    }

    /**
     * @dev Checks if address has admin role.
     */
    function hasAdminRole(address _address) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /**
     * @dev Checks if address has finance role.
     */
    function hasFinanceRole(address _address) public view returns (bool) {
        return hasRole(FINANCE_ROLE, _address);
    }

    // Royalty
    /**
     * @dev Sets royalty percentage of the collection and the royalty receiver address.
     *
     * The royalty percentage should be expressed in basis points, so 5% royalty should be 500.
     *
     * Emits {DefaultRoyaltySet} event.
     */
    function setDefaultRoyalty(address _receiver, uint96 _royaltyPercentage)
        external
        onlyRole(FINANCE_ROLE)
    {
        _setDefaultRoyalty(_receiver, _royaltyPercentage);
        emit DefaultRoyaltySet(_royaltyPercentage, _receiver, _msgSender());
    }

    /**
     * @dev Sets royalty percentage of specific tokenId.
     *
     * Emits {TokenRoyaltySet} event.
     */
    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _royaltyPercentage
    ) external onlyRole(FINANCE_ROLE) {
        _setTokenRoyalty(_tokenId, _receiver, _royaltyPercentage);
        emit TokenRoyaltySet(
            _tokenId,
            _royaltyPercentage,
            _receiver,
            _msgSender()
        );
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     *
     * Emits {TokenRoyaltyReset} event.
     */
    function resetTokenRoyalty(uint256 _tokenId)
        external
        onlyRole(FINANCE_ROLE)
    {
        _resetTokenRoyalty(_tokenId);
        emit TokenRoyaltyReset(_tokenId, _msgSender());
    }

    // Payee and Withdraw
    /**
     * @dev Sets the address that will receive fund when withdraw from the contract.
     *
     * Emits {PayeeSet} event.
     */
    function setPayee(address _newPayee) external onlyRole(FINANCE_ROLE) {
        _payee = _newPayee;
        emit PayeeSet(_newPayee, _msgSender());
    }

    /**
     * @dev Withdraws the Ether balance to the payee address.
     *
     * Emits {FundWithdraw} event.
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_payee == address(0)) {
            revert TIMEAdmin__PayeeNotSet();
        }
        uint256 amount = address(this).balance;
        Address.sendValue(payable(_payee), amount);

        emit FundWithdraw(_payee, amount, _msgSender());
    }

    /**
     * @dev Returns the address that will receive fund when withdraw from the contract.
     */
    function getPayee()
        public
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (address)
    {
        return _payee;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}