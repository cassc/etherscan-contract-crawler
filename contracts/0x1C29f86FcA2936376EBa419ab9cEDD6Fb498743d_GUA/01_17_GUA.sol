// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./GIF89a.sol";
import "./API.sol";
import "./iGUA.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

interface iGUAMetadata {
  function getMetadata(uint256 _tokenId, bytes32 _seed, bytes32 _queryhash, uint256 _timestamp, uint256 _rand, string memory _query, uint8 _colorIndex, bytes2 _bitstream) external pure returns (string memory);
  function fetusMovementGif() external view returns (bytes memory);
  function render(bytes memory _gif, string memory _metadata) external pure returns (string memory);
}

interface iBaGua {
  function cast(bytes32 _input, uint8 _totalColors) external pure returns(uint8[][] memory seed, uint8 colorIndex, bytes2 bitstream);
}

/** @title GUA Contract
  * @author @0xAnimist
  * @notice A collaboration between Cai Guo-Qiang and Kanon
  */
contract GUA is ERC721Enumerable, iGUA {
  address public _artist;
  address public _manager;
  bytes3[] public _colors;
  uint256 private _ww = 3;
  uint256 private _hh = 3;
  address public _GUAMetadataAddress;
  address public _BaGuaAddress;
  bool public _depsFrozen = false;
  bool public _colorsFrozen = false;

  struct Gua {
    bytes32 seed;//hash of query, randomness, & context
    bytes32 queryhash;//hash of query alone
    uint256 timestamp;
    uint256 rand;
    bytes gif;
    string encrypted;
    string query;//blank unless published
    bool queried;//false if gifted
    uint8 colorIndex;
    bytes2 bitstream;
  }

  mapping(uint256 => Gua) public _guas;
  mapping(address => bool) public _readers;//whitelist of contracts that can mint a seed


  modifier onlyAuth(){
    require(msg.sender == _manager || msg.sender == _artist, "a");
    _;
  }

  modifier tokenExists(uint256 _tokenId) {
    require(_exists(_tokenId), "e");
    _;
  }

  /**
    * @dev Constructor, sets caller as _artist and mints token 0 to the caller
    * @param manager_ Address Address of manager
    */
  constructor(address manager_, bytes3[] memory colors_) ERC721("GUA", "GUA"){
    _artist = msg.sender;
    _manager = manager_;
    _colors = colors_;
  }

  function mintFetusMovement() external {
    require(!_exists(0), "f");
    _safeMint(_artist, 0);//mint token #0 to artist
  }

  /**
    * @dev Sets contract manager
    * @param manager_ Address Address of manager
    */
  function setManager(address manager_) external {
    require(msg.sender == _manager, "a");
    _manager = manager_;
  }

  /**
    * @dev Sets address of contract that provides metadata
    * @param GUAMetadataAddress_ Address
    * @param _freeze Blocks any future changes if true
    */
  function setDependencies(address GUAMetadataAddress_, address BaGuaAddress_, bool _freeze) external onlyAuth {
    require(!_depsFrozen, "f");
    _GUAMetadataAddress = GUAMetadataAddress_;
    _BaGuaAddress = BaGuaAddress_;
    _depsFrozen = _freeze;
  }

/*
  function updateColors(bytes3[] memory colors_, bool _freeze) external onlyAuth {
    require(!_colorsFrozen, "f");
    _colors = colors_;
    _colorsFrozen = _freeze;
  }*/
/*
  function getGifs() external view returns(bytes[] memory){
    bytes[] memory gifs = new bytes[](totalSupply()-1);
    for(uint256 i = 1; i < totalSupply(); i++){
      gifs[i-1] = _guas[i].gif;
    }
    return gifs;
  }
*/
  /**
    * @dev Authorizes _reader to mint GUA NFTs
    * @param _reader Address of reader authorized to mint
    */
  function addReader(address _reader) external onlyAuth {
    _readers[_reader] = true;
  }

  /**
    * @dev Mints one GUA NFT
    * @param _owner address to assign ownership of the minted NFT
    * @param _queryhash keccak256 hash of the query
    * @param _rand Random number representing context/intent
    */
  function mint(address _owner, bytes32 _queryhash, uint256 _rand, string memory _encrypted) public returns(uint256 tokenId, bytes32 seed){
    require(_readers[msg.sender], "r");
    tokenId = totalSupply();//start at token #1 bc initialize mints token #0
    _safeMint(_owner, tokenId);

    if(_rand == 0){//not queried
      bytes memory blank;
      _guas[tokenId] = (Gua(seed, _queryhash, block.timestamp, _rand, blank, _encrypted, "", false, 0, 0));
    }else{//queried
      seed = keccak256(abi.encodePacked(_queryhash, block.difficulty));
      seed = keccak256(abi.encodePacked(seed, _rand));

      (bytes memory gif, uint8 colorIndex, bytes2 bitstream) = _response(seed);

      _guas[tokenId] = (Gua(seed, _queryhash, block.timestamp, _rand, gif, _encrypted, "", true, colorIndex, bitstream));
    }
  }

  function redeemFortune(uint256 _tokenId, bytes32 _queryhash, uint256 _rand, string memory _encrypted) external returns(bool success) {
    require(_readers[msg.sender], "r");
    require(ownerOf(_tokenId) == msg.sender, "o");

    bytes32 seed = keccak256(abi.encodePacked(_queryhash, block.difficulty));
    seed = keccak256(abi.encodePacked(seed, _rand));

    (bytes memory gif, uint8 colorIndex, bytes2 bitstream) = _response(seed);

    _guas[_tokenId].seed = seed;
    _guas[_tokenId].queryhash = _queryhash;
    _guas[_tokenId].timestamp = block.timestamp;
    _guas[_tokenId].rand = _rand;
    _guas[_tokenId].gif = gif;
    _guas[_tokenId].queried = true;
    _guas[_tokenId].encrypted = _encrypted;
    _guas[_tokenId].colorIndex = colorIndex;
    _guas[_tokenId].bitstream = bitstream;

    success = true;
  }

  /**
    * @dev Gets GIF and seed raw bytes
    * @param _tokenId the token
    */
  function getData(uint256 _tokenId) external view override tokenExists(_tokenId) returns(bytes memory gif, bytes32 seed, bool queried, string memory encrypted){
    return (_guas[_tokenId].gif, _guas[_tokenId].seed, _guas[_tokenId].queried, _guas[_tokenId].encrypted);
  }

  /**
    * @dev Returns the URI of the token
    * @param _tokenId the token
    */
  function tokenURI(uint256 _tokenId) public view override tokenExists(_tokenId) returns(string memory) {
    bytes memory gif;

    if(_tokenId != 0){
      (gif,,) = _response(_guas[_tokenId].seed);
    }else{
      gif = iGUAMetadata(_GUAMetadataAddress).fetusMovementGif();
    }

    string memory slug = iGUAMetadata(_GUAMetadataAddress).getMetadata(_tokenId, _guas[_tokenId].seed, _guas[_tokenId].queryhash, _guas[_tokenId].timestamp, _guas[_tokenId].rand, _guas[_tokenId].query, _guas[_tokenId].colorIndex, _guas[_tokenId].bitstream);

    return iGUAMetadata(_GUAMetadataAddress).render(gif, slug);
  }

  /**
    * @dev Returns all relevant data for the token in JSON format
    * @param _tokenId the token
    */
  function tokenAPI(uint256 _tokenId) public view returns(string memory api) {
    (bytes memory gif,,) = _response(_guas[_tokenId].seed);

    if(_tokenId != 0){
      return API.guaAPI(
        _tokenId,
        _guas[_tokenId].timestamp,
        _guas[_tokenId].rand,
        _guas[_tokenId].query,
        _guas[_tokenId].queried,
        gif,
        _guas[_tokenId].seed,
        _guas[_tokenId].queryhash
      );
    }
  }

  /**
    * @dev Burns GUA NFT
    * @param tokenId Token to burn
    */
  function burn(uint256 tokenId) public virtual {
      //solhint-disable-next-line max-line-length
      require(_isApprovedOrOwner(_msgSender(), tokenId), "a");
      _burn(tokenId);
  }

  /**
    * @dev Publishes the otherwise private query
    * @param _tokenId the token
    * @param _query the original query, proving knowledge of it
    */
  function publishQuery(uint256 _tokenId, string memory _query) external returns (bool published) {
    require(msg.sender == ownerOf(_tokenId), "o");
    if(keccak256(abi.encodePacked(_query)) == _guas[_tokenId].queryhash){
      _guas[_tokenId].query = _query;
      published = true;
    }
  }

  /**
    * @dev Oracle that provides a GIF in response to a query
    * @param _input the keccak256-encoded contextualized query
    */
  function _response(bytes32 _input) internal view returns(bytes memory gif, uint8 colorIndex, bytes2 bitstream) {
    uint8[][] memory frame;
    (frame, colorIndex, bitstream) = iBaGua(_BaGuaAddress).cast(_input, uint8(_colors.length));

    bytes memory header = hex'47494638396103000300800000ffffff';
    header = abi.encodePacked(header, _colors[colorIndex], hex'21FE154361692047756F2D5169616E672078204B616E6F6E0021f90401000000002c000000000300030000');

    gif = bytes.concat(
      header,
      GIF89a.formatImageLZW(
        frame,
        uint16(2)//only two colors but 2 is the minimum minimum code size for LZW compression
      )
    );

    gif = bytes.concat(gif, hex'3b');
/*
    bytes3[] memory colors = new bytes3[](2);
    colors[0] = 0xFFFFFF;
    colors[1] = 0xF53077;
    //note" hardcoded the header so as to reduce mint gas price, more generic version below
    bytes1 packedLSD = GIF89a.formatLSDPackedField(colors);

    uint16 minCodeSize = uint16(GIF89a.root2(GIF89a.fullColorTableSize(2)));

    return (GIF89a.buildStaticGIF(colors, _ww, _hh, true, 0x00, frame, packedLSD, minCodeSize), colorIndex, bitstream);
*/
  }

}//end