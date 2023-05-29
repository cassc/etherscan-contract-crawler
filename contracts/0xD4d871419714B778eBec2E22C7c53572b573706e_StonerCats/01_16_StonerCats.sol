// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

// @title: Stoner Cats
// @author: bighead.club

////////////////////////////////////////////////////////////////////////
//                                                                    //
//    __     =^..^=                                                   //
//  =^._.^=   (u u).                    =^..^=                        //
//  (_)--\_)  (   \     =^..^=___. ,--. //--//(,------.,------,       //
//  /    _ / |'--b..b__)( u u).-.\|   \ |  |) |  .---'|   ---`'       //
//  \_..`--. `--.  .--'( _) | |  ||  . '|  |d |  '--. |  |_.' |       //
//  .-._)   \   |  |    \|  | |  ||  |\    |  |  .--' |  .   .'       //
//  \       /   |  |     '  '-'  '|  | \   |  |  `---.|  |\  \        //
//   `-----'    `--'      `-----' `--'  `--'  `------'`--' '--'       //
//                                                                    //
//                                                    ((((            //
//   ,-----.  ,----.   _=^..^= __∫ _____        .,,  ((((((  .//.     //
//  /  .--./ |  /`. \ |   uu...u_)  ___/       /(((( `(((/. (((((     //
//  | =^..^= '-'|_.' |`--.  .--'\_..`--.       (((((. ..,.  /(((/     //
//  |  |u u )(|  .-. |   |  |   .-._)   \     ,,```. ((((((./(' /(\   //
//  '  '--'\ |  | |  |   |  |   \       /    ((((,, .((/((((. '((((   //
//   `-----' `--' `--'   `--'    `-----'     .((/,..(((((((((( *((,   //
//                                                 (////((((((        //
//                                                  ((//((/)          //
//                                                                    //
////////////////////////////////////////////////////////////////////////

// OpenZeppelin
import "./token/ERC721/ERC721.sol";
import "./access/Ownable.sol";
import "./security/ReentrancyGuard.sol";
import "./introspection/ERC165.sol";
import "./utils/Strings.sol";
import "./access/Ownable.sol";

contract StonerCats is ERC721, Ownable, ReentrancyGuard {
  using SafeMath for uint8;
  using SafeMath for uint256;
  using Strings for string;

  // Max NFTs total. Due to burning this won't be the max tokenId
  uint public constant MAX_TOKENS = 13420;
  // Max at launch before ltd edition chars unlock
  uint public constant MAX_TOKENS_INIT = 10420;
  // Track current supply cap in range [MAX_TOKENS_INIT, MAX_TOKENS]
  uint internal CURR_SUPPLY_CAP = MAX_TOKENS_INIT;

  // Allow for starting/pausing sale
  bool public hasSaleStarted = false;

  // Effectively a UUID. Only increments to avoid collisions
  // possible if we were reusing token IDs
  uint internal nextTokenId = 0;

  /*
   * Set up the basics
   *
   * @dev It will NOT be ready to start sale immediately upon deploy
   */
  constructor(string memory baseURI) ERC721("Stoner Cats","TOKEn") {
    setBaseURI(baseURI);
  }

  /*
   * Get the tokens owned by _owner
   */
  function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  /*
   * Calculate price for the immediate next NFT minted
   */
  function calculatePrice() public view returns (uint256) {
    require(hasSaleStarted == true, "Sale hasn't started");
    require(totalSupply() < CURR_SUPPLY_CAP,
            "We're at max supply!");

    return 350000000000000000;  // 0.35 ETH
  }

  /*
   * Main function for the NFT sale
   *
   * Prerequisites
   *  - Not at max supply
   *  - Sale has started
   */
  function mewnt(uint256 numTokens) external payable nonReentrant {
    require(totalSupply() < CURR_SUPPLY_CAP,
           "We are at max supply. Burn some in a paper bag...?");
    require(numTokens > 0 && numTokens <= 20, "You can drop minimum 1, maximum 20 NFTs");
    require(totalSupply().add(numTokens) <= CURR_SUPPLY_CAP, "Exceeds CURR_SUPPLY_CAP");
    require(msg.value >= calculatePrice().mul(numTokens),
           "Ether value sent is below the price");

    for (uint i = 0; i < numTokens; i++) {
      uint mintId = nextTokenId++;
      _safeMint(msg.sender, mintId);
      _setTokenURI(mintId, Strings.strConcat(Strings.uint2str(mintId), "/index.json"));
    }
  }

  /*
   * Only valid before the sales starts, for giveaways/team thank you's
   */
  function reserveGiveaway(uint256 numTokens) public onlyOwner {
    uint currentSupply = totalSupply();
    require(totalSupply().add(numTokens) <= 100, "Exceeded giveaway supply");
    require(hasSaleStarted == false, "Sale has already started");
    uint256 index;
    // Reserved for people who helped this project and giveaways
    for (index = 0; index < numTokens; index++) {
      nextTokenId++;
      _safeMint(owner(), currentSupply + index);
			_setTokenURI(currentSupply + index,
      Strings.strConcat(Strings.uint2str(currentSupply + index), "/index.json"));
    }
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
    return ERC165.supportsInterface(interfaceId);
  }


  // Admin functions

  /*
   * @dev Under the max of 13420, new characters from future episodes may
   * get their own tokens. This makes room for those new ones,
   * but still cannot go past the supply cap.
   */
  function addCharacter(uint numTokens) public onlyOwner {
    require(CURR_SUPPLY_CAP + numTokens <= MAX_TOKENS,
            "Can't add new character NFTs. Would exceed MAX_TOKENS");

    CURR_SUPPLY_CAP = CURR_SUPPLY_CAP + numTokens;
  }
  
  function getCurrentSupplyCap() public view returns(uint) {
    return CURR_SUPPLY_CAP;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }

  function startSale() public onlyOwner {
    hasSaleStarted = true;
  }

  function pauseSale() public onlyOwner {
    hasSaleStarted = false;
  }

  function withdrawAll() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}