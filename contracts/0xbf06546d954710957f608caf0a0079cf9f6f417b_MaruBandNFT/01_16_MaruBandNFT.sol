// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#((#%#(//(@@@@@@@@@@@@@@@@@@@@@@@@@@@%/%,/*//%&/#&@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@%&(#%%#((((###(%(@@@@@@@@@@@@@@@@@@@@&%/(&#(,%#/#*###*(((@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@&&##(%#(#%%%%&&%#%%@&%%%(#%@@@@@@@@@#(((#/**/,/,(/((((/////%((@@@@@@@@@@@@@@@
// @@@@@@@@@@@@&##&#@#,...........,&&&&%%%&&&@@@@@@*((/#*&/,/,%,#(((//#((%**#//%@@@@@@@@@@@@@
// @@@@@@@@@@@@@&@,,,*/*,.......,(%%(*,.(@@&&@@@@@*((,%#(/&,*,%,#((//(%#@(#%#((/#@@@@@@@@@@@@
// @@@@@@@@@@@@&,#/,(&//#*#,..(.,/((#(//#.(@@@@@@/%(*%(&@&@@@#/(....##@@@&&##%,%,@@@@@@@@@@@@
// @@@@@@@@@@@,.%,( @@@* %*&,,@.#(/@@#(/*%(#@@@@@,/(*#/&#&@@*&&,#..,#%&@@&%%.%*#*@@@@@@@@@@@@
// @@@@@@@@@@@.../#*#/*(/(%*..#/#.*,,,,#*...,@@@@**/((.,.,,.,.,(.............(/#*&@@@@@@@@@@@
// @@@@@@@@@@@.......,.../*(%*&&............,@@@@(*(((.......,*(%*........../*/%,@@@@@@@@@@@@
// @@@@@@@@@@@..........*&@@@@@@%/[email protected]@@@@/(#((......................%*/@*@@@@@@@@@@@@
// @@@@@@@@@@@&.......(%,*#(*#%(*,,........*@@@@@&(%/#.....,@*,,//,*/#@*....%/%%*@@@@@@@@@@@@
// @@@@@@@@@@@@@*......./(,.....,#(......,@@@@@@@@*%/&,......&*,,,*(%,[email protected]/#/##@@@@@@@@@@@
// @@@@@@@@@@@@@@@@....................,@@@@@@@@@@*/((&@%,..............,@@@@@##/%@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@%//###@@@@@@@@@@@@@@@@@@@@@@@(@%#@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/%(@(@@@@@@@@@@@@@@@@@@@@@@%@%%@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@&@%%%%%(##%&@@@@@@@@@@@@@@@&#*&@@@@@@%(&/%/%%(#(&&&%@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@&(&%%%%##%%@%#%(&&@@@@@@@@@@@@@@@@%#&@@(((@/(#(%&(&(&(&%%@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@&@@@%##@#%&%%(@(##&(&(@%(&@@@@@@@@@@&%(%%/&%&#((@#/%&#(%#/%(&&&%%@@@@@@@@@@@@
// @@@@@@@@@@@@#@&%%&(&&%#&%%#%(%@##%#&%#&#@@@@@@@@#(%%###/@(@/%/%#%%&&/&&&&/&&#%%#@@@@@@@@@@
// @@@@@@@@@@%&@%%&####&%#&%#%#(@##&#%%@%#&&%@@@@@/&/%%#%#(/&@(&(%#@#&%&(&/#%/&&%(#%@@@@@@@@@
// @@@@@@@@@#&&&#&(#%@&@@@@@#&(%@%&&%&#%%&&&@&@@@&(&/%#%#&/@/@(#&(&&(&&#@/%%%(&&@(%%@@@@@@@@@
// @@@@@@@@#&&&@@@.& %@@# %,/...%*(@@#/(/#%@%(@@@@/@#(#%&%#&@&#%(/(,*,,%@@@@&@&@%(#&@@@@@@@@@
// @@@@@@@&%#%%&@#../#,((,,(*.....*,,,..*#&&&%&@@@@#&(##&(,@@&,%**/*,.*(%@@@%&%&@(%@@@@@@@@@@
// @@@@@@@%%&#%&&%.......,%(,...........*#%&@@%@@@@@&&@%.*,.#,,..#,,#.............(@@@@@@@@@@
// @@@@@@@%%&(@##@,...................../(%%@@(@@@@@.,*..........#.,#[email protected]@@@@@@@@@@
// @@@@@@@%%&(%(@%&.....*%/,%%*.*%%*...*%#&&@%%@@@@@,............(,*(............#@@@@@@@@@@@
// @@@@@@@%&&(#%(&%&*...*(......,&,...(#&#&##%%@@@@@@#.........,(#,#%##,........#@@@@@@@@@@@@
// @@@@@@@@@&%(%(##(&#@,...........*@@%%%(%@@@@@@@@@@@@.......//.,,...*%......%@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&.......&&@@@@@@@@@@@@@@@@@@@@@@@@%................%@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Maru by KLKTN STUDIO @
// Authors: @alliu930410 @fallanic
// Reviewer: @flockonus

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@klktn/allowlist.eth/contracts/MerkleProofAllowlisting.sol";
import "./SalesTimestamps.sol";

// custom errors
error ReachedMaxTotalSupply();
error ReachedMaxDevSupply();
error CannotMintMoreThanFourAtOnceDuringPublicSale();
error OnlyTwoMintsPerWalletDuringPresale();
error InsufficientEth(uint256 sent, uint256 required);

contract MaruBandNFT is
  Ownable,
  SalesTimestamps,
  ERC721A,
  MerkleProofAllowlisting
{
  constructor(string memory name, string memory symbol) ERC721A(name, symbol) {
  }

  // 💎💎💎
  string public constant PROVENANCE_HASH = "75ae07f26ee0fc62dff104050cbb93f4fcc46c69dd2e0df6cd17176e5b80d552";

  // metadata URI
  string private _baseTokenURI;
  // mint schedule:
  // 1: pre sale with 370 allowlist spots with a maximum 2 mints per wallet per transaction,
  //    which is equivalent to a capped 740 mint limit
  //
  // 2: dev mint reserves 103 tokens after pre sale concludes
  //
  // 3: public sale after dev mint concludes with a maximum of 4 mints per wallet per transaction
  //    until all 1203 tokens are minted
  uint256 public devMintedCount = 0;
  uint256 public constant PUBLIC_SALE_PRICE = 0.1 ether;
  uint256 public constant PRE_SALE_PRICE = 0.08 ether;
  uint256 private constant COLLECTION_SIZE = 1203;
  uint256 private constant MAX_DEV_MINT_LIMIT = 103;
  uint256 private constant PUBLIC_SALE_MAX_MINT_PER_TX = 4;

  event DevMint(
    address indexed minter,
    address indexed receiver,
    uint256 quantity,
    uint256 fromIndex
  );
  event PreSaleMint(
    address indexed minter,
    uint256 quantity,
    uint256 fromIndex
  );
  event PublicSaleMint(
    address indexed minter,
    uint256 quantity,
    uint256 fromIndex
  );
  event WithdrawETH(
    address indexed receiver,
    uint256 amount
  );

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function getBaseURI() external view returns (string memory) {
    return _baseTokenURI;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return _ownershipOf(tokenId);
  }

  // following minting functions inspired by Azuki contract
  // https://etherscan.io/address/0xed5af388653567af2f388e6224dc7c4b3241c544#code#F1#L75
  function publicSaleMint(uint256 quantity)
    external
    payable
    isInValidPublicSalePeriod
    isSufficientPayment(PUBLIC_SALE_PRICE * quantity)
  {
    if (quantity > PUBLIC_SALE_MAX_MINT_PER_TX)
      revert CannotMintMoreThanFourAtOnceDuringPublicSale();

    if (totalSupply() + quantity > COLLECTION_SIZE)
      revert ReachedMaxTotalSupply();

    uint256 indexBeforeMint = _currentIndex;

    _safeMint(msg.sender, quantity);
    refundIfOver(PUBLIC_SALE_PRICE * quantity);

    emit PublicSaleMint(msg.sender, quantity, indexBeforeMint);
  }

  function preSaleMint(uint256 quantity, bytes32[] calldata _merkleProof)
    external
    payable
    isInValidPreSalePeriod
    requiresMerkleProofAllowlist(_merkleProof)
    isSufficientPayment(PRE_SALE_PRICE * quantity)
  {
    if (totalSupply() + quantity > COLLECTION_SIZE)
      revert ReachedMaxTotalSupply();

    if (numberMinted(msg.sender) + quantity > 2)
      revert OnlyTwoMintsPerWalletDuringPresale();

    uint256 indexBeforeMint = _currentIndex;

    _safeMint(msg.sender, quantity);
    refundIfOver(PRE_SALE_PRICE * quantity);

    emit PreSaleMint(msg.sender, quantity, indexBeforeMint);
  }

  // used for pre-mint reserve
  function devMint(uint256 quantity) external onlyOwner {
    _devMint(quantity, msg.sender);
  }

  function devMint(uint256 quantity, address receiver) external onlyOwner {
    _devMint(quantity, receiver);
  }

  function _devMint(uint256 quantity, address receiver) internal {
    if (devMintedCount + quantity > MAX_DEV_MINT_LIMIT)
      revert ReachedMaxDevSupply();

    if (totalSupply() + quantity > COLLECTION_SIZE)
      revert ReachedMaxTotalSupply();

    uint256 indexBeforeMint = _currentIndex;

    _safeMint(receiver, quantity);

    devMintedCount += quantity;

    emit DevMint(msg.sender, receiver, quantity, indexBeforeMint);
  }

  function burn(uint256 tokenId) external {
    _burn(tokenId, true);
  }

  function refundIfOver(uint256 price) private {
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function withdrawETH() external onlyOwner {
    emit WithdrawETH(msg.sender, address(this).balance);
    payable(msg.sender).transfer(address(this).balance);
  }

  modifier isSufficientPayment(uint256 required) {
    if (msg.value < required) revert InsufficientEth(msg.value, required);
    _;
  }
}