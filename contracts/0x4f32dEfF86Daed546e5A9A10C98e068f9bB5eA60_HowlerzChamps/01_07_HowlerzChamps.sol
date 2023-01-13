// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IHowlerz {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IPrey {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

contract HowlerzChamps is ERC721, Ownable {
  constructor() ERC721("Howlerz Champions", "CHAMPS") {}

  address howlerzAddress = 0x40Cf6a63C35B6886421988871F6b74cC86309940;

  address preyAddress = 0x057847A1c11A34d1A92Fb61e87D38707A9eE34C7;

  string private uri = "ipfs://QmY6KU7h1fNueSffSK3V99xtVK4FnkxjNkHYcM6NnZ73wZ/";
  mapping(uint => bool) public inArena;

  bool public frozen = false;
  address public constant signerAddress = 0x7d1c1c1Fb80897fa9e08703faedBF8A6A25582f8;

  mapping(uint => uint[]) public rounds1;
  mapping(uint => uint[]) public rounds2;
  mapping(uint => uint[]) public rounds3;
  mapping(uint => uint[]) public rounds4;

  mapping(uint => uint) playInChamps;
  uint[] public registeredChamps;
  uint[] public finalFour;
  uint[] public finals;
  uint[] public winner;

  
  using Strings for uint256;
  using ECDSA for bytes32;


  function mint(uint howlerid, uint preyid, uint championid, bytes memory signature) public {
    bytes32 inputHash = keccak256(
      abi.encodePacked(
        msg.sender,
        howlerid,
        preyid,
        championid
      )
    );


    bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
    address recoveredAddress = ethSignedMessageHash.recover(signature);
    require(recoveredAddress == signerAddress, 'Bad signature');

    IHowlerz(howlerzAddress).transferFrom(msg.sender, address(this), howlerid);
    IPrey(preyAddress).transferFrom(msg.sender, address(this), preyid);
    _mint(msg.sender, championid);
  }

  function feedHowler(uint howlerid, uint howlerid2, uint championid, bytes memory signature) public {
    bytes32 inputHash = keccak256(
      abi.encodePacked(
        msg.sender,
        howlerid,
        howlerid2,
        championid
      )
    );


    bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
    address recoveredAddress = ethSignedMessageHash.recover(signature);
    require(recoveredAddress == signerAddress, 'Bad signature');

    IHowlerz(howlerzAddress).transferFrom(msg.sender, address(this), howlerid);
    IHowlerz(howlerzAddress).transferFrom(msg.sender, address(this), howlerid2);
    _mint(msg.sender, championid);
  }

  /** TOURNAMENT FUNCTIONS 
  --------------------------
  The tournament bracket is structured like march madness, with 4 sub brackets to allow for 
  round execution in smaller chunks.
  The tournament works as follows:

    Say there are 1400 Champs participatings. The closest clean bracket is with 1024 Champs, so we need to 
    elimate the rest. This will trigger a play-in scenario. In this case there will be (1400 - 1024) * 2
    or 752 participating in the play-in round. The play-in will be randomly selected from rabids first. If there are more
    play-in slots than Rabids, next Supers will be selected next randomly.

    After the play-in round, half, or 376 Champions will move on to the bracket stage. Each bracket will consist of 1024/4, or 256 champions.
    
    The play-in round and seeding will be done off chain. Code will be available for randomization upon request. We will use
    the transaction hash of the last registered champion to seed the randomization. Once the play-in round is done, the full tournament bracket will be released.
  */
  function registerChampion(uint tokenId) public {
    require(_ownerOf[tokenId] == msg.sender, "You don't own this token");
    registeredChamps.push(tokenId);
    inArena[tokenId] = true;
  }

  function getRegistered() public view returns (uint[] memory) {
    return registeredChamps;
  }

  function playIn(uint[] calldata random, uint[] calldata health, uint i, uint max) external onlyOwner {
    uint offset = getOffset();
    while (i < max) {
      uint randomIndex = (offset + i) % max;
      uint randomIndex2 = (offset + i + 1) % max;
      if ((health[i] * random[randomIndex]) >= (health[i + 1] * random[randomIndex2])) {
        inArena[playInChamps[i + 1]] = false;
      } else {
        inArena[playInChamps[i]] = false;
      }
      i += 2;
    }
  }

  function setPlayIn(uint[] calldata champs, uint i) external onlyOwner {
    for (uint ind = 0; ind < champs.length; ind++) {
      playInChamps[i] = champs[ind];
      i++;
    }
  }

  function playRound(uint[] calldata random, uint[] calldata health, uint[] storage round, uint[] storage nextround) internal {
    uint i = 0;
    uint offset = getOffset();
    while (i < round.length) {
      uint randomIndex = (offset + i) % round.length;
      uint randomIndex2 = (offset + i + 1) % round.length;
      if ((health[i] * random[randomIndex]) >= (health[i + 1] * random[randomIndex2])) {
        inArena[round[i + 1]] = false;
        nextround.push(round[i]);
      } else {
        inArena[round[i]] = false;
        nextround.push(round[i + 1]);
      }
      i = i + 2;
    }
  }

  function playBracket1Round(uint[] calldata random, uint[] calldata health, uint round) public onlyOwner {
    playRound(random, health, rounds1[round], rounds1[round + 1]);
  }

  function setBracket1Round(uint[] calldata champs, uint round) public onlyOwner {
    for (uint i = 0; i < champs.length; i++) {
      rounds1[round].push(champs[i]);
    }
  }

  function playBracket2Round(uint[] calldata random, uint[] calldata health, uint round) public onlyOwner {
    playRound(random, health, rounds2[round], rounds2[round + 1]);
  }

  function setBracket2Round(uint[] calldata champs, uint round) public onlyOwner {
    for (uint i = 0; i < champs.length; i++) {
      rounds2[round].push(champs[i]);
    }
  }

  function playBracket3Round(uint[] calldata random, uint[] calldata health, uint round) public onlyOwner {
    playRound(random, health, rounds3[round], rounds3[round + 1]);
  }

  function setBracket3Round(uint[] calldata champs, uint round) public onlyOwner {
    for (uint i = 0; i < champs.length; i++) {
      rounds3[round].push(champs[i]);
    }
  }

  function playBracket4Round(uint[] calldata random, uint[] calldata health, uint round) public onlyOwner {
    playRound(random, health, rounds4[round], rounds4[round + 1]);
  }

  function setBracket4Round(uint[] calldata champs, uint round) public onlyOwner {
    for (uint i = 0; i < champs.length; i++) {
      rounds4[round].push(champs[i]);
    }
  }

  function playFinalFour(uint[] calldata random, uint[] calldata health) public onlyOwner {
    playRound(random, health, finalFour, finals);
  }

  function setFinalFour(uint[] calldata champs) public onlyOwner {
    for (uint i = 0; i < 4; i++) {
      finalFour.push(champs[i]);
    }
  }

  function playFinals(uint[] calldata random, uint[] calldata health) public onlyOwner {
    playRound(random, health, finals, winner);
  }
  // function unwrap() public {
  //   // we have so few howler feedz that aren't prey we can probably if them all out and just have 1 unwrap function

  // }

  /** OWNER FUNCTIONS */
  function ownerMint(uint id) public onlyOwner {
    _mint(msg.sender, id);
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    if (frozen) {
      revert("Metadata is frozen");
    }

    uri = baseURI;
  }

  function freezeMetadata() public onlyOwner {
    frozen = true;
  }

  function setContractAddress(uint identifier, address newaddress) public onlyOwner {
    if (identifier == 0) {
      howlerzAddress = newaddress;
    } else {
      preyAddress = newaddress;
    }
  }

  /** INTERNAL FUNCTIONS */

  function getOffset() internal returns (uint) {
    uint offsetBlock = block.number - 69;
    uint offset = uint(blockhash(offsetBlock));
    return offset;
  }

  /** OVERRIDE FUNCTIONS */
  function transferFrom(address from, address to, uint256 id) public virtual override {
    if (inArena[id]) {
      revert("Champion is in arena");
    }
    super.transferFrom(from,to,id);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_ownerOf[tokenId] != address(0), "NOT_MINTED");

    return string(abi.encodePacked(uri, tokenId.toString()));
  }
}