// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//              (%.                                   /%.
//            ,@(  &@@@                          /@@@,  @@
//            @@  %%*  &@@%                   @@@.  %%% @@    *@@@@@@@@@@
//            #@  %%%%%    @@@@&%%%%%%%%%@@@@/    %%%%, @@   @@@  @@  @@ @@
//             @@  %%.       %%%%%%%%%%%%%%%       #%*  @@  %@  @@@@@@@@@@@@
//             @@            %%%%,%%%% %%%%,           *@/   @@           @@
//            @@                                        *@@  @@          @@
//          /@@                                           @@ &@        (@/
//         ,@%          @@@@@@,          *@@@@@/           @@@@        @@
//         @@         ,@&     @&        @@     @@.         /@@         @@
//         @@          ,                                    @@         @@
//         @@                                               @@         @@
//         @@                     @@@@&                    *@/         @@
//         /@/                    @@@@                     @@         @@
//          %@#            @@.  #@@  *@@   @@&            @@          @@
//            @@              .,         ,              @@%          @@
//              @@@.                                 &@@@#          @@
//             @@%%&@@@&                        *@@@@%%%@@        %@@
//            %@%%%%%%%%%@@@@@@@@@@@@&@@@@@@@@@&%%%%%%%%%@@     %@@
//            @@%%%%%%%%%%%%%%%%@@,,@@&,#@@%%%%%%%%%%%%%%@@  %@@%
//             @@@%%%%%%%%%%%%%@@@,,,@@,,@@%%%%%%%%%%%@@@@@@&
//                 &@@@@@@@@@@&&@@@,@@.,@@@@@@@@@@@@&.
//                               [email protected]@@@@@*
//
//          DRP + PrimeFlare 2021
//          Drop 1 - LushSux.io!

contract DRPToken is ERC721Enumerable, Ownable {

  using Strings for uint256;
  uint256 public constant BUY_PRICE = 0.1 ether;
  uint16 public constant MAX_SUPPLY_DEV = 4344;
  uint16 public constant MAX_SUPPLY = 4444;
  uint8 public constant MAX_PER_ACCOUNT = 5;

  WhitelistContract public WHITELIST_CONTRACT_A;
  uint16 public constant WHITELIST_CONTRACT_TOKEN_A = 888;
  uint16 public constant WHITELIST_MAX_SUPPLY_A = 2000;
  uint16 public whitelistClaimedA = 0;

  WhitelistContract public WHITELIST_CONTRACT_B;
  uint16 public constant WHITELIST_CONTRACT_TOKEN_B1 = 1;
  uint16 public constant WHITELIST_CONTRACT_TOKEN_B2 = 2;
  uint16 public constant WHITELIST_CONTRACT_TOKEN_B3 = 10003;
  uint16 public constant WHITELIST_CONTRACT_TOKEN_B4 = 10004;
  uint16 public constant WHITELIST_MAX_SUPPLY_B = 1500;
  uint16 public whitelistClaimedB = 0;

  uint16 public tokenId = 0;

  bool public whitelistClaimActive = false;
  bool public salesActive = false;
  bool public revealed = false;
  string public baseURI;

  uint8 public constant MULTIPLER = 8;

  uint8 public constant OUT = 0;
  uint8 public constant INNER = 1;
  uint8 public constant RANDOM = 2;
  uint8 public constant NORMAL = 3;

  mapping (address => uint8) private _whitelist;

  constructor() ERC721('DRPToken', 'DRP') {
    WHITELIST_CONTRACT_A = WhitelistContract(0x36d30B3b85255473D27dd0F7fD8F35e36a9d6F06);
    WHITELIST_CONTRACT_B = WhitelistContract(0x10DaA9f4c0F985430fdE4959adB2c791ef2CCF83);
  }

  function toggleActive() external onlyOwner {
    salesActive = !salesActive;
  }

  function toggleReveal() external onlyOwner {
    revealed = !revealed;
  }

  function toggleWhitelistClaim() external onlyOwner {
    whitelistClaimActive = !whitelistClaimActive;
  }

  function setWhitelist(address[] calldata addresses, uint8 code) external onlyOwner {
    require((code == INNER || code == RANDOM || code == NORMAL || code == OUT), "Set: code value incorrect.");
    for (uint16 i = 0; i < addresses.length; i++){
      _whitelist[addresses[i]] = code;
    }
  }

  function removeFromWhitelist(address wallet) external onlyOwner {
    _whitelist[wallet] = OUT;
  }

  function eligiblePresale() public view returns (uint16) {
    if (
      WHITELIST_CONTRACT_B.balanceOf(msg.sender, WHITELIST_CONTRACT_TOKEN_B1) > 0 ||
      WHITELIST_CONTRACT_B.balanceOf(msg.sender, WHITELIST_CONTRACT_TOKEN_B2) > 0 ||
      WHITELIST_CONTRACT_B.balanceOf(msg.sender, WHITELIST_CONTRACT_TOKEN_B3) > 0 ||
      WHITELIST_CONTRACT_B.balanceOf(msg.sender, WHITELIST_CONTRACT_TOKEN_B4) > 0 ||
      _whitelist[msg.sender] == NORMAL
    ) {
      return MAX_PER_ACCOUNT;
    }
    if (_whitelist[msg.sender] == RANDOM || _whitelist[msg.sender] == INNER) {
      uint16 eligibleA = uint16(WHITELIST_CONTRACT_A.balanceOf(msg.sender, WHITELIST_CONTRACT_TOKEN_A)) / MULTIPLER;
      return _whitelist[msg.sender] == RANDOM ? (eligibleA + 1) : eligibleA;
    }
    return 0;
  }

  function whitelistClaim(uint16 amount) external payable {
    require(whitelistClaimActive, "Claim is not active.");
    require(tx.origin == msg.sender, "Claim cannot be made from a contract");
    require((tokenId + amount) < MAX_SUPPLY_DEV, "Claim: Cannot exceed total supply.");
    require(msg.value >= (amount * BUY_PRICE), "Claim: Ether value incorrect.");

    if (_whitelist[msg.sender] == INNER || _whitelist[msg.sender] == RANDOM) {
      require(whitelistClaimedA < WHITELIST_MAX_SUPPLY_A, "Claim: Maximum presale sold.");
      uint16 eligible = eligiblePresale();
      require((balanceOf(msg.sender) + amount) <= eligible, "Claim: Can not claim that many.");
      amount = amount < eligible ? amount : eligible;

      for (uint16 i = 0; i < amount; i++){
        _safeMint(msg.sender, tokenId);
        whitelistClaimedA = whitelistClaimedA + 1;
        tokenId = tokenId + 1;
      }
    }
    else if (
      WHITELIST_CONTRACT_B.balanceOf(msg.sender, WHITELIST_CONTRACT_TOKEN_B4) > 0 ||
      WHITELIST_CONTRACT_B.balanceOf(msg.sender, WHITELIST_CONTRACT_TOKEN_B3) > 0 ||
      WHITELIST_CONTRACT_B.balanceOf(msg.sender, WHITELIST_CONTRACT_TOKEN_B2) > 0 ||
      WHITELIST_CONTRACT_B.balanceOf(msg.sender, WHITELIST_CONTRACT_TOKEN_B1) > 0
    ) {
      require((balanceOf(msg.sender) + amount) <= MAX_PER_ACCOUNT, "Claim: Can not claim that many.");
      require(whitelistClaimedB < WHITELIST_MAX_SUPPLY_B, "Claim: Maximum presale sold.");

      for (uint16 i = 0; i < amount; i++){
        _safeMint(msg.sender, tokenId);
        whitelistClaimedB = whitelistClaimedB + 1;
        tokenId = tokenId + 1;
      }
    }
    else {
      require(_whitelist[msg.sender] == NORMAL, "Claim: not on the white list.");
      require((balanceOf(msg.sender) + amount) <= MAX_PER_ACCOUNT, "Claim: Can not claim that many.");
      for (uint16 i = 0; i < amount; i++){
        _safeMint(msg.sender, tokenId);
        tokenId = tokenId + 1;
      }
    }
  }

  function claim(uint8 amount) external payable {
    require(salesActive, "Claim is not active");
    require(tx.origin == msg.sender, "Claim cannot be made from a contract");
    require((tokenId + amount) < MAX_SUPPLY_DEV, "Claim: Cannot exceed total supply.");
    require(msg.value >= (amount * BUY_PRICE), "Claim: Ether value incorrect.");
    require((balanceOf(msg.sender) + amount) <= MAX_PER_ACCOUNT, "Claim: Can not claim that many.");

    for(uint8 i = 0; i < amount; i++){
      _safeMint(msg.sender, tokenId);
      tokenId = tokenId + 1;
    }
  }

  function devClaim() external onlyOwner {
    for(uint16 i = MAX_SUPPLY_DEV; i < MAX_SUPPLY; i++){
      _safeMint(0x59d4dDd34c08904d0571bb6F70AeBB2Aa55e4948, i);
    }
  }

  function tokenURI(uint256 tokenIdx) public view virtual override returns (string memory){
    require(_exists(tokenIdx), "URI query for non existent token");
    if (!revealed) {
      return "ipfs://QmUV7ufASwkbbCuS6dq7TwdhWCaKp4YCggGt46wBfxurYm";
    }
    return string(abi.encodePacked(baseURI, Strings.toString(tokenIdx)));
  }

  function setTokenURI(string memory uri) external onlyOwner {
    baseURI = uri;
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    require(balance > 0, "Contract balance is 0");
    payable(msg.sender).transfer(balance);
  }
}

interface WhitelistContract {
  function balanceOf(address account, uint256 id) external view returns (uint256);
}