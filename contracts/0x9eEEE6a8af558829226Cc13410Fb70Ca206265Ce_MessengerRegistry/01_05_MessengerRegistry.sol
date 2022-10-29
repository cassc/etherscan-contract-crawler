// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import './interfaces/IMessenger.sol';
import './interfaces/IMessengerRegistry.sol';

/**
 * @title MessengerRegistry
 * @notice MessengerRegistry is a contract to register openly distributed Messengers
 */
contract MessengerRegistry is IMessengerRegistry {
    /// @notice struct to store the definition of Messenger
    struct Messenger {
        address ownerAddress;
        address messengerAddress;
        string specificationUrl;
        uint256 precision;
        uint256 requestsCounter;
        uint256 fulfillsCounter;
        uint256 id;
    }

    /// @notice messengers
    Messenger[] private _messengers;
    /// @notice (messengerAddress=>bool) to check if the Messenger was registered
    mapping(address => bool) private _registeredMessengers;
    /// @notice (userAddress=>messengerAddress[]) to register the messengers of an owner
    mapping(address => uint256[]) private _ownerMessengers;
    /// @notice SLARegistry address
    address private _slaRegistry;

    /// @notice an event that is emitted when SLARegistry registers a new messenger
    event MessengerRegistered(
        address indexed ownerAddress,
        address indexed messengerAddress,
        string specificationUrl,
        uint256 precision,
        uint256 id
    );

    /// @notice an event that is emitted when Messenger owner modifies the messenger
    event MessengerModified(
        address indexed ownerAddress,
        address indexed messengerAddress,
        string specificationUrl,
        uint256 precision,
        uint256 id
    );

    /**
     * @notice function to set SLARegistry address
     * @dev this function can be called only once
     */
    function setSLARegistry() external override {
        require(
            address(_slaRegistry) == address(0),
            'SLARegistry address has already been set'
        );

        _slaRegistry = msg.sender;
    }

    /**
     * @notice function to register a new Messenger
     * @dev only SLARegistry can call this function
     * @param callerAddress_ messenger owner address
     * @param messengerAddress_ messenger address
     * @param specificationUrl_ specification url of messenger
     */
    function registerMessenger(
        address callerAddress_,
        address messengerAddress_,
        string calldata specificationUrl_
    ) external override {
        require(
            msg.sender == _slaRegistry,
            'Should only be called using the SLARegistry contract'
        );
        require(messengerAddress_ != address(0x0), 'invalid messenger address');
        require(
            !_registeredMessengers[messengerAddress_],
            'messenger already registered'
        );

        IMessenger messenger = IMessenger(messengerAddress_);
        address messengerOwner = messenger.owner();
        require(
            messengerOwner == callerAddress_,
            'Should only be called by the messenger owner'
        );
        uint256 precision = messenger.messengerPrecision();
        uint256 requestsCounter = messenger.requestsCounter();
        uint256 fulfillsCounter = messenger.fulfillsCounter();
        _registeredMessengers[messengerAddress_] = true;
        uint256 id = _messengers.length;
        _ownerMessengers[messengerOwner].push(id);

        require(
            precision % 100 == 0 && precision != 0,
            'invalid messenger precision, cannot register messanger'
        );

        _messengers.push(
            Messenger({
                ownerAddress: messengerOwner,
                messengerAddress: messengerAddress_,
                specificationUrl: specificationUrl_,
                precision: precision,
                requestsCounter: requestsCounter,
                fulfillsCounter: fulfillsCounter,
                id: id
            })
        );

        emit MessengerRegistered(
            messengerOwner,
            messengerAddress_,
            specificationUrl_,
            precision,
            id
        );
    }

    /**
     * @notice function to modify messenger
     * @dev only messenger owner can call this function
     * @param _specificationUrl new specification url to update
     */
    function modifyMessenger(
        string calldata _specificationUrl,
        uint256 _messengerId
    ) external {
        Messenger storage storedMessenger = _messengers[_messengerId];
        require(
            msg.sender == IMessenger(storedMessenger.messengerAddress).owner(),
            'Can only be modified by the owner'
        );
        storedMessenger.specificationUrl = _specificationUrl;
        storedMessenger.ownerAddress = msg.sender;
        emit MessengerModified(
            storedMessenger.ownerAddress,
            storedMessenger.messengerAddress,
            storedMessenger.specificationUrl,
            storedMessenger.precision,
            storedMessenger.id
        );
    }

    /**
     * @notice external view function that returns registered messengers
     * @return array of Messenger struct
     */
    function getMessengers(uint256 skip, uint256 num)
        external
        view
        returns (Messenger[] memory)
    {
        if (skip >= _messengers.length) num = 0;
        if (skip + num > _messengers.length) num = _messengers.length - skip;
        Messenger[] memory returnMessengers = new Messenger[](num);

        for (uint256 index = skip; index < skip + num; index++) {
            IMessenger messenger = IMessenger(
                _messengers[index].messengerAddress
            );
            returnMessengers[index - skip] = Messenger({
                ownerAddress: _messengers[index].ownerAddress,
                messengerAddress: _messengers[index].messengerAddress,
                specificationUrl: _messengers[index].specificationUrl,
                precision: _messengers[index].precision,
                requestsCounter: messenger.requestsCounter(),
                fulfillsCounter: messenger.fulfillsCounter(),
                id: _messengers[index].id
            });
        }
        return returnMessengers;
    }

    /**
     * @notice external view function that returns the number of registered messengers
     * @return number of registered messengers
     */
    function getMessengersLength() external view returns (uint256) {
        return _messengers.length;
    }

    /**
     * @notice external view function that returns the registration state by address
     * @param messengerAddress_ messenger address to check
     * @return bool registered or not
     */
    function registeredMessengers(address messengerAddress_)
        external
        view
        override
        returns (bool)
    {
        return _registeredMessengers[messengerAddress_];
    }
}