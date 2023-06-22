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

/**
* @notice Should be a Oracle contract
* @param _passedAddress passed address that does not support IOracle interface
*/
error FeeDistributor__NotOracle(address _passedAddress);

/**
* @notice Initial client-only CL rewards must be zero
* @param _firstValidatorId passed value for firstValidatorId
*/
error FeeDistributor__InvalidFirstValidatorId(uint64 _firstValidatorId);

/**
* @notice Initial client-only CL rewards must be zero
* @param _validatorCount passed value for validatorCount
*/
error FeeDistributor__InvalidValidatorCount(uint16 _validatorCount);

/**
* @notice Should be a FeeDistributorFactory contract
* @param _passedAddress passed address that does not support IFeeDistributorFactory interface
*/
error FeeDistributor__NotFactory(address _passedAddress);

/**
* @notice Service address should be a secure P2P address, not zero.
*/
error FeeDistributor__ZeroAddressService();

/**
* @notice Client address should be different from service address.
* @param _passedAddress passed client address that equals to the service address
*/
error FeeDistributor__ClientAddressEqualsService(address _passedAddress);

/**
* @notice Client address should be an actual client address, not zero.
*/
error FeeDistributor__ZeroAddressClient();

/**
* @notice Client basis points should be >= 0 and <= 10000
* @param _clientBasisPoints passed incorrect client basis points
*/
error FeeDistributor__InvalidClientBasisPoints(uint96 _clientBasisPoints);

/**
* @notice The sum of (Client basis points + Referral basis points) should be >= 0 and <= 10000
* @param _clientBasisPoints passed client basis points
* @param _referralBasisPoints passed referral basis points
*/
error FeeDistributor__ClientPlusReferralBasisPointsExceed10000(uint96 _clientBasisPoints, uint96 _referralBasisPoints);

/**
* @notice Referrer address should be different from service address.
* @param _passedAddress passed referrer address that equals to the service address
*/
error FeeDistributor__ReferrerAddressEqualsService(address _passedAddress);

/**
* @notice Referrer address should be different from client address.
* @param _passedAddress passed referrer address that equals to the client address
*/
error FeeDistributor__ReferrerAddressEqualsClient(address _passedAddress);

/**
* @notice Only factory can call `initialize`.
* @param _msgSender sender address.
* @param _actualFactory the actual factory address that can call `initialize`.
*/
error FeeDistributor__NotFactoryCalled(address _msgSender, IFeeDistributorFactory _actualFactory);

/**
* @notice `initialize` should only be called once.
* @param _existingClient address of the client with which the contact has already been initialized.
*/
error FeeDistributor__ClientAlreadySet(address _existingClient);

/**
* @notice Cannot call `withdraw` if the client address is not set yet.
* @dev The client address is supposed to be set by the factory.
*/
error FeeDistributor__ClientNotSet();

/**
* @notice basisPoints of the referrer must be zero if referrer address is empty.
* @param _referrerBasisPoints basisPoints of the referrer.
*/
error FeeDistributor__ReferrerBasisPointsMustBeZeroIfAddressIsZero(uint96 _referrerBasisPoints);

/**
* @notice service should be able to receive ether.
* @param _service address of the service.
*/
error FeeDistributor__ServiceCannotReceiveEther(address _service);

/**
* @notice client should be able to receive ether.
* @param _client address of the client.
*/
error FeeDistributor__ClientCannotReceiveEther(address _client);

/**
* @notice referrer should be able to receive ether.
* @param _referrer address of the referrer.
*/
error FeeDistributor__ReferrerCannotReceiveEther(address _referrer);

/**
* @notice zero ether balance
*/
error FeeDistributor__NothingToWithdraw();

/**
* @notice cannot withdraw until rewards (CL+EL) are enough to be split
*/
error FeeDistributor__WaitForEnoughRewardsToWithdraw();

/**
* @notice Throws if called by any account other than the client.
* @param _caller address of the caller
* @param _client address of the client
*/
error FeeDistributor__CallerNotClient(address _caller, address _client);

/**
* @title Contract receiving MEV and priority fees
* and distributing them to the service and the client.
*/
contract FeeDistributor is OwnableTokenRecoverer, ReentrancyGuard, ERC165, IFeeDistributor {
    // State variables

    /**
    * @notice address of FeeDistributorFactory
    */
    IFeeDistributorFactory private immutable i_factory;

    /**
    * @notice address of Oracle
    */
    IOracle private immutable i_oracle;

    /**
    * @notice address of the service (P2P) fee recipient
    */
    address payable private immutable i_service;

    /**
    * @notice client config (address of the client, client basis points)
    */
    FeeRecipient private s_clientConfig;

    /**
    * @notice referrer config (address of the referrer, referrer basis points)
    */
    FeeRecipient private s_referrerConfig;

    /**
    * @notice amount of CL rewards (in Wei) that should belong to the client only
    * and should not be considered for splitting between the service and the referrer
    */
    ValidatorData private s_validatorData;

    /**
    * @dev Set values that are constant, common for all the clients, known at the initial deploy time.
    * @param _factory address of FeeDistributorFactory
    * @param _service address of the service (P2P) fee recipient
    */
    constructor(
        address _oracle,
        address _factory,
        address payable _service
    ) {
        if (!ERC165Checker.supportsInterface(_oracle, type(IOracle).interfaceId)) {
            revert FeeDistributor__NotOracle(_factory);
        }
        if (!ERC165Checker.supportsInterface(_factory, type(IFeeDistributorFactory).interfaceId)) {
            revert FeeDistributor__NotFactory(_factory);
        }
        if (_service == address(0)) {
            revert FeeDistributor__ZeroAddressService();
        }

        i_oracle = IOracle(_oracle);
        i_factory = IFeeDistributorFactory(_factory);
        i_service = _service;

        bool serviceCanReceiveEther = _sendValue(_service, 0);
        if (!serviceCanReceiveEther) {
            revert FeeDistributor__ServiceCannotReceiveEther(_service);
        }
    }

    /**
    * @dev Throws if called by any account other than the client.
    */
    modifier onlyClient() {
        address caller = _msgSender();
        address clientAddress = s_clientConfig.recipient;

        if (clientAddress != caller) {
            revert FeeDistributor__CallerNotClient(caller, clientAddress);
        }
        _;
    }

    // Functions

    /**
    * @notice Accept ether from transactions
    */
    receive() external payable {
        // only accept ether in an instance, not in a template
        if (s_clientConfig.recipient == address(0)) {
            revert FeeDistributor__ClientNotSet();
        }
    }

    /**
    * @notice Set client address.
    * @dev Could not be in the constructor since it is different for different clients.
    * @dev _referrerConfig can be zero if there is no referrer.
    * @param _clientConfig address and basis points (percent * 100) of the client
    * @param _referrerConfig address and basis points (percent * 100) of the referrer.
    * @param _validatorData clientOnlyClRewards, firstValidatorId, and validatorCount
    */
    function initialize(
        FeeRecipient calldata _clientConfig,
        FeeRecipient calldata _referrerConfig,
        ValidatorData calldata _validatorData
    ) external {
        if (msg.sender != address(i_factory)) {
            revert FeeDistributor__NotFactoryCalled(msg.sender, i_factory);
        }
        if (_clientConfig.recipient == address(0)) {
            revert FeeDistributor__ZeroAddressClient();
        }
        if (_clientConfig.recipient == i_service) {
            revert FeeDistributor__ClientAddressEqualsService(_clientConfig.recipient);
        }
        if (s_clientConfig.recipient != address(0)) {
            revert FeeDistributor__ClientAlreadySet(s_clientConfig.recipient);
        }
        if (_clientConfig.basisPoints > 10000) {
            revert FeeDistributor__InvalidClientBasisPoints(_clientConfig.basisPoints);
        }
        if (_validatorData.firstValidatorId == 0) {
            revert FeeDistributor__InvalidFirstValidatorId(_validatorData.firstValidatorId);
        }
        if (_validatorData.validatorCount == 0) {
            revert FeeDistributor__InvalidValidatorCount(_validatorData.validatorCount);
        }

        if (_referrerConfig.recipient != address(0)) {// if there is a referrer
            if (_referrerConfig.recipient == i_service) {
                revert FeeDistributor__ReferrerAddressEqualsService(_referrerConfig.recipient);
            }
            if (_referrerConfig.recipient == _clientConfig.recipient) {
                revert FeeDistributor__ReferrerAddressEqualsClient(_referrerConfig.recipient);
            }
            if (_clientConfig.basisPoints + _referrerConfig.basisPoints > 10000) {
                revert FeeDistributor__ClientPlusReferralBasisPointsExceed10000(_clientConfig.basisPoints, _referrerConfig.basisPoints);
            }

            // set referrer config
            s_referrerConfig = _referrerConfig;

        } else {// if there is no referrer
            if (_referrerConfig.basisPoints != 0) {
                revert FeeDistributor__ReferrerBasisPointsMustBeZeroIfAddressIsZero(_referrerConfig.basisPoints);
            }
        }

        // set client config
        s_clientConfig = _clientConfig;

        // set validator data
        s_validatorData = _validatorData;

        emit Initialized(
            _clientConfig.recipient,
            _clientConfig.basisPoints,
            _referrerConfig.recipient,
            _referrerConfig.basisPoints
        );

        bool clientCanReceiveEther = _sendValue(_clientConfig.recipient, 0);
        if (!clientCanReceiveEther) {
            revert FeeDistributor__ClientCannotReceiveEther(_clientConfig.recipient);
        }
        if (_referrerConfig.recipient != address(0)) {// if there is a referrer
            bool referrerCanReceiveEther = _sendValue(_referrerConfig.recipient, 0);
            if (!referrerCanReceiveEther) {
                revert FeeDistributor__ReferrerCannotReceiveEther(_referrerConfig.recipient);
            }
        }
    }

    /**
    * @notice Withdraw the whole balance of the contract according to the pre-defined basis points.
    * @dev In case someone (either service, or client, or referrer) fails to accept ether,
    * the owner will be able to recover some of their share.
    * This scenario is very unlikely. It can only happen if that someone is a contract
    * whose receive function changed its behavior since FeeDistributor's initialization.
    * It can never happen unless the receiving party themselves wants it to happen.
    * We strongly recommend against intentional reverts in the receive function
    * because the remaining parties might call `withdraw` again multiple times without waiting
    * for the owner to recover ether for the reverting party.
    * In fact, as a punishment for the reverting party, before the recovering,
    * 1 more regular `withdraw` will happen, rewarding the non-reverting parties again.
    * `recoverEther` function is just an emergency backup plan and does not replace `withdraw`.
    *
    * @param _proof Merkle proof (the leaf's sibling, and each non-leaf hash that could not otherwise be calculated without additional leaf nodes)
    * @param _amountInGwei total CL rewards earned by all validators in GWei (see _validatorCount)
    */
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

        // read from storage once
        ValidatorData memory vd = s_validatorData;

        // verify the data from the caller against the oracle
        i_oracle.verify(_proof, vd.firstValidatorId, vd.validatorCount, _amountInGwei);

        // Gwei to Wei
        uint256 amount = _amountInGwei * (10 ** 9);

        if (balance + amount < vd.clientOnlyClRewards) {
            // Can happen if the client has called emergencyEtherRecoveryWithoutOracleData before
            // but the actual rewards amount now appeared to be lower than the already split.
            // Should happen rarely.

            revert FeeDistributor__WaitForEnoughRewardsToWithdraw();
        }

        // total to split = EL + CL - already split part of CL (should be OK unless halfBalance < serviceAmount)
        uint256 totalAmountToSplit = balance + amount - vd.clientOnlyClRewards;

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

        // client gets the rest from CL as not split anymore amount
        s_validatorData.clientOnlyClRewards = uint176(vd.clientOnlyClRewards + (totalAmountToSplit - balance));

        // how much should referrer get
        uint256 referrerAmount;

        if (s_referrerConfig.recipient != address(0)) {
            // if there is a referrer

            referrerAmount = (totalAmountToSplit * s_referrerConfig.basisPoints) / 10000;

            serviceAmount -= referrerAmount;

            // Send ETH to referrer. Ignore the possible yet unlikely revert in the receive function.
            _sendValue(s_referrerConfig.recipient, referrerAmount);
        }

        // Send ETH to service. Ignore the possible yet unlikely revert in the receive function.
        _sendValue(i_service, serviceAmount);

        // Send ETH to client. Ignore the possible yet unlikely revert in the receive function.
        _sendValue(s_clientConfig.recipient, clientAmount);

        emit Withdrawn(serviceAmount, clientAmount, referrerAmount);
    }

    /**
    * @notice Recover ether in a rare case when either service, or client, or referrer
    * refuse to accept ether.
    * @param _to receiver address
    * @param _proof Merkle proof (the leaf's sibling, and each non-leaf hash that could not otherwise be calculated without additional leaf nodes)
    * @param _amountInGwei total CL rewards earned by all validators in GWei (see _validatorCount)
    */
    function recoverEther(
        address payable _to,
        bytes32[] calldata _proof,
        uint256 _amountInGwei
    ) external onlyOwner {
        this.withdraw(_proof, _amountInGwei);

        // get the contract's balance
        uint256 balance = address(this).balance;

        if (balance > 0) { // only happens if at least 1 party reverted in their receive
            bool success = _sendValue(_to, balance);

            if (success) {
                emit EtherRecovered(_to, balance);
            } else {
                emit EtherRecoveryFailed(_to, balance);
            }
        }
    }

    /**
    * @notice SHOULD NEVER BE CALLED NORMALLY!!!! Recover ether if oracle data (Merkle proof) is not available for some reason.
    */
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

        // client gets the rest from CL as not split anymore amount
        s_validatorData.clientOnlyClRewards = uint176(s_validatorData.clientOnlyClRewards + (totalAmountToSplit - balance));

        // how much should referrer get
        uint256 referrerAmount;

        if (s_referrerConfig.recipient != address(0)) {
            // if there is a referrer

            referrerAmount = (totalAmountToSplit * s_referrerConfig.basisPoints) / 10000;

            serviceAmount -= referrerAmount;

            // Send ETH to referrer. Ignore the possible yet unlikely revert in the receive function.
            _sendValue(s_referrerConfig.recipient, referrerAmount);
        }

        // Send ETH to service. Ignore the possible yet unlikely revert in the receive function.
        _sendValue(i_service, serviceAmount);

        // Send ETH to client. Ignore the possible yet unlikely revert in the receive function.
        _sendValue(s_clientConfig.recipient, clientAmount);

        emit Withdrawn(serviceAmount, clientAmount, referrerAmount);
    }

    /**
     * @dev Returns the factory address
     */
    function factory() external view returns (address) {
        return address(i_factory);
    }

    /**
     * @dev Returns the service address
     */
    function service() external view returns (address) {
        return i_service;
    }

    /**
     * @dev Returns the client address
     */
    function client() external view returns (address) {
        return s_clientConfig.recipient;
    }

    /**
     * @dev Returns the client basis points
     */
    function clientBasisPoints() external view returns (uint256) {
        return s_clientConfig.basisPoints;
    }

    /**
    * @dev Returns the referrer address
     */
    function referrer() external view returns (address) {
        return s_referrerConfig.recipient;
    }

    /**
     * @dev Returns the referrer basis points
     */
    function referrerBasisPoints() external view returns (uint256) {
        return s_referrerConfig.basisPoints;
    }

    /**
    * @dev Returns First Validator Id
    */
    function firstValidatorId() external view returns (uint256) {
        return s_validatorData.firstValidatorId;
    }

    /**
    * @dev Returns a portion of CL rewards that should not be counted during withdraw (belongs to client only)
    */
    function clientOnlyClRewards() external view returns (uint256) {
        return s_validatorData.clientOnlyClRewards;
    }

    /**
    * @dev Returns validator count
    */
    function validatorCount() external view returns (uint256) {
        return s_validatorData.validatorCount;
    }

    /**
    * @dev See {IERC165-supportsInterface}.
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IFeeDistributor).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return i_factory.owner();
    }

    function _sendValue(address payable _recipient, uint256 _amount) internal returns (bool) {
        (bool success, ) = _recipient.call{
            value: _amount,
            gas: gasleft() / 4 // to prevent DOS, should be enough in normal cases
        }("");

        return success;
    }
}