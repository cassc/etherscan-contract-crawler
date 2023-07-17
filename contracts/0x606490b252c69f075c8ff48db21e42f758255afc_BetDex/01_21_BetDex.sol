// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./EIP712.sol";
import "./Token.sol";
//import "./MerkleVerifier.sol";
import { InputBet, Input, SignatureVersion } from "./BetStructs.sol";
import "./BetDexEvent.sol";

contract BetDex is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, EIP712, PausableUpgradeable, BetDexEvent {
    bool private initialized;
    bytes32 public constant ROLE_RANDOMIZER = keccak256("ROLE_RANDOMIZER");
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");
	bytes32 public constant ROLE_AUDITOR = keccak256("ROLE_AUDITOR");

    uint8 public constant ODDS_DECIMAL = 4;
	uint8 public constant SIGNATURE_TIMESTAMP_THRESHOLD = 90;
	uint16 public constant WITHDRAWAL_TIMEOUT = 60 * 24 * 2; // TODO:: will change?
	string public constant NAME = "BetDex";
	string public constant VERSION = "1.0";

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ECDSAUpgradeable for bytes32;
	using MathUpgradeable for uint256;

    address public signerAddress; // Signer role (1:1 mapping)
    mapping(bytes32 => mapping(address => uint256))
	public userBalances;
	mapping(bytes32 => mapping(uint256 => bytes32[]))
		private gameBetsArr;
	mapping(uint256 => bytes32[])
		private gameBetRoomsArr;
	mapping(uint256 => mapping(bytes32 => bool))
		private gameBetRoomsArrState;
    mapping(address => mapping(uint256 => bool)) public usedNonce;
    mapping(bytes32 => Room) public rooms;
	mapping(address => uint256) private minBetLimit;
	mapping(address => uint256) public withdrawalDailyLimit;
	mapping(uint256 => PendingWithdrawal) public pendingWithdrawals;
	mapping(address => mapping(address => mapping(uint256 => uint256))) public userWithdrawalCount; // userAddress, contractAddress, day, limit
	mapping(uint256 => uint256) gameBetRoomsArrProcessed;
	mapping(bytes32 => mapping(uint256 => uint256)) gameBetsArrProcessed;
	mapping(address => uint256) public gameBetFee;
	mapping(uint256 => bool) public matchResolved;
	uint256 public pendingWithdrawalId;
	uint256 public maxOdds;

	struct PendingWithdrawal {
		uint256 id;
		bytes32 roomId;
		address userAddress;
		uint256 amount;
		uint256 time;
		bool executed;
	}

    struct Room {
		address owner;
		address contractAddress;
		bytes32 id;
		uint256 reverse;
		uint256 lockedReverse;
		uint256 availableFee;
    }

    struct Bet {
		uint16 target;
		address bettor;
        uint256 potentialWinningAmount;
		uint256 amount;
    }

	mapping(uint16 => bool) private targets;
	mapping(bytes32 => Bet) public bets;
	mapping(uint16 => bool) private refundTargets;

    function initialize(address _address) public initializer {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
        _setupRole(ROLE_MANAGER, _address);
        signerAddress = _address;
		maxOdds = 10 * (10 ** ODDS_DECIMAL); // TODO::Define max odd
    }

	function _getDomainSeparator() internal view override(EIP712) returns (bytes32) {
		return _hashDomain(EIP712Domain({
			name              : NAME,
			version           : VERSION,
			chainId           : block.chainid,
			verifyingContract : address(this)
		}));
	}

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PERMISSION_DENIED");
        _;
    }

    modifier onlyOwners(bytes32 roomId) {
        require(
			rooms[roomId].owner == msg.sender,
            "PERMISSION_DENIED"
        );
        _;
    }

    function createRoomWithToken(
        bytes32 roomId,
        address mainOwner,
        address contractAddress
    ) external whenNotPaused {
        Room storage room = rooms[roomId];
        require(room.id == 0, "ROOM_ALREADY_EXISTS");
        require(
            IERC20Upgradeable(contractAddress).totalSupply() > 0,
            "INVALID_TOKEN"
        );
        room.id = roomId;
		room.owner = mainOwner;
		room.contractAddress = contractAddress;
		emit RoomCreated(roomId, contractAddress, mainOwner);
    }

    /// @notice Deposit reserves into the room. Only available to room owners.
    /// @param _amount Amount to deposit into the room.
    /// @notice Must approve enough amount for ERC20 transfer before calling this function.
    function depositReserves(
        bytes32 roomId,
        uint256 _amount,
		uint256 _feeAmount
    ) external whenNotPaused nonReentrant onlyOwners(roomId) {
		Room storage room = rooms[roomId];
        Token.deposit(room.contractAddress, msg.sender, _amount + _feeAmount);
        room.reverse += _amount;
		room.availableFee += _feeAmount;
        emit ReservesDeposited(roomId, msg.sender, room.contractAddress, _amount);
		emit FeeDeposited(roomId, msg.sender, room.contractAddress, _feeAmount);
    }

    /// @notice Withdraw from the room. Only available to room owners.
    /// @param _recipient Address of the withdraw recipient.
    /// @param _amount Amount to withdraw.
    function withdrawReserves(
        bytes32 roomId,
        address _recipient,
        uint256 _amount
    ) external whenNotPaused nonReentrant onlyOwners(roomId) {
        require(rooms[roomId].lockedReverse == 0, "LOCKED");
        uint256 roomBalance = roomAvailableReserve(roomId);
        require(roomBalance >= _amount, "INSUFFICIENT_BALANCE");
        rooms[roomId].reverse -= _amount;
        Token.withdrawal(rooms[roomId].contractAddress, _recipient, _amount);
        emit ReservesWithdrawn(
            roomId,
			rooms[roomId].contractAddress,
            msg.sender,
            _recipient,
            _amount
        );
    }

	function adminWithdrawBetFee(
		address contractAddress,
		address _recipient,
		uint256 _amount
	) external whenNotPaused onlyAdmin nonReentrant {
		require(gameBetFee[contractAddress] >= _amount, "INSUFFICIENT_BALANCE");
		gameBetFee[contractAddress] -= _amount;
		Token.withdrawal(contractAddress, _recipient, _amount);
		emit AdminFeeWithdrawn(
			contractAddress,
			msg.sender,
			_recipient,
			_amount
		);
	}

    /// @notice User withdrawal
    /// @param roomId Room Id
    /// @param _amount Amount to withdraw.
    function userWithdrawal(
        bytes32 roomId,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
		Room memory room = rooms[roomId];
        require(
            userBalances[roomId][msg.sender] >= _amount,
            "INSUFFICIENT_BALANCE"
        );
        userBalances[roomId][msg.sender] -= _amount;
		uint256 currentDay = block.timestamp - (block.timestamp % 1 days);
		userWithdrawalCount[msg.sender][room.contractAddress][currentDay] += _amount;
		if (withdrawalDailyLimit[room.contractAddress] > 0 && userWithdrawalCount[msg.sender][room.contractAddress][currentDay] >= withdrawalDailyLimit[room.contractAddress]) { // exceed daily limit
			uint256 currentPendingWithdrawalId = ++pendingWithdrawalId;
			PendingWithdrawal storage pendingWithdrawal = pendingWithdrawals[currentPendingWithdrawalId];
			pendingWithdrawal.id = currentPendingWithdrawalId;
			pendingWithdrawal.roomId = roomId;
			pendingWithdrawal.userAddress = msg.sender;
			pendingWithdrawal.amount = _amount;
			pendingWithdrawal.time = block.timestamp;
			emit PendingWithdrawalCreated(pendingWithdrawal.id, msg.sender, room.contractAddress, _amount);
		} else {
			Token.withdrawal(room.contractAddress, msg.sender, _amount);
		}
    }

	function approveWithdrawal(uint256 id, uint256 amount) external whenNotPaused onlyRole(ROLE_AUDITOR) nonReentrant {
		PendingWithdrawal storage pendingWithdrawal = pendingWithdrawals[id];
		require(pendingWithdrawal.id == id, "PENDING_WITHDRAWAL_NOT_EXISTS");
		require(pendingWithdrawal.executed == false, "WITHDRAWAL_PROCESSED");
		require(amount > 0 && amount <= pendingWithdrawal.amount, "INVALID_WITHDRAWAL_AMOUNT");
		pendingWithdrawal.executed = true;
		uint256 feeToRoom = pendingWithdrawal.amount - amount;
		if (feeToRoom > 0) {
			rooms[pendingWithdrawal.roomId].reverse += feeToRoom;
		}
		Token.withdrawal(rooms[pendingWithdrawal.roomId].contractAddress, pendingWithdrawal.userAddress, amount);
	}

	function batchApproveWithdrawal(uint256[] calldata ids) external whenNotPaused onlyRole(ROLE_AUDITOR) nonReentrant {
		uint idLength = ids.length;
    	address roomContractAddress;
    	address userAddress;
    	uint256 totalAmount;

		for (uint i; i < idLength; i = _uncheckedInc(i)) {
			PendingWithdrawal storage pendingWithdrawal = pendingWithdrawals[ids[i]];
			require(pendingWithdrawal.id == ids[i], "PENDING_WITHDRAWAL_NOT_EXISTS");
			require(!pendingWithdrawal.executed, "WITHDRAWAL_PROCESSED");
			if (i == 0) {
				roomContractAddress = rooms[pendingWithdrawal.roomId].contractAddress;
				userAddress = pendingWithdrawal.userAddress;
			} else {
				address tempRoomContractAddress = rooms[pendingWithdrawal.roomId].contractAddress;
				address tempUserAddress = pendingWithdrawal.userAddress;

				if (roomContractAddress != tempRoomContractAddress || userAddress != tempUserAddress) {
					Token.withdrawal(roomContractAddress, userAddress, totalAmount);
					roomContractAddress = tempRoomContractAddress;
					userAddress = tempUserAddress;
					totalAmount = 0;
				}
			}
			totalAmount += pendingWithdrawal.amount;
			pendingWithdrawal.executed = true;
		}

		if (totalAmount > 0) {
			Token.withdrawal(roomContractAddress, userAddress, totalAmount);
		}
	}

	function rejectWithdrawal(uint256 id) external whenNotPaused onlyRole(ROLE_AUDITOR) {
		PendingWithdrawal storage pendingWithdrawal = pendingWithdrawals[id];
		require(pendingWithdrawal.id == id, "PENDING_WITHDRAWAL_NOT_EXISTS");
		require(pendingWithdrawal.executed == false, "WITHDRAWAL_PROCESSED");
		pendingWithdrawal.executed = true;
		rooms[pendingWithdrawal.roomId].reverse += pendingWithdrawal.amount;
		emit RejectWithdrawal(id, pendingWithdrawal.roomId, rooms[pendingWithdrawal.roomId].contractAddress, msg.sender, pendingWithdrawal.userAddress, pendingWithdrawal.amount);
	}

	function userRequestWithdrawalTimeout(uint256 id) external whenNotPaused nonReentrant {
		PendingWithdrawal storage pendingWithdrawal = pendingWithdrawals[id];
		require(pendingWithdrawal.id == id, "PENDING_WITHDRAWAL_NOT_EXISTS");
		require(pendingWithdrawal.executed == false, "WITHDRAWAL_PROCESSED");
		require(pendingWithdrawal.userAddress == msg.sender, "NOT_REQUEST_BY_SENDER");
		require(block.timestamp - WITHDRAWAL_TIMEOUT >= pendingWithdrawal.time, "PENDING_ADMIN_APPROVAL");
		pendingWithdrawal.executed = true;
		Token.withdrawal(rooms[pendingWithdrawal.roomId].contractAddress, pendingWithdrawal.userAddress, pendingWithdrawal.amount);
	}

	function setMaxOdds(uint256 odds) external onlyAdmin {
		maxOdds = odds;
		emit MaxBetOddsLimit(odds);
	}

    /// @notice Get current amount of available reserves.
    function roomAvailableReserve(bytes32 roomId)
        public
        view
        returns (uint256)
    {
        return
            rooms[roomId].reverse -
            rooms[roomId].lockedReverse;
    }

    function getUserBalance(
        bytes32 roomId,
        address userAddress
    ) public view returns (uint256) {
        return userBalances[roomId][userAddress];
    }

	/**
     * @dev Verify ECDSA signature
     * @param signer Expected signer
     * @param digest Signature preimage
     * @param v v
     * @param r r
     * @param s s
     */
	function _verify(
		address signer,
		bytes32 digest,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal pure returns (bool) {
		require(v == 27 || v == 28, "Invalid v parameter");
		address recoveredSigner = ecrecover(digest, v, r, s);
		if (recoveredSigner == address(0)) {
			return false;
		} else {
			return signer == recoveredSigner;
		}
	}

	function _validateSignatures(Input calldata input, bytes32 hash)
		internal
		view
		returns (bool)
	{
		require((input.timestamp + SIGNATURE_TIMESTAMP_THRESHOLD) >= block.timestamp, "INVALID_SIGNATURE");
		return _validateAuthorization(keccak256(abi.encodePacked(hash, input.timestamp)), input.v, input.r, input.s);
	}

	function _validateAuthorization(
		bytes32 hash,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal view returns (bool) {
		bytes32 hashToSign;
		hashToSign = _hashToSign(hash);
		return _verify(signerAddress, hashToSign, v, r, s);
	}

	function batchSignedBet(Input calldata input) external whenNotPaused nonReentrant {
		require(usedNonce[input.bets[0].bettor][input.nonce] == false, "Nonce already used");
		usedNonce[input.bets[0].bettor][input.nonce] = true;
		bytes32[] memory betHashes = _hashBets(input.bets, input.nonce);
		bytes32 betSignHash = keccak256(abi.encodePacked(betHashes));
		require(_validateSignatures(input, betSignHash), "Invalid signature");
		(uint256 totalBetAmount, uint256 totalPotentialWinningAmount) = _preparePlaceBets(input, betHashes);
		_transferFees(input.roomId, input.bets[0].bettor, totalBetAmount);
		_transferRoomReverse(input.roomId, totalBetAmount, totalPotentialWinningAmount);
	}

	function setMatchResolved(uint256 matchId) external whenNotPaused nonReentrant onlyRole(ROLE_MANAGER) {
		matchResolved[matchId] = true;
	}

	function _preparePlaceBets(Input calldata input, bytes32[] memory betHashes) internal returns (uint256, uint256) {
		uint256 totalPotentialWinningAmount;
		uint256 totalBetAmount;
		address bettorAddress;
		uint betLength = input.bets.length;
		for (uint i = 0; i < betLength; i = _uncheckedInc(i)) {
			if (i == 0) {
				bettorAddress = input.bets[0].bettor;
			}
			require(input.bets[i].amount > minBetLimit[rooms[input.roomId].contractAddress], "Invalid amount");
			require(bettorAddress == input.bets[i].bettor, "Not allow multiple bettor");
			require(input.bets[i].odds <= maxOdds, "Exceed Max Odds");
			require(matchResolved[input.bets[i].matchId] == false, "Match resolved");
			uint256 potentialWinningAmount = (input.bets[i].amount * input.bets[i].odds) / (10**ODDS_DECIMAL);
			totalPotentialWinningAmount += potentialWinningAmount;
			totalBetAmount += input.bets[i].amount;
			bytes32 betHash = betHashes[i];
			Bet storage myBet = bets[betHash];
			require(myBet.bettor == address(0), "BET_EXISTS");
			myBet.bettor = input.bets[i].bettor;
			myBet.target = input.bets[i].target;
			myBet.potentialWinningAmount = potentialWinningAmount;
			myBet.amount = input.bets[i].amount;
			gameBetsArr[input.roomId][input.bets[i].matchId].push(betHashes[i]);
			if (!gameBetRoomsArrState[input.bets[i].matchId][input.roomId]) {
				gameBetRoomsArrState[input.bets[i].matchId][input.roomId] = true;
				gameBetRoomsArr[input.bets[i].matchId].push(input.roomId);
			}

			emit BetPlaced(
				input.bets[i].matchId,
				myBet.bettor,
				betHashes[i],
				input.roomId
			);
		}
		return (totalBetAmount, totalPotentialWinningAmount);
	}

	function _transferFees(bytes32 roomId, address userAddress, uint256 amount) internal {
		address contractAddress = rooms[roomId].contractAddress;
		uint256 transferAmount;
		uint256 userBalance = userBalances[roomId][userAddress];
		if (userBalance == 0) {
			Token.deposit(contractAddress, userAddress, amount);
			emit TransferToRoom(
				roomId,
				contractAddress,
				userAddress,
				amount
			);
		} else if (userBalance < amount) {
			transferAmount = amount - userBalance;
			userBalances[roomId][userAddress] = 0;
			Token.deposit(contractAddress, userAddress, transferAmount);
			emit TransferToRoom(
				roomId,
				contractAddress,
				userAddress,
				transferAmount
			);
		} else {
			userBalances[roomId][userAddress] = userBalance - amount;
		}
	}

	function _transferRoomReverse(bytes32 roomId, uint256 betAmount, uint256 potentialWinningAmount) internal {
		rooms[roomId].reverse += betAmount;
		require(
			roomAvailableReserve(roomId) >=
			potentialWinningAmount,
			"FAILED_TO_BET"
		);
		rooms[roomId].lockedReverse += potentialWinningAmount;
	}

	function transferBetFee(bytes32 roomId, uint256 feeAmount) public whenNotPaused nonReentrant onlyRole(ROLE_AUDITOR) {
		require(rooms[roomId].availableFee >= feeAmount, "ROOM_OUT_OF_FEE");
		rooms[roomId].availableFee -= feeAmount;
		gameBetFee[rooms[roomId].contractAddress] += feeAmount;
	}

	function _uncheckedInc(uint i) pure internal returns (uint) {
		unchecked {
			return i + 1;
		}
	}

    function resolveBet(
        uint256 matchId,
        uint16[] calldata _targets,
		uint16[] calldata _refundTargets,
		uint256 maxBetLength
    ) external whenNotPaused onlyRole(ROLE_MANAGER) {
		uint256 processedRoomLength = gameBetRoomsArrProcessed[matchId];
		uint256 roomLength = gameBetRoomsArr[matchId].length - processedRoomLength;
		uint256 targetLength = _targets.length;
		uint256 refundTargetLength = _refundTargets.length;
		uint256 processedRoomCount = 0;
		uint256 totalProcessed = 0;
		require(roomLength > 0, "NO_BETS");
		matchResolved[matchId] = true;
        for (uint i = 0; i < targetLength; i = _uncheckedInc(i)) {
            targets[_targets[i]] = true;
        }
		for (uint i = 0; i < refundTargetLength; i = _uncheckedInc(i)) {
			refundTargets[_refundTargets[i]] = true;
		}
		for (uint i = processedRoomLength; i < (processedRoomLength + roomLength) && totalProcessed < maxBetLength; i = _uncheckedInc(i)) {
			bytes32 roomId = gameBetRoomsArr[matchId][i];
			uint256 processedGameLength = gameBetsArrProcessed[roomId][matchId];
			uint256 length = gameBetsArr[roomId][matchId].length - processedGameLength;
			uint256 processedGameCount = 0;
			for (uint j = processedGameLength; j < (processedGameLength + length) && totalProcessed < maxBetLength; j = _uncheckedInc(j)) {
				bytes32 betSlipId = gameBetsArr[roomId][matchId][j];
				Bet memory myBet = bets[betSlipId];
				uint256 potentialWinningAmount = myBet.potentialWinningAmount;
				bool result = targets[myBet.target];
				if (refundTargets[myBet.target]) {
					uint256 betAmount = myBet.amount;
					rooms[roomId].lockedReverse -= potentialWinningAmount;
					rooms[roomId].reverse -= betAmount;
					potentialWinningAmount = betAmount;
					userBalances[roomId][
						myBet.bettor
					] += betAmount;
				} else if (result) {
					userBalances[roomId][
						myBet.bettor
					] += potentialWinningAmount;
					rooms[roomId].reverse -= potentialWinningAmount;
					rooms[roomId].lockedReverse -= potentialWinningAmount;
				} else {
					rooms[roomId].lockedReverse -= potentialWinningAmount;
					potentialWinningAmount = 0;
				}

				emit BetResolved(
					roomId,
					myBet.bettor,
					betSlipId,
					myBet.target,
					result,
					potentialWinningAmount
				);
				delete gameBetsArr[roomId][matchId][j];
				processedGameCount++;
				totalProcessed++;
			}
			gameBetsArrProcessed[roomId][matchId] += processedGameCount;
			if (gameBetsArr[roomId][matchId].length == processedGameLength + processedGameCount) {
				delete gameBetRoomsArr[matchId][i];
				++processedRoomCount;
			}
		}
		gameBetRoomsArrProcessed[matchId] += processedRoomCount;
        for (uint i = 0; i < targetLength; i = _uncheckedInc(i)) {
			targets[_targets[i]] = false;
        }
		for (uint i = 0; i < refundTargetLength; i = _uncheckedInc(i)) {
			refundTargets[_refundTargets[i]] = false;
		}
    }

    function setSignerAddress(address _signerAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        signerAddress = _signerAddress;
    }

	function setMinBetLimit(address contractAddress, uint256 amount) public onlyAdmin {
		minBetLimit[contractAddress] = amount;
		emit MinBetLimit(contractAddress, amount);
	}

	function getMinBetLimit(address contractAddress) public view returns (uint256) {
		return minBetLimit[contractAddress];
	}

	function setWithdrawalDailyLimit(address contractAddress, uint256 amount) public onlyAdmin {
		withdrawalDailyLimit[contractAddress] = amount;
		emit WithdrawalDailyLimit(contractAddress, amount);
	}

	function getWithdrawalDailyLimit(address contractAddress) public view returns (uint256) {
		return withdrawalDailyLimit[contractAddress];
	}

	function pauseContract() public onlyAdmin {
		_pause();
	}

	function unpauseContract() public onlyAdmin {
		_unpause();
	}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}