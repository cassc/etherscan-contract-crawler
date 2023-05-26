// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IArrayErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ContractState.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ERC173.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721.sol";
import { FxBaseRootTunnel } from "fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";

contract NuCyberStaking is IArrayErrors, ContractState, ERC173, FxBaseRootTunnel {
	// **************************************
	// *****        CUSTOM TYPES        *****
	// **************************************
		struct StakedToken {
			uint64 tokenId;
			address beneficiary;
		}
	// **************************************

	// **************************************
	// *****           ERRORS           *****
	// **************************************
		/**
		* @dev Thrown when user tries to unstake a token they don't own
		* 
		* @param tokenId the token being unstaked
		*/
		error NCS_TOKEN_NOT_OWNED(uint256 tokenId);
    /**
    * @dev Thrown when trying to stake while rewards are not set
    */
    error NCS_REWARDS_NOT_SET();
	// **************************************

	// **************************************
	// *****           EVENTS           *****
	// **************************************
		/**
		* @dev Emitted when a user sets a beneficiary address
		* 
		* @param tokenId the token being unstaked
		* @param beneficiary the address benefitting from the token
		*/
		event BenefitStarted(uint256 indexed tokenId, address indexed beneficiary);
		/**
		* @dev Emitted when a user sets a beneficiary address
		* 
		* @param tokenId the token being unstaked
		* @param beneficiary the address benefitting from the token
		*/
		event BenefitEnded(uint256 indexed tokenId, address indexed beneficiary);
	// **************************************

  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
    uint8 public constant ACTIVE = 1;
  // **************************************

	// **************************************
	// *****     STORAGE  VARIABLES     *****
	// **************************************
		IERC721 public nuCyber;
		// Wallet address mapped to list of token Ids
		mapping(address => StakedToken[]) private _stakedTokens;
		// Beneficiary wallet address mapped to list of token Ids
		mapping(address => uint256[]) private _benefitTokens;
	// **************************************

	constructor(address nucyberContractAddress_, address cpManager_, address fxRoot_)
  FxBaseRootTunnel(cpManager_, fxRoot_) {
		nuCyber = IERC721(nucyberContractAddress_);
		_setOwner(msg.sender);
	}

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function returning the benefit balance of `account_`.
		* 
		* @param account_ the beneficiary address
		*/
		function _balanceOfBenefit(address account_) internal view returns (uint256) {
			return _benefitTokens[account_].length;
		}
		/**
		* @dev Internal function returning the staking balance of `account_`.
		* 
		* @param account_ the beneficiary address
		*/
		function _balanceOfStaked(address account_) internal view returns (uint256) {
			return _stakedTokens[account_].length;
		}
		/**
		* @dev Internal function that ends a benefit.
		* 
		* @param beneficiary_ the beneficiary address
		* @param tokenId_ the token being unstaked
		* 
		* Requirements:
		* 
		* - Emits a {BenefitEnded} event
		*/
		function _endBenefit(address beneficiary_, uint256 tokenId_) internal {
			uint256 _last_ = _benefitTokens[beneficiary_].length;
			uint256 _count_ = _last_;
			bool _deleted_;
			while(_count_ > 0) {
				unchecked {
					--_count_;
				}
				if (_benefitTokens[beneficiary_][_count_] == tokenId_) {
					if (_count_ != _last_ - 1) {
						_benefitTokens[beneficiary_][_count_] = _benefitTokens[beneficiary_][_last_ - 1];
					}
					_benefitTokens[beneficiary_].pop();
					_deleted_ = true;
				}
			}
			if(! _deleted_) {
				revert NCS_TOKEN_NOT_OWNED(tokenId_);
			}
			emit BenefitEnded(tokenId_, beneficiary_);
		}
		/**
		* @dev Internal function that returns a specific staked token and its index
		* 
		* @param tokenOwner_ the token owner
		* @param tokenId_ the token being unstaked
		* 
		* Requirements:
		* 
		* - `tokenOwner_` must own `tokenId_`
		*/
		function _findToken(address tokenOwner_, uint256 tokenId_) internal view returns (StakedToken memory, uint256) {
			uint256 _count_ = _stakedTokens[tokenOwner_].length;
			while(_count_ > 0) {
				unchecked {
					--_count_;
				}
				if (_stakedTokens[tokenOwner_][_count_].tokenId == tokenId_) {
					return (_stakedTokens[tokenOwner_][_count_], _count_);
				}
			}
			revert NCS_TOKEN_NOT_OWNED(tokenId_);
		}
    /**
    * @dev Internal function to process a message sent by the child contract on Polygon
    * Note: In our situation, we do not expect to receive any message from the child contract.
    * 
    * @param message the message sent by the child contract
    */
    function _processMessageFromChild(bytes memory message) internal override {
      // We don't need a message from child
    }
    /**
    * @dev Internal function to send a message to the child contract on Polygon
    * 
    * @param sender_ the address staking or unstaking one or more token
    * @param amount_ the number of token being staked or unstaked
    * @param isStake_ whether the token are being staked or unstaked
    */
    function _sendMessage(address sender_, uint16 amount_, bool isStake_) internal {
      if (amount_ > 0) {
        _sendMessageToChild(
          abi.encode(sender_, uint8(1), amount_, isStake_)
        );
      }
    }
		/**
		* @dev Internal function that stakes `tokenId_` for `tokenOwner_`.
		* 
		* @param tokenOwner_ the token owner
		* @param tokenId_ the token being staked
		* @param beneficiary_ an address that will benefit from the token being staked
		* 
		* Requirements:
		* 
		* - `tokenOwner_` must own `tokenId_`
		* - This contract must be allowed to transfer NuCyber tokens on behalf of `tokenOwner_`
		* - Emits a {BenefitStarted} event if `beneficiary_` is not null
		*/
		function _stakeToken(address tokenOwner_, uint256 tokenId_, address beneficiary_) internal {
			_stakedTokens[tokenOwner_].push(StakedToken(uint64(tokenId_),beneficiary_));
			if (beneficiary_ != address(0)) {
				_benefitTokens[beneficiary_].push(tokenId_);
				emit BenefitStarted(tokenId_, beneficiary_);
			}
			try nuCyber.transferFrom(tokenOwner_, address(this), tokenId_) {}
			catch Error(string memory reason) {
				revert(reason);
			}
		}
		/**
		* @dev Internal function that unstakes `tokenId_` for `tokenOwner_`.
		* 
		* @param tokenOwner_ the token owner
		* @param tokenId_ the token being unstaked
		* 
		* Requirements:
		* 
		* - `tokenOwner_` must own `tokenId_`
		* - Emits a {BenefitEnded} event if `tokenId_` had a beneficiary
		*/
		function _unstakeToken(address tokenOwner_, uint256 tokenId_) internal {
			uint256 _last_ = _stakedTokens[tokenOwner_].length;
			uint256 _count_ = _last_;
			bool _deleted_;
			while(_count_ > 0) {
				unchecked {
					--_count_;
				}
				if (_stakedTokens[tokenOwner_][_count_].tokenId == tokenId_) {
					address _beneficiary_ = _stakedTokens[tokenOwner_][_count_].beneficiary;
					if(_beneficiary_ != address(0)) {
						_endBenefit(_beneficiary_, tokenId_);
					}
					if (_count_ != _last_ - 1) {
						_stakedTokens[tokenOwner_][_count_] = _stakedTokens[tokenOwner_][_last_ - 1];
					}
					_stakedTokens[tokenOwner_].pop();
					_deleted_ = true;
				}
			}
			if(! _deleted_) {
				revert NCS_TOKEN_NOT_OWNED(tokenId_);
			}
			try nuCyber.transferFrom(address(this), tokenOwner_, tokenId_) {}
			catch Error(string memory reason) {
				revert(reason);
			}
		}
	// **************************************

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		/**
		* @dev Stakes a batch of NuCyber at once.
		* 
		* @param tokenIds_ the tokens being staked
		* @param beneficiaries_ a list of addresses that will benefit from the tokens being staked
		* 
		* Requirements:
		* 
		* - Caller must own all of `tokenIds_`
		* - Emits one or more {BenefitStarted} events if `beneficiaries_` is not null
		* - This contract must be allowed to transfer NuCyber tokens on behalf of the caller
		*/
		function bulkStake(uint256[] memory tokenIds_, address[] memory beneficiaries_) public isState(ACTIVE) {
      if (fxChildTunnel == address(0)) {
        revert NCS_REWARDS_NOT_SET();
      }
			uint256 _len_ = tokenIds_.length;
			if ( beneficiaries_.length != _len_ ) {
				revert ARRAY_LENGTH_MISMATCH();
			}
			while (_len_ > 0) {
				unchecked {
					--_len_;
				}
				_stakeToken(msg.sender, tokenIds_[_len_], beneficiaries_[_len_]);
			}
			_sendMessage(msg.sender, uint16(tokenIds_.length), true);
		}
		/**
		* @dev Unstakes a batch of NuCyber at once.
		* 
		* @param tokenIds_ the tokens being unstaked
		* 
		* Requirements:
		* 
		* - Caller must own all of `tokenIds_`
		* - Emits one or more {BenefitEnded} events if `tokenIds_` had beneficiaries
		*/
		function bulkUnstake(uint256[] memory tokenIds_) public {
			uint256 _len_ = tokenIds_.length;
			while (_len_ > 0) {
				unchecked {
					--_len_;
				}
				_unstakeToken(msg.sender, tokenIds_[_len_]);
			}
			_sendMessage(msg.sender, uint16(tokenIds_.length), false);
		}
		/**
		* @dev Stakes a NuCyber token.
		* 
		* @param tokenId_ the token being staked
		* @param beneficiary_ an address that will benefit from the token being staked
		* 
		* Requirements:
		* 
		* - Caller must own `tokenId_`
		* - Emits a {BenefitStarted} event if `beneficiary_` is not null
		* - This contract must be allowed to transfer NuCyber tokens on behalf of the caller
		*/
		function stake(uint256 tokenId_, address beneficiary_) public isState(ACTIVE) {
      if (fxChildTunnel == address(0)) {
        revert NCS_REWARDS_NOT_SET();
      }
			_stakeToken(msg.sender, tokenId_, beneficiary_);
			_sendMessage(msg.sender, 1, true);
		}
		/**
		* @dev Unstakes a NuCyber token.
		* 
		* @param tokenId_ the token being unstaked
		* 
		* Requirements:
		* 
		* - Caller must own `tokenId_`
		* - Emits a {BenefitEnded} event if `tokenId_` had a beneficiary
		*/
		function unstake(uint256 tokenId_) public {
			_unstakeToken(msg.sender, tokenId_);
			_sendMessage(msg.sender, 1, false);
		}
		/**
		* @dev Updates the beneficiary of a staked token.
		* 
		* @param tokenId_ the staked token
		* @param newBeneficiary_ the address that will benefit from the staked token
		* 
		* Requirements:
		* 
		* - Caller must own `tokenId_`
		* - Emits a {BenefitEnded} event if `tokenId_` had a beneficiary
		* - Emits a {BenefitStarted} event if `newBeneficiary_` is not null
		*/
		function updateBeneficiary(uint256 tokenId_, address newBeneficiary_) public {
			(StakedToken memory _stakedToken_, uint256 _index_) = _findToken(msg.sender, tokenId_);
			_stakedTokens[msg.sender][_index_].beneficiary = newBeneficiary_;
			if (_stakedToken_.beneficiary != address(0)) {
				_endBenefit(_stakedToken_.beneficiary, tokenId_);
			}
			if (newBeneficiary_ != address(0)) {
				_benefitTokens[newBeneficiary_].push(tokenId_);
				emit BenefitStarted(tokenId_, newBeneficiary_);
			}
		}
	// **************************************

	// **************************************
	// *****       CONTRACT OWNER       *****
	// **************************************
		/**
		* @dev Sets the NuCyber contract address
		* 
		* @param contractAddress_ the address of the NuCyber contract
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner
		*/
		function setNuCyberContract(address contractAddress_) external onlyOwner {
			nuCyber = IERC721(contractAddress_);
		}
    /**
    * @dev Updates the contract state.
    * 
    * @param newState_ the new sale state
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newState_` must be a valid state.
    */
		function setContractState(uint8 newState_) external onlyOwner {
      if (newState_ > ACTIVE) {
        revert ContractState_INVALID_STATE(newState_);
      }
      _setContractState(newState_);
		}
    /**
    * @dev Updates the child contract on Polygon
    * 
    * @param fxChildTunnel_ the new child contract on Polygon
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function updateFxChildTunnel(address fxChildTunnel_) external onlyOwner {
      fxChildTunnel = fxChildTunnel_;
    }
	// **************************************

	// **************************************
	// *****            VIEW            *****
	// **************************************
		/**
		* @dev Returns the number oof NuCyber staked and owned by `tokenOwner_`.
		* Note: We need this function for collab.land to successfully give out token ownership roles
		* 
		* @param tokenOwner_ address owning tokens
		*/
		function balanceOf(address tokenOwner_) public view returns (uint256) {
			return nuCyber.balanceOf(tokenOwner_) + _balanceOfStaked(tokenOwner_) + _balanceOfBenefit(tokenOwner_);
		}
		/**
		* @dev Returns the benefit balance of `account_`.
		* 
		* @param account_ the address to check
		*/
		function balanceOfBenefit(address account_) external view returns (uint256) {
			return _balanceOfBenefit(account_);
		}
		/**
		* @dev Returns the staking balance of `account_`.
		* 
		* @param account_ the address to check
		*/
		function balanceOfStaked(address account_) external view returns (uint256) {
			return _balanceOfStaked(account_);
		}
		/**
		* @dev Returns the list of tokens owned by `tokenOwner_`.
		* 
		* @param tokenOwner_ address owning tokens
		*/
		function stakedTokens(address tokenOwner_) public view returns (StakedToken[] memory) {
			return _stakedTokens[tokenOwner_];
		}
	// **************************************
}