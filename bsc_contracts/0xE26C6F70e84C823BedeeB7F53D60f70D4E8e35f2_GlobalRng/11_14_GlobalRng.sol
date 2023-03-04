// SPDX-License-Identifier: Ridotto Core License

/*
.------..------..------..------..------..------.     .------..------..------.
|G.--. ||L.--. ||O.--. ||B.--. ||A.--. ||L.--. |.-.  |R.--. ||N.--. ||G.--. |
| :/\: || :/\: || :/\: || :(): || (\/) || :/\: ((5)) | :(): || :(): || :/\: |
| :\/: || (__) || :\/: || ()() || :\/: || (__) |'-.-.| ()() || ()() || :\/: |
| '--'G|| '--'L|| '--'O|| '--'B|| '--'A|| '--'L| ((1)) '--'R|| '--'N|| '--'G|
`------'`------'`------'`------'`------'`------'  '-'`------'`------'`------'
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IGlobalRng.sol";
import "./lib/bytes.sol";

contract GlobalRng is IGlobalRng, Initializable, PausableUpgradeable, AccessControlUpgradeable {
    // Global RNG role
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");

    uint256 public providerCounter;
    uint256 public totalCallCount;

    mapping(uint256 => provider) public providers;
    mapping(address => uint256) public providerId;
    mapping(uint256 => uint256) public reqIds;

    // Chainlink Provider
    uint256 public chainlinkPId;
    bytes32 _CHAINLINK_PROVIDER;

    // Randomizer Provider
    uint256 public randomizerId;
    bytes32 _RANDOMIZER_PROVIDER;

    mapping(uint256 => mapping(uint256 => uint256)) public result;

    function init() external initializer {
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        providerCounter = 0;
        _CHAINLINK_PROVIDER = keccak256("chainlink");
        _RANDOMIZER_PROVIDER = keccak256("randomizer");
        emit Initialised();
    }

    /*
     * @notice Request a random words. Only support a single word
     * @param _pId: The provider id to use
     * @param _functionData : the provider id to use
     * @return requestId: The request id given by the provider
     */
    function requestRandomWords(
        uint256 _pId,
        bytes memory _functionData
    ) external onlyRole(CONSUMER_ROLE) whenNotPaused returns (uint256) {
        require(_pId <= providerCounter, "GlobalRng: Unsupported provider");
        require(providers[_pId].isActive, "GlobalRng: Inactive provider");
        totalCallCount++;
        provider memory selectedProvider = providers[_pId];
        (bool success, bytes memory res) = selectedProvider.providerAddress.call(_functionData);
        require(success, "call not forwarded");
        // Chainlink and Randomizer Check
        if (
            keccak256(bytes(selectedProvider.name)) == _CHAINLINK_PROVIDER ||
            keccak256(bytes(selectedProvider.name)) == _RANDOMIZER_PROVIDER
        ) {
            reqIds[totalCallCount] = uint256(bytes32(res));
        } else {
            // Assume provider will return ID/Seed to identitfy the request
            // The information will be stored in reqIds
            reqIds[totalCallCount] = uint256(
                bytes32(BytesLib.slice(res, selectedProvider.paramData[0], selectedProvider.paramData[1]))
            );
        }

        emit newRngRequest(_pId, totalCallCount, msg.sender);
        return totalCallCount;
    }

    /*
     * @notice Retrigger a request for a random words. Only support a single word
     * @param _pId: The provider id to use (should be the same as the original request)
     * @param _callCount: The call count to retrigger
     * @param _functionData : the provider id to use
     * @return requestId: The request id given by the provider
     */
    function retriggerRequestRandomWords(
        uint256 _pId,
        uint256 _callCount,
        bytes memory _functionData
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused returns (uint256) {
        require(_pId <= providerCounter, "GlobalRng: Unsupported provider");
        require(providers[_pId].isActive, "GlobalRng: Inactive provider");
        require(_callCount <= totalCallCount, "GlobalRng: Use callCount < totalCallCount");
        provider memory selectedProvider = providers[_pId];
        (bool success, bytes memory res) = selectedProvider.providerAddress.call(_functionData);
        require(success, "call not forwarded");
        // Chainlink and Randomizer Check
        if (
            keccak256(bytes(selectedProvider.name)) == _CHAINLINK_PROVIDER ||
            keccak256(bytes(selectedProvider.name)) == _RANDOMIZER_PROVIDER
        ) {
            reqIds[_callCount] = uint256(bytes32(res));
        } else {
            // Assume provider will return ID/Seed to identitfy the request
            // The information will be stored in reqIds
            reqIds[_callCount] = uint256(
                bytes32(BytesLib.slice(res, selectedProvider.paramData[0], selectedProvider.paramData[1]))
            );
        }

        emit newRngRequest(_pId, _callCount, msg.sender);
        return _callCount;
    }

    /*
     * @notice Callback function for the provider to return the random words
     */
    fallback() external {
        provider memory selectedProvider = providers[providerId[msg.sender]];
        require(selectedProvider.isActive, "Caller not active");
        uint256 pId = providerId[selectedProvider.providerAddress];

        bytes memory idData = msg.data[selectedProvider.paramData[2]:selectedProvider.paramData[3]];
        uint length = idData.length;
        uint pad = 32 - length;
        bytes memory padZero = new bytes(pad);

        uint256 id = uint256(bytes32(bytes.concat(padZero, idData)));

        result[pId][id] = uint256(bytes32(msg.data[selectedProvider.paramData[4]:selectedProvider.paramData[5]]));

        emit newRngResult(pId, id, result[pId][id]);
    }

    /*
     * @notice Callback function for chainlink provider
     * @param _requestId: The request id given by Chainlink
     * @param _randomness: The random number given by Chainlink
     */
    function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
        require(msg.sender == providers[chainlinkPId].providerAddress, "GlobalRng: Only VRF coordinator can fullFill");
        result[chainlinkPId][_requestId] = _randomWords[0];
        emit newRngResult(chainlinkPId, _requestId, _randomWords[0]);
    }

    /**

    @notice This function is used as a callback by the external randomizer service
    @param _id: the unique ID of the request made to the randomizer
    @param _value: the random value returned by the external randomizer
    @dev This function can only be called by the address of the designated randomizer service provider.
    It stores the received random value to the result mapping with the randomizer ID and the request ID as keys.
    It also emits a 'newRngResult' event with the randomizer ID, the request ID and the random value as parameters.
    */
    function randomizerCallback(uint256 _id, bytes32 _value) external {
        //Callback can only be called by randomizer
        require(
            msg.sender == providers[randomizerId].providerAddress,
            "GlobalRng: Only Randomizer coordinator can fullFill"
        );
        result[randomizerId][_id] = uint256(_value);
        emit newRngResult(randomizerId, _id, uint256(_value));
    }

    /*
     * @notice view the request result
     * @param _pId: The provider id to use
     * @param _callCount: The request id given by the global rng
     * @return The random word
     */
    function viewRandomResult(uint256 _pId, uint256 _callCount) external view returns (uint256) {
        return result[_pId][reqIds[_callCount]];
    }

    /*
     * @notice Configure a provider
     * @param _pId: The provider id to configure
     * @param _providerInfo: The provider information
     */
    function configureProvider(uint256 _pId, provider memory _providerInfo) public onlyRole(OPERATOR_ROLE) {
        require(_pId <= providerCounter, "GlobalRng: Unsupported provider");
        require(_providerInfo.providerAddress != address(0), "GlobalRng: Cannot use Zero address as provider");
        providers[_pId] = _providerInfo;
        emit setProvider(_pId, _providerInfo.name, _providerInfo.isActive, _providerInfo.providerAddress);
    }

    /*
     * @notice Add a new provider
     * @param _providerInfo: The provider information
     * @return The provider id
     */
    function addProvider(provider memory _providerInfo) public onlyRole(OPERATOR_ROLE) returns (uint256) {
        providerCounter++;
        providers[providerCounter] = provider(
            _providerInfo.name,
            _providerInfo.isActive,
            _providerInfo.providerAddress,
            _providerInfo.gasLimit,
            _providerInfo.paramData
        );
        providerId[_providerInfo.providerAddress] = providerCounter;
        _checkChainlink(providerCounter);
        _checkRandomizer(providerCounter);
        emit createProvider(providerCounter);
        return (providerCounter);
    }

    /*
     * @notice Check if the provider is chainlink. If yes, set the chainlinkPId
     * @param _pId: The provider id to check
     */
    function _checkChainlink(uint256 _providerId) internal {
        if (keccak256(bytes(providers[_providerId].name)) == _CHAINLINK_PROVIDER) {
            for (uint256 i = 0; i < providerCounter; i++) {
                require(
                    keccak256(bytes(providers[i].name)) != _CHAINLINK_PROVIDER,
                    "GlobalRng: Cannot set multiple chainlink provider"
                );
            }
            chainlinkPId = providerCounter;
        }
    }

    function _checkRandomizer(uint256 _providerId) internal {
        if (keccak256(bytes(providers[_providerId].name)) == _RANDOMIZER_PROVIDER) {
            for (uint256 i = 0; i < providerCounter; i++) {
                require(
                    keccak256(bytes(providers[i].name)) != _RANDOMIZER_PROVIDER,
                    "GlobalRng: Cannot set multiple randomizer provider"
                );
            }
            randomizerId = providerCounter;
        }
    }
}