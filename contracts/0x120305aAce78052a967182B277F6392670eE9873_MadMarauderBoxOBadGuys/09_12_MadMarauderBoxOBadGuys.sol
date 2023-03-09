import "Guardable/ERC721AGuardable.sol";
import "solmate/auth/Owned.sol";
import "solmate/utils/MerkleProofLib.sol";
import "./lib/MarauderErrors.sol";
import "./lib/MarauderEnums.sol";
import "./lib/MarauderStructs.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract MadMarauderBoxOBadGuys is ERC721AGuardable, Owned {
  string private baseUri;

  address public immutable maraudersContract;
  address public immutable archerContract;
  address public immutable merchContract;
  address public immutable serumContract;

  bool public smashingEnabled;

  mapping(Phase => PhaseDetails) public phases;
  mapping(Item => ItemDetails) public itemDetails;
  mapping(address => mapping(Item => uint256)) public numMintedDuringNerdPhase;

  constructor(
    bytes32[3] memory roots,
    uint64 _startTime,
    address _marauders,
    address _archer,
    address _merch,
    address _serum,
    string memory _uri
  ) ERC721AGuardable("Box O Bad Guys", "BoBG") Owned(msg.sender) {
    phases[Phase.NERDS_ONLY] = PhaseDetails(roots[0], _startTime);
    phases[Phase.FRIENDS_AND_FAMILY] = PhaseDetails(roots[1], _startTime + 48 hours);
    phases[Phase.PUBLIC_ALLOWLIST] = PhaseDetails(roots[2], _startTime + 72 hours);
    phases[Phase.PUBLIC] = PhaseDetails(bytes32(0), _startTime + 96 hours);

    maraudersContract = _marauders;
    archerContract = _archer;
    merchContract = _merch;
    serumContract = _serum;

    itemDetails[Item.BOX_O_BAD_GUYS] = ItemDetails(0x4e6ec247, 0, 969, 5, address(this), 0.42069 ether, 0.3333 ether);
    itemDetails[Item.ENFORCER] = ItemDetails(0x956fd85b, 0, 3069, 10, maraudersContract, 0.1 ether, 0.0666 ether);
    itemDetails[Item.WARLORD] = ItemDetails(0x680b5093, 0, 2069, 10, maraudersContract, 0.169 ether, 0.0999 ether);
    itemDetails[Item.MYSTERY_SERUM] = ItemDetails(0x91ff7e01, 0, 2069, 10, serumContract, 0.269 ether, 0.2 ether);

    baseUri = _uri;
  }

  /**
   * @notice mint function that allows minting several item types
   * @param items item types where 0 = BoBG, 1 = Enforcers, 2 = Warlords, 3 = serums
   * @param amounts a matching array to items containing the number of each item type to mint
   * @param proof your merkle proof for the current phase (for public mint, use an empty array: [])
   */
  function mint(Item[] calldata items, uint16[] calldata amounts, bytes32[] calldata proof) external payable {
    if (items.length != amounts.length) revert ArrayLengthMismatch();
    Phase phase = currentPhase();
    if (phase == Phase.NOT_STARTED) revert SaleNotActive();

    PhaseDetails memory phaseDetails = phases[phase];

    if (uint(phase) <= 3) _validateSender(phaseDetails.root, proof);

    bool isNerdsOnly = phase == Phase.NERDS_ONLY;

    uint256 totalCost = 0;

    for (uint256 i = 0; i < items.length;) {
      if (amounts[i] == 0) revert MintZeroAmount();
      unchecked {
        totalCost += priceFor(items[i], phase, amounts[i]);

        _mintItem(items[i], amounts[i], isNerdsOnly);
        ++i;
      }
    }

    if (msg.value != totalCost) revert WrongValueSent();
  }

  /**
   * @notice owner only mint function that still increments counters and reverts if maxSupply is exceeded for a given item type
   */
  function bazookaMint(Item[] calldata items, uint16[] calldata amounts) external onlyOwner {
    if (items.length != amounts.length) revert ArrayLengthMismatch();

    for (uint256 i = 0; i < items.length;) {
      unchecked {
        _mintItem(items[i], amounts[i], false);
        ++i;
      }
    }
  }

  /**
   * @notice function for smashing boxes and receiving contents in return. Your box will be burned during this process
   * @param tokenIds an array of boxes that you are prepared to burn
   */
  function smashAndGrab(uint256[] memory tokenIds) external {
    if (!smashingEnabled) revert SmashingNotActive();
    for (uint256 i = 0; i < tokenIds.length;) {
      _burn(tokenIds[i], true); // this checks ownership and also prevents duplicate tokenIds
      unchecked { ++i; }
    }

    address[4] memory mintContracts = [maraudersContract, archerContract, merchContract, serumContract];
    for (uint256 i = 0; i < mintContracts.length; i++) {
      (bool success, ) = mintContracts[i].call(abi.encodeWithSelector(0x91ff7e01, msg.sender, tokenIds.length));
      if (!success) revert FailedToMint();
    }
  }

  // VIEW FUNCTIONS

  /**
   * @dev returns the price for a given item during a given phase
   * @param item item types where 0 = BoBG, 1 = Enforcers, 2 = Warlords, 3 = serums
   * @param phase phases where 0 = NOT_STARTED, 1 = NERDS_ONLY, 2 = FRIENDS_AND_FAMILY
   * 3 = PUBLIC_ALLOWLIST, 4 = PUBLIC
   * @param amount the number of units to use in price calculation
   */
  function priceFor(Item item, Phase phase, uint256 amount) public view returns (uint256) {
    if (phase == Phase.NOT_STARTED) revert SaleNotActive();
    return uint(phase) <= 2 ? itemDetails[item].discountedPrice * amount : itemDetails[item].price * amount;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseUri;
  }

  /**
  * @notice Returns the current phase based on the current timestamp, where 
  * 0 = NOT_STARTED, 1 = NERDS_ONLY, 2 = FRIENDS_AND_FAMILY, 3 = PUBLIC_ALLOWLIST, 4 = PUBLIC
  */
  function currentPhase() public view returns (Phase) {
    if (block.timestamp < phases[Phase.NERDS_ONLY].startTime) {
      return Phase.NOT_STARTED;
    } else if (block.timestamp < phases[Phase.FRIENDS_AND_FAMILY].startTime) {
      return Phase.NERDS_ONLY;
    } else if (block.timestamp < phases[Phase.PUBLIC_ALLOWLIST].startTime) {
      return Phase.FRIENDS_AND_FAMILY;
    } else if (block.timestamp < phases[Phase.PUBLIC].startTime) {
      return Phase.PUBLIC_ALLOWLIST;
    } else {
      return Phase.PUBLIC;
    }
  }

  // OWNER ONLY FUNCTIONS

  function setRoots(Phase[] calldata _phases, bytes32[] calldata _roots) external onlyOwner {
    if (_phases.length != _roots.length) revert ArrayLengthMismatch();

    for (uint256 i = 0; i < _phases.length; i++) {
      phases[_phases[i]].root = _roots[i];
    }
  }

  function setSmashingStatus(bool status) external onlyOwner {
    smashingEnabled = status;
  }

  function setBaseURI(string memory _uri) external onlyOwner {
    baseUri = _uri;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    if (!success) revert WrongValueSent();
  }

  // INTERNAL HELPERS 

  function _validateSender(bytes32 root, bytes32[] calldata _proof) private view {
    bytes32 leaf = keccak256((abi.encodePacked(msg.sender)));

    if (!MerkleProofLib.verify(_proof, root, leaf)) {
        revert InvalidProof();
    }
  }

  function _mintItem(Item _item, uint16 amount, bool isNerdsOnly) internal {
    ItemDetails storage item = itemDetails[_item];

    if (item.numUnitsSold + amount > item.maxUnitsAllowed) revert ExceedMaxSupply();
    unchecked { item.numUnitsSold += amount; }

    if (isNerdsOnly) {
      if (numMintedDuringNerdPhase[msg.sender][_item] + amount > item.maxNerdPhaseUnitsAllowedPerWallet) revert ExceedMaxPerWallet();
      unchecked { numMintedDuringNerdPhase[msg.sender][_item] += amount; }
    }

    if (_item == Item.BOX_O_BAD_GUYS) {
      _mint(msg.sender, amount);
    } else {
      (bool success, ) = item.mintContractAddress.call(abi.encodeWithSelector(item.mintFunctionSelector, msg.sender, amount));
      if (!success) revert FailedToMint();
    }
  }
}