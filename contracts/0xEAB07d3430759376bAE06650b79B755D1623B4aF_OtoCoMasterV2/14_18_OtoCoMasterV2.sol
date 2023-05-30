// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./utils/IOtoCoJurisdiction.sol";
import "./utils/IOtoCoURI.sol";
import "./utils/IOtoCoPlugin.sol";


contract OtoCoMasterV2 is OwnableUpgradeable, ERC721Upgradeable {

    // Custom Errors
    error NotAllowed();
    error InitializerError();
    error IncorrectOwner();
    error InsufficientValue(uint256 available, uint256 required);

    // Events
    event FeesWithdrawn(address owner, uint256 amount);
    event UpdatedPriceFeed(address newPriceFeed);
    event BaseFeeChanged(uint256 newFee);
    event ChangedURISource(address newSource);
    event DocsUpdated(uint256 indexed tokenId);

    // Series Structs
    struct Series {
        uint16 jurisdiction;
        uint16 entityType;
        uint64 creation;
        uint64 expiration;
        string name;
    }

    // OLD STORAGE VARIABLES

    // Total count of series
    uint256 public seriesCount;
    // Last migrated series at start
    uint256 internal lastMigrated;
    // Mapping from Series Ids to Series data
    mapping(uint256=>Series) public series;

    // Total count of unique jurisdictions
    uint16 public jurisdictionCount;
    // How much series exist in each jurisdiction
    mapping(uint16=>address) public jurisdictionAddress;
    // How much series exist in each jurisdiction
    mapping(uint16=>uint256) public seriesPerJurisdiction;

    // Base External URL to access entities page
    string public externalUrl;

    // The percentage in total gas fees that should be charged in ETH
    uint256 public baseFee;

    // NEW STORAGE VARIABLES 

    // Constant ETH to divide by price
    uint256 constant priceFeedEth = 1 ether * (10**8);
    // Chainlink price feed reference
    AggregatorV3Interface internal priceFeed;
    // Default URI builder for OtoCo Entities
    IOtoCoURI public entitiesURI;
    // Valid marketplace addresses that are allowed to create standalone entities
    mapping(address=>bool) internal marketplaceAddress;
    mapping(address=>bool) internal allowedPlugins;
    mapping(uint256=>string) public docs;
    /**
     * Check if there's enough ETH paid for public transactions.
     */
    modifier onlyMarketplace() {
        if (!marketplaceAddress[msg.sender]) revert NotAllowed();
        _;
    }

     /**
     * Check if there's enough ETH paid for public transactions.
     */
    modifier enoughAmountFees() {
        if (msg.value < gasleft() * baseFee) revert InsufficientValue({
            available: msg.value,
            required: gasleft() * baseFee
        });
        _;
    }

     /**
     * Check if there's enough ETH paid for USD priced transactions.
     */
    modifier enoughAmountUSD(uint256 usdPrice) {
        uint256 requiredValue= priceConverter(usdPrice);
        if (msg.value < requiredValue) revert InsufficientValue({
            available: msg.value,
            required: requiredValue
        });
        _;
    }

    function priceConverter(uint256 usdPrice) public view returns (uint256) {
        (,int256 quote,,,) = priceFeed.latestRoundData();
        return (priceFeedEth/uint256(quote))*usdPrice;
    }

    /**
     * Upgradeable contract initializer.
     *
     * @param jurisdictionAddresses Initial juridiction pre-deployed addresses.
     * @param url Initial external URL.
     */
    function initialize(address[] calldata jurisdictionAddresses, string calldata url) initializer external {
        __Ownable_init();
        __ERC721_init("OtoCo Series", "OTOCO");
        uint16 counter = uint16(jurisdictionAddresses.length);
        for (uint16 i = 0; i < counter; i++){
            jurisdictionAddress[i] = jurisdictionAddresses[i];
        }
        jurisdictionCount = counter;
        baseFee = 10;
        externalUrl = url;
    }

    /**
     * Create a new Series at specific jurisdiction and also select its name.
     *
     * @param jurisdiction Jurisdiction that will store entity.
     * @param controller who will control the entity.
     * @param name the legal name of the entity.
     */
    function createSeries(uint16 jurisdiction, address controller, string memory name) 
    public enoughAmountUSD(
        IOtoCoJurisdiction(jurisdictionAddress[jurisdiction]).getJurisdictionDeployPrice()
    ) payable {
        if (IOtoCoJurisdiction(jurisdictionAddress[jurisdiction]).isStandalone() == true) {
            revert NotAllowed();
        }

        // Get next index to create tokenIDs
        uint256 current = seriesCount;
        // Initialize Series data
        series[current] = Series(
            jurisdiction,
            0,
            uint64(block.timestamp),
            0,
            IOtoCoJurisdiction(jurisdictionAddress[jurisdiction]).getSeriesNameFormatted(seriesPerJurisdiction[jurisdiction], name)
        );
        // Mint NFT
        _mint(controller, current);
        // Increase counters
        seriesCount++;
        seriesPerJurisdiction[jurisdiction]++;
    }

    /**
     * Create a new Series with initializer contract and custom plugins.
     * The initializer deployed will own the entity after deployment.
     *
     * @param jurisdiction Jurisdiction that will store entity.
     * @param plugins The array of plugin addresses to be called. The index 0 is the initializer.
     * @param pluginsData The array of pluginData to be used as parameters. Index 0 is initializer params.
     * @param value The array of values to be send for each plugins. Index 0 is initializer value.
     * @param name the legal name of the entity.
     */
    function createEntityWithInitializer(
        uint16 jurisdiction,
        address[] calldata plugins,
        bytes[] calldata pluginsData,
        uint256 value,
        string calldata name
    ) public payable {
        if (IOtoCoJurisdiction(jurisdictionAddress[jurisdiction]).isStandalone() == true) {
            revert NotAllowed();
        }
        uint256 valueRequired = gasleft()*baseFee
            + priceConverter(IOtoCoJurisdiction(jurisdictionAddress[jurisdiction]).getJurisdictionDeployPrice())
            + value;
        if (msg.value < valueRequired) revert InsufficientValue({
            available: msg.value,
            required: valueRequired
        });
        address controller = msg.sender;
        if (plugins[0] != address(0x0)) {
            (bool success, bytes memory initializerBytes) = plugins[0].call{value: value}(pluginsData[0]);
            if (!success || plugins[0].code.length == 0) revert InitializerError();
            assembly {
                controller := mload(add(initializerBytes,32))
            }
        }
        // Get next index to create tokenIDs
        uint256 current = seriesCount;
        createSeries(jurisdiction, controller, name);
        for (uint8 i=1; i<plugins.length; i++){
            IOtoCoPlugin(plugins[i]).addPlugin(current, pluginsData[i]);
        }
    }

    /**
     * Extend entity expiration date.
     *
     * @param tokenId Token id related to the entity to be renewed
     * @param periodInYears Period in Years to be extended
     */
    function renewEntity(uint256 tokenId, uint256 periodInYears) payable external {
        Series storage s = series[tokenId];
        uint256 renewalPrice = 
            priceConverter(IOtoCoJurisdiction(jurisdictionAddress[s.jurisdiction]).getJurisdictionRenewalPrice());

        if(msg.value < (renewalPrice * periodInYears)) revert InsufficientValue({
            available: msg.value,
            required: (renewalPrice * periodInYears)
        });
        // 31536000 = 1 Year of renewal in seconds
        if (s.expiration < 1) { s.expiration = uint64(block.timestamp); }
        s.expiration += uint64(31536000*periodInYears);
    }

    /**
     * Close series previously created.
     *
     * @param tokenId of the series to be burned.
     */
    function closeSeries(uint256 tokenId) public enoughAmountUSD(
        IOtoCoJurisdiction(jurisdictionAddress[series[tokenId].jurisdiction]).getJurisdictionClosePrice()
    ) payable {
        if(ownerOf(tokenId) != msg.sender) revert IncorrectOwner();
        _burn(tokenId);
    }

    function setDocs(uint256 tokenId, string memory documentation) external {
        if(ownerOf(tokenId) != msg.sender) revert IncorrectOwner();
        docs[tokenId] = documentation;

        emit DocsUpdated(tokenId);
    }

    receive() enoughAmountFees() external payable {}

    // --- ADMINISTRATION FUNCTIONS ---

    /**
     * Add a new jurisdiction to the contract
     *
     * @param newAddress the address of the jurisdiction.
     */
    function addJurisdiction(address newAddress) external onlyOwner {
        jurisdictionAddress[jurisdictionCount] = newAddress;
        jurisdictionCount++;
    } 

    /**
     * Update a jurisdiction to the contract
     *
     * @param jurisdiction the index of the jurisdiction.
     * @param newAddress the new address of the jurisdiction.
     */
    function updateJurisdiction(uint16 jurisdiction, address newAddress) external onlyOwner {
        jurisdictionAddress[jurisdiction] = newAddress;
    }

    /**
     * Change creation fees charged for entity creation, plugin addition/modification/removal.
     *
     * @param newFee new price to be charged for base fees.
     */
    function changeBaseFees(uint256 newFee) external onlyOwner {
        baseFee = newFee;
        emit BaseFeeChanged(newFee);
    }

    /**
     * Replace marketplace Address to the contract
     *
     * @param addresses the address of the jurisdiction.
     * @param enabled the address of the jurisdiction.
     */
    function setMarketplaceAddresses(address[] calldata addresses, bool[] calldata enabled) external onlyOwner {
        uint256 i;
        uint256 addressesSize = addresses.length;  
        for (i; i < addressesSize;){
            marketplaceAddress[addresses[i]] = enabled[i];
            unchecked { ++i; }
        }
    }

    /**
     * Replace URI builder contract
     *
     * @param newEntitiesURI New URI builder contract
     */
    function changeURISources(address newEntitiesURI) external onlyOwner {
        entitiesURI = IOtoCoURI(newEntitiesURI);
        emit ChangedURISource(newEntitiesURI);
    }

    /**
     * Replace Price Feed source
     *
     * @param newPriceFeed New price feed address
     */
    function changePriceFeed(address newPriceFeed) external onlyOwner {
        priceFeed = AggregatorV3Interface(newPriceFeed);
        emit UpdatedPriceFeed(newPriceFeed);
    }

    /**
     * Create a new entity to a specific jurisdiction. 
     *
     * @param jurisdiction The jurisdiction for the created entity.
     * @param expiration expiration of the entity, date limit to renew.
     * @param name name of the entity.
     */
    function addEntity(
        uint16 jurisdiction,
        uint64 expiration,
        string calldata name
    ) external onlyMarketplace {
        // Get next index to create tokenIDs
        uint256 current = seriesCount;
        // Initialize Series data
        series[current] = Series(
            jurisdiction,
            1,                          // Standalone entity type
            uint64(block.timestamp),
            expiration,
            name
        );
        // Mint NFT
        _mint(msg.sender, current);
        // Increase counters
        seriesCount++;
        seriesPerJurisdiction[jurisdiction]++;
    }

    /**
     * Withdraw fees paid by series creation.
     * Fees are transfered to the caller of the function that should be the contract owner.
     *
     * Emits a {FeesWithdraw} event.
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit FeesWithdrawn(msg.sender, balance);
    }

    // -- TOKEN VISUALS AND DESCRIPTIVE ELEMENTS --

    /**
     * Get the tokenURI that points to a image.
     * Returns the JSON formatted accordingly with Base64.
     *
     * @param tokenId must exist.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return entitiesURI.tokenExternalURI(tokenId, lastMigrated);
    }
}