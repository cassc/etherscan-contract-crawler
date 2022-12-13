// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../libraries/AssetLib.sol";
import "./RecrowTransfer.sol";

/**
 * @title RecrowEscrow
 * @notice Manages escrow logic
 */
abstract contract RecrowEscrow is RecrowTransfer {
    /*//////////////////////////////////////////////////////////////
                             ESCROW STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps order ids to their deposit existence.
    mapping(bytes32 => bool) private _deposits;
    /// @notice Maps order ids to their completion status.
    mapping(bytes32 => bool) private _completed;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposited(
        bytes32 indexed id,
        address indexed payee,
        AssetLib.AssetData[] assets
    );
    event Paid(bytes32 indexed id, AssetLib.AssetData[] assets);
    event Withdrawn(
        bytes32 indexed id,
        address indexed payee,
        AssetLib.AssetData[] assets
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error DepositDoesNotExist();
    error DepositAlreadyExist();
    error EscrowCompleted();
    error ValueMismatch();

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if order has already exists.
     * @param id Hash id of the order.
     */
    modifier whenEscrowDeposited(bytes32 id) {
        if (!getDeposit(id)) revert DepositDoesNotExist();
        _;
    }

    /**
     * @notice Check if order already exists.
     * @param id Hash id of the order.
     */
    modifier whenNotEscrowDeposited(bytes32 id) {
        if (getDeposit(id)) revert DepositAlreadyExist();
        _;
    }

    /**
     * @notice Check if order is already completed.
     * @param id Hash id of the order.
     */
    modifier whenNotEscrowCompleted(bytes32 id) {
        if (getCompleted(id)) revert EscrowCompleted();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check completion status of an order.
     * @param id Hash id of the order.
     * @return True if order is already completed, false if not.
     */
    function getCompleted(bytes32 id) public view returns (bool) {
        return _completed[id];
    }

    /**
     * @notice Check existence of an order.
     * @param id Hash id of the order.
     * @return True if order exists, false if not.
     */
    function getDeposit(bytes32 id) public view returns (bool) {
        return _deposits[id];
    }

    /*//////////////////////////////////////////////////////////////
                            ESCROW LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Record and transfer assets to the escrow.
     * @dev Will revert if assets is empty.
     * @param id Hash id of the order.
     * @param payee Address that deposits the assets.
     * @param assets Assets that will be deposited.
     */
    function _createDeposit(
        bytes32 id,
        address payee,
        AssetLib.AssetData[] calldata assets
    ) internal whenNotEscrowDeposited(id) {
        _setDeposit(id, true);

        // Guard against msg.value being reused across multiple assets
        uint256 ethValue;
        uint256 assetsLength = assets.length;
        for (uint256 i = 0; i <= assetsLength - 1; ) {
            if (assets[i].assetType.assetClass == AssetLib.ETH_ASSET_CLASS) {
                ethValue += assets[i].value;
            }
            _transfer(assets[i], payee, address(this));

            unchecked {
                i++;
            }
        }
        if (ethValue != msg.value) {
            revert ValueMismatch();
        }
        emit Deposited(id, payee, assets);
    }

    /**
     * @notice Transfer the escrowed assets to their recipient.
     * @dev Will revert if assets is empty.
     * @param id Hash id of the order.
     * @param assets Assets that will be transferred.
     */
    function _pay(bytes32 id, AssetLib.AssetData[] calldata assets)
        internal
        whenEscrowDeposited(id)
        whenNotEscrowCompleted(id)
    {
        _setCompleted(id, true);

        uint256 assetsLength = assets.length;
        for (uint256 i = 0; i <= assetsLength - 1; ) {
            _transfer(assets[i], address(this), assets[i].recipient);

            unchecked {
                i++;
            }
        }
        emit Paid(id, assets);
    }

    /**
     * @notice Transfer the escrowed assets back to taker.
     * @dev Will revert if assets is empty.
     * @param id Hash id of the order.
     * @param assets Assets that will be transferred.
     */
    function _withdraw(
        bytes32 id,
        address payee,
        AssetLib.AssetData[] calldata assets
    ) internal whenEscrowDeposited(id) whenNotEscrowCompleted(id) {
        _setCompleted(id, true);

        uint256 assetsLength = assets.length;
        for (uint256 i = 0; i <= assetsLength - 1; ) {
            _transfer(assets[i], address(this), payee);

            unchecked {
                i++;
            }
        }
        emit Withdrawn(id, payee, assets);
    }

    /**
     * @notice Set order deposit status.
     * @param id Hash id of the order.
     * @param status Boolean value of the deposit status.
     */
    function _setDeposit(bytes32 id, bool status) internal {
        _deposits[id] = status;
    }

    /**
     * @notice Set order completion status.
     * @param id Hash id of the order.
     * @param status Boolean value of the completion status.
     */
    function _setCompleted(bytes32 id, bool status) internal {
        _completed[id] = status;
    }
}