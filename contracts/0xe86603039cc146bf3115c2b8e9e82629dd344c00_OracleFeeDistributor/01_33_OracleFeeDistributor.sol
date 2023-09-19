// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../feeDistributorFactory/IFeeDistributorFactory.sol";
import "../assetRecovering/OwnableTokenRecoverer.sol";
import "./IFeeDistributor.sol";
import "../oracle/IOracle.sol";
import "../structs/P2pStructs.sol";
import "./BaseFeeDistributor.sol";

/// @notice Should be a Oracle contract
/// @param _passedAddress passed address that does not support IOracle interface
error OracleFeeDistributor__NotOracle(address _passedAddress);

/// @notice cannot withdraw until rewards (CL+EL) are enough to be split
error OracleFeeDistributor__WaitForEnoughRewardsToWithdraw();

/// @notice clientOnlyClRewards can only be set once
error OracleFeeDistributor__CannotResetClientOnlyClRewards();

/// @notice Client basis points should be higher than 5000
error OracleFeeDistributor__ClientBasisPointsShouldBeHigherThan5000();

/// @title FeeDistributor accepting EL rewards only but splitting them with consideration of CL rewards
/// @dev CL rewards are received by the client directly since client's address is ETH2 withdrawal credentials
contract OracleFeeDistributor is BaseFeeDistributor {

    /// @notice Emits when clientOnlyClRewards has been updated
    /// @param _clientOnlyClRewards new value of clientOnlyClRewards
    event OracleFeeDistributor__ClientOnlyClRewardsUpdated(
        uint256 _clientOnlyClRewards
    );

    /// @notice address of Oracle
    IOracle private immutable i_oracle;

    /// @notice amount of CL rewards (in Wei) that should belong to the client only
    /// and should not be considered for splitting between the service and the referrer
    uint256 s_clientOnlyClRewards;

    /// @dev Set values that are constant, common for all the clients, known at the initial deploy time.
    /// @param _oracle address of Oracle
    /// @param _factory address of FeeDistributorFactory
    /// @param _service address of the service (P2P) fee recipient
    constructor(
        address _oracle,
        address _factory,
        address payable _service
    ) BaseFeeDistributor(_factory, _service) {
        if (!ERC165Checker.supportsInterface(_oracle, type(IOracle).interfaceId)) {
            revert OracleFeeDistributor__NotOracle(_oracle);
        }

        i_oracle = IOracle(_oracle);
    }

    /// @inheritdoc IFeeDistributor
    function initialize(
        FeeRecipient calldata _clientConfig,
        FeeRecipient calldata _referrerConfig
    ) public override {
        if (_clientConfig.basisPoints <= 5000) {
            revert OracleFeeDistributor__ClientBasisPointsShouldBeHigherThan5000();
        }

        super.initialize(_clientConfig, _referrerConfig);
    }

    /// @notice Set clientOnlyClRewards to a new value
    /// @param _clientOnlyClRewards new value of clientOnlyClRewards
    /// @dev may be needed when attaching this FeeDistributor to an existing validator.
    /// If previously earned rewards need not be split, they should be declared as client only.
    function setClientOnlyClRewards(uint256 _clientOnlyClRewards) external {
        i_factory.checkOperatorOrOwner(msg.sender);

        if (s_clientOnlyClRewards != 0) {
            revert OracleFeeDistributor__CannotResetClientOnlyClRewards();
        }

        s_clientOnlyClRewards = _clientOnlyClRewards;

        emit OracleFeeDistributor__ClientOnlyClRewardsUpdated(_clientOnlyClRewards);
    }

    /// @notice Withdraw the whole balance of the contract according to the pre-defined basis points.
    /// @dev In case someone (either service, or client, or referrer) fails to accept ether,
    /// the owner will be able to recover some of their share.
    /// This scenario is very unlikely. It can only happen if that someone is a contract
    /// whose receive function changed its behavior since FeeDistributor's initialization.
    /// It can never happen unless the receiving party themselves wants it to happen.
    /// We strongly recommend against intentional reverts in the receive function
    /// because the remaining parties might call `withdraw` again multiple times without waiting
    /// for the owner to recover ether for the reverting party.
    /// In fact, as a punishment for the reverting party, before the recovering,
    /// 1 more regular `withdraw` will happen, rewarding the non-reverting parties again.
    /// `recoverEther` function is just an emergency backup plan and does not replace `withdraw`.
    ///
    /// @param _proof Merkle proof (the leaf's sibling, and each non-leaf hash that could not otherwise be calculated without additional leaf nodes)
    /// @param _amountInGwei total CL rewards earned by all validators in GWei (see _validatorCount)
    function withdraw(
        bytes32[] calldata _proof,
        uint256 _amountInGwei
    ) external nonReentrant {
        if (s_clientConfig.recipient == address(0)) {
            revert FeeDistributor__ClientNotSet();
        }

        // get the contract's balance
        uint256 balance = address(this).balance;

        if (balance == 0) {
            // revert if there is no ether to withdraw
            revert FeeDistributor__NothingToWithdraw();
        }

        // verify the data from the caller against the oracle
        i_oracle.verify(_proof, address(this), _amountInGwei);

        // Gwei to Wei
        uint256 amount = _amountInGwei * (10 ** 9);

        if (amount < s_clientOnlyClRewards) {
            // Can happen if the client has called emergencyEtherRecoveryWithoutOracleData before
            // but the actual rewards amount now appeared to be lower than the already split.
            // Should happen rarely.

            revert OracleFeeDistributor__WaitForEnoughRewardsToWithdraw();
        }

        // total to split = EL + CL - already split part of CL (should be OK unless halfBalance < serviceAmount)
        uint256 totalAmountToSplit = balance + amount - s_clientOnlyClRewards;

        // set client basis points to value from storage config
        uint256 clientBp = s_clientConfig.basisPoints;

        // how much should service get
        uint256 serviceAmount = totalAmountToSplit - ((totalAmountToSplit * clientBp) / 10000);

        uint256 halfBalance = balance / 2;

        // how much should client get
        uint256 clientAmount;

        // if a half of the available balance is not enough to cover service (and referrer) shares
        // can happen when CL rewards (only accessible by client) are way much than EL rewards
        if (serviceAmount > halfBalance) {
            // client gets 50% of EL rewards
            clientAmount = halfBalance;

            // service (and referrer) get 50% of EL rewards combined (+1 wei in case balance is odd)
            serviceAmount = balance - halfBalance;

            // update the total amount being split to a smaller value to fit the actual balance of this contract
            totalAmountToSplit = (halfBalance * 10000) / (10000 - clientBp);
        } else {
            // send the remaining balance to client
            clientAmount = balance - serviceAmount;
        }

        emit OracleFeeDistributor__ClientOnlyClRewardsUpdated(s_clientOnlyClRewards);

        bool someEthSent;

        // how much should referrer get
        uint256 referrerAmount;

        if (s_referrerConfig.recipient != address(0)) {
            // if there is a referrer

            referrerAmount = (totalAmountToSplit * s_referrerConfig.basisPoints) / 10000;

            serviceAmount -= referrerAmount;

            // Send ETH to referrer. Ignore the possible yet unlikely revert in the receive function.
            someEthSent = P2pAddressLib._sendValue(s_referrerConfig.recipient, referrerAmount);
        }

        // Send ETH to service. Ignore the possible yet unlikely revert in the receive function.
        someEthSent = P2pAddressLib._sendValue(i_service, serviceAmount) || someEthSent;

        // Send ETH to client. Ignore the possible yet unlikely revert in the receive function.
        someEthSent = P2pAddressLib._sendValue(s_clientConfig.recipient, clientAmount) || someEthSent;

        if (someEthSent) {
            // client gets the rest from CL as not split anymore amount
            s_clientOnlyClRewards += (totalAmountToSplit - balance);
        }

        emit FeeDistributor__Withdrawn(
            serviceAmount,
            clientAmount,
            referrerAmount
        );
    }

    /// @notice Recover ether in a rare case when either service, or client, or referrer
    /// refuse to accept ether.
    /// @param _to receiver address
    /// @param _proof Merkle proof (the leaf's sibling, and each non-leaf hash that could not otherwise be calculated without additional leaf nodes)
    /// @param _amountInGwei total CL rewards earned by all validators in GWei (see _validatorCount)
    function recoverEther(
        address payable _to,
        bytes32[] calldata _proof,
        uint256 _amountInGwei
    ) external onlyOwner {
        if (_to == address(0)) {
            revert FeeDistributor__ZeroAddressEthReceiver();
        }

        this.withdraw(_proof, _amountInGwei);

        // get the contract's balance
        uint256 balance = address(this).balance;

        if (balance > 0) { // only happens if at least 1 party reverted in their receive
            bool success = P2pAddressLib._sendValueWithoutGasRestrictions(_to, balance);

            if (success) {
                emit FeeDistributor__EtherRecovered(_to, balance);
            } else {
                revert FeeDistributor__EtherRecoveryFailed(_to, balance);
            }
        }
    }

    /// @notice SHOULD NEVER BE CALLED NORMALLY!!!! Recover ether if oracle data (Merkle proof) is not available for some reason.
    function emergencyEtherRecoveryWithoutOracleData() external onlyClient nonReentrant {
        // get the contract's balance
        uint256 balance = address(this).balance;

        if (balance == 0) {
            // revert if there is no ether to withdraw
            revert FeeDistributor__NothingToWithdraw();
        }

        uint256 halfBalance = balance / 2;

        // client gets 50% of EL rewards
        uint256 clientAmount = halfBalance;

        // service (and referrer) get 50% of EL rewards combined (+1 wei in case balance is odd)
        uint256 serviceAmount = balance - halfBalance;

        // the total amount being split fits the actual balance of this contract
        uint256 totalAmountToSplit = (halfBalance * 10000) / (10000 - s_clientConfig.basisPoints);

        emit OracleFeeDistributor__ClientOnlyClRewardsUpdated(s_clientOnlyClRewards);

        bool someEthSent;

        // how much should referrer get
        uint256 referrerAmount;

        if (s_referrerConfig.recipient != address(0)) {
            // if there is a referrer

            referrerAmount = (totalAmountToSplit * s_referrerConfig.basisPoints) / 10000;

            serviceAmount -= referrerAmount;

            // Send ETH to referrer. Ignore the possible yet unlikely revert in the receive function.
            someEthSent = P2pAddressLib._sendValue(s_referrerConfig.recipient, referrerAmount);
        }

        // Send ETH to service. Ignore the possible yet unlikely revert in the receive function.
        someEthSent = P2pAddressLib._sendValue(i_service, serviceAmount) || someEthSent;

        // Send ETH to client. Ignore the possible yet unlikely revert in the receive function.
        someEthSent = P2pAddressLib._sendValue(s_clientConfig.recipient, clientAmount) || someEthSent;

        if (someEthSent) {
            // client gets the rest from CL as not split anymore amount
            s_clientOnlyClRewards += (totalAmountToSplit - balance);
        }

        emit FeeDistributor__Withdrawn(
            serviceAmount,
            clientAmount,
            referrerAmount
        );
    }

    /// @notice amount of CL rewards (in Wei) that should belong to the client only
    /// and should not be considered for splitting between the service and the referrer
    /// @return uint256 amount of client only CL rewards
    function clientOnlyClRewards() external view returns (uint256) {
        return s_clientOnlyClRewards;
    }

    /// @notice Returns the oracle address
    /// @return address oracle address
    function oracle() external view returns (address) {
        return address(i_oracle);
    }

    /// @inheritdoc Erc4337Account
    function withdrawSelector() public pure override returns (bytes4) {
        return OracleFeeDistributor.withdraw.selector;
    }

    /// @inheritdoc IFeeDistributor
    /// @dev client address
    function eth2WithdrawalCredentialsAddress() external override view returns (address) {
        return s_clientConfig.recipient;
    }
}