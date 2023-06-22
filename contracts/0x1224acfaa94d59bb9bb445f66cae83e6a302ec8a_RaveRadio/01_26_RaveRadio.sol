// SPDX-License-Identifier: MIT LICENSE

/*
                                                                                                                                                                        
RRRRRRRRRRRRRRRRR                                                          FFFFFFFFFFFFFFFFFFFFFF                                                                        
R::::::::::::::::R                                                         F::::::::::::::::::::F                                                                        
R::::::RRRRRR:::::R                                                        F::::::::::::::::::::F                                                                        
RR:::::R     R:::::R                                                       FF::::::FFFFFFFFF::::F                                                                        
  R::::R     R:::::R  aaaaaaaaaaaaavvvvvvv           vvvvvvv eeeeeeeeeeee    F:::::F       FFFFFFaaaaaaaaaaaaa      cccccccccccccccc    eeeeeeeeeeee        ssssssssss   
  R::::R     R:::::R  a::::::::::::av:::::v         v:::::vee::::::::::::ee  F:::::F             a::::::::::::a   cc:::::::::::::::c  ee::::::::::::ee    ss::::::::::s  
  R::::RRRRRR:::::R   aaaaaaaaa:::::av:::::v       v:::::ve::::::eeeee:::::eeF::::::FFFFFFFFFF   aaaaaaaaa:::::a c:::::::::::::::::c e::::::eeeee:::::eess:::::::::::::s 
  R:::::::::::::RR             a::::a v:::::v     v:::::ve::::::e     e:::::eF:::::::::::::::F            a::::ac:::::::cccccc:::::ce::::::e     e:::::es::::::ssss:::::s
  R::::RRRRRR:::::R     aaaaaaa:::::a  v:::::v   v:::::v e:::::::eeeee::::::eF:::::::::::::::F     aaaaaaa:::::ac::::::c     ccccccce:::::::eeeee::::::e s:::::s  ssssss 
  R::::R     R:::::R  aa::::::::::::a   v:::::v v:::::v  e:::::::::::::::::e F::::::FFFFFFFFFF   aa::::::::::::ac:::::c             e:::::::::::::::::e    s::::::s      
  R::::R     R:::::R a::::aaaa::::::a    v:::::v:::::v   e::::::eeeeeeeeeee  F:::::F            a::::aaaa::::::ac:::::c             e::::::eeeeeeeeeee        s::::::s   
  R::::R     R:::::Ra::::a    a:::::a     v:::::::::v    e:::::::e           F:::::F           a::::a    a:::::ac::::::c     ccccccce:::::::e           ssssss   s:::::s 
RR:::::R     R:::::Ra::::a    a:::::a      v:::::::v     e::::::::e        FF:::::::FF         a::::a    a:::::ac:::::::cccccc:::::ce::::::::e          s:::::ssss::::::s
R::::::R     R:::::Ra:::::aaaa::::::a       v:::::v       e::::::::eeeeeeeeF::::::::FF         a:::::aaaa::::::a c:::::::::::::::::c e::::::::eeeeeeee  s::::::::::::::s 
R::::::R     R:::::R a::::::::::aa:::a       v:::v         ee:::::::::::::eF::::::::FF          a::::::::::aa:::a cc:::::::::::::::c  ee:::::::::::::e   s:::::::::::ss  
RRRRRRRR     RRRRRRR  aaaaaaaaaa  aaaa        vvv            eeeeeeeeeeeeeeFFFFFFFFFFF           aaaaaaaaaa  aaaa   cccccccccccccccc    eeeeeeeeeeeeee    sssssssssss    
                                                                                                                                                                         
*/

pragma solidity ^0.8.4;

import "./Rave.sol";
import "./RaveFaces.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract RaveRadio is Ownable, IERC721Receiver {
  // TODO: figoure out a way to limit the number of tokens staked per account to
  // avoid issues with gas when unstake/// @title A title that should describe the contract/interface

  // FIXME: change it to a final one
  // This contract is able to produce a maximum of 45,000,000 RAVES.
  uint256 public MAXIMUM_RAVE_FROM_THE_RADIO_CONTRACT = 45000000 * (10**18);

  // FIXME: THIS IS FOR DEVELOPMENT:
  // uint256 public MAXIMUM_RAVE_FROM_THE_RADIO_CONTRACT = 10 * (10**18);

  // 1 $RAVE per day
  uint256 public EMISSION_PER_DAY = 1 * (10**18);
  uint256 public SECONDS_IN_A_DAY = 86400;
  uint256 public EMISSIONS_RATE_PER_SECONDS =
    EMISSION_PER_DAY / SECONDS_IN_A_DAY;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
  }

  // struct to store the informations of a vault
  // multipliers are in the following format: 100 means 1x; 50 means 0.5x
  struct vaultInfo {
    RaveFaces nft;
    Rave token;
    string name;
    uint256 multiplier;
    uint256 maximumClamable;
    address royalityAddress;
    uint256 royalityPercentage;
  }

  vaultInfo[] public VaultInfo;

  // total number of staked NFTs
  uint256 public totalStaked;

  // stores the amount of total claimed RAVES
  uint256 public totalClaimed;

  // stores the total amount of claimed RAVES per Vault
  mapping(uint256 => uint256) totalClaimedPerVault;

  // stores the total royality earning per Vault
  mapping(uint256 => uint256) totalRoyalityPerVault;

  // stores the total royality Claimed per Vault
  mapping(uint256 => uint256) totalRoyalityClaimedPerVault;

  // vault lock status
  mapping(uint256 => bool) _isVaultLocked;

  // staked NFTs per vault
  mapping(uint256 => mapping(uint256 => Stake)) stakedNFTsPerVault;

  // stores staked NFT ids per vault per address
  mapping(uint256 => mapping(address => uint256[])) internal stakerToTokenIds;

  // events emitted
  event NFTStaked(address owner, uint256 tokenId, uint256 value);
  event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
  event Claimed(address owner, uint256 amount);

  /**
   * @dev     Stores the vault data within this struct. Only owner can call this fuction to add additional vaults.
   * @param   _nft    NFT contract definition
   * @param   _token  ERC20 token contract definition
   * @param   _name   Name of the vault
   */
  function addVault(
    RaveFaces _nft,
    Rave _token,
    uint256 _multiplier,
    string calldata _name,
    uint256 _maximumClamable,
    address _royalityAddress,
    uint256 _royalityPercentage
  ) public onlyOwner {
    VaultInfo.push(
      vaultInfo({
        nft: _nft,
        token: _token,
        multiplier: _multiplier,
        name: _name,
        maximumClamable: _maximumClamable,
        royalityAddress: _royalityAddress,
        royalityPercentage: _royalityPercentage
      })
    );
  }

  /**
   * @notice  Change the multiplier of a vault
   * @param   _pid      Id of the vault
   * @param   _multiplier  the new multiplier
   */

  function changeVaultMultiplier(uint256 _pid, uint256 _multiplier)
    public
    onlyOwner
  {
    require(
      _multiplier <= 1000,
      "multiplier cannot be higher than 10 for a vault"
    );

    vaultInfo storage vaultid = VaultInfo[_pid];
    vaultid.multiplier = _multiplier;
  }

  /**
   * @notice  Change the royality of a vault
   * @param   _pid      Id of the vault
   * @param   _royalityAddress  the recepient address
   * @param   _royalityPercentage the percentage
   */

  function changeVaultRoyality(
    uint256 _pid,
    address _royalityAddress,
    uint256 _royalityPercentage
  ) public onlyOwner {
    require(
      _royalityPercentage <= 1000,
      "percentage cannot be higher than 1000 for a vault"
    ); // which means 100%

    vaultInfo storage vaultid = VaultInfo[_pid];

    vaultid.royalityAddress = _royalityAddress;
    vaultid.royalityPercentage = _royalityPercentage;
  }

  function claimVaultRoyality(uint256 _pid) public {
    vaultInfo storage vaultid = VaultInfo[_pid];

    uint256 vaultRoyalityEarnings = totalRoyalityPerVault[_pid] -
      totalRoyalityClaimedPerVault[_pid];

    if (vaultRoyalityEarnings > 0) {
      totalRoyalityClaimedPerVault[_pid] += vaultRoyalityEarnings;
      vaultid.token.mint(vaultid.royalityAddress, vaultRoyalityEarnings);
    }
  }

  /**
   * @notice  Lock a vault so no more NFTs can be staked there
   * @param   _pid      Id of the vault
   */

  function lockVault(uint256 _pid) public onlyOwner {
    _isVaultLocked[_pid] = true;
  }

  /**
   * @notice  Unlock a vault so no more NFTs can be staked there
   * @param   _pid      Id of the vault
   */

  function unLockVault(uint256 _pid) public onlyOwner {
    _isVaultLocked[_pid] = false;
  }

  /**
   * @notice  Check if the vault is locked or not
   * @param   _pid      Id of the vault
   */

  function isVaultLocked(uint256 _pid) public view returns (bool) {
    return _isVaultLocked[_pid];
  }

  /**
   * @notice  Returns the amount of total claimed tokens from the radio contract
   */

  function getTotalClaimed() public view returns (uint256) {
    return totalClaimed;
  }

  /**
   * @notice  Returns the amount of total claimed tokens from a specific vault
   * @param   _pid      Id of the vault
   */

  function getTotalClaimedFromVault(uint256 _pid)
    public
    view
    returns (uint256)
  {
    return totalClaimedPerVault[_pid];
  }

  /**
   * @notice  Returns the amount of total claimed royality from a specific vault
   * @param   _pid      Id of the vault
   */

  function getTotalRoyalityClaimedFromVault(uint256 _pid)
    public
    view
    returns (uint256)
  {
    return totalRoyalityClaimedPerVault[_pid];
  }

  /**
   * @notice  Returns the amount of total claimed royality from a specific vault
   * @param   _pid      Id of the vault
   */

  function getTotalRoyalityFromVault(uint256 _pid)
    public
    view
    returns (uint256)
  {
    return totalRoyalityPerVault[_pid];
  }

  /**
   * @notice  Returns the amount of clamable royality per vault
   * @param   _pid      Id of the vault
   */

  function getClamableRoyalityFromVault(uint256 _pid)
    public
    view
    returns (uint256)
  {
    return totalRoyalityPerVault[_pid] - totalRoyalityClaimedPerVault[_pid];
  }

  /**
   * @notice  Stake tokens into a vault.
   * @param   _pid      Id of the vault which accepts tokens from a pre-definied NFT collection
   * @param   tokenIds  Ids of tokens to be staked
   */

  function stake(uint256 _pid, uint256[] calldata tokenIds) external {
    require(
      _isVaultLocked[_pid] == false,
      "vault is locked, you can only unstake"
    );

    uint256 tokenId;

    totalStaked += tokenIds.length;

    vaultInfo storage vaultid = VaultInfo[_pid];

    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];

      require(vaultid.nft.ownerOf(tokenId) == msg.sender, "not your token");

      require(stakedNFTsPerVault[_pid][tokenId].tokenId == 0, "already staked");

      vaultid.nft.transferFrom(msg.sender, address(this), tokenId);

      stakerToTokenIds[_pid][msg.sender].push(tokenIds[i]);

      emit NFTStaked(msg.sender, tokenId, block.timestamp);

      stakedNFTsPerVault[_pid][tokenId] = Stake({
        owner: msg.sender,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
    }
  }

  /**
   * @dev  Unstake multiple tokens from a vault
   * @param   account   The address of the staker
   * @param   tokenIds  Ids of tokens to be staked
   * @param   _pid      Id of the vault which accepts tokens from a pre-definied NFT collection
   */
  function _unstakeMany(
    address account,
    uint256[] calldata tokenIds,
    uint256 _pid
  ) internal {
    uint256 tokenId;
    totalStaked -= tokenIds.length;
    vaultInfo storage vaultid = VaultInfo[_pid];
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = stakedNFTsPerVault[_pid][tokenId];
      require(staked.owner == msg.sender, "not an owner");

      delete stakedNFTsPerVault[_pid][tokenId];

      removeTokenIdFromStaker(_pid, msg.sender, tokenId);

      emit NFTUnstaked(account, tokenId, block.timestamp);

      vaultid.nft.transferFrom(address(this), account, tokenId);
    }
  }

  /**
   * @notice  Claim rewards from vault for token ids
   * @param   tokenIds  token ids
   * @param   _pid      vault id
   */
  function claim(uint256 _pid, uint256[] calldata tokenIds) external {
    _claim(msg.sender, tokenIds, _pid, false);
  }

  /**
   * @notice  Makes others to be able to claim the staking rewards for someone else.
   * @param   account   address of the staker
   * @param   tokenIds  token ids
   * @param   _pid      vault id
   */
  function claimForAddress(
    address account,
    uint256[] calldata tokenIds,
    uint256 _pid
  ) external {
    _claim(account, tokenIds, _pid, false);
  }

  /**
   * @notice  Unstake the tokens from a vault
   * @param   _pid      vault id
   * @param   tokenIds  token ids
   */
  function unstake(uint256 _pid, uint256[] calldata tokenIds) external {
    _claim(msg.sender, tokenIds, _pid, true);
  }

  /**
   * @dev     Claim rewards after tokens
   * @param   account   address for the tokens to be minted
   * @param   tokenIds  token ids
   * @param   _pid      vault id
   * @param   _unstake  unstake after claiming
   */
  function _claim(
    address account,
    uint256[] calldata tokenIds,
    uint256 _pid,
    bool _unstake
  ) internal {
    uint256 tokenId;
    uint256 earned = 0;
    uint256 royalityEarned = 0;

    vaultInfo storage vaultid = VaultInfo[_pid];

    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = stakedNFTsPerVault[_pid][tokenId];
      require(staked.owner == account, "not an owner");

      uint256 stakedAt = staked.timestamp;

      earned +=
        ((EMISSIONS_RATE_PER_SECONDS * (block.timestamp - stakedAt)) *
          vaultid.multiplier) /
        100;

      stakedNFTsPerVault[_pid][tokenId] = Stake({
        owner: account,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
    }

    if (earned > 0) {
      // If the reward is more than the vault maximum, then let the user withdraw
      // the difference to reach the limit of the vault
      if ((totalClaimedPerVault[_pid] + earned) >= vaultid.maximumClamable) {
        earned = vaultid.maximumClamable - totalClaimedPerVault[_pid]; // tokens left in the vault
      }

      // But if the remaining earnings would be more than the contract maximum
      // limit the earnings to reach the contract maximum
      if ((totalClaimed + earned) >= MAXIMUM_RAVE_FROM_THE_RADIO_CONTRACT) {
        earned = MAXIMUM_RAVE_FROM_THE_RADIO_CONTRACT - totalClaimed;
      }
      if (earned > 0) {
        // if there is still earnings then transfer it
        totalClaimed += earned;
        totalClaimedPerVault[_pid] += earned;

        if (vaultid.royalityPercentage > 0) {
          // split earnings if royality

          royalityEarned = (earned * vaultid.royalityPercentage) / 1000;
          totalRoyalityPerVault[_pid] += royalityEarned;

          vaultid.token.mint(account, earned - royalityEarned);
        } else {
          // no royality set

          vaultid.token.mint(account, earned);
        }
      }
    } // earned > 0

    if (_unstake) {
      _unstakeMany(account, tokenIds, _pid);
    }
    if (earned > 0) {
      emit Claimed(account, earned);
    }
  }

  /**
   * @notice  Returns current rewards for staking per tokenids within a vault
   * @param   _pid      the vault id
   * @param   tokenIds  ids of the tokens
   * @return  earnings  earnings
   */
  function earningInfo(uint256 _pid, uint256[] calldata tokenIds)
    external
    view
    returns (uint256)
  {
    uint256 tokenId;
    uint256 earned = 0;

    vaultInfo storage vaultid = VaultInfo[_pid];

    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];

      Stake memory staked = stakedNFTsPerVault[_pid][tokenId];

      // Checks if the token is staked
      if (staked.timestamp > 0) {
        if (vaultid.royalityPercentage > 0) {
          uint256 stakingEarned;
          uint256 royalityEarned;

          stakingEarned =
            ((EMISSIONS_RATE_PER_SECONDS *
              (block.timestamp - staked.timestamp)) * vaultid.multiplier) /
            100;

          royalityEarned = (stakingEarned * vaultid.royalityPercentage) / 1000;

          earned += stakingEarned - royalityEarned;
        } else {
          earned +=
            ((EMISSIONS_RATE_PER_SECONDS *
              (block.timestamp - staked.timestamp)) * vaultid.multiplier) /
            100;
        }
      }
    }

    return earned;
  }

  /**
   * @notice  Returns the staked token ids from a vault for a staker
   * @param   _pid      the vault id
   * @param   account   the address of the staker
   * @return  tokenids  the tokens of the staker
   */
  function getTokensStaked(uint256 _pid, address account)
    public
    view
    returns (uint256[] memory)
  {
    return stakerToTokenIds[_pid][account];
  }

  /**
   * @dev Helper function to remove a specific item from an array
   */
  function remove(
    uint256 _pid,
    address account,
    uint256 index
  ) internal {
    if (index >= stakerToTokenIds[_pid][account].length) return;

    for (
      uint256 i = index;
      i < stakerToTokenIds[_pid][account].length - 1;
      i++
    ) {
      stakerToTokenIds[_pid][account][i] = stakerToTokenIds[_pid][account][
        i + 1
      ];
    }
    stakerToTokenIds[_pid][account].pop();
  }

  /**
   * @dev     Removes a token id from the staked array when someone unstakes
   */
  function removeTokenIdFromStaker(
    uint256 _pid,
    address staker,
    uint256 tokenId
  ) internal {
    for (uint256 i = 0; i < stakerToTokenIds[_pid][staker].length; i++) {
      if (stakerToTokenIds[_pid][staker][i] == tokenId) {
        remove(_pid, staker, i);
      }
    }
  }

  /**
   * @dev     Prevents sending NFTs directly to the contract address
   */
  function onERC721Received(
    address,
    address from,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    require(from == address(0x0), "Cannot send nfts to Vault directly");
    return IERC721Receiver.onERC721Received.selector;
  }
}