// SPDX-License-Identifier: MIT
// Creator: OrigamasksTeam

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract RewardContract {
    function mintReward(address to_, uint256 tokenId_) public payable virtual returns (uint256);
}

error ProvenanceHashNotSetYet();
error LevelNotReachedToClaim();
error RewardAddressNotSetYet();
error LimitPerWalletExceeded();
error RewardAlreadyClaimed();
error StartingIndexExisted();
error WrongFieldTripLevel();
error ExceedReservedSpots();
error WrongDaysToLevelUp();
error LevelNotAvailable();
error TokenNotAvailable();
error InvalidSignature();
error InvalidSaleState();
error TokenOutOfRange();
error FieldTripClosed();
error ExceedVIPSpots();
error NotOnFieldTrip();
error IncorrectPrice();
error PublicNotReady();
error TransferFailed();
error WrongMaxLevel();
error LevelExisted();
error SizeNotSame();
error ZeroAddress();
error OnFieldTrip();
error NotOwner();
error NotUser();
error SoldOut();
error Level0();

contract Origamasks is
    ERC721,
    ERC2981,
    ReentrancyGuard,
    AccessControl,
    DefaultOperatorFilterer,
    Ownable,
    VRFV2WrapperConsumerBase
{
    using ECDSA for bytes32;

    // ECDSA signing address
    address public signerAddress;

    enum SaleState {
        Closed,
        VIP,
        BuddyList,
        WaitList,
        Public,
        Airdrop,
        Reserve
    }

    SaleState public saleState;

    mapping(address => uint256[]) private mintedTokenIds; // Tracker tokenIds that owned by wallet address
    mapping(address => uint256) private buddyListMints; // Buddy List quota
    mapping(address => uint256) private waitListMints; // Wait List quota (if still available)
    mapping(address => uint256) private publicMints; // Public quota (if still available)

    uint256 public collectionSize = 5000;
    uint256 public totalSupply = 0;
    uint256 public vipSupply;
    uint256 public mintPrice = 0.025 ether;
    uint256 public waitListMintPrice = 0.035 ether;
    uint256 public publicMintPrice;
    uint256 public constant VIP_LIMIT_PER_WALLET = 1;
    uint256 public buddyListLimitPerWallet = 2;
    uint256 public waitListLimitPerWallet = 2;
    uint256 public publicLimitPerWallet = 2;
    uint256 public numberReserved = 200;

    mapping(uint256 => string) public baseTokenUriPerLevel;
    string private contractMetadataURI;
    string public provenanceHash;
    uint256 public startingIndex;

    struct Experience {
        uint256 level;
        uint256 daysToLevelUp;
    }
    mapping(uint256 => Experience) public experienceData;

    constructor(
        address signer_,
        address payable origamasksAddress_,
        address linkAddress_,
        address wrapperAddress_,
        uint256 vipSupply_,
        uint256 minimumReserved_,
        uint256 initialMaxLevel_,
        uint256 initialDaysToLevelUp_
    )
        ERC721("Origamasks", unicode"⭐")
        VRFV2WrapperConsumerBase(linkAddress_, wrapperAddress_)
    {
        setSignerAddress(signer_);
        setOrigamasksAddress(origamasksAddress_);
        setRoyaltyInfo(500); //(500 → 5%)
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        linkAddress = linkAddress_;
        vipSupply = vipSupply_;
        numberReserved = minimumReserved_;
        setNewMaxLevel(initialMaxLevel_, initialDaysToLevelUp_);

        _mint(origamasksAddress_, 1); // Will be included to numberReserved (initial collection setup purpose)
    }

    /**
     * @dev Handle VIP minting
     * @param signature_ Validate signature
     * @param tokenId_ Chosen tokenId
     */
    function VIPMint(bytes calldata signature_, uint256 tokenId_)
        external
        payable
        isSaleState(SaleState.VIP)
    {
        // General validation
        if (tokenId_ < 1 || tokenId_ > collectionSize) revert TokenOutOfRange();

        // Specific per sale state validation
        if (!verifySignature(signature_, "VIP")) revert InvalidSignature();
        if (totalSupply + 1 > vipSupply) revert ExceedVIPSpots();
        if (msg.value != mintPrice) revert IncorrectPrice();
        if (buddyListMints[msg.sender] >= VIP_LIMIT_PER_WALLET) revert LimitPerWalletExceeded();

        // Save purchased token ids
        mintedTokenIds[msg.sender].push(tokenId_);

        // Track and future validation
        buddyListMints[msg.sender] += 1;
        
        // User instantly receive the token
        _mint(msg.sender, tokenId_);
        totalSupply++;

        emit Minted(msg.sender, SaleState.VIP, msg.value, tokenId_);
    }

    /**
     * @dev Handle Buddy List minting
     * @param signature_ Validate signature
     * @param tokenId_ Chosen tokenId
     */
    function buddyListMint(bytes calldata signature_, uint256 tokenId_)
        external
        payable
        isSaleState(SaleState.BuddyList)
    {
        // General validation
        if (tokenId_ < 1 || tokenId_ > collectionSize) revert TokenOutOfRange();

        // Specific per sale state validation
        if (!verifySignature(signature_, "BuddyList")) revert InvalidSignature();
        if (totalSupply + 1 > maxSupply()) revert SoldOut();
        if (msg.value != mintPrice) revert IncorrectPrice();
        if (buddyListMints[msg.sender] >= buddyListLimitPerWallet) revert LimitPerWalletExceeded();

        // Save purchased token ids
        mintedTokenIds[msg.sender].push(tokenId_);

        // Track and future validation
        buddyListMints[msg.sender] += 1;
        
        // User instantly receive the token
        _mint(msg.sender, tokenId_);
        totalSupply++;

        emit Minted(msg.sender, SaleState.BuddyList, msg.value, tokenId_);
    }

    /**
     * @dev handle Buddy List + Wait List minting
     * @param signature_ Validate signature
     * @param tokenId_ Chosen tokenId
     */
    function waitListMint(bytes calldata signature_, uint256 tokenId_)
        external
        payable
        isSaleState(SaleState.WaitList)
    {
        // General validation
        if (tokenId_ < 1 || tokenId_ > collectionSize) revert TokenOutOfRange();

        // Specific per sale state validation
        if (!verifySignature(signature_, "WaitList")) revert InvalidSignature();
        if (totalSupply + 1 > maxSupply()) revert SoldOut();
        if (msg.value != waitListMintPrice) revert IncorrectPrice();
        if (waitListMints[msg.sender] >= waitListLimitPerWallet) revert LimitPerWalletExceeded();

        // Save purchased token ids
        mintedTokenIds[msg.sender].push(tokenId_);

        // Track and future validation
        waitListMints[msg.sender] += 1;
        
        // User instantly receive the token
        _mint(msg.sender, tokenId_);
        totalSupply++;

        emit Minted(msg.sender, SaleState.WaitList, msg.value, tokenId_);
    }

    /**
     * @dev Handle Public minting
     * @param signature_ Validate signature
     * @param tokenId_ Chosen tokenId
     */
    function publicMint(bytes calldata signature_, uint256 tokenId_)
        external
        payable
        isSaleState(SaleState.Public)
    {
        if (publicMintPrice == 0) revert PublicNotReady();

        // General validation
        if (tokenId_ < 1 || tokenId_ > collectionSize) revert TokenOutOfRange();

        // Specific per sale state validation
        if (!verifySignature(signature_, "Public")) revert InvalidSignature();
        if (totalSupply + 1 > maxSupply()) revert SoldOut();
        if (msg.value != publicMintPrice) revert IncorrectPrice();
        if (publicMints[msg.sender] >= publicLimitPerWallet) revert LimitPerWalletExceeded();

        // Save purchased token ids
        mintedTokenIds[msg.sender].push(tokenId_);

        // Track and future validation
        publicMints[msg.sender] += 1;
        
        // User instantly receive the token
        _mint(msg.sender, tokenId_);
        totalSupply++;

        emit Minted(msg.sender, SaleState.Public, msg.value, tokenId_);
    }

    /**
     * @dev Reserve tokens (will be done after all sale finished)
     */
    function reserve(uint256[] memory tokenIds, address receiver_)
        external
        onlyOwner
        isSaleState(SaleState.Reserve)
    {
        if (totalSupply + tokenIds.length > collectionSize) revert ExceedReservedSpots();

        // Loop through owners' addresses
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(receiver_, tokenIds[i]);
            totalSupply++;
        }
    }

    /**
     * @dev Emitted when mint
     */
    event Minted(
        address indexed to,
        SaleState indexed state,
        uint256 amount,
        uint256 indexed tokenId
    );

    /**
     * @dev Get array of tokenIds that owned by ownerAddress_
     * @param ownerAddress_ Address of the owner
     */
    function getMintedTokenIds(address ownerAddress_)
        public
        view
        returns (uint256[] memory)
    {
        return mintedTokenIds[ownerAddress_];
    }


    /**
     * @dev Get maximum supply that can be minted
     */
    function maxSupply() public view returns (uint256) {
        return collectionSize - numberReserved;
    }

    /**
     * @dev Tracker minted on Buddy List
     */
    function numberMintedBuddyList(address address_)
        external
        view
        returns (uint256)
    {
        return buddyListMints[address_];
    }

    /**
     * @dev Tracker minted on Wait List
     */
    function numberMintedWaitList(address address_)
        external
        view
        returns (uint256)
    {
        return waitListMints[address_];
    }

    /**
     * @dev Tracker minted on Public
     */
    function numberMintedPublic(address address_)
        external
        view
        returns (uint256)
    {
        return publicMints[address_];
    }

    /**
     * @dev Airdrop for many addresses with specific tokenIds
     * @param tos_ Many addresses
     * @param tokenIds_ Matched token id
     */
    function airdrop(address[] memory tos_, uint256[] memory tokenIds_)
        external
        onlyOwner
        nonReentrant
        isSaleState(SaleState.Airdrop)
    {
        if (tos_.length != tokenIds_.length) revert SizeNotSame();

        // Loop through owners' addresses
        for (uint256 i = 0; i < tos_.length; i++) {
            address _receiver = tos_[i];
            uint256 _tokenId = tokenIds_[i];

            // Track and future validation
            buddyListMints[_receiver] += 1;
            _mint(_receiver, _tokenId);
            totalSupply++;
        }
    }

    /**
     * @dev verify ECDSA signature
     */
    function verifySignature(
        bytes memory signature_,
        string memory saleStateName_
    ) internal view returns (bool) {
        return
            signerAddress ==
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    bytes32(abi.encodePacked(msg.sender, saleStateName_))
                )
            ).recover(signature_);
    }

    /**
    @dev Emitted when sale state changed.
     */
    event SaleStateChanged(SaleState indexed saleState);

    modifier isSaleState(SaleState saleState_) {
        if (msg.sender != tx.origin) revert NotUser();
        if (saleState != saleState_) revert InvalidSaleState();
        _;
    }

    /*
    // @dev Change the current `saleState` value. 
    */
    function setSaleState(uint256 saleState_) external onlyOwner {
        saleState = SaleState(saleState_);
        emit SaleStateChanged(saleState);
    }

    /*
    // @dev Dynamic tokenURI based on level
    */
    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "Token doesn't exist!");

        uint256 _currentLevel = getLevel(tokenId_);
        return
            string(
                abi.encodePacked(
                    baseTokenUriPerLevel[_currentLevel],
                    Strings.toString(tokenId_)
                )
            );
    }

    /*
     *
     * F
     * I
     * E
     * L
     * D
     *
     * T
     * R
     * I
     * P
     *
     */

    /**
     * @dev Level is tied to tokenId, not owner
     */
    mapping(uint256 => uint256) private levelTokenId;
    uint256 public maxLevel;

    /**
     * @dev TokenId to fieldTrip start time in epoch (0 = not fieldTrip)
     */
    mapping(uint256 => uint256) private fieldTripStarted;

    /**
     * @dev Start field trip
     */
    function startFieldTrip(uint256 tokenId_, uint256 level_)
        internal
        onlyApprovedOrOwner(tokenId_)
    {
        if (!fieldTripOpen[level_]) revert FieldTripClosed();
        if (fieldTripStarted[tokenId_] > 0) revert OnFieldTrip();
        if (level_ > maxLevel) revert LevelNotAvailable();

        fieldTripStarted[tokenId_] = block.timestamp; //change time
        emit StartedFieldTrip(tokenId_, level_); //emit
    }

    /**
     * @dev Stop field trip
     */
    function stopFieldTrip(uint256 tokenId_)
        internal
        onlyApprovedOrOwner(tokenId_)
    {
        if (fieldTripStarted[tokenId_] == 0) revert NotOnFieldTrip();

        // Level up if already level up in field trip
        if (isLeveledUpFromCurrentFieldTrip(tokenId_)) {
            uint256 currentLevel = levelTokenId[tokenId_];
            levelTokenId[tokenId_] = currentLevel + 1;
        }

        // Reset if dismissed
        fieldTripStarted[tokenId_] = 0;

        emit StoppedFieldTrip(tokenId_);
    }

    /**
     * @dev Start field trip for many tokenIds
     */
    function startManyFieldTrips(uint256[] calldata tokenIds_) external {
        uint256 count = tokenIds_.length;
        for (uint256 i = 0; i < count; i++) {
            uint256 nextLevel = getLevel(tokenIds_[i]) + 1;
            if (nextLevel <= maxLevel) {
                startFieldTrip(tokenIds_[i], nextLevel);
            }
        }
    }

    /**
     * @dev Stop field trip for many tokenIds
     */
    function stopManyFieldTrips(uint256[] calldata tokenIds_) external {
        uint256 count = tokenIds_.length;
        for (uint256 i = 0; i < count; i++) {
            stopFieldTrip(tokenIds_[i]);
        }
    }

    /* 
    Linked with the token (not reset upon sale)
    return "isFieldTrip" status fieldTrip
    return "currentPeriod" how long already fieldTrip, in seconds
    return "prevLevel" current level fieldTrip
    return "isLeveledUp" check if already leveled up before stop field trip
    */
    function fieldTripStatus(uint256 tokenId_)
        public
        view
        returns (
            bool isFieldTrip,
            uint256 currentPeriod,
            uint256 prevLevel,
            bool isLeveledUp
        )
    {
        uint256 start = fieldTripStarted[tokenId_];
        if (start > 0) {
            isFieldTrip = true;
            currentPeriod = block.timestamp - start;
        }

        prevLevel = levelTokenId[tokenId_];

        uint256 daysNeededToLevelUp = levelData[prevLevel + 1];

        // make sure next level already exists && currentPeriod already passed
        if (
            daysNeededToLevelUp > 0 &&
            currentPeriod >= (daysNeededToLevelUp * 86400)
        ) {
            isLeveledUp = true;
        }
    }

    /**
     * @dev level => days needed to level up
     */
    mapping(uint256 => uint256) public levelData;

    /**
     * @dev Set new max level
     */
    function setNewMaxLevel(uint256 newMaxLevel_, uint256 daysToLevelUp_)
        public
        onlyOwner
    {
        if (levelData[newMaxLevel_] > 0) revert LevelExisted();
        if (daysToLevelUp_ <= 0) revert WrongDaysToLevelUp();
        if (newMaxLevel_ != maxLevel + 1) revert WrongMaxLevel();

        levelData[newMaxLevel_] = daysToLevelUp_;
        maxLevel = newMaxLevel_;
    }

    /**
     * @dev Get current level for specific tokenId (Dynamic tokenURI)
     */
    function getLevel(uint256 tokenId_) public view returns (uint256) {
        uint256 newLevel = levelTokenId[tokenId_];
        if (isLeveledUpFromCurrentFieldTrip(tokenId_)) {
            newLevel += 1;
        }
        return newLevel;
    }

    /**
     * @dev Status if already leveled up in current Field Trip
     */
    function isLeveledUpFromCurrentFieldTrip(uint256 tokenId_)
        public
        view
        returns (bool)
    {
        bool isLeveledUp;
        (, , , isLeveledUp) = fieldTripStatus(tokenId_);
        return isLeveledUp;
    }

    /**
     * @dev Force dismiss - with help manually from DISMISS role
     */
    function dismissFromFieldTrip(uint256 tokenId_)
        external
        onlyRole(DISMISS_ROLE)
    {
        if (fieldTripStarted[tokenId_] == 0) revert NotOnFieldTrip();

        // Level up if already level up in field trip
        if (isLeveledUpFromCurrentFieldTrip(tokenId_)) {
            uint256 currentLevel = levelTokenId[tokenId_];
            levelTokenId[tokenId_] = currentLevel + 1;
        }

        // Reset if dismissed
        fieldTripStarted[tokenId_] = 0;

        emit StoppedFieldTrip(tokenId_); // emit Unnested
        emit Dismissed(tokenId_); // emit Expelled
    }

    /**
     * @notice Block transfer when Field Trip
     */
    function _beforeTokenTransfer(
        address,
        address,
        uint256 tokenId,
        uint256
    ) internal view override {
        if (fieldTripStarted[tokenId] > 0) revert OnFieldTrip();
    }

    /**
    @dev Emitted when starts fieldTrip.
     */
    event StartedFieldTrip(uint256 indexed tokenId, uint256 indexed nextLevel);

    /**
    @dev Emitted when stops fieldTrip
     */
    event StoppedFieldTrip(uint256 indexed tokenId);

    /**
    @dev Emitted when is Dismissed from the fieldTrip.
     */
    event Dismissed(uint256 indexed tokenId);

    /**
    @notice Whether fieldTrip is currently allowed.
    @dev If false then fieldTrip is blocked, but stopFieldTrip is always allowed.
     */
    mapping(uint256 => bool) public fieldTripOpen;

    /**
    @notice Toggles the `fieldTripOpen` flag.
     */
    function setFieldTripOpen(uint256 level_, bool open_) external onlyOwner {
        if (level_ <= 0) revert Level0();
        if (level_ > maxLevel) revert LevelNotAvailable();

        fieldTripOpen[level_] = open_;
    }

    bytes32 public constant DISMISS_ROLE = keccak256("DISMISS_ROLE");

    /**
     * @dev REWARD based on Level of the token
     */
    mapping(uint256 => bool) public rewardAlreadyClaimed; // check claimed status
    mapping(uint256 => address) public rewardContractAddress; // reward contract per level
    mapping(uint256 => bool) public rewardOpenToClaim;

    function claimReward(uint256 level_, uint256 tokenId_) public payable {
        if (ownerOf(tokenId_) != msg.sender) revert NotOwner();
        if (getLevel(tokenId_) < level_) revert LevelNotReachedToClaim();
        if (rewardAlreadyClaimed[tokenId_]) revert RewardAlreadyClaimed();
        if (rewardContractAddress[level_] == address(0x0))
            revert RewardAddressNotSetYet();

        rewardAlreadyClaimed[tokenId_] = true;
        RewardContract rewardContract = RewardContract(
            rewardContractAddress[level_]
        );
        rewardContract.mintReward{value: msg.value}(msg.sender, tokenId_);
    }

    function setRewardContract(uint256 level_, address contractAddress_)
        public
        onlyOwner
    {
        rewardContractAddress[level_] = contractAddress_;
    }

    function setRewardOpenToClaim(uint256 level_, bool open_) public onlyOwner {
        if (rewardContractAddress[level_] == address(0x0))
            revert RewardAddressNotSetYet();
        rewardOpenToClaim[level_] = open_;
    }

    /**
     * @dev SET THE PROVENANCE HASH for Fairness Random
     */
    function setProvenanceHash(string memory provenanceHash_)
        external
        onlyOwner
    {
        provenanceHash = provenanceHash_;
    }

    /* BEGIN CHAINLINK CONFIG */

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    // ChainLink config
    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    address public linkAddress;

    /* END CHAINLINK CONFIG */

    // Request random for provable fairness
    function requestRandomStartingIndex()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        if (bytes(provenanceHash).length <= 0) revert ProvenanceHashNotSetYet(); // should be done after provenance hash existed
        if (startingIndex > 0) revert StartingIndexExisted(); // once only

        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;

        startingIndex = _randomWords[0] % collectionSize;
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }

        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (
            uint256 paid,
            bool fulfilled,
            uint256[] memory randomWords
        )
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    /**
     * @dev Set LINK address
     */
    function setLinkAddress(address linkAddress_) external onlyOwner {
        linkAddress = linkAddress_;
    }

    /**
     * @dev Filter registry
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Set the baseTokenURI for {_baseURI}
     */
    function setBaseTokenURI(string memory baseTokenURI_, uint256 level_)
        public
        onlyOwner
    {
        baseTokenUriPerLevel[level_] = baseTokenURI_;
    }

    /**
     * @dev Owner's
     */
    function setBuddyListLimitPerWallet(uint256 newLimit_) external onlyOwner {
        buddyListLimitPerWallet = newLimit_;
    }

    function setWaitListLimitPerWallet(uint256 newLimit_) external onlyOwner {
        waitListLimitPerWallet = newLimit_;
    }

    function setPublicLimitPerWallet(uint256 newLimit_) external onlyOwner {
        publicLimitPerWallet = newLimit_;
    }

    function setContractMetadataURI(string memory contractMetadataURI_)
        public
        onlyOwner
    {
        contractMetadataURI = contractMetadataURI_;
    }

    function setSignerAddress(address signerAddress_) public onlyOwner {
        if (signerAddress_ == address(0)) revert ZeroAddress();
        signerAddress = signerAddress_;
    }

    function setMintPrice(uint256 mintPrice_) public onlyOwner {
        mintPrice = mintPrice_;
    }

    function setPublicMintPrice(uint256 publicMintPrice_) public onlyOwner {
        publicMintPrice = publicMintPrice_;
    }

    /**
     * In case needed, otherwise just use from constructor
     * @dev newSupply_
     */
    function setVIPSupply(uint256 newSupply_) external onlyOwner {
        vipSupply = newSupply_;
    }

    /**
     * Will be set at the end of sale state if needed
     * @dev numberReserved_ new reserved qty
     */
    function setNumberReservedToken(uint256 numberReserved_)
        external
        onlyOwner
    {
        numberReserved = numberReserved_;
    }

    // Sets Origamasks Address for withdraw(), reserved tokens, and ERC2981 royaltyInfo
    address payable public origamasksAddress;

    /**
     * @dev Update the Origamasks address
     */
    function setOrigamasksAddress(address payable origamasksAddress_)
        public
        onlyOwner
    {
        if (origamasksAddress_ == address(0)) revert ZeroAddress();
        origamasksAddress = origamasksAddress_;
    }

    /**
     * @dev Update the royalty percentage (500 = 5%)
     */
    function setRoyaltyInfo(uint96 royaltyPercentage_) public onlyOwner {
        if (origamasksAddress == address(0)) revert ZeroAddress();
        _setDefaultRoyalty(origamasksAddress, royaltyPercentage_);
    }

    /**
     * @dev Set contract royalty info
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721, ERC2981)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @notice Requires that msg.sender owns or is approved for the token.
     */
    modifier onlyApprovedOrOwner(uint256 tokenId_) {
        require(
            // _ownershipOf(tokenId_).addr == _msgSender() ||
            ownerOf(tokenId_) == _msgSender() ||
                getApproved(tokenId_) == _msgSender(),
            "ERC721: Not approved nor owner"
        );
        _;
    }

    /**
     * @dev Withdraw of LINK tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /**
     * @dev Withdraw function for owner.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(origamasksAddress).call{
            value: address(this).balance
        }("");
        if (!success) revert TransferFailed();
    }

    /**
     * Useful for testing. Not to use in production.
     */
    function setCollectionSize(uint256 size) external onlyOwner {
        collectionSize = size;
    }
}