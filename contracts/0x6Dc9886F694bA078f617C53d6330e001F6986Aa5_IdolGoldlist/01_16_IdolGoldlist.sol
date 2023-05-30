// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
  @notice IdolGoldlist is an ERC721A contract that allows NFT holders to claim a portion of the
    VIRTUE rewards that have been allocated to the contract. The initial minting of the Goldlist
    NFTs is authenticated using a Merkle Tree proof.
*/
contract IdolGoldlist is ERC721A, ReentrancyGuard, Ownable {
  // merkleRoot is the value of the root of the Merkle Tree being used for authenticating mints.
  bytes32 public merkleRoot;

  // virtueToken contains a reference to the ERC20 contract for the VIRTUE token.
  IERC20 virtueToken;

  // rewardPerGoldlistToken tracks the cumulative amount of VIRTUE awarded to each Goldlist token
  // since the contract's inception.
  uint public rewardPerGoldlistToken;

  // claimedSnapshots stores the amount of VIRTUE per Goldlist token that each address has claimed
  // thus far.
  mapping(address => uint) public claimedSnapshots;

  // alreadyMinted is a mapping that stores which addresses have already minted their goldlist
  // NFTs and are no longer eligible to mint.
  mapping(address => bool) public alreadyMinted;

  // MAX_SUPPLY stores the maximum number of Goldlist NFTs that can be minted.
  uint public constant MAX_SUPPLY = 888;

  // deployTime records the time the contract was deployed.
  uint public immutable deployTime;

  // tokenUri stores the URI for all of the Goldlist NFTs.
  string public tokenUri;

  // approvedDistibutors is a mapping of addresses that are allowed to transfer the Goldlist NFTs.
  // All other addresses must wait a full year before the Goldlist NFTs can be transferred.
  mapping(address => bool) public approvedDistributors;

  // VirtueRewardDeposited is an event that is emitted anytime additional VIRTUE rewards are
  // deposited into the IdolGoldlist contract.
  event VirtueRewardDeposited(
    uint _virtueAmount,
    uint _rewardPerGoldlistToken,
    address _caller
  );

  constructor(
    bytes32 _merkleRoot,
    address _virtueTokenAddress,
    string memory _tokenUri
  ) ERC721A("IdolGoldlist", "GOLDLIST") {
    merkleRoot = _merkleRoot;
    virtueToken = IERC20(_virtueTokenAddress);
    deployTime = block.timestamp;
    tokenUri = _tokenUri;

    // Add team wallet and cre8tordao wallet as approved distributors.
    approvedDistributors[0x82AF9d2Ea81810582657f6DC04B1d7d0D573F616] = true;
    approvedDistributors[0x5eefD9C64d8c35142B7611aE3A6dECFc6d7a8a5E] = true;
  }

  function addApprovedDistributor(address _addr) external onlyOwner {
    approvedDistributors[_addr] = true;
  }

  function removeApprovedDistributor(address _addr) external onlyOwner {
    delete approvedDistributors[_addr];
  }

  /**
    @notice mint allows senders to mint a certain number of Goldlist NFTs to an authenticated
      address. Addresses must mint the EXACT amount of Goldlist NFTs they are authenticated to mint,
      i.e. if someone is eligible to mint 5 Goldlist NFTs and they try to mint 1, the transaction
      will be reverted -- they must mint exactly 5.
    @param _to The address to mint the NFTs for.
    @param _numTokens The number of Goldlist NFTs to mint for the sender.
    @param _merkleProof The Merkle proof used to verify the transaction against the Merkle root.
  */
  function mint(address _to, uint _numTokens, bytes32[] calldata _merkleProof) external {
    require(totalSupply() + _numTokens <= MAX_SUPPLY, "Mint would exceed max supply");
    require(!alreadyMinted[_to], "Goldlist NFTs have already been minted for that address");

    // Verify against the Merkle tree that the transaction is authenticated for the user.
    bytes32 leaf = keccak256(abi.encodePacked(_to, _numTokens));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Failed to authenticate with merkle tree");

    alreadyMinted[_to] = true;

    _mint(_to, _numTokens, '', false);
  }

  /**
    @notice depositVirtueRewards is intended to be called by the founding team to transfer
      VIRTUE to the IdolGoldlist contract, which is then eligible to be withdrawn by Goldlist
      NFT holders. The IdolGoldlist must first be approved to transfer VIRTUE token on the sender's
      behalf before this function can be called successfully.
    @param _virtueAmount The amount of VIRTUE to distribute to Goldlist NFT holders.
  */
  function depositVirtueRewards(uint _virtueAmount) external {
    rewardPerGoldlistToken = rewardPerGoldlistToken + _virtueAmount / totalSupply();
    require(virtueToken.transferFrom(msg.sender, address(this), _virtueAmount));

    emit VirtueRewardDeposited(_virtueAmount, rewardPerGoldlistToken, msg.sender);
  }

  /**
    @notice getPendingVirtueReward is a view function which returns the amount of VIRTUE that has
      accrued for a user and is eligible to be claimed.
    @param _user The user to get pending VIRTUE rewards for.
  */
  function getPendingVirtueReward(address _user) public view returns (uint256) {
    return (balanceOf(_user) * (rewardPerGoldlistToken - claimedSnapshots[_user]));
  }

  /**
    @notice claimVirtueRewards is called to claim VIRTUE rewards on behalf of a user.
    @param _user The user to claim VIRTUE rewards for.
  */
  function claimVirtueRewards(address _user) external nonReentrant {
    require(balanceOf(_user) > 0, "Can only claim if balance of user > 0");
    _claimVirtueRewards(_user);
  }

  function _claimVirtueRewards(address _user) internal {
    uint256 pendingVirtueRewards = getPendingVirtueReward(_user);
    if (pendingVirtueRewards > 0) {
      claimedSnapshots[_user] = rewardPerGoldlistToken;
      require(virtueToken.transfer(_user, pendingVirtueRewards));
    }
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
    return tokenUri;
  }

  /**
    @notice _beforeTokenTransfers runs logic to claim any pending VIRTUE rewards for both the sender
      and the receiver before the transfer confirms.
    @param _from Address of the current NFT holder.
    @param _to Address to send transfer the NFT(s) to.
    @param _startTokenId ID of the first NFT to transfer
    @param _quantity The number of NFTs to transfer.
  */
  function _beforeTokenTransfers(
    address _from,
    address _to,
    uint256 _startTokenId,
    uint256 _quantity
  )
    internal virtual override
  {
    super._beforeTokenTransfers(_from, _to, _startTokenId, _quantity);

    if (_from != address(0x0)) {
      if (!approvedDistributors[_from]) {
        require(deployTime + 365 days < block.timestamp, 'Token can only be transferred once 1-year lock has expired');
      }
      _claimVirtueRewards(_from);

      if (balanceOf(_from) == _quantity) {
        delete claimedSnapshots[_from];
      }
    }

    if (balanceOf(_to) > 0) {
      _claimVirtueRewards(_to);
    } else {
      claimedSnapshots[_to] = rewardPerGoldlistToken;
    }
  }
}