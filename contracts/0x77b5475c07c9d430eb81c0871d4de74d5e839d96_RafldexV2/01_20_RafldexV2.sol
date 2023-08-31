// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RafldexV2 is
    Ownable,
    ReentrancyGuard,
    VRFConsumerBaseV2,
    ERC721Holder,
    ERC1155Holder
{
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    address constant vrfCoordinator =
        0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    address constant link_token_contract =
        0x514910771AF9Ca656af840dff83E8264EcF986CA;
    bytes32 private keyHash =
        0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    uint16 private requestConfirmations = 3;
    uint32 private callbackGasLimit = 2500000;
    uint32 private numWords = 1;
    uint64 private subscriptionId = 810;

    struct RandomResult {
        uint256 randomNumber;
        uint256 nomalizedRandomNumber;
    }
    struct RaffleInfo {
        uint256 id;
        uint256 size;
    }

    mapping(uint256 => RandomResult) public requests;
    mapping(uint256 => RaffleInfo) public chainlinkRaffleInfo;

    event GotSubscription(address _address);
    event CollectionWhitelisted(address _collection, uint256 _rafflesnumber);
    event UserBlacklisted(address _address);
    event AddedTokenPayment(address _address);
    event RequestFulfilled(
        uint256 requestId,
        uint256 randomNumber,
        uint256 indexed raffleId
    );
    event RequestSent(uint256 requestId, uint32 numWords);
    event RaffleCreated(
        uint256 indexed raffleId,
        address[] nftAddress,
        uint256[] nftId
    );
    event RaffleDrawn(
        uint256 indexed raffleId,
        address indexed winner,
        uint256 amountRaised,
        uint256 randomNumber
    );
    event EntryBought(
        uint256 indexed raffleId,
        address indexed buyer,
        uint256 currentSize,
        uint256 numberEntries
    );

    event RaffleSetNotToCancel(uint256 indexed raffleId, address creator);

    event RaffleCancelled(uint256 indexed raffleId, uint256 amountRaised);
    event SetWinnerTriggered(uint256 indexed raffleId, uint256 amountRaised);

    struct EntriesBought {
        address player;
        uint256[] currentEntriesLength;
        uint256 totalEntries;
    }
    mapping(uint256 => EntriesBought[]) public entriesList;

    enum STATUS {
        CREATED,
        PENDING_DRAW,
        DRAWING,
        DRAWN,
        CANCELLED
    }

    struct RaffleStruct {
        STATUS status;
        uint256 endTime;
        address[] collateralAddress;
        uint256[] collateralId;
        uint256[] tokenAmount;
        uint256 entriesSupply;
        uint256 pricePerEntry;
        uint256 maxEntriesUser;
        address winner;
        uint256 randomNumber;
        uint256 amountRaised;
        address creator;
        uint256 platformPercentage;
        address tokenPayment;
        uint256 entriesSold;
        bool canCancel;
    }

    RaffleStruct[] public raffles;

    struct RaffleCreationHolder {
        uint256 startTime;
        uint256 endTime;
        uint256 countRaffles;
    }

    mapping(bytes32 => RaffleCreationHolder) public raffleCreationData;
    mapping(address => uint256) public numberRafflesMonthCollection;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    address payable private platformWallet =
        payable(0x2300Ae69d7D1Ea0457aD79e822422888e3Ee3e87);

    uint256 public CHAINLINK_RAFFLE_FEE = 0.015 ether;
    uint256 public HOLDER_CREATE_RAFFLE_FEE = 0.02 ether;
    uint256 public HOLDER_CREATE_RAFFLE_FEE_DISCOUNT = 0.01 ether;
    uint256 public CANCELATION_RAFFLE_FEE_BASE = 0.03 ether;
    uint256 public SUBSCRIPTION_PRICE = 0.5 ether;
    uint256 public COMMISSION_HOLDERS = 500; //5 %
    uint256 public COMMISSION_HOLDERS_DISCOUNT = 350; //3.5%
    uint256 public COMMISSION_SUBSCRIBERS = 300; //3%
    uint256 public COMMISSION_SUBSCRIBERS_DISCOUNT = 150; //1.5%

    mapping(address => bool) public Subscribers;
    mapping(address => bool) public BlacklistAddresses;
    mapping(address => bool) public TokenPaymentAddresses;
    mapping(address => bool) public DiscountTokenPayments;

    bool public createEnabledHolders = false;
    bool public createEnabledSubscribers = false;

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }
    mapping(bytes32 => RoleData) private _roles;

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyRole(bytes32 role, address account) {
        _checkRole(role, account);
        _;
    }

    function createRaffleOperator(
        uint256 _endTime,
        address[] memory _collateralAddress,
        uint256[] memory _collateralId,
        uint256[] memory _tokenAmount,
        address _tokenPayment,
        uint256 _pricePerEntry,
        uint256 _maxEntriesRaffle,
        uint256 _maxEntriesUser
    ) external onlyRole(OPERATOR_ROLE, msg.sender) returns (uint256) {
        require(
            !BlacklistAddresses[msg.sender],
            "User blacklisted can't create raffles."
        );
        require(
            _endTime > getCurrentTime(),
            "End time can't be < as current time."
        );
        require(
            _collateralAddress.length == _collateralId.length,
            "Address, IDs need to have same length."
        );
        require(
            _collateralAddress.length == _tokenAmount.length,
            "Address, Token Amounts need to have same length."
        );
        require(_maxEntriesRaffle > 0, "No entries");
        require(
            _maxEntriesUser > 0 && _maxEntriesUser <= _maxEntriesRaffle,
            "Min entries user > 0 and <= max entries raffle"
        );

        if (_tokenPayment != address(0)) {
            require(
                TokenPaymentAddresses[_tokenPayment],
                "Token Address not added "
            );
        }

        for (uint256 i = 0; i < _collateralAddress.length; i++) {
            require(_collateralAddress[i] != address(0), "NFT is null");
            if (_tokenAmount[i] == 0) {
                IERC721 nftContract = IERC721(_collateralAddress[i]);
                require(
                    msg.sender == nftContract.ownerOf(_collateralId[i]),
                    "Only NFT owner can create raffle"
                );
            } else {
                IERC1155 nftContract = IERC1155(_collateralAddress[i]);
                require(
                    nftContract.balanceOf(msg.sender, _collateralId[i]) >=
                        _tokenAmount[i],
                    "Dont have enough amount."
                );
            }
        }
        uint256 _commissionInBasicPoints = 0;

        safeMultipleTransfersFrom(
            msg.sender,
            address(this),
            _collateralAddress,
            _collateralId,
            _tokenAmount
        );

        RaffleStruct memory raffle = RaffleStruct({
            status: STATUS.CREATED,
            endTime: _endTime,
            collateralAddress: _collateralAddress,
            collateralId: _collateralId,
            tokenAmount: _tokenAmount,
            pricePerEntry: _pricePerEntry,
            entriesSupply: _maxEntriesRaffle,
            maxEntriesUser: _maxEntriesUser,
            winner: address(0),
            randomNumber: 0,
            amountRaised: 0,
            creator: msg.sender,
            platformPercentage: _commissionInBasicPoints,
            tokenPayment: _tokenPayment,
            entriesSold: 0,
            canCancel: true
        });

        raffles.push(raffle);

        uint256 idRaffle = raffles.length - 1;

        EntriesBought memory entryBought = EntriesBought({
            player: address(0),
            currentEntriesLength: new uint256[](1),
            totalEntries: 0
        });
        entriesList[idRaffle].push(entryBought);

        delete entriesList[idRaffle][0];

        emit RaffleCreated(idRaffle, _collateralAddress, _collateralId);
        return idRaffle;
    }

    function createRaffleHolder(
        address createRaffleCollection,
        uint256 createRaffleTokenId,
        uint256 _endTime,
        address[] memory _collateralAddress,
        uint256[] memory _collateralId,
        uint256[] memory _tokenAmount,
        address _tokenPayment,
        uint256 _pricePerEntry,
        uint256 _maxEntriesRaffle,
        uint256 _maxEntriesUser
    ) external payable returns (uint256) {
        require(createEnabledHolders, "Create raffle not set for holders.");

        require(
            !BlacklistAddresses[msg.sender],
            "User blacklisted can't create raffles."
        );
        require(
            _endTime > getCurrentTime(),
            "End time can't be < as current time."
        );
        require(
            _collateralAddress.length == _collateralId.length,
            "Address, IDs & Token Amount need to have same length."
        );
        require(
            _collateralAddress.length == _tokenAmount.length,
            "Address, Token Amounts need to have same length."
        );

        require(_maxEntriesRaffle > 0, "No entries");
        require(
            _maxEntriesUser > 0 && _maxEntriesUser <= _maxEntriesRaffle,
            "Min entries user > 0 and <= max entries raffle"
        );
        if (_tokenPayment != address(0)) {
            require(
                TokenPaymentAddresses[_tokenPayment],
                "Token Address not added "
            );
        }

        for (uint256 i = 0; i < _collateralAddress.length; i++) {
            require(_collateralAddress[i] != address(0), "NFT is null");
            if (_tokenAmount[i] == 0) {
                IERC721 nftContract = IERC721(_collateralAddress[i]);
                require(
                    msg.sender == nftContract.ownerOf(_collateralId[i]),
                    "Only NFT owner can create raffle"
                );
            } else {
                IERC1155 nftContract = IERC1155(_collateralAddress[i]);
                require(
                    nftContract.balanceOf(msg.sender, _collateralId[i]) >=
                        _tokenAmount[i],
                    "Dont have enough amount."
                );
            }
        }

        uint256 _commissionInBasicPoints = 0;
        if (DiscountTokenPayments[_tokenPayment]) {
            require(
                msg.value >=
                    HOLDER_CREATE_RAFFLE_FEE_DISCOUNT + CHAINLINK_RAFFLE_FEE,
                "Invalid funds provided"
            );

            _commissionInBasicPoints = COMMISSION_HOLDERS_DISCOUNT;
        } else {
            require(
                msg.value >= HOLDER_CREATE_RAFFLE_FEE + CHAINLINK_RAFFLE_FEE,
                "Invalid funds provided"
            );
            _commissionInBasicPoints = COMMISSION_HOLDERS;
        }

        IERC721 createraffleNFT = IERC721(createRaffleCollection);
        require(
            createraffleNFT.ownerOf(createRaffleTokenId) == msg.sender,
            "Not the owner of tokenId"
        );

        bytes32 hash = keccak256(
            abi.encode(createRaffleCollection, createRaffleTokenId)
        );

        if (raffleCreationData[hash].endTime > getCurrentTime()) {
            require(
                numberRafflesRemainingPerNFT(
                    createRaffleCollection,
                    createRaffleTokenId
                ) > 0,
                "Created too many raffles with your NFT you hold."
            );
            raffleCreationData[hash].countRaffles++;
        } else {
            raffleCreationData[hash].startTime = getCurrentTime();
            raffleCreationData[hash].endTime = getCurrentTime() + 30 days;
            raffleCreationData[hash].countRaffles = 1;
        }

        safeMultipleTransfersFrom(
            msg.sender,
            address(this),
            _collateralAddress,
            _collateralId,
            _tokenAmount
        );

        platformWallet.transfer(msg.value);

        RaffleStruct memory raffle = RaffleStruct({
            status: STATUS.CREATED,
            endTime: _endTime,
            collateralAddress: _collateralAddress,
            collateralId: _collateralId,
            tokenAmount: _tokenAmount,
            pricePerEntry: _pricePerEntry,
            entriesSupply: _maxEntriesRaffle,
            maxEntriesUser: _maxEntriesUser,
            winner: address(0),
            randomNumber: 0,
            amountRaised: 0,
            creator: msg.sender,
            platformPercentage: _commissionInBasicPoints,
            tokenPayment: _tokenPayment,
            entriesSold: 0,
            canCancel: true
        });

        raffles.push(raffle);

        uint256 idRaffle = raffles.length - 1;

        EntriesBought memory entryBought = EntriesBought({
            player: address(0),
            currentEntriesLength: new uint256[](1),
            totalEntries: 0
        });
        entriesList[idRaffle].push(entryBought);
        delete entriesList[idRaffle][0];

        emit RaffleCreated(idRaffle, _collateralAddress, _collateralId);

        return idRaffle;
    }

    function createRaffleSubscriber(
        uint256 _endTime,
        address[] memory _collateralAddress,
        uint256[] memory _collateralId,
        uint256[] memory _tokenAmount,
        address _tokenPayment,
        uint256 _pricePerEntry,
        uint256 _maxEntriesRaffle,
        uint256 _maxEntriesUser
    ) external payable returns (uint256) {
        require(
            !BlacklistAddresses[msg.sender],
            "User blacklisted can't create raffles."
        );
        require(
            createEnabledSubscribers,
            "Create raffle noot set for subscribers."
        );
        require(
            Subscribers[msg.sender],
            "Need to be subscriber to create raffle."
        );
        require(
            _endTime > getCurrentTime(),
            "End time can't be < as current time."
        );
        require(
            _collateralAddress.length == _collateralId.length,
            "Address, IDs & Token Amount need to have same length."
        );
        require(
            _collateralAddress.length == _tokenAmount.length,
            "Address, Token Amounts need to have same length."
        );
        require(msg.value >= CHAINLINK_RAFFLE_FEE, "Invalid funds provided");

        require(_maxEntriesRaffle > 0, "No entries");
        require(
            _maxEntriesUser > 0 && _maxEntriesUser <= _maxEntriesRaffle,
            "Min entries user > 0 and <= max entries raffle"
        );

        if (_tokenPayment != address(0)) {
            require(
                TokenPaymentAddresses[_tokenPayment],
                "Token Address not added "
            );
        }
        for (uint256 i = 0; i < _collateralAddress.length; i++) {
            require(_collateralAddress[i] != address(0), "NFT is null");
            if (_tokenAmount[i] == 0) {
                IERC721 nftContract = IERC721(_collateralAddress[i]);
                require(
                    msg.sender == nftContract.ownerOf(_collateralId[i]),
                    "Only NFT owner can create raffle"
                );
            } else {
                IERC1155 nftContract = IERC1155(_collateralAddress[i]);
                require(
                    nftContract.balanceOf(msg.sender, _collateralId[i]) >=
                        _tokenAmount[i],
                    "Dont have enough amount."
                );
            }
        }
        uint256 _commissionInBasicPoints = 0;

        if (DiscountTokenPayments[_tokenPayment]) {
            _commissionInBasicPoints = COMMISSION_SUBSCRIBERS_DISCOUNT;
        } else {
            _commissionInBasicPoints = COMMISSION_SUBSCRIBERS;
        }

        safeMultipleTransfersFrom(
            msg.sender,
            address(this),
            _collateralAddress,
            _collateralId,
            _tokenAmount
        );

        RaffleStruct memory raffle = RaffleStruct({
            status: STATUS.CREATED,
            endTime: _endTime,
            collateralAddress: _collateralAddress,
            collateralId: _collateralId,
            tokenAmount: _tokenAmount,
            pricePerEntry: _pricePerEntry,
            entriesSupply: _maxEntriesRaffle,
            maxEntriesUser: _maxEntriesUser,
            winner: address(0),
            randomNumber: 0,
            amountRaised: 0,
            creator: msg.sender,
            platformPercentage: _commissionInBasicPoints,
            tokenPayment: _tokenPayment,
            entriesSold: 0,
            canCancel: true
        });

        raffles.push(raffle);

        uint256 idRaffle = raffles.length - 1;
        EntriesBought memory entryBought = EntriesBought({
            player: address(0),
            currentEntriesLength: new uint256[](1),
            totalEntries: 0
        });
        entriesList[idRaffle].push(entryBought);
        delete entriesList[idRaffle][0];
        emit RaffleCreated(idRaffle, _collateralAddress, _collateralId);

        return idRaffle;
    }

    function buyEntry(uint256 _raffleId, uint256 _numberEntries)
        external
        payable
    {
        RaffleStruct storage raffle = raffles[_raffleId];

        require(raffle.endTime > getCurrentTime(), "Raffle Closed on time");
        require(raffle.status == STATUS.CREATED, "Raffle is not in CREATED");
        require(_numberEntries > 0, "Number entries can't be 0");
        require(msg.sender != address(0), "Address cant't be null address");
        require(
            raffle.entriesSold + _numberEntries <=
                raffles[_raffleId].entriesSupply,
            "Raffle has reached max entries"
        );

        if (raffle.tokenPayment == address(0)) {
            require(
                msg.value == raffle.pricePerEntry * _numberEntries,
                "msg.value must be equal to the price"
            );

            raffle.amountRaised += msg.value;
        } else {
            require(
                IERC20(raffle.tokenPayment).balanceOf(msg.sender) >=
                    raffle.pricePerEntry * _numberEntries,
                "Need to have in wallet equal or more than ERC20 Token price"
            );
            IERC20(raffle.tokenPayment).transferFrom(
                msg.sender,
                address(this),
                raffle.pricePerEntry * _numberEntries
            );
            raffle.amountRaised += raffle.pricePerEntry * _numberEntries;
        }

        EntriesBought memory entryBought = EntriesBought({
            player: msg.sender, 
            currentEntriesLength: new uint256[](1), 
            totalEntries: _numberEntries 
        });

        bool bought = false;
        for (uint256 i = 0; i < entriesList[_raffleId].length; i++) {
            if (entriesList[_raffleId][i].player == msg.sender) {
                require(
                    entriesList[_raffleId][i].totalEntries + _numberEntries <=
                        raffles[_raffleId].maxEntriesUser,
                    "Bought too many entries"
                );
                entriesList[_raffleId][i].currentEntriesLength.push(
                    raffle.entriesSold + _numberEntries
                );
                entriesList[_raffleId][i].totalEntries += _numberEntries;
                bought = true;
                break;
            }
        }
        if (!bought) {
            entriesList[_raffleId].push(entryBought);
            uint256 idEntry = entriesList[_raffleId].length - 1;
            entriesList[_raffleId][idEntry].currentEntriesLength[0] =
                raffle.entriesSold +
                _numberEntries;
        }
        raffle.entriesSold += _numberEntries;

        emit EntryBought(
            _raffleId,
            msg.sender,
            raffle.entriesSold,
            _numberEntries
        );
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getSubscription() external payable {
        require(
            msg.value == SUBSCRIPTION_PRICE,
            "msg.value must be equal to the price"
        );
        platformWallet.transfer(msg.value);
        Subscribers[msg.sender] = true;
        emit GotSubscription(msg.sender);
    }

    function giveorRemoveSubscriptionTo(
        address[] memory _addresses,
        bool _isSubscriber
    ) external onlyRole(OPERATOR_ROLE, msg.sender) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            Subscribers[_addresses[i]] = _isSubscriber;
            if (_isSubscriber == true) {
                emit GotSubscription(_addresses[i]);
            }
        }
    }

    function ChangeSubscriptionFee(uint256 _subscriptionfee)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        SUBSCRIPTION_PRICE = _subscriptionfee;
    }

    function ChangeCancellationFeeBase(uint256 _fee)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        CANCELATION_RAFFLE_FEE_BASE = _fee;
    }

    function ChangeSubscriptionId(uint64 _id)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        subscriptionId = _id;
    }

    function ChangecallbackGasLimit(uint32 _number)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        callbackGasLimit = _number;
    }

    function ChangeKeyHash(bytes32 _hash)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        keyHash = _hash;
    }

    function setNumberRafflesCollectionWhitelistedPerMonth(
        address _collection,
        uint256 _rafflesnumber
    ) external onlyRole(OPERATOR_ROLE, msg.sender) {
        numberRafflesMonthCollection[_collection] = _rafflesnumber;
        emit CollectionWhitelisted(_collection, _rafflesnumber);
    }

    function ChangeUserHolderCreateRaffleFee(uint256 _rafflefee)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        HOLDER_CREATE_RAFFLE_FEE = _rafflefee;
    }

    function ChangeUserHolderCreateRaffleFeeDiscount(uint256 _rafflefee)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        HOLDER_CREATE_RAFFLE_FEE_DISCOUNT = _rafflefee;
    }

    function numberRafflesRemainingPerNFT(
        address _collectionaddress,
        uint256 _tokenid
    ) public view returns (uint256) {
        uint256 numberRafflesNFT = 0;
        if (numberRafflesMonthCollection[_collectionaddress] > 0) {
            bytes32 hashNFT = keccak256(
                abi.encode(_collectionaddress, _tokenid)
            );
            numberRafflesNFT =
                numberRafflesMonthCollection[_collectionaddress] -
                raffleCreationData[hashNFT].countRaffles;
        }
        return numberRafflesNFT;
    }

    function changePlatformWalletAddress(address payable _address)
        external
        onlyOwner
    {
        platformWallet = _address;
    }

    function addTokenPayment(address _address, bool _isAdded)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        TokenPaymentAddresses[_address] = _isAdded;
        if (_isAdded == true) {
            emit AddedTokenPayment(_address);
        }
    }

    function addDiscountTokenPayment(address _address, bool _isAdded)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        DiscountTokenPayments[_address] = _isAdded;
    }

    function blacklistAddressOrNot(address _address, bool _isBlacklist)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        BlacklistAddresses[_address] = _isBlacklist;
        if (_isBlacklist == true) {
            emit UserBlacklisted(_address);
        }
    }

    function toggleCreateHoldersEnabled()
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        createEnabledHolders = !createEnabledHolders;
    }

    function toggleCreateSubscribersEnabled()
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        createEnabledSubscribers = !createEnabledSubscribers;
    }

    function getWinnerAddressFromRandom(
        uint256 _raffleId,
        uint256 _normalizedRandomNumber
    ) public view returns (address) {
        uint256 cumulativeSum = 0;
        address winner;
        EntriesBought[] storage entries = entriesList[_raffleId];
        for (uint256 i = 0; i < entries.length; i++) {
            for (
                uint256 j = 0;
                j < entries[i].currentEntriesLength.length;
                j++
            ) {
                cumulativeSum += entries[i].currentEntriesLength[j];
                if (cumulativeSum >= _normalizedRandomNumber) {
                    winner = entries[i].player;
                    break;
                }
            }
        }
        require(winner != address(0), "Winner not found");
        return winner;
    }

    function safeMultipleTransfersFrom(
        address from,
        address to,
        address[] memory nftAddresses,
        uint256[] memory nftIds,
        uint256[] memory nftAmounts
    ) internal virtual {
        for (uint256 i = 0; i < nftIds.length; i++) {
            safeTransferFrom(
                from,
                to,
                nftAddresses[i],
                nftIds[i],
                nftAmounts[i],
                ""
            );
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        address tokenAddress,
        uint256 tokenId,
        uint256 tokenAmount,
        bytes memory _data
    ) internal virtual {
        if (tokenAmount == 0) {
            IERC721(tokenAddress).safeTransferFrom(from, to, tokenId, _data);
        } else {
            IERC1155(tokenAddress).safeTransferFrom(
                from,
                to,
                tokenId,
                tokenAmount,
                _data
            );
        }
    }

    function requestRandomWords(uint256 _id, uint256 _entriesSold)
        internal
        returns (uint256 requestId)
    {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        chainlinkRaffleInfo[requestId] = RaffleInfo({
            id: _id,
            size: _entriesSold
        });
        RaffleStruct storage raffle = raffles[_id];
        raffle.status = STATUS.DRAWING;

        emit RequestSent(requestId, numWords);

        return requestId;
    }

    function requestRandomWordsRetry(uint256 _id)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
        returns (uint256 requestId)
    {
        RaffleStruct storage raffle = raffles[_id];

        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        chainlinkRaffleInfo[requestId] = RaffleInfo({
            id: _id,
            size: raffle.entriesSold
        });
        raffle.status = STATUS.DRAWING;

        emit RequestSent(requestId, numWords);

        return requestId;
    }

    function transferNFTsAndFunds(
        uint256 _raffleId,
        uint256 _normalizedRandomNumber
    ) internal nonReentrant {
        RaffleStruct storage raffle = raffles[_raffleId];
        require(raffle.status == STATUS.DRAWING, "Raffle in wrong status");
        raffle.randomNumber = _normalizedRandomNumber;
        raffle.winner = (raffle.entriesSold == 0)
            ? raffle.creator
            : getWinnerAddressFromRandom(_raffleId, _normalizedRandomNumber);

        safeMultipleTransfersFrom(
            address(this),
            raffle.winner,
            raffle.collateralAddress,
            raffle.collateralId,
            raffle.tokenAmount
        );

        uint256 amountForPlatform = (raffle.amountRaised *
            raffle.platformPercentage) / 10000;
        uint256 amountForSeller = raffle.amountRaised - amountForPlatform;

        if (raffle.tokenPayment == address(0)) {
            (bool sent, ) = raffle.creator.call{value: amountForSeller}("");
            require(sent, "Failed to send Eth");

            (bool sent2, ) = platformWallet.call{value: amountForPlatform}("");
            require(sent2, "Failed send Eth to Platform");
        } else {
            IERC20(raffle.tokenPayment).approve(
                address(this),
                raffle.amountRaised
            );
            bool sent = IERC20(raffle.tokenPayment).transferFrom(
                address(this),
                raffle.creator,
                amountForSeller
            );
            require(sent, "Failed to send ERC20 Token");
            bool sent2 = IERC20(raffle.tokenPayment).transferFrom(
                address(this),
                platformWallet,
                amountForPlatform
            );
            require(sent2, "Failed to send ERC20 Token to platform");
        }
        raffle.status = STATUS.DRAWN;

        emit RaffleDrawn(
            _raffleId,
            raffle.winner,
            raffle.amountRaised,
            raffle.randomNumber
        );
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 normalizedRandomNumber = (_randomWords[0] %
            chainlinkRaffleInfo[_requestId].size) + 1;
        RaffleStruct storage raffle = raffles[
            chainlinkRaffleInfo[_requestId].id
        ];

        raffle.randomNumber = normalizedRandomNumber;

        RandomResult memory result = RandomResult({
            randomNumber: _randomWords[0],
            nomalizedRandomNumber: normalizedRandomNumber
        });

        requests[chainlinkRaffleInfo[_requestId].id] = result;

        emit RequestFulfilled(
            _requestId,
            normalizedRandomNumber,
            chainlinkRaffleInfo[_requestId].id
        );
        transferNFTsAndFunds(
            chainlinkRaffleInfo[_requestId].id,
            normalizedRandomNumber
        );
    }

    function setWinnerRaffle(uint256 _raffleId) external {
        RaffleStruct storage raffle = raffles[_raffleId];
        require(
            raffle.creator == msg.sender || hasRole(OPERATOR_ROLE, msg.sender),
            "Not raffle creator or Operator."
        );
        if (msg.sender != raffle.creator) {
            require(
                raffle.endTime <= getCurrentTime() ||
                    raffle.entriesSold == raffle.entriesSupply,
                "Raffle still opened or not sold out"
            );
        }

        require(raffle.status == STATUS.CREATED, "Raffle in wrong status");
        raffle.status = STATUS.PENDING_DRAW;
        uint256 entriesSold = raffle.entriesSold;
        if (entriesSold > 0) {
            requestRandomWords(_raffleId, entriesSold);
        } else {
            raffle.status = STATUS.DRAWING;
            transferNFTsAndFunds(_raffleId, raffle.randomNumber);
        }

        emit SetWinnerTriggered(_raffleId, raffle.amountRaised);
    }

    function setRaffleToNotCancel(uint256 _raffleId) external nonReentrant {
        RaffleStruct storage raffle = raffles[_raffleId];
        require(raffle.creator == msg.sender, "Not raffle creator.");
        if (raffle.canCancel == true) {
            raffle.canCancel = false;
            emit RaffleSetNotToCancel(_raffleId, msg.sender);
        }
    }

    function usersLengthRaffle(uint256 _raffleId)
        public
        view
        returns (uint256)
    {
        return entriesList[_raffleId].length;
    }

    function cancelRaffle(uint256 _raffleId) external payable nonReentrant {
        RaffleStruct storage raffle = raffles[_raffleId];
        require(
            raffle.creator == msg.sender || hasRole(OPERATOR_ROLE, msg.sender),
            "Not raffle creator or Operator."
        );
        require(
            raffle.endTime > getCurrentTime(),
            "End time can't be < as current time."
        );
        require(raffle.status == STATUS.CREATED, "Wrong status");

        if (!hasRole(OPERATOR_ROLE, msg.sender)) {
            require(raffle.canCancel, "User Can't cancel");
            if (raffle.entriesSold == 0) {
                require(msg.value == 0, "Not cancelation fee value.");
            } else {
                require(
                    msg.value >= CANCELATION_RAFFLE_FEE_BASE,
                    "Not cancelation fee value."
                );
                platformWallet.transfer(CANCELATION_RAFFLE_FEE_BASE);
            }
        }

        uint256 usersLength = entriesList[_raffleId].length;
        require(
            usersLength <= 200,
            "Not cancelation available when it's more than 200 users."
        );

        if (raffle.tokenPayment == address(0)) {
            for (uint256 i = 0; i < usersLength; i++) {
                address user = entriesList[_raffleId][i].player;
                if (user != address(0)) {
                    uint256 amountToSend = raffle.pricePerEntry *
                        entriesList[_raffleId][i].totalEntries;
                    payable(user).transfer(amountToSend);
                }
            }
        } else {
            IERC20(raffle.tokenPayment).approve(
                address(this),
                raffle.amountRaised
            );
            for (uint256 i = 0; i < usersLength; i++) {
                address user = entriesList[_raffleId][i].player;
                if (user != address(0)) {
                    uint256 amountToSend = raffle.pricePerEntry *
                        entriesList[_raffleId][i].totalEntries;
                    IERC20(raffle.tokenPayment).transferFrom(
                        address(this),
                        user,
                        amountToSend
                    );
                }
            }
        }

        safeMultipleTransfersFrom(
            address(this),
            raffle.creator,
            raffle.collateralAddress,
            raffle.collateralId,
            raffle.tokenAmount
        );

        raffle.status = STATUS.CANCELLED;

        emit RaffleCancelled(_raffleId, raffle.amountRaised);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        _revokeRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
        }
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
        }
    }
}