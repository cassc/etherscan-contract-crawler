// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @notice General staking contract that allows
 *         users to temporarily lock their NFTs.
 * 
 * Fires an event when the NFTs are staken/unstaken
 * for more things to happen on the backend
 *
 * The NFTs are locked inside this contract for the
 * duration of the staking period while allowing the
 * user to unstake at any time
 *
 * While the NFTs are staked, they are technically
 * owned by this contract and cannot be moved or placed
 * on any marketplace
 *
 * The contract allows users to stake and unstake multiple
 * NFTs efficiently, in one transaction
 */
contract EventStaking is ERC721Holder {
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * @notice Stores the ERC-721 tokens that can
   *         be staked
   */
  mapping(address => bool) public allowedTokenAddresses;

  /**
   * @dev Stores the staked token IDs of every owner for every allowed
   *      NFT address
   */
  mapping(address => mapping(address => EnumerableSet.UintSet)) private stakedTokens;

  /**
   * @dev Stores which NFT addresses an owner has staked NFTs of
   */
  mapping(address => EnumerableSet.AddressSet) private ownerTokenAddresses;

  /**
   * @dev Emitted every time a token is staked
   *
   * Emitted in stake()
   *
   * @param by address that staked the NFTs
   * @param addresses NFT addresses of staked NFTs
   * @param ids NFT ids of staked NFTs
   * @param timestamp when the event was emitted
   */
  event Staked(
    address indexed by,
    address[] addresses,
    uint256[] ids,
    uint256 timestamp
  );

  /**
   * @dev Emitted every time a token is unstaked
   *
   * Emitted in unstake()
   *
   * @param by address that unstaked the NFTs
   * @param addresses NFT addresses of unstaked NFTs
   * @param ids NFT ids of unstaked NFTs
   * @param timestamp when the event was emitted
   */
  event Unstaked(
    address indexed by,
    address[] addresses,
    uint256[] ids,
    uint256 timestamp
  );

  struct TokensStakedByOwner {
    address[] addresses;
    uint256[] ids;
  }

  /**
   * @notice Initiates the staking contract
   *
   * @param _tokenAddressList list of allowed NFT addresses
   */
  constructor(address[] memory _tokenAddressList) {
    for(uint256 i = 0; i < _tokenAddressList.length; i++) {
      allowedTokenAddresses[_tokenAddressList[i]] = true;
    }
  }

  /**
   * @notice Stakes NFTs
   *
   * @dev Requres user to have approved the staking contract for
   *      all NFT addresses
   *
   * @param _addresses addresses of the NFTs to be staked. Must be approved addresses
   * @param _ids ids of the NFTs to be staked. Must be same length as _addresses
   */
  function stake(address[] memory _addresses, uint256[] memory _ids) public {
    require(_ids.length > 0, "no ids set");
    require(_addresses.length == _ids.length, "address length must be same as ids length");

    for(uint256 i = 0 ; i < _addresses.length; i++) {
      address addr = _addresses[i];
      uint256 id = _ids[i];

      require(allowedTokenAddresses[addr], "address not allowed");

      IERC721(addr).transferFrom(msg.sender, address(this), id);

      stakedTokens[msg.sender][addr].add(id);
      ownerTokenAddresses[msg.sender].add(addr);
    }

    emit Staked(msg.sender, _addresses, _ids, block.timestamp);
  }

  /**
   * @notice Unstakes NFTs
   *
   *
   * @param _addresses addresses of the NFTs to be staked
   * @param _ids ids of the NFTs to be staked. Must be same length as _addresses
   */
  function unstake(address[] memory _addresses, uint256[] memory _ids) public {
    require(_ids.length > 0, "no ids set");
    require(_addresses.length == _ids.length, "address length must be same as ids length");

    for(uint256 i = 0 ; i < _addresses.length; i++) {
      address addr = _addresses[i];
      uint256 id = _ids[i];

      require(stakedTokens[msg.sender][addr].contains(id), "not owner");

      stakedTokens[msg.sender][addr].remove(id);

      IERC721(addr).transferFrom(address(this), msg.sender, id);
    }

    emit Unstaked(msg.sender, _addresses, _ids, block.timestamp);
  }

  /**
   * @notice Returns the NFT addresses and tokens that were staked by a user
   *
   * @param _owner user to get staked NFT addresses and tokens for
   */
  function tokensStakedByOwner(address _owner) public view returns (TokensStakedByOwner memory) {
    uint256 totalTokens = 0;

    for(uint256 i = 0; i < ownerTokenAddresses[_owner].length(); i++) {
      address addr = ownerTokenAddresses[_owner].at(i);

      totalTokens += stakedTokens[_owner][addr].length();
    }

    address[] memory addresses = new address[](totalTokens);
    uint256[] memory ids = new uint256[](totalTokens);

    uint256 c = 0;

    for(uint256 i = 0; i < ownerTokenAddresses[_owner].length(); i++) {
      address addr = ownerTokenAddresses[_owner].at(i);

      for(uint256 j = 0; j < stakedTokens[_owner][addr].length(); j++) {
        addresses[c] = addr;
        ids[c] = stakedTokens[_owner][addr].at(j);

        c++;
      }
    }

    return TokensStakedByOwner(
      addresses,
      ids
    );
  }
}