// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ECDSALibrary.sol";
import "../interfaces/INefturiansArtifact.sol";
import "../interfaces/INefturians.sol";

/**********************************************************************************************************************/
/*                                                                                                                    */
/*                                                Nefturians Artifacts                                                */
/*                                                                                                                    */
/*                     NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                     */
/*                  NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                  */
/*                NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                */
/*              NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN              */
/*             NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN             */
/*            NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN            */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN........NNNNNNNNNNNNNNNNNNN.......NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...........NNNNNNNNNNNNNNNN.........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNN...............NNNNNNNNNNNN............NNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNN.................NNNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNN...................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNN.....................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNN.......................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNN..........................NNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNN.............................NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNN............NNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN............NNNNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNN.............NNNNNNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNN.............NNNNNNNNNN..............NNNNNNNNNN............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN..............NNNNNNNN.............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN...............NNNNN.............NNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNN...............NNN.............NNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN............................NNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNN..........................NNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNN........................NNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNN.....................NNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNNN..................NNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNNN................NNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNN...........NNNNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.........NNNNNNNNNNNNNNNN...........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.......NNNNNNNNNNNNNNNNNNN........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.NNNNNNNNNNNNNNNNNNNNNNNNNN.NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*            NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN            */
/*             NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN             */
/*               NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN               */
/*                 NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                 */
/*                    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                     */
/*                                                                                                                    */
/*                                                                                                                    */
/*                                                                                                                    */
/**********************************************************************************************************************/

contract NefturiansArtifact is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, INefturianArtifact {

  /**
   * Roles for the access control
   * these roles are only checked against the parent contract's settings
   */
  bytes32 internal constant DAO_ROLE = keccak256("DAO_ROLE");
  bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 internal constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
  bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

  /**
   * Custom URI for each token
   */
  mapping(uint256 => string) private _uris;

  /**
   * Odds of drawing artifacts based on their rarity level.
   *
   * Rarity levels go in this order:
   *  - odds[0] = common (for common equipment and basic consumables)
   *  - odds[1] = powerUp (consummables used to upgrades Nefturians stats)
   *  - odds[2] = rare (for rare equipment and powerful buffs consumables)
   *  - odds[3] = legendary (wait for it...)
   */
  uint256[] private odds = [70000, 90000, 99000, 100000];

  /**
   * Current tokenId count.
   * Starts at 1. Index 0 is reserved for eggs
   */
  uint256 private generalCount = 1;

  /**
   * Mapping rarity levels and indexes to tokenIds.
   *
   * indexesByRarity[ rarityId ][ autoincremented index ] => tokenId
   * countByRarity = autoincremented indexes for each rarity level
   */
  mapping(uint256 => mapping(uint256 => uint256)) private indexesByRarity;
  mapping(uint256 => uint256) private countByRarity;

  /**
   * If a token should be burned when used
   */
  mapping(uint256 => bool) private consumable;

  /**
   * Ether pool to pay for the gas when a method needs to be called by our API
   */
  mapping(address => uint256) public stakes;

  /**
   * Parent contract: The Nefturians collection
   */
  INefturians internal nefturians;

  constructor() ERC1155("") {
    nefturians = INefturians(msg.sender);
    consumable[0] = true;
  }

  /**
   * Update the odds of drawing artifacts based on their rarity level
   * @param newOdds: new odds in increment order with last equal to 100000
   *
   * Error messages:
   *  - AC0: "You dont have required role"
   *  - NA03: "Wrong format for array"
   */
  function updateOdds(uint256[] calldata newOdds)
  public
  {
    require(nefturians.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AC0");
    require(newOdds.length == 4, "NA03");
    require(newOdds[3] == 100000, "NA03");
    require(
      newOdds[0] <= newOdds[1] &&
      newOdds[1] <= newOdds[2] &&
      newOdds[2] <= newOdds[3], "NA03");
    emit UpdateOdds(odds, newOdds);
    odds = newOdds;
  }

  /**
   * Adds a new artifact
   * @param rarity: rarity of the new artifact (must be between 0 and 3)
   * @param quantity: quantity of artifacts to be added
   * @param isConsumable: if the artifact can be consumed
   *
   * Error messages:
   *  - NA07: "Rarity out of bounds"
   */
  function addRareItem(uint256 rarity, uint256 quantity, bool isConsumable)
  public
  {
    require(rarity < 4 && rarity >= 0, "NA07");
    require(nefturians.hasRole(MINTER_ROLE, msg.sender), "Missing role");
    for (uint256 i = 0; i < quantity; i++) {
      indexesByRarity[rarity][countByRarity[rarity] + i] = generalCount + i;
      consumable[generalCount + i] = isConsumable;
    }
    countByRarity[rarity] += quantity;
    generalCount += quantity;
    emit AddRareItem(rarity, quantity, isConsumable);
  }

  /**
   * Set URI of a given token
   * @param tokenId: id of the token
   * @param newuri: new uri of token id
   *
   */
  function setURI(uint256 tokenId, string memory newuri) public {
    require(nefturians.hasRole(MINTER_ROLE, msg.sender), "Missing role");
    _setURI(tokenId, newuri);
  }

  /**
   * Public mint function that requires a signature from a SIGNER_ROLE
   * @param tokenId: id of the token
   * @param quantity: quantity to be minted
   * @param signature: signature of SIGNER_ROLE
   *
   * Error messages:
   *  - N6: "This operation has not been signed"
   */
  function mintWithSignature(uint256 tokenId, uint256 quantity, bytes calldata signature)
  public
  {
    uint256 nonce = nefturians.getNonce(msg.sender);
    require(nefturians.hasRole(SIGNER_ROLE, ECDSALibrary.recover(abi.encodePacked(msg.sender, nonce, tokenId, quantity), signature)), "N6");
    nefturians.incrementNonce(msg.sender);
    _mint(msg.sender, tokenId, quantity, "");
  }

  /**
   * Mint batch of token only if MINTER_ROLE
   * @param to: address reveiving tokens
   * @param tokenIds: ids of the tokens to be minted
   * @param amounts: quantities of each token to be minted
   * @param data: arbitrary data for events
   *
   * Error messages:
   *  - AC0: "You dont have required role"
   */
  function mintBatch(address to, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data)
  public
  {
    require(nefturians.hasRole(MINTER_ROLE, msg.sender), "AC0");
    _mintBatch(to, tokenIds, amounts, data);
  }

  /**
   * Get the uri of a tokenId
   * @param tokenId: id of the token
   */
  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    return _uris[tokenId];
  }

  /**
   * Stake some eth to allow the admin to claim artifacts for you
   */
  function stake() public payable {
    stakes[msg.sender] += msg.value;
  }

  /**
   * Get your staked eth back
   */
  function unstake() public {
    require(stakes[msg.sender] > 0, "No stake");
    uint256 staked = stakes[msg.sender];
    stakes[msg.sender] = 0;
    payable(msg.sender).transfer(staked);
  }

  /**
   * Allows a MINTER from the parent contract to mint eggs to address
   * @param to: address of the token recipient
   *
   * Error messages:
   *  - AC0: "You dont have required role"
   */
  function giveEgg(address to) override external {
    require(nefturians.hasRole(MINTER_ROLE, msg.sender), "AC0");
    _mint(to, 0, 1, "");
  }

  /**
   * Claim artifacts with a egg for a user. One egg gives one random artifact of a random rarity level
   * @param quantity: quantity of eggs to use
   * @param userSeed: random seed from the user
   * @param serverSeed: random seed from the server
   * @param signature: the user seed signed with the token owner's private key
   *
   * Error messages:
   *  - AC0: "You dont have required role"
   *  - NA00: "Your stake does not cover the gas price"
   *  - NA01: "Division by zero"
   *  - NA08: "Balance too low"
   */
  function claimArtifact(
    uint256 quantity,
    bytes4 userSeed,
    bytes4 serverSeed,
    bytes calldata signature
  ) public {
    require(nefturians.hasRole(SIGNER_ROLE, msg.sender), "AC0");
    address caller = ECDSALibrary.recover(abi.encodePacked(userSeed), signature);
    require(balanceOf(caller, 0) >= quantity, "NA00");
    require(stakes[caller] >= tx.gasprice, "NA01");
    _burn(caller, 0, quantity);
    for (uint256 i = 0; i < quantity; i++) {
      uint256 number = uint256(keccak256(abi.encodePacked(userSeed, serverSeed, i)));
      distributeReward(caller, number);
    }
    stakes[caller] -= tx.gasprice;
    payable(msg.sender).transfer(tx.gasprice);
  }

  /**
   * Mint reward based on odds and egg number
   * @param rewardee: address of receiver
   * @param ticket: random number
   *
   * Error messages:
   *  - NA02: "Division by zero"
   */
  function distributeReward(address rewardee, uint256 ticket) internal {
    uint256 number = ticket % 100000;
    uint256 rarity;

    if (number < odds[0]) {
      rarity = 0;
    }
    else if (number < odds[1]) {
      rarity = 1;
    }
    else if (number < odds[2]) {
      rarity = 2;
    }
    else {
      rarity = 3;
    }

    require(countByRarity[rarity] > 0, "NA02");
    uint256 index = ticket % countByRarity[rarity];
    _mint(rewardee, indexesByRarity[rarity][index], 1, "");
  }

  /**
   * Allow an owner of consumable tokens to use them
   * @param tokenId: id of the token to be used
   * @param quantity: quantity to be used
   *
   * Error messages:
   *  - NA06: "Item not consummable"
   *  - NA04: "Not enough artifacts"
   */
  function useArtifact(uint256 tokenId, uint256 quantity) public {
    require(consumable[tokenId], "NA06");
    require(balanceOf(msg.sender, tokenId) >= quantity, "NA04");
    _burn(msg.sender, tokenId, quantity);
    emit UseArtifact(tokenId, quantity);
  }

  function _setURI(uint256 tokenId, string memory newuri) internal {
    _uris[tokenId] = newuri;
  }

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
  internal
  override(ERC1155, ERC1155Supply)
  {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  // The following functions are overrides required by Solidity.
  function supportsInterface(bytes4 interfaceId)
  public
  view
  override(ERC1155, IERC165)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
  function transferOwnership(address newOwner) public override(INefturianArtifact, Ownable) onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }
}