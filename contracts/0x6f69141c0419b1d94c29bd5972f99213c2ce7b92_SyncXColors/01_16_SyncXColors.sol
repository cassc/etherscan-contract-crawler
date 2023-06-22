// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import 'base64-sol/base64.sol';
import './legacy_colors/TheColors.sol';
import './legacy_colors/INFTOwner.sol';

/**
 * @title Sync x Colors contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract SyncXColors is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Strings for uint16;
  using Strings for uint8;

  uint256 public constant TotalReservedAmount = 17; // Amount reserved for promotions (giveaways, team)
  uint256 public constant MAX_SUPPLY = 4317 - TotalReservedAmount;

  // Declare Public
  address public constant THE_COLORS = 
    address(0x9fdb31F8CE3cB8400C7cCb2299492F2A498330a4);

  uint256 public constant mintPrice = 0.05 ether; // Price per mint
  uint256 public constant resyncPrice = 0.005 ether; // Price per color resync
  uint256 public constant maxMintAmount = 10; // Max amount of mints per transaction
  uint256 public MintedReserves = 0; // Total Promotional Reserves Minted

  // Declare Private
  address private constant TREASURY =
    address(0x48aE900E9Df45441B2001dB4dA92CE0E7C08c6d2);
  address private constant TEAM =
    address(0x263853ef2C3Dd98a986799aB72E3b78334EB88cb);

  mapping(uint256 => uint16[]) private _colorTokenIds;
  mapping(uint256 => uint256) private _seed; // Trait seed is generated at time of mint and stored on-chain
  mapping(uint256 => uint8) private _resync_count; //Store count of color resyncs applied
  
  // Struct for NFT traits
  struct SyncTraitsStruct {
    uint8[] shape_color;
    uint8[] shape_type;
    uint16[] shape_x;
    uint16[] shape_y;
    uint16[] shape_sizey;
    uint16[] shape_sizex;
    uint16[] shape_r;
    uint16 rarity_roll;
    bytes[] baseColors;
    bytes[] bgColors;
    bytes[] infColors;
    bytes logoColors;
    bytes driftColors;
    bytes theme;
    bytes7 sigil;
  }

  // Constructor
  constructor() ERC721('Sync x Colors', 'SyncXColors') {}

  /**
   * Returns NFT tokenURI JSON
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721)
    returns (string memory)
  {
    require(_exists(tokenId), 'ERC721: operator query for nonexistent token');

    SyncTraitsStruct memory syncTraits = generateTraits(tokenId);

    string memory svgData = generateSVGImage(tokenId, syncTraits);
    string memory image = Base64.encode(bytes(svgData));

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{',
                '"image":"',
                'data:image/svg+xml;base64,',
                image,
                '",',
                generateNameDescription(),
                ',',
                generateAttributes(tokenId, syncTraits),
                '}'
              )
            )
          )
        )
      );
  }

  /**
   * Withdraw accrued funds from contract. 50% treasury, 10% to each team member
   */
  function withdraw() internal {
    bool sent;
    uint256 balance = address(this).balance;
    (sent, ) = payable(TEAM).call{value: (balance * 50) / 100}('');
    require(sent);
    (sent, ) = payable(TREASURY).call{value: (balance * 50) / 100}('');
    require(sent);
  }

  /**
   * Withdraw by owner
   */
  function withdrawOwner() external onlyOwner {
    withdraw();
  }

  /**
   * Withdraw by team
   */
  function withdrawTeam() external {
    require(msg.sender == TEAM, 'Only team can withdraw');
    withdraw();
  }

  /**
   * Mint 1 or multiple NFTs
   */
  function mint(uint256 _mintAmount, uint16[] calldata colorTokenIds)
    external
    payable
  {
    // Requires
    uint256 _mintIndex = totalSupply();
    require(
      _mintAmount > 0 && _mintAmount <= maxMintAmount,
      'Max mint 10 per tx'
    );
    require(colorTokenIds.length <= 3, '# COLORS tokenIds must be <=3');
    if (msg.sender == TEAM) {
      require(
        MintedReserves + _mintAmount <= TotalReservedAmount,
        'Not enough reserve tokens'
      );
      // Update reserve count
      MintedReserves += _mintAmount;
    } else {
      require(_mintIndex + _mintAmount <= MAX_SUPPLY, 'Exceeds supply');
      require(msg.value == (mintPrice * _mintAmount), 'Insufficient funds');
      // Validate colorTokenIds
      require(isHolder(colorTokenIds), 'COLORS not owned by sender.');
    }

    for (uint256 i = _mintIndex; i < (_mintIndex + _mintAmount); i++) {
      // Update states
      _colorTokenIds[i] = colorTokenIds;
      _seed[i] = _rng(i);

      // Mint
      _safeMint(msg.sender, i);
    }
  }

  /**
   * Store mapping between tokenId and applied tokenIdColors
   */
  function updateColors(uint256 tokenId, uint16[] calldata colorTokenIds)
    external
    payable
  {
    require(msg.sender == ownerOf(tokenId), 'Only NFT holder can updateColors');
    require(colorTokenIds.length <= 3, '# COLORS tokenIds must be <=3');
    require(msg.value >= resyncPrice, 'Insufficient funds');
    // Validate colorTokenIds
    require(isHolder(colorTokenIds), 'COLORS not owned by sender.');
    // Update state
    _colorTokenIds[tokenId] = colorTokenIds;
    _resync_count[tokenId] += 1;
  }

  /**
   * Verify that sender holds supplied colorTokenIds
   */
  function isHolder(uint16[] calldata colorTokenIds)
    private
    view
    returns (bool)
  {
    address colors_address = THE_COLORS;
    for (uint256 i = 0; i < colorTokenIds.length; i++) {
      if (
        msg.sender !=
        INFTOwner(colors_address).ownerOf(uint256(colorTokenIds[i]))
      ) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return NFT description
   */
  function generateNameDescription()
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '"external_url":"https://syncxcolors.xyz",',
          unicode'"description":"Sync X Colors is a unique, on-chain generative collection of Syncs on Ethereum. Each Sync can be re-colored with new Colors at any time."'
        )
      );
  }

  /**
   * Generate attributes json
   */
  function generateAttributes(
    uint256 tokenId,
    SyncTraitsStruct memory syncTraits
  ) internal view returns (string memory) {
    uint16[] memory colorTokenIds = _colorTokenIds[tokenId];
    uint256 length = colorTokenIds.length;
    bytes[] memory colorArray = new bytes[](3);
    for (uint256 i = 0; i < length; i++) {
      colorArray[i] = bytes(
        TheColors(THE_COLORS).getHexColor(uint256(colorTokenIds[i]))
      );
    }
    // fixing assembly overflow error, too much params
    string memory attributes = string(
        abi.encodePacked(
          '"attributes":[',
          '{"trait_type":"Rarity","value":"',
          syncTraits.theme,
          '"},',
          '{"trait_type":"Sigil","value":"',
          syncTraits.sigil,
          '"},'
        )
    );
    attributes = string(
        abi.encodePacked(
          attributes,
          '{"trait_type":"Color 1","value":"',
          colorArray[0],
          '"},',
          '{"trait_type":"Color 2","value":"',
          colorArray[1],
          '"},',
          '{"trait_type":"Color 3","value":"',
          colorArray[2],
          '"},',
          '{"trait_type":"Resyncs","value":',
          _resync_count[tokenId].toString(),
          '}]'
      )
    );
    return attributes;
  }

  /**
   * Returns hex strings representing colorTokenIDs as an array
   */
  function getColorsHexStrings(uint256 tokenId)
    internal
    view
    returns (bytes[] memory)
  {
    uint16[] memory colorTokenIds = _colorTokenIds[tokenId];
    uint256 length = _colorTokenIds[tokenId].length;
    bytes[] memory hexColors = new bytes[](3);
    hexColors[0] = '#222222'; // Defaults (grayscale)
    hexColors[1] = '#777777';
    hexColors[2] = '#AAAAAA';
    for (uint256 i = 0; i < length; i++) {
      hexColors[i] = bytes(
        TheColors(THE_COLORS).getHexColor(uint256(colorTokenIds[i]))
      );
    }
    return hexColors;
  }

  /**
   * Generates the SVG
   */
  function generateSVGImage(uint256 tokenId, SyncTraitsStruct memory syncTraits)
    private
    pure
    returns (string memory)
  {
    bytes memory svgBG = generateSVGBG(syncTraits);
    bytes memory svgInfinity = generateSVGInfinity(syncTraits.infColors);
    bytes memory svgLogo = generateSVGLogo(
      syncTraits.baseColors,
      syncTraits.logoColors,
      syncTraits.rarity_roll,
      tokenId.toString()
    );
    bytes memory svgDrift = generateSVGDrift(
      syncTraits.baseColors,
      syncTraits.driftColors,
      syncTraits.rarity_roll,
      syncTraits.sigil,
      tokenId.toString()
    );
    return
      string(
        abi.encodePacked(
          '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500" viewbox="0 0 500 500" style="background-color:#111111">',
          svgBG,
          svgInfinity,
          svgLogo,
          svgDrift,
          '</svg>'
        )
      );
  }

  /**
   * Generates the SVG Background
   */
  function generateSVGBG(SyncTraitsStruct memory syncTraits)
    private
    pure
    returns (bytes memory)
  {
    bytes memory newShape;
    bytes memory svgBG = '<g fill-opacity="0.3">';

    for (uint256 i = 0; i < 15; i++) {
      if (syncTraits.shape_type[i] == 0) {
        newShape = abi.encodePacked(
          '<circle fill="',
          syncTraits.bgColors[syncTraits.shape_color[i]],
          '" cx="',
          syncTraits.shape_x[i].toString(),
          '" cy="',
          syncTraits.shape_y[i].toString(),
          '" r="',
          syncTraits.shape_sizex[i].toString(),
          '"'
        );
      } else if (syncTraits.shape_type[i] == 1) {
        newShape = abi.encodePacked(
          '<rect fill="',
          syncTraits.bgColors[syncTraits.shape_color[i]],
          '" x="',
          (syncTraits.shape_x[i] / 2).toString(),
          '" y="',
          (syncTraits.shape_y[i] / 2).toString(),
          '" width="',
          (syncTraits.shape_sizex[i] * 2).toString(),
          '" height="',
          (syncTraits.shape_sizey[i] * 2).toString(),
          '" transform="rotate(',
          syncTraits.shape_r[i].toString(),
          ')"'
        );
      }
      if (
        (syncTraits.rarity_roll % 19 == 0 &&
          syncTraits.rarity_roll % 95 != 0) ||
        (syncTraits.rarity_roll % 13 == 0)
      ) {
        // Silver or Mosaic
        // Add strokes to background elements
        newShape = abi.encodePacked(
          newShape,
          ' stroke="',
          syncTraits.infColors[syncTraits.shape_color[i]],
          '"/>'
        );
      } else {
        newShape = abi.encodePacked(newShape, '/>');
      }

      svgBG = abi.encodePacked(svgBG, newShape);
    }
    return abi.encodePacked(svgBG, '</g>');
  }

  /**
   * Generates the infinity
   */
  function generateSVGInfinity(bytes[] memory infColors)
    private
    pure
    returns (bytes memory)
  {
    bytes memory infinity1 = abi.encodePacked(
      '<g><path stroke-dasharray="0" stroke-dashoffset="0" stroke-width="16" ',
      'd="M195.5 248c0 30 37.5 30 52.5 0s 52.5-30 52.5 0s-37.5 30-52.5 0s-52.5-30-52.5 0" fill="none">',
      '<animate begin="s.begin" attributeType="XML" attributeName="stroke" values="',
      infColors[0],
      ';',
      infColors[1],
      ';',
      infColors[0],
      '" dur="4s" fill="freeze"/>'
    );
    bytes memory infinity2 = abi.encodePacked(
      '<animate begin="s.begin" attributeType="XML" attributeName="stroke-dasharray" values="0;50;0" dur="6s" fill="freeze"/>',
      '<animate begin="a.begin" attributeType="XML" attributeName="stroke-width" values="16;20;16" dur="1s" fill="freeze"/>',
      '</path><path stroke-dasharray="300" stroke-dashoffset="300" stroke-width="16" ',
      'd="M195.5 248c0 30 37.5 30 52.5 0s 52.5-30 52.5 0s-37.5 30-52.5 0s-52.5-30-52.5 0" fill="none">'
    );
    bytes memory infinity3 = abi.encodePacked(
      '<animate begin="s.begin" attributeType="XML" attributeName="stroke" values="',
      infColors[2],
      ';',
      infColors[0],
      ';',
      infColors[2],
      '" dur="4s" fill="freeze"/>',
      '<animate id="a" begin="s.begin;a.end" attributeType="XML" attributeName="stroke-width" values="16;20;16" dur="1s" fill="freeze"/>',
      '<animate id="s" attributeType="XML" attributeName="stroke-dashoffset" begin="0s;s.end" to= "-1800" dur="6s"/></path></g>'
    );
    return abi.encodePacked(infinity1, infinity2, infinity3);
  }

  /**
   * Generates the logo
   */
  function generateSVGLogo(
    bytes[] memory baseColors,
    bytes memory logoColors,
    uint16 rarity_roll,
    string memory tokenId
  ) private pure returns (bytes memory) {
    
    bytes memory logo = abi.encodePacked(
      '<g id="',tokenId,'b">',
      '<path d="M194 179H131c-34 65 0 143 0 143h63C132 251 194 179 194 179Zm-26 128H144s-25-35 0-111h23S126 245 168 307Z" ',
      'stroke="black" fill-opacity="0.9" stroke-width="0.7">'
    );

    if (
      rarity_roll % 333 == 0 || rarity_roll % 241 == 0 || rarity_roll % 19 == 0
    ) {
      //Shimmer
      logo = abi.encodePacked(
        logo,
        '<set attributeName="stroke-dasharray" to="20"/>',
        '<set attributeName="stroke-width" to="2"/>',
        '<set attributeName="fill" to="',
        logoColors,
        '"/>',
        '<animate begin="s.begin" attributeType="XML" attributeName="stroke-dashoffset" from="0" to="280" dur="6s" fill="freeze"/>',
        '<animate begin="s.begin" attributeType="XML" attributeName="stroke" values="',
        baseColors[0],
        ';',
        baseColors[1],
        ';',
        baseColors[2],
        ';',
        baseColors[0],
        '" dur="6s" fill="freeze"/>'
      );
    } else {
      logo = abi.encodePacked(
        logo,
        '<animate begin="s.begin" attributeName="fill" dur="6s" '
        'values="black;',
        baseColors[0],
        ';black;',
        baseColors[1],
        ';black;',
        baseColors[2],
        ';black"/>'
      );
    }
    return logo;
  }

  /**
   * Generates the drift
   */
  function generateSVGDrift(
    bytes[] memory baseColors,
    bytes memory driftColors,
    uint16 rarity_roll,
    bytes7 sigil,
    string memory tokenId
  ) private pure returns (bytes memory) {
    if (rarity_roll % 11 != 0) {
      // Drift is colored as a single color unless Tokyo Drift trait
      baseColors[0] = driftColors;
      baseColors[1] = driftColors;
      baseColors[2] = driftColors;
    }
    bytes memory borders1 = abi.encodePacked(
      '</path><text x="2" y="40" font-size="3em" fill-opacity="0.3" fill="',
      'black">',
      sigil,
      '</text>',
      '<path d="M90 203c-21 41 0 91 0 91h11c0 0-16-42 0-91z" stroke-opacity="0.7" fill-opacity="0.7" fill="transparent">'
      '<animate id="w" attributeName="fill" values="transparent;',
      baseColors[0],
      ';transparent" begin="s.begin+.17s;s.begin+2.17s;s.begin+4.17s" dur="1s"/>',
      '<animate begin="w.begin" attributeName="stroke" values="transparent;black;transparent" dur="1s"/>',
      '</path>'
    );

    bytes memory borders2 = abi.encodePacked(
      '<path d="M60 212c-17 34 0 74 0 74h9c0-1-13-34 0-74z" stroke-opacity="0.5" fill-opacity="0.5" fill="transparent">',
      '<animate attributeName="fill" values="transparent;',
      baseColors[1],
      ';transparent" begin="w.begin+0.2s" dur="1s"/>',
      '<animate attributeName="stroke" values="transparent;black;transparent" begin="w.begin+0.2s" dur="1s"/>',
      '</path>'
    );

    bytes memory borders3 = abi.encodePacked(
      '<path d="M37 221c-13 26 0 57 0 57h7c0 0-10-26 0-57z" stroke-opacity="0.3" fill-opacity="0.3" fill="transparent">',
      '<animate attributeName="fill" values="transparent;',
      baseColors[2],
      ';transparent" begin="w.begin+0.4s" dur="1s"/>',
      '<animate attributeName="stroke" values="transparent;black;transparent" begin="w.begin+0.4s" dur="1s"/>',
      '</path></g><use href="#',tokenId,'b" x="-500" y="-500" transform="rotate(180)"/>'
    );

    return abi.encodePacked(borders1, borders2, borders3);
  }

  /**
   * Generates the NFT traits by stored seed (note: seed generated and stored at mint)
   */
  function generateTraits(uint256 tokenId)
    private
    view
    returns (SyncTraitsStruct memory)
  {
    // Initialize struct arrays
    SyncTraitsStruct memory syncTraits;
    syncTraits.shape_x = new uint16[](15);
    syncTraits.shape_y = new uint16[](15);
    syncTraits.shape_sizex = new uint16[](15);
    syncTraits.shape_sizey = new uint16[](15);
    syncTraits.shape_r = new uint16[](15);
    syncTraits.shape_type = new uint8[](15);
    syncTraits.shape_color = new uint8[](15);
    syncTraits.bgColors = new bytes[](3);
    syncTraits.infColors = new bytes[](3);

    // Retrieve seed from storage
    uint256 seed = _seed[tokenId];
    syncTraits.rarity_roll = uint16(
      1 + ((seed & 0x3FF) % 1000) // range 1 to 2047 % 1000 - ~ slightly bottom heavy but round numbers nicer
    );

    // Calculate traits
    syncTraits.baseColors = getColorsHexStrings(tokenId);

    if (syncTraits.rarity_roll % 333 == 0) {
      // 0.3% probability (3 in 1000)
      syncTraits.theme = 'Concave';
      syncTraits.sigil = '\xE2\x9D\xAA\x20\xE2\x9D\xAB'; //( )
      syncTraits.bgColors[0] = '#214F70'; //Light Blue
      syncTraits.bgColors[1] = '#2E2E3F'; //Dark Blue
      syncTraits.bgColors[2] = '#2E2E3F'; //Dark Blue
      syncTraits.infColors[0] = '#FAF7C0'; //Con-yellow
      syncTraits.infColors[1] = '#214F70'; //Light Blue
      syncTraits.infColors[2] = '#FAF7C0'; //Con-yellow
      syncTraits.logoColors = '#FAF7C0'; //Con-yellow
      syncTraits.driftColors = '#FAF7C0';
    } else if (syncTraits.rarity_roll % 241 == 0) {
      // 0.4% probability (4 in 1000)
      syncTraits.theme = 'Olympus';
      syncTraits.sigil = '\xF0\x9D\x9B\x80\x20\x20\x20'; // OMEGA
      syncTraits.bgColors[0] = '#80A6AF'; // Oly Blue
      syncTraits.bgColors[1] = '#3A424F'; // Dark Blue
      syncTraits.bgColors[2] = '#80A6AF'; // Oly Blue
      syncTraits.infColors[0] = '#FFC768'; // Oly yellow
      syncTraits.infColors[1] = '#3A424F'; // Dark Blue
      syncTraits.infColors[2] = '#FFC768'; // Oly yellow
      syncTraits.logoColors = '#FFC768'; // Oly-yellow
      syncTraits.driftColors = '#FFC768';
    } else if (syncTraits.rarity_roll % 19 == 0) {
      // ~4% probability (50-10 in 1000)
      syncTraits.theme = 'Silver';
      syncTraits.sigil = '\xE2\x98\x86\x20\x20\x20\x20'; // Empty Star
      syncTraits.bgColors[0] = '#c0c0c0'; // Silver
      syncTraits.bgColors[1] = '#e5e4e2'; // Platinum
      syncTraits.bgColors[2] = '#c0c0c0'; // Silver
      syncTraits.infColors[0] = 'white';
      syncTraits.infColors[1] = '#C0C0C0'; // silver
      syncTraits.infColors[2] = '#CD7F32'; // Gold
      syncTraits.logoColors = 'black';
      syncTraits.driftColors = 'black';
      // Silver has 1 in 4 chance of upgrading to gold
      // (contract memory usage happened to be more efficient this way)
      if (syncTraits.rarity_roll % 95 == 0) {
        // `~1% probability (10 in 1000)
        syncTraits.theme = 'Gold'; // Gold
        syncTraits.sigil = '\xE2\x98\x85\x20\x20\x20\x20'; // Full star
        syncTraits.bgColors[0] = '#CD7F32'; // Gold
        syncTraits.bgColors[2] = '#725d18'; // Darker Gold
        syncTraits.infColors[0] = 'black';
        syncTraits.infColors[2] = '#E5E4E2'; // Platinum
      }
    } else {
      syncTraits.theme = 'Common'; // Common
      syncTraits.sigil = '\xE2\x97\x8F\x20\x20\x20\x20'; // Circle 
      syncTraits.driftColors = 'white';
      syncTraits.bgColors = syncTraits.baseColors;
      syncTraits.infColors = syncTraits.baseColors;

      bytes[] memory upgrades = new bytes[](3);
      upgrades[0] = '#214F70';
      upgrades[1] = '#FAF7C0';
      upgrades[2] = '#222222';
      
      if (syncTraits.rarity_roll % 13 == 0) {
        // 7.7% probability ((77 in 1000)
        syncTraits.theme = 'Mosaic';
        syncTraits.sigil = '\xE2\x9C\xA6\x20\x20\x20\x20'; // Full Diamond
        upgrades[2] = '#3A424F';
      } else if (syncTraits.rarity_roll % 11 == 0) {
        // 9% probability (91 in 1000)
        syncTraits.theme = 'Tokyo Drift';
        syncTraits.sigil = '\xE2\x9C\xA7\x20\x20\x20\x20'; //Empty Diamond
        upgrades[2] = '#3A424F';
      }
      if (_colorTokenIds[tokenId].length == 0){
        syncTraits.baseColors[0] = upgrades[syncTraits.rarity_roll % 3];
      }
    }
    //Background generation
    for (uint256 i = 0; i < 15; i++) {
      syncTraits.shape_x[i] = uint16(1 + ((seed & 0x3FF) % 500));
      syncTraits.shape_y[i] = uint16(1 + (((seed & 0x3FF0000) / 2**4) % 500));
      syncTraits.shape_sizex[i] = uint16(
        250 + (((seed & 0x1FF00000000) / 2**5) % 151)
      );
      syncTraits.shape_sizey[i] = uint16(
        250 + (((seed & 0x1FF000000000000) >> 48) % 151)
      );
      syncTraits.shape_r[i] = uint16(
        1 + (((seed & 0x1FF0000000000000000) / 2**6) % 360)
      );
      syncTraits.shape_type[i] = uint8(
        ((seed & 0x1FF00000000000000000000) >> 80) % 2
      );
      syncTraits.shape_color[i] = uint8(
        ((seed & 0x1FF000000000000000000000000) >> 96) % 3
      );
      seed = seed >> 2;
    }
    return syncTraits;
  }

  /**
   * Produce a PRNG uint256 as hash of several inputs
   */
  function _rng(uint256 tokenId) private view returns (uint256) {
    uint256 _tokenId = tokenId + 1;
    uint256 seed = uint256(uint160(THE_COLORS));
    return
      uint256(
        keccak256(
          abi.encodePacked(
            _tokenId.toString(),
            block.timestamp,
            block.difficulty,
            seed
          )
        )
      ) + uint256(_tokenId * seed);
  }
}