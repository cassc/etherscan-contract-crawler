// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ECDSA }   from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { PaymentSplitter } from "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%##*+=======-+#%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%#**+=======+**#%%%%%%%%*-=%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#**+======++*##%@@@@@@@@@@%%%%%%%%%%%==%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@%#**++++=+++**#%%@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%#.%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@#*+======+*#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%:#%%%%%%%%%%%%%%
@@@@@@@@@@@%==*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%==%%%%%%%%%%%%%%
@@@@@@@@@@%:%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%#.%%%%%%%%%%%%%%
@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@%%%%%%%%%:#%%%%%%%%%%%%%
@@@@@@@@@@*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#***%@@+:.     -%@@@@@@@%%%%%%%%+=%%%%%%%%%%%%%
@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@#=-*@+      :%*   =+-  :@@@@@@@@%%%%%%%#.%%%%%%%%%%%%%
@@@@@@@@@@@-#@@@@@@@@@@@@@@@@+. [email protected]@@+  =%   *#-  [email protected]   *@%   #@@@@@@@%%%%%%%%:#%%%%%%%%%%%%
@@@@@@@@@@@*[email protected]@@@@@@@@@@@@@@@@...*@@+  =%   #@%*#%@-  :@@:  [email protected]@@@@@@@%%%%%%%==%%%%%%%%%%%%
@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@#..:@@*[email protected]+...-*%@@@*   =-   *@@@@@@@@@%%%%%%#.%%%%%%%%%%%%
@@@@@@@@@@@@-#@@@@@@@@@@@@@@@@@[email protected]*[email protected]@%-....-#@@.    .-#@@@@@@@@@@@%%%%%%:#%%%%%%%%%%%
@@@@@@@@@@@@*[email protected]@@@@@@@@@@@@@@@@%::.##[email protected]@@@%*[email protected]:@@@@@@@@@@@@@@@@%%%%%==%%%%%%%%%%%
@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@*::-#.:[email protected]@#*+%@%:..**...%@@@@@@@@@@@@@@@@%%%%#:%%%%%%%%%%%
@@@@@@@@@@@@@-#@@@@@@@@@@@@@@@@@@=::-::[email protected]@+::-##::.*@[email protected]@@@@@@@@@@@@@@@@%%%%:#%%%%%%%%%%
@@@@@@@@@@@@@*[email protected]@@@@@@@@@@@@@@@@@%:-:::[email protected]@@=::::::[email protected]@+=+*@@@@@@@@@@@@@@@@@@%%%==%%%%%%%%%%
@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@*---:[email protected]@@@%#*##@@@@@@@@@@@@@@@@@@@@@@@@@@%%%#:%%%%%%%%%%
@@@@@@@@@@@@@@:#@@@@@@@@@@@@@@@@@@@##%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%.%%%%%%%%%%
@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*-%%%%%%%%%%
@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*-=%%%%%%%%%%%
@@@@@@@@@@@@@@@:#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#*+=======*%%%%%%%%%%%%%
@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##*++=====++*##%%%%%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@%[email protected]@@@@@@@@@@@@@@@@@@@@@@@%##*+++++++++*##%@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@*-#@@@@@@@@@@%##*++++++++**#%%@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@*=+++++++++*##%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%
*/

// Contract by: @backseats_eth

// Errors

error BadID();
error CantMintZero();
error ExceedsSupply();
error IDAlreadyUsed();
error InvalidSignature();
error InvalidSlot();
error MintDisabled();
error MissingSystemAddress();
error NoContracts();
error UsedNonce();

interface IVSP {
  function ownerOf(uint256 tokenId) external returns (address);
}

contract VSPxEightBitMe is ERC1155, Ownable, PaymentSplitter {
  using ECDSA for bytes32;
  using Strings for uint256;

  uint256 constant BASEBALL   = 1;
  uint256 constant BASKETBALL = 2;
  uint256 constant ESPORTS    = 3;
  uint256 constant FOOTBALL   = 4;
  uint256 constant GOLF       = 5;
  uint256 constant HOCKEY     = 6;
  uint256 constant MMA        = 7;
  uint256 constant SOCCER     = 8;
  uint256 constant TENNIS     = 9;
  uint256 constant VOLLEYBALL = 10;
  uint256 constant LAVA       = 11;
  uint256 constant GOLD       = 12;
  uint256 constant BUBBLEGUM  = 13;
  uint256 constant DIAMOND    = 14;
  uint256 constant HOLOGRAM   = 15;

  // This is redundant due to a 1:1 claim with each VSP token
  uint256 constant MAX_SUPPLY = 15_555;

  // Not needed but nice to have for good measure
  uint256 public totalSupply;

  // 15_555 1s that we flip to 0s when a particular ID has been used
  uint256[] _usedIdSlots;

  // If the mint is enabled or not
  bool public mintEnabled;

  // The address that correspondings to the private key signing on the server
  address public systemAddress;

  // The baseURI of where metadata is being served from
  string private _baseURI;

  // A mapping of nonces that have been used to mint
  mapping(string => bool) private _usedNonces;

  constructor(address[] memory _payees, uint256[] memory _shares) ERC1155("") PaymentSplitter(_payees, _shares) {}

  /**
  @notice This function allows you to mint various EightBit.Me trophies depending on how
  you have allocated your credits. Requires a signature from the server to ensure token ownership
  */
  function mintMyTrophies(uint256[][] calldata _counts, string calldata _nonce, bytes calldata _signature) external {
    if (msg.sender != tx.origin) revert NoContracts();
    if (!mintEnabled) revert MintDisabled();
    if (!isValidSignature(keccak256(abi.encodePacked(msg.sender, _nonce)), _signature)) revert InvalidSignature();
    if (_usedNonces[_nonce]) revert UsedNonce();

    // A counter to check against total supply before minting
    uint256 totalToMint;

    IVSP vsp = IVSP(0xbcE6D2aa86934AF4317AB8615F89E3F9430914Cb);

    // An array for use after checking if we've used those IDs already
    uint256[] memory tierCountsToMint = new uint256[](15);

    // Loop through the array of arrays
    for(uint256 i; i < _counts.length;) {

      // Run 15 inner loops
      uint256 localCount;
      for(uint256 n; n < _counts[i].length;) {
        // Check each piece hasn't been claimed and that msg.sender owns it
        uint256 id = _counts[i][n];
        if (!hasIdBeenUsed(id) && vsp.ownerOf(id) == msg.sender) {
          // Increment the local count for the tier and the total across all tiers
          unchecked {
            ++localCount;
            ++totalToMint;
          }
          // Flip ID 1 -> 0 to record it was used
          _recordIdUsed(id);
        }

        // Increment inner loop
        unchecked { ++n; }
      }

      // Set the count to mint for that tier in the array
      tierCountsToMint[i] = localCount;

      // Increment outer loop
      unchecked { ++i; }
    }

    if (totalToMint == 0) revert CantMintZero();
    if (totalSupply + totalToMint > MAX_SUPPLY) revert ExceedsSupply();

    // Increment the total supply
    totalSupply += totalToMint;

    // Record the nonce so it's not re-used
    _usedNonces[_nonce] = true;

    mintTiers(tierCountsToMint);
  }

  /**
  @notice Mints various amounts of each tier depending on your allocations
  */
  function mintTiers(uint256[] memory _array) internal {
    for(uint256 i; i < _array.length;) {
      if (_array[i] > 0) {
        // Adds 1 to i because the tiers are base 1-based and the loop is base 0-based
        _mint(msg.sender, (i + 1), _array[i], "");
      }

      unchecked { ++i; }
    }
  }

  // Setters

  /**
  @notice Enables/disables mint
  */
  function setMintEnabled(bool _val) external onlyOwner {
    mintEnabled = _val;
  }

  /**
  @notice Sets the system address corresponding to the private key signing on the server
  */
  function setSystemAddress(address _systemAddress) external onlyOwner {
    systemAddress = _systemAddress;
  }

  /**
  @notice Sets the BaseURI
  */
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseURI = baseURI;
  }

  /**
  @notice See {IERC1155MetadataURI-uri}
  */
  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : "";
  }

  /**
  @notice Verifies that the signature sent through is signed by the system address
  */
  function isValidSignature(bytes32 hash, bytes calldata signature) internal view returns (bool) {
    if (systemAddress == address(0)) revert MissingSystemAddress();
    bytes32 signedHash = hash.toEthSignedMessageHash();
    return signedHash.recover(signature) == systemAddress;
  }

  // Storage

  /**
  @notice Returns whether an id has already been used
  */
  function hasIdBeenUsed(uint256 _vspId) public view returns (bool) {
    if (_vspId >= _usedIdSlots.length * 256) revert InvalidSlot();

    uint256 storageOffset; // [][][]
    uint256 localGroup; // [][x][]
    uint256 offsetWithin256; // 0xF[x]FFF

    unchecked {
      storageOffset = _vspId / 256;
      offsetWithin256 = _vspId % 256;
    }
    localGroup = _usedIdSlots[storageOffset];

    return ((localGroup >> offsetWithin256) & uint256(1) != 1);
  }

  /**
  @notice To check if a VSP is being used
  @dev Returns error if id is larger than range or has been used already
  @dev Uses bit manipulation in place of mapping
  @dev https://medium.com/donkeverse/hardcore-gas-savings-in-nft-minting-part-3-save-30-000-in-presale-gas-c945406e89f0
  @param _vspId is the id of the token being used
  */
  function _recordIdUsed(uint256 _vspId) internal {
    if (_vspId >= _usedIdSlots.length * 256) revert InvalidSlot();

    uint256 storageOffset; // [][][]
    uint256 localGroup; // [][x][]
    uint256 offsetWithin256; // 0xF[x]FFF

    unchecked {
      storageOffset = _vspId / 256;
      offsetWithin256 = _vspId % 256;
    }
    localGroup = _usedIdSlots[storageOffset];

    // [][x][] > 0x1111[x]1111 > 1
    if (hasIdBeenUsed(_vspId)) revert IDAlreadyUsed();

    // [][x][] > 0x1111[x]1111 > (1) flip to (0)
    localGroup = localGroup & ~(uint256(1) << offsetWithin256);

    _usedIdSlots[storageOffset] = localGroup;
  }

  /**
  @notice This is a cheaper way of handling which IDs have been used to mint rather than using a mapping
  Thanks xtremetom. Credit Cool Pets Contract: https://www.contractreader.io/contract/0x86c10d10eca1fca9daf87a279abccabe0063f247
  */
  function setUsedSlotLength(uint256 num) external onlyOwner {
    // Prevents over-filling
    if (num > 15_555) revert BadID();

    // Account for solidity rounding down
    uint256 slotCount = (num / 256) + 1;

    // Set each element in the slot to binaries of 1
    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // Create a temporary array based on number of slots required
    uint256[] memory arr = new uint256[](slotCount);

    // Fill each element with MAX_INT
    for (uint256 i; i < slotCount; i++) {
      arr[i] = MAX_INT;
    }

    _usedIdSlots = arr;
  }

}