// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./GIF89a.sol";
import "./BytesLib.sol";
import "./iGUA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface iBondingCurve {
  function getFee(uint256 _amount, address _currency) external view returns (uint256 fee);
  function burnTo(uint256 _tokenId, address _owner, address payable _msgSender, address _currency, bytes memory _burnPayload) external returns (bool rewarded);
  function pay(address _payee, uint256 _amount, uint256 _tokenCount, address _currency, bytes memory _mintPayload) external payable returns(bool success);
}

interface iEETRenderEngine {
  function render(uint256 _tokenId, address _guaContract, bytes3[] memory _colors, bytes memory _packedHeader) external view returns (string memory);
  function api(uint256 _tokenId, address _guaContract, bytes3[] memory _colors, bytes memory _packedHeader, address _scoreBoardAddress) external view returns (string memory json);
}

interface iScoreBoard {
  function addMintPayload(uint256 _eetTokenId, address _msgSender, bytes memory _mintPayload) external;
  function addBurnPayload(uint256 _eetTokenId, address _msgSender, bytes memory _burnPayload) external;
}


/** @title EET Contract
  * @author @0xAnimist
  * @notice A collaboration between Cai Guo-Qiang and Kanon
  */
contract EET is ERC721Enumerable, ReentrancyGuard {
  address public _artist;
  address public _manager;
  bytes3[] public _colors;
  bool public _colorsFrozen = false;

  uint256 private _ww = 9;
  uint256 private _hh = 15;
  address public _guaContract;

  bytes1 private _transIndex = 0x00;
  bytes1 private _disposalMethod = 0x04;
  bytes2 private _delay = 0x6400;

  address public _BondingCurveAddress;
  address public _EETRenderEngineAddress;
  address public _scoreBoardAddress;
  bool public _depsFrozen = false;

  struct GIFparts {
    bytes packedHeader;
    bytes header;
    bytes gce;
    bytes trailer;
  }

  GIFparts private _gifParts;

  modifier onlyAuth(){
    require(msg.sender == _manager || msg.sender == _artist, "a");
    _;
  }

  /**
    * @dev Constructor
    * @param manager_ Address Address of manager
    */
  constructor(address manager_, bytes3[] memory colors_) ERC721("EET", "EET"){
    _artist = msg.sender;
    _manager = manager_;
    _updateColors(colors_);
  }


  /**
    * @dev Updates colors
    * @param colors_ Array of colors by hex value
    */
  function _updateColors(bytes3[] memory colors_) internal onlyAuth {
    _colors = colors_;

    //Generate GIF parts
    bytes1 packedLSD = GIF89a.formatLSDPackedField(_colors);
    bytes memory header = BytesLib.concat(BytesLib.concat(GIF89a.formatHeader(), GIF89a.formatLSD(_ww, _hh, packedLSD)), GIF89a.formatGCT(_colors));
    bytes memory aeb = GIF89a.formatAEB(uint16(1));
    bytes memory gce = GIF89a.formatGCE(true, _disposalMethod, _delay, true, _transIndex);
    bytes memory trailer = GIF89a.formatTrailer();

    bytes memory packedHeader = BytesLib.concat(header, BytesLib.concat(aeb, gce));

    _gifParts = GIFparts(packedHeader, header, gce, trailer);
  }


  /**
    * @dev Sets contract manager
    * @param manager_ Address Address of manager
    */
  function setManager(address manager_) public {
    require(msg.sender == _manager, "m");
    _manager = manager_;
  }

  /**
    * @dev Sets contract dependencies
    * @param guaContract_ Address of GUA contract
    * @param BondingCurveAddress_ Address of BondingCurve contract
    * @param EETRenderEngineAddress_ Address of EETRenderEngine contract
    * @param ScoreBoardAddress_ Address of ScoreBoard contract
    * @param _freeze Blocks any future changes if true
    */
  function setDependencies(address guaContract_, address BondingCurveAddress_, address EETRenderEngineAddress_, address ScoreBoardAddress_, bool _freeze) external onlyAuth {
    require(!_depsFrozen, "f");
    _guaContract = guaContract_;
    _BondingCurveAddress = BondingCurveAddress_;
    _EETRenderEngineAddress = EETRenderEngineAddress_;
    _scoreBoardAddress = ScoreBoardAddress_;

    _depsFrozen = _freeze;
  }


  /**
    * @dev Returns the URI of the token
    * @param _tokenId the token
    */
  function tokenURI(uint256 _tokenId) public view override returns(string memory) {
    return iEETRenderEngine(_EETRenderEngineAddress).render(_tokenId, _guaContract, _colors, _gifParts.packedHeader);
  }

  /**
    * @dev Returns the URI of the token
    * @param _tokenId the token
    */
  function tokenAPI(uint256 _tokenId) public view returns(string memory) {
    return iEETRenderEngine(_EETRenderEngineAddress).api(_tokenId, _guaContract, _colors, _gifParts.packedHeader, _scoreBoardAddress);
  }


  /**
    * @dev Mints one or more EET NFTs and corresponding GUA NFTs
    * @param _owners array of addresses to which the tokens will be minted
    * @param _queryhash keccak256 hash of the query
    * @param _rand Random number representing context/intent
    */
  function mint(address[] memory _owners, bytes32[] memory _queryhash, uint256[] memory _rand, address _currency, string[] memory _encrypteds, bytes memory _mintPayload) public payable nonReentrant returns (uint256[] memory tokenIds){
    //Pay fee
    uint256 fee = iBondingCurve(_BondingCurveAddress).getFee(_queryhash.length, _currency);

    require(iBondingCurve(_BondingCurveAddress).pay{value:msg.value, gas: gasleft()}(msg.sender, fee, _queryhash.length, _currency, _mintPayload), "u");

    //Mint tokens
    tokenIds = new uint256[](_queryhash.length);

    for(uint256 i = 0; i < _queryhash.length; i++){
      //mint GUA nft
      (tokenIds[i],) = iGUA(_guaContract).mint(_BondingCurveAddress, _queryhash[i], _rand[i], _encrypteds[i]);
      //store payload
      iScoreBoard(_scoreBoardAddress).addMintPayload(tokenIds[i], msg.sender, _mintPayload);

      //mint eet nft
      _safeMint(_owners[i], tokenIds[i]);//starts at token 1 bc seed starts at token 1
    }
  }


  /**
    * @dev Burns EET NFT and unlocks GUA NFT for a reward from the Bonding Curve
    * @param _tokenIds Tokens to burn
    * @param _currency Currency of the reward
    * @param _burnPayload data
    */
  function burnToCurve(uint256[] memory _tokenIds, address _currency, bytes memory _burnPayload) public nonReentrant {
    for(uint256 i = 0; i < _tokenIds.length; i++){
      address owner = ownerOf(_tokenIds[i]);
      _burnToken(_tokenIds[i], msg.sender, _burnPayload);

      require(iBondingCurve(_BondingCurveAddress).burnTo(_tokenIds[i], owner, payable(msg.sender), _currency, _burnPayload), "f");
    }
  }

  /**
    * @dev Burns EET NFT and updates ScoreBoard
    * @param _tokenId Token to burn
    * @param _msgSender sender
    * @param _burnPayload data
    */
  function _burnToken(uint256 _tokenId, address _msgSender, bytes memory _burnPayload) internal {
    require(_isApprovedOrOwner(_msgSender, _tokenId), "a");
    _burn(_tokenId);

    iScoreBoard(_scoreBoardAddress).addBurnPayload(_tokenId, msg.sender, _burnPayload);
  }

}//end