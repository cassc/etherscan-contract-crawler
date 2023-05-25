// SPDX-License-Identifier: MIT

// starting a new era but probably nothing...
//
//
//                 ..        .           .    ..
//  @@@@&        &@@@@@@@@@@@@@@@(        @@@@@.
//  @@@@&   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@.   @@@@@.
//  @@@@& @@@@@@@@               @@@@@@@@ @@@@@.
//  @@@@@@@@@@..                    ,@@@@@@@@@@.
//  @@@@@@@@                          [email protected]@@@@@@@.
//  @@@@@@.                             %@@@@@@.
//  @@@@@.                               %@@@@@.
//  @@@@@                                 @@@@@.
// [email protected]@@@&                                 @@@@@
//  @@@@@                                 @@@@@.
//  /@@@@,                              .&@@@@..
//   @@@@@/                             @@@@@(
//    %@@@@@..                        [email protected]@@@@.
//     [email protected]@@@@@,.                    #@@@@@@
//       [email protected]@@@@@@@...         . ,@@@@@@@@
//         . @@@@@@@@@@@@@@@@@@@@@@@@&
//               [email protected]@@@@@@@@@@@@@@..
//
//
// @creator:     ConiunIO
// @security:    [email protected]
// @author:      Batuhan KATIRCI (@batuhan_katirci)
// @website:     https://coniun.io/

pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ConiunPass is ERC721A, Ownable {
  using ECDSA for bytes32;
  using Strings for uint256;

  // token and mint related variables
  uint256 public MAX_SUPPLY = 6555;
  uint256 public constant TEAM_RESERVED_SUPPLY = 150;
  uint256 public constant INVESTOR_RESERVED_SUPPLY = 100;

  uint256 public constant WL_MINT_PRICE = 0.2 ether;
  uint256 public constant MINT_PER_WALLET = 2;

  uint256 public constant PUBLIC_MINT_PRICE = 0.3 ether;

  uint256 public teamMintCount = 0;
  uint256 public investorMintCount = 0;
  int256 public mintStage = 0; // 0 - not started | 1 - wl mint | 2 - public mint

  string public tokenBaseUrl =
    "https://temp-cdn.coniun.io/coniun-pass-metadata/";
  string public tokenUrlSuffix = ".json";

  // whitelist sign address
  address private _signerAddress;

  address COMPANY_WALLET = 0x92B1DF9E40723AB7c9Ba7D9585204f514b1E1598;

  constructor(address signerAddress_) ERC721A("ConiunPass", "CPASS") {
    _signerAddress = signerAddress_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return tokenBaseUrl;
  }

  function _suffix() internal view virtual returns (string memory) {
    return tokenUrlSuffix;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    string memory suffix = _suffix();
    return
      bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), suffix))
        : "";
  }

  function wlMint(uint256 numTokens, bytes calldata signature)
    external
    payable
    onlyOrigin
    mintCompliance(numTokens)
  {
    // check mint stage
    require(mintStage == 1, "Whitelist mint not started");
    // check wl signature
    require(
      _signerAddress ==
        keccak256(
          abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            bytes32(uint256(uint160(msg.sender)))
          )
        ).recover(signature),
      "Signer address mismatch."
    );

    // check amount payed
    require(
      msg.value == (numTokens == 2 ? PUBLIC_MINT_PRICE : WL_MINT_PRICE),
      "Value supplied is incorrect"
    );

    // _safeMint's second argument now takes in a numTokens, not a tokenId (ERC721A).
    _safeMint(msg.sender, numTokens);
  }

  function mint(uint256 numTokens)
    external
    payable
    onlyOrigin
    mintCompliance(numTokens)
  {
    // check mint stage
    require(mintStage == 2, "Public mint not started");
    require(
      msg.value == numTokens * PUBLIC_MINT_PRICE,
      "Value supplied is incorrect"
    );

    // _safeMint's second argument now takes in a numTokens, not a tokenId (ERC721A).
    _safeMint(msg.sender, numTokens);
  }

  // - management only functions

  // this function is able to CHANGE MAX_SUPPLY
  // but it can only reduce it
  // so it's fud free :P hi guys!
  function reduceSupply(uint256 burnAmount) external onlyOwner {
    uint256 requiredMaxSupply = totalSupply() +
      (TEAM_RESERVED_SUPPLY - teamMintCount) +
      (INVESTOR_RESERVED_SUPPLY - investorMintCount);

    if (burnAmount == 0) {
      burnAmount = MAX_SUPPLY - requiredMaxSupply;
    }

    require(
      totalSupply() < MAX_SUPPLY - burnAmount + 1,
      "aint_own_it_cant_burn_it"
    );

    require(
      MAX_SUPPLY - burnAmount >= requiredMaxSupply,
      "cant_burn_team_and_investor_supply"
    );
    MAX_SUPPLY -= burnAmount;
  }

  function teamMint(address receiver, uint256 numTokens) external onlyOwner {
    require(
      teamMintCount + numTokens < TEAM_RESERVED_SUPPLY + 1,
      "supply_exceeded"
    );
    require(totalSupply() + numTokens < MAX_SUPPLY + 1, "over_capacity");
    // ;)
    teamMintCount += numTokens;
    _safeMint(receiver, numTokens);
  }

  function investorMint(address receiver, uint256 numTokens)
    external
    onlyOwner
  {
    require(
      investorMintCount + numTokens < INVESTOR_RESERVED_SUPPLY + 1,
      "supply_exceeded"
    );
    require(totalSupply() + numTokens < MAX_SUPPLY + 1, "over_capacity");
    // ;)
    investorMintCount += numTokens;
    _safeMint(receiver, numTokens);
  }

  function setMintStage(int256 _mintStage) external onlyOwner {
    require(_mintStage < 3, "Unsupported mint stage");
    mintStage = _mintStage;
  }

  function setTokenBaseUrl(string memory _tokenBaseUrl) public onlyOwner {
    tokenBaseUrl = _tokenBaseUrl;
  }

  function setTokenSuffix(string memory _tokenUrlSuffix) public onlyOwner {
    tokenUrlSuffix = _tokenUrlSuffix;
  }

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);

    _withdraw(COMPANY_WALLET, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }

  // - modifiers

  modifier onlyOrigin() {
    // disallow access from contracts
    require(msg.sender == tx.origin, "Come on!!!");
    _;
  }

  modifier mintCompliance(uint256 _numTokens) {
    require(_numTokens > 0, "You must mint at least one token.");
    require(
      totalSupply() + _numTokens <
        MAX_SUPPLY - (TEAM_RESERVED_SUPPLY + INVESTOR_RESERVED_SUPPLY + 1),
      "Max supply exceeded!"
    );
    require(
      _numberMinted(msg.sender) + _numTokens < MINT_PER_WALLET + 1,
      "You are exceeding your minting limit"
    );
    _;
  }
}