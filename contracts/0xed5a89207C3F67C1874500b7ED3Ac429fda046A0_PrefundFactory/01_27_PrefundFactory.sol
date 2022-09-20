// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Prefund.sol";

/**
 * @title PrefundFactory
 */
contract PrefundFactory is AccessControl {
    using Clones for address;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address public prefundImplementation;
    address public prefundsAdmin;
    uint256 public prefundsCount;

    event CreatePrefund(address indexed creator, address indexed prefundAddress,
        uint256 startTime, uint256 endTime, uint256 minimumDeposit, bool isEtherPrefund, address[] acceptedTokens);

    constructor(
        address prefundImplementationAddress
    ) {
        if (!_addressIsValid(prefundImplementationAddress))
            revert InvalidAddress();

        prefundsAdmin = _msgSender();
        prefundImplementation = prefundImplementationAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setPrefundsAdmin(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_addressIsValid(addr))
            revert InvalidAddress();

        prefundsAdmin = addr;
    }

    function setPrefundImplementation(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_addressIsValid(addr))
            revert InvalidAddress();

        prefundImplementation = addr;
    }

    function createPrefund(
        uint256 startTime,
        uint256 endTime,
        uint256 minimumDeposit,
        bool isEtherPrefund,
        address[] memory acceptedTokens
    ) external onlyRole(OPERATOR_ROLE) {

        address prefund = prefundImplementation.clone();
        Prefund(payable(prefund)).initialize(
            prefundsAdmin,
            _msgSender(),
            startTime,
            endTime,
            minimumDeposit,
            isEtherPrefund,
            acceptedTokens
        );

        prefundsCount++;

        emit CreatePrefund(
            _msgSender(),
            prefund,
            startTime,
            endTime,
            minimumDeposit,
            isEtherPrefund,
            acceptedTokens
        );
    }

    /**
     * @dev Checks if address is not empty
     */
    function _addressIsValid(address _addr) internal pure returns (bool) {
        return _addr != address(0);
    }
}