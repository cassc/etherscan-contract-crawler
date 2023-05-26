// SPDX-FileCopyrightText: 2022 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../feeDistributorFactory/IFeeDistributorFactory.sol";
import "../assetRecovering/OwnableTokenRecoverer.sol";
import "./IFeeDistributor.sol";

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
    * @dev Set values that are constant, common for all the clients, known at the initial deploy time.
    * @param _factory address of FeeDistributorFactory
    * @param _service address of the service (P2P) fee recipient
    */
    constructor(
        address _factory,
        address payable _service
    ) {
        if (!ERC165Checker.supportsInterface(_factory, type(IFeeDistributorFactory).interfaceId)) {
            revert FeeDistributor__NotFactory(_factory);
        }
        if (_service == address(0)) {
            revert FeeDistributor__ZeroAddressService();
        }

        i_factory = IFeeDistributorFactory(_factory);
        i_service = _service;

        bool serviceCanReceiveEther = _sendValue(_service, 0);
        if (!serviceCanReceiveEther) {
            revert FeeDistributor__ServiceCannotReceiveEther(_service);
        }
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
    */
    function initialize(FeeRecipient calldata _clientConfig, FeeRecipient calldata _referrerConfig) external {
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
    */
    function withdraw() external nonReentrant {
        if (s_clientConfig.recipient == address(0)) {
            revert FeeDistributor__ClientNotSet();
        }

        // get the contract's balance
        uint256 balance = address(this).balance;

        if (balance == 0) {
            // revert if there is no ether to withdraw
            revert FeeDistributor__NothingToWithdraw();
        }

        // how much should client get
        uint256 clientAmount = (balance * s_clientConfig.basisPoints) / 10000;

        // how much should service get
        uint256 serviceAmount = balance - clientAmount;

        // how much should referrer get
        uint256 referrerAmount;

        if (s_referrerConfig.recipient != address(0)) {
            // if there is a referrer

            referrerAmount = (balance * s_referrerConfig.basisPoints) / 10000;
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
    */
    function recoverEther(address payable _to) external onlyOwner {
        this.withdraw();

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
     * @dev Returns the factory address
     */
    function getFactory() external view returns (address) {
        return address(i_factory);
    }

    /**
     * @dev Returns the service address
     */
    function getService() external view returns (address) {
        return i_service;
    }

    /**
     * @dev Returns the client address
     */
    function getClient() external view returns (address) {
        return s_clientConfig.recipient;
    }

    /**
     * @dev Returns the client basis points
     */
    function getClientBasisPoints() external view returns (uint256) {
        return s_clientConfig.basisPoints;
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