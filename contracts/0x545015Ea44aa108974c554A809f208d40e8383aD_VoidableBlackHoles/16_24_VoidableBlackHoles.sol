// SPDX-License-Identifier: MIT
/*                                                                                                                                                                                                                                          
                                                         ........................                                                           
                                                   .....*22222222222222222222222#......                                                     
                                                  ,*****(222222222222222222222222******                                                     
                                                ../22222244444444444444444444444422222#...                                                  
                                             ..*22222244(                       .444222222...                                               
                                          ../22244444(                              44444422#...                                            
                                       ../22222244/                                   .444222222...                                         
                                       ../22244/                                          444222...                                         
                                      .,,(22###*                                          ###222,,,                                         
                                    ../22244*                                                444222...                                      
                                    ../22244*                                                444222...                                      
                                    ../22244*                                                444222...                                      
                                   .../22244*                                                444222...                                      
                                 ../((#22244*                                                444222(((...                                   
                                ...(22222244*                                                44422222#...                                   
                             ...(22222244444/...............................................,444444222222...                                
                             #444444444444444444444444444444444444444444444444444444444444444444444444444442                                
                                 ................./22222222222222222222222222222222222#..................                                   
                                       ../22244/            ..................            444222...                                         
                                       ../22222(**.                                    ***222222...                                         
                                       ../22222244/                                   .444222222...                                         
                                          ../22244444(                              44444422#...                                            
                                          .....*22222244(                       .444222222...                                               
                                                ../22222244444444444444444444444422222#...                                                  
                                                   .....*22222222222222222222222#......                                                     
                                                   .....*#######################(......                                                     
                                                         ........................                                                           
                                                                                    ..                                                      
                                                                                                                                            
                                                                                                                                            
                                                                                                                                            
                                                                                                                                            
     ,@  [email protected]  #(((   (@(  (4(#(   (@2  /@((4/  @     @@((.       ,@((##  @,     [email protected]#   (2(4* @, *4        @*  @* /2(4, [email protected]    #4((  /4((@,    
     [email protected], /4 22  @#   @   (2  44 ,@ 4/ /@,,2#  @     @4,,        ,@*,/2  @,    /4 @, #2     @/#(         @(,*@* @  /4 [email protected]    #4,,  (2,,,     
      [email protected],@  #2  @#  [email protected]   #2  44 (@[email protected] (4  #4 [email protected]     @4          ,@  ,@  @,    [email protected]@2 #4     @,(2         @,  @* @  (4 [email protected]    #2        4(    
       .4    *44.  .444  (444,  4*  4 /4444.  4444, 4444,       ,4444*  4444#.4. .4  ,444  4, .4.       4,  4*  44#  .4444/ (444.  4444                                                                                                                                                                                                                                  
*/

pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC4906} from "./interfaces/ERC4906.sol";
import "./Utilities.sol";
import "./Renderer.sol";
import "./BlackHoles.sol";
import "./interfaces/BlackHole.sol";
import "svgnft/contracts/Base64.sol";

contract VoidableBlackHoles is ERC4906, Ownable {
  error NotAllowed();
  error URIQueryForNonexistentToken();

  uint256 public mergeOpenTimestamp;

  mapping(uint256 => uint256) public massesConsumed;

  Renderer public renderer;
  BlackHoles public unmigratedBlackHoles;

  uint256 minted;
  uint256 burned;

  /**
   * @dev Constructs a new instance of the contract.
   * @param _name Name of the ERC721 token.
   * @param _symbol Symbol of the ERC721 token.
   * @param _mergeOpenTimestamp Timestamp when merging is open.
   * @param _renderer Address of the Renderer contract.
   * @param _unmigratedBlackHoles Address of Black Holes contract.
   */
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _mergeOpenTimestamp,
    address _renderer,
    address _unmigratedBlackHoles
  ) ERC4906(_name, _symbol) {
    mergeOpenTimestamp = _mergeOpenTimestamp;
    renderer = Renderer(_renderer);
    unmigratedBlackHoles = BlackHoles(_unmigratedBlackHoles);
  }

  /**
   * @notice Sets the merging delay.
   * @param _mergeOpenTimestamp Timestamp when merging is open.
   */
  function setMergeOpenTimestamp(uint256 _mergeOpenTimestamp) external onlyOwner {
    mergeOpenTimestamp = _mergeOpenTimestamp;
  }

  /**
   * @notice Returns the token URI for a given token ID.
   * @param _tokenId ID of the token to get the URI for.
   * @return Token URI.
   */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

    string memory name = string(abi.encodePacked("Voidable BlackHole #", utils.uint2str(_tokenId)));
    string memory description = "Fully on-chain, procedurally generated, animated black holes. Ready to be merged.";

    BlackHole memory blackHole = blackHoleForTokenId(_tokenId);

    string memory svg = renderer.getBlackHoleSVG(blackHole);

    string memory attributes = string.concat(
      "[",
      '{"trait_type": "Level", "value": ',
      utils.uint2str(blackHole.level),
      "},",
      '{"trait_type": "Name", "value": "',
      blackHole.name,
      '"},',
      '{"trait_type": "Mass", "value": ',
      utils.uint2str(blackHole.mass),
      "}]"
    );

    string memory json = string(
      abi.encodePacked(
        '{"name":"',
        name,
        '","description":"',
        description,
        '",',
        '"attributes": ',
        attributes, // attributes
        ', "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(svg)),
        '"}'
      )
    );
    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
  }

  /**
   * @notice Get the structured representation of a token by its ID.
   * @param _tokenId ID of the token.
   * @return BlackHole Structured representation of the token.
   */
  function blackHoleForTokenId(uint256 _tokenId) public view returns (BlackHole memory) {
    uint256 mass = massForTokenId(_tokenId);
    uint256 level = levelForMass(mass);
    string memory name = nameForBlackHoleLevel(level);
    uint256 adjustment = getAdjustmentForMass(mass);

    return
      BlackHole({
        tokenId: _tokenId,
        level: level,
        size: renderer.PIXELS_PER_SIDE() / 2 - (10 - level),
        mass: mass,
        name: name,
        adjustment: adjustment
      });
  }

  /**
   * @notice Gets adjustment for a given mass.
   * @param _mass Mass to calculate the adjustment for.
   * @return Adjustment.
   */
  function getAdjustmentForMass(uint256 _mass) public view returns (uint256) {
    uint256 level = levelForMass(_mass); // 1

    if (level == unmigratedBlackHoles.MAX_LEVEL()) {
      return 0;
    }

    int256 maxAdjustment = 20;
    int256 adjustment = 0;
    uint256[] memory upgradeIntervals = getUpgradeIntervals();

    if (level == 0) {
      adjustment = (-maxAdjustment * int256(_mass - 1)) / int256(upgradeIntervals[0] - 2) + maxAdjustment;
    } else {
      adjustment =
        (-maxAdjustment * int256(_mass - upgradeIntervals[level - 1])) /
        int256(upgradeIntervals[level] - upgradeIntervals[level - 1] - 1) +
        maxAdjustment;
    }

    return uint256(adjustment);
  }

  /**
   * @notice Gets the level for a given mass.
   */
  function levelForMass(uint256 _mass) public view returns (uint256) {
    uint256[] memory upgradeIntervals = getUpgradeIntervals();

    if (_mass < upgradeIntervals[0]) {
      return 0;
    } else if (_mass < upgradeIntervals[1]) {
      return 1;
    } else if (_mass < upgradeIntervals[2]) {
      return 2;
    } else if (_mass < upgradeIntervals[3]) {
      return 3;
    } else {
      return 4;
    }
  }

  function massForTokenId(uint256 _tokenId) public view returns (uint256) {
    return massesConsumed[_tokenId] + 1;
  }

  /**
   * @notice Returns the mass required to upgrade to the next level for each level.
   */
  function getUpgradeIntervals() public view returns (uint256[] memory) {
    uint256 baseUpgradeMass = utils.max(
      unmigratedBlackHoles.totalMinted() /
        unmigratedBlackHoles.MAX_SUPPLY_OF_INTERSTELLAR() /
        2**(unmigratedBlackHoles.MAX_LEVEL() - 1),
      2
    );
    uint256[] memory intervals = new uint256[](unmigratedBlackHoles.MAX_LEVEL() + 1);
    intervals[0] = 5;
    intervals[1] = baseUpgradeMass * 2;
    intervals[2] = baseUpgradeMass * 4;
    intervals[3] = baseUpgradeMass * 8;
    return intervals;
  }

  /**
   * @notice Returns the name of a black hole level.
   * @param _level Level of the black hole.
   * @return name of the black hole level.
   */
  function nameForBlackHoleLevel(uint256 _level) public view returns (string memory) {
    return unmigratedBlackHoles.nameForBlackHoleLevel(_level);
  }

  /**
   * @notice Migrate Black Holes to Voidable Black Holes by burning the Black Holes.
   *         Requires the Approval of this contract on the Edition contract.
   * @param tokenIds The Edition token IDs you want to migrate.
   */
  function mint(uint256[] calldata tokenIds) external {
    uint256 count = tokenIds.length;

    // Burn the Black Holes for the given tokenIds & mint the Voidable Black Holes.
    for (uint256 i; i < count; ) {
      uint256 id = tokenIds[i];
      address owner = unmigratedBlackHoles.ownerOf(id);

      // Check whether we're allowed to migrate this Black Hole.
      if (
        owner != msg.sender &&
        (!unmigratedBlackHoles.isApprovedForAll(owner, msg.sender)) &&
        unmigratedBlackHoles.getApproved(id) != msg.sender
      ) {
        revert NotAllowed();
      }

      // Burn old.
      unmigratedBlackHoles.transferFrom(owner, address(1), id);

      // Mint new.
      _safeMint(msg.sender, id);

      unchecked {
        ++i;
      }
    }

    // Keep track of how many checks have been minted.
    unchecked {
      minted += uint32(count);
    }
  }

  /**
   * @notice Returns whether merging is enabled or not.
   */
  function isMergingEnabled() public view returns (bool) {
    return block.timestamp > mergeOpenTimestamp;
  }

  /**
   * @notice Simulates the merge for an array of tokens.
   * @param tokens Array of tokens to merge.
   * @return BlackHole struct of new Black Hole.
   * @return SVG of new Black Hole.
   */
  function simulateMerge(uint256[] memory tokens) public view returns (BlackHole memory, string memory) {
    uint256 targetId = tokens[0];

    uint256 sum;
    for (uint256 i = 1; i < tokens.length; ) {
      sum = sum + massForTokenId(tokens[i]);

      unchecked {
        ++i;
      }
    }

    uint256 mass = massForTokenId(targetId) + sum;
    uint256 level = levelForMass(mass);
    string memory name = nameForBlackHoleLevel(level);
    uint256 adjustment = getAdjustmentForMass(mass);

    BlackHole memory blackHole = BlackHole({
      tokenId: targetId,
      level: level,
      size: renderer.PIXELS_PER_SIDE() / 2 - (10 - level),
      mass: mass,
      name: name,
      adjustment: adjustment
    });

    return (blackHole, renderer.getBlackHoleSVG(blackHole));
  }

  /**
   * @notice Merges a list of tokens into a single token.
   * @param tokens List of token IDs to merge. The first token in the list is the target.
   */
  function merge(uint256[] memory tokens) public {
    // Burn all tokens except the first one, aka the target
    // The mass of all other tokens get added to the target
    require(isMergingEnabled(), "Merging not enabled");
    require(tokens.length > 1, "Must merge at least 2 tokens");

    uint256 targetId = tokens[0];

    require(ownerOf(tokens[0]) == msg.sender, "Must own all tokens (target)");

    uint256 sum;
    for (uint256 i = 1; i < tokens.length; ) {
      require(ownerOf(tokens[i]) == msg.sender, "Must own all tokens (burn)");
      sum = sum + massForTokenId(tokens[i]);
      _burn(tokens[i]);

      unchecked {
        ++i;
      }
    }

    massesConsumed[targetId] += sum;

    emit MetadataUpdate(targetId);
  }

  /**
   * @notice Returns Black Holes for a list of token IDs.
   * @param tokenIds List of token IDs.
   */
  function blackHolesForTokenIds(uint256[] memory tokenIds) public view returns (BlackHole[] memory) {
    BlackHole[] memory blackHoles = new BlackHole[](tokenIds.length);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      blackHoles[i] = blackHoleForTokenId(tokenIds[i]);
    }
    return blackHoles;
  }

  function burn(uint256 tokenId) public {
    require(ownerOf(tokenId) == msg.sender, "Must own token");
    burned += 1;
    _burn(tokenId);
  }

  /**
   * @notice Returns total number of tokens minted.
   */
  function totalMinted() external view returns (uint256) {
    return minted;
  }

  /**
   * @notice Returns total number of tokens burned.
   */
  function totalBurned() external view returns (uint256) {
    return burned;
  }

  /**
   * @notice Returns how many tokens this contract manages.
   */
  function totalSupply() public view returns (uint256) {
    return minted - burned;
  }
}