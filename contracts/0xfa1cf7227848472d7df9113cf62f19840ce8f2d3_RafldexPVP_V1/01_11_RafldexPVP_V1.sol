// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RafldexPVP_V1 is Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
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

    event TokenAdded(address _address);
    event RequestFulfilled(
        uint256 requestId,
        uint256 randomNumber,
        uint256 indexed raffleId
    );
    event RequestSent(uint256 requestId, uint32 numWords);
    event RaffleCreated(
        uint256 indexed raffleId,
        address coinAddress,
        uint256 amount
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

    event RaffleCancelled(uint256 indexed raffleId, uint256 amountRaised);
    event SetWinnerTriggered(uint256 indexed raffleId, uint256 amountRaised);

    struct EntriesBought {
        address player;
        uint256 currentEntriesLength;
        uint256 entries;
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
        address collateralAddress;
        uint256 collateralAmount;
        address tokenPayment;
        uint256 entriesSupply;
        uint256 pricePerEntry;
        address winner;
        uint256 randomNumber;
        uint256 maxEntriesUser;
        address creator;
        uint256 platformPercentage;
        uint256 entriesSold;
    }

    RaffleStruct[] public raffles;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    address payable private platformWallet =
        payable(0x2300Ae69d7D1Ea0457aD79e822422888e3Ee3e87);

    uint256 public COMMISSION = 1000; //10%

    mapping(address => bool) public TokenAddresses; //token addresses that can be in raffle
    mapping(address => uint256) public minimumAmountToken; //minimum amount depending in token

    bool public createEnabled = true;

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
        minimumAmountToken[address(0)] = 30000000000000000; //0.03 eth ~ 50$
    }

    modifier onlyRole(bytes32 role, address account) {
        _checkRole(role, account);
        _;
    }

    function createRaffle(address _collateralAddress, uint256 _collateralAmount)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        require(createEnabled, "Create raffle not enabled.");
        uint256 totalEth;
        require(
            _collateralAmount > 0 &&
                _collateralAmount >= minimumAmountToken[_collateralAddress],
            "Amount can't be null / minimum amount"
        );
        if (_collateralAddress == address(0)) {
            totalEth += _collateralAmount;
        } else {
            require(
                TokenAddresses[_collateralAddress],
                "Token Address not added "
            );
            safeTransferFrom(
                msg.sender,
                address(this),
                _collateralAddress,
                _collateralAmount
            );
        }
        require(msg.value >= totalEth, "Total mismatched");

        uint256 _commissionInBasicPoints;
        if (hasRole(OPERATOR_ROLE, msg.sender)) {
            _commissionInBasicPoints = 0;
        } else {
            _commissionInBasicPoints = COMMISSION;
        }

        uint256 _numberEntries = 1;

        RaffleStruct memory raffle = RaffleStruct({
            status: STATUS.CREATED,
            collateralAddress: _collateralAddress,
            collateralAmount: _collateralAmount,
            tokenPayment: _collateralAddress,
            pricePerEntry: _collateralAmount,
            entriesSupply: 2,
            maxEntriesUser: 1,
            winner: address(0),
            randomNumber: 0,
            creator: msg.sender,
            platformPercentage: _commissionInBasicPoints,
            entriesSold: _numberEntries
        });

        raffles.push(raffle);
        uint256 idRaffle = raffles.length - 1;
        emit RaffleCreated(idRaffle, _collateralAddress, _collateralAmount);

        EntriesBought memory entryBought = EntriesBought({
            player: address(0),
            currentEntriesLength: 0,
            entries: 0
        });
        entriesList[idRaffle].push(entryBought);
        delete entriesList[idRaffle][0];

        EntriesBought memory entryBoughtCreator = EntriesBought({
            player: msg.sender,
            currentEntriesLength: _numberEntries,
            entries: _numberEntries
        });
        entriesList[idRaffle].push(entryBoughtCreator);

        emit EntryBought(idRaffle, msg.sender, _numberEntries, _numberEntries);

        return idRaffle;
    }

    function buyEntry(uint256 _raffleId) external nonReentrant payable {
        uint256 _numberEntries = 1;
        RaffleStruct storage raffle = raffles[_raffleId];
        require(raffle.status == STATUS.CREATED, "Raffle is not in CREATED");
        require(msg.sender != raffle.creator, "Buyer can't be raffle creator.");

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
        } else {
            IERC20(raffle.tokenPayment).transferFrom(
                msg.sender,
                address(this),
                raffle.pricePerEntry * _numberEntries
            );
        }

        EntriesBought memory entryBought = EntriesBought({
            player: msg.sender,
            currentEntriesLength: uint256(raffle.entriesSold + _numberEntries),
            entries: _numberEntries
        });
        entriesList[_raffleId].push(entryBought);
        raffle.entriesSold += _numberEntries;

        emit EntryBought(
            _raffleId,
            msg.sender,
            raffle.entriesSold,
            _numberEntries
        );
    }

    function addorRemoveTokens(address[] memory _addresses, bool _isAdded)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            TokenAddresses[_addresses[i]] = _isAdded;
            if (_isAdded == true) {
                emit TokenAdded(_addresses[i]);
            }
        }
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

    function changePlatformWalletAddress(address payable _address)
        external
        onlyOwner
    {
        platformWallet = _address;
    }

    function getEntriesBought(uint256 _raffleId)
        public
        view
        returns (EntriesBought[] memory)
    {
        return entriesList[_raffleId];
    }

    function toggleCreateRaffles()
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        createEnabled = !createEnabled;
    }

    function setMinimumAmountTokenRaffle(address _token, uint256 _amount)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        minimumAmountToken[_token] = _amount;
    }

    function getWinnerAddressFromRandom(
        uint256 _raffleId,
        uint256 _normalizedRandomNumber
    ) public view returns (address) {
        address winner;
        EntriesBought[] storage entries = entriesList[_raffleId];
        for (uint256 i = 0; i < entries.length; i++) {
            uint256 entriesIndex = entries[i].currentEntriesLength;
            if (entriesIndex >= _normalizedRandomNumber) {
                winner = entries[i].player;
                break;
            }
        }
        require(winner != address(0), "Winner not found");
        return winner;
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
        raffle.randomNumber = _normalizedRandomNumber;
        raffle.winner = getWinnerAddressFromRandom(
            _raffleId,
            _normalizedRandomNumber
        );

        uint256 amountBet = raffle.collateralAmount;
        uint256 amountForPlatform = ((amountBet * 2) *
            raffle.platformPercentage) / 10000;
        uint256 amountForWinner = (amountBet * 2) - amountForPlatform;

        if (raffle.tokenPayment == address(0)) {
            (bool sent, ) = raffle.winner.call{value: amountForWinner}("");
            require(sent, "Failed to send Eth");

            (bool sent2, ) = platformWallet.call{value: amountForPlatform}("");
            require(sent2, "Failed send Eth to Platform");
        } else {
            IERC20(raffle.tokenPayment).approve(address(this), amountBet * 2);
            bool sent = IERC20(raffle.tokenPayment).transferFrom(
                address(this),
                raffle.winner,
                amountForWinner
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
            amountBet * 2,
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

    function setWinnerRaffle(uint256 _raffleId)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
        nonReentrant
    {
        RaffleStruct storage raffle = raffles[_raffleId];
        require(raffle.status == STATUS.CREATED, "Raffle in wrong status");
        require(
            raffle.entriesSold == raffle.entriesSupply,
            "Raffle still not sold out"
        );
        raffle.status = STATUS.PENDING_DRAW;
        uint256 entriesSold = raffle.entriesSold;
        uint256 amountRaised = raffle.collateralAmount * 2;
        requestRandomWords(_raffleId, entriesSold);
        emit SetWinnerTriggered(_raffleId, amountRaised);
    }

    function setWinnerRaffleEmergency(uint256 _raffleId)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        //function in case that chainlink vrf2 doesnt work
        RaffleStruct storage raffle = raffles[_raffleId];
        require(
            raffle.entriesSold == raffle.entriesSupply,
            "Raffle still opened or not sold out"
        );

        uint256 entriesSold = raffle.entriesSold;

        bytes32 baseHash = keccak256(
            abi.encodePacked(
                block.number,
                block.timestamp,
                block.gaslimit,
                block.coinbase
            )
        );
        uint256 normalizedRandomNumber = (uint256(baseHash) % entriesSold) + 1;

        raffle.randomNumber = normalizedRandomNumber;
        transferNFTsAndFunds(_raffleId, normalizedRandomNumber);
        uint256 amountRaised = raffle.collateralAmount * 2;
        emit SetWinnerTriggered(_raffleId, amountRaised);
    }

    function cancelRaffle(uint256 _raffleId) external payable nonReentrant {
        RaffleStruct storage raffle = raffles[_raffleId];

        require(
            raffle.creator == msg.sender || hasRole(OPERATOR_ROLE, msg.sender),
            "Not raffle creator or Operator."
        );
        require(raffle.status == STATUS.CREATED, "Wrong status");
 require(
            raffle.entriesSold < raffle.entriesSupply,
            "Raffle has sold out"
        );
        uint256 amountBet = raffle.collateralAmount;
        uint256 txLength = entriesList[_raffleId].length;

        if (raffle.tokenPayment == address(0)) {
            for (uint256 i = 0; i < txLength; i++) {
                address user = entriesList[_raffleId][i].player;
                if (user != address(0)) {
                    payable(user).transfer(amountBet);
                }
            }
        } else {
            IERC20(raffle.tokenPayment).approve(address(this), amountBet * 2);
            for (uint256 i = 0; i < txLength; i++) {
                address user = entriesList[_raffleId][i].player;
                if (user != address(0)) {
                    IERC20(raffle.tokenPayment).transferFrom(
                        address(this),
                        user,
                        amountBet
                    );
                }
            }
        }

        raffle.status = STATUS.CANCELLED;
        emit RaffleCancelled(_raffleId, amountBet);
    }

    function ChangeCommissionPlatform(uint256 _fee)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        COMMISSION = _fee;
    }

    function cancelRaffleEmergency(uint256 _raffleId)
        external
        onlyRole(OPERATOR_ROLE, msg.sender)
    {
        RaffleStruct storage raffle = raffles[_raffleId];
        uint256 amountBet = raffle.collateralAmount;

        uint256 txLength = entriesList[_raffleId].length;
        if (raffle.tokenPayment == address(0)) {
            for (uint256 i = 0; i < txLength; i++) {
                address user = entriesList[_raffleId][i].player;
                if (user != address(0)) {
                    payable(user).transfer(amountBet);
                }
            }
        } else {
            IERC20(raffle.tokenPayment).approve(address(this), amountBet * 2);
            for (uint256 i = 0; i < txLength; i++) {
                address user = entriesList[_raffleId][i].player;
                if (user != address(0)) {
                    IERC20(raffle.tokenPayment).transferFrom(
                        address(this),
                        user,
                        amountBet
                    );
                }
            }
        }

        raffle.status = STATUS.CANCELLED;
        emit RaffleCancelled(_raffleId, amountBet);
    }

    function safeTransferFrom(
        address from,
        address to,
        address tokenAddress,
        uint256 tokenAmount
    ) internal virtual {
        if (tokenAddress == address(0)) {
            payable(to).transfer(tokenAmount);
        } else {
            if (from == address(this)) {
                IERC20(tokenAddress).approve(address(this), tokenAmount);
            }
            IERC20(tokenAddress).transferFrom(from, to, tokenAmount);
        }
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