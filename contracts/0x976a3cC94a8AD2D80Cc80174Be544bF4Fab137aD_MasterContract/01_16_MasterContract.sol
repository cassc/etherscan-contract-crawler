//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Round.sol";
import "./Oracle.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/IMetaDataOracle.sol";

contract MasterContract is AccessControl, IMaster, ERC721 {
  using Address for address payable;
  using Strings for uint256;

  uint[] private _mintedIds;

  address public constant WITHDRAW_ADDRESS = 0xf867C48da1Aa3268FEBCff36a6879066dd8EB304;
  address public constant OWNER_ADDRESS = 0x0867436a889bf9C1abCAf3c505046FC4F7880b50;
  bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  string private baseUri;
  string private notRevealUri;
  uint16 private _totalSupply;
  uint16 private _maxSupply;


  IMetaDataOracle private metaDataOracle;

  mapping(Round => RoundContract) public roundContracts;
  mapping(Round => uint256) private _roundPrice;
  mapping(uint => string) private _tokenAttributesJSON;
  mapping(uint => bool) private _requests;
  mapping(uint => string) _tokenRound;

  /// @notice Is the token occupied
  /// @dev tokenId => true or false
  mapping(uint => bool) public occupiedIdxs;

  uint256 revealDate;
  uint256 createDate;

  /// @notice user whitelist
  /// @dev address => true or false
  mapping(address => bool) private whiteList;


  // EVENTS
  event MintRand(address indexed owner, uint indexed id);
  event Reveal(string message);
  event ChangeMaxSupply(uint16 newMaxSupply);
  event AddToWhitelist(address user);
  event RemoveFromWhitelist(address user);
  /// @notice event for check if oracle contract was changed
  event OracleAddressChanged(address oracle);

  /// @notice event emit when resived successful
  event MetaDataReceived(string json, uint id, uint tokenId);

  /// @notice event emit when request data for token
  event MetaDataRequested(uint tokenId, uint id);

  /// @notice event emit when new token was minted
  event MintTokens(address owner, Round round, uint[] tokenIds);

  modifier onlyOracle() {
    require(msg.sender == address(metaDataOracle), "Unauthorized.");
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _notRevealUri,
    string memory _baseUri,
    uint16 maxSupply_,
    uint256 _revealDate,
    address _legendaryRound
    ) ERC721(_name, _symbol) {
      notRevealUri = _notRevealUri;
      baseUri = _baseUri;
      _maxSupply = maxSupply_;
      createDate = block.timestamp;
      revealDate = _revealDate;
      
      roundContracts[Round.Legendary] = RoundContract(payable(_legendaryRound));
      _roundPrice[Round.Legendary] = RoundContract(payable(_legendaryRound)).mintPrice();

      _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _grantRole(DEFAULT_ADMIN_ROLE, OWNER_ADDRESS);
      _grantRole(MINTER_ROLE, _legendaryRound);
  }

  function addMinter(Round _round, address _minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(MINTER_ROLE, _minter);
    roundContracts[_round] = RoundContract(payable(_minter));
  }

  function removeMinter(Round _round) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(MINTER_ROLE, address(roundContracts[_round]));
    roundContracts[_round] = RoundContract(address(0));
  }

  function setMaxSupply(uint16 maxSupply_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _maxSupply = maxSupply_;
    emit ChangeMaxSupply(_maxSupply);
  }

  function totalSupply() external view override returns(uint) {
    return _totalSupply;
  }

  function maxSupply() external view override returns(uint) {
    return _maxSupply;
  }

  /// @notice Сhecks whether the collection is revealed 
  function isRevealed() public view returns(bool) {
    return block.timestamp > revealDate;
  }

  function tokenRoundString(uint tokenId) public view returns(string memory) {
    return _tokenRound[tokenId];
  }

  /// @notice Get token URI
  /// @dev Checks if the collection is revealed and return <notRevealUri> or <currentBaseURI + token URI>
  /// @param tokenId Current token Id
  /// @return tokenURI Link to token metadata
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
      require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
      );
      
      if(!isRevealed()) {
        return notRevealUri;
      }

      string memory currentBaseURI = baseUri;
      return bytes(currentBaseURI).length > 0
          ? string(abi.encodePacked(currentBaseURI, _tokenRound[tokenId], "/metadata/", Strings.toString(tokenId), ".json"))
          : "";
  }
    
  /// @notice Auxiliary function for marketplaces
  /// @param interfaceId Bytes like id of contract interfase
  /// @return boolean
  function supportsInterface(bytes4 interfaceId) public pure override(AccessControl, ERC721) returns (bool) {
    return interfaceId == type(IERC721).interfaceId;
  }

  /// @notice Service function for working with oracle
  /// @param json strigify json data
  /// @param id of request
  /// @param tokenId token id
  function fulfillMetaDataRequest(string memory json, uint id, uint tokenId) external override onlyRole(ORACLE_ROLE) {
    require(_requests[id], "Request is invalid or already fulfilled.");

    _tokenAttributesJSON[tokenId] = json;

    delete _requests[id];
    emit MetaDataReceived(json, id, tokenId);
  }

  function setMetaDataOracleAddress(address newAddress) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    metaDataOracle = IMetaDataOracle(newAddress);
    _setupRole(ORACLE_ROLE, newAddress);
    emit OracleAddressChanged(newAddress);
  }

  function getRoundPrice(Round round) external view override returns(uint) {
    return _roundPrice[round];
  }

  function _getAttributes(uint tokenId) internal {

    require(metaDataOracle != IMetaDataOracle(address(0)), "Oracle not initialized.");
     
    uint256 id = metaDataOracle.requestMetaData(tokenId);
    _requests[id] = true;
    
    emit MetaDataRequested(tokenId, id);
  }

  function showMetaData(uint tokenId) external view override returns(string memory) {
    require(isRevealed(), "NFT: collections not revealed");
    return _tokenAttributesJSON[tokenId];
  }

  function roundAddress(Round round) external view returns(address) {
    return address(roundContracts[round]);
  }

  function mintedIds() external view returns(uint[] memory) {
    return _mintedIds;
  }

  function getRoundTotalSupply(Round round) external view returns(uint) {
    return roundContracts[round].roundTotalSupply();
  }

  /// @notice refers to the selected round and says whether the token is occupied or not
  /// @param tokenId target token id
  /// @return bool
  function idOccuped(uint tokenId) external view override returns(bool) {
    return occupiedIdxs[tokenId];
  }

  /// @notice main mint function, wich generate and mint batch of tokens
  /// @param tokenIdxs - number of tokens for mint
  /// @dev all the checks with the round are taken out here in order not to carry them out twice
  /// @dev if contract not found free token ids contract will send funds back
  function mint(uint[] memory tokenIdxs, address from, string memory name) override(IMaster) external onlyRole(MINTER_ROLE) {
    _totalSupply += uint16(tokenIdxs.length);
    
    for (uint256 i = 0; i < tokenIdxs.length; i++) {
      _tokenRound[tokenIdxs[i]] = name;
      _getAttributes(tokenIdxs[i]);
      occupiedIdxs[tokenIdxs[i]] = true;
      _mintedIds.push(tokenIdxs[i]);
      _safeMint(from, tokenIdxs[i]);
      emit MintRand(from, tokenIdxs[i]);
    }
  }

  bool migrated;
  function migrate(address reciever, uint id) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!migrated, "Already done!");
    occupiedIdxs[id] = true;
    _mintedIds.push(id);
    _safeMint(reciever, id);
  }

  function migrateFinish() external onlyRole(DEFAULT_ADMIN_ROLE){
    migrated = true;
  }
}