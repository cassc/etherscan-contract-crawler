// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IAsteroidToken.sol";
import "../interfaces/IAsteroidFeatures.sol";
import "../interfaces/IAsteroidScans.sol";
import "../interfaces/ICrewToken.sol";
import "../interfaces/ICrewFeatures.sol";


/**
 * @dev Manages the second sale including both asteroids and crew distribution for the first 11,100
 */
contract ArvadCrewSale is Ownable {
  IAsteroidToken asteroids;
  IAsteroidFeatures astFeatures;
  IAsteroidScans scans;
  ICrewToken crew;
  ICrewFeatures crewFeatures;

  // Mapping from asteroidId to bool whether it's been used to generate a crew member
  mapping (uint => bool) private _asteroidsUsed;

  uint public saleStartTime; // in seconds since epoch
  uint public baseAsteroidPrice;
  uint public baseLotPrice;
  uint public startScanCount; // count of total purchases when the sale starts
  uint public endScanCount; // count of total purchases after which to stop the sale

  event SaleCreated(uint indexed start, uint asteroidPrice, uint lotPrice, uint startCount, uint endCount);
  event SaleCancelled(uint indexed start);
  event AsteroidUsed(uint indexed asteroidId, uint indexed crewId);

  /**
   * @param _asteroids Reference to the AsteroidToken contract address
   * @param _astFeatures Reference to the AsteroidFeatures contract address
   * @param _scans Reference to the AsteroidScans contract address
   * @param _crew Reference to the CrewToken contract address
   * @param _crewFeatures Reference to the CrewFeatures contract address
   */
  constructor(
    IAsteroidToken _asteroids,
    IAsteroidFeatures _astFeatures,
    IAsteroidScans _scans,
    ICrewToken _crew,
    ICrewFeatures _crewFeatures
  ) {
    asteroids = _asteroids;
    astFeatures = _astFeatures;
    scans = _scans;
    crew = _crew;
    crewFeatures = _crewFeatures;
  }

  /**
   * @dev Sets the initial parameters for the sale
   * @param _startTime Seconds since epoch to start the sale
   * @param _perAsteroid Price in wei per asteroid
   * @param _perLot Additional price per asteroid multiplied by the surface area of the asteroid
   * @param _startScanCount Starting scan count for the sale, impacts which collection is minted for crew
   * @param _endScanCount End the sale once this scan order is reached
   */
  function createSale(
    uint _startTime,
    uint _perAsteroid,
    uint _perLot,
    uint _startScanCount,
    uint _endScanCount
  ) external onlyOwner {
    saleStartTime = _startTime;
    baseAsteroidPrice = _perAsteroid;
    baseLotPrice = _perLot;
    startScanCount = _startScanCount;
    endScanCount = _endScanCount;
    emit SaleCreated(saleStartTime, baseAsteroidPrice, baseLotPrice, startScanCount, endScanCount);
  }

  /**
   * @dev Cancels a future or ongoing sale
   **/
  function cancelSale() external onlyOwner {
    require(saleStartTime > 0, "ArvadCrewSale: no sale defined");
    _cancelSale();
  }

  /**
   * @dev Retrieve the price for the given asteroid which includes a base price and a price scaled by surface area
   * @param _tokenId ERC721 token ID of the asteroid
   */
  function getAsteroidPrice(uint _tokenId) public view returns (uint) {
    require(baseAsteroidPrice > 0 && baseLotPrice > 0, "ArvadCrewSale: base prices must be set");
    uint radius = astFeatures.getRadius(_tokenId);
    uint lots = (radius * radius) / 250000;
    return baseAsteroidPrice + (baseLotPrice * lots);
  }

  /**
   * @dev Purchase an asteroid
   * @param _asteroidId ERC721 token ID of the asteroid
   **/
  function buyAsteroid(uint _asteroidId) external payable {
    require(block.timestamp >= saleStartTime, "ArvadCrewSale: no active sale");
    require(msg.value == getAsteroidPrice(_asteroidId), "ArvadCrewSale: incorrect amount of Ether sent");
    uint scanCount = scans.scanOrderCount();
    require(scanCount < endScanCount, "ArvadCrewSale: sale has completed");

    asteroids.mint(_msgSender(), _asteroidId);
    scans.recordScanOrder(_asteroidId);

    // Complete sale if no more crew members available
    if (scanCount == (endScanCount - 1)) {
      _cancelSale();
      unlockCitizens();
    }
  }

  /**
   * @dev Mints a crew member with an existing, already purchased asteroid
   * @param _asteroidId The ERC721 tokenID of the asteroid
   */
  function mintCrewWithAsteroid(uint _asteroidId) external {
    require(asteroids.ownerOf(_asteroidId) == _msgSender(), "ArvadCrewSale: caller must own the asteroid");
    require(!_asteroidsUsed[_asteroidId], "ArvadCrewSale: asteroid has already been used to mint crew");
    uint scanOrder = scans.getScanOrder(_asteroidId);
    require(scanOrder > 0 && scanOrder <= endScanCount, "ArvadCrewSale: crew not mintable with this asteroid");
    uint scanCount = scans.scanOrderCount();
    require(scanOrder <= startScanCount || scanCount >= endScanCount, "ArvadCrewSale: Scanning citizens not unlocked");

    // Mint crew token and record asteroid usage
    uint crewId = crew.mint(_msgSender());

    if (scanOrder <= startScanCount) {
      // Record crew as Arvad Specialists (collection #1) in CrewFeatures
      crewFeatures.setToken(crewId, 1, (250000 - _asteroidId) * (250000 - _asteroidId) / 25000000);
    } else {
      // Record crew as Arvad Citizens (collection #2) in CrewFeatures
      crewFeatures.setToken(crewId, 2, (250000 - _asteroidId) * (250000 - _asteroidId) / 25000000);
    }

    _asteroidsUsed[_asteroidId] = true;
    emit AsteroidUsed(_asteroidId, crewId);
  }

  /**
   * @dev Withdraw Ether from the contract to owner address
   */
  function withdraw() external onlyOwner {
    uint balance = address(this).balance;
    _msgSender().transfer(balance);
  }

  /**
   * @dev Unlocks Arvad Citizens attribute generation by setting a seed. Can be called by anyone.
   */
  function unlockCitizens() internal {
    require(scans.scanOrderCount() >= endScanCount, "ArvadCrewSale: all asteroids must be sold first");
    bytes32 seed = blockhash(block.number - 1);
    crewFeatures.setGeneratorSeed(2, seed);
  }

  /**
   * @dev Unlocks Arvad Citizens attribute generation before all asteroids are sold as a backup
   */
  function emergencyUnlockCitizens() external onlyOwner {
    bytes32 seed = blockhash(block.number - 1);
    crewFeatures.setGeneratorSeed(2, seed);
  }

  /**
   * @dev Internal sale cancellation method
   */
  function _cancelSale() private {
    emit SaleCancelled(saleStartTime);
    saleStartTime = 0;
    baseAsteroidPrice = 0;
    baseLotPrice = 0;
  }
}