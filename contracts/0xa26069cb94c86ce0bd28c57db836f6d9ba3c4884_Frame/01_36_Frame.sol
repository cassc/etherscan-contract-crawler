//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstract/Rentable.sol";
import "./abstract/Exhibitionable.sol";
import "./interface/IVersionedContract.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./lib/ABDKMath64x64.sol";
import "./lib/AllowList.sol";

/**
 * @title Musee Dezentral Frame NFT contract
 *
 * @dev   ERC-721 compatible token with multiple price categories
 * @dev   Allows token holders to rent and exhibit other NFTs inside the Frame
 * @dev   Uses Chainlink VRF function to select minting within a price category
 * @dev   Implements a basic pre-sale list using AccessControl roles configured during deploy
 * @dev   Implements ABDK math library for percentage-based fees arithmetic
 *
 * @author Aaron Boyd <https://github.com/aaronmboyd>
 */
contract Frame is
    IVersionedContract,
    ReentrancyGuard,
    Rentable,
    Exhibitionable,
    ERC721PresetMinterPauserAutoId,
    VRFConsumerBase
{
    using EnumerableSet for EnumerableSet.UintSet;

    enum SaleStatus {
        OFF,
        PRESALE,
        MAINSALE
    }

    enum Category {
        A,
        B,
        C,
        D,
        E,
        F,
        G,
        H,
        I,
        J,
        K
    }
    struct CategoryDetail {
        uint256 price;
        uint256 startingTokenId;
        uint256 supply;
        EnumerableSet.UintSet tokenIds;
    }

    /**
     * @dev Mappings
     */
    mapping(Category => CategoryDetail) internal categories;
    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => Category) public requestIdToCategory;
    mapping(bytes32 => uint256) public requestIdToTokenId;

    /**
     * @dev Chainlink variables
     * @dev Fee: defaulted to 0.1 LINK on Rinkeby (varies by network), set during constructor
     * @dev KeyHash: must be set during constructor (varies by network)
     */
    bytes32 internal keyHash;
    uint256 internal fee = 0.1 * 10**18;

    /**
     * @dev Frame variables
     * @dev Fee: defaulted to 0.1 LINK on Rinkeby (varies by network), set during constructor
     * @dev KeyHash: must be set during constructor (varies by network)
     */
    bytes32 public constant PRESALE_ROLE = keccak256("PRESALE_ROLE");
    SaleStatus internal saleStatus = SaleStatus.OFF;
    int256 public rentalFeeNumerator = 50;
    int256 public rentalFeeDenominator = 1000;

    /**
     * @dev ERC721 variables
     */
    string public contractURI;

    /**
     * @notice Triggered when a minting is requested
     * @param _requestId      Request ID of the request
     * @param _address        Recipient address
     */
    event MintRequest(bytes32 indexed _requestId, address indexed _address);

    /**
     * @notice Triggered when a minting is fulfilled
     * @param _requestId      Request ID of the fulfillment
     * @param _address        Recipient address
     * @param _tokenId        TokenID received
     */
    event MintFulfilled(
        bytes32 indexed _requestId,
        address indexed _address,
        uint256 indexed _tokenId
    );

    /**
     * @notice Triggered when LINK is withdrawn
     * @param _to             Recipient of the LINK
     * @param _value          Withdrawal amount in wei
     */
    event LinkWithdrawn(address indexed _to, uint256 _value);

    /**
     * @notice Triggered when ether is withdrawn
     * @param _to             Recipient of the ether
     * @param _value          Withdrawal amount in wei
     */
    event EtherWithdrawn(address indexed _to, uint256 _value);

    /**
     * @notice Triggered when rental fee accumulated in the contract
     * @param _tokenId        Token id that was rented
     * @param _from           Frame owner
     * @param _value          Rental fee collected
     */
    event RentalFeeCollectedFrom(uint256 indexed _tokenId, address indexed _from, uint256 _value);

    /**
     * @notice Triggered when the Rental Fee is updated
     * @param _oldNumerator   Old numerator
     * @param _oldDenominator Old denominator
     * @param _newNumerator   New numerator
     * @param _newDenominator New denominator
     */
    event RentalFeeUpdated(
        int256 _oldNumerator,
        int256 _oldDenominator,
        int256 _newNumerator,
        int256 _newDenominator
    );

    /**
     * @notice Returns the storage, major, minor, and patch version of the contract.
     * @return The storage, major, minor, and patch version of the contract.
     */
    function getVersionNumber()
        external
        pure
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (1, 0, 2, 1);
    }

    /**
     *  @notice Enforces any sale is on
     */
    modifier mintingAvailable() {
        require(saleStatus != SaleStatus.OFF, "Frame: Minting not available");
        _;
    }

    /**
     *  @notice Enforces a valid category
     */
    modifier validCategory(Category category) {
        require(category <= Category.K, "Frame: Invalid Category");
        require(category >= Category.A, "Frame: Invalid Category");
        _;
    }

    /**
     *  @notice Enforces a tokenId exists
     */
    modifier tokenExists(uint256 _tokenId) {
        require(_exists(_tokenId), "ERC721: operator query for nonexistent token");
        _;
    }

    /**
     * @notice Enforces an address should have the DEFAULT_ADMIN_ROLE (0x00) for the entire contract
     */
    modifier onlyOwner(address _address) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _address), "Frame: Only owner");
        _;
    }

    /**
     * @notice Enforces a tokenId should be owned by an address
     */
    modifier tokenIsOwned(uint256 _tokenId, address _address) {
        require(_tokenIsOwned(_tokenId, _address), "Frame: Not the Owner");
        _;
    }

    /**
     * @notice Enforces an Exhibit is owned by the user
     */
    modifier ownsExhibit(
        address _exhibitor,
        address _exhibitContractAddress,
        uint256 _exhibitTokenId
    ) {
        require(
            Exhibitionable(this).exhibitIsOwnedBy(
                _exhibitor,
                _exhibitContractAddress,
                _exhibitTokenId
            ),
            "Frame: Exhibit not valid"
        );
        _;
    }

    /**
     * @notice Enforces a token is not currently rented
     */
    modifier tokenNotRented(uint256 _tokenId) {
        require(!_isCurrentlyRented(_tokenId), "Frame: Token already rented");
        _;
    }

    /**
     * @notice Enforces a token has a rentalPricePerBlock configured
     */
    modifier rentalPriceSet(uint256 _tokenId) {
        require(Rentable(this).getRentalPricePerBlock(_tokenId) > 0, "Frame: Rental price not set");
        _;
    }

    /**
     * @notice Constructor
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the account that deploys the contract
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenUri,
        string memory _contractUri,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        int256 _rentalFeeNumerator,
        int256 _rentalFeeDenominator
    )
        ERC721PresetMinterPauserAutoId(_name, _symbol, _baseTokenUri)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        // Used to generate a metadata location for the entire contract
        // commonly used on secondary marketplaces like OpenSea to display collection information
        contractURI = _contractUri;

        // Used to requestRandomness from VRFConsumerBase
        fee = _fee;
        keyHash = _keyHash;

        // Rental fee starting at 5%, adjustable
        rentalFeeNumerator = _rentalFeeNumerator;
        rentalFeeDenominator = _rentalFeeDenominator;

        // Initialise allow list
        // Gas intensive on deploy but easier than sending 127 transactions
        address[128] memory allowList = AllowList.getAllowList();
        uint256 i;
        for (i = 0; i < allowList.length; i++) {
            grantRole(PRESALE_ROLE, allowList[i]);
        }
    }

    /**
     * @dev Frame functions
     */

    /**
     * @notice Internal: simple ether transfer
     */
    function _transfer(address payable _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Frame: Failed to send ETH");
    }

    /**
     * @notice Internal: checks if a token is currently owned by address
     * @param _tokenId The token to check is owned
     * @param _address The address to check if it's owned by
     */
    function _tokenIsOwned(uint256 _tokenId, address _address) internal view returns (bool) {
        return _address == ownerOf(_tokenId);
    }

    /**
     * @notice Returns information about a Category
     * @param _category The Category to retrieve
     * @return uint256 The price of the Category in wei
     * @return uint256 The startingTokenId of the Category
     * @return uint256 The total supply of the Category
     * @return uint256 The remaining supply of the Category
     */
    function getCategoryDetail(Category _category)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        CategoryDetail storage category = categories[_category];
        uint256 supplyRemaining = category.supply - category.tokenIds.length();
        return (category.price, category.startingTokenId, category.supply, supplyRemaining);
    }

    /**
     * @dev Rentable implementation overrides
     */

    /**
     * @inheritdoc Rentable
     */
    function setRenter(
        uint256 _tokenId,
        address _renter,
        uint256 _numberOfBlocks
    )
        external
        payable
        override
        tokenExists(_tokenId)
        tokenNotRented(_tokenId)
        rentalPriceSet(_tokenId)
        nonReentrant
    {
        // Calculate rent
        uint256 rentalCostPerBlock = _getRentalPricePerBlock(_tokenId);
        uint256 rentalCost = _numberOfBlocks * rentalCostPerBlock;
        require(msg.value == rentalCost, "Frame: Incorrect payment");

        // Calculate rental fee
        int128 rentalFeeRatio = ABDKMath64x64.divi(rentalFeeNumerator, rentalFeeDenominator);
        uint256 rentalFeeAmount = ABDKMath64x64.mulu(rentalFeeRatio, rentalCost);
        address owner = ownerOf(_tokenId);
        emit RentalFeeCollectedFrom(_tokenId, owner, rentalFeeAmount);

        // Calculate net amount to owner
        rentalCost = rentalCost - rentalFeeAmount;

        // Send to owner (remainder remains in contract as fee)
        address payable tokenOwner = payable(owner);
        _transfer(tokenOwner, rentalCost);

        // Rent
        _setRenter(_tokenId, _renter, _numberOfBlocks);
    }

    /**
     * @inheritdoc Rentable
     */
    function setRentalPricePerBlock(uint256 _tokenId, uint256 _rentalPrice)
        external
        override
        tokenExists(_tokenId)
        tokenIsOwned(_tokenId, _msgSender())
    {
        _setRentalPricePerBlock(_tokenId, _rentalPrice);
    }

    /**
     * @dev Internal: verify you are the owner or renter of a token
     */
    function _verifyOwnership(address _ownerOrRenter, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        if (Rentable(this).isCurrentlyRented(_tokenId)) {
            bool rented = _tokenIsRentedByAddress(_tokenId, _ownerOrRenter);
            require(rented, "Frame: Not the Renter");
            return rented;
        } else {
            bool owned = _tokenIsOwned(_tokenId, _ownerOrRenter);
            require(owned, "Frame: Not the Owner");
            return owned;
        }
    }

    /**
     * @dev Exhibitionable implementation overrides
     */

    /**
     * @inheritdoc Exhibitionable
     */
    function setExhibit(
        uint256 _tokenId,
        address _exhibitContractAddress,
        uint256 _exhibitTokenId
    )
        external
        override
        tokenExists(_tokenId)
        ownsExhibit(_msgSender(), _exhibitContractAddress, _exhibitTokenId)
        nonReentrant
    {
        _verifyOwnership(_msgSender(), _tokenId);
        _setExhibit(_tokenId, _exhibitContractAddress, _exhibitTokenId);
    }

    /**
     * @inheritdoc Exhibitionable
     */
    function clearExhibit(uint256 _tokenId) external override tokenExists(_tokenId) nonReentrant {
        _verifyOwnership(_msgSender(), _tokenId);
        _clearExhibit(_tokenId);
    }

    /**
     * @dev Frame
     */

    /**
     * @notice Set rental fee
     * @param _numerator   Rental fee numerator
     * @param _denominator Rental fee denominator
     */
    function setRentalFee(int256 _numerator, int256 _denominator) external onlyOwner(_msgSender()) {
        int256 oldNumerator = rentalFeeNumerator;
        int256 oldDenominator = rentalFeeDenominator;
        rentalFeeNumerator = _numerator;
        rentalFeeDenominator = _denominator;
        emit RentalFeeUpdated(
            oldNumerator,
            oldDenominator,
            rentalFeeNumerator,
            rentalFeeDenominator
        );
    }

    /**
     * @notice Configure a category
     * @param _category        Category to configure
     * @param _price           Price of this category
     * @param _startingTokenId Starting token ID of the category
     * @param _supply          Number of tokens in this category
     */
    function setCategoryDetail(
        Category _category,
        uint256 _price,
        uint256 _startingTokenId,
        uint256 _supply
    ) external onlyOwner(_msgSender()) validCategory(_category) {
        CategoryDetail storage category = categories[_category];
        category.price = _price;
        category.startingTokenId = _startingTokenId;
        category.supply = _supply;

        uint256 j;
        for (j = _startingTokenId; j < (_startingTokenId + _supply); j++) {
            category.tokenIds.add(j);
        }
    }

    /**
     * @notice Set the status of the sale
     * @dev    Possible statuses are the enum SaleStatus
     * @param _status          Status to set
     */
    function setSaleStatus(SaleStatus _status) external onlyOwner(_msgSender()) {
        saleStatus = _status;
    }

    /**
     * @notice Mint a Frame in a given Category
     * @param _category   Category to mint
     */
    function mintFrame(Category _category)
        external
        payable
        mintingAvailable
        validCategory(_category)
        nonReentrant
        whenNotPaused
    {
        if (saleStatus == SaleStatus.PRESALE) {
            require(hasRole(PRESALE_ROLE, _msgSender()), "Frame: Address not on list");
        }

        CategoryDetail storage category = categories[_category];
        require(category.tokenIds.length() > 0, "Frame: Sold out");
        require(msg.value == category.price, "Frame: Incorrect payment for category");
        require(LINK.balanceOf(address(this)) >= fee, "Frame: Not enough LINK");

        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = _msgSender();
        requestIdToCategory[requestId] = _category;

        emit MintRequest(requestId, _msgSender());
    }

    /**
     * @notice fulfillRandomness internal ultimately called by Chainlink Oracles
     * @param requestId     VRF request ID
     * @param randomNumber  The VRF number
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        address minter = requestIdToSender[requestId];
        CategoryDetail storage category = categories[requestIdToCategory[requestId]];

        uint256 tokensReminingInCategory = category.tokenIds.length();
        uint256 tokenIdToAllocate;

        if (tokensReminingInCategory > 1)
            tokenIdToAllocate = category.tokenIds.at(randomNumber % tokensReminingInCategory);
        else tokenIdToAllocate = category.tokenIds.at(0);

        category.tokenIds.remove(tokenIdToAllocate);
        requestIdToTokenId[requestId] = tokenIdToAllocate;
        _safeMint(minter, tokenIdToAllocate);

        emit MintFulfilled(requestId, minter, tokenIdToAllocate);
    }

    /**
     * @dev Accounting functions
     */

    /**
     * @notice Withdraws all LINK token from this contract
     * @param _to Address to receive all the LINK
     */
    function withdrawAllLink(address payable _to) external onlyOwner(_msgSender()) nonReentrant {
        uint256 linkBalance = LINK.balanceOf(address(this));
        require(LINK.transfer(_to, linkBalance), "Frame: Error sending LINK");
        emit LinkWithdrawn(_to, linkBalance);
    }

    /**
     * @notice Withdraws an amount of ether from this contract
     * @param _to Address to receive the ether
     */
    function withdrawEther(address payable _to, uint256 _value)
        external
        onlyOwner(_msgSender())
        nonReentrant
    {
        _transfer(_to, _value);
        emit EtherWithdrawn(_to, _value);
    }
}