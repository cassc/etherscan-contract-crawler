// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./RoyaltyStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RoyaltyRegistry is RoyaltyStorage {
    /// @dev emitted when royalties set for token.
    event RoyaltySetForCollection(address indexed _token, uint96 _royaltyRate);

    event ReceiverUpdated(address oldReceiver, address newReceiver);

    event ModelFactoryUpdated(address oldFactory, address newFactory);

    event DefaultRoyaltyRatePercentageUpdated(uint96 oldRate, uint96 newRate);

    event CollectionManagerUpdated(address indexed _oldAddress, address _newAddress);

    event CollectionAuthorizedSignerAddressUpdated(address indexed _oldAddress, address _newAddress);

    event CollectionOwnerUpdated(address indexed _oldAddress, address _newAddress);

    event BaseContractURIUpdated(string oldBaseContractURI, string newBaseContractURI);

    modifier onlyOwnerOrFactory() {
        require(msg.sender == owner() || msg.sender == modelFactory, "Unauthorized");
        _;
    }

    /**
     * @notice Initialization for upgradeable contract.
     *
     * @param _receiver receiver address.
     * @param _defaultRateRoyaltyPercentage default royalty percentage.
     *
     */
    function initialize(
        address _receiver,
        uint96 _defaultRateRoyaltyPercentage,
        address _collectionOwner,
        address _collectionManager,
        address _collectionAuthorizedSignerAddress
    ) external initializer {
        require(_receiver != address(0), "Invalid receiver address");
        require(_collectionOwner != address(0), "Invalid owner address");
        require(_collectionManager != address(0), "Invalid manager address");
        require(_collectionAuthorizedSignerAddress != address(0), "Invalid signer address");


        receiver = _receiver;
        defaultRoyaltyRatePercentage = _defaultRateRoyaltyPercentage;
        collectionOwner = _collectionOwner;
        collectionManager = _collectionManager;
        collectionAuthorizedSignerAddress = _collectionAuthorizedSignerAddress;

        __Ownable_init_unchained();
    }

    /**
     * @dev setter for receiver address.
     *
     * @param _newReceiver new Receiver address
     *
     */
    function changeReceiver(address _newReceiver) external onlyOwner {
        require(_newReceiver != address(0), "Invalid address");
        address oldReceiver = receiver;
        receiver = _newReceiver;

        emit ReceiverUpdated(oldReceiver, receiver);
    }

    /**
     * @dev setter for model factory address.
     *
     * @param _newModelFactory new Receiver address
     *
     */
    function changeModelFactory(address _newModelFactory) external onlyOwner {
        require(_newModelFactory != address(0), "Invalid address");
        address oldModelFactory = modelFactory;
        modelFactory = _newModelFactory;

        emit ModelFactoryUpdated(oldModelFactory, modelFactory);
    }

    /**
     * @dev setter for defaultRoyaltyRatePercentage
     * @notice the deafult royalty rate can be 0.
     *
     * @param _newDefaultRate new default rate for royalty.
     *
     */
    function changeDefaultRoyaltyRatePercentage(uint96 _newDefaultRate) external onlyOwner {
        require(_newDefaultRate <= MAX_RATE_ROYALTY, "Invalid Rate");
        uint96 oldDefaultRoyaltyRatePercentage = defaultRoyaltyRatePercentage;
        defaultRoyaltyRatePercentage = _newDefaultRate;

        emit DefaultRoyaltyRatePercentageUpdated(oldDefaultRoyaltyRatePercentage, defaultRoyaltyRatePercentage);
    }

    /**
     * @dev set royalty rate for specific collection. Support multiple set. The length of array between tokens & rates must exactly the same.
     * @notice the rate will be applied to all of token ids inside the collection.
     * @notice only owner can call the multiple set.
     *
     * @param _tokens array of token address.
     * @param _royaltyRates array of royalty rates.
     */
    function setRoyaltyRateForCollections(
        address[] calldata _tokens,
        uint96[] calldata _royaltyRates,
        address[] calldata _royaltyReceivers
    ) external onlyOwner {
        require(_tokens.length == _royaltyRates.length, "Mismatch royaltyRates length");
        require(_tokens.length == _royaltyReceivers.length, "Mismatch royaltyReceivers length");

        for (uint256 i = 0; i < _tokens.length; i++) {
            _setRoyaltyForCollection(_tokens[i], _royaltyRates[i], _royaltyReceivers[i]);
        }
    }

    /**
     * @dev set royalty rate for specific collection. Support multiple set. The length of array between tokens & rates must exactly the same.
     * @notice the rate will be applied to all of token ids inside the collection.
     * @notice Owner or factory can perform this function call.
     *
     * @param _token token address.
     * @param _royaltyRate royalty rate.
     */
    function setRoyaltyRateForCollection(
        address _token,
        uint96 _royaltyRate,
        address _royaltyReceiver
    ) external onlyOwnerOrFactory {
        _setRoyaltyForCollection(_token, _royaltyRate, _royaltyReceiver);
    }

    /**
     * @dev internal setter royalty rate for collection.
     *
     * @param _token token / collection address.
     * @param _royaltyRate royalty rate for that particular collection.
     */
    function _setRoyaltyForCollection(
        address _token,
        uint96 _royaltyRate,
        address _royaltyReceiver
    ) private {
        require(_token != address(0), "Invalid token");
        require(_royaltyReceiver != address(0), "Invalid receiver address");
        require(_royaltyRate <= MAX_RATE_ROYALTY, "Invalid Rate");

        RoyaltySet memory _royaltySet = RoyaltySet({
            isSet: true,
            royaltyRateForCollection: _royaltyRate,
            royaltyReceiver: _royaltyReceiver
        });

        royaltiesSet[_token] = _royaltySet;

        emit RoyaltySetForCollection(_token, _royaltyRate);
    }

    /**
     * @dev royalty info for specific token / collection.
     * @dev It will return custom rate for the token, otherwise will return the default one.
     *
     * @param _token address of token / collection.
     *
     * @return _receiver receiver address.
     * @return _royaltyRatePercentage royalty rate percentage.
     */
    function getRoyaltyInfo(address _token) external view returns (address _receiver, uint96 _royaltyRatePercentage) {
        RoyaltySet memory _royaltySet = royaltiesSet[_token];
        return (
            _royaltySet.royaltyReceiver != address(0) ? _royaltySet.royaltyReceiver : receiver,
            _royaltySet.isSet ? _royaltySet.royaltyRateForCollection : defaultRoyaltyRatePercentage
        );
    }


    /**
     * @dev Update the authorized signer address.
     *
     * @param _collectionSignerAddress new authorized signer address.
     */
    function changeCollectionAuthorizedSignerAddress(address _collectionSignerAddress) external onlyOwner {
        require(_collectionSignerAddress != address(0), "Invalid address");
        address oldSignerAddress = collectionAuthorizedSignerAddress;
        collectionAuthorizedSignerAddress = _collectionSignerAddress;
        emit CollectionAuthorizedSignerAddressUpdated(oldSignerAddress, collectionAuthorizedSignerAddress);
    }

    /**
     * @notice Setter for manager address.
     * @dev Can be called only by the current manager.
     *
     * @param _collectionManager new manager address.
     */
    function changeCollectionManager(address _collectionManager) external onlyOwner {
        require(_collectionManager != address(0), "Invalid address");
        address oldManagerAddress = collectionManager;
        collectionManager = _collectionManager;

        emit CollectionManagerUpdated(oldManagerAddress, collectionManager);
    }

    /**
     * @dev Update the authorized signer address.
     *
     * @param _collectionOwner new authorized signer address.
     */
    function changeCollectionOwner(address _collectionOwner) external onlyOwner {
        require(_collectionOwner != address(0), "Invalid address");
        address oldOwner = collectionOwner;
        collectionOwner = _collectionOwner;
        emit CollectionOwnerUpdated(oldOwner, collectionOwner);
    }

    /**
     * @dev Update baseContractURI.
     *
     * @param _baseContractURI new base contract URI.
     */
    function changeContractURI(string memory _baseContractURI) external onlyOwner {
        string memory oldBaseContractURI = baseContractURI;
        baseContractURI = _baseContractURI;
        emit BaseContractURIUpdated(oldBaseContractURI, baseContractURI);
    }

    /**
     * @dev full contract URI based on collection contract.
     *
     * @return string of full contract uri.
     */
    function getContractURIForToken() external view returns(string memory) {
        return string(abi.encodePacked(baseContractURI, Strings.toHexString(msg.sender) ));
    }
}