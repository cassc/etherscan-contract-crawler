// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import './interfaces/IRubicWhitelist.sol';

contract RubicWhitelist is IRubicWhitelist, Initializable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // AddressSet of whitelisted addresses
    EnumerableSetUpgradeable.AddressSet internal whitelistedOperators;
    EnumerableSetUpgradeable.AddressSet internal blacklistedRouters;

    // The main account which can grant roles
    address public admin;
    // The address of a pending admin in transfer process
    address public pendingAdmin;

    error NotAnOperatorOrAdmin();
    error NotAnAdmin();
    error NotPendingAdmin();
    error ZeroAddress();
    error Blacklisted();

    EnumerableSetUpgradeable.AddressSet internal whitelistedCrossChains;
    EnumerableSetUpgradeable.AddressSet internal whitelistedDEXs;
    EnumerableSetUpgradeable.AddressSet internal whitelistedAnyRouters;

    event TransferAdmin(address currentAdmin, address pendingAdmin);
    event AcceptAdmin(address newAdmin);

    // reference to https://github.com/OpenZeppelin/openzeppelin-contracts/pull/3347/
    modifier onlyOperatorOrAdmin() {
        checkIsOperatorOrAdmin();
        _;
    }

    function checkIsOperatorOrAdmin() internal view {
        if (!whitelistedOperators.contains(msg.sender) && msg.sender != admin) revert NotAnOperatorOrAdmin();
    }

    modifier onlyAdmin() {
        checkIsAdmin();
        _;
    }

    function checkIsAdmin() internal view {
        if (msg.sender != admin) revert NotAnAdmin();
    }

    function initialize(address[] memory _operators, address _admin) public initializer {
        if (_admin == address(0)) {
            revert ZeroAddress();
        }

        admin = _admin;

        uint256 length = _operators.length;
        for (uint256 i; i < length; ) {
            if (_operators[i] == address(0)) {
                revert ZeroAddress();
            }
            whitelistedOperators.add(_operators[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Appends new whitelisted operators
     * @param _operators operators addresses to add
     */
    function addOperators(address[] calldata _operators) external override onlyAdmin {
        uint256 length = _operators.length;
        for (uint256 i; i < length; ) {
            if (_operators[i] == address(0)) {
                revert ZeroAddress();
            }
            whitelistedOperators.add(_operators[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Removes existing whitelisted operators
     * @param _operators operators addresses to remove
     */
    function removeOperators(address[] calldata _operators) external override onlyAdmin {
        uint256 length = _operators.length;
        for (uint256 i; i < length; ) {
            whitelistedOperators.remove(_operators[i]);
            unchecked {
                ++i;
            }
        }
    }

    function transferAdmin(address _admin) external onlyAdmin {
        pendingAdmin = _admin;
        emit TransferAdmin(msg.sender, _admin);
    }

    function acceptAdmin() external {
        if (msg.sender != pendingAdmin) {
            revert NotPendingAdmin();
        }

        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit AcceptAdmin(msg.sender);
    }

    function getAvailableOperators() external view override returns (address[] memory) {
        return whitelistedOperators.values();
    }

    function isOperator(address _operator) external view override returns (bool) {
        return whitelistedOperators.contains(_operator);
    }

    /**
     * @dev Appends new whitelisted cross chain addresses
     * @param _crossChains cross chain addresses to add
     */
    function addCrossChains(address[] calldata _crossChains) external override onlyOperatorOrAdmin {
        uint256 length = _crossChains.length;
        for (uint256 i; i < length; ) {
            if (_crossChains[i] == address(0)) {
                revert ZeroAddress();
            }
            if (blacklistedRouters.contains(_crossChains[i])) {
                revert Blacklisted();
            }
            whitelistedCrossChains.add(_crossChains[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Removes existing whitelisted cross chain addesses
     * @param _crossChains cross chain addresses to remove
     */
    function removeCrossChains(address[] calldata _crossChains) public override onlyOperatorOrAdmin {
        uint256 length = _crossChains.length;
        for (uint256 i; i < length; ) {
            whitelistedCrossChains.remove(_crossChains[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getAvailableCrossChains() external view override returns (address[] memory) {
        return whitelistedCrossChains.values();
    }

    function isWhitelistedCrossChain(address _crossChain) external view override returns (bool) {
        return whitelistedCrossChains.contains(_crossChain);
    }

    /**
     * @dev Appends new whitelisted DEX addresses
     * @param _dexs DEX addresses to add
     */
    function addDEXs(address[] calldata _dexs) external override onlyOperatorOrAdmin {
        uint256 length = _dexs.length;
        for (uint256 i; i < length; ) {
            if (_dexs[i] == address(0)) {
                revert ZeroAddress();
            }
            if (blacklistedRouters.contains(_dexs[i])) {
                revert Blacklisted();
            }
            whitelistedDEXs.add(_dexs[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Removes existing whitelisted DEX addesses
     * @param _dexs DEX addresses to remove
     */
    function removeDEXs(address[] calldata _dexs) public override onlyOperatorOrAdmin {
        uint256 length = _dexs.length;
        for (uint256 i; i < length; ) {
            whitelistedDEXs.remove(_dexs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getAvailableDEXs() external view override returns (address[] memory) {
        return whitelistedDEXs.values();
    }

    function isWhitelistedDEX(address _dex) external view override returns (bool) {
        return whitelistedDEXs.contains(_dex);
    }

    /**
     * @dev Appends new whitelisted any router addresses of Multichain
     * @param _anyRouters any router addresses to add
     */
    function addAnyRouters(address[] calldata _anyRouters) external override onlyOperatorOrAdmin {
        uint256 length = _anyRouters.length;
        for (uint256 i; i < length; ) {
            if (_anyRouters[i] == address(0)) {
                revert ZeroAddress();
            }
            if (blacklistedRouters.contains(_anyRouters[i])) {
                revert Blacklisted();
            }
            whitelistedAnyRouters.add(_anyRouters[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Removes existing whitelisted any router addesses of Multichain
     * @param _anyRouters any router addresses to remove
     */
    function removeAnyRouters(address[] calldata _anyRouters) public override onlyOperatorOrAdmin {
        uint256 length = _anyRouters.length;
        for (uint256 i; i < length; ) {
            whitelistedAnyRouters.remove(_anyRouters[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getAvailableAnyRouters() external view override returns (address[] memory) {
        return whitelistedAnyRouters.values();
    }

    function isWhitelistedAnyRouter(address _anyRouter) external view override returns (bool) {
        return whitelistedAnyRouters.contains(_anyRouter);
    }

    /**
     * @dev Appends new blacklisted router addresses
     * @param _blackAddrs black list router addresses to add
     */
    function addToBlackList(address[] calldata _blackAddrs) external override onlyOperatorOrAdmin {
        uint256 length = _blackAddrs.length;
        for (uint256 i; i < length; ) {
            if (whitelistedDEXs.contains(_blackAddrs[i])) {
                removeDEXs(_blackAddrs);
            } else if (whitelistedCrossChains.contains(_blackAddrs[i])) {
                removeCrossChains(_blackAddrs);
            } else {
                removeAnyRouters(_blackAddrs);
            }

            blacklistedRouters.add(_blackAddrs[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Removes existing blacklisted router addresses
     * @param _blackAddrs black list router addresses to remove
     */
    function removeFromBlackList(address[] calldata _blackAddrs) external override onlyOperatorOrAdmin {
        uint256 length = _blackAddrs.length;
        for (uint256 i; i < length; ) {
            blacklistedRouters.remove(_blackAddrs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getBlackList() external view override returns (address[] memory) {
        return blacklistedRouters.values();
    }

    function isBlacklisted(address _router) external view override returns (bool) {
        return blacklistedRouters.contains(_router);
    }

    function sendToken(address _token, uint256 _amount, address _receiver) internal {
        if (_token == address(0)) {
            AddressUpgradeable.sendValue(payable(_receiver), _amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_receiver, _amount);
        }
    }

    function sweepTokens(address _token, uint256 _amount) external onlyOperatorOrAdmin {
        sendToken(_token, _amount, msg.sender);
    }

    /**
     * @dev Plain fallback function
     */
    fallback() external {}
}