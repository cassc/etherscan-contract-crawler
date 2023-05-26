pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./CosmosToken.sol";
import "./CudosAccessControls.sol";

pragma experimental ABIEncoderV2;

// This is used purely to avoid stack too deep errors
// represents everything about a given validator set
struct ValsetArgs {
	// the validators in this set, represented by an Ethereum address
	address[] validators;
	// the powers of the given validators in the same order as above
	uint256[] powers;
	// the nonce of this validator set
	uint256 valsetNonce;
	// the reward amount denominated in the below reward token, can be
	// set to zero
	uint256 rewardAmount;
	// the reward token, should be set to the zero address if not being used
	address rewardToken;
}

contract Gravity is ReentrancyGuard, Pausable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	// These are updated often
	bytes32 public state_lastValsetCheckpoint;
	mapping(address => uint256) public state_lastBatchNonces;
	mapping(bytes32 => uint256) public state_invalidationMapping;
	uint256 public state_lastValsetNonce;

	// event nonce zero is reserved by the Cosmos module as a special
	// value indicating that no events have yet been submitted
	uint256 public state_lastEventNonce = 1;

	// These are set once at initialization

	bytes32 public immutable state_gravityId;
	uint256 public immutable state_powerThreshold;

	CudosAccessControls public immutable cudosAccessControls;

	mapping(address => bool) public supportedToCosmosTokens;
  
	// TransactionBatchExecutedEvent and SendToCosmosEvent both include the field _eventNonce.
	// This is incremented every time one of these events is emitted. It is checked by the
	// Cosmos module to ensure that all events are received in order, and that none are lost.
	//
	// ValsetUpdatedEvent does not include the field _eventNonce because it is never submitted to the Cosmos
	// module. It is purely for the use of relayers to allow them to successfully submit batches.
	event TransactionBatchExecutedEvent(
		uint256 indexed _batchNonce,
		address indexed _token,
		uint256 _eventNonce
	);

	event SendToCosmosEvent(
		address indexed _tokenContract,
		address indexed _sender,
		bytes32 indexed _destination,
		uint256 _amount,
		uint256 _eventNonce
	);

	event ERC20DeployedEvent(
		// FYI: Can't index on a string without doing a bunch of weird stuff
		string _cosmosDenom,
		address indexed _tokenContract,
		string _name,
		string _symbol,
		uint8 _decimals,
		uint256 _eventNonce
	);

	event ValsetUpdatedEvent(
		uint256 indexed _newValsetNonce,
		uint256 _eventNonce,
		uint256 _rewardAmount,
		address _rewardToken,
		address[] _validators,
		uint256[] _powers
	);


	modifier onlyAdmin() {
		require(cudosAccessControls.hasAdminRole(msg.sender), "Recipient is not an admin");
		_;
	}

	// END TEST FIXTURES

	function lastBatchNonce(address _erc20Address) external view returns (uint256) {
		return state_lastBatchNonces[_erc20Address];
	}
	
	//pause functions
	function pause() external onlyAdmin {
		_pause();
	}

	function unpause() external onlyAdmin {
		_unpause();
	}

	// Utility function to verify geth style signatures
	function verifySig(
		address _signer,
		bytes32 _theHash,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) private pure returns (bool) {
		bytes32 messageDigest = keccak256(
			abi.encodePacked("\x19Ethereum Signed Message:\n32", _theHash)
		);
		address recAddr = ECDSA.recover(messageDigest, _v, _r, _s);
		return _signer == recAddr;
	}

	// Make a new checkpoint from the supplied validator set
	// A checkpoint is a hash of all relevant information about the valset. This is stored by the contract,
	// instead of storing the information directly. This saves on storage and gas.
	// The format of the checkpoint is:
	// h(gravityId, "checkpoint", valsetNonce, validators[], powers[])
	// Where h is the keccak256 hash function.
	// The validator powers must be decreasing or equal. This is important for checking the signatures on the
	// next valset, since it allows the caller to stop verifying signatures once a quorum of signatures have been verified.
	function makeCheckpoint(ValsetArgs memory _valsetArgs, bytes32 _gravityId)
		private
		pure
		returns (bytes32)
	{
		// bytes32 encoding of the string "checkpoint"
		bytes32 methodName = 0x636865636b706f696e7400000000000000000000000000000000000000000000;

		bytes32 checkpoint = keccak256(
			abi.encode(
				_gravityId,
				methodName,
				_valsetArgs.valsetNonce,
				_valsetArgs.validators,
				_valsetArgs.powers,
				_valsetArgs.rewardAmount,
				_valsetArgs.rewardToken
			)
		);

		return checkpoint;
	}


	// checks if the provided signatures are correct and also
	// checks if the gathered validator power is over threshold
	function checkValidatorSignatures(
		// The current validator set and their powers
		address[] memory _currentValidators,
		uint256[] memory _currentPowers,
		// The current validator's signatures
		uint8[] memory _v,
		bytes32[] memory _r,
		bytes32[] memory _s,
		// This is what we are checking they have signed
		bytes32 _theHash
	) private view {

		uint256 _powerThreshold = state_powerThreshold;
		uint256 cumulativePower;
		uint256 valLength = _currentValidators.length;
		for (uint256 i; i < valLength; ++i) {
			// If v is set to 0, this signifies that it was not possible to get a signature from this validator and we skip evaluation
			// (In a valid signature, it is either 27 or 28)
			if (_v[i] != 0) {
				// Check that the current validator has signed off on the hash
				require(
					verifySig(_currentValidators[i], _theHash, _v[i], _r[i], _s[i]),
					"Validator signature does not match."
				);

				// Sum up cumulative power
				cumulativePower = cumulativePower + _currentPowers[i];

				// Break early to avoid wasting gas
				if (cumulativePower > _powerThreshold) {
					break;
				}
			}
		}

		// Check that there was enough power
		checkComulatedPower(cumulativePower, _powerThreshold);
		// Success
	}

	// checks if the comulated power surpasses power threshold
	// not using state value ot power threshold so this can be used in constructor as well
	function checkComulatedPower(uint256 _cumulativePower, uint256 _powerThreshold) internal pure {
		require(
			_cumulativePower > _powerThreshold,
			"given valset power < threshold"
		);
	}

	function checkValsetData(
		ValsetArgs memory _currentValset,
		// These are arrays of the parts of the validators signatures
		uint8[] memory _v,
		bytes32[] memory _r,
		bytes32[] memory _s
	) internal pure {
		require(_currentValset.validators.length == _currentValset.powers.length, "Malformed current validator set");
		require(_currentValset.validators.length == _v.length, "Malformed current validator set");
		require(_currentValset.validators.length == _r.length, "Malformed current validator set");
		require(_currentValset.validators.length == _s.length, "Malformed current validator set");
	}

	function checkCheckpoint(ValsetArgs memory _currentValset, bytes32 _gravityId) private view {
		require(
			makeCheckpoint(_currentValset, _gravityId) == state_lastValsetCheckpoint,
			"given valset != checkpoint"
		);
	}
  
	// checks if the address is in the validator / orchestrator set
	function isOrchestrator(ValsetArgs memory _valset, address _sender) private pure {
		uint256 valLength = _valset.validators.length;
		for (uint256 i; i < valLength; ++i) {
			if(_valset.validators[i] == _sender) {
				return;
			}
		}
		
		revert("not validated orchestrator");
	}

	// adds supported token to the mapping
	function addToCosmosToken(address _cosmosToken) external onlyAdmin {
		supportedToCosmosTokens[_cosmosToken] = true;
	}

	// removes a supported token from the mapping
	function removeToCosmosToken(address _cosmosToken) external onlyAdmin {
		supportedToCosmosTokens[_cosmosToken] = false;
	}

	// This updates the valset by checking that the validators in the current valset have signed off on the
	// new valset. The signatures supplied are the signatures of the current valset over the checkpoint hash
	// generated from the new valset.
	// Anyone can call this function, but they must supply valid signatures of state_powerThreshold of the current valset over
	// the new valset.
	function updateValset(
		// The new version of the validator set
		ValsetArgs memory _newValset,
		// The current validators that approve the change
		ValsetArgs memory _currentValset,
		// These are arrays of the parts of the current validator's signatures
		uint8[] memory _v,
		bytes32[] memory _r,
		bytes32[] memory _s
	) external nonReentrant whenNotPaused {
		// CHECKS

		// Check that the valset nonce is greater than the old one
		require(
			_newValset.valsetNonce > _currentValset.valsetNonce,
			"newValset nonce <= current"
		);

		// Check that new validators and powers set is well-formed
		require(
			_newValset.validators.length == _newValset.powers.length,
			"Malformed new validator set"
		);

		// Check that current validators, powers, and signatures (v,r,s) set is well-formed
		checkValsetData(_currentValset, _v, _r, _s);

		// Check that the supplied current validator set matches the saved checkpoint
		bytes32 gravityId = state_gravityId;
		checkCheckpoint(_currentValset, gravityId);

		// check that the msg.sender is one of the orchestrators
		isOrchestrator(_currentValset, msg.sender);

		// Check that enough current validators have signed off on the new validator set
		bytes32 newCheckpoint = makeCheckpoint(_newValset, gravityId);

		checkValidatorSignatures(
			_currentValset.validators,
			_currentValset.powers,
			_v,
			_r,
			_s,
			newCheckpoint
		);

		// ACTIONS

		// Stored to be used next time to validate that the valset
		// supplied by the caller is correct.
		state_lastValsetCheckpoint = newCheckpoint;

		// Store new nonce
		state_lastValsetNonce = _newValset.valsetNonce;

		// Send submission reward to msg.sender if reward token is a valid value
		if (_newValset.rewardToken != address(0) && _newValset.rewardAmount != 0) {
			IERC20(_newValset.rewardToken).safeTransfer(msg.sender, _newValset.rewardAmount);
		}

		// LOGS
		uint256 lastEventNonce = state_lastEventNonce.add(1);
		state_lastEventNonce = lastEventNonce;
		emit ValsetUpdatedEvent(
			_newValset.valsetNonce,
			lastEventNonce,
			_newValset.rewardAmount,
			_newValset.rewardToken,
			_newValset.validators,
			_newValset.powers
		);
	}

	// submitBatch processes a batch of Cosmos -> Ethereum transactions by sending the tokens in the transactions
	// to the destination addresses. It is approved by the current Cosmos validator set.
	// Anyone can call this function, but they must supply valid signatures of state_powerThreshold of the current valset over
	// the batch.
	function submitBatch (
		// The validators that approve the batch
		ValsetArgs memory _currentValset,
		// These are arrays of the parts of the validators signatures
		uint8[] memory _v,
		bytes32[] memory _r,
		bytes32[] memory _s,
		// The batch of transactions
		uint256[] memory _amounts,
		address[] memory _destinations,
		uint256[] memory _fees,
		uint256 _batchNonce,
		address _tokenContract,
		// a block height beyond which this batch is not valid
		// used to provide a fee-free timeout
		uint256 _batchTimeout
	) external nonReentrant whenNotPaused {
		// CHECKS scoped to reduce stack depth
		{

			// Check that the transaction batch is well-formed
			require(_amounts.length == _destinations.length, "Malformed batch of transactions");
			require(_amounts.length == _fees.length, "Malformed batch of transactions");
			
			// Check that the batch nonce is higher than the last nonce for this token
			require(
				state_lastBatchNonces[_tokenContract] < _batchNonce,
				"new batch nonce <= current"
			);

			// Check that the block height is less than the timeout height
			require(
				block.number < _batchTimeout,
				"batch timeout <= block height"
			);

			// Check that current validators, powers, and signatures (v,r,s) set is well-formed
			checkValsetData(_currentValset, _v, _r, _s);

			// Check that the supplied current validator set matches the saved checkpoint
			bytes32 gravityId = state_gravityId;
			checkCheckpoint(_currentValset, gravityId);

			// check that the msg.sender is one of the orchestrators
			isOrchestrator(_currentValset, msg.sender);

			// Check that enough current validators have signed off on the transaction batch and valset
			checkValidatorSignatures(
				_currentValset.validators,
				_currentValset.powers,
				_v,
				_r,
				_s,
				// Get hash of the transaction batch and checkpoint
				keccak256(
					abi.encode(
						gravityId,
						// bytes32 encoding of "transactionBatch"
						0x7472616e73616374696f6e426174636800000000000000000000000000000000,
						_amounts,
						_destinations,
						_fees,
						_batchNonce,
						_tokenContract,
						_batchTimeout
					)
				)
			);

			// ACTIONS

			// Store batch nonce
			state_lastBatchNonces[_tokenContract] = _batchNonce;

			{
				// Send transaction amounts to destinations
				uint256 totalFee;
				uint256 amountsLength = _amounts.length;
				for (uint256 i; i < amountsLength; ++i) {
					IERC20(_tokenContract).safeTransfer(_destinations[i], _amounts[i]);
					totalFee = totalFee.add(_fees[i]);
				}

				// Send transaction fees to msg.sender
				IERC20(_tokenContract).safeTransfer(msg.sender, totalFee);
			}
		}

		// LOGS scoped to reduce stack depth
		{
			uint256 lastEventNonce = state_lastEventNonce.add(1);
			state_lastEventNonce = lastEventNonce;
			emit TransactionBatchExecutedEvent(_batchNonce, _tokenContract, lastEventNonce);
		}
	}

	function sendToCosmos(
		address _tokenContract,
		bytes32 _destination,
		uint256 _amount
	)
		external 
		nonReentrant 
		whenNotPaused
	{
		require(supportedToCosmosTokens[_tokenContract], "token not supported");

		uint32 size;
		assembly {
			size := extcodesize(_tokenContract)
		}
		require(size != 0, "empty bytecode token");


		IERC20(_tokenContract).safeTransferFrom(msg.sender, address(this), _amount);
		
		uint256 lastEventNonce = state_lastEventNonce.add(1);
		state_lastEventNonce = lastEventNonce;
		emit SendToCosmosEvent(
			_tokenContract,
			msg.sender,
			_destination,
			_amount,
			lastEventNonce
		);
	}

	function deployERC20(
		string memory _cosmosDenom,
		string memory _name,
		string memory _symbol,
		uint8 _decimals
	) 	
		external 
		whenNotPaused 
	{
		uint256 lastEventNonce = state_lastEventNonce.add(1);
		state_lastEventNonce = lastEventNonce;
		// Deploy an ERC20 with entire supply granted to Gravity.sol
		CosmosERC20 erc20 = new CosmosERC20(address(this), _name, _symbol, _decimals);

		// Fire an event to let the Cosmos module know
		emit ERC20DeployedEvent(
			_cosmosDenom,
			address(erc20),
			_name,
			_symbol,
			_decimals,
			lastEventNonce
		);
	}

	function withdrawERC20(
		address _tokenAddress
	) 
		external 
		onlyAdmin
	{
		uint256 totalBalance = IERC20(_tokenAddress).balanceOf(address(this));
		IERC20(_tokenAddress).safeTransfer(msg.sender , totalBalance);
	}

	constructor(
		// A unique identifier for this gravity instance to use in signatures
		bytes32 _gravityId,
		// How much voting power is needed to approve operations
		uint256 _powerThreshold,
		// The validator set, not in valset args format since many of it's
		// arguments would never be used in this case
		address[] memory _validators,
    	uint256[] memory _powers,
		CudosAccessControls _cudosAccessControls,
		address _mainToken
	) {
		// CHECKS

		// Check that validators, powers, and signatures (v,r,s) set is well-formed

		uint256 powersLength = _powers.length;
		require(_validators.length == powersLength, "Malformed current validator set");
		require(address(_cudosAccessControls) != address(0), "AccessControl address wrong");

		// Check cumulative power to ensure the contract has sufficient power to actually
		// pass a vote
		uint256 cumulativePower;
		for (uint256 i; i < powersLength; ++i) {
			cumulativePower = cumulativePower + _powers[i];
			if (cumulativePower > _powerThreshold) {
				break;
			}
		}

		checkComulatedPower(cumulativePower, _powerThreshold);

		ValsetArgs memory _valset;
		_valset = ValsetArgs(_validators, _powers, 0, 0, address(0));

		bytes32 newCheckpoint = makeCheckpoint(_valset, _gravityId);

		// ACTIONS

		state_gravityId = _gravityId;
		state_powerThreshold = _powerThreshold;
		state_lastValsetCheckpoint = newCheckpoint;

		cudosAccessControls = _cudosAccessControls;

		supportedToCosmosTokens[_mainToken] = true;
		// LOGS

		emit ValsetUpdatedEvent(
			state_lastValsetNonce,
			state_lastEventNonce,
			0,
			address(0),
			_validators,
			_powers
		);
	}
}