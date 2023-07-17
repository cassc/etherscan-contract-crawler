// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

contract BetDexEvent {
	/// @notice Emitted when reserves is deposited.
	event ReservesDeposited(
		bytes32 indexed roomId,
		address indexed sender,
		address indexed contractAddress,
		uint256 amount
	);

	event FeeDeposited(
		bytes32 indexed roomId,
		address indexed sender,
		address indexed contractAddress,
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

	event FeeWithdrawn(
		bytes32 indexed roomId,
		address indexed contractAddress,
		address sender,
		address indexed recipient,
		uint256 amount
	);

	event RejectWithdrawal(
		uint256 indexed id,
		bytes32 indexed roomId,
		address contractAddress,
		address approver,
		address indexed recipient,
		uint256 amountToRoom
	);

	event AdminFeeWithdrawn(
		address indexed contractAddress,
		address sender,
		address indexed recipient,
		uint256 amount
	);

	event RoomCreated(
		bytes32 indexed roomId,
		address indexed contractAddress,
		address sender
	);

	/// @notice Emitted when user transfer balance to room.
	event TransferToRoom(
		bytes32 indexed roomId,
		address indexed contractAddress,
		address sender,
		uint256 amount
	);

	event BetPlaced(
		uint256 indexed matchId,
		address indexed sender,
		bytes32 betSlipId,
		bytes32 roomId
	//        uint16 gameType,
	//        uint16 _target,
	//        address contractAddress,
	//        uint256 amount,
	//        uint32 odds
	);
	event BetResolved(
		bytes32 indexed roomId,
		address indexed sender,
		bytes32 indexed betSlipId,
		uint16 target,
		bool result,
	//        address contractAddress,
	//        uint256 amount,
		uint256 payout
	);
	event PendingWithdrawalCreated(
		uint256 indexed id,
		address indexed sender,
		address indexed contractAddress,
		uint256 amount
	);

	event WithdrawalDailyLimit(address indexed contractAddress, uint256 amount);
	event MinBetLimit(address indexed contractAddress, uint256 amount);
	event MaxBetOddsLimit(uint256 maxOdds);
}