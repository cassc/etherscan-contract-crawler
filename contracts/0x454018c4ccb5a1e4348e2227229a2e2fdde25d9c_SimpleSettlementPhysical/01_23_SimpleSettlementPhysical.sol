// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";

// inherited contracts
import {SimpleSettlementBase} from "./SimpleSettlementBase.sol";

// external libraries
import {ActionUtil} from "pomace/libraries/ActionUtil.sol";

// interfaces
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IPomace} from "pomace/interfaces/IPomace.sol";
import {IMarginEnginePhysical} from "../../../interfaces/IMarginEngine.sol";
import {IAuctionVaultPhysical} from "../../../interfaces/IAuctionVault.sol";

import "pomace/config/types.sol";
import "./types.sol";
import "./errors.sol";

contract SimpleSettlementPhysical is SimpleSettlementBase {
    using ActionUtil for ActionArgs[];
    using ActionUtil for BatchExecute[];

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _domainName, string memory _domainVersion, address _auctioneer)
        SimpleSettlementBase(_domainName, _domainVersion, _auctioneer)
    {}

    /**
     * @notice Settles a single bid
     * @dev revokes access to counterparty (msg.sender) after complete
     * @param _bid is the signed data type containing bid information
     * @param _collateralIds array of pomace ids for erc20 tokens needed to collateralize options
     * @param _amounts array of (counterparty) deposit amounts for each collateral + premium (if applicable)
     */
    function settle(Bid calldata _bid, uint8[] calldata _collateralIds, uint256[] calldata _amounts) external override {
        _assertBidValid(_bid);

        IAuctionVaultPhysical vault = IAuctionVaultPhysical(_bid.vault);

        vault.verifyOptions(_bid.options);

        ActionArgs[] memory deposits = _createDeposits(_collateralIds, _amounts, msg.sender);

        (ActionArgs[] memory sActions, ActionArgs[] memory bMints) =
            _createMints(_bid.vault, msg.sender, _bid.options, _bid.weights);

        ActionArgs[] memory bActions = deposits.concat(bMints);

        if (_bid.premium != 0) {
            ActionArgs memory premiumAction = _createPremiumTransfer(vault, _bid.premium);

            if (_bid.premium > 0) bActions = bActions.append(premiumAction);
            else sActions = sActions.append(premiumAction);
        }

        BatchExecute[] memory batch;

        // batch execute vault actions
        if (sActions.length > 0) batch = batch.append(BatchExecute(_bid.vault, sActions));

        // batch execute counterparty actions
        if (bActions.length > 0) batch = batch.append(BatchExecute(msg.sender, bActions));

        emit SettledBid(_bid.nonce, _bid.vault, msg.sender);

        IMarginEnginePhysical marginEngine = vault.marginEngine();

        marginEngine.batchExecute(batch);

        marginEngine.revokeSelfAccess(msg.sender);
    }

    /**
     * @notice Settles a several bids
     * @dev    revokes access to counterparty (msg.sender) after settlement
     * @param _bids is array of signed data types containing bid information
     * @param _collateralIds array of asset id for erc20 tokens needed to collateralize options
     * @param _amounts array of (counterparty) deposit amounts for each collateral + premium (if applicable)
     */
    function settleBatch(Bid[] calldata _bids, uint8[] calldata _collateralIds, uint256[] calldata _amounts) external override {
        ActionArgs[] memory depositActions = _createDeposits(_collateralIds, _amounts, msg.sender);

        IAuctionVaultPhysical vault = IAuctionVaultPhysical(_bids[0].vault);

        (BatchExecute[] memory batch, ActionArgs[] memory bActions, uint256[] memory nonces, address[] memory vaults) =
            _setupBidActionsBulk(vault, _bids);

        // batch execute counterparty actions
        if (depositActions.length > 0 || bActions.length > 0) {
            batch = batch.append(BatchExecute(msg.sender, depositActions.concat(bActions)));
        }

        emit SettledBids(nonces, vaults, msg.sender);

        IMarginEnginePhysical marginEngine = vault.marginEngine();

        marginEngine.batchExecute(batch);

        marginEngine.revokeSelfAccess(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Bulk created bid related actions (verification of options, mints, premium transfers)
     */
    function _setupBidActionsBulk(IAuctionVaultPhysical _vault, Bid[] calldata _bids)
        internal
        returns (BatchExecute[] memory batch, ActionArgs[] memory bActions, uint256[] memory nonces, address[] memory vaults)
    {
        uint256 bidCount = _bids.length;

        nonces = new uint256[](bidCount);
        vaults = new address[](bidCount);

        for (uint256 i; i < bidCount;) {
            _assertBidValid(_bids[i]);

            _vault.verifyOptions(_bids[i].options);

            (ActionArgs[] memory sActions, ActionArgs[] memory bMints) =
                _createMints(_bids[i].vault, msg.sender, _bids[i].options, _bids[i].weights);

            if (bMints.length > 0) bActions = bActions.concat(bMints);

            if (_bids[i].premium != 0) {
                ActionArgs memory premiumAction = _createPremiumTransfer(_vault, _bids[i].premium);

                if (_bids[i].premium > 0) bActions = bActions.append(premiumAction);
                else sActions = sActions.append(premiumAction);
            }

            // batch execute vault actions
            if (sActions.length > 0) batch = batch.append(BatchExecute(_bids[i].vault, sActions));

            nonces[i] = _bids[i].nonce;
            vaults[i] = _bids[i].vault;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Helper function to transfer premium action
     * @dev    Assumes premium payer has collateral in margin account
     * @return action encoded transfer instruction
     */
    function _createPremiumTransfer(IAuctionVaultPhysical _vault, int256 _premium) internal view returns (ActionArgs memory) {
        address to = address(_vault);

        if (_premium < 0) {
            to = msg.sender;
            _premium *= -1;
        }

        return ActionUtil.createTransferCollateralAction(_vault.getCollaterals()[0].id, uint256(_premium), to);
    }

    /**
     * @notice Helper function to setup deposit collateral actions
     * @dev    Assumes  has collateral in margin account
     * @return actions array of collateral deposits for counterparty
     */
    function _createDeposits(uint8[] memory _collateralIds, uint256[] memory _amounts, address _from)
        internal
        pure
        returns (ActionArgs[] memory actions)
    {
        unchecked {
            if (_collateralIds.length == 0) return actions;

            if (_collateralIds.length != _amounts.length) revert LengthMismatch();

            actions = new ActionArgs[](_collateralIds.length);

            for (uint256 i; i < _collateralIds.length; ++i) {
                actions[i] = ActionUtil.createAddCollateralAction(_collateralIds[i], _amounts[i], _from);
            }
        }
    }

    /**
     * @notice Helper function to setup mint options action
     * @return vault array of option mints for vault
     * @return counterparty array of option mints for counterparty
     */
    function _createMints(address _vault, address _counterparty, uint256[] memory _options, int256[] memory _weights)
        internal
        pure
        returns (ActionArgs[] memory vault, ActionArgs[] memory counterparty)
    {
        unchecked {
            if (_options.length != _weights.length) revert LengthMismatch();

            for (uint256 i; i < _options.length; ++i) {
                int256 weight = _weights[i];

                if (weight == 0) continue;

                // counterparty receives negative weighted instruments (vault is short)
                // vault receives positive weighted instruments (vault long)
                if (weight < 0) {
                    vault = vault.append(ActionUtil.createMintIntoAccountAction(_options[i], uint256(-weight), _counterparty));
                } else {
                    counterparty =
                        counterparty.append(ActionUtil.createMintIntoAccountAction(_options[i], uint256(weight), _vault));
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                                View Functions
    //////////////////////////////////////////////////////////////*/

    function verifyBid(Bid calldata _bid, uint8[] calldata _collateralIds, uint256[] calldata _amounts)
        external
        view
        returns (uint256 errorCount, bytes32[] memory errors)
    {
        errors = new bytes32[](20);

        {
            address signer = ECDSA.recover(_getDigest(_bid), _bid.v, _bid.r, _bid.s);

            if (signer != auctioneer) {
                errors[errorCount] = "AUCTIONEER_INCORRECT";
                ++errorCount;
            }

            if (noncesUsed[_bid.nonce]) {
                errors[errorCount] = "NONCE_ALREADY_USED";
                ++errorCount;
            }

            if (_bid.expiry <= block.timestamp) {
                errors[errorCount] = "BID_EXPIRED";
                ++errorCount;
            }
        }

        IAuctionVaultPhysical vault = IAuctionVaultPhysical(_bid.vault);
        IMarginEnginePhysical marginEngine;
        IPomace pomace;

        {
            try vault.marginEngine() returns (IMarginEnginePhysical _engine) {
                marginEngine = _engine;
                pomace = marginEngine.pomace();
            } catch {
                errors[errorCount] = "VAULT_INVALID";
                ++errorCount;
            }
        }

        {
            if (address(pomace) != address(0)) {
                for (uint256 i; i < _collateralIds.length; ++i) {
                    (address addr,) = pomace.assets(_collateralIds[i]);
                    IERC20 collateral = IERC20(addr);

                    if (collateral.balanceOf(msg.sender) < _amounts[i]) {
                        errors[errorCount] = "COLLATERAL_BALANCE_LOW";
                        ++errorCount;
                    }

                    if (address(marginEngine) != address(0)) {
                        if (collateral.allowance(msg.sender, address(marginEngine)) < _amounts[i]) {
                            errors[errorCount] = "COLLATERAL_ALLOWANCE_LOW";
                            ++errorCount;
                        }
                    }
                }
            }
        }

        {
            // Premium balance and allowance check
            address premiumPayer;
            uint256 premium;

            if (_bid.premium > 0) {
                premiumPayer = msg.sender;
                premium = uint256(_bid.premium);
            } else if (_bid.premium < 0) {
                premiumPayer = _bid.vault;
                premium = uint256(-_bid.premium);
            }

            if (premiumPayer != address(0) || address(pomace) != address(0)) {
                (address addr,) = pomace.assets(vault.getCollaterals()[0].id);

                if (IERC20(addr).balanceOf(premiumPayer) < premium) {
                    errors[errorCount] = "PREMIUM_BALANCE_LOW";
                    ++errorCount;
                }

                if (IERC20(addr).allowance(premiumPayer, address(this)) < premium) {
                    errors[errorCount] = "PREMIUM_ALLOWANCE_LOW";
                    ++errorCount;
                }
            }
        }

        {
            if (address(marginEngine) != address(0)) {
                (ActionArgs[] memory sMints, ActionArgs[] memory bMints) =
                    _createMints(_bid.vault, msg.sender, _bid.options, _bid.weights);

                uint160 maskedId = uint160(_bid.vault) | 0xFF;
                if (marginEngine.allowedExecutionLeft(maskedId, address(this)) < sMints.length) {
                    errors[errorCount] = "VAULT_MARGIN_ACCESS_LOW";
                    ++errorCount;
                }

                maskedId = uint160(msg.sender) | 0xFF;
                if (marginEngine.allowedExecutionLeft(maskedId, address(this)) < _collateralIds.length + bMints.length) {
                    errors[errorCount] = "COUNTERPARTY_MARGIN_ACCESS_LOW";
                    ++errorCount;
                }
            }
        }
    }
}