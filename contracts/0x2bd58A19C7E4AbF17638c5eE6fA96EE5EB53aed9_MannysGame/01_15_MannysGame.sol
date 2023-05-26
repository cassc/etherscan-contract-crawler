//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract MannysGame is ERC721, Ownable {

  using SafeMath for uint256;

  uint16[] mannys;
  bool public mintActive = true;
  bool public goldMannyMinted = false;
  bool public gameWon = false;
  uint256 public gameStart;
  address public gameWinner;

  mapping(address => uint) public claimedPerWallet;
  uint256 public constant price = 0.1 ether;

  address public constant mannyWallet = 0xF3A45Ee798fc560CE080d143D12312185f84aa72;
  address public constant vaultWallet = 0x65861c79fA4249ACc971C229eB52f80A3eDEDedc;

  constructor() public ERC721("mannys.game", "MNYGME") {
    gameStart = now;

    _setBaseURI("ipfs://QmSVeNNmfQ2AJbYQveuP4Uhn1HufyAWFhvknLqwqkrspBS/");

    // token 404 is reserved for game winner so skip it
    for(uint16 i = 1; i <= 1616; i++) {
      if (i != 404) {
        mannys.push(i);
      }
    }

    // mint token 1 to mannys wallet
    mannys[0] = mannys[mannys.length - 1];
    mannys.pop();
    _safeMint(mannyWallet, 1);

    // mint 1 of each token type to vault wallet
    mannys[201] = mannys[mannys.length - 1]; // base rare
    mannys.pop();
    _safeMint(vaultWallet, 202);
    mannys[400] = mannys[mannys.length - 1]; // albino
    mannys.pop();
    _safeMint(vaultWallet, 401);
    mannys[41] = mannys[mannys.length - 1]; // holo
    mannys.pop();
    _safeMint(vaultWallet, 42);
    mannys[143] = mannys[mannys.length - 1]; // inverted
    mannys.pop();
    _safeMint(vaultWallet, 144);
    mannys[65] = mannys[mannys.length - 1]; // silver
    mannys.pop();
    _safeMint(vaultWallet, 66);
    mannys[243] = mannys[mannys.length - 1]; // stone
    mannys.pop();
    _safeMint(vaultWallet, 244);
    mannys[254] = mannys[mannys.length - 1]; // zombie
    mannys.pop();
    _safeMint(vaultWallet, 255);
  }

  function mint(uint numberOfTokens) public payable {
    require(mintActive == true, "mint is not active rn..");
    require(tx.origin == msg.sender, "dont get Seven'd");
    require(numberOfTokens > 0, "mint more lol");
    require(numberOfTokens <= 16, "dont be greedy smh");
    require(numberOfTokens <= mannys.length, "no more tokens sry");
    require(claimedPerWallet[msg.sender] + numberOfTokens <= 64, "claimed too many");
    require(msg.value >= price.mul(numberOfTokens), "more eth pls");

    // mint a random manny
    for (uint i = 0; i < numberOfTokens; i++) {
      uint256 randManny = getRandom(mannys);
      _safeMint(msg.sender, randManny);
      claimedPerWallet[msg.sender] += 1;
    }

    uint mannyCut = msg.value * 40 / 100;
    payable(mannyWallet).transfer(mannyCut);
  }

  function getRandom(uint16[] storage _arr) private returns (uint256) {
    uint256 random = _getRandomNumber(_arr);
    uint256 tokenId = uint256(_arr[random]);

    _arr[random] = _arr[_arr.length - 1];
    _arr.pop();

    return tokenId;
  }

	/**
   * @dev Pseudo-random number generator
	 * if you're able to exploit this you probably deserve to win TBH
   */
  function _getRandomNumber(uint16[] storage _arr) private view returns (uint256) {
    uint256 random = uint256(
      keccak256(
        abi.encodePacked(
          _arr.length,
          blockhash(block.number - 1),
          block.coinbase,
          block.difficulty,
          msg.sender
        )
      )
    );

    return random % _arr.length;
  }

  function tokensByOwner(address _owner) external view returns(uint16[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint16[](0);
    } else {
      uint16[] memory result = new uint16[](tokenCount);
      uint16 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = uint16(tokenOfOwnerByIndex(_owner, index));
      }
      return result;
    }
  }

  function mintGoldManny() public {
    require(goldMannyMinted == false, "golden manny already minted...");
    uint16[5] memory zombie = [13, 143, 180, 255, 363];
    uint16[16] memory inverted = [10, 17, 44, 60, 64, 77, 78, 144, 155, 165, 168, 216, 219, 298, 329, 397];
    uint16[16] memory silver = [7, 24, 66, 76, 85, 127, 148, 167, 172, 186, 210, 287, 303, 304, 348, 396];
    uint16[16] memory stone = [11, 33, 36, 58, 108, 138, 171, 173, 184, 190, 209, 231, 234, 244, 308, 332];
    uint16[24] memory albinos = [59, 91, 93, 94, 115, 118, 119, 141, 145, 150, 160, 179, 192, 195, 235, 
      237, 271, 273, 291, 297, 325, 326, 381, 401];
    uint16[24] memory holos = [42, 90, 92, 98, 122, 124, 132, 156, 162, 182, 197, 206, 240, 242, 253, 
      306, 335, 341, 351, 382, 387, 390, 391, 399];

    uint16[] memory tokensOwned = this.tokensByOwner(msg.sender);
    uint16[] memory points = new uint16[](7);

    for (uint16 k = 0; k < tokensOwned.length; k++) {
      uint16 token = tokensOwned[k];
      bool isBase = token <= 403;
      for (uint16 i = 0; i < 24; i++) {
        if (i < albinos.length && albinos[i] == token) {
          points[1] = 1;
          isBase = false;
        } else if (i < holos.length && holos[i] == token) {
          points[2] = 1;
          isBase = false;
        } else if (i < inverted.length && inverted[i] == token) {
          points[3] = 1;
          isBase = false;
        } else if (i < silver.length && silver[i] == token) {
          points[4] = 1;
          isBase = false;
        } else if (i < stone.length && stone[i] == token) {
          points[5] = 1;
          isBase = false;
        } else if (i < zombie.length && zombie[i] == token) {
          points[6] = 1;
          isBase = false;
        }
      }
      // if checked all special ids and none matched, add base point
      if (isBase) {
        points[0] = 1;
      }
    }

    uint16 totalPoints;
    for (uint16 j = 0; j < points.length; j++) {
      if (points[j] == 1) {
        totalPoints += 1;
      }
    }

    require(totalPoints >= 7, "not enough points for a golden manny, ngmi...");
    _safeMint(msg.sender, 404);
    goldMannyMinted = true;
  }

  function winTheGame() public {
    require(gameWon == false, "game has already been won, gg");
    require(this.ownerOf(404) == msg.sender, "have not acquired the golden manny, smh...");
    msg.sender.transfer(address(this).balance);
    gameWon = true;
    gameWinner = msg.sender;
  }

  // admin
  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }

  function setMintActive(bool _mintActive) public onlyOwner {
    mintActive = _mintActive;
  }

  function withdraw() public onlyOwner {
    uint256 days404 = 86400 * 404;
    // time hasnt expired, so enforce rules
    if (now <= gameStart + days404) {
      require(gameWon == true, "game isnt over yet...");
    }

    uint256 balance = address(this).balance;
    msg.sender.transfer(balance);

    if (gameWon == false) {
      gameWon = true;
      gameWinner = msg.sender;
    }
  }
}