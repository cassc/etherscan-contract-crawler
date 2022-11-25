// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IShape.sol";

import {Utils} from "./utils/Utils.sol";

contract Shapes is 
  Initializable, 
  ERC721Upgradeable, 
  ERC721EnumerableUpgradeable, 
  OwnableUpgradeable 
{

  // how it ends
  uint public constant FINAL_SUPPLY = 2048;

  // cant transfer to address zero
  address constant public BURN_ADDRESS = 0x0000000000000000000000000000000000000001;
  
  // used to parse seed/shape
  uint constant private SEED_RANGE = 10000000000;
  
  // some pre-parsed json elements
  string constant description = "Shapes 2048 by makio135 & clemsos";
  string constant jsonHeader = "data:application/json;base64,";

  // contructor arg
  uint public maxSupply;
  
  // timestamp in sec 
  uint public deadline;
  
  // store SVG contracts
  address[] public shapesAddresses;
  
  // index of the shape to use at mint
  uint public defaultShapeIndex;

  // address of SLASHES contract
  address public slashesAddress;

  // (tokenId => {index of SVG contract in shapesAddresses}000000{seed})
  mapping (uint => uint[]) public seeds;

  // (tokenId => timestamp)
  mapping (uint => uint) changeDeadline;

  // (tokenId => boolean)
  mapping (uint => bool) isLocked;

  // auto increment token ids
  using Counters for Counters.Counter;
  Counters.Counter private _nextTokenId;

  // auto increment seed
  using Counters for Counters.Counter;
  Counters.Counter private _nextSeed;

  // mint price
  uint public priceToMint;
  
  // price to change shape or seed
  uint public priceToUpdate;

  // one day in seconds
  uint interval;
  
  // 66 premint: 64 archival, 1 test, 1 stolen by a bot !
  // 1024 limit number of mint
  uint constant MAX_MINT = 958;
  
  // track number of mints
  uint public mints;

  // emit some events
  event TokenChanged(uint tokenId, uint seed, uint shapeIndex);
  event SwapSlashes(uint slashesTokenId, uint newTokenId);

  // errors
  error SoldOut();
  error SalesNotOpen();
  error CanNotChange();
  error InsufficientPrice();
  error WithdrawFailed(uint balance);
  error WrongNumber();
  error ZeroAddress();
  error Unauthorized();
  error Ended();
  error NoMintLeft();

  // modifiers
  function _salesIsOpen(uint numberOfMints) private view {
    if(totalSupply() == FINAL_SUPPLY) {
      revert SoldOut();
    }
    if(totalSupply() >= maxSupply) {
      revert SalesNotOpen();
    }
    if(mints + numberOfMints > MAX_MINT) {
      revert NoMintLeft();
    }
  }

  function _projectNotEnded() private view {
    if(block.timestamp > deadline) {
      revert Ended();
    }
  }

  function _canBeChanged(uint _tokenId) internal view {
    if(ownerOf(_tokenId) != msg.sender) {
      revert Unauthorized();
    }
    if(msg.value < priceToUpdate) { 
      revert InsufficientPrice(); 
    }
  }

  function initialize() public initializer {

      // initialize
      ERC721Upgradeable.__ERC721_init("SHAPES", "SHAPES");
      OwnableUpgradeable.__Ownable_init();

      // default to 31 Jan 2023 00:00:00 GMT
      deadline = 1675123200;

      // initially dont allow any supply
      maxSupply = 0;

      // default settings
      priceToMint = 0.3 ether;
      priceToUpdate = 0.01 ether;
      interval = 60 * 60; // default to one hour

      // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
      _nextTokenId.increment();

      // seed follow tokenId pattern to avoid duplicates
      _nextSeed.increment();

  }

  /**
  * NFT functions 
  */
  function mint(
    address _recipient, 
    uint _shapeIndex
  ) payable public returns (uint256) {
    _salesIsOpen(1);
    _projectNotEnded();
    if(msg.value < priceToMint) { 
      revert InsufficientPrice(); 
    }
    uint tokenId = _mintShape(_recipient, _shapeIndex, 0);
    mints = mints + 1;
    return tokenId;
  }

  function _mintShape(
    address _recipient, 
    uint _shapeId,
    uint _seed // set to 0 to make seed random
    ) internal returns (uint currentTokenId) 
    {
    currentTokenId = _nextTokenId.current();
    uint parsedSeed; 
    
    if(_seed == 0) {
      // we skip the first 1024 to make sure we dont get identical slashes
      parsedSeed = _shapeId * SEED_RANGE + 1024 + _nextSeed.current();
      _nextSeed.increment();
    } else {
      // assign existing seed
      parsedSeed = _shapeId * SEED_RANGE + _seed;
    }

    // store seed
    seeds[currentTokenId].push(parsedSeed);

    // mint the token
    _safeMint(_recipient, currentTokenId);
    _nextTokenId.increment();
    return currentTokenId;
  }

  function batchMint(
    address _recipient, 
    uint _shapeId,
    uint256 numberOfNfts
  ) public payable {
    _salesIsOpen(numberOfNfts);
    _projectNotEnded();

    if(numberOfNfts == 0 || totalSupply() + numberOfNfts > maxSupply) {
      revert WrongNumber();
    }
    
    if(msg.value < priceToMint * numberOfNfts) {
      revert InsufficientPrice();
    }

    for (uint i = 0; i < numberOfNfts; i++) {
        _mintShape(_recipient, _shapeId, 0);
    }

    mints = mints + numberOfNfts;
  }
  
  function totalSupply() public view override returns (uint256) {
    return _nextTokenId.current() - 1;
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
    ) internal
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable) 
    {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
      returns (bool)
    {
      return super.supportsInterface(interfaceId);
  }

  function contractURI() 
    public 
    view 
    returns (string memory) 
    {
      // generate random thumbnail
      IShape svg = IShape(shapesAddresses[0]);
      string memory svgString;
      string memory attributes;
      (svgString, attributes) = svg.generateSVG(block.timestamp % _nextTokenId.current());

      return string(
          abi.encodePacked(
              jsonHeader,
              Base64.encode(
                  bytes(
                      abi.encodePacked(
                        '{"name": "Shapes","description":"',
                        description,
                        '","image":"',
                        svgString,
                        '", "external_link": "https://makio135.com/shapes2048"}'
                        )
                  )
              )
          )
      );
  }

  function tokenURI(uint256 tokenId) 
    public 
    view 
    virtual 
    override (ERC721Upgradeable)
    returns (string memory) 
    {
      
      // doesnt revert even if the token doesnt exist
      if (tokenId > totalSupply()) return '{}';
      
      (string memory svgString, string memory attributes) = IShape(
        shapesAddresses[shape(tokenId)]
      ).generateSVG(
        seed(tokenId)
      );

      return string(
          abi.encodePacked(
              jsonHeader,
              Base64.encode(
                  bytes(
                      abi.encodePacked(
                        '{"description": "',
                        description,
                        '","name":"Shapes #',
                        Utils.uint2str(tokenId),
                        '","image":"',
                        svgString,
                        '","attributes":[{"trait_type":"countChanges","value":',
                        Utils.uint2str(seeds[tokenId].length),
                        '},',
                        attributes,
                        ']}'
                      )
                  )
              )
          )
      );
  }
  
  /**
   * Admin features
   */

  function setPriceToMint(uint _priceToMint) public onlyOwner {
    priceToMint = _priceToMint;
  }
  function setPriceToUpdate(uint _priceToUpdate) public onlyOwner {
    priceToUpdate = _priceToUpdate;
  }

  function withdraw(address payable recipient, uint256 amount) public onlyOwner {
      if(recipient == address(0)) {
        revert ZeroAddress();
      }

      uint balance = address(this).balance;
      if(balance == 0) { 
        revert WithdrawFailed(0); 
      }
      
      (bool succeed, ) = recipient.call{value: amount}("");
      if(!succeed) {
        revert WithdrawFailed(balance);
      }
  }

  function setMaxSupply(uint _maxSupply) public onlyOwner {
    if(_maxSupply < totalSupply() || _maxSupply > FINAL_SUPPLY) {
      revert WrongNumber();
    }
    maxSupply = _maxSupply;
  }
  
  // shapes address should be as follow: [ slashesV1, slashesV2, arcs... ]
  function setShapesAddresses(address[] calldata _shapesAddresses) public onlyOwner {
    shapesAddresses = _shapesAddresses;
  }

  function updateDeadline(uint _deadline) public onlyOwner {
    deadline = _deadline;
  }

  /**
   * Slashes v1 logic
   */
  function setSlashesAddress(address _slashesAddress) public onlyOwner {
    slashesAddress = _slashesAddress;
  }

  function swapSlash(uint _slashTokenId, uint _shapeIndex) public returns (uint tokenId){
    _projectNotEnded();
    IERC721 slashes = IERC721(slashesAddress);
    if(slashes.ownerOf(_slashTokenId) != msg.sender) {
      revert Unauthorized();
    }

    // mint new one
    tokenId = _mintShape(
      msg.sender, // same owner
      _shapeIndex,
      _slashTokenId // assign tokenId as seed
    );

    emit SwapSlashes(_slashTokenId, tokenId);

    // burn old token by transferring to the burn address as the original
    // Slashes contract has no burn function
    slashes.transferFrom(msg.sender, BURN_ADDRESS, _slashTokenId);
  }

  /**
   * Getters
   */
  function seed(uint _tokenId) public view returns (uint) {
    return seeds[_tokenId][seeds[_tokenId].length - 1] % SEED_RANGE;
  }
  
  function shape(uint _tokenId) public view returns (uint) {
    return seeds[_tokenId][seeds[_tokenId].length - 1] / SEED_RANGE;
  }

  function countChanges(uint _tokenId) public view returns (uint) {
    return seeds[_tokenId].length;
  }
  
  /**
   * User features
   */

  function changeToken(
    uint _tokenId, 
    uint _shapeIndex
  ) public payable {
    _projectNotEnded();
    _canBeChanged(_tokenId);

    // we skip the first 1024 to make sure we dont get identical slashes
    uint newSeed = 1024 + _nextSeed.current();

    // make sure shape exists
    if(_shapeIndex > shapesAddresses.length - 1) {
      revert WrongNumber();
    }

    seeds[_tokenId].push(_shapeIndex * SEED_RANGE + newSeed);

    emit TokenChanged(_tokenId, newSeed, _shapeIndex);
    _nextSeed.increment();
  }

  function selectSeed(uint _tokenId, uint _seed) public {
    _projectNotEnded();
    
    if(ownerOf(_tokenId) != msg.sender) {
      revert Unauthorized();
    }

    bool seedFound;
    for (uint256 i = 0; i < seeds[_tokenId].length - 1; i++) {
      // if seed is found move all elements to the left, starting from the `index + 1`
      if(seedFound) {
        seeds[_tokenId][i] = seeds[_tokenId][i + 1];
      } else if(seeds[_tokenId][i] == _seed) {
        seedFound = true;
        seeds[_tokenId][i] = seeds[_tokenId][i + 1];
      } 
      
    }

    if(seedFound) {
      // set _seed as the last seed
      seeds[_tokenId][seeds[_tokenId].length - 1] = _seed;
      emit TokenChanged(_tokenId, _seed % SEED_RANGE, _seed / SEED_RANGE);
    }
  }

}