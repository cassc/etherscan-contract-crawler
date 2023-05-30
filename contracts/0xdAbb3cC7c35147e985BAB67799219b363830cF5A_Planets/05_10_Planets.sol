//SPDX-License-Identifier: MIT

// ███████╗████████╗██╗░░██╗███████╗██████╗░  ██████╗░██╗░░░░░░█████╗░███╗░░██╗███████╗████████╗░██████╗
// ██╔════╝╚══██╔══╝██║░░██║██╔════╝██╔══██╗  ██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔════╝╚══██╔══╝██╔════╝
// █████╗░░░░░██║░░░███████║█████╗░░██████╔╝  ██████╔╝██║░░░░░███████║██╔██╗██║█████╗░░░░░██║░░░╚█████╗░
// ██╔══╝░░░░░██║░░░██╔══██║██╔══╝░░██╔══██╗  ██╔═══╝░██║░░░░░██╔══██║██║╚████║██╔══╝░░░░░██║░░░░╚═══██╗
// ███████╗░░░██║░░░██║░░██║███████╗██║░░██║  ██║░░░░░███████╗██║░░██║██║░╚███║███████╗░░░██║░░░██████╔╝
// ╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝  ╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚══════╝░░░╚═╝░░░╚═════╝░

pragma solidity ^0.8.18;

import "./PlanetsThumbnail.sol";
import "./Utilities.sol";
import "./interfaces/IPlanets.sol";
import "./interfaces/IPlanetsRenderer.sol";
import "scripty.sol/contracts/scripty/IScriptyBuilder.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Planets is ERC721A, Ownable {
  uint256 public immutable deployBlock;
  uint256 public immutable supply;
  address public thumbnailAddress;
  address public rendererAddress;

  uint256 public price;
  bool public isOpen;

  bool public finalized;

  error MintClosed();
  error SoldOut();
  error InsufficientFunds();
  error TokenDoesntExist();
  error RefundFailed();
  error Finalized();

  constructor(
    string memory name,
    string memory symbol,
    uint256 _supply,
    uint256 _price,
    address _thumbnailAddress,
    address _rendererAddress
  ) ERC721A(name, symbol) {
    thumbnailAddress = _thumbnailAddress;
    rendererAddress = _rendererAddress;

    supply = _supply;
    price = _price;

    deployBlock = block.number;
  }

  /**
   * @notice  Airdrops tokens to a list of recipients. Only callable by the contract owner.
   * @param _recipients List of recipients to receive the airdrop.
   * @param _quantity Quantity of tokens to airdrop to each recipient.
   */
  function airdrop(address[] calldata _recipients, uint256 _quantity) external payable onlyOwner {
    if (totalMinted() + _recipients.length * _quantity > supply) revert SoldOut();
    for (uint256 i = 0; i < _recipients.length; i++) {
      _mint(_recipients[i], _quantity);
    }
  }

  /**
   * @notice Mints new tokens for the caller.
   * @param _quantity Quantity of tokens to mint.
   */
  function mint(uint256 _quantity) public payable {
    if (!isOpen) revert MintClosed();
    if (totalMinted() + _quantity > supply) revert SoldOut();
    if (msg.value < price * _quantity) revert InsufficientFunds();

    _mint(msg.sender, _quantity);

    // Refund any extra ETH sent
    if (msg.value > price * _quantity) {
      (bool status, ) = payable(msg.sender).call{value: msg.value - price * _quantity}("");
      if (!status) revert RefundFailed();
    }
  }

  /**
   * @notice Withdraws the contract's balance. Only callable by the contract owner.
   */
  function withdraw() external onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  /**
   * @notice Update the mint price.
   * @dev Very doubtful this gets used, but good to have
   * @param _price - The new price.
   */
  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  /**
   * @notice Update thumbnail contract address
   * @param _thumbnailAddress - Address of the thumbnail contract.
   */
  function setThumbnailAddress(address _thumbnailAddress) external onlyOwner {
    if (finalized) revert Finalized();
    thumbnailAddress = _thumbnailAddress;
  }

  /**
   * @notice Update renderer contract address
   * @param _rendererAddress - Address of the renderer contract.
   */
  function setRendererAddress(address _rendererAddress) external onlyOwner {
    if (finalized) revert Finalized();
    rendererAddress = _rendererAddress;
  }

  /**
   * @notice Open or close minting
   * @param _state - Boolean state for being open or closed.
   */
  function setMintStatus(bool _state) external onlyOwner {
    isOpen = _state;
  }

  function finalize() external onlyOwner {
    finalized = true;
  }

  /**
   * @notice Minting starts at token id #1
   * @return Token id to start minting at
   */
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /**
   * @notice Retrieve how many tokens have been minted
   * @return Total number of minted tokens
   */
  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  function formatVar(bytes memory _name, uint256 _value) internal pure returns (bytes memory) {
    return abi.encodePacked("var ", _name, "=", utils.uint2str(_value), ";");
  }

  /**
   * @notice Build all the settings into a struct
   * @param _tokenId - Token ID for seed value
   * @return settings - All settings as a struct
   */
  function buildSettings(uint256 _tokenId) public view returns (Settings memory settings) {
    uint256 randomSeed = _tokenId + deployBlock;

    settings.seed = utils.randomRange(randomSeed, "seed", 1, 1000000);
    settings.vars[0] = formatVar("seed", settings.seed);

    settings.planetSize = utils.randomRange(randomSeed, "planetSize", 30, 100);
    settings.vars[1] = formatVar("planetSize", settings.planetSize);

    // 40% gas, 60% rock
    settings.planetType = utils.randomRange(randomSeed, "planetType", 0, 10) < 4 ? PlanetType.GAS : PlanetType.SOLID;
    settings.vars[4] = formatVar("planetType", uint256(settings.planetType));

    // 30% of gaseous planets;
    settings.hasRings = settings.planetType == PlanetType.GAS && utils.randomRange(randomSeed, "hasRings", 0, 10) < 3;
    settings.vars[2] = formatVar("hasRings", settings.hasRings ? 1 : 0);

    {
      // 25% 1 moon, 12% 2 moons, 3% 3 moons
      uint256 observation = utils.randomRange(randomSeed, "numMoons", 0, 100);
      if (observation < 25) settings.numMoons = 1;
      else if (observation < 37) settings.numMoons = 2;
      else if (observation < 40) settings.numMoons = 3;
      else settings.numMoons = 0;
      settings.vars[3] = formatVar("numMoons", settings.numMoons);
    }

    settings.hue = utils.randomRange(randomSeed, "baseHue", 0, 360);
    settings.vars[5] = formatVar("baseHue", settings.hue);

    // If rocky, 30% water
    settings.hasWater = settings.planetType == PlanetType.SOLID && utils.randomRange(randomSeed, "hasWater", 0, 10) < 3;
    settings.vars[6] = formatVar("hasWater", settings.hasWater ? 1 : 0);

    return settings;
  }

  /**
   * @notice Util function to help build traits
   * @param _key - Trait key as string
   * @param _value - Trait value as string
   * @return trait - object as string
   */
  function buildTraitString(string memory _key, string memory _value) internal pure returns (string memory trait) {
    return string.concat('{"trait_type":"', _key, '","value":"', _value, '"}');
  }

  /**
   * @notice Util function to help build traits where value is continuous
   * @param _key - Trait key as string
   * @param _value - Trait value as string
   * @return trait - object as string
   */
  function buildTraitNumber(string memory _key, string memory _value) internal pure returns (string memory trait) {
    return string.concat('{"trait_type":"', _key, '","value":', _value, "}");
  }

  /**
   * @notice Build attributes for metadata
   * @param settings - Track settings struct
   * @return attr - array as a string
   */
  function buildAttributes(Settings memory settings) public pure returns (string memory attr) {
    return
      string.concat(
        '"attributes": [',
        buildTraitNumber("Planet Size", utils.uint2str(settings.planetSize)),
        ",",
        buildTraitString("Has Rings", settings.hasRings ? "Yes" : "No"),
        ",",
        buildTraitString("Has Water", settings.hasWater ? "Yes" : "No"),
        ",",
        buildTraitString("Number of Moons", utils.uint2str(settings.numMoons)),
        ",",
        buildTraitString("Planet Type", settings.planetType == PlanetType.SOLID ? "Rock" : "Gas"),
        ",",
        buildTraitString("Planet Color", utils.getColorName(settings.hue)),
        "]"
      );
  }

  /**
   * @notice Pack and base64 encode JS compatible vars
   * @param settings - Track settings struct
   * @return vars - base64 encoded JS compatible setting variables
   */
  function buildVars(Settings memory settings) public pure returns (bytes memory vars) {
    return
      bytes(
        utils.encode(
          abi.encodePacked(
            settings.vars[0],
            settings.vars[1],
            settings.vars[2],
            settings.vars[3],
            settings.vars[4],
            settings.vars[5],
            settings.vars[6]
          )
        )
      );
  }

  /**
   * @notice Build the metadata including the full render html for the planet
   * @dev This depends on
   *      - https://ethfs.xyz/ [stores code libraries]
   *      - https://github.com/intartnft/scripty.sol [builds rendering html and stores code libraries]
   * @param _tokenId - TokenId to build planet for
   * @return metadata - as string
   */
  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A) returns (string memory metadata) {
    // show nothing if token doesnt exist
    if (!_exists(_tokenId)) revert TokenDoesntExist();

    // Generate all the settings and various objects for the metadata
    Settings memory settings = buildSettings(_tokenId);
    string memory attr = buildAttributes(settings);
    bytes memory vars = buildVars(settings);
    string memory thumbnail = utils.encode(PlanetsThumbnail(thumbnailAddress).buildThumbnail(settings));

    bytes memory animationUri = IPlanetsRenderer(rendererAddress).buildAnimationURI(vars);

    bytes memory json = abi.encodePacked(
      '{"name":"',
      "EtherPlanet #",
      utils.uint2str(_tokenId),
      '", "description":"',
      "Fully on-chain, procedurally generated, 3D planets.",
      '","image":"data:image/svg+xml;base64,',
      thumbnail,
      '","animation_url":"',
      animationUri,
      '",',
      attr,
      "}"
    );

    return string(abi.encodePacked("data:application/json,", json));
  }
}