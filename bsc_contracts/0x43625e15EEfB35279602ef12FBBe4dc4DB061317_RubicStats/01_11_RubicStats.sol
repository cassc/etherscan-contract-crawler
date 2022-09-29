// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**

██████╗ ██╗   ██╗██████╗ ██╗ ██████╗    ███████╗████████╗ █████╗ ████████╗███████╗
██╔══██╗██║   ██║██╔══██╗██║██╔════╝    ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██╔════╝
██████╔╝██║   ██║██████╔╝██║██║         ███████╗   ██║   ███████║   ██║   ███████╗
██╔══██╗██║   ██║██╔══██╗██║██║         ╚════██║   ██║   ██╔══██║   ██║   ╚════██║
██║  ██║╚██████╔╝██████╔╝██║╚██████╗    ███████║   ██║   ██║  ██║   ██║   ███████║
╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚══════╝
                                                                                  
*/

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

error NotAnAdmin();
error NotAManager();

/**
    @title Rubic stats
    @author Vladislav Yaroshuk
    @notice Contract for dune stats
 */
contract RubicStats is AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Role of the manager
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    mapping(string => uint256) public dateToLastIndexCrossChain;
    mapping(string => uint256) public dateToLastIndexBridge;
    mapping(string => uint256) public dateToLastIndexOnChain;

    event CrossChain(uint256 index, string date, uint256 volumeUSDC, uint256 transactionCount);
    event Bridge(uint256 index, string date, uint256 volumeUSDC, uint256 transactionCount);
    event OnChain(uint256 index, string date, uint256 volumeUSDC, uint256 transactionCount);

    modifier onlyManagerOrAdmin() {
        checkIsManagerOrAdmin();
        _;
    }

    modifier onlyAdmin() {
        checkIsAdmin();
        _;
    }

    /**
     * @notice Used in modifiers
     * @dev Function to check if address is belongs to manager or admin role
     */
    function checkIsManagerOrAdmin() internal view {
        if (!(hasRole(MANAGER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender))) {
            revert NotAManager();
        }
    }

    /**
     * @notice Used in modifiers
     * @dev Function to check if address is belongs to default admin role
     */
    function checkIsAdmin() internal view {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NotAnAdmin();
        }
    }

    function initialize(address _newManager) external initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, _newManager);
    }

    function updateCrossChainStats(
        string calldata _date,
        uint256 _volumeUSDC,
        uint256 _transactionCount
    ) external onlyManagerOrAdmin {
        dateToLastIndexCrossChain[_date] += 1;

        emit CrossChain(dateToLastIndexCrossChain[_date], _date, _volumeUSDC, _transactionCount);
    }

    function updateBridgeStats(
        string calldata _date,
        uint256 _volumeUSDC,
        uint256 _transactionCount
    ) external onlyManagerOrAdmin {
        dateToLastIndexBridge[_date] += 1;

        emit Bridge(dateToLastIndexBridge[_date], _date, _volumeUSDC, _transactionCount);
    }

    function updateOnChainStats(
        string calldata _date,
        uint256 _volumeUSDC,
        uint256 _transactionCount
    ) external onlyManagerOrAdmin {
        dateToLastIndexOnChain[_date] += 1;

        emit OnChain(dateToLastIndexOnChain[_date], _date, _volumeUSDC, _transactionCount);
    }

    function updateCrossChainStatsMulti(
        string[] calldata _date,
        uint256[] calldata _volumeUSDC,
        uint256[] calldata _transactionCount
    ) external onlyManagerOrAdmin {
        uint256 dateLength = _date.length;
        require(
            dateLength == _volumeUSDC.length && dateLength == _transactionCount.length,
            'RubicStats: Incorrect length'
        );
        for (uint256 i; i < dateLength; ) {
            dateToLastIndexCrossChain[_date[i]] += 1;

            emit CrossChain(dateToLastIndexCrossChain[_date[i]], _date[i], _volumeUSDC[i], _transactionCount[i]);
            unchecked {
                ++i;
            }
        }
    }

    function updateBridgeStatsMulti(
        string[] calldata _date,
        uint256[] calldata _volumeUSDC,
        uint256[] calldata _transactionCount
    ) external onlyManagerOrAdmin {
        uint256 dateLength = _date.length;
        require(
            dateLength == _volumeUSDC.length && dateLength == _transactionCount.length,
            'RubicStats: Incorrect length'
        );
        for (uint256 i; i < dateLength; ) {
            dateToLastIndexBridge[_date[i]] += 1;

            emit Bridge(dateToLastIndexBridge[_date[i]], _date[i], _volumeUSDC[i], _transactionCount[i]);
            unchecked {
                ++i;
            }
        }
    }

    function updateOnChainStatsMulti(
        string[] calldata _date,
        uint256[] calldata _volumeUSDC,
        uint256[] calldata _transactionCount
    ) external onlyManagerOrAdmin {
        uint256 dateLength = _date.length;
        require(
            dateLength == _volumeUSDC.length && dateLength == _transactionCount.length,
            'RubicStats: Incorrect length'
        );
        for (uint256 i; i < dateLength; ) {
            dateToLastIndexOnChain[_date[i]] += 1;

            emit OnChain(dateToLastIndexOnChain[_date[i]], _date[i], _volumeUSDC[i], _transactionCount[i]);
            unchecked {
                ++i;
            }
        }
    }

    function sweepTokens(address _token, uint256 _amount) external onlyAdmin {
        sendToken(_token, _amount, msg.sender);
    }

    function sendToken(
        address _token,
        uint256 _amount,
        address _receiver
    ) internal {
        if (_token == address(0)) {
            AddressUpgradeable.sendValue(payable(_receiver), _amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_receiver, _amount);
        }
    }

    /**
     * @dev Transfers admin role
     * @param _newAdmin New admin's address
     */
    function transferAdmin(address _newAdmin) external onlyAdmin {
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    }

    /**
     * @dev Plain fallback function to receive native
     */
    receive() external payable {}

    /**
     * @dev Plain fallback function
     */
    fallback() external {}
}