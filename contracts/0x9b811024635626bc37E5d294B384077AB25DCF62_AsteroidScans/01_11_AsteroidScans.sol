// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/InfluenceSettings.sol";
import "./lib/Procedural.sol";
import "./interfaces/IAsteroidToken.sol";
import "./interfaces/IAsteroidFeatures.sol";


/**
 * @dev Contract that generates randomized perks based on when the asteroid is "scanned" by its owner. Perks
 * are specific to certain types of asteroids, have varying degrees of rarity and can stack.
 */
contract AsteroidScans is Pausable, Ownable {
  using Procedural for bytes32;

  IAsteroidToken internal token;
  IAsteroidFeatures internal features;

  // Mapping indicating allowed managers
  mapping (address => bool) private _managers;

  /**
   * @dev This is a bit-packed set of:
   * << 0: the order purchased for scan boosts
   * << 64: Bit-packed number with 15 bits. The first indicates whether the asteroid
   * has been scanned, with the remainder pertaining to specific bonuses.
   * << 128: The block number to use for the randomization hash
   */
  mapping (uint => uint) internal scanInfo;

  /**
   * @dev Tracks the scan order to manage awarding early boosts to bonuses
   */
  uint public scanOrderCount = 0;

  event ScanStarted(uint indexed asteroidId);
  event AsteroidScanned(uint indexed asteroidId, uint bonuses);

  constructor(IAsteroidToken _token, IAsteroidFeatures _features) {
    token = _token;
    features = _features;
  }

  // Modifier to check if calling contract has the correct minting role
   modifier onlyManagers {
     require(isManager(_msgSender()), "Only managers can call this function");
     _;
   }

  /**
   * @dev Add a new account / contract that can mint / burn asteroids
   * @param _manager Address of the new manager
   */
  function addManager(address _manager) external onlyOwner {
    _managers[_manager] = true;
  }

  /**
   * @dev Remove a current manager
   * @param _manager Address of the manager to be removed
   */
  function removeManager(address _manager) external onlyOwner {
    _managers[_manager] = false;
  }

  /**
   * @dev Checks if an address is a manager
   * @param _manager Address of contract / account to check
   */
  function isManager(address _manager) public view returns (bool) {
    return _managers[_manager];
  }

  /**
   * @dev Sets the order the asteroid should receive boosts to bonuses
   * @param _asteroidId The ERC721 token ID of the asteroid
   */
  function recordScanOrder(uint _asteroidId) external onlyManagers {
    scanOrderCount += 1;
    scanInfo[_asteroidId] = scanOrderCount;
  }

  /**
   * @dev Returns the scan order for managing boosts for a particular asteroid
   * @param _asteroidId The ERC721 token ID of the asteroid
   */
  function getScanOrder(uint _asteroidId) external view returns(uint) {
    return uint(uint64(scanInfo[_asteroidId]));
  }

  /**
   * @dev Method to pre-scan a set of asteroids to be offered during pre-sale. This method may only be run
   * before any sale purchases have been made.
   * @param _asteroidIds An array of asteroid ERC721 token IDs
   * @param _bonuses An array of bit-packed bonuses corresponding to _asteroidIds
   */
  function setInitialBonuses(uint[] calldata _asteroidIds, uint[] calldata _bonuses) external onlyOwner {
    require(scanOrderCount == 0);
    require(_asteroidIds.length == _bonuses.length);

    for (uint i = 0; i < _asteroidIds.length; i++) {
      scanInfo[_asteroidIds[i]] |= _bonuses[i] << 64;
      emit AsteroidScanned(_asteroidIds[i], _bonuses[i]);
    }
  }

  /**
   * @dev Starts the scan and defines the future blockhash to use for
   * @param _asteroidId The ERC721 token ID of the asteroid
   */
  function startScan(uint _asteroidId) external whenNotPaused {
    require(token.ownerOf(_asteroidId) == _msgSender(), "Only owner can scan asteroid");
    require(uint(uint64(scanInfo[_asteroidId] >> 64)) == 0, "Asteroid has already been scanned");
    require(uint(uint64(scanInfo[_asteroidId] >> 128)) == 0, "Asteroid scanning has already started");

    scanInfo[_asteroidId] |= (block.number + 1) << 128;
    emit ScanStarted(_asteroidId);
  }

  /**
   * @dev Returns a set of 0 or more perks for the asteroid randomized by time / owner address
   * @param _asteroidId The ERC721 token ID of the asteroid
   */
  function finalizeScan(uint _asteroidId) external whenNotPaused {
    uint blockForHash = uint(uint64(scanInfo[_asteroidId] >> 128));
    require(uint(uint64(scanInfo[_asteroidId] >> 64)) == 0, "Asteroid has already been scanned");
    require(blockForHash != block.number && blockForHash > 0, "Must wait at least one block after starting");

    // Capture the bonuses bitpacked into a uint. The first bit is set to indicate the asteroid has been scanned.
    uint bonuses = 1;
    uint purchaseOrder = uint(uint64(scanInfo[_asteroidId]));
    uint bonusTest;
    bytes32 seed = features.getAsteroidSeed(_asteroidId);
    uint spectralType = features.getSpectralTypeBySeed(seed);

    // Add some randomness to the bonuses outcome
    uint bhash = uint(blockhash(blockForHash));

    // bhash == 0 if we're later than 256 blocks after startScan, this will default to no bonus
    if (bhash != 0) {
      seed = seed.derive(bhash);

      // Array of possible bonuses (0 or 1) per spectral type (same order as spectral types in AsteroidFeatures)
      uint8[6][11] memory bonusRates = [
        [ 1, 1, 0, 1, 0, 0 ],
        [ 1, 1, 1, 1, 0, 1 ],
        [ 1, 1, 0, 1, 0, 0 ],
        [ 1, 1, 1, 1, 1, 1 ],
        [ 1, 1, 1, 1, 1, 1 ],
        [ 1, 1, 1, 1, 1, 1 ],
        [ 1, 0, 1, 0, 1, 1 ],
        [ 1, 0, 1, 0, 1, 1 ],
        [ 1, 1, 1, 0, 1, 1 ],
        [ 1, 0, 1, 0, 0, 1 ],
        [ 1, 1, 0, 0, 0, 0 ]
      ];

      // Boosts the bonus chances based on early scan tranches
      int128 rollMax = 10001;

      if (purchaseOrder < 100) {
        rollMax = 3441; // 4x increase
      } else if (purchaseOrder < 1100) {
        rollMax = 4143; // 3x increase
      } else if (purchaseOrder < 11100) {
        rollMax = 5588; // 2x increase
      }

      // Loop over the possible bonuses for the spectral class
      for (uint i = 0; i < 6; i++) {

        // Handles the case for regular bonuses
        if (i < 4 && bonusRates[spectralType][i] == 1) {
          bonusTest = uint(seed.derive(i).getIntBetween(0, rollMax));

          if (bonusTest <= 2100) {
            if (bonusTest > 600) {
              bonuses = bonuses | (1 << (i * 3 + 1)); // Tier 1 regular bonus (15% of asteroids)
            } else if (bonusTest > 100) {
              bonuses = bonuses | (1 << (i * 3 + 2)); // Tier 2 regular bonus (5% of asteroids)
            } else {
              bonuses = bonuses | (1 << (i * 3 + 3)); // Tier 3 regular bonus (1% of asteroids)
            }
          }
        }

        // Handle the case for the special bonuses
        if (i >= 4 && bonusRates[spectralType][i] == 1) {
          bonusTest = uint(seed.derive(i).getIntBetween(0, rollMax));

          if (bonusTest <= 250) {
            bonuses = bonuses | (1 << (i + 9)); // Single tier special bonus (2.5% of asteroids)
          }
        }
      }

      // Guarantees at least a level 1 yield bonus for the early adopters
      if (purchaseOrder < 11100 && bonuses == 1) {
        bonuses = 3;
      }
    }

    scanInfo[_asteroidId] |= bonuses << 64;
    emit AsteroidScanned(_asteroidId, bonuses);
  }

  /**
   * @dev Query for the results of an asteroid scan
   * @param _asteroidId The ERC721 token ID of the asteroid
   */
  function retrieveScan(uint _asteroidId) external view returns (uint) {
    return uint(uint64(scanInfo[_asteroidId] >> 64));
  }
}