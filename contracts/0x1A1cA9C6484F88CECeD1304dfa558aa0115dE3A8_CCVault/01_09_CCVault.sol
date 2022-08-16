// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";
import "../EthereumContracts/contracts/interfaces/IERC721.sol";
import "../EthereumContracts/contracts/interfaces/IERC721Receiver.sol";
import "../EthereumContracts/contracts/interfaces/IERC1155.sol";
import "../EthereumContracts/contracts/interfaces/IERC1155Receiver.sol";
import "../EthereumContracts/contracts/utils/IOwnable.sol";
import "../EthereumContracts/contracts/utils/IPausable.sol";

contract CCCOIN {
  event Transfer( address indexed from, address indexed to, uint256 value );
  event Approval( address indexed owner, address indexed spender, uint256 value );
  function totalSupply() external view returns ( uint256 ) {}
  function balanceOf( address account ) external view returns ( uint256 ) {}
  function transfer( address recipient, uint256 amount ) external returns ( bool ) {}
  function allowance( address owner, address spender ) external view returns ( uint256 ) {}
  function approve( address spender, uint256 amount ) external returns ( bool ) {}
  function transferFrom( address sender, address recipient, uint256 amount ) external returns ( bool ) {}
  
  //proxy access functions:
  function isProxy( address checkProxy ) external view returns ( bool ) {}
  function proxyMint( address reciever, uint256 amount ) public {}
  function proxyBurn( address sender, uint256 amount ) public {}
  function proxyTransfer( address from, address to, uint256 amount ) public {}
}

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@/      \@@@@/      \@@@@  @@@@@@@@@@  @@@@@@@@@@         \@@/      \@@          @@/      \@@@@@       \@@@@/      \@@
// @@@@@  /@@@@  @@@  /@@@@  @@@  @@@@@@@@@@  @@@@@@@@@@  @@@@@@@@@@  /@@@@  @@@@@  @@@@@@  /@@@@  @@@@  @@@@@  @@@  /@@@@  @@
// @@@@  @@@@@@@@@@  @@@@@@  @@  @@@@@@@@@@  @@@@@@@@@@  @@@@@@@@@@  @@@@@@@@@@@@  @@@@@@  @@@@@@  @@@  @@@@/  @@@  @@@@@@@@@@
// @@@  @@@@@@@@@@  @@@@@@  @@  @@@@@@@@@@  @@@@@@@@@@        @@@@  @@@@@@@@@@@@  @@@@@@  @@@@@@  @@@        /@@@@\      \@@@@
// @@  @@@@@@@@@@  @@@@@@  @@  @@@@@@@@@@  @@@@@@@@@@  @@@@@@@@@@  @@@@@@@@@@@@  @@@@@@  @@@@@@  @@@  @@@  @@@@@@@@@@@@@  @@@@
// @@  @@@@   @@@  @@@@   @@  @@@@@@@@@@  @@@@@@@@@@  @@@@@@@@@@@  @@@@   @@@@  @@@@@@@  @@@@   @@@  @@@@@  @@@@  @@@@/  @@@@@
// @@\      /@@@@\      /@@          @@          @@\         @@@@\      /@@@@  @@@@@@@@\      /@@@  @@@@@@  @@@@\      /@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@  @@    @@@@@@@@  @@@@@@  @@  @@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@  @@  @  @@@@@@@  @@@@@@  @@  @@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@  @@  @@  @@@@@@  @@@@@@  @@  @@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@  @@  @@@  @@@@@  @@@@@@  @@  @@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@  @@        @@@@  @@@@@@  @@  @@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @  @@  @@@@@  @@@  @@@@@@  @@  @@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@  @@@@@@  @@          @@          @@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

contract CCVault is Context, IOwnable, IERC721Receiver, IERC1155Receiver, IPausable {
	error CCVault_ARRAY_LENGTH_MISMATCH();
	error CCVault_INVALID_CONTRACT( address contractAddress );
	error CCVault_INSUFFICIENT_CRYSTAL_BALANCE( uint256 seriesId, uint256 amountRequested );
	error CCVault_INSUFFICIENT_BALANCE( address contractAddress );
	error CCVault_INSUFFICIENT_REWARDS( uint256 amountRequested, uint256 amountAvailable );
	error CCVault_NONEXISTANT_CRYSTAL( uint256 seriesId );
	error CCVault_NO_PROXY_ACCESS( address contractAddress );
	error CCVault_NO_REWARDS_EARNED( address tokenOwner );
	error CCVault_TOKEN_ALREADY_STAKED( uint256 tokenId );
	error CCVault_TOKEN_NOT_OWNED( address contractAddress, uint256 tokenId );
	error CCVault_TOKEN_NOT_STAKED( address contractAddress, uint256 tokenId );
	error CCVault_EMPTY( address tokenOwner );

	struct StakingInfo {
		uint256 lastUpdate;
		uint256 key;
		uint256 tier1;
		uint256 tier2;
		uint256 tier3;
		uint256 degen;
		uint256 partner;
		uint256 rewardsEarned;
	}

	struct stakedNFT {
		address contractAddress;
		uint256 tokenId;
	}

	uint constant DAY = 86400;

	// Staking rewards in tokens per second
	uint256  public KEY_REWARD;
	uint256  public DEGEN_REWARD;
	uint256  public PARTNER_REWARD;

	CCCOIN   public COIN_CONTRACT;
	IERC1155 public CRYSTAL_CONTRACT;

	// Multipliers, expressed in percentage, with base 1000:
	// one crystal can only be applied to one key at a time, 
	// and one key can only be applied one crystal at a time
	mapping( uint256 => uint256 ) public CRYSTAL_MULTIPLIER;

	// Wallet address mapped to staking info
	mapping ( address => StakingInfo ) public stakingInfo;

	// Wallet address mapped to a dynamic array of staked tokens
	mapping ( address => stakedNFT[] ) public stakeNFTWallets;

	// Mappings to verify stakable contracts.
	mapping ( address => bool ) public keyContracts;
	mapping ( address => bool ) public degenContracts;
	mapping ( address => bool ) public partnerContracts;

	constructor() {
		_initIOwnable( _msgSender() );

		KEY_REWARD              = 250 * ( 10 ** 15 );
		DEGEN_REWARD            =  10 * ( 10 ** 15 );
		PARTNER_REWARD          = 100 * ( 10 ** 15 );
		CRYSTAL_MULTIPLIER[ 1 ] = 4000;
		CRYSTAL_MULTIPLIER[ 2 ] = 2500;
		CRYSTAL_MULTIPLIER[ 3 ] = 2000;
	}

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function executing the staking of an NFT.
		* 
		* @param tokenOwner_      ~ type = address : the owner of the NFT
		* @param contractAddress_ ~ type = address : the contract that manages the NFT
		* @param tokenId_         ~ type = uint256 : the NFT's token ID
		*/
		function _stakeNFT( address tokenOwner_, address contractAddress_, uint256 tokenId_ ) private {
			IERC721 NFTcontract = IERC721( contractAddress_ );
			if ( ! NFTcontract.isApprovedForAll( tokenOwner_, address( this ) ) ) {
				revert CCVault_NO_PROXY_ACCESS( contractAddress_ );
			}
			if ( NFTcontract.ownerOf( tokenId_ ) != tokenOwner_ ) {
				revert CCVault_TOKEN_NOT_OWNED( contractAddress_, tokenId_ );
			}

			stakeNFTWallets[ tokenOwner_ ].push( stakedNFT( contractAddress_, tokenId_ ) );
			NFTcontract.transferFrom( tokenOwner_, address( this ), tokenId_ );
		}

		/**
		* @dev Internal function to unstake a specific NFT.
		* 
		* @param tokenOwner_      ~ type = address : the owner of the NFT
		* @param contractAddress_ ~ type = address : the contract that manages the NFT
		* @param tokenId_         ~ type = uint256 : the NFT's token ID
		*/
		function _unstakeNFT( address tokenOwner_, address contractAddress_, uint256 tokenId_ ) private {
			uint256 _index_ = stakeNFTWallets[ tokenOwner_ ].length;
			while ( _index_ > 0 ) {
				unchecked {
					_index_ --;
				}

				if ( stakeNFTWallets[ tokenOwner_ ][ _index_ ].contractAddress == contractAddress_
					&& stakeNFTWallets[ tokenOwner_ ][ _index_ ].tokenId         == tokenId_ ) {
					_unstakeNFTatIndex( tokenOwner_, _index_ );
					return;
				}
			}
			revert CCVault_TOKEN_NOT_STAKED( contractAddress_, tokenId_ );
		}

		/**
		* @dev Internal function executing the unstaking of an NFT.
		* 
		* @param tokenOwner_      ~ type = address : the owner of the NFT
		* @param index_           ~ type = uint256 : the index of the NFT
		*/
		function _unstakeNFTatIndex( address tokenOwner_, uint256 index_ ) private {
			uint256 _totalStaked_ = stakeNFTWallets[ tokenOwner_ ].length;
			address _contractAddress_ = stakeNFTWallets[ tokenOwner_ ][ index_ ].contractAddress;
			uint256 _tokenId_ = stakeNFTWallets[ tokenOwner_ ][ index_ ].tokenId;
			IERC721 NFTcontract = IERC721( _contractAddress_ );
			if ( NFTcontract.ownerOf( _tokenId_ ) != address( this ) ) {
				revert CCVault_TOKEN_NOT_STAKED( _contractAddress_, _tokenId_ );
			}

			if ( index_ + 1 != _totalStaked_ ) {
				stakeNFTWallets[ tokenOwner_ ][ index_ ] = stakeNFTWallets[ tokenOwner_ ][ _totalStaked_ - 1 ];
			}
			stakeNFTWallets[ tokenOwner_ ].pop();
			NFTcontract.transferFrom( address( this ), tokenOwner_, _tokenId_ );
		}

		/**
		* @dev Internal function executing the staking of a crystal.
		* 
		* @param tokenOwner_      ~ type = address : the owner of the NFT
		* @param tier_            ~ type = uint256 : the crystal series
		* @param amount_          ~ type = uint256 : the amount of crystals to be staked
		*/
		function _stakeCrystal( address tokenOwner_, uint256 tier_, uint256 amount_ ) private {
			if ( ! CRYSTAL_CONTRACT.isApprovedForAll( tokenOwner_, address( this ) ) ) {
				revert CCVault_NO_PROXY_ACCESS( address( CRYSTAL_CONTRACT ) );
			}
			if ( CRYSTAL_CONTRACT.balanceOf( tokenOwner_, tier_ ) < amount_ ) {
				revert CCVault_INSUFFICIENT_CRYSTAL_BALANCE( tier_, amount_ );
			}
			CRYSTAL_CONTRACT.safeTransferFrom( tokenOwner_, address( this ), tier_, amount_, "" );
		}

		/**
		* @dev Internal function executing the staking of a crystal.
		* 
		* @param tokenOwner_      ~ type = address : the owner of the NFT
		* @param tier_            ~ type = uint256 : the crystal series
		* @param amount_          ~ type = uint256 : the amount of crystals to be unstaked
		*/
		function _unstakeCrystal( address tokenOwner_, uint256 tier_, uint256 amount_ ) private {
			if ( CRYSTAL_CONTRACT.balanceOf( address( this ), tier_ ) < amount_ ) {
				revert CCVault_INSUFFICIENT_CRYSTAL_BALANCE( tier_, amount_ );
			}
			CRYSTAL_CONTRACT.safeTransferFrom( address( this ), tokenOwner_, tier_, amount_, "" );
		}

		/**
		* @dev Internal function that updates the staking info for the given user.
		* 
		* @param tokenOwner_      ~ type = address : the owner of the NFTs
		* @param key_             ~ type = uint256 : the number of keys staked, regardless of their contract
		* @param tier1_           ~ type = uint256 : the amount of tier1 crystals staked
		* @param tier2_           ~ type = uint256 : the amount of tier2 crystals staked
		* @param tier3_           ~ type = uint256 : the amount of tier3 crystals staked
		* @param degen_           ~ type = uint256 : the number of degen tokens staked, regardless of their contract
		* @param partner_         ~ type = uint256 : the number of partner tokens staked, regardless of their contract
		*/
		function _updateStakingInfo( address tokenOwner_, uint256 key_, uint256 tier1_, uint256 tier2_, uint256 tier3_, uint256 degen_, uint256 partner_ ) private {
			StakingInfo storage _stakingInfo_ = stakingInfo[ tokenOwner_ ];
			if ( _stakingInfo_.key != key_ ) {
				_stakingInfo_.key = key_;
			}
			if ( _stakingInfo_.tier1 != tier1_ ) {
				_stakingInfo_.tier1 = tier1_;
			}
			if ( _stakingInfo_.tier2 != tier2_ ) {
				_stakingInfo_.tier2 = tier2_;
			}
			if ( _stakingInfo_.tier3 != tier3_ ) {
				_stakingInfo_.tier3 = tier3_;
			}
			if ( _stakingInfo_.degen != degen_ ) {
				_stakingInfo_.degen = degen_;
			}
			if ( _stakingInfo_.partner != partner_ ) {
				_stakingInfo_.partner = partner_;
			}
			_updateRewards( tokenOwner_ );
		}

		/**
		* @dev Internal function that updates the rewards and timestamp for a given account.
		* 
		* @param tokenOwner_      ~ type = address : the owner of the NFTs
		*/
		function _updateRewards( address tokenOwner_ ) private {
			StakingInfo storage _stakingInfo_ = stakingInfo[ tokenOwner_ ];
			_stakingInfo_.rewardsEarned = _totalRewards( tokenOwner_ );
			if ( _stakingInfo_.lastUpdate != block.timestamp ) {
				_stakingInfo_.lastUpdate = block.timestamp;
			}
		}

		/**
		* @dev Internal function that spends rewards for a given account.
		* 
		* @param tokenOwner_      ~ type = address : the owner of the NFTs
		* @param amountSpent_     ~ type = uint256 : the amount of rewards spent
		*/
		function _spendRewards( address tokenOwner_, uint256 amountSpent_ ) private {
			uint256 _totalRewards_ = _totalRewards( tokenOwner_ );
			if ( _totalRewards_ < amountSpent_ ) {
				revert CCVault_INSUFFICIENT_REWARDS( amountSpent_, _totalRewards_ );
			}

			StakingInfo storage _stakingInfo_ = stakingInfo[ tokenOwner_ ];
			unchecked {
				_stakingInfo_.rewardsEarned = _totalRewards_ - amountSpent_;
			}
			if ( _stakingInfo_.lastUpdate != block.timestamp ) {
				_stakingInfo_.lastUpdate = block.timestamp;
			}
		}

		/**
		* @dev Internal function that calculates and returns the amount of rewards earned by `tokenOwner_` so far.
		* 
		* @param tokenOwner_      ~ type = address : the owner of the NFTs
		*/
		function _totalRewards( address tokenOwner_ ) private view returns ( uint256 ) {
			uint256 _totalRewards_;
			StakingInfo memory _stakingInfo_ = stakingInfo[ tokenOwner_ ];
			if ( _stakingInfo_.lastUpdate != 0 ) {
				uint256 _timeDiff_;
				uint256 _unclaimedRewards_;
				_totalRewards_ = _stakingInfo_.rewardsEarned;

				if ( block.timestamp > _stakingInfo_.lastUpdate ) {
					unchecked {
						_timeDiff_ = block.timestamp - _stakingInfo_.lastUpdate;
						_unclaimedRewards_ = rewardsPerSecond( tokenOwner_ ) * _timeDiff_;
						_totalRewards_ += _unclaimedRewards_;
					}
				}
			}
			return _totalRewards_;
		}
	// **************************************

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		/**
		* @dev Stake several token types for the caller
		* 
		* @param contractAddresses_ ~ type = address[] : an array of contract addresses
		* @param tokenIds_          ~ type = uint256[] : an array of token IDs
		*/
		function bulkStake( address[] memory contractAddresses_, uint256[] memory tokenIds_ ) public {
			uint256 _index_ = contractAddresses_.length;
			if ( _index_ != tokenIds_.length ) {
				revert CCVault_ARRAY_LENGTH_MISMATCH();
			}
			address _tokenOwner_ = _msgSender();

			uint256 _key_     = stakingInfo[ _tokenOwner_ ].key;
			uint256 _tier1_   = stakingInfo[ _tokenOwner_ ].tier1;
			uint256 _tier2_   = stakingInfo[ _tokenOwner_ ].tier2;
			uint256 _tier3_   = stakingInfo[ _tokenOwner_ ].tier3;
			uint256 _degen_   = stakingInfo[ _tokenOwner_ ].degen;
			uint256 _partner_ = stakingInfo[ _tokenOwner_ ].partner;

			while ( _index_ > 0 ) {
				unchecked {
					_index_ --;
				}
				if ( keyContracts[ contractAddresses_[ _index_ ] ] ) {
					unchecked {
						_key_ ++;
					}
				}
				else if ( degenContracts[ contractAddresses_[ _index_ ] ] ) {
					unchecked {
						_degen_ ++;
					}
				}
				else if ( partnerContracts[ contractAddresses_[ _index_ ] ] ) {
					unchecked {
						_partner_ ++;
					}
				}
				else {
					// Skip if contract is invalid
					continue;
				}
				_stakeNFT( _tokenOwner_, contractAddresses_[ _index_ ], tokenIds_[ _index_ ] );
			}
			_updateStakingInfo( _tokenOwner_, _key_, _tier1_, _tier2_, _tier3_, _degen_, _partner_ );
		}

		/**
		* @dev Stake an ERC721 token for the caller.
		* 
		* @param contractAddress_ ~ type = address : the contract that manages the NFT
		* @param tokenId_         ~ type = uint256 : the NFT's token ID
		*/
		function stakeNFT( address contractAddress_, uint256 tokenId_ ) public {
			address _tokenOwner_ = _msgSender();

			uint256 _key_     = stakingInfo[ _tokenOwner_ ].key;
			uint256 _tier1_   = stakingInfo[ _tokenOwner_ ].tier1;
			uint256 _tier2_   = stakingInfo[ _tokenOwner_ ].tier2;
			uint256 _tier3_   = stakingInfo[ _tokenOwner_ ].tier3;
			uint256 _degen_   = stakingInfo[ _tokenOwner_ ].degen;
			uint256 _partner_ = stakingInfo[ _tokenOwner_ ].partner;

			if ( keyContracts[ contractAddress_ ] ) {
				unchecked {
					_key_ ++;
				}
			}
			else if ( degenContracts[ contractAddress_ ] ) {
				unchecked {
					_degen_ ++;
				}
			}
			else if ( partnerContracts[ contractAddress_ ] ) {
				unchecked {
					_partner_ ++;
				}
			}
			else {
				revert CCVault_INVALID_CONTRACT( contractAddress_ );
			}

			_stakeNFT( _tokenOwner_, contractAddress_, tokenId_ );
			_updateStakingInfo( _tokenOwner_, _key_, _tier1_, _tier2_, _tier3_, _degen_, _partner_ );
		}

		/**
		* @dev Stake `amount_` crystals of series `tier_` for the caller.
		* 
		* @param tier_            ~ type = uint256 : the crystal series
		* @param amount_          ~ type = uint256 : the amount of crystals to be staked
		*/
		function stakeCrystal( uint256 tier_, uint256 amount_ ) public {
			address _tokenOwner_ = _msgSender();

			uint256 _key_     = stakingInfo[ _tokenOwner_ ].key;
			uint256 _tier1_   = stakingInfo[ _tokenOwner_ ].tier1;
			uint256 _tier2_   = stakingInfo[ _tokenOwner_ ].tier2;
			uint256 _tier3_   = stakingInfo[ _tokenOwner_ ].tier3;
			uint256 _degen_   = stakingInfo[ _tokenOwner_ ].degen;
			uint256 _partner_ = stakingInfo[ _tokenOwner_ ].partner;

			if ( tier_ == 1 ) {
				unchecked {
					_tier1_ += amount_;
				}
			}
			else if ( tier_ == 2 ) {
				unchecked {
					_tier2_ += amount_;
				}
			}
			else if ( tier_ == 3 ) {
				unchecked {
					_tier3_ += amount_;
				}
			}
			else {
				revert CCVault_NONEXISTANT_CRYSTAL( tier_ );
			}

			_stakeCrystal( _tokenOwner_, tier_, amount_ );
			_updateStakingInfo( _tokenOwner_, _key_, _tier1_, _tier2_, _tier3_, _degen_, _partner_ );
		}

		/**
		* @dev Unstake several token types for the caller
		* 
		* @param contractAddresses_ ~ type = address[] : an array of contract addresses
		* @param tokenIds_          ~ type = uint256[] : an array of token IDs
		* 
		* Requirements:
		* - Contract state is OPEN
		*/
		function bulkUnstake( address[] memory contractAddresses_, uint256[] memory tokenIds_ ) public isOpen {
			uint256 _index_ = contractAddresses_.length;
			if ( _index_ != tokenIds_.length ) {
				revert CCVault_ARRAY_LENGTH_MISMATCH();
			}
			address _tokenOwner_ = _msgSender();

			uint256 _key_     = stakingInfo[ _tokenOwner_ ].key;
			uint256 _tier1_   = stakingInfo[ _tokenOwner_ ].tier1;
			uint256 _tier2_   = stakingInfo[ _tokenOwner_ ].tier2;
			uint256 _tier3_   = stakingInfo[ _tokenOwner_ ].tier3;
			uint256 _degen_   = stakingInfo[ _tokenOwner_ ].degen;
			uint256 _partner_ = stakingInfo[ _tokenOwner_ ].partner;

			while ( _index_ > 0 ) {
				unchecked {
					_index_ --;
				}
				if ( keyContracts[ contractAddresses_[ _index_ ] ] ) {
					if ( _key_ == 0 ) {
						revert CCVault_INSUFFICIENT_BALANCE( contractAddresses_[ _index_ ] );
					}
					unchecked {
						_key_ --;
					}
				}
				else if ( degenContracts[ contractAddresses_[ _index_ ] ] ) {
					if ( _degen_ == 0 ) {
						revert CCVault_INSUFFICIENT_BALANCE( contractAddresses_[ _index_ ] );
					}
					unchecked {
						_degen_ --;
					}
				}
				else if ( partnerContracts[ contractAddresses_[ _index_ ] ] ) {
					if ( _partner_ == 0 ) {
						revert CCVault_INSUFFICIENT_BALANCE( contractAddresses_[ _index_ ] );
					}
					unchecked {
						_partner_ --;
					}
				}
				else {
					// Skip if contract is invalid
					continue;
				}
				_unstakeNFT( _tokenOwner_, contractAddresses_[ _index_ ], tokenIds_[ _index_ ] );
			}
			_updateStakingInfo( _tokenOwner_, _key_, _tier1_, _tier2_, _tier3_, _degen_, _partner_ );
		}

		/**
		* @dev Unstake all tokens staked by the caller
		* 
		* Requirements:
		* - Contract state is OPEN
		*/
		function unstakeAll() public isOpen {
			address _tokenOwner_ = _msgSender();
			StakingInfo storage _stakingInfo_ = stakingInfo[ _tokenOwner_ ];
			if ( _stakingInfo_.lastUpdate == 0 ) {
				revert CCVault_EMPTY( _tokenOwner_ );
			}

			uint256 _totalStaked_ = stakeNFTWallets[ _tokenOwner_ ].length;
			while ( _totalStaked_ > 0 ) {
				unchecked {
					_totalStaked_ --;
				}
				_unstakeNFTatIndex( _tokenOwner_, _totalStaked_ );
			}
			if ( _stakingInfo_.tier1 > 0 ) {
				_unstakeCrystal( _tokenOwner_, 1, _stakingInfo_.tier1 );
			}
			if ( _stakingInfo_.tier2 > 0 ) {
				_unstakeCrystal( _tokenOwner_, 2, _stakingInfo_.tier2 );
			}
			if ( _stakingInfo_.tier3 > 0 ) {
				_unstakeCrystal( _tokenOwner_, 3, _stakingInfo_.tier3 );
			}

			_updateStakingInfo( _tokenOwner_, 0, 0, 0, 0, 0, 0 );
		}

		/**
		* @dev Unstake all tokens managed by `contractAddress_` staked by the caller
		* 
		* @param contractAddress_ ~ type = address : the contract that manages the tokens
		* 
		* Requirements:
		* - Contract state is OPEN
		*/
		function unstakeCollection( address contractAddress_ ) public isOpen {
			address _tokenOwner_ = _msgSender();
			if ( stakingInfo[ _tokenOwner_ ].lastUpdate == 0 ) {
				revert CCVault_EMPTY( _tokenOwner_ );
			}

			uint256 _key_     = stakingInfo[ _tokenOwner_ ].key;
			uint256 _tier1_   = stakingInfo[ _tokenOwner_ ].tier1;
			uint256 _tier2_   = stakingInfo[ _tokenOwner_ ].tier2;
			uint256 _tier3_   = stakingInfo[ _tokenOwner_ ].tier3;
			uint256 _degen_   = stakingInfo[ _tokenOwner_ ].degen;
			uint256 _partner_ = stakingInfo[ _tokenOwner_ ].partner;

			if ( contractAddress_ == address( CRYSTAL_CONTRACT ) ) {
				if ( _tier1_ > 0 ) {
					_unstakeCrystal( _tokenOwner_, 1, _tier1_ );
				}
				if ( _tier2_ > 0 ) {
					_unstakeCrystal( _tokenOwner_, 2, _tier2_ );
				}
				if ( _tier3_ > 0 ) {
					_unstakeCrystal( _tokenOwner_, 3, _tier3_ );
				}
				_tier1_ = 0;
				_tier2_ = 0;
				_tier3_ = 0;
			}
			else {
				if ( keyContracts[ contractAddress_ ] ) {
					_key_ = 0;
				}
				else if ( degenContracts[ contractAddress_ ] ) {
					_degen_ = 0;
				}
				else if ( partnerContracts[ contractAddress_ ] ) {
					_partner_ = 0;
				}
				else {
					revert CCVault_INVALID_CONTRACT( contractAddress_ );
				}

				uint256 _totalStaked_ = stakeNFTWallets[ _tokenOwner_ ].length;
				while ( _totalStaked_ > 0 ) {
					unchecked {
						_totalStaked_ --;
					}
					if ( stakeNFTWallets[ _tokenOwner_ ][ _totalStaked_ ].contractAddress == contractAddress_ ) {
						_unstakeNFTatIndex( _tokenOwner_, _totalStaked_ );
					}
				}
			}
			_updateStakingInfo( _tokenOwner_, _key_, _tier1_, _tier2_, _tier3_, _degen_, _partner_ );
		}

		/**
		* @dev Unstake an ERC721 token for the caller.
		* 
		* @param contractAddress_ ~ type = address : the contract that manages the NFT
		* @param tokenId_         ~ type = uint256 : the NFT's token ID
		* 
		* Requirements:
		* - Contract state is OPEN
		*/
		function unstakeNFT( address contractAddress_, uint256 tokenId_ ) public isOpen {
			address _tokenOwner_ = _msgSender();

			uint256 _key_     = stakingInfo[ _tokenOwner_ ].key;
			uint256 _tier1_   = stakingInfo[ _tokenOwner_ ].tier1;
			uint256 _tier2_   = stakingInfo[ _tokenOwner_ ].tier2;
			uint256 _tier3_   = stakingInfo[ _tokenOwner_ ].tier3;
			uint256 _degen_   = stakingInfo[ _tokenOwner_ ].degen;
			uint256 _partner_ = stakingInfo[ _tokenOwner_ ].partner;

			if ( keyContracts[ contractAddress_ ] ) {
				if ( _key_ == 0 ) {
					revert CCVault_INSUFFICIENT_BALANCE( contractAddress_ );
				}
				unchecked {
					_key_ --;
				}
			}
			else if ( degenContracts[ contractAddress_ ] ) {
				if ( _degen_ == 0 ) {
					revert CCVault_INSUFFICIENT_BALANCE( contractAddress_ );
				}
				unchecked {
					_degen_ --;
				}
			}
			else if ( partnerContracts[ contractAddress_ ] ) {
				if ( _partner_ == 0 ) {
					revert CCVault_INSUFFICIENT_BALANCE( contractAddress_ );
				}
				unchecked {
					_partner_ --;
				}
			}
			else {
				revert CCVault_INVALID_CONTRACT( contractAddress_ );
			}

			_unstakeNFT( _tokenOwner_, contractAddress_, tokenId_ );
			_updateStakingInfo( _tokenOwner_, _key_, _tier1_, _tier2_, _tier3_, _degen_, _partner_ );
		}

		/**
		* @dev Unstake `amount_` crystals of series `tier_` for the caller.
		* 
		* @param tier_            ~ type = uint256 : the crystal series
		* @param amount_          ~ type = uint256 : the amount of crystals to be staked
		*/
		function unstakeCrystal( uint256 tier_, uint256 amount_ ) public {
			address _tokenOwner_ = _msgSender();

			uint256 _key_     = stakingInfo[ _tokenOwner_ ].key;
			uint256 _tier1_   = stakingInfo[ _tokenOwner_ ].tier1;
			uint256 _tier2_   = stakingInfo[ _tokenOwner_ ].tier2;
			uint256 _tier3_   = stakingInfo[ _tokenOwner_ ].tier3;
			uint256 _degen_   = stakingInfo[ _tokenOwner_ ].degen;
			uint256 _partner_ = stakingInfo[ _tokenOwner_ ].partner;

			if ( tier_ == 1 ) {
				if ( _tier1_ < amount_ ) {
					revert CCVault_INSUFFICIENT_CRYSTAL_BALANCE( tier_, amount_ );
				}
				unchecked {
					_tier1_ -= amount_;
				}
			}
			else if ( tier_ == 2 ) {
				if ( _tier2_ < amount_ ) {
					revert CCVault_INSUFFICIENT_CRYSTAL_BALANCE( tier_, amount_ );
				}
				unchecked {
					_tier2_ -= amount_;
				}
			}
			else if ( tier_ == 3 ) {
				if ( _tier3_ < amount_ ) {
					revert CCVault_INSUFFICIENT_CRYSTAL_BALANCE( tier_, amount_ );
				}
				unchecked {
					_tier3_ -= amount_;
				}
			}
			else {
				revert CCVault_NONEXISTANT_CRYSTAL( tier_ );
			}

			_unstakeCrystal( _tokenOwner_, tier_, amount_ );
			_updateStakingInfo( _tokenOwner_, _key_, _tier1_, _tier2_, _tier3_, _degen_, _partner_ );
		}

		/**
		* @dev Spend `amountSpent_` amount of rewards for the caller.
		* 
		* @param amountSpent_    ~ type = uint256 : the amount of rewards spent
		*/
		function spendRewards( uint256 amountSpent_ ) public {
			address _tokenOwner_ = _msgSender();
			if ( stakingInfo[ _tokenOwner_ ].lastUpdate == 0 ) {
				revert CCVault_EMPTY( _tokenOwner_ );
			}
			_spendRewards( _tokenOwner_, amountSpent_ );
		}

		/**
		* @dev Claim all rewards earned by the caller.
		*/
		function claimRewards() public {
			if ( ! COIN_CONTRACT.isProxy( address( this ) ) ) {
				revert CCVault_NO_PROXY_ACCESS( address( COIN_CONTRACT ) );
			}
			address _tokenOwner_ = _msgSender();
			StakingInfo storage _stakingInfo_ = stakingInfo[ _tokenOwner_ ];
			if ( _stakingInfo_.lastUpdate == 0 ) {
				revert CCVault_EMPTY( _tokenOwner_ );
			}

			_updateRewards( _tokenOwner_ );
			uint256 _rewardsEarned_ = _stakingInfo_.rewardsEarned;
			if ( _rewardsEarned_ == 0 ) {
				revert CCVault_NO_REWARDS_EARNED( _tokenOwner_ );
			}

			_stakingInfo_.rewardsEarned = 0;
			COIN_CONTRACT.proxyMint( _tokenOwner_, _rewardsEarned_ );
		}
	// **************************************

	// **************************************
	// *****       CONTRACT_OWNER       *****
	// **************************************
		/**
		* @dev Airdrops `amount_` coins to `recipient_`.
		* 
		* @param recipient_        ~ type = address : the address that will receive the coins
		* @param amount_           ~ type = uint256 : the amount of coin the address will receive
		*/
		function airdropCoin( address recipient_, uint256 amount_ ) public onlyOwner {
			if ( ! COIN_CONTRACT.isProxy( address( this ) ) ) {
				revert CCVault_NO_PROXY_ACCESS( address( COIN_CONTRACT ) );
			}
			COIN_CONTRACT.proxyMint( recipient_, amount_ );
		}

		/**
		* @dev Register `contractAddress` as a key collection manager.
		* 
		* @param contractAddress_ ~ type = address : the contract to register
		*/
		function addKeyContract( address contractAddress_ ) public onlyOwner {
			keyContracts[ contractAddress_ ] = true;
		}

		/**
		* @dev Register `contractAddress` as a degen collection manager.
		* 
		* @param contractAddress_ ~ type = address : the contract to register
		*/
		function addDegenContract( address contractAddress_ ) public onlyOwner {
			degenContracts[ contractAddress_ ] = true;
		}

		/**
		* @dev Register `contractAddress` as a partner collection manager.
		* 
		* @param contractAddress_ ~ type = address : the contract to register
		*/
		function addPartnerContract( address contractAddress_ ) public onlyOwner {
			partnerContracts[ contractAddress_ ] = true;
		}

		/**
		* @dev Remove `contractAddress` from the key collection managers.
		* 
		* @param contractAddress_ ~ type = address : the contract to register
		*/
		function removeKeyContract( address contractAddress_ ) public onlyOwner {
			keyContracts[ contractAddress_ ] = false;
		}

		/**
		* @dev Remove `contractAddress` from the degen collection managers.
		* 
		* @param contractAddress_ ~ type = address : the contract to register
		*/
		function removeDegenContract( address contractAddress_ ) public onlyOwner {
			degenContracts[ contractAddress_ ] = false;
		}

		/**
		* @dev Remove `contractAddress` from the partner collection managers.
		* 
		* @param contractAddress_ ~ type = address : the contract to register
		*/
		function removePartnerContract( address contractAddress_ ) public onlyOwner {
			partnerContracts[ contractAddress_ ] = false;
		}

		/**
		* @dev Sets `contractAddress_` as the coin manager.
		* 
		* @param contractAddress_ ~ type = address : the contract to register
		*/
		function setCoinContract( address contractAddress_ ) public onlyOwner {
			COIN_CONTRACT = CCCOIN( contractAddress_ );
		}

		/**
		* @dev Sets `contractAddress_` as the crystal manager.
		* 
		* @param contractAddress_ ~ type = address : the contract to register
		*/
		function setCrystalContract( address contractAddress_ ) public onlyOwner {
			CRYSTAL_CONTRACT = IERC1155( contractAddress_ );
		}

		/**
		* @dev Updates the daily rewards for staking a key.
		* 
		* @param rewards_ ~ type = uint256 : the new daily rewards for staking a key
		*/
		function setKeyRewards( uint256 rewards_ ) public onlyOwner {
			KEY_REWARD = rewards_;
		}

		/**
		* @dev Updates the daily rewards for staking a degen drop.
		* 
		* @param rewards_ ~ type = uint256 : the new daily rewards for staking a degen drop
		*/
		function setDegenRewards( uint256 rewards_ ) public onlyOwner {
			DEGEN_REWARD = rewards_;
		}

		/**
		* @dev Updates the daily rewards for staking a partner drop.
		* 
		* @param rewards_ ~ type = uint256 : the new daily rewards for staking a partner drop
		*/
		function setPartnerRewards( uint256 rewards_ ) public onlyOwner {
			PARTNER_REWARD = rewards_;
		}

		/**
		* @dev Activates or deactivates unstaking, to activate unstaking, set the state to {IPausable.OPEN}.
		* 
		* @param newState_ : the new state of the contract
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function setPauseState( uint8 newState_ ) external onlyOwner {
			_setPauseState( newState_ );
		}

		/**
		* @dev Updates the daily reward multiplier for staking a tier 1 crystal.
		* 
		* @param multiplier_ ~ type = uint256 : the new daily rewards for staking a tier 1 crystal
		*/
		function setTier1Multiplier( uint256 multiplier_ ) public onlyOwner {
			CRYSTAL_MULTIPLIER[ 1 ] = multiplier_;
		}

		/**
		* @dev Updates the daily reward multiplier for staking a tier 2 crystal.
		* 
		* @param multiplier_ ~ type = uint256 : the new daily rewards for staking a tier 2 crystal
		*/
		function setTier2Multiplier( uint256 multiplier_ ) public onlyOwner {
			CRYSTAL_MULTIPLIER[ 2 ] = multiplier_;
		}

		/**
		* @dev Updates the daily reward multiplier for staking a tier 3 crystal.
		* 
		* @param multiplier_ ~ type = uint256 : the new daily rewards for staking a tier 3 crystal
		*/
		function setTier3Multiplier( uint256 multiplier_ ) public onlyOwner {
			CRYSTAL_MULTIPLIER[ 3 ] = multiplier_;
		}
	// **************************************

	// **************************************
	// *****            VIEW            *****
	// **************************************
		/**
		* @dev Returns the number of keys staked by `tokenOwner_`.
		* 
		* Note: We add this function here so that collab.land can grant roles to keyholders who stake their keys.
		*/
		function balanceOf( address tokenOwner_ ) public view returns ( uint256 ) {
			return stakingInfo[ tokenOwner_ ].key;
		}

		/**
		* @dev Returns the list of nfts staked by `tokenOwner_`.
		* 
		* @param tokenOwner_      ~ type = address : the owner of the NFT
		*/
		function nftsOfOwner( address tokenOwner_ ) public view returns ( stakedNFT[] memory ) {
			return stakeNFTWallets[ tokenOwner_ ];
		}

		/**
		* @dev Returns the rewards that `tokenOwner_` earns per second.
		* 
		* @param tokenOwner_      ~ type = address : the owner of the NFT
		*/
		function rewardsPerSecond( address tokenOwner_ ) public view returns ( uint256 ) {
			StakingInfo storage _stakingInfo_ = stakingInfo[ tokenOwner_ ];

			uint256 _tier1_ = _stakingInfo_.tier1;
			uint256 _tier2_ = _stakingInfo_.tier2;
			uint256 _tier3_ = _stakingInfo_.tier3;
			uint256 _reward_;

			uint256 _index_ = _stakingInfo_.key;
			while ( _index_ > 0 ) {
				unchecked {
					_index_ --;
				}
				if ( _tier1_ > 0 ) {
					unchecked {
						_reward_ += KEY_REWARD * ( CRYSTAL_MULTIPLIER[ 1 ] / 1000 ) / DAY;
						_tier1_ --;
					}
				}
				else if ( _tier2_ > 0 ) {
					unchecked {
						_reward_ += KEY_REWARD * ( CRYSTAL_MULTIPLIER[ 2 ] / 1000 ) / DAY;
						_tier2_ --;
					}
				}
				else if ( _tier3_ > 0 ) {
					unchecked {
						_reward_ += KEY_REWARD * ( CRYSTAL_MULTIPLIER[ 3 ] / 1000 ) / DAY;
						_tier3_ --;
					}
				}
				else {
					unchecked {
						_reward_ += KEY_REWARD / DAY;
					}
				}
			}
			unchecked {
				_reward_ += DEGEN_REWARD * _stakingInfo_.degen / DAY;
				_reward_ += PARTNER_REWARD * _stakingInfo_.partner / DAY;
			}

			return _reward_;
		}

		/**
		* @dev Returns the amount of rewards earned by `tokenOwner_` so far.
		* 
		* @param tokenOwner_      ~ type = address : the owner of the NFT
		*/
		function getTotalRewards( address tokenOwner_ ) public view returns ( uint256 ) {
			return _totalRewards( tokenOwner_ );
		}

		/**
		* @dev Allows the contract to manage tokens on behalf of token holders.
		* This function is called as part of the {IERC721.isApprovedForAll}.
		*/
		function proxies( address ) public view returns ( address ) {
			return address( this );
		}

		/**
		* @dev See {IERC165-supportsInterface}.
		*/
		function supportsInterface( bytes4 interfaceId_ ) public view virtual returns ( bool ) {
			return interfaceId_ == type( IERC721Receiver  ).interfaceId ||
						 interfaceId_ == type( IERC1155Receiver ).interfaceId;
		}
	// **************************************

	// **************************************
	// *****            PURE            *****
	// **************************************
		/**
		* @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
		* by `operator` from `from`, this function is called.
		*
		* It must return its Solidity selector to confirm the token transfer.
		* If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
		*
		* The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
		*/
		function onERC721Received( address, address, uint256, bytes calldata ) external pure returns ( bytes4 ) {
			return IERC721Receiver.onERC721Received.selector;
		}

		/**
		* @notice Handle the receipt of a single ERC1155 token type.
		* @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
		* This function MAY throw to revert and reject the transfer.
		* Return of other amount than the magic value MUST result in the transaction being reverted.
		* Note: The token contract address is always the message sender.
		*/
		function onERC1155Received( address, address, uint256, uint256, bytes calldata ) external pure returns ( bytes4 ) {
			return IERC1155Receiver.onERC1155Received.selector;
		}

		/**
		* @notice Handle the receipt of multiple ERC1155 token types.
		* @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
		* This function MAY throw to revert and reject the transfer.
		* Return of other amount than the magic value WILL result in the transaction being reverted.
		* Note: The token contract address is always the message sender.
		*/
		function onERC1155BatchReceived( address, address, uint256[] calldata, uint256[] calldata, bytes calldata ) external pure returns ( bytes4 ) {
			return IERC1155Receiver.onERC1155BatchReceived.selector;
		}
	// **************************************
}