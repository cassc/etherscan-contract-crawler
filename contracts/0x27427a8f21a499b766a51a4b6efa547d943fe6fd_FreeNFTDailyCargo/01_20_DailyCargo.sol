// SPDX-License-Identifier: Unliscensed

pragma solidity ^0.8.17;


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";  

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract FreeNFTDailyCargo is ERC721A, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, DefaultOperatorFilterer {

  /* ------------------------------------ *\

  ||||||||||||||||||||||||||||||||||||||||||
  ||| ------- ERC721A/PROXY SET-UP ------ ||
  ||||||||||||||||||||||||||||||||||||||||||

  \* ------------------------------------ */

  using Strings for uint256;
  using ECDSA for bytes32;
  string suffix;

  function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _name = "Daily Cargo";
        _symbol = "DC";
        _currentIndex = _startTokenId();
  }

  function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

  string description = "Go to https://freenft.xyz every day to upgrade your cargo, maintain your streak and win rewards.";
  string externalUrl = "https://freenft.xyz";
  string baseURI = "https://a2vh8vk6r7.execute-api.us-east-1.amazonaws.com/prod/daily_chest_image/";
  string baseName = "Daily Cargo #";

  string attributesStart = '[{"trait_type": "Streak", "value":';
  string attributesEnd = "}]";



  /* ------------------------------------ *\

  ||||||||||||||||||||||||||||||||||||||||||
  ||| ---- DAILY CONTAINER VARIABLES --- |||
  ||||||||||||||||||||||||||||||||||||||||||

  \* ------------------------------------ */

  address signerAddress;

  /**
   * @notice struct defining a player.
   * @param lastClaimed the last time the player claimed a cargo.
   * @param streak the number of consecutive daily cargos minted by the
   * player.
   * @param activeChestId the id of the ctonainer the player is currently upgrading.
   */
  struct Player {
    uint64 lastClaimed;
    uint64 streak;
    uint128 activeCargoId;
  }

  /**
   * @notice mapping from address to their player data.
   * @dev keeps track of the last time a player claimed a cargo, the number
   * of consecutive days they have claimed a cargo, and the id of the chest
   * @dev used in { getDailyCargo } to determine if a player can upgrade
   * their cargo, or need to mint a new one.
   */
  mapping(address => Player) public players;

  /**
   * @notice keeps track of a cargo's streak. A cargo's streak is the number of
   * times { getDailyCargo } has been called by the minter of the cargo consecutively
   * without missing a day.
   * 
   * @dev this is incremented in { getDailyCargo } if the sender is on time. A cargo
   * streak can becomes immutable if the sender is not on time - they must mint
   * a new cargo and start a new streak. Nonetheless, the cargo's streak is still
   * stored and the ERC721 is still ownable/tradeable.
   */
  mapping (uint256 => uint256) public cargoStreak;


  /**
   * @notice one/two day/s in seconds.
   * 
   * @dev used in time calculations in { getDailyCargo } and { missedADay }
   */
  uint256 private constant DAY_IN_SECONDS = 86400;
  uint256 private constant TWO_DAYS_IN_SECONDS = 86400 * 2;



  /* ------------------------------------ *\

  ||||||||||||||||||||||||||||||||||||||||||
  ||| ----- DAILY CONTAINER FUNCTIONS -- |||
  ||||||||||||||||||||||||||||||||||||||||||

  \* ------------------------------------ */


  //TODO: SIGNATURE INPUT

  /**
   * @notice mints a new ERC721 cargo for the sender if they haven't minted before
   * OR updates their existing cargo's streak if they call within the 24 hour window
   * starting when the function becomes callable again.
   * @notice the function becomes callable again after 24 hours.
   */
  function getDailyCargo(bytes calldata _signature) public nonReentrant onlyProxy {
    
    // gets the timestamp the address last called the function at //
    // then checks they did not call the function less than a day ago //

    Player memory player = players[msg.sender];

    uint256 lastMintedTimestamp = uint256(player.lastClaimed);
    uint256 addressStreak= uint256(player.streak);

   
    require(_verifyDailyCargo(_signature, addressStreak, lastMintedTimestamp), "invalid signature.");
 
    require(lastMintedTimestamp + DAY_IN_SECONDS < block.timestamp, "you can only mint one per day");

    // checks if the sender hasn't minted or missed the 24 hour callable window //
    if (addressStreak == 0 || missedADay(lastMintedTimestamp)) {

      // if so we grab the new cargo id //
      uint256 nextCargoId = _nextTokenId();

      
      // create a new Player struct with the new cargo id and a streak of 1 //

      Player memory newPlayerData;
      newPlayerData.streak = 1;
      newPlayerData.lastClaimed = uint64(block.timestamp);
      newPlayerData.activeCargoId = uint128(nextCargoId);

      // update the players mapping with the new Player struct //
      players[msg.sender] = newPlayerData;

      // set the cargo's streak to 1 //
      cargoStreak[nextCargoId] = 1;
    

      // we mint the new cargo and increment the supply //
      return _mint(msg.sender, 1);

    }  
    
    // if the sender has a cargo and is on time... //
    // we grab the cargo id the most recently minted //
    // increment their address streak //
    // increment the cargo streak //

    uint128 activeCargoId = player.activeCargoId;

    Player memory updatedPlayerData;
    updatedPlayerData.streak = player.streak + 1;
    updatedPlayerData.lastClaimed = uint64(block.timestamp);
    updatedPlayerData.activeCargoId = activeCargoId;

    // update the mapping //
    players[msg.sender] = updatedPlayerData;

    // update the cargo streak //

    cargoStreak[activeCargoId] += 1;

    emit Transfer(address(0), msg.sender, activeCargoId);
  }

  /**
   * @notice checks if the sender missed the 24 hour window to call { getDailyCargo }
   * 
   * @dev after they call { getDailyCargo } the function 
   * becomes callable again
   * after 24 hours. If they call within the 24 hour window after it is callable, 
   * they are on time, so this will return false.
   */
  function missedADay(uint256 _lastMintedTimestamp) public view returns (bool) {
    // using two days in seconds to account for the 24 hour uncallable period //
    return _lastMintedTimestamp + TWO_DAYS_IN_SECONDS < block.timestamp;
  }
  
  /**
   * @notice signature functions to verify a cargo is being minted from
   * freenft.xyz to stop bots from minting.
   */
  function _hashDailyCargo(address _address, uint256 _streakCount, uint256 _lastMintedTimestamp) internal view returns (bytes32) {
      return keccak256(abi.encode(
        address(this), 
        _address, 
        _streakCount, 
        _lastMintedTimestamp
        )).toEthSignedMessageHash();
  }

  function _verifyDailyCargo(bytes memory signature, uint256 _streakCount, uint256 _lastMintedTimestamp) internal view returns (bool) {
      return (_hashDailyCargo(msg.sender, _streakCount, _lastMintedTimestamp).recover(signature) == signerAddress);
  }


  /* ------------------------------------ *\

  ||||||||||||||||||||||||||||||||||||||||||
  ||| ------ CONTAINER METADATA  ------- |||
  ||||||||||||||||||||||||||||||||||||||||||

  \* ------------------------------------ */
  

  /**
   * @notice returns the cargo's metadata.
   * @dev constructs a json string in compliance with the ERC721/A metadata standard.
   * @dev the json string is constructed using the cargo's id and streak.
   * @dev used in { tokenURI }.
   */
  function buildJSON(uint256 _cargoId) public view returns (string memory) {
    uint256 streak = cargoStreak[_cargoId];
    string memory openBracket = "{";
    string memory quotation = '"';

    string memory descriptionAdded = string(abi.encodePacked(openBracket, '"description":', quotation, description, quotation, ","));
    string memory urlAdded = string(abi.encodePacked(descriptionAdded, '"external_url":', quotation, externalUrl, quotation, ","));
    string memory imageAdded = string(abi.encodePacked(urlAdded, '"image":', quotation, baseURI, streak.toString(), quotation, ","));
    string memory nameAdded = string(abi.encodePacked(imageAdded, '"name":', quotation, baseName, _cargoId.toString(), quotation, ",")); 
    string memory attributesAdded = string(abi.encodePacked(nameAdded, '"attributes":', attributesStart, quotation, streak.toString(), quotation, attributesEnd, "}"));


    return attributesAdded;
  }

  /**
   * @notice overrides the ERC721 tokenURI, uses { buildJSON }.
   * @dev return a base64 encoded string of the JSON metadata.
   * 
   */
  function tokenURI(uint256 _cargoId) public view override returns (string memory) {
    require(_exists(_cargoId), "cargo has not been minted.");

    string memory json = buildJSON(_cargoId);
    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
  }

  /**
   * @notice sets the baseName used in { buildJSON }.
   */
  function setBaseName(string memory _baseName) public onlyOwner {
    baseName = _baseName;
  }

  /**
   * @notice sets the externalUrl used in { buildJSON }.
   */
  function setExternalUrl(string memory _externalUrl) public onlyOwner {
    externalUrl = _externalUrl;
  }

  /**
   * @notice sets the attributesStart used in { buildJSON }.
   */
  function setAttributesStart(string memory _attributesStart) public onlyOwner {
    attributesStart = _attributesStart;
  }
 
  /**
   * @notice sets the attributesEnd used in { buildJSON }.
   */
  function setAttributesEnd(string memory _attributesEnd) public onlyOwner {
    attributesEnd = _attributesEnd;
  }
  
  /**
   * @notice sets the description used in { buildJSON }.
   */
  function setDescription(string memory _description) public onlyOwner {
    description = _description;
  }

  /**
   * @notice sets the baseURI used in { tokenURI }.
   */
  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }



  /* ------------------------------------ *\

  ||||||||||||||||||||||||||||||||||||||||||
  ||| ------- ERC721A OVERRIDDES ------- |||
  ||||||||||||||||||||||||||||||||||||||||||

  \* ------------------------------------ */
  
  

  /**
   * @notice overrides the ERC721A transferFrom function to delete an address'
   * streak when they transfer a cargo.
   * 
   * @dev this is so that the address needs to mint a new cargo to start a streak again.
   * the cargo data is not cleared, the receiver may use the cargo's streak benefits as they please.
   * BUT the new owner cannot increment the cargo's streak, as they are not the minter.
   * calling { getDailyCargo } will still just update the receivers streak, or mint them a token.
   */
  function transferFrom(
      address from,
      address to,
      uint256 tokenId
    ) public override payable onlyAllowedOperator(from) {  
      // deleteing the from address' streak if it's their active cargo //
      Player memory player = players[from];
      if (player.activeCargoId == tokenId) {
          delete players[from];
      }

      // complete the transfer //
      ERC721A.transferFrom(from, to, tokenId);
    }

  /**
   * @notice overrides the ERC721A { _startTokenId } function to start at 1.
   * 
   * @dev starting at 1 makes the first mint cheaper, since moving from 0 -> 1
   * is more expensive than x > 0 => y > 0.
  */
  function _startTokenId() internal pure override returns (uint256) {
      return 1;
  }

  /**
   * overrides of { ERC721A } approval/transfer functions in compliance
   * with exchange on-chain royalty requirements.
   * 
   * read more https://support.opensea.io/hc/en-us/articles/1500009575482-How-do-creator-fees-work-on-OpenSea-
   */
  
  function approve(address to, uint256 tokenId) 
    public 
    payable 
    virtual 
    override 
    onlyAllowedOperatorApproval(to)
  {
    super.approve(to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) 
    public 
    virtual 
    override 
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
    )    
    public 
    payable 
    virtual 
    override 
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, '');
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
    ) 
    public 
    payable 
    virtual 
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, _data);
  }
  

  /* ------------------------------------ *\

  ||||||||||||||||||||||||||||||||||||||||||
  ||| -- VIEW FUNCTIONS FOR FRONT END -- |||
  ||||||||||||||||||||||||||||||||||||||||||

  \* ------------------------------------ */


  /**
   * @notice returns the address' streak and the cargo's streak.
   * 
   * @dev used in the front end to display the address' streak and the cargo's streak.
   * 
   * @param _address the address to check.
   */
  function getAddressStreak(address _address) public view returns (uint256) {
    return players[_address].streak;
  }

  /**
   * @notice returns the the cargo's streak.
   * 
   * @dev used in the front end to display the cargo' streak.
   * 
   * @param _cargoId the cargo id to check.
   */
  function getCargoStreak(uint256 _cargoId) public view returns (uint256) {
    return cargoStreak[_cargoId];
  }

  /**
   * @notice returns the address' latest cargo minted timestamp.
   * 
   * @param _address the address to check.
   */
  function getAddressLastMintedTimestamp(address _address) public view returns (uint256) {
    return players[_address].lastClaimed;
  }

  /**
   * @notice returns the address' latest cargo minted.
   * 
   * @dev used in the front end the address' active cargo.
   * 
   * @param _address the address to check.
   */
  function getLatestCargoMinted(address _address) public view returns (uint256) {
    return players[_address].activeCargoId;
  }


  /* ------------------------------------ *\

  ||||||||||||||||||||||||||||||||||||||||||
  ||| ------- CONTRACT MANAGEMENT ------ |||
  ||||||||||||||||||||||||||||||||||||||||||

  \* ------------------------------------ */

  /**
   * @notice sets the signer address used in { _verifyDailyCargo }.
   */
  function setSignerAddress(address _signerAddress) public onlyOwner {
    signerAddress = _signerAddress;
  }
}