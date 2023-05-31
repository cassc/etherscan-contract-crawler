// SPDX-License-Identifier: MIT
//
// Spirit Orb Pets Care Token Contract
// Developed by:  Heartfelt Games LLC
//
// The CARE token is a utility token for the Spirit Orb Pets game ecosystem.
// $CARE is NOT an investment and has NO economic value.
// It will be earned by active holding and game interactions within the
// Spirit Orb Pets game ecosystem. Each v0 Spirit Orb Pet will be eligible
// to claim tokens at a rate of 10 $CARE per day.
//

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISpiritOrbPetsv0 is IERC721, IERC721Enumerable {

}

contract CareToken is ERC20 {

  address public _owner;
  address[] public _approvedMinters;

  // freezes the ability to mint new tokens to owner of contract
  bool public _closedMintToOwner = false;
  // freezes the ability to add or remove contracts from approvedMinters
  // Only to be used once all current sources of generating CARE are to be
  // only ones ever to mint in a closed ecosystem.
  bool public _freezeApprovedMintersList = false;

  // v0 pet owner related variables
  ISpiritOrbPetsv0 public SOPV0Contract;
  uint256 public INITIAL_ALLOTMENT = 100 * (10 ** 18);

  uint256 public _emissionStart = 0;
  uint256 public _emissionEnd = 0;
  uint256 public _emissionPerDay = 10 * (10 ** 18);

  mapping(uint256 => uint256) private _lastClaim;

  constructor() ERC20('Spirit Orb Pets Care Token', 'CARE') {
     // Initial tokens minted for contests, giveaways, and initial liquidity pool
    _mint(msg.sender, 100000 * 10 ** 18);
    _owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  /**
  * @dev in case more is needed for contests, giveaways, and liquidity pool
  */
  function mint(uint256 amount) external onlyOwner {
    require(!_closedMintToOwner, "Minting to owner is permanently closed.");
    _mint(msg.sender, amount * 10 ** 18);
  }

  /**
  * @dev burn tokens
  */
  function burn(address account, uint256 amount) external {
    super._burn(account, amount);
  }

  /**
  * @dev If the community decides that the mint to owner function should no
  * @dev longer be accessable to the contract owner, call this and it will be
  * @dev permanently disabled.
  */
  function closeMintToOwner() external onlyOwner {
    // This can only be set to true.
    _closedMintToOwner = true;
  }

  /**
  * @dev This adds new contracts to the list of contracts that are allowed to
  * @dev generate new tokens for use in the CARE token system.
  */
  function addApprovedContract(address addr) external onlyOwner {
    _approvedMinters.push(addr);
  }

  function removeApprovedContract(uint index) external onlyOwner {
    _approvedMinters[index] = _approvedMinters[_approvedMinters.length - 1];
    _approvedMinters.pop();
  }

  function getApprovedContractList() external view returns (address[] memory) {
    return _approvedMinters;
  }

  /**
  * @dev Permanently freezes the access list disallowing additions and removals.
  */
  function freezeApprovedMinters() external onlyOwner {
    require(_freezeApprovedMintersList == false, "Once frozen, no more contracts can be added or removed.");
    _freezeApprovedMintersList = true;
  }

  function isApproved(address addr) internal view returns (bool) {
    bool approved = false;
    for (uint i = 0; i < _approvedMinters.length; i++) {
      if (_approvedMinters[i] == addr) approved = true;
    }
    return approved;
  }

  /**
  * @dev Mints new tokens to contracts on the approved minters list.
  */
  function mintToApprovedContract(uint256 amount, address mintToAddress) external {
    require(_approvedMinters.length > 0, "There are no approved contracts yet.");
    require(isApproved(msg.sender), "Address is not approved to mint.");

    _mint(mintToAddress, amount);
  }

  function setOwner(address addr) external onlyOwner {
    _owner = addr;
  }

  function setSOPV0Contract(address addr) external onlyOwner {
    SOPV0Contract = ISpiritOrbPetsv0(addr);
  }

  function beginEmissionOfTokens() external onlyOwner {
    require(_emissionStart == 0 && _emissionEnd == 0, "Emission timestamps already set!");
    _emissionStart = block.timestamp;
    _emissionEnd = _emissionStart + (10 * 365 days) + 2 days; // +2 for leap years
  }

  function lastClaim(uint256 tokenIndex) public view returns (uint256) {
    require(SOPV0Contract.ownerOf(tokenIndex) != address(0));
    require(tokenIndex < SOPV0Contract.totalSupply(), "Token index is higher than total collection count.");

    // If tokens have never been claimed use emissionStart, otherwise grab from _lastClaim
    uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0 ? uint256(_lastClaim[tokenIndex]) : _emissionStart;
    return lastClaimed;
  }

  /**
   * @dev Accumulated CARE tokens for a Hashmask token index.
   */
  function accumulated(uint256 tokenIndex) public view returns (uint256) {
      require(_emissionStart != 0 && _emissionEnd != 0, "Emission has not started yet");
      require(SOPV0Contract.ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
      require(tokenIndex < SOPV0Contract.totalSupply(), "Token index is higher than total collection count.");

      uint256 lastClaimed = lastClaim(tokenIndex);

      // if last claim was on or after emission end, there isn't any left to give
      if (lastClaimed >= _emissionEnd) return 0;

      uint256 accumulationPeriod = block.timestamp < _emissionEnd ? block.timestamp : _emissionEnd; // Getting the min value of both
      uint256 totalAccumulated = (((accumulationPeriod - lastClaimed) * _emissionPerDay) / 1 days);

      // If claim hasn't been done before for the index, add initial allotment
      if (lastClaimed == _emissionStart) {
        totalAccumulated = totalAccumulated + INITIAL_ALLOTMENT;
      }

      return totalAccumulated;
  }

  /**
   * @dev Claim mints CARE tokens and supports multiple Hashmask token indices at once.
   */
  function claim(uint256[] memory tokenIndices) public returns (uint256) {
      require(_emissionStart != 0 && _emissionEnd != 0, "Emission has not started yet");

      uint256 totalClaimQty = 0;
      for (uint i = 0; i < tokenIndices.length; i++) {
          // Sanity check for non-minted index
          require(tokenIndices[i] < SOPV0Contract.totalSupply(), "NFT at index has not been minted yet");
          // Duplicate token index check
          for (uint j = i + 1; j < tokenIndices.length; j++) {
              require(tokenIndices[i] != tokenIndices[j], "Duplicate token index");
          }

          uint tokenIndex = tokenIndices[i];
          require(SOPV0Contract.ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");

          uint256 claimQty = accumulated(tokenIndex);
          if (claimQty != 0) {
              totalClaimQty = totalClaimQty + claimQty;
              _lastClaim[tokenIndex] = block.timestamp;
          }
      }

      require(totalClaimQty != 0, "No accumulated CARE");
      _mint(msg.sender, totalClaimQty);
      return totalClaimQty;
  }

}