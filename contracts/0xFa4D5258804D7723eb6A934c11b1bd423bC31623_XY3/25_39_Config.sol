// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IConfig.sol";
import {MANAGER_ROLE, SIGNER_ROLE} from "./Roles.sol";

bytes32 constant PERMIT_MANAGER_ROLE = keccak256("PERMIT_MANAGER");

/**
 * @title  Configurations for both ERC721 token and ERC20 currency.
 * @author XY3 g
 * @dev Implements token and currency management and security functions.
 */
abstract contract Config is AccessControl, Pausable, ReentrancyGuard, IConfig {

    /**
     * @dev Admin fee receiver, can be updated by admin.
     */
    address public adminFeeReceiver;

    /**
     * @dev Borrow durations, can be updated by admin.
     */
    uint256 public override maxBorrowDuration = 365 days;
    uint256 public override minBorrowDuration = 1 days;

    /**
     * @dev The fee percentage is taken by the contract admin's as a
     * fee, which is from the the percentage of lender earned.
     * Unit is hundreths of percent, like adminShare/10000.
     */
    uint16 public override adminShare = 25;
    uint16 public constant HUNDRED_PERCENT = 10000;

    /**
     * @dev The permitted ERC20 currency for this contract.
     */
    mapping(address => bool) private erc20Permits;

    /**
     * @dev The permitted ERC721 token or collections for this contract.
     */
    mapping(address => bool) private erc721Permits;

    /**
     * @dev The permitted agent for this contract, index is target + selector;
     */
    mapping(address => mapping(bytes4 => bool)) private agentPermits;

    /**
     * @dev Address Provider
     */
    address private addressProvider;

    /**
     * @dev Init the contract admin.
     * @param _admin - Initial admin of this contract and fee receiver.
     */
    constructor(address _admin, address _addressProvider) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _setRoleAdmin(MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(SIGNER_ROLE, DEFAULT_ADMIN_ROLE);
        adminFeeReceiver = _admin;
        addressProvider = _addressProvider;
    }

    /**
     * @dev Sets contract to be stopped state.
     */
    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    /**
     * @dev Restore the contract from stopped state.
     */
    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    /**
     * @dev Update the maxBorrowDuration by manger role.
     * @param _newMaxBorrowDuration - The new max borrow duration, measured in seconds.
     */
    function updateMaxBorrowDuration(
        uint256 _newMaxBorrowDuration
    ) external override onlyRole(MANAGER_ROLE) {
        require(_newMaxBorrowDuration >= minBorrowDuration, "Invalid duration");
        if (maxBorrowDuration != _newMaxBorrowDuration) {
            maxBorrowDuration = _newMaxBorrowDuration;
            emit MaxBorrowDurationUpdated(_newMaxBorrowDuration);
        }
    }

    /**
     * @dev Update the minBorrowDuration by manger role.
     * @param _newMinBorrowDuration - The new min borrow duration, measured in seconds.
     */
    function updateMinBorrowDuration(
        uint256 _newMinBorrowDuration
    ) external override onlyRole(MANAGER_ROLE) {
        require(_newMinBorrowDuration <= maxBorrowDuration, "Invalid duration");
        if (minBorrowDuration != _newMinBorrowDuration) {
            minBorrowDuration = _newMinBorrowDuration;
            emit MinBorrowDurationUpdated(_newMinBorrowDuration);
        }
    }

    /**
     * @notice Update the adminShaer by manger role. The newAdminFee can be bigger than 10,000.
     * @param _newAdminShare - The new admin fee measured in basis points.
     */
    function updateAdminShare(
        uint16 _newAdminShare
    ) external override onlyRole(MANAGER_ROLE) {
        require(_newAdminShare <= HUNDRED_PERCENT, "basis points > 10000");
        if (adminShare != _newAdminShare) {
            adminShare = _newAdminShare;
            emit AdminFeeUpdated(_newAdminShare);
        }
    }

    /**
     * @dev Update the adminFeeReceiver by manger role.
     * @param _newAdminFeeReceiver - The new admin fee receiver address.
     */
    function updateAdminFeeReceiver(
        address _newAdminFeeReceiver
    ) external override onlyRole(MANAGER_ROLE) {
        require(_newAdminFeeReceiver != address(0), "Invalid receiver address");
        if (adminFeeReceiver != _newAdminFeeReceiver) {
            adminFeeReceiver = _newAdminFeeReceiver;
            emit AdminFeeReceiverUpdated(adminFeeReceiver);
        }
    }

    /**
     * @dev Set or remove the ERC20 currency permit by manger role.
     * @param _erc20s - The addresses of the ERC20 currencies.
     * @param _permits - The new statuses of the currencies.
     */
    function setERC20Permits(
        address[] memory _erc20s,
        bool[] memory _permits
    ) external override onlyRole(MANAGER_ROLE) {
        require(
            _erc20s.length == _permits.length,
            "address and permits length mismatch"
        );

        for (uint256 i = 0; i < _erc20s.length; i++) {
            _setERC20Permit(_erc20s[i], _permits[i]);
        }
    }

    /**
     * @dev Set or remove the ERC721 token permit by manger role.
     * @param _erc721s - The addresses of the ERC721 collection.
     * @param _permits - The new statuses of the collection.
     */
    function setERC721Permits(
        address[] memory _erc721s,
        bool[] memory _permits
    ) external override onlyRole(MANAGER_ROLE) {
        require(
            _erc721s.length == _permits.length,
            "address and permits length mismatch"
        );

        for (uint256 i = 0; i < _erc721s.length; i++) {
            _setERC721Permit(_erc721s[i], _permits[i]);
        }
    }

    /**
     * @dev Set or remove the ERC721 token permit by manger role.
     * @param _agents - The addresses of the ERC721 collection.
     * @param _permits - The new statuses of the collection.
     */
    function setAgentPermits(
        address[] memory _agents,
        bytes4[] memory _selectors,
        bool[] memory _permits
    ) external override onlyRole(PERMIT_MANAGER_ROLE) {
        require(
            _agents.length == _permits.length && _selectors.length == _permits.length,
            "address and permits length mismatch"
        );

        for (uint256 i = 0; i < _agents.length; i++) {
            _setAgentPermit(_agents[i], _selectors[i], _permits[i]);
        }
    }

    /**
     * @dev Get the permit of the ERC20 token, public reading.
     * @param _erc20 - The address of the ERC20 token.
     * @return The ERC20 permit boolean value
     */
    function getERC20Permit(
        address _erc20
    ) public view override returns (bool) {
        return erc20Permits[_erc20];
    }

    /**
     * @dev Get the permit of the ERC721 collection, public reading.
     * @param _erc721 - The address of the ERC721 collection.
     * @return The ERC721 collection permit boolean value
     */
    function getERC721Permit(
        address _erc721
    ) public view override returns (bool) {
        return erc721Permits[_erc721];
    }

    /**
     * @dev Get the permit of agent, public reading.
     * @param _agent - The address of the agent.
     * @return The agent permit boolean value
     */
    function getAgentPermit(
        address _agent,
        bytes4 _selector
    ) public view override returns (bool) {
        return agentPermits[_agent][_selector];
    }

    function getAddressProvider()
        public
        view
        override
        returns (IAddressProvider)
    {
        return IAddressProvider(addressProvider);
    }

    /**
     * @dev Permit or remove ERC20 currency.
     * @param _erc20 - The operated ERC20 currency address.
     * @param _permit - The currency new status, permitted or not.
     */
    function _setERC20Permit(address _erc20, bool _permit) internal {
        require(_erc20 != address(0), "erc20 is zero address");

        erc20Permits[_erc20] = _permit;

        emit ERC20Permit(_erc20, _permit);
    }

    /**
     * @dev Permit or remove ERC721 token.
     * @param _erc721 - The operated ERC721 token address.
     * @param _permit - The token new status, permitted or not.
     */
    function _setERC721Permit(address _erc721, bool _permit) internal {
        require(_erc721 != address(0), "erc721 is zero address");

        erc721Permits[_erc721] = _permit;

        emit ERC721Permit(_erc721, _permit);
    }

    /**
     * @dev Permit or remove ERC721 token.
     * @param _agent - The operated ERC721 token address.
     * @param _permit - The token new status, permitted or not.
     */
    function _setAgentPermit(address _agent, bytes4 _selector, bool _permit) internal {
        require(_agent != address(0) && _selector != bytes4(0), "agent is zero address");

        agentPermits[_agent][_selector] = _permit;

        emit AgentPermit(_agent, _selector, _permit);
    }
}