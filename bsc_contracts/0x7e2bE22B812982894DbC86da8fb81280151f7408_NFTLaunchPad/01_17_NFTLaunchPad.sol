// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./NFTCollection.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
contract NFTLaunchPad is Initializable, OwnableUpgradeable {
    address[] _allCollections; //Addresses of collections
    address platformPublicKey; //Address of Public key
    address public brokerAddress; //Address of broker
    mapping(address => address[]) _userCollections;
    mapping(address => int256) brokerage;
    string public globalBaseURI;

    function initialize(address _brokerAddress, address _platformPublicKey)
        public
        initializer
    {
        __Ownable_init();
        brokerAddress = _brokerAddress;
        platformPublicKey = _platformPublicKey;
    }

    //Event
    event CreateLaunchpad(
        address indexed creator,
        address indexed collection,
        uint256 creationtime,
        string name,
        string symbol,
        string contractURI,
        uint256 maxSupply
    );

    event currencySupport(
        address[] currencies,
        address[] whiteListCurrencies,
        uint256[] currenciesPrice,
        uint256[] whiteListCurrenciesPrice
    );

    /**
     *@dev Method to set brokerage.
     *@notice allow only autorized user to call this function.
     *@param _brokerage new brokerage.
     *@param currency address of currency.
     */
    function setBrokerage(int256 _brokerage, address currency)
        external
        onlyOwner
    {
        brokerage[currency] = _brokerage;
    }

    function getBrokerage(address currency) public view returns (int256) {
        return brokerage[currency];
    }

    /**
     *@dev Method to set broker address.
     *@notice allow only autorized user to call this function.
     *@param newBrokerAddress address of new broker.
     */
    function setBroker(address newBrokerAddress) external onlyOwner {
        require(
            newBrokerAddress != address(0) && newBrokerAddress != brokerAddress,
            "NFTLaunchPad: New address should not be address 0x0 nor existing address"
        );
        brokerAddress = newBrokerAddress;
    }

    /**
     *@dev Method to set PlatformPublicKey
     *@notice allow only authorized user to call this function
     *@param _newPlatformPublicKey to be set
     */
    function updatePublicKey(address _newPlatformPublicKey) external onlyOwner {
        platformPublicKey = _newPlatformPublicKey;
    }

    /**
     *@dev Method to get PublicKey
     *@return Returns platformPublicKey
     */

    function getPublicKey() external view returns (address) {
        return platformPublicKey;
    }

    /**
     *@dev Method to create new NFTLaunchPad.
     *@param _uints struct of integer values used to create launchPad
     *@param _strings struct of string used to create launchPad
     *@param _enableWhiteList bool value to enable or disable whiteList
     *@param _currencies address of the currencies
     *@param _whiteListCurrencies address of the whiteList Currencies
     *@param _currenciesPrice prices of the currencies
     *@param _whiteListCurrenciesPrice  prices of the whiteListed Currencies
     *@return _launchpad the address of new create launchPad
     */

    function createLaunchPad(
        NFTCollection.UintArgs calldata _uints,
        NFTCollection.StringArgs memory _strings,
        bool _enableWhiteList,
        address[] calldata _currencies,
        address[] calldata _whiteListCurrencies,
        uint256[] calldata _currenciesPrice,
        uint256[] memory _whiteListCurrenciesPrice
    ) external returns (address _launchpad) {
        require(
            (_uints.royalty >= 0 && _uints.royalty <= 10000),
            "NFTLaunchPad: Royalty should be less than 10000"
        );

        require(
            _uints.maxNFTPerUser >= _uints.maxQuantity &&
                _uints.maxQuantity > 0,
            "NFTLaunchPad: Invalid quantities."
        );

        for (uint256 i = 0; i < _currencies.length; i++) {
            require(
                getBrokerage(_currencies[i]) != 0,
                "NFTLaunchpad: Currency not Supported"
            );
        }
        if (_enableWhiteList) {
            require(
                _uints.WhiteListStartTime > block.timestamp,
                "NFTLaunchPad: WhiteListStartTime should be greater than current time"
            );
            require(
                _uints.WhiteListEndTime > _uints.WhiteListStartTime,
                "NFTLaunchPad: WhiteListEndTime should be greater than whiteListStartTime"
            );

            for (uint256 i = 0; i < _whiteListCurrencies.length; i++) {
                require(
                    getBrokerage(_whiteListCurrencies[i]) != 0,
                    "NFTLaunchpad: WhiteListCurrency not Supported"
                );
            }
        }

        NFTCollection launchpadCollection = new NFTCollection(
            _uints,
            msg.sender,
            _strings,
            _currencies,
            _whiteListCurrencies,
            _currenciesPrice,
            _whiteListCurrenciesPrice
        );
        _allCollections.push(address(launchpadCollection));
        _userCollections[msg.sender].push(address(launchpadCollection));

        emit CreateLaunchpad(
            msg.sender,
            address(launchpadCollection),
            block.timestamp,
            _strings.name,
            _strings.symbol,
            _strings.contractURI,
            _uints.maxSupply
        );
        emit currencySupport(
            _currencies,
            _whiteListCurrencies,
            _currenciesPrice,
            _whiteListCurrenciesPrice
        );

        _launchpad = address(launchpadCollection);
        return _launchpad;
    }

    /**
     * @dev Method to get all created LaunchPad.
     * @return return array of created collections.
     */

    function getCollections() external view returns (address[] memory) {
        return _allCollections;
    }

    /**
     * @dev Method to get created LaunchPad of specific user.
     * @param user: address of user to get their collections
     * @return return array of created collections of user.
     */

    function getUserCollection(address user)
        external
        view
        returns (address[] memory)
    {
        return _userCollections[user];
    }

    /**
     * @dev Method  to get Global base uri
     * @param baseURI_: base uri of user
     */
    function setGlobalBaseURI(string calldata baseURI_) external onlyOwner{  
        globalBaseURI = baseURI_;
    }
}