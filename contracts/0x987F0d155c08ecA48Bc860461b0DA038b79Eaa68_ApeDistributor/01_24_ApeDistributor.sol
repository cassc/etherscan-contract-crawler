// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "Ownable.sol";
import "MerkleProof.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "ApeRegistry.sol";
import "ApeVault.sol";
import "ApeAllowanceModule.sol";
import {VaultAPI} from "BaseWrapperImplementation.sol";

contract ApeDistributor is ApeAllowanceModule {
	using MerkleProof for bytes32[];
	using SafeERC20 for IERC20;

	struct ClaimData {
		address vault;
		bytes32 circle;
		address token;
		uint256 epoch;
		uint256 index;
		address account;
		uint256 checkpoint;
		bool redeemShare;
		bytes32[] proof;
	}

	address public registry;

	// address to approve admins for a circle
	// vault => circle => admin address
	mapping(address => mapping(bytes32 => address)) public vaultApprovals;


	// roots following this mapping:
	// vault address => circle ID => token address => epoch ID => root
	mapping(address => mapping(bytes32 => mapping(address => mapping(uint256 => bytes32)))) public epochRoots;
	mapping(bytes32 => mapping(address => uint256)) public epochTracking;
	mapping(address => mapping(bytes32 => mapping(address => mapping(uint256 => mapping(uint256 => uint256))))) public epochClaimBitMap;

	mapping(address => mapping(bytes32 => mapping(address => uint256))) public circleAlloc;

	// checkpoints following this mapping:
	// circle => token => address => checkpoint
	mapping(address => mapping(bytes32 => mapping(address => mapping(address => uint256)))) public checkpoints;

	event AdminApproved(address indexed vault, bytes32 indexed circle, address indexed admin);

	event Claimed(address vault, bytes32 circle, address token, uint256 epoch, uint256 index, address account, uint256 amount);
	
	event EpochFunded(address indexed vault, bytes32 indexed circle, address indexed token, uint256 epochId, uint8 _tapType, uint256 amount);

	event yearnApeVaultFundsTapped(address indexed apeVault, address yearnVault, uint256 amount);

	constructor(address _registry) {
		registry = _registry;
	}

	function _tap(
		address _vault,
		bytes32 _circle,
		address _token,
		uint256 _amount,
		uint8 _tapType,
		bytes32 _root
	) internal {
		require(ApeVaultFactory(ApeRegistry(registry).factory()).vaultRegistry(_vault), "ApeDistributor: Vault does not exist");
		bool isOwner = ApeVaultWrapperImplementation(_vault).owner() == msg.sender;
		require(vaultApprovals[_vault][_circle] == msg.sender || isOwner, "ApeDistributor: Sender not approved");
		
		if (_tapType == uint8(2))
			require(address(ApeVaultWrapperImplementation(_vault).simpleToken()) == _token, "ApeDistributor: Vault cannot supply token");
		else
			require(address(ApeVaultWrapperImplementation(_vault).vault()) == _token, "ApeDistributor: Vault cannot supply token");
			
		if (!isOwner)
			_isTapAllowed(_vault, _circle, _token, _amount);
		
		uint256 beforeBal = IERC20(_token).balanceOf(address(this));
		uint256 sharesRemoved = ApeVaultWrapperImplementation(_vault).tap(_amount, _tapType);
		uint256 afterBal = IERC20(_token).balanceOf(address(this));
		require(afterBal - beforeBal == _amount, "ApeDistributor: Did not receive correct amount of tokens");

		if (sharesRemoved > 0)
			emit yearnApeVaultFundsTapped(_vault, address(ApeVaultWrapperImplementation(_vault).vault()), sharesRemoved);
		
		uint256 epoch = epochTracking[_circle][_token];
		epochRoots[_vault][_circle][_token][epoch] = _root;
		epochTracking[_circle][_token]++;

		emit EpochFunded(_vault, _circle, _token, epoch, _tapType, _amount);
	}

	/**  
	 * @notice
	 * Used to allow a circle to supply an epoch with funds from a given ape vault
	 * @param _vault Address of ape vault from which to take funds from
	 * @param _circle Circle ID querying the funds
	 * @param _token Address of the token to withdraw from the vault
	 * @param _root Merkle root of the current circle's epoch
	 * @param _amount Amount of tokens to withdraw
	 * @param _tapType Ape vault's type tap (pure profit, mixed, simple token)
	 */
	function uploadEpochRoot(
		address _vault,
		bytes32 _circle,
		address _token,
		bytes32 _root,
		uint256 _amount,
		uint8 _tapType)
		external {
		_tap(_vault, _circle, _token, _amount, _tapType, _root);

		circleAlloc[_vault][_circle][_token] += _amount;
	}

	function sum(uint256[] calldata _vals) internal pure returns(uint256 res) {
		for (uint256 i = 0; i < _vals.length; i++)
			res += _vals[i];
	}

	/**  
	* @notice
	* Used to distribute funds from an epoch directly to users
	* @param _vault Address of ape vault from which to take funds from
	* @param _circle Circle ID querying the funds
	* @param _token Address of the token to withdraw from the vault
	* @param _users Users to receive tokens
	* @param _amounts Tokens to give per user
	* @param _amount Amount of tokens to withdraw
	* @param _tapType Ape vault's type tap (pure profit, mixed, simple token)
	*/
	function tapEpochAndDistribute(
		address _vault,
		bytes32 _circle,
		address _token,
		address[] calldata _users,
		uint256[] calldata _amounts,
		uint256 _amount,
		uint8 _tapType)
		external {
		require(_users.length == _amounts.length, "ApeDistributor: Array lengths do not match");
		require(sum(_amounts) == _amount, "ApeDistributor: Amount does not match sum of values");

		_tap(_vault, _circle, _token, _amount, _tapType, bytes32(type(uint256).max));

		for (uint256 i = 0; i < _users.length; i++)
			IERC20(_token).safeTransfer(_users[i], _amounts[i]);
	}

	/**  
	 * @notice
	 * Used to allow an ape vault owner to set an admin for a circle
	 * @param _circle Circle ID of future admin
	 * @param _admin Address of allowed admin to call `uploadEpochRoot`
	 */
	function updateCircleAdmin(bytes32 _circle, address _admin) external {
		vaultApprovals[msg.sender][_circle] = _admin;
		emit AdminApproved(msg.sender, _circle, _admin);
	}

	function isClaimed(address _vault, bytes32 _circle, address _token, uint256 _epoch, uint256 _index) public view returns(bool) {
		uint256 wordIndex = _index / 256;
		uint256 bitIndex = _index % 256;
		uint256 word = epochClaimBitMap[_vault][_circle][_token][_epoch][wordIndex];
		uint256 bitMask = 1 << bitIndex;
		return word & bitMask == bitMask;
	}

	function _setClaimed(address _vault, bytes32 _circle, address _token, uint256 _epoch, uint256 _index) internal {
		uint256 wordIndex = _index / 256;
		uint256 bitIndex = _index % 256;
		epochClaimBitMap[_vault][_circle][_token][_epoch][wordIndex] |= 1 << bitIndex;
	}

	/**  
	 * @notice
	 * Used to allow circle users to claim their allocation of a given epoch
	 * @param _circle Circle ID of the user
	 * @param _token Address of token claimed
	 * @param _epoch Epoch ID associated to the claim
	 * @param _index Position of user's address in the merkle tree
	 * @param _account Address of user
	 * @param _checkpoint Total amount of tokens claimed by user (enables to claim multiple epochs at once)
	 * @param _redeemShares Boolean to allow user to redeem underlying tokens of a yearn vault (prerequisite: _token must be a yvToken)
	 * @param _proof Merkle proof to verify user is entitled to claim
	 */
	function claim(address _vault, bytes32 _circle, address _token, uint256 _epoch, uint256 _index, address _account, uint256 _checkpoint, bool _redeemShares, bytes32[] memory _proof) public {
		require(!isClaimed(_vault, _circle, _token, _epoch, _index), "Claimed already");
		bytes32 node = keccak256(abi.encodePacked(_index, _account, _checkpoint));
		require(_proof.verify(epochRoots[_vault][_circle][_token][_epoch], node), "Wrong proof");
		uint256 currentCheckpoint = checkpoints[_vault][_circle][_token][_account];
		require(_checkpoint > currentCheckpoint, "Given checkpoint not higher than current checkpoint");

		uint256 claimable = _checkpoint - currentCheckpoint;
		require(claimable <= circleAlloc[_vault][_circle][_token], "Can't claim more than circle has to give");
		circleAlloc[_vault][_circle][_token] -= claimable;
		checkpoints[_vault][_circle][_token][_account] = _checkpoint;
		_setClaimed(_vault, _circle, _token, _epoch, _index);
		if (_redeemShares && msg.sender == _account)
			VaultAPI(_token).withdraw(claimable, _account);
		else
			IERC20(_token).safeTransfer(_account, claimable);
		emit Claimed(_vault, _circle, _token, _epoch, _index, _account, claimable);
	}

	/**
	 * @notice
	 * Used to allow circle users to claim many tokens at once if applicable
	 * Operated similarly to the `claim` function but due to "Stack too deep errors",
	 * input data was concatenated into similar typed arrays
	 * @param _claims Array of ClaimData objects to claim tokens of users
	 */
	function claimMany(ClaimData[] memory _claims) external {
		for(uint256 i = 0; i < _claims.length; i++) {
			claim(
				_claims[i].vault,
				_claims[i].circle,
				_claims[i].token,
				_claims[i].epoch,
				_claims[i].index,
				_claims[i].account,
				_claims[i].checkpoint,
				_claims[i].redeemShare,
				_claims[i].proof
				);
		}
	}
}