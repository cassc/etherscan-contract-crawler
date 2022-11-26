// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./Token.sol";

contract BetGame is Initializable, AccessControl, ReentrancyGuardUpgradeable {
    bool private initialized;
    bytes32 public constant ROLE_RANDOMIZER = keccak256("ROLE_RANDOMIZER");
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");
    uint8 public ODDS_DECIMAL;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ECDSA for bytes32;

    uint256 nextGameId;
    uint8 timestampThreshold;
    address private signerAddress;
    mapping(bytes32 => mapping(address => mapping(address => uint256)))
        private userBalances;
    mapping(bytes32 => mapping(address => mapping(address => bool)))
        private userBalanceMutexes;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(uint256 => mapping(uint16 => EnumerableSet.Bytes32Set))
        private gameBets;
    mapping(uint256 => bool) private usedNonce;
    mapping(bytes32 => Room) private rooms;

    struct Room {
        bytes32 id;
        uint256 _totalOwners;
        mapping(uint32 => address) owners;
        mapping(address => uint32) shares;
        mapping(uint256 => bool) availableGames;
        mapping(address => bool) availableContracts;
        mapping(address => uint256) reverses;
        mapping(address => uint256) lockedReverses;
        mapping(address => bool) roomReverseMutexes;
        EnumerableSet.AddressSet contractAddresses;
        uint256 betLimitPerDay;
        uint256 maxBetPerPlayer;
        uint32 apiPermission;
        uint256 todayBetAmount;
        uint256 lastBettingTime;
        uint256 totalOwnerDeposit;
    }

    struct ClientBet {
        MatchInfo matchInfo;
        uint16 gameType;
        uint32 odds;
        uint16 target;
        address contractAddress;
        address bettorAddress;
        uint256 amount;
    }

    struct Bet {
        address bettor;
        bytes32 roomId;
        uint256 matchId;
        uint256 gameId;
        uint16 gameType;
        uint32 odds;
        uint16 target;
        address contractAddress;
        uint256 amount;
        uint256 potentialWinningAmount;
        uint256 payout;
        uint8 result;
        bool resolved;
    }

    struct MatchInfo {
        bytes32 roomId;
        uint256 gameId;
        uint256 matchId;
    }

    struct SigningBet {
        MatchInfo matchInfo;
        uint16 gameType;
        uint16 target;
        uint32 odds;
        address contractAddress;
        address bettorAddress;
        uint256 amount;
        uint32 timestamp;
        uint32 nonce;
        bytes signature;
    }

    struct RoomOwner {
        address ownerAddress;
        uint32 shares;
    }

    struct BettingAddress {
        address contractAddress;
        address bettorAddress;
    }

    mapping(bytes32 => Bet) public bets;
    mapping(uint16 => bool) private targets;

    /// @notice Emitted when reserves is deposited.
    event ReservesDeposited(
        bytes32 indexed roomId,
        address indexed contractAddress,
        address indexed sender,
        uint256 amount
    );

    /// @notice Emitted when reserves is withdrawn.
    event ReservesWithdrawn(
        bytes32 indexed roomId,
        address indexed contractAddress,
        address sender,
        address indexed recipient,
        uint256 amount
    );

    /// @notice Emmited when user transfer balance to room.
    event TransferToRoom(
        bytes32 indexed roomId,
        address indexed contractAddress,
        address sender,
        uint256 amount
    );

    event BetPlaced(
        MatchInfo indexed matchInfo,
        address indexed sender,
        bytes32 betSlipID,
        uint16 gameType,
        uint16 _target,
        address contractAddress,
        uint256 amount,
        uint32 odds
    );
    event BetResolved(
        bytes32 indexed roomId,
        address indexed sender,
        bytes32 indexed betSlipID,
        uint16 target,
        uint8 result,
        address contractAddress,
        uint256 amount,
        uint256 payout
    );

    function initialize(address _address) public initializer {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
        _setupRole(ROLE_MANAGER, _address);
        signerAddress = _address;
        nextGameId = 1;
        timestampThreshold = 30;
        ODDS_DECIMAL = 4;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PERMISSION_DENIED");
        _;
    }

    modifier onlyOwners(bytes32 roomId) {
        require(
            rooms[roomId].shares[msg.sender] > 0 ||
                hasRole(ROLE_MANAGER, msg.sender),
            "PERMISSION_DENIED"
        );
        _;
    }

    function getNextGameId() private returns (uint256) {
        return nextGameId++;
    }

    function lockRoomReverse(bytes32 roomId, address contractAddress) internal {
        require(
            !rooms[roomId].roomReverseMutexes[contractAddress],
            "FAILED_TO_LOCK_ROOM_REVERSE"
        );
        rooms[roomId].roomReverseMutexes[contractAddress] = true;
    }

    function unlockRoomReverse(bytes32 roomId, address contractAddress)
        internal
    {
        require(
            rooms[roomId].roomReverseMutexes[contractAddress],
            "FAILED_TO_UNLOCK_ROOM_REVERSE"
        );
        rooms[roomId].roomReverseMutexes[contractAddress] = false;
    }

    function createRoom(bytes32 roomId, address mainOwner)
        external
        nonReentrant
        onlyRole(ROLE_MANAGER)
    {
        Room storage room = rooms[roomId];
        require(room.id == 0, "ROOM_ALREADY_EXISTS");
        room.id = roomId;
        room.owners[0] = mainOwner;
        room.shares[mainOwner] = 100;
        room._totalOwners = 1;
        room.betLimitPerDay = 0;
        room.maxBetPerPlayer = 0;
        room.apiPermission = 0;
    }

    function createRoomWithToken(
        bytes32 roomId,
        address mainOwner,
        address contractAddress
    ) external nonReentrant onlyRole(ROLE_MANAGER) {
        Room storage room = rooms[roomId];
        require(room.id == 0, "ROOM_ALREADY_EXISTS");
        require(
            IERC20Upgradeable(contractAddress).totalSupply() > 0,
            "INVALID_TOKEN"
        );
        room.id = roomId;
        room.owners[0] = mainOwner;
        room.shares[mainOwner] = 100;
        room._totalOwners = 1;
        room.betLimitPerDay = 0;
        room.maxBetPerPlayer = 0;
        room.apiPermission = 0;
        rooms[roomId].availableContracts[contractAddress] = true;
        rooms[roomId].contractAddresses.add(contractAddress);
    }

    function addToken(bytes32 roomId, address contractAddress)
        external
        nonReentrant
    {
        require(rooms[roomId].id != 0, "ROOM_NOT_EXISTS");
        require(
            !rooms[roomId].availableContracts[contractAddress],
            "TOKEN_EXISTS"
        );
        require(
            rooms[roomId].shares[msg.sender] > 0 ||
                hasRole(ROLE_MANAGER, msg.sender),
            "PERMISSION_DENIED"
        );
        require(
            IERC20Upgradeable(contractAddress).totalSupply() > 0,
            "INVALID_TOKEN"
        );
        rooms[roomId].availableContracts[contractAddress] = true;
        rooms[roomId].contractAddresses.add(contractAddress);
    }

    /// @notice setting the room limit. Only available to admin.
    function setRoomLimit(
        uint256 betLimitPerDay,
        uint256 maxBetPerPlayer,
        uint32 apiPermission,
        bytes32 roomId
    ) external nonReentrant onlyAdmin {
        require(rooms[roomId].id != 0, "ROOM_NOT_EXISTS");
        rooms[roomId].betLimitPerDay = betLimitPerDay;
        rooms[roomId].maxBetPerPlayer = maxBetPerPlayer;
        rooms[roomId].apiPermission = apiPermission;
    }

    /// @notice Deposit reserves into the room. Only available to room owners.
    /// @param _amount Amount to deposit into the room.
    /// @notice Must approve enough amount for ERC20 transfer before calling this function.
    function depositReserves(
        bytes32 roomId,
        address contractAddress,
        uint256 _amount
    ) external nonReentrant onlyOwners(roomId) {
        require(
            rooms[roomId].availableContracts[contractAddress],
            "TOKEN_NOT_EXISTS"
        );
        require(
            rooms[roomId].reverses[contractAddress] + _amount >
                rooms[roomId].reverses[contractAddress],
            "INVALID_AMOUNT"
        );
        lockRoomReverse(roomId, contractAddress);
        Token.deposit(contractAddress, msg.sender, _amount);
        rooms[roomId].reverses[contractAddress] += _amount;
        rooms[roomId].totalOwnerDeposit += _amount;
        unlockRoomReverse(roomId, contractAddress);
        emit ReservesDeposited(roomId, msg.sender, contractAddress, _amount);
    }

    /// @notice Withdraw from the room. Only available to room owners.
    /// @param _recipient Address of the withdraw recipient.
    /// @param _amount Amount to withdraw.
    function withdrawReserves(
        bytes32 roomId,
        address contractAddress,
        address _recipient,
        uint256 _amount
    ) external nonReentrant onlyOwners(roomId) {
        require(rooms[roomId].lockedReverses[contractAddress] == 0, "LOCKED");
        uint256 roomBalance = roomAvailableReserves(roomId, contractAddress);
        require(roomBalance <= _amount, "INSUFFICIENT_BALANCE");
        require(
            rooms[roomId].reverses[contractAddress] >
                rooms[roomId].reverses[contractAddress] - _amount,
            "INVALID_AMOUNT"
        );
        require(
            roomBalance * rooms[roomId].shares[msg.sender] >= _amount,
            "EXCEED_OWNER_WITHDRAW_LIMIT"
        );
        lockRoomReverse(roomId, contractAddress);
        rooms[roomId].reverses[contractAddress] -= _amount;
        Token.withdrawal(contractAddress, _recipient, _amount);
        unlockRoomReverse(roomId, contractAddress);
        emit ReservesWithdrawn(
            roomId,
            contractAddress,
            msg.sender,
            _recipient,
            _amount
        );
    }

    /// @notice User withdrawal
    /// @param roomId Room Id
    /// @param contractAddress Amount to withdraw.
    function userWithdrawal(
        bytes32 roomId,
        address contractAddress,
        uint256 _amount
    ) external nonReentrant {
        require(
            rooms[roomId].availableContracts[contractAddress],
            "TOKEN_NOT_EXISTS"
        );
        require(
            userBalances[roomId][contractAddress][msg.sender] >= _amount,
            "INSUFFICIENT_BALANCE"
        );
        lockUserBalance(roomId, contractAddress, msg.sender);
        userBalances[roomId][contractAddress][msg.sender] -= _amount;
        Token.withdrawal(contractAddress, msg.sender, _amount);
        unlockUserBalance(roomId, contractAddress, msg.sender);
    }

    /// @notice Get current amount of available reserves.
    function roomAvailableReserves(bytes32 roomId, address contractAddress)
        public
        view
        returns (uint256)
    {
        return
            rooms[roomId].reverses[contractAddress] -
            rooms[roomId].lockedReverses[contractAddress];
    }

    function getUserBalance(
        bytes32 roomId,
        address contractAddress,
        address userAddress
    ) public view returns (uint256) {
        return userBalances[roomId][contractAddress][userAddress];
    }

    function lockUserBalance(
        bytes32 roomId,
        address contractAddress,
        address userAddress
    ) internal {
        require(
            !userBalanceMutexes[roomId][contractAddress][userAddress],
            "FAILED_TO_LOCK_USER_BALANCE"
        );
        userBalanceMutexes[roomId][contractAddress][userAddress] = true;
    }

    function unlockUserBalance(
        bytes32 roomId,
        address contractAddress,
        address userAddress
    ) internal {
        require(
            userBalanceMutexes[roomId][contractAddress][userAddress],
            "FAILED_TO_UNLOCK_USER_BALANCE"
        );
        userBalanceMutexes[roomId][contractAddress][userAddress] = false;
    }

    function checkBetDayLimit(uint256 _amount, bytes32 roomId) internal {
        require(
            rooms[roomId].maxBetPerPlayer >= _amount,
            "EXCEED_BETTING_LIMIT_PER_USER"
        );
        (
            uint256 nowYear,
            uint256 nowMonth,
            uint256 nowDay
        ) = BokkyPooBahsDateTimeLibrary.timestampToDate(block.timestamp);
        (
            uint256 betYear,
            uint256 betMonth,
            uint256 betDay
        ) = BokkyPooBahsDateTimeLibrary.timestampToDate(
                rooms[roomId].lastBettingTime
            );
        if (
            rooms[roomId].lastBettingTime < block.timestamp &&
            (nowYear != betYear && nowMonth != betMonth && nowDay != betDay)
        ) {
            rooms[roomId].todayBetAmount = 0;
        }
        require(
            rooms[roomId].betLimitPerDay >= rooms[roomId].todayBetAmount,
            "EXCEED_ROOM_BETTING_LIMIT_PER_DAY"
        );
    }

    function batchSignedBet(SigningBet[] calldata signingBets)
        external
        nonReentrant
    {
        require(signingBets.length > 0, "INVALID_INPUT_PARAMETERS");
        for (uint256 i = 0; i < signingBets.length; i++) {
            uint32 fullNonce = signingBets[i].timestamp;
            fullNonce = fullNonce & signingBets[i].nonce;
            require(!usedNonce[fullNonce], "NONCE_ALREADY_USED");
            require(
                (signingBets[i].timestamp - timestampThreshold) <=
                    block.timestamp &&
                    (signingBets[i].timestamp + timestampThreshold) >=
                    block.timestamp,
                "INVALID_TIMESTAMP"
            );
            usedNonce[fullNonce] = true;
            bytes32 hash = keccak256(
                abi.encodePacked(
                    signingBets[i].matchInfo.roomId,
                    signingBets[i].matchInfo.gameId,
                    signingBets[i].gameType,
                    signingBets[i].target,
                    signingBets[i].odds,
                    signingBets[i].contractAddress,
                    signingBets[i].amount,
                    signingBets[i].timestamp,
                    signingBets[i].nonce
                )
            );
            require(
                hash.recover(signingBets[i].signature) == signerAddress,
                "INVALID_SIGNATURE"
            );
            bet(
                signingBets[i].matchInfo,
                signingBets[i].gameType,
                signingBets[i].target,
                signingBets[i].odds,
                signingBets[i].contractAddress,
                signingBets[i].bettorAddress,
                signingBets[i].amount
            );
        }
    }

    /// @notice Place a bet on a market.
    /// @param _target Index of the betting target. Index is starting from 1.
    /// @param _amount Amount to bet. Must not over {maxBetAmount} for this target.
    /// @notice Must approve enough amount for ERC20 transfer before calling this function.
    function bet(
        MatchInfo calldata matchInfo,
        uint16 gameType,
        uint16 _target,
        uint32 odds,
        address contractAddress,
        address bettorAddress,
        uint256 _amount
    ) internal {
        require(_amount > 0, "Amount must be nonzero");
        require(
            rooms[matchInfo.roomId].availableContracts[contractAddress],
            "TOKEN_NOT_ALLOWED"
        );
        uint256 potentialWinningAmount = (_amount * odds) / (10**ODDS_DECIMAL);
        require(
            roomAvailableReserves(matchInfo.roomId, contractAddress) >=
                potentialWinningAmount,
            "FAILED_TO_BET"
        );
        require(potentialWinningAmount > _amount, "FAILED_TO_BET_OVERFLOW");
        bytes32 betSlipId = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                bettorAddress,
                block.coinbase,
                block.difficulty,
                getNextGameId()
            )
        );
        Bet storage myBet = bets[betSlipId];
        require(myBet.bettor == address(0), "BET_EXISTS");

        checkBetDayLimit(_amount, matchInfo.roomId);

        lockUserBalance(matchInfo.roomId, contractAddress, bettorAddress);
        uint256 transferAmount = _amount;
        if (
            userBalances[matchInfo.roomId][contractAddress][bettorAddress] >=
            transferAmount
        ) {
            userBalances[matchInfo.roomId][contractAddress][
                bettorAddress
            ] -= transferAmount;
            transferAmount = 0;
        } else if (
            userBalances[matchInfo.roomId][contractAddress][bettorAddress] > 0
        ) {
            transferAmount -= userBalances[matchInfo.roomId][contractAddress][
                bettorAddress
            ];
            userBalances[matchInfo.roomId][contractAddress][bettorAddress] = 0;
        }
        unlockUserBalance(matchInfo.roomId, contractAddress, bettorAddress);
        if (transferAmount > 0) {
            Token.deposit(contractAddress, bettorAddress, transferAmount);
            emit TransferToRoom(
                matchInfo.roomId,
                contractAddress,
                bettorAddress,
                transferAmount
            );
        }

        myBet.bettor = bettorAddress;
        myBet.roomId = matchInfo.roomId;
        myBet.matchId = matchInfo.matchId;
        myBet.gameId = matchInfo.gameId;
        myBet.gameType = gameType;
        myBet.odds = odds;
        myBet.target = _target;
        myBet.contractAddress = contractAddress;
        myBet.amount = _amount;
        myBet.potentialWinningAmount = potentialWinningAmount;

        lockRoomReverse(matchInfo.roomId, contractAddress);
        rooms[matchInfo.roomId].lockedReverses[
            contractAddress
        ] += potentialWinningAmount;
        rooms[myBet.roomId].reverses[myBet.contractAddress] += _amount;
        rooms[matchInfo.roomId].lastBettingTime = block.timestamp;
        unlockRoomReverse(matchInfo.roomId, contractAddress);
        gameBets[matchInfo.matchId][gameType].add(betSlipId);

        emit BetPlaced(
            matchInfo,
            bettorAddress,
            betSlipId,
            gameType,
            _target,
            contractAddress,
            _amount,
            odds
        );
    }

    function resolveBet(
        uint256 matchId,
        uint16 gameType,
        uint16[] calldata _targets
    ) external nonReentrant onlyRole(ROLE_MANAGER) {
        bytes32[] memory betIds = gameBets[matchId][gameType].values();
        uint256 length = gameBets[matchId][gameType].length();
        require(length > 0, "NO_BETS");
        for (uint256 i = 0; i < _targets.length; i++) {
            targets[_targets[i]] = true;
        }
        for (uint256 i = 0; i < length; i++) {
            bytes32 betSlipId = betIds[i];
            Bet storage myBet = bets[betSlipId];
            gameBets[matchId][gameType].remove(betSlipId);
            if (myBet.resolved) {
                continue;
            }
            bool valid = targets[myBet.target];
            myBet.resolved = true;
            if (valid) {
                myBet.result = 1;
                lockUserBalance(
                    myBet.roomId,
                    myBet.contractAddress,
                    myBet.bettor
                );
                myBet.payout = myBet.potentialWinningAmount;
                userBalances[myBet.roomId][myBet.contractAddress][
                    myBet.bettor
                ] += myBet.potentialWinningAmount;
                unlockUserBalance(
                    myBet.roomId,
                    myBet.contractAddress,
                    myBet.bettor
                );
                lockRoomReverse(myBet.roomId, myBet.contractAddress);
                rooms[myBet.roomId].reverses[myBet.contractAddress] -= myBet
                    .potentialWinningAmount;
                rooms[myBet.roomId].lockedReverses[
                    myBet.contractAddress
                ] -= myBet.potentialWinningAmount;
                unlockRoomReverse(myBet.roomId, myBet.contractAddress);
            } else {
                myBet.result = 0;
                lockRoomReverse(myBet.roomId, myBet.contractAddress);
                rooms[myBet.roomId].lockedReverses[
                    myBet.contractAddress
                ] -= myBet.potentialWinningAmount;
                unlockRoomReverse(myBet.roomId, myBet.contractAddress);
            }

            emit BetResolved(
                myBet.roomId,
                myBet.bettor,
                betSlipId,
                myBet.target,
                myBet.result,
                myBet.contractAddress,
                myBet.amount,
                myBet.payout
            );
        }
        for (uint256 i = 0; i < _targets.length; i++) {
            delete targets[_targets[i]];
        }
    }

    function setSignerAddress(address _signerAddress)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        signerAddress = _signerAddress;
    }

    function setTimestampThreshold(uint8 _timestampThreshold)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        timestampThreshold = _timestampThreshold;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}