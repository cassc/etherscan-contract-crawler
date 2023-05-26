// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./VirtueToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract IdolMain is ERC721Enumerable, IERC2981, Ownable, ReentrancyGuard {
  // stethPrincipalBalance tracks the treasury's principal stETH balance.
  uint public stethPrincipalBalance;

  // allocatedStethRewards tracks the current amount of stETH that has been allocated to god owners.
  uint public allocatedStethRewards;

  // mintContractAddress holds the address for the minting contract.
  address public immutable mintContractAddress;

  // marketplaceAddress holds the address for the idol marketplace.
  address public marketplaceAddress;

  // teamWalletAddress holds the address that VIRTUE rewards are paid to when claimTeamIdol is
  // called.
  address public immutable teamWalletAddress;

  // steth is a reference to LIDO's stETH token contract.
  IERC20 public immutable steth;

  // virtueToken contains a reference to the protocol's native VIRTUE token contract.
  VirtueToken public virtueToken;

  // rewardPerGod tracks the cumulative amount of stETH awarded for each god since the protocol's
  // inception.
  uint public rewardPerGod;

  // claimedSnapshots stores the amount of rewards per god that each address has claimed thus far.
  mapping(address => uint) public claimedSnapshots;

  // contractWhitelist tracks which contracts are allowed to interact with the god NFTs.
  // (Only used if allowAllContracts is false).
  mapping(address => bool) public contractWhitelist;

  // contractBlacklist tracks which contracts are forbidden from interacting with the god NFTs.
  // (Only used if allowAllContracts is true).
  mapping(address => bool) public contractBlacklist;

  // allowAllContracts will allow all contracts to interact with the god NFTs when set to true.
  bool public allowAllContracts;

  // updateCallerReward expresses, in basis points, the percentage of newRewards paid to the function
  // caller, as an incentive to pay the gas prices for calling update functions.
  uint public updateCallerReward;

  // teamRewards tracks the current amount of VIRTUE accrued for the team.
  uint public teamRewards;

  // deployTime tracks when the contract was deployed.
  uint public deployTime;

  // lockedGods keeps track of which gods (owned by the team) have been locked from transferring/
  // purchasing for a 1-year window.
  mapping(uint => bool) public lockedGods;

  string private baseURI;

  // getVirtueAllowed specifies when users can bond stETH for VIRTUE using the getVirtue function.
  bool public getVirtueAllowed = false;

  // Royalties that are allocated to the VIRTUE rewards protocol in basis points (100ths of a %).
  uint public constant ROYALTY_BPS = 750;

  event RewardPerGodUpdated(uint _rpg, uint _slashAmt, address indexed _callerAddress);
  /**
    Instantiate with the address of LIDO's steth token
    0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84
  */
  constructor(
    address _mintContractAddress,
    address _stethAddr,
    address _teamWalletAddress
  )
    ERC721("Idol", "IDOL")
  {
    mintContractAddress = _mintContractAddress;
    marketplaceAddress = address(0x0);
    teamWalletAddress = _teamWalletAddress;
    steth = IERC20(_stethAddr);
    stethPrincipalBalance = 0;
    allocatedStethRewards = 0;
    rewardPerGod = 0;
    allowAllContracts = true;
    // set caller reward to 1%
    updateCallerReward = 100;
    teamRewards = 0;
    deployTime = block.timestamp;
  }
  /**
    @notice this function set the address of the VIRTUE Token
    @param _virtueTokenAddr the address of the VIRTUE token
  */
  function setVirtueTokenAddr(address _virtueTokenAddr) external onlyMintContract {
    virtueToken = VirtueToken(_virtueTokenAddr);
  }

  /**
    @notice This function sets the address for the Idol Marketplace.
    @param _marketplaceAddr The address for the marketplace
  */
  function setIdolMarketplaceAddr(address _marketplaceAddr) external onlyMintContract {
    marketplaceAddress = _marketplaceAddr;
  }

  /**
    @notice Overrides the ERC721 safeTransferFrom function by also giving the marketplace contract
      universal approval to execute transfers.
  */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    // Skip approval check for the marketplace address.
    if (msg.sender != marketplaceAddress) {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    }
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
    @notice setUpdateCallerReward updates the reward percentage paid to the function caller for
      calling updateRewardPerGod.
    @param _amt The amount to set the reward to, in basis points (i.e. 100 = 1%)
  */
  function setUpdateCallerReward(uint _amt)
    external
    onlyOwner
  {
    require(_amt <= 100, "hardcode max caller reward is 1%");
    updateCallerReward = _amt;
  }

  /**
    @notice whitelistAdd function adds an address to the smart contract whitelist.
    @param _addr The address to add to the whitelist.
  */
  function whitelistAdd(address _addr)
    external
    onlyOwner
  {
    contractWhitelist[_addr] = true;
  }

  /**
    @notice whitelistRemove removes an address from the smart contract whitelist.
    @param _addr The address to remove from the whitelist.
  */
  function whitelistRemove(address _addr)
    external
    onlyOwner
  {
    delete contractWhitelist[_addr];
  }


  /**
    @notice blacklistAdd function adds an address to the smart contract blacklist.
    @param _addr The address to add to the blacklist.
  */
  function blacklistAdd(address _addr)
    external
    onlyOwner
  {
    contractBlacklist[_addr] = true;
  }

  /**
    @notice blacklistRemove removes an address from the smart contract blacklist.
    @param _addr The address to remove from the blacklist.
  */
  function blacklistRemove(address _addr)
    external
    onlyOwner
  {
    delete contractBlacklist[_addr];
  }

  /**
    @notice setAllowAllContracts updates the allowAllContracts boolean.
    @param _val The value to set allowAllContracts, if true then all smart contracts will be allowed.
  */
  function setAllowAllContracts(bool _val)
    external
    onlyOwner
  {
    allowAllContracts = _val;
  }

  /**
    @notice _beforeTokenTransfer outlines the logic that should be run before every token transfer.
    @param _from - address of current owner
    @param _to - address of new owner
    @param _tokenId - id of token to transfer
    @dev needs to call claim and update on both '_from' and 'to'
         reverts if 'to' is a non-whitelisted smart contract
  */

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
    override
    onlyAllowedContracts(_to)
  {
    super._beforeTokenTransfer(_from, _to, _tokenId);
    if(_from != address(0x0)){
      if (lockedGods[_tokenId]) {
        require(deployTime + 365 days < block.timestamp,'Token can only be transferred when lock has expired');
      }
      _claimEthRewards(_from);

      // If the user will have 0 NFTs left after this transfer, delete them from claimedSnapshots
      // entirely.
      if(balanceOf(_from) == 1){
        delete claimedSnapshots[_from];
      }
    }

    // It the _to user already has NFTs, claim their rewards.
    if(balanceOf(_to) > 0){
      _claimEthRewards(_to);
    } else {
      claimedSnapshots[_to] = rewardPerGod;
    }
  }

  /**
    @notice override setapproval function to only allow whitelisted addresses
  */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    public
    virtual
    override
    onlyAllowedContracts(_operator)
  {
    super.setApprovalForAll(_operator, _approved);
  }

  /**
    @notice override approve function to only allow whitelisted addresses
  */
  function approve(
    address _to,
    uint256 _tokenId
  )
    public
    virtual
    override
    onlyAllowedContracts(_to)
  {
    super.approve(_to, _tokenId);
  }

  /**
    @notice this function deposits steth and increase steth prin bal
    @param _stethAmt - amount to deposit
  */
  function depositSteth(uint _stethAmt)
    public
  {
    require(steth.transferFrom(msg.sender, address(this), _stethAmt));
    stethPrincipalBalance = stethPrincipalBalance + _stethAmt;
  }

  /**
      @notice this function updates rewardPerGod based on the relationship between steth prin bal
      and actual steth in the contract
  */
  function updateRewardPerGod()
      public
      nonReentrant
  {
    uint256 stethBal = steth.balanceOf(address(this));
    // This should only occur if steth has experienced slashing.
    // Reduce stethPrincipalBalance to stethBal minus previously allocated rewards.
    if (stethBal < (stethPrincipalBalance + allocatedStethRewards)) {
      emit RewardPerGodUpdated(rewardPerGod, stethPrincipalBalance + allocatedStethRewards - stethBal, msg.sender);
      stethPrincipalBalance = stethBal - allocatedStethRewards;
      return;
    }
    // Nothing to do if the balances are equal.
    else if (stethBal == (stethPrincipalBalance + allocatedStethRewards)) {
      return;
    }
    // If we have extra stETH, update rewardPerGod, add newRewards to allocatedStethRewards.
    else if (stethBal > (stethPrincipalBalance + allocatedStethRewards)) {
      uint newRewards = stethBal - (stethPrincipalBalance + allocatedStethRewards);
      uint callerReward = newRewards * updateCallerReward / 10000;
      newRewards = newRewards - callerReward;
      rewardPerGod = rewardPerGod + newRewards / totalSupply();
      allocatedStethRewards = allocatedStethRewards + newRewards;
      emit RewardPerGodUpdated(rewardPerGod, 0, msg.sender);
      if(callerReward > 0){
        require(steth.transfer(msg.sender, callerReward));
      }
    }
  }

  /**
    @notice currentUpdateReward shows what the current reward would be for calling
      updateRewardPerGod, as an incentive to spend the gas costs on calling the function.
  */
  function currentUpdateReward()
    public
    view
    returns(uint)
  {
    uint256 stethBal = steth.balanceOf(address(this));
    if (stethBal <= stethPrincipalBalance + allocatedStethRewards) {
      return 0;
    }
    uint newRewards = stethBal - (stethPrincipalBalance + allocatedStethRewards);
    uint callerReward = newRewards * updateCallerReward/10000;
    return callerReward;
  }

  /**
    @notice getPendingStethReward returns the amount of stETH that has accrued to the user
      and has yet to be claimed.
  */
  function getPendingStethReward(address _user)
    public
    view
    returns (uint256)
  {
    return (balanceOf(_user) * (rewardPerGod - claimedSnapshots[_user]));
  }

  /**
    @notice claimEthRewards is called to claim rewards on behalf of a user.
  */
  function claimEthRewards(address _user)
    external
  {
    require(balanceOf(_user) > 0, "Can only claim if balance of user > 0");
    _claimEthRewards(_user);
  }

  /**
    @notice allowGetVirtue is a one-time function that enables the bonding of stETH for VIRTUE
      token. It is intended to only be enabled once the mint has concluded.
  */
  function allowGetVirtue() public onlyOwner {
    getVirtueAllowed = true;
  }

  /**
    @notice getVirtue transfers VIRTUE token to the caller in exchange for stETH.
      It requires that the caller has approved this contract to transfer
      stETH on their behalf.
    @param _stethAmt - The amount of stETH the user would like to deposit to the
      bonding curve in exhange for Idol.
    @param _minVirtue - The minimum amount of VIRTUE that the function needs to return.
      Reverts if returned amount is lower than this.
  */
  function getVirtue(uint256 _stethAmt, uint256 _minVirtue)
    public
    nonReentrant
  {
    require(getVirtueAllowed, "Bonding of stETH for VIRTUE is not yet enabled");
    uint256 virtueToTransfer = virtueToken.getVirtueBondAmt(_stethAmt);
    require(virtueToTransfer >= _minVirtue, "Not enough VIRTUE returned");
    // Update Steth bonded.
    depositSteth(_stethAmt);
    require(virtueToken.transfer(msg.sender, virtueToTransfer));
    virtueToken.incrementBondedSteth(_stethAmt);
    // Accrue team allocation to team.
    teamRewards = teamRewards + virtueToTransfer / 5;
  }

  /**
    @notice claimTeamIdol claims all rewards accrued to the team thus far and sends it to
      teamWalletAddress.
  */
  function claimTeamIdol()
    external
    nonReentrant
  {
    uint currentRewards = teamRewards;
    teamRewards = 0;
    require(virtueToken.transfer(teamWalletAddress, currentRewards));
  }

  /**
    @notice internal helper function for claimEthRewards
  */
  function _claimEthRewards(address _user)
    internal
    nonReentrant
  {
    uint256 currentRewards = getPendingStethReward(_user);
    if (currentRewards > 0) {
      allocatedStethRewards = allocatedStethRewards - currentRewards;
      claimedSnapshots[_user] = rewardPerGod;
      require(steth.transfer(_user, currentRewards));
    }
  }


  /**
    @notice mint function called by the mintContract
  */
  function mint(address _mintAddress, uint _godId, bool _lock)
    external
    onlyMintContract
  {
    if(_lock){
      lockedGods[_godId] = true;
    }
    _safeMint(_mintAddress, _godId);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /**
    @notice Sets the baseURI string for the NFT. Can only be set by the mint contract,
      and cannot be updated once the mint contract is locked.
  */
  function setBaseURI(string memory uri) external onlyMintContract {
    baseURI = uri;
  }

  function royaltyInfo(uint256, uint256 salePrice) external view returns (
    address receiver,
    uint256 royaltyAmount
  ) {
    receiver = marketplaceAddress;
    royaltyAmount = salePrice * ROYALTY_BPS / 10000;
  }

  modifier onlyMintContract {
    require(msg.sender == mintContractAddress);
    _;
  }

  modifier onlyAllowedContracts(address _addr) {
    if (Address.isContract(_addr)) {
      if (!allowAllContracts) {
        require(contractWhitelist[_addr], 'Function can only be called for whitelisted contracts');
      }
      if (allowAllContracts) {
        require(!contractBlacklist[_addr], 'Function cannot be called for blacklisted contracts');
      }
    }
    _;
  }
}