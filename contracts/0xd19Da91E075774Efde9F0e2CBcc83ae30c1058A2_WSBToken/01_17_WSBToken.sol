// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./WSBSwappable.sol";

//                .::-++**#:...:=+#%--===-:...+%#:..::
//              :--       .+=::::-+#%*+--=+=-+*--:    +=.
//           .::.:    .:+%@**+:.     =%@%%%@#. :..  .++.++..
//        ..:.   :  ....=#=.         :%@@@@#+*.   [email protected]@@. :*=..
//       *-:*+==:#*++:..:-::::::::-=++++****%@#####**+=###--=-*.
//        .... .-+-.      +#*++=-:[email protected]@@@@@@@%%@@@%+-+%@#..==..
//          ..::  .:..  .-*+:-=*@@@: %+.  .-%%@@#-:[email protected]@@-:=-.
//             .-:  :.:=*#: :   :@#  -     =%@*:.=%@@+:-:.
//               .=: :=+=*:  .   %-  -:   .#*:.:::-:::.
//                 .--.-= :-  .  %+#@@*   +:.:.  ..:.
//                    --=*. ....-+:.:@@. -:.   .-:.
//                      :+%* ::-+    %@*=:    :-
//                       +:=*.. =.    **    ..
//                       +...   *.    *  ::.
//                       #-.   +-.:-:*==- -
//                      -%-   +:  .+%%#*: =
//                      %:    *     -*#+:.::
//                     -.    =-     :+=    =:
//                    -+:   :@@      +-     =:
//                    -#. -:=%@=      =.     =-
//                    -%-=.  :+*+.    =.     .+
//                    :@#:    .-+*=:+%#       .+:
//                    :@+   .:.: :-*#@#         **.
//                    =%*  -:  -=:.::=++:.       =%-
//                    [email protected]#--     .-==-. :--=       =%
//                    [email protected]%=    .=. ..:-=::=%=.     :@.
//                    [email protected]=.  [email protected]#++.  ..-%:..:.   [email protected]=
//                    -*=.    :.   --::.:.   .:-.:*+*
//                    @#+=-: .                :++%%+.*
//                    -#%#*=:                 :*#%@=.:-
//                       -+#%#+-:.           .*#%@%+  +
//                          .-+%@%#*+=----=+#%%%@@%= .::
//                               :=*%@@@@%%@@@@@@%#+:-.+
//                                    :=%@@@@@@@%%%*--:#
//                                       #@@@@@@%%%#=:++.
//                                       [email protected]@@@@@%%%#+-*--
//                                       :@@@@@%%%%%#**.*
//
//       Run It Wild + PrimeFlare

contract WSBToken is IERC721Receiver, ReentrancyGuard, Ownable, WSBSwappable {

  using SafeMath for uint256;

  uint16 public constant MAX_RAFFLE = 1194;
  uint16 public constant MAX_TOKEN = 7375;
  uint16 public constant MAX_DEV_CLAIMA = 7475;
  uint16 public constant MAX_DEV_CLAIMB = 7500;
  uint16 public constant MAX_PER_CLAIM = 10;
  uint256 public constant BUY_PRICE = 0.1 ether;

  uint16 private publicTokens = 1194;
  string public baseURI = "ipfs://bafybeihecf5alieuoojmghsvtdymxul6jbj6eeagnaewij4cjkjetcka4m/";

  PresaleContract public presaleContract;
  bool public active = false;
  bool public raffleDrawn = false;
  address public svgLink;

  uint256 private raffleSeed;

  address payable private ownerA = payable(0xB240D3aAD9093a08B62ce96343d8A47e22266AdD);
  address payable private ownerB = payable(0x75dF311CE8E000CaDD8E4382B42483530bCC6355);
  address payable private ownerC = payable(0x724696c017902944ADD5916eA36776435c64B306);

  constructor() ERC721("WSB Diamond Hands", "WSB") {}

  receive() external payable onlyOwner {}

  function drawRaffle() external onlyOwner {
    require(tx.origin == msg.sender, "Draw: Can not be called using a contract.");
    require(!raffleDrawn, "Draw: Can only draw raffle once");

    // pseudo random to generate seed, offset max presale to prevent overflow
    raffleSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, msg.sender, MAX_RAFFLE, address(this)))).sub(MAX_RAFFLE);

    // ensuring draw can only happen once
    raffleDrawn = true;
  }

  function claimRaffle(uint8 amount) external nonReentrant {
    require(active, "ClaimRaffle: We are not yet open.");
    require(tx.origin == msg.sender, "ClaimRaffle: Can not be called using a contract.");
    require(raffleDrawn, "ClaimRaffle: Raffle has not been drawn.");
    uint8 balance = uint8(presaleContract.balanceOf(msg.sender));
    require(balance > 0, "ClaimRaffle: Need pre-mint to claim.");
    amount = amount < balance ? amount : balance;

    while (amount > 0) {
      uint16 presaleTokenId = uint16(presaleContract.tokenOfOwnerByIndex(msg.sender, 0));
      uint16 raffleTokenIndex = getRaffleEntry(presaleTokenId);
      _safeMint(msg.sender, raffleTokenIndex);
      presaleContract.burnRedeem(presaleTokenId);
      amount -= 1;
    }
  }

  function claim(uint256 amount) external payable nonReentrant {
    require(active, "ClaimToken: We are not yet open.");
    require(tx.origin == msg.sender, "ClaimToken: Can not be called using a contract.");
    require(msg.value >= BUY_PRICE.mul(amount), "ClaimToken: Not enough ETH to claim.");
    require(amount > 0, "ClaimToken: Need to claim at least 1.");
    require(amount <= MAX_PER_CLAIM, "ClaimToken: You can claim at most 10.");
    require((publicTokens + amount) < MAX_TOKEN, "ClaimToken: All tokens are claimed.");

    for(uint16 i = 0; i < amount; i++){
      _safeMint(msg.sender, publicTokens);
      publicTokens = publicTokens + 1;
    }
  }

  function claimDevTokensA() external onlyOwner {
    for(uint16 i = MAX_TOKEN; i < MAX_DEV_CLAIMA; i++){
      _safeMint(ownerA, i);
    }
  }

  function claimDevTokensB() external onlyOwner {
    for(uint16 i = MAX_DEV_CLAIMA; i < MAX_DEV_CLAIMB; i++){
      _safeMint(ownerB, i);
    }
  }

  function anyRaffle() external view returns(bool) {
    return uint256(presaleContract.balanceOf(msg.sender)) > 0;
  }

  function toggleActive() external onlyOwner  {
    active = !active;
  }

  function setPresaleContract(address contractAddress) external onlyOwner {
    presaleContract = PresaleContract(contractAddress);
  }

  function setSvgLink(address contractAddress) external onlyOwner {
    svgLink = contractAddress;
  }

  function withdraw() public onlyOwner {
    uint balanceA = address(this).balance.mul(550).div(1000);
    uint balanceB = address(this).balance.mul(350).div(1000);
    uint balanceC = address(this).balance.sub(balanceA).sub(balanceB);

    ownerA.transfer(balanceA);
    ownerB.transfer(balanceB);
    ownerC.transfer(balanceC);
  }

  function withdrawOperational() public onlyOwner {
    require(!active, "Can not withdraw");
    uint balance = address(this).balance;
    address payable owner = payable(msg.sender);
    owner.transfer(balance);
  }

  function onERC721Received(address, address, uint256, bytes memory) public pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function getRaffleEntry(uint16 presaleTokenId) private view returns (uint16) {
    return uint16(raffleSeed.add(uint256(presaleContract.getTokenValue(presaleTokenId))) % MAX_RAFFLE);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
  }

  function setTokenURI(string memory uri) external onlyOwner {
    baseURI = uri;
  }
}

interface PresaleContract {
  function burnRedeem(uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function tokenOfOwnerByIndex(address account, uint256 index) external view returns (uint256);
  function getTokenValue(uint16 tokenId) external pure returns (uint16);
}