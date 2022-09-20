// SPDX-License-Identifier: MIT
//
//      ╓       ▄▄
//      ╫█      ██▄
//       ██     ╫▌▀▌       █▌
//       ▓▌█┐    █¡╨█      █╫▌
//        █µ▀▌   ╚▓:└▀▌    █░╠▓
//        "█¡╙█▄  ╫▌⌐:│▀▌  ╚▓^┘▓▄
//         ╙█¡"╨▓▄ █▄::"┘▀▓▄█▌::╨▓┐
//          ╙█¡┌:╨▀▓█µ┌::┌:│▀▀:┌::╨▓▄
//           ╙█µ┌┌:\╙!:⌐┌┌::»;╓▄▄▄▄▓██▓▄,
//             █Q╓▄▄▄▄▌▓▓▓▓▓▓▀▀▀▀▀▀▀▓██▌▀▓█▌▄
//              ▓█▀▀╨╙┘⌐~'     '╥▓█▓▀╡█▌┐┐┐│╨▀▓▓▄▄
//             ╒█╨          '╓▓█▀╠░░░▒█▌▄▄░┐┐┐┐\│╨▀▓▓▄▄
//            ╓█╙'       ''▄▓█╬░░▄▓▀▀╢█▌╨╟▀▓▌µ¡┐¡┐!╫▓└╨▀▓▓▄▄
//           ╓█╛'        ▄█▓▒░Ü▓██▓▓▓▓█████▓█▓Ö┐┐┐▐█       ╙██▓▄▄
//          ╒█╙       '╥█▓╡░░░░╡┤┤▀▀▀░█▌└╨╨┐¡┐┐┐┐¡▓▌        ╨▀▀└╨▀▓▓▄╖
//         ┌█╨      '.▓█╟░░░░░░░░░░░░░█▌┐┐┐┐┐┐┐┐┐¡█▓▌▌▄▄▄▄▄µ,,      └╨▀▓▓▄┐
//         █▀      .╓█▓│░░░░░░░░░░░░░░█▌┐┐┐┐┐┐┐┐¡┐▓▌  └┴╙╟╫▓▓███████▓▓▓▌▄▌▓██▓▄┐
//        █▌'     '▄█▀░░░░░░░░░░░░░░░░█▌┐┐┐┐┐;(Q▄▄▓█▓▓▀▀▀╙╙╙└└└      └└└╙╙╙╙▀▀▀▓▀
//       █▓''     ╫█▒░░░░░░░░░░░░░░░░░█▌¡p▄▓▓▓▀╙└
//      ╫█ '    '╫█▒░░░░░░░░░░░░░░░░░▒██▓▀└
//     ╔█─.     ╟█▒░░░░░░░░░░░░░░░▄▓█▀█▌
//     █╝'     ╥█▀░░░░░░░░░░░░░▄▓█▀┤┌⌐█▌
//    █▌      .█▓░░░░░░░░░░░░▄█▓╙┌┌┌┌⌐█▌
//   ╫█.     '╫█░░░░░░░░░░░▄█▀┘┌┌:┌┌:⌐█▌
//  ┌█b.     .█▌░░░░░░░░░▄█▀└:┌┌┌┌┌┌┌⌐█▌
//  ╙▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀¬
//
//      The Stoics by Gabe Weis
//         Phoenix Burn Token
//           thestoics.art
//
//       Assisted by Merlyn Labs
//
//    Smart Contract v0 by Ryan Meyers
//
//    Generosity attracts generosity
//   The world will be saved by beauty
//
//

pragma solidity ^0.8.16;

import "ERC721AQueryable.sol";

import "Ownable.sol";

import "ERC2981.sol";

import "draft-EIP712.sol";
import "ECDSA.sol";

import "Base64.sol";
import "Strings.sol";

interface ITheStoics is IERC721AQueryable {}

contract PhoenixBurn is ERC2981, EIP712, ERC721AQueryable, Ownable {

  error ExceedsMaxSupply();
  error InsufficientPhoenixSouls();
  error NotAllowed();
  error BadTiming();
  error InsufficientStoics();
  error BadMintKey();

  event RedeemedPhoenixSouls(address holder, uint howMany, string perkName);

  struct MintKey {
    address wallet;
    uint8 generation;
  }

  bytes32 private constant MINTKEY_TYPE_HASH = keccak256("MintKey(address wallet,uint8 generation)");

  address private _signer;

  uint8 public MAX_SUPPLY = 222;
  uint8 public GENERATION = 0;
  bool public REBIRTH_CYCLE = false;
  uint public CURRENT_PERK_COST = 5;
  string public CURRENT_PERK = "Inactive";

  
  address public STOICS;
  string public imageURI;

  constructor(
      string memory name,
      string memory symbol,
      address signer,
      address receiver,
      address stoics
    )
     ERC721A(name, symbol)
     EIP712(name, "1")
    {
      setSigner(signer);
      setStoics(stoics);
      
      _setDefaultRoyalty(receiver, 1000);

    }

    // If REBIRTH_CYCLE, minting is open and burning is closed; if not vice-versa
    function startRebirthCycle() public onlyOwner {
      REBIRTH_CYCLE = true;
    }
    function endRebirthCycle() public onlyOwner {
      REBIRTH_CYCLE = false;
      GENERATION += 1;
    }
    

    // Send a list of addresses one PBT each
    function riseAndFlyTo(address[] calldata targets) public onlyOwner {
      if (totalSupply() + targets.length > MAX_SUPPLY) revert ExceedsMaxSupply();
      for (uint i = 0; i < targets.length; i++) {
        _mint(targets[i], 1);
      }
    }

    // Mint PBTs
    // Requirements:
    // Must be in REBIRTH_CYCLE
    // Must have a valid mint key (by wallet/generation)
    // Must not exceed 222 total
    // Must have at least the number of Stoics as PBTs 
    // 
    // When the total supply reaches 222, it automatically switches to a new generation and toggles REBIRTH_CYCLE
    function riseFromTheAshes(bytes calldata signature, uint howMany) public {
      if (!REBIRTH_CYCLE) revert BadTiming();
      if (!verify(signature)) revert BadMintKey();
      if (totalSupply() + howMany > MAX_SUPPLY) revert ExceedsMaxSupply();
      if (IERC721A(STOICS).balanceOf(msg.sender) - balanceOf(msg.sender) < howMany) revert InsufficientStoics();

      _mint(msg.sender, howMany);

      if(totalSupply() == MAX_SUPPLY){
        REBIRTH_CYCLE = false;
        GENERATION += 1;
      }

    }

    // Burn a PBT
    // May only be called by the owner of the token OR the owner of the contract
    // When burned, credits are given to that wallet address and the token goes away
    function returnToDust(uint[] calldata tokens) public {
      if (REBIRTH_CYCLE) revert BadTiming();
      for (uint i = 0; i < tokens.length; i++){
        _burn(tokens[i], msg.sender != owner());
      }
    }

    // How many phoenix souls are held by the wallet?
    // = number burned - number spent
    function phoenixSoulBalance(address holder) public view returns (uint256){
      return _numberBurned(holder) - _getAux(holder);
    }

    // Redeem souls for a perk
    function redeemPhoenixSouls(address holder, uint64 howMany) public {
      if (howMany != CURRENT_PERK_COST) revert InsufficientPhoenixSouls();
      if(holder != msg.sender){
        if (msg.sender != owner()){
          revert NotAllowed();
        }
      }
      if (phoenixSoulBalance(holder) < howMany) revert InsufficientPhoenixSouls();

      _setAux(holder, _getAux(holder) + howMany);

      emit RedeemedPhoenixSouls(holder, howMany, CURRENT_PERK);

    }


    // Setter methods
    function setSigner(address signer) public onlyOwner {
      _signer = signer;
    }
    function setStoics(address stoics) public onlyOwner {
      STOICS = stoics;
    }
    function setImageURI(string memory uri) public onlyOwner {
      imageURI = uri;
    }
    function setRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
      _setDefaultRoyalty(receiver, feeNumerator);
    }
    function setCurrentPerk(string memory perk, uint perk_cost) public onlyOwner {
      CURRENT_PERK = perk;
      CURRENT_PERK_COST = perk_cost;
    }

    // Public getter methods
    function BURN_CYCLE() public view returns (bool) {
      return !REBIRTH_CYCLE;
    }

    // https://codebeautify.org/html-decode-string
    function SEED_PUZZLE_HINT() public pure returns (string memory) {
      return "&#x2B7;&#xBA;&#x2B3;&#x1D48;&#x2154;&hyphen;&#x2192;&dash;";
    }

    function verify(bytes calldata signature) public view returns (bool) {
    bytes32 digest = _hashTypedDataV4(
        keccak256(
            abi.encode(
                MINTKEY_TYPE_HASH,
                msg.sender,
                GENERATION
            )
        )
      );

      return ECDSA.recover(digest, signature) == _signer;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = "data:application/json;base64,";
        string memory json = string(
            abi.encodePacked(
                '{"name": "Phoenix Burn Token #',
                Strings.toString(tokenId),
                '", "description": "222 Phoenixes to Burn and Revive", "image":"',
                imageURI,
                '", "attributes": [{"trait_type": "Generation", "value": ',
                Strings.toString(_ownershipOf(tokenId).extraData),
                '}, { "display_type": "date", "trait_type": "Rebirth", "value": ',
                Strings.toString(_ownershipOf(tokenId).startTimestamp),
                '}]}'
            )
        );
        string memory jsonBase64Encoded = Base64.encode(bytes(json));
        return string(abi.encodePacked(baseURI, jsonBase64Encoded));
    }

   

    function _afterTokenTransfers(
      address from,
      address to,
      uint256 startTokenId,
      uint256 quantity
    ) internal virtual override(ERC721A) {
      if(REBIRTH_CYCLE){
        if(IERC721A(STOICS).balanceOf(to) < 1) {
          revert InsufficientStoics();
        }
      }
      if(from == address(0)){
        for(uint i=startTokenId; i<quantity; i++){
          _setExtraDataAt(i, GENERATION);
        }
      }
    }

    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal pure override(ERC721A) returns (uint24) {
      return previousExtraData;
    }

    // Override to support royalties via ERC2981
    function supportsInterface(
    bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

}

// if you made it this far, you deserve a good fork.
// go mint one at forkhunger.art and feed someone real food