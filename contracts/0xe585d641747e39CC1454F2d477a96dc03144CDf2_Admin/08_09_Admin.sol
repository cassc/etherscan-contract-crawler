// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./interfaces/IAdmin.sol";

/**
 *  @title  Dev Admin Contract
 *
 *  @author IHeart Team
 *
 *  @notice This smart contract is contract to control access and role to call function
 */
contract Admin is OwnableUpgradeable, ERC165Upgradeable, IAdmin {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     *  @notice mapping from token ID to isAdmin status
     */
    mapping(address => bool) public admins;

    /**
     *  @notice treasury is address of Treasury
     */
    address public treasury;

    /**
     *  @notice mapping payment token address => status is allowed
     */
    mapping(address => bool) public permittedPaymentTokens;

    event SetAdmin(address indexed user, bool allow);
    event SetTreasury(address indexed oldTreasury, address indexed newTreasury);
    event RegisterTreasury(address indexed account);
    event SetPaymentToken(address indexed paymentToken, bool allow);

    /**
     *  @notice Initialize new logic contract.
     */
    function initialize(address _owner) public initializer {
        require(_owner != address(0) && !AddressUpgradeable.isContract(_owner), "Invalid address");

        __Ownable_init();
        __ERC165_init();

        transferOwnership(_owner);
    }

    modifier notZeroAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Caller is not owner or admin");
        _;
    }

    /**
     *  @notice Register Treasury to allow it order methods of this contract
     *
     *  @dev    Register can only be called once
     */
    function registerTreasury() external {
        require(treasury == address(0), "Already register");
        treasury = _msgSender();
        emit RegisterTreasury(treasury);
    }

    /**
     *  @notice Replace the admin role by another address.
     *
     *  @dev    Only owner can call this function.
     *
     *  @param  _account   Address that will allow to admin.
     *  @param  _allow     Status of allowance (true is admin | false is banned).
     */
    function setAdmin(address _account, bool _allow) external onlyOwner notZeroAddress(_account) {
        require(admins[_account] != _allow, "Already register");
        admins[_account] = _allow;
        emit SetAdmin(_account, _allow);
    }

    /**
     *  @notice Replace the treasury by another address.
     *
     *  @dev    Only owner can call this function.
     *
     *  @param  _treasury  Address of Treasury contract.
     */
    function setTreasury(address _treasury) external onlyOwner notZeroAddress(_treasury) {
        require(treasury != _treasury, "Already register");

        address oldTreasury = treasury;
        treasury = _treasury;

        emit SetTreasury(oldTreasury, treasury);
    }

    /**
     *  @notice Set payment token.
     *
     *  @dev    Only admin can call this function.
     *
     *  @param  _paymentToken   Address that will allow to admin.
     *  @param  _allow          true / false.
     */
    function setPaymentToken(address _paymentToken, bool _allow) external onlyAdmin {
        require(permittedPaymentTokens[_paymentToken] != _allow, "Already register");
        permittedPaymentTokens[_paymentToken] = _allow;
        emit SetPaymentToken(_paymentToken, _allow);
    }

    /**
     * @notice Get owner of this contract
     *
     * @dev Using in related contracts
     */
    function owner() public view override(IAdmin, OwnableUpgradeable) returns (address) {
        return super.owner();
    }

    /**
     *  @notice Check account whether it is the admin role.
     */
    function isAdmin(address _account) public view virtual returns (bool) {
        return admins[_account] || _account == owner();
    }

    /**
     *  @notice Check payment token whether it is permitted.
     */
    function isPermittedPaymentToken(address _paymentToken) public view virtual returns (bool) {
        return permittedPaymentTokens[_paymentToken];
    }
}