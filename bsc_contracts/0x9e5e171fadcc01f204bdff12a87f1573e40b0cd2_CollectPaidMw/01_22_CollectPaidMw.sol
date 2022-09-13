// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { IEssenceMiddleware } from "../../interfaces/IEssenceMiddleware.sol";
import { ICyberEngine } from "../../interfaces/ICyberEngine.sol";

import { Constants } from "../../libraries/Constants.sol";

import { FeeMw } from "../base/FeeMw.sol";
import { SubscribeStatusMw } from "../base/SubscribeStatusMw.sol";

/**
 * @title  Collect Paid Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to only allow users to collect when they pay a certain fee to the essence owner.
 * the essence creator can choose to set rules including whether collecting this essence require previous subscription and
 * has a total supply.
 */
contract CollectPaidMw is IEssenceMiddleware, FeeMw {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                EVENT
    //////////////////////////////////////////////////////////////*/

    event CollectPaidMwSet(
        address indexed namespace,
        uint256 indexed profileId,
        uint256 indexed essenceId,
        uint256 totalSupply,
        uint256 amount,
        address recipient,
        address currency,
        bool subscribeRequired
    );

    /*//////////////////////////////////////////////////////////////
                               STATES
    //////////////////////////////////////////////////////////////*/

    struct CollectPaidData {
        uint256 totalSupply;
        uint256 currentCollect;
        uint256 amount;
        address recipient;
        address currency;
        bool subscribeRequired;
    }

    mapping(address => mapping(uint256 => mapping(uint256 => CollectPaidData)))
        internal _paidEssenceData;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address treasury) FeeMw(treasury) {}

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Stores the parameters for setting up the paid essence middleware, checks if the amount, recipient, and
     * currency is valid and approved
     */
    function setEssenceMwData(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata data
    ) external override returns (bytes memory) {
        (
            uint256 totalSupply,
            uint256 amount,
            address recipient,
            address currency,
            bool subscribeRequired
        ) = abi.decode(data, (uint256, uint256, address, address, bool));

        require(amount != 0, "INVALID_AMOUNT");
        require(recipient != address(0), "INVALID_ADDRESS");
        require(_currencyAllowed(currency), "CURRENCY_NOT_ALLOWED");

        _paidEssenceData[msg.sender][profileId][essenceId]
            .totalSupply = totalSupply;
        _paidEssenceData[msg.sender][profileId][essenceId].amount = amount;
        _paidEssenceData[msg.sender][profileId][essenceId]
            .recipient = recipient;
        _paidEssenceData[msg.sender][profileId][essenceId].currency = currency;
        _paidEssenceData[msg.sender][profileId][essenceId]
            .subscribeRequired = subscribeRequired;

        emit CollectPaidMwSet(
            msg.sender,
            profileId,
            essenceId,
            totalSupply,
            amount,
            recipient,
            currency,
            subscribeRequired
        );
        return new bytes(0);
    }

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Determines whether the collection requires prior subscription and whether there is a limit, and processes the transaction
     * from the essence collector to the essence owner.
     */
    function preProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address,
        bytes calldata
    ) external override {
        require(
            _paidEssenceData[msg.sender][profileId][essenceId].totalSupply -
                _paidEssenceData[msg.sender][profileId][essenceId]
                    .currentCollect >
                0,
            "COLLECT_LIMIT_EXCEEDED"
        );

        address currency = _paidEssenceData[msg.sender][profileId][essenceId]
            .currency;
        uint256 amount = _paidEssenceData[msg.sender][profileId][essenceId]
            .amount;
        uint256 treasuryCollected = (amount * _treasuryFee()) /
            Constants._MAX_BPS;
        uint256 actualPaid = amount - treasuryCollected;

        if (
            _paidEssenceData[msg.sender][profileId][essenceId]
                .subscribeRequired == true
        ) {
            require(
                SubscribeStatusMw.checkSubscribe(profileId, collector),
                "NOT_SUBSCRIBED"
            );
        }

        IERC20(currency).safeTransferFrom(
            collector,
            _paidEssenceData[msg.sender][profileId][essenceId].recipient,
            actualPaid
        );

        if (treasuryCollected > 0) {
            IERC20(currency).safeTransferFrom(
                collector,
                _treasuryAddress(),
                treasuryCollected
            );
        }
        _paidEssenceData[msg.sender][profileId][essenceId].currentCollect++;
    }

    /// @inheritdoc IEssenceMiddleware
    function postProcess(
        uint256,
        uint256,
        address,
        address,
        bytes calldata
    ) external {
        // do nothing
    }
}