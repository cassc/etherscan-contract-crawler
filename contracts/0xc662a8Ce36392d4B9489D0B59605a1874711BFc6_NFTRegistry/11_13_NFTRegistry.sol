pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./IERC20.sol";
import "./IPunks.sol";
import "./IERC721.sol"; 
import "./ReentrancyGuard.sol";
import "./INamingCredits.sol";
import "./IWETH.sol";
import "./INFTRegistry.sol";
import "./IHoldFarming.sol";
import "./IRNM.sol"; 

/**
 * @title NFTRegistry
 * @notice NFTR's main contract. The registry. Where the magic happens.
 */
contract NFTRegistry is ReentrancyGuard, Ownable {

    // Structs
    struct Token {
        address collectionAddress;
        uint256 tokenId;
    }

    // Enums
    enum NamingCurrency {
        Ether,
        RNM,
        NamingCredits
    }
 
    enum NamingState {
        NotReadyYet,
        ReadyForNaming
    }

    NamingState public namingState = NamingState.NotReadyYet;

    // Naming prices, fee recipients, and control parameters
    uint256 public namingPriceEther = 0.05 ether;
    uint256 public immutable MIN_NAMING_PRICE_ETHER;
    uint256 public immutable MIN_NAMING_PRICE_RNM;
    uint256 public namingPriceRNM = 1000 * 10**18;
    address public protocolFeeRecipient;
    uint256 public constant INFINITE_BLOCK = 100000000000;
    uint256 public rnmNamingStartBlock = INFINITE_BLOCK;
    uint256 public constant MAX_NUMBER_CURATED_COLLECTIONS = 10;
    uint256 public numberCuratedCollections;
    uint256 public constant MAX_ASSIGNABLE_NAMING_CREDITS = 10;
    uint256 public constant MAX_TOTAL_ASSIGNABLE_NAMING_CREDITS = 1000;
    uint256 public totalNumberAssignedCredits;
    bool public allowUpdatingFeeRecipient = true;

    // Golden Tickets & Special Names
    uint256 public constant MAX_SPECIAL_NAMES_COUNT = 1000;
    uint256 public numberSpecialNames = 0;
    IERC20 public immutable goldenTicketAddress;
    mapping(string => bool) public specialNames; // List of special (reserved) names. Stored in lowercase.

    // Relevant contract addresses
    IPunks public immutable punksAddress;
    address public immutable WETH;
    IRNM public rnmToken;
    INamingCredits public namingCreditsAddress;
    IHoldFarming public holdFarmingAddress;
    address public marketplaceAddress;

    // Marketplace transfer allowance
    mapping(address => mapping(address => mapping(uint256 => bool)))
        public allowances;

    // Name mappings
    mapping(address => mapping(uint256 => string)) public tokenName;
    mapping(string => Token) public tokenByName; // Stored in lowercase
    mapping(address => mapping(uint256 => uint256)) public firstNamed;

    // Events
    event NameChange(
        address indexed nftAddress,
        uint256 indexed tokenId,
        string newName,
        address sender,
        NamingCurrency namingCurrency,
        uint256 currencyQuantity
    );
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);
    event NewNamingPriceEther(uint256 namingPriceEther);
    event NewNamingPriceRNM(uint256 namingPriceRNM);
    event NewRnmNamingStartBlock(uint256 rnmNamingStartBlock);
    event TransferAllowed(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId
    );
    event TransferDisAllowed(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId
    );
    event NameTransfer(
        address indexed nftAddressFrom,
        uint256 tokenIdFrom,
        address indexed nftAddressTo,
        uint256 tokenIdTo,
        string name,
        address transferer
    );

    /**
     * @notice Constructor
     * @param _punksAddress address of the CryptoPunks contract. Input to constructor for testing purposes
     * @param _goldenTicketAddress address of Golden Ticket contract
     * @param _WETH address of the WETH contract. Input to constructor for testing purposes
     * @param _protocolFeeRecipient protocol fee recipient
     * @param _minNamingPriceEther min naming price that can be set (in Ether)
     * @param _minNamingPriceRNM minimum naming price that can be set (in RNM)
     */
    constructor(
        address _punksAddress,
        address _goldenTicketAddress,
        address _WETH,
        address _protocolFeeRecipient,
        uint256 _minNamingPriceEther,
        uint256 _minNamingPriceRNM
    ) {
        require(_punksAddress != address(0), "NFTRegistry: In constructor, can't set punksAddress to zero");
        require(_goldenTicketAddress != address(0), "NFTRegistry: In constructor, can't set goldenTicketAddress to zero");
        require(_WETH != address(0), "NFTRegistry: In constructor, can't set WETH address to zero");
        require(_protocolFeeRecipient != address(0), "NFTRegistry: In constructor, can't set protocolFeeRecipient to zero");
        require(_minNamingPriceEther > 0, "NFTRegistry: min naming price in Ether must be non-zero");
        require(_minNamingPriceRNM > 0, "NFTRegistry: min naming price in RNM must be non-zero");
        punksAddress = IPunks(_punksAddress);
        goldenTicketAddress = IERC20(_goldenTicketAddress);
        WETH = address(_WETH);
        protocolFeeRecipient = _protocolFeeRecipient;
        MIN_NAMING_PRICE_ETHER = _minNamingPriceEther;
        MIN_NAMING_PRICE_RNM = _minNamingPriceRNM;
    }

    /**
     * @notice Set the RNM address (only once)
     * @param _rnmToken address of the RNM token
     */
    function setRnmTokenAddress(IRNM _rnmToken) external onlyOwner {
        require(
            address(rnmToken) == address(0),
            "NFTRegistry: RNM address has already been set"
        );
        rnmToken = _rnmToken;
    }

    /**
     * @notice Set the Naming Credits contract address once deployed
     * @param _namingCreditsAddress address of the marketplace contract
     */
    function setNamingCreditsAddress(INamingCredits _namingCreditsAddress)
        external
        onlyOwner
    {
        require(
            address(namingCreditsAddress) == address(0),
            "NFTRegistry: naming credits contract address can only be set once"
        );
        namingCreditsAddress = _namingCreditsAddress;
    }

    /**
     * @notice Set the Hold Farming contract address once deployed
     * @param _holdFarmingAddress address of the marketplace contract
     */
    function setHoldFarmingAddress(IHoldFarming _holdFarmingAddress)
        external
        onlyOwner
    {
        require(
            address(holdFarmingAddress) == address(0),
            "NFTRegistry: hold farming contract address can only be set once"
        );
        holdFarmingAddress = _holdFarmingAddress;
    }

    /**
     * @notice Set the Marketplace contract address once deployed
     * @param _marketplaceAddress address of the marketplace contract
     */
    function setMarketplaceAddress(address _marketplaceAddress)
        external
        onlyOwner
    {
        require(
            marketplaceAddress == address(0),
            "NFTRegistry: marketplace contract address can only be set once"
        );
        marketplaceAddress = _marketplaceAddress;
    }

    /**
     * @notice Give the marketplace contract permission to transfer name (for a name sale) for a particular NFT. Care is taken so that if the NFT changes owners, the allowance doesn't hold.
     * @param nftAddress address of the NFT Collection from which name is being transferred
     * @param tokenId token id of the NFT from which the name is being transferred
     */
    function allowTransfer(address nftAddress, uint256 tokenId) external {
        require(
            marketplaceAddress != address(0),
            "NFTRegistry: Marketplace address hasn't been set yet"
        );
        checkOwnership(nftAddress, tokenId); // allowance setter must be the NFT owner

        allowances[msg.sender][nftAddress][tokenId] = true;

        emit TransferAllowed(msg.sender, nftAddress, tokenId);
    }

    /**
     * @notice Disallow marketplace contract to transfer name for a particular NFT
     * @param nftAddress address of the NFT Collection from which name is being transferred
     * @param tokenId token id of the NFT from which the name is being transferred
     */
    function disallowTransfer(address nftAddress, uint256 tokenId) external {
        require(
            marketplaceAddress != address(0),
            "NFTRegistry: Marketplace address hasn't been set yet"
        );
        checkOwnership(nftAddress, tokenId);

        allowances[msg.sender][nftAddress][tokenId] = false;

        emit TransferDisAllowed(msg.sender, nftAddress, tokenId);
    }

    /**
     * @notice Used by the marketplace contract to transfer a name from one NFT to another. Transfer allowance isn't reset, so if the NFT is named again it doesn't have to be allowed again to transfer its name, as long as it's still owned by the same allower. Transfer allowance is per owner, so doesn't travel with the NFT.
     * @param nftAddressFrom address of the NFT Collection from which name is being transferred
     * @param tokenIdFrom token id of the NFT from which the name is being transferred
     * @param nftAddressTo address of the NFT Collection to which name is being transferred
     * @param tokenIdTo token id of the NFT to which the name is being transferred
     */
    function transferName(
        address nftAddressFrom,
        uint256 tokenIdFrom,
        address nftAddressTo,
        uint256 tokenIdTo
    ) external {
        require(
            marketplaceAddress != address(0),
            "NFTRegistry: Marketplace address hasn't been set yet"
        );
        require(
            msg.sender == marketplaceAddress,
            "NFTRegistry: Only the Marketplace contract can make this call"
        );

        // Obtain current NFT owner
        address nftOwner = getOwner(nftAddressFrom, tokenIdFrom);

        // Check that name can be transferred
        require(
            allowances[nftOwner][nftAddressFrom][tokenIdFrom],
            "NFTRegistry: NFT hasn't been allowed for name transfer"
        );

        // Check that token mapping is set
        string memory _tokenName = tokenName[nftAddressFrom][tokenIdFrom];
        require(
            bytes(_tokenName).length > 0,
            "NFTRegistry: Can't transfer name as it isn't set"
        );
        // Transfer name
        tokenName[nftAddressFrom][tokenIdFrom] = "";
        tokenName[nftAddressTo][tokenIdTo] = _tokenName;
        tokenByName[toLower(_tokenName)] = Token(nftAddressTo, tokenIdTo);

        emit NameTransfer(
            nftAddressFrom,
            tokenIdFrom,
            nftAddressTo,
            tokenIdTo,
            _tokenName,
            nftOwner
        );
    }

    /**
     * @notice Update the naming price in ETH
     * @param _namingPriceEther naming price in Ether
     */
    function updateNamingPriceEther(uint256 _namingPriceEther)
        external
        onlyOwner
    {
        require(
            _namingPriceEther >= MIN_NAMING_PRICE_ETHER,
            "NFTRegistry: ETHER naming price too low"
        );
        namingPriceEther = _namingPriceEther;

        emit NewNamingPriceEther(namingPriceEther);
    }

    /**
     * @notice Update the naming price in RNM
     * @param _namingPriceRNM naming price in RNM
     */
    function updateNamingPriceRNM(uint256 _namingPriceRNM) external onlyOwner {
        require(
            _namingPriceRNM >= MIN_NAMING_PRICE_RNM,
            "NFTRegistry: RNM naming price too low"
        );
        namingPriceRNM = _namingPriceRNM;

        emit NewNamingPriceRNM(namingPriceRNM);
    }

    /**
     * @notice Update the recipient of protocol (naming) fees in WETH
     * @param _protocolFeeRecipient protocol fee recipient
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient)
        external
        onlyOwner
    {
        require(allowUpdatingFeeRecipient, "NFTRegistry: Updating the protocol fee recipient has been shut off");
        protocolFeeRecipient = _protocolFeeRecipient;

        emit NewProtocolFeeRecipient(protocolFeeRecipient);
    }

    /**
     * @notice Update starting block for RNM naming
     * @param _rnmNamingStartBlock starting block of RNM naming
     */
    function updateRnmNamingStartBlock(uint256 _rnmNamingStartBlock)
        external
        onlyOwner
    {
        require(
            rnmNamingStartBlock == INFINITE_BLOCK,
            "NFTRegistry: rnmNamingStartBlock can only be set once"
        );
        require(
            _rnmNamingStartBlock > block.number,
            "NFTRegistry: RNM naming start block can't be set to past"
        );
        require(
            _rnmNamingStartBlock < block.number + 192000, // + 1 month
            "NFTRegistry: RNM naming start block can't be set so far in advance"
        );
        rnmNamingStartBlock = _rnmNamingStartBlock;

        emit NewRnmNamingStartBlock(rnmNamingStartBlock);
    }

    /**
     * @notice Returns name of the NFT at (address, index).
     * @param nftAddress Address of NFT collection
     * @param index token index of NFT within collection
     */
    function tokenNameByIndex(address nftAddress, uint256 index)
        external
        view
        returns (string memory)
    {
        return tokenName[nftAddress][index];
    }

    /**
     * @notice Sets/Changes the name of an NFT
     * @param nftAddress address of the NFT collection
     * @param tokenId NFT token id
     * @param newName name to register for the NFT with tokenId
     * @param namingCurrency currency used for naming fee
     * @param currencyQuantity quantity of naming currency to spend. This disables the contract owner from being able to front-run naming to extract unintended quantiy of assets (WETH or RNM)
     */
    function changeName(
        address nftAddress,
        uint256 tokenId,
        string memory newName,
        NamingCurrency namingCurrency,
        uint256 currencyQuantity
    ) external payable nonReentrant {
        require(
            namingState == NamingState.ReadyForNaming,
            "NFTRegistry: Not ready for naming yet"
        );
        checkOwnership(nftAddress, tokenId);
        require(
            validateName(newName),
            "NFTRegistry: Not a valid new name"
        );
        require(
            sha256(bytes(newName)) !=
                sha256(bytes(tokenName[nftAddress][tokenId])),
            "NFTRegistry: New name is same as the current one"
        );
        require(
            isTokenStructEmpty(tokenByName[toLower(newName)]),
            "NFTRegistry: Name already reserved"
        );
        if (namingCurrency == NamingCurrency.NamingCredits) {
            require(currencyQuantity == 1, "NFTRegistry: currencyQuantity must be 1 when naming with Naming Credits");
        }
        else if (namingCurrency == NamingCurrency.RNM) {
            require(currencyQuantity == namingPriceRNM, "NFTRegistry: currencyQuantity must be equal to namingPriceRNM when naming with RNM");            
        }
        else { // namingCurrency is Ether
            require(currencyQuantity == namingPriceEther, "NFTRegistry: currencyQuantity must be equal to namingPriceEther when naming with Ether");               
        }

        // Check if the name is from the special list and thus golden ticket is required and available
        if (specialNames[toLower(newName)]) {
            IERC20(goldenTicketAddress).transferFrom(
                msg.sender,
                address(this),
                1
            );
        }

        if (
            namingCurrency == NamingCurrency.RNM &&
            block.number < rnmNamingStartBlock
        ) {
            revert("NFTRegistry: Not ready for naming paid with RNM");
        }

        bool freeNaming = false;
        if (address(holdFarmingAddress) != address(0) && firstNamed[nftAddress][tokenId] == 0) {
            // Check if the NFT being named is curated and is still in hold farming period
            (uint256 startBlock, uint256 lastBlock) = 
                holdFarmingAddress.holdFarmingBlocks(nftAddress);
            if (block.number >= startBlock && block.number <= lastBlock) {
                // Hold farming is still enabled for this collection. Allow free naming.
                holdFarmingAddress.initiateHoldFarmingForNFT(
                    nftAddress,
                    tokenId
                );

                freeNaming = true;
            }
        }

        if (!freeNaming) {
            if (namingCurrency == NamingCurrency.Ether) {
                // If not enough ETH to cover the price, use WETH
                if (namingPriceEther > msg.value) {
                    require(
                        IERC20(WETH).balanceOf(msg.sender) >=
                            (namingPriceEther - msg.value),
                        "NFTRegistry: Not enough ETH sent or WETH available"
                    );
                    IERC20(WETH).transferFrom(
                        msg.sender,
                        address(this),
                        (namingPriceEther - msg.value)
                    );
                } else {
                    require(
                        namingPriceEther == msg.value,
                        "NFTRegistry: Too much Ether sent for naming"
                    );
                }

                // Wrap ETH sent to this contract 
                IWETH(WETH).deposit{value: msg.value}();
                IERC20(WETH).transfer(
                    protocolFeeRecipient,
                    namingPriceEther
                );
            } else if (namingCurrency == NamingCurrency.NamingCredits) {
                require(
                    address(namingCreditsAddress) != address(0),
                    "NFTRegistry: Naming Credits contract isn't set yet"
                );
                namingCreditsAddress.reduceNamingCredits(
                    msg.sender,
                    1
                );
            } else if (namingCurrency == NamingCurrency.RNM) {
                require(
                    address(rnmToken) != address(0),
                    "NFTRegistry: RNM contract isn't set yet"
                );
                IERC20(rnmToken).transferFrom(
                    msg.sender,
                    address(this),
                    namingPriceRNM
                );
                IRNM(rnmToken).burn(namingPriceRNM);
            } else {
                revert("NFTRegistry: The currency isn't supported for naming");
            }   
        }

        // If already named, dereserve old name
        if (bytes(tokenName[nftAddress][tokenId]).length > 0) {
            releaseTokenByName(tokenName[nftAddress][tokenId]);
        }
        tokenByName[toLower(newName)] = Token(nftAddress, tokenId);
        tokenName[nftAddress][tokenId] = newName;

        if (firstNamed[nftAddress][tokenId] == 0) {
            firstNamed[nftAddress][tokenId] = block.number;
        }
        emit NameChange(
            nftAddress,
            tokenId,
            newName,
            msg.sender,
            namingCurrency,
            currencyQuantity
        );
    }

    /**
     * @notice Check if the message sender owns the NFT
     * @param nftAddress address of the NFT collection
     * @param tokenId token id of the NFT
     */
    function checkOwnership(address nftAddress, uint256 tokenId) internal view {
        require(msg.sender == getOwner(nftAddress, tokenId), "NFTRegistry: Caller is not the NFT owner");
    }

    /**
     * @notice Get NFT's owner
     * @param nftAddress address of the NFT collection
     * @param tokenId token id of the NFT
     */
    function getOwner(address nftAddress, uint256 tokenId)
        internal
        view
        returns (address)
    {
        if (nftAddress == address(punksAddress)) {
            return IPunks(punksAddress).punkIndexToAddress(tokenId);
        } else {
            return IERC721(nftAddress).ownerOf(tokenId);
        }
    }

    /**
     * @notice Check if a Token structure is empty
     * @param token_in token to check
     */
    function isTokenStructEmpty(Token memory token_in)
        internal
        pure
        returns (bool)
    {
        return (token_in.collectionAddress == address(0) && token_in.tokenId == 0);
    }

    /**
     * @notice Returns NFT collection contract address and tokenId in Token struct if the name is reserved
     * @param nameString name of the NFT
     */
    function getTokenByName(string memory nameString)
        external
        view
        returns (Token memory)
    {
        return tokenByName[toLower(nameString)];
    }

    /**
     * @notice Releases the name so another person can register it
     * @param str name to deregister
     */
    function releaseTokenByName(string memory str) internal {
        delete tokenByName[toLower(str)];
    }

    /**
     * @notice Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     * @param str name to validate
     */
    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            lastChar = char;
        }

        return true;
    }

    /**
     * @notice Converts the string to lowercase
     * @param str string to convert
     */
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    /**
     * @notice Adds special names to the special names list. Unfortunately can't be handled with a Merkle Tree as they can only be used to prove that a nem is in a set, but not that a name is not in a set. That is, non-special names can't be checked against such Merkle Tree. So we are only left with burning the special names into the contract state.
     * @param _specialNames array of special names to reserve
     */
    function setSpecialNames(string[] memory _specialNames) external onlyOwner {
        require(
            numberSpecialNames + _specialNames.length <=
                MAX_SPECIAL_NAMES_COUNT,
            "NFTRegistry: This would make special names list longer than allowed"
        );
        for (uint256 i = 0; i < _specialNames.length; i++) {
            require(
                !specialNames[toLower(_specialNames[i])],
                "NFTRegistry: At least one of the names is already in the special list"
            );
            specialNames[toLower(_specialNames[i])] = true;
            numberSpecialNames++;
        }
        if (numberSpecialNames == MAX_SPECIAL_NAMES_COUNT) {
            namingState = NamingState.ReadyForNaming;
        }
    }

    /**
     * @notice Assign naming credits in the NamingCredits contract. Avoids mistakes assigning more than 10 credits.
     * @param user address of the user assigning credits to
     * @param numberOfCredits number of credits to assign
     */
    function assignNamingCredits(address user, uint256 numberOfCredits)
        external
        onlyOwner
    {
        require(
            address(namingCreditsAddress) != address(0),
            "NFTRegistry: Naming Credits contract isn't set yet"
        );
        require(numberOfCredits <= MAX_ASSIGNABLE_NAMING_CREDITS, "NFTRegistry: Can't assign that number of credits in a single call");
        require(totalNumberAssignedCredits + numberOfCredits <= MAX_TOTAL_ASSIGNABLE_NAMING_CREDITS, "NFTRegistry: Assigning that number of credits would take total assigned credits over the limit");
        totalNumberAssignedCredits += numberOfCredits;
        namingCreditsAddress.assignNamingCredits(
            user,
            numberOfCredits
        );
    }

    /**
     * @notice Shut off naming credit assignments in the NamingCredits contract
     */
    function shutOffAssignments() external onlyOwner {
        require(
            address(namingCreditsAddress) != address(0),
            "NFTRegistry: Naming Credits contract isn't set yet"
        );
        namingCreditsAddress.shutOffAssignments();
    }

    /**
     * @notice Shut off protocol fee recipient updates
     */
    function shutOffFeeRecipientUpdates() external onlyOwner {
        allowUpdatingFeeRecipient = false;
    }    

    /**
     * @notice Update protocol fee recipient in the NamingCredits contract
     */
    function updateNamingCreditsProtocolFeeRecipient(
        address _protocolFeeRecipient
    ) external onlyOwner {
        require(
            address(namingCreditsAddress) != address(0),
            "NFTRegistry: Naming Credits contract isn't set yet"
        );
        require(allowUpdatingFeeRecipient, "NFTRegistry: Updating the protocol free recipient has been shut off");
        namingCreditsAddress.updateProtocolFeeRecipient(
            _protocolFeeRecipient
        );
    }

    /**
     * @notice Call the HoldFarming contract curateCollection function
     * @param nftAddress address of the NFT collection contract to be curated
     */
    function curateCollection(address nftAddress) external onlyOwner {
        require(
            address(holdFarmingAddress) != address(0),
            "NFTRegistry: Hold Farming contract isn't set yet"
        );
        require(numberCuratedCollections < MAX_NUMBER_CURATED_COLLECTIONS, "NFTRegistry: Number of curated collections has been maxed out");
        numberCuratedCollections++;
        holdFarmingAddress.curateCollection(nftAddress);
    }

    /**
     * @notice Withdraw any RNM that got sent to the contract by accident
     */
    function withdrawRNM() external onlyOwner {
        require(
            address(rnmToken) != address(0),
            "NFTRegistry: RNM contract isn't set yet"
        );
        uint256 withdrawableRNM = IERC20(rnmToken).balanceOf(address(this));
        require(
            withdrawableRNM != 0,
            "NFTRegistry: There is no RNM to withdraw"
        );
        IERC20(rnmToken).transfer(
            msg.sender,
            withdrawableRNM
        );
    }
}