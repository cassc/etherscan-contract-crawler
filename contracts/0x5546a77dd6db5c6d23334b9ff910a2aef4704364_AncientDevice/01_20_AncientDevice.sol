// SPDX-License-Identifier: MIT LICENSE  
/*

'########:'##::::'##:'########::::                                                         
... ##..:: ##:::: ##: ##.....:::::                                                         
::: ##:::: ##:::: ##: ##::::::::::                                                         
::: ##:::: #########: ######::::::                                                         
::: ##:::: ##.... ##: ##...:::::::                                                         
::: ##:::: ##:::: ##: ##::::::::::                                                         
::: ##:::: ##:::: ##: ########::::                                                         
:::..:::::..:::::..::........:::::                                                         
'##::::'##:'########:'########:::'######::'##::::'##:'########::'####::::'###::::'##::: ##:
 ###::'###: ##.....:: ##.... ##:'##... ##: ##:::: ##: ##.... ##:. ##::::'## ##::: ###:: ##:
 ####'####: ##::::::: ##:::: ##: ##:::..:: ##:::: ##: ##:::: ##:: ##:::'##:. ##:: ####: ##:
 ## ### ##: ######::: ########:: ##::::::: ##:::: ##: ########::: ##::'##:::. ##: ## ## ##:
 ##. #: ##: ##...:::: ##.. ##::: ##::::::: ##:::: ##: ##.. ##:::: ##:: #########: ##. ####:
 ##:.:: ##: ##::::::: ##::. ##:: ##::: ##: ##:::: ##: ##::. ##::: ##:: ##.... ##: ##:. ###:
 ##:::: ##: ########: ##:::. ##:. ######::. #######:: ##:::. ##:'####: ##:::: ##: ##::. ##:
..:::::..::........::..:::::..:::......::::.......:::..:::::..::....::..:::::..::..::::..::
'########::'########:::'#######::::::::'##:'########::'######::'########:                  
 ##.... ##: ##.... ##:'##.... ##::::::: ##: ##.....::'##... ##:... ##..::                  
 ##:::: ##: ##:::: ##: ##:::: ##::::::: ##: ##::::::: ##:::..::::: ##::::                  
 ########:: ########:: ##:::: ##::::::: ##: ######::: ##:::::::::: ##::::                  
 ##.....::: ##.. ##::: ##:::: ##:'##::: ##: ##...:::: ##:::::::::: ##::::                  
 ##:::::::: ##::. ##:: ##:::: ##: ##::: ##: ##::::::: ##::: ##:::: ##::::                  
 ##:::::::: ##:::. ##:. #######::. ######:: ########:. ######::::: ##::::                  
..:::::::::..:::::..:::.......::::......:::........:::......::::::..:::::                                    
                                                                                
                                             @@@@@@@@@@@@@@                     
                                          @@             ..   @@@@@             
                                       @@@        ....      ,,..   @@@          
                                   @@  ./((((((((%%%%%%%%(((((  .    ,    @     
                                   @@..%%%%%(((.....(((%%%%(%%((   ,,   ,,,@@   
                              @@%%%((...               ..../%%%%(              @
                             @%%%%(..                    ../%%(((          ,,,,@
                         @@%%%((..                         /////(     ,,,,,//,,@
                      @@@look(....                         /%%//     ,,,,,/,,((@
                   @((%%%**.......                       %%%       ,,,//,,(((((@
               @@@@%%%%%*.... ....                     %%//   ,,,,,///,,((,/(@@ 
            @@,%%%%%..          ...     ..     .. ..//(  ,,,,,,,/,,,,,/((((((@@ 
         @@@,,%%%.......          ...       .  ...//((   ,,,////,,,,,,/(((,@@   
     @@  ,%%((........     ...            .....//(    ,,,,,,,,,,,%%,,,/(((@     
  @@@  ,,%  ...    .....   ..             ..///,,   ,,,,,,,%@@%%for,,/(@@      
@@  ,%%%%(((............           .... ..((,  ,,/,,,,,  ,,@@@%%%@@             
@@     ,,%@@(((.......             ....%((,,   ...//,,,  ((@@@@@%@@             
  @[email protected],    ,((%%(((...     .....  ((     .///////@@@((((@@@@@                
    @@@@@,((     ,,%((((.....   ...((,,.  ..////////@@@((((@                    
     @@/////,,(,,     ,,(%%(((((((      /////@@((/[email protected]@@
     @@(((((@@(((,,,,,  ,(((((((   ,,,,%////%@@@@/@@@@@                         
            @@(((@@/[email protected]@,          %%%%/////(@@@@(@@                            
              @@@@@(@@@@@,,       /,,@@@////(@@@@@                              
                    @@(((@@/////,,.//@@@////@                                   
                      @@(((//////////@@@@@//@                                   
                           @@[email protected]                                             
                             @%%%%@  

  A Melange Labs Project
  Founder:          @atreidesETH
  Contract Author:  @BlockDaddyy
  Auditor:          @ItsCuzzo      

*/                                                                           

pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./OwnableWithAdmin.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./MAGNESIUM.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AncientDevice is ERC721Enumerable, OwnableWithAdmin, Pausable, ReentrancyGuard {
  
  using Strings for uint256;

  bytes32 public whitelistMerkleRoot;
  mapping(address => bool) public addressHasClaimed; // track whitelisters

  uint256 constant MAX_DEVICES_SUPPLY = 1390;
  uint256 constant SECONDS_PER_DAY    = 1 days;
  uint256 public   yieldEndTime       = 1742839200; // March 24, 2025, 19:00 UTC: Mercury's first Inferior Conjunction of 2025

  string public baseURI;
  string public baseExtension;

  uint256 private lineOfClue;

  mapping(uint256 => Device) public devices;

  struct Device {
    uint16 level; // maxval 255 ... yield = (2**(uint256(level-1))) ether
    uint240 lastClaimTimestamp; // stored in seconds, no chance of overflow
  }

  event AncientDevicesClaimed(address recipient, uint256 amount);
  event MagnesiumClaimed(address recipient, uint256 tokenId, uint256 amount);
  event DeviceUpgradedMagClaimed(address user, uint256 tokenId, uint256 targetLevel, uint256 amount);

  MAGNESIUM public magnesium;

  constructor(address _magnesium) ERC721("Ancient Devices", "ANCIENT DEVICES") {
      magnesium = MAGNESIUM(_magnesium);
      _pause();
  }

  /**
    * @dev include trailing /
    */
  function setBaseURI(string memory _baseURI) external onlyOwnerOrAdmin {
      baseURI = _baseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) external onlyOwnerOrAdmin {
      baseExtension = _newBaseExtension;
  }

  function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwnerOrAdmin {
      whitelistMerkleRoot = _whitelistMerkleRoot;
  }

  function setMagnesiumAddress(address _newMagAddress) external onlyOwnerOrAdmin {
      magnesium = MAGNESIUM(_newMagAddress);
  }

  function setYieldEndTime(uint256 _newTime) external onlyOwnerOrAdmin {
      uint256 currentTime = block.timestamp;
      require(currentTime < yieldEndTime, "yieldEndTime can't be changed once the end time has past");
      require(currentTime < _newTime, "yieldEndTime can only be changed to a time in the future");
      yieldEndTime = _newTime;
  }

  function setLineOfClue(uint256 _lineNumber) external onlyOwnerOrAdmin {
      lineOfClue = _lineNumber;
  }

  /**
   * enables owner or admin to pause / unpause minting, claiming mag, and upgrading
   */
  function setPaused(bool _paused) external onlyOwnerOrAdmin {
    if (_paused) _pause(); // Pausable
    else _unpause();
  }

  /**
   * it's a secret
   */
  function setSecretUnlockEnabled(bool _enable) external onlyOwnerOrAdmin {
    if (_enable) _enableSecretUnlock(); // Pausable
    else _disableSecretUnlock();
  }

  // CLAIMING DEVICES

  function claimDevices(uint256 _amount, bytes32[] calldata _merkleProof, uint256 _allowance) external whenNotPaused nonReentrant {
    uint256 totalSupply = _owners.length;
    require(totalSupply + _amount <= MAX_DEVICES_SUPPLY, "Exceeds max supply");
    require(_amount > 0, "You must claim an amount greater than 0");
    require(_amount <= _allowance, "You cant mint more than your allowance");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _allowance));
    require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid Merkle Tree proof supplied.");
    require(!addressHasClaimed[_msgSender()], "You have already claimed devices"); // User can only claim once
    addressHasClaimed[_msgSender()] = true; // can only claim once
    for(uint i; i < _amount; i++) { 
      devices[totalSupply + i] = Device({
        level: uint16(1),
        lastClaimTimestamp: uint240(block.timestamp)
      });
      _mint(_msgSender(), totalSupply + i);
    }
    emit AncientDevicesClaimed(_msgSender(), _amount);
  }

  function claimReserves(address _to, uint _amount) external onlyOwner {
    uint256 totalSupply = _owners.length;
    require(totalSupply + _amount <= MAX_DEVICES_SUPPLY, "Exceeds max supply.");
    for(uint i; i < _amount; i++) { 
      devices[totalSupply + i] = Device({
        level: uint16(1),
        lastClaimTimestamp: uint240(block.timestamp)
      });
      _mint(_to, totalSupply + i);
    }
    emit AncientDevicesClaimed(_to, _amount);
  }

  // Claiming MAG

  /**
   * the amount of MAG currently available to claim in a device
   * @param tokenId the token to check the MAG for
   */
  function magnesiumAvailable(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "Token does not exist");
    Device memory device = devices[tokenId];
    uint256 currentTimestamp = block.timestamp;
    
    if (currentTimestamp > yieldEndTime) // if its past the yield end time
      currentTimestamp = yieldEndTime; // stop the yield at yield end time
    if (device.lastClaimTimestamp > currentTimestamp) return 0; 

    uint256 elapsedSeconds = currentTimestamp - device.lastClaimTimestamp;
    uint256 earnedPerSecond = (2**((uint256(device.level))-1)) * 1 ether / SECONDS_PER_DAY;
    return earnedPerSecond * elapsedSeconds;
  }

  /**
   * the amount of MAG currently available to claim in a set of device
   * @param tokenIds the tokens to check MAG for
   */
  function magnesiumAvailableInMany(uint256[] calldata tokenIds) external view returns (uint256) {
    uint256 available;
    uint256 totalAvailable;
    require(tokenIds.length > 0, "You cannot pass an empty array");
    for (uint i = 0; i < tokenIds.length; i++) {
      available = magnesiumAvailable(tokenIds[i]);
      totalAvailable += available;
    }
    return totalAvailable;
  }

  function claimMagFromMany(uint256[] calldata _tokenIds) external whenNotPaused nonReentrant {
    uint256 available;
    uint256 totalAvailable;
    require(_tokenIds.length > 0, "You cannot pass an empty array");
    for (uint i = 0; i < _tokenIds.length; i++) {
      require(ownerOf(_tokenIds[i]) == _msgSender(), "NOT YOUR DEVICE(S)");
      available = magnesiumAvailable(_tokenIds[i]);
      Device storage device = devices[_tokenIds[i]];
      device.lastClaimTimestamp = uint240(block.timestamp);
      emit MagnesiumClaimed(_msgSender(), _tokenIds[i], available);
      totalAvailable += available;
    }
    require(totalAvailable > 0, "NO MAG AVAILABLE");
    magnesium.mint(_msgSender(), totalAvailable); // trusted
  }

  // DEVICE UPGRADES

  /** 
   * Upgrade a device (One device at a time. You can upgrade multiple levels at once)
   */
  function upgradeDeviceAndClaim(uint256 _tokenId, uint256 _targetLevel) external whenNotPaused nonReentrant {
    require(_msgSender() == ownerOf(_tokenId), "NOT YOUR DEVICE");
    Device storage device = devices[_tokenId];
    require(device.level < _targetLevel, "Must be an upgrade");
    require(_targetLevel < 6, "Max known level is 5");

    // if there's mag, claim it
    uint256 available = magnesiumAvailable(_tokenId);
    if (available > 0) {
      device.lastClaimTimestamp = uint240(block.timestamp);
      magnesium.mint(_msgSender(), available);
    }

    // upgrade
    uint256 magCost = upgradeCost(device.level, _targetLevel);
    require(magnesium.balanceOf(_msgSender()) > magCost, "You do not have enough MAG for this upgrade");
    magnesium.burn(_msgSender(), magCost);
    device.level = uint16(_targetLevel);
    emit DeviceUpgradedMagClaimed(_msgSender(), _tokenId, _targetLevel, available);
  } 

  /*
   * User can upgrade 1 level at a time or multiple levels at a time
   * 1 to 2 : 7 MAG
   * 2 to 3 : 35 MAG
   * 3 to 4 : 350 MAG
   * 4 to 5 : 3000 MAG
   * @param _level current level of device
   * @param _targetLevel the level the user would like to upgrade to
   * @return the cost of upgrade
   */
  function upgradeCost(uint _level, uint _targetLevel) internal pure returns (uint256) {
    uint256 totalCost;
    while(_level < _targetLevel){ // 377981
      if (_level == 1)      totalCost += 7 ether;
      else if (_level == 2) totalCost += 35 ether;
      else if (_level == 3) totalCost += 350 ether;
      else if (_level == 4) totalCost += 3000 ether;
      _level++;
    }
    return totalCost;
  }

  function getUpgradeCost(uint256 _tokenId, uint _targetLevel) external view returns (uint256) {
    uint256 totalCost;
    uint16 level = devices[_tokenId].level;
    while(level < _targetLevel){
      if (level == 1)      totalCost += 7 ether;
      else if (level == 2) totalCost += 35 ether;
      else if (level == 3) totalCost += 350 ether;
      else if (level == 4) totalCost += 3000 ether;
      level++;
    }
    return totalCost;
  }

  function getLevel(uint256 _tokenId) external view returns (uint16) {
    require(_exists(_tokenId), "Token does not exist");
    return devices[_tokenId].level;
  }

  function secretUnlockWithClaimIfNeeded(uint256 _tokenId) external whenNotPaused whenSecretUnlockEnabled nonReentrant {
    require(_msgSender() == ownerOf(_tokenId), "Not your device");
    require(block.timestamp > yieldEndTime, "Device not ready");
    Device storage device = devices[_tokenId];
    require(device.level == 5, "Must be level 5 to unlock a device");
    uint256 available = magnesiumAvailable(_tokenId); // placed here intentionally
    device.level = uint16(6);
    if (available > 0) { //if there is mag in the device, claim it
      device.lastClaimTimestamp = uint240(block.timestamp);
      magnesium.mint(_msgSender(), available); // trusted
    }
  }

  function getClue() external view returns (string memory) {
    return string(abi.encodePacked("Line #", Strings.toString(lineOfClue))); 
  }

  // Overrides

  /** 
   Override to make sure that transfers can't be frontrun
  */
  function transferFrom(address from, address to, uint256 tokenId) public override nonReentrant {
    require(devices[tokenId].lastClaimTimestamp < block.timestamp, "Cannot claim immediately before a transfer");
    super.transferFrom(from, to, tokenId);
  }

  /** 
   Override to make sure that transfers can't be frontrun
  */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override nonReentrant {
    require(devices[tokenId].lastClaimTimestamp < block.timestamp, "Cannot claim immediately before a transfer");
    super.safeTransferFrom(from, to, tokenId, _data);
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), baseExtension));
  }

  function _mint(address to, uint256 tokenId) internal virtual override {
    _owners.push(to);
    emit Transfer(address(0), to, tokenId);
  }

}