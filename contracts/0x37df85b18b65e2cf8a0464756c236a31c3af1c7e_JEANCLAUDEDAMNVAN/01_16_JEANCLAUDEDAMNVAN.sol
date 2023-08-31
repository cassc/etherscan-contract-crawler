// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/// @title: JEAN CLAUDE DAMN VAN
/// @author: white lights & sidewaysDAO

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "./ITokenURISupplier.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                ,,                                //
//                                              ╓φ░░░░φ                             //
//                                          ╓φ▒░░░░░░░╠▒                            //
//                                  ,,╓╔φ▒▒░░░░░░░░░▒╠╣▒                            //
//                          ,╓φφ▒▒░░░░░░░░░░░░░░▒▒╠╬╬╩                              //
//                      ╓φ╠░░░░░░░░░░░░░▒▒▒▒▒▒╠╠╬╬╣╩                                //
//                    φ╠╩░░░░░░░░░░▒▒▒▒▒╠╠╠╬╬╣╝╩╙`                                  //
//                  ;╠╩░░░░░░░░░░░░╚╚╚╚╚╚╚╚╚╚╚░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒φ╓    //
//                  ╔╠▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╠▒  //
//    ,╬╠▒▒▒φφσ╓,╓╬╠▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒╠╬   //
//    ╔╠▒╚╚╠╠╠╠╠╠╠╩▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╠╠╠╬╩   //
//  φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒╠╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╚╙╙╙╙╙╙╙└       //
//  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╠╠ε                               //
//  «░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒╠                              //
//  φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒╠╩                              //
//  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒╠`                               //
//  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╠ε                               //
//  ╚░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒╠░                               //
//  ]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░▒╠╩                                //
//  ╠▒▒╠╠╠╠╠╠╠╠╠╠╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╬╙                                  //
//  `╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╬▒                                   //
//    ╚╬╬╬╬╬╬╬╬╬╬╬╬╣╣╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠╠╠╠╠╠╠╬╬╬╬                                    //
//      `╚╣╣╣╝╩╩╙╙└`  ╙╚╝╣╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╩                                    //
//                          ╙╙╙╙╩╩╩╩╩╩╩╩╙╙╙                                         //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////
// An ERC1155 Gumball Machine

contract JEANCLAUDEDAMNVAN is AdminControl, ERC1155, ReentrancyGuard {
  uint256 public salePrice = 40000000000000000;
  bool public activated;
  bool private transferSemaphore;
  uint256 public gumballsLeft = 0;
  ITokenURISupplier public tokenURIContract;

  address[] public artists;
  uint256[] private availableTokenIds;
  uint256 private availableTokenIdsLength;
  mapping(uint256 => uint256) private tokenIdToEditionCount;

  AggregatorV3Interface ethUsdPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

  error NotActivated();
  error Paused();
  error SoldOut();
  error WrongSalesPrice();
  error MachineIsLocked();

  constructor() ERC1155("") {}

  function withdraw() external adminRequired {
    payable(msg.sender).transfer(address(this).balance);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AdminControl, ERC1155)
    returns (bool)
  {
    return
      AdminControl.supportsInterface(interfaceId) ||
      ERC1155.supportsInterface(interfaceId) ||
      super.supportsInterface(interfaceId);
  }

  function name() public view virtual returns (string memory) {
    return "JEAN CLAUDE DAMN VAN";
  }

  function symbol() public view virtual returns (string memory) {
    return "JCDV";
  }

  /**
   * @dev See {IERC1155-isApprovedForAll}.
   *
   * This implementation allows only the owner to transfer tokens.
   * If that check fails, we let them through when transferSemaphore is set.
   * The transferSemaphore is only ever set for one line during buyGumball().
   */
  function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
    return super.isApprovedForAll(account, operator) || transferSemaphore;
  }

  function setActivate(bool val) external adminRequired {
    activated = val;
  }

  function setPrice(uint256 val) external adminRequired {
    salePrice = val;
  }

  /**
   * Sets up the initial set of artist wallet that can autograph the contract
   *
   * @param _artistWallets the addresses of the artists that will be able to autograph the contract
   */
  function setArtists(address[] memory _artistWallets) external adminRequired {
    if (activated || gumballsLeft > 0)
      revert MachineIsLocked();

    artists = _artistWallets;
  }

  /**
   * Allows the uri() this contract returns to be controlled by another contract.
   *
   * @param addy the address of the contract that implements the tokenURI function
   */
  function setTokenURIContract(address addy) external adminRequired {
    tokenURIContract = ITokenURISupplier(addy);
  }

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   *
   * This implementation makes a proxy call to another contract for the uri.
   */
  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    return tokenURIContract.tokenURI(tokenId);
  }

  /**
   * @notice
   *
   * By signing this contract, the artist authorizes the creation and sale of a
   * limited-edition artwork for this exhibition.
   *
   * The contract maintains a list of eligible artists who can participate
   * in the exhibition by signing the contract. If you're not on the list,
   * you cannot sign the contract, and you cannot be in the exhibition.
   *
   * If you're on the list, your artwork will only be a part of the exhibition
   * after you sign. You can sign the contract at any time before the exhibition
   * starts, but once the exhibition starts, you are locked out.
   *
   * When minted, the art is first sent to the artist's wallet, followed
   * by the buyer's wallet. This ensures on-chain evidence of the artist's
   * "signature" on the artwork, giving the buyer confidence in the token's
   * authenticity as part of that artist's provenance.
   *
   * "I am the artist of token X and approve 11 editions to be created and sold"
   */
  function sign() public {
    if (activated)
      revert MachineIsLocked();

    bool found = false;
    uint256 foundId = 0;
    for(;foundId < artists.length;) {
      if (artists[foundId] == _msgSender()) {
        found = true;
        foundId = foundId;
        break;
      }

      unchecked {
        foundId++;
      }
    }

    if (!found)
      revert MachineIsLocked();

    if (tokenIdToEditionCount[foundId] > 0)
      revert MachineIsLocked();

    // tracks the total supply of all tokens
    unchecked {
      gumballsLeft += 11;
    }
    // tracks the token ids that are approved for minting
    availableTokenIds.push(foundId);
    // tracks the "end" of the array that we can select from (see swap algo)
    availableTokenIdsLength = availableTokenIds.length;
    // tracks the supply left of that token id
    tokenIdToEditionCount[foundId] = 11;
  }

  /**
   * @dev Used for publicly minting artworks.
   * @param numberOfTokens the number of tokens to buy
   */
  function buyGumball(uint256 numberOfTokens) public payable {
    if (!activated)
      revert NotActivated();

    uint256 _gumballsLeft = gumballsLeft;
    uint256 _availableTokenIdsLength = availableTokenIdsLength;

    if ((_gumballsLeft == 0) || _gumballsLeft < numberOfTokens)
      revert SoldOut();

    bool isDiscounted = numberOfTokens % 3 == 0;
    uint256 expectedPayment = numberOfTokens * salePrice * (isDiscounted ? 5 : 6) / 6;

    if (msg.value != expectedPayment)
      revert WrongSalesPrice();

    (,int256 price,,,) = ethUsdPriceFeed.latestRoundData();

    for(uint i; i < numberOfTokens;) {
      uint256 rngIndex = getRandomNumberDuringWriteTx(_availableTokenIdsLength, price);
      uint256 tokenId;

      uint tries = 0;

      do {
        if (tries > _availableTokenIdsLength) {
          break;
        }

        rngIndex = getRandomNumberDuringWriteTx(_availableTokenIdsLength, price);
        tokenId = availableTokenIds[rngIndex];
        tries++;
      } while (tokenIdToEditionCount[tokenId] == 0);

      address artistWallet = artists[tokenId];

      unchecked {
        tokenIdToEditionCount[tokenId]--;
        _gumballsLeft--;
      }

      if (tokenIdToEditionCount[tokenId] == 0) {
        availableTokenIds[rngIndex] = availableTokenIds[_availableTokenIdsLength - 1];
        unchecked {
          _availableTokenIdsLength--;
        }
      }

      _mint(artistWallet, tokenId, 1, "");
      transferSemaphore = true;
      safeTransferFrom(artistWallet, msg.sender, tokenId, 1, "");
      transferSemaphore = false;

      unchecked {
        i++;
      }
    }

    gumballsLeft = _gumballsLeft;
    availableTokenIdsLength = _availableTokenIdsLength;
  }


  uint256 private nonce = 9356734589;
  /**
   * @dev gives a random digit from 0 (exclusive) to _range (inclusive)
   * @param _range the range of the random number
   * @param price  the price of eth in usd as a PRNG seed
   */
  function getRandomNumberDuringWriteTx(uint256 _range, int256 price) private returns (uint256) {
    uint256 random = uint256(keccak256(abi.encodePacked(
      msg.sender,
      // pack all 256 bit variables together
      block.timestamp,
      tx.gasprice,
      price,
      nonce
    )));

    unchecked {
      nonce += 1;
    }

    return random % _range;
  }
}