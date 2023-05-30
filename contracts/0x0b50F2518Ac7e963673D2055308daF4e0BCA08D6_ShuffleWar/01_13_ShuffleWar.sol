// SPDX-License-Identifier: MIT
/*
                                                                ,.                                  
                    @@@                                       ,@@@@@@@@@@@@@                        
                  @@@@@@@                                    @@   @@@@@#  (@@@@@*     %@@(          
                  @@@@@@@                               @@@@@[email protected]               @@@@@@@@@@@@@&        
                  @@@@@@@                              %@@@@@@@ @@,,  @@,      [email protected]@@@@@@@@@@@@       
             @@@@@@@@@@@@@@@                            @@@@@@@@      [email protected]@@@@   &@@@@@@@@@@@@@       
          #@@     @@@@@@@   @@*                           @@@@&              @@@@@@@@@@@@@@@&       
        @@#                   &@@                           *@@@         [email protected]@@@@@@@@@@@@@@@@         
        @@#                   &@@                            @@             @@@@@@@                 
        @@#                   &@@       /@   @@ @%@@@.       (@&              @@@@@@@                
     @@@                      &@@       /@   @@  @&.        @@                %@@@@@                
     @@@     @@%         ,@@  &@@        @@ @@     @@      @@                  @@@@ .               
     @@@@@#                   &@@         @@@   @@@@       @@                 @@@@                 
        @@#                   &@@                           @@              (@@@@@@                 
        @@#         ,@@       &@@                             @@@@@@@@@@@@@@@@@@@@@,                
        @@#              ,@@@@@@@@@@@@@@                               * @@@@@@@@@@@                
        @@#                             @@@                         &.,/@@@@@@@@@@@@(  ,            
          %@@            ,@@@@@@@@@@@@@@                         %    @@@@@@@@@@@@ ,      @         
          %@@            ,@@                                   @@@@ (&@@@@@@@@@/  ,  * @@@@@@@@@    
          %@@     @@@@@@@@                                    @@@   *(@@@@@@@  ..     ,@@@@@@@@@@   
          %@@       ,@@                                       @@@      @@@@/  ,,    ,@@@@@@@@@@@@@  
          %@@       ,@@                                      @@@@@   @  @    @    (@@@@@@@@@@@@@@@@ 

*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Puzzle.sol";

contract ShuffleWar is ERC721, Puzzle, Ownable {

  using Strings for uint256;

  string public baseURI;
  bool public isBaseURIset = false;

  uint256 public mintPrice = 20000000000000000;
  uint256 public editPrice = 0;

  uint16 constant MAX_TOKEN_ID = 9999;

  uint256 public earlyAccessWindowOpens = 1641916800;
  uint256 public gameStartWindowOpens  = 1641920400;

  uint16 public freeMintCount = 1000;
  uint8 public maxBatchMintCount = 20;

  bool public paused = false;

  uint16 public apeTotal;
  uint16 public punkTotal;

  struct TokenInfo {
      uint8 tokenType;
      bool editAllowed;
      uint16 shuffleTokenId;
      uint256[] movesData;
  }

  mapping (uint16 => TokenInfo) public tokenInfo;
  event NftMinted(address sender, uint16 tokenId);

  constructor() ERC721("punksVSapes", "PvsA") {}

  function _baseURI() override internal view virtual returns (string memory) {
      return baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      string memory _base = _baseURI();
      return bytes(_base).length > 0 ? string(abi.encodePacked(_base, uint(tokenInfo[uint16(tokenId)].tokenType).toString(), "/", tokenId.toString())) : "";
  }

  function totalSupply() external view returns (uint16) {
    return getTotalMintedCount();
  }

  function getTotalMintedCount() public view returns (uint16) {
    return apeTotal + punkTotal;
 }

  function getMintPrice(uint8 count) public view returns (uint) {
    if (getTotalMintedCount() > freeMintCount) {
        return mintPrice * count;
    } else if (getTotalMintedCount() + count < freeMintCount) {
      return 0;
    } else {
      return (getTotalMintedCount() + count - freeMintCount) * mintPrice;
    }
  }
 
 function getTotalMintedCountForType() external view returns (uint16, uint16) {
   return (apeTotal, punkTotal);
 }

  function getOwnerInfoForToken(uint16 tokenId) external view returns (uint8, address) {
    TokenInfo memory info = tokenInfo[tokenId];
    return (info.tokenType, ownerOf(tokenId));
  }

   function isAvailableForSale(uint16 tokenId) external view returns (bool) {
    return !(_exists(tokenId));
  }

  function getGameStartWindows() external view returns (uint256, uint256) {
    return (earlyAccessWindowOpens, gameStartWindowOpens);
  }

   function getShuffledNumbersForToken(uint16 tokenId) public view returns (uint8[9] memory shuffledOrder, uint16 shuffleIteration) {
        uint16 shuffleTokenId = tokenInfo[tokenId].shuffleTokenId;
        if (shuffleTokenId != 0) {
          return _getShuffledNumbersForToken(shuffleTokenId);
        } else {
          return _getShuffledNumbersForToken(tokenId);
        }
    }

  function getOwnerInfoForTokens(uint16[] memory tokenIds) external view returns (uint8[] memory) {
      uint totalCount = tokenIds.length;
      uint8[] memory ownerInfo = new uint8[](totalCount);

      for (uint16 i=0; i < totalCount; i++) {
        TokenInfo memory info = tokenInfo[tokenIds[i]];

        bool available = !_exists(tokenIds[i]);
        uint8 tokenType = info.tokenType;
        
        if (available) {
            ownerInfo[i] = 1;
        } else {
            if (tokenType == 0) {
              ownerInfo[i] = 2;
            } else {
              ownerInfo[i] = 3;
            }
        }
      }
      return ownerInfo;
  }

   function getMovesForToken(uint16 tokenId) external view returns (uint256[] memory) {
    return tokenInfo[uint16(tokenId)].movesData;
   }

/*
tokenType - 0 (ape), 1 (punk)
only 1 type can be minted for a tokenId
eg. if someone mints 80 for ape, then 80 can't be minted for punk

@dev

There are two parameters for moves data, bytes moves is optimised for verification of moves
and uint256[] movesData is optimised for storage

All moves of the user are replayed on the original shuffle order for that tokenId (also generated from contract) and the final order
order is verified to make sure user actually solved the puzzle

_movesData is a compressed array of uint256 representing the user's moves. Each move on the puzzle is recorded as a up,down,left,right action
(as 1,2,3,4 in this data, represented as base5). These moves are then converted to base10 and split into multiple uint256 each having 76 digits.
Around 104 moves can be stored in a single uint256 in 76 digits after changing the base from 5 to 10.
Effectively - 300 moves can be packed into an array of 3 uint256
*/

  function verifyAndMintItem(uint16 tokenId, 
        uint8 tokenType, 
        bytes memory moves, 
        uint256[] memory _movesData,
        uint16 shuffleIterationCount,
        uint16[] memory batchMintTokens)
      external
      payable
  {

      require(!paused, "Minting paused");

      require(block.timestamp >= earlyAccessWindowOpens, "Game not started");
      require(block.timestamp >= gameStartWindowOpens || getTotalMintedCount() < freeMintCount, "EA limit reached");

      uint8 totalMintCount = uint8(batchMintTokens.length) + 1;
      require(msg.value == getMintPrice(totalMintCount), "Incorrect payment");

      require(!(_exists(tokenId)), "Already minted");
      require(tokenId > 0 && tokenId <= MAX_TOKEN_ID, "Invalid tokenId");
      require(tokenType == 0 || tokenType == 1, "Invalid tokenType");

      require(batchMintTokens.length <= maxBatchMintCount, "Token limit exceeded");

      require (verifyMoves(tokenId, moves, shuffleIterationCount), "Puzzle not solved, unable to verify moves");

      for (uint8 i = 0; i < batchMintTokens.length; i++) {
          uint16 nextMintTokenId = batchMintTokens[i];
          require(!(_exists(nextMintTokenId)), "Already minted");
          require(nextMintTokenId > 0 && nextMintTokenId <= MAX_TOKEN_ID, "Invalid tokenId");
          tokenInfo[nextMintTokenId] = TokenInfo(tokenType, false, tokenId, _movesData);
          _safeMint(msg.sender, nextMintTokenId);
          emit NftMinted(msg.sender, nextMintTokenId);
      }

      tokenInfo[tokenId] = TokenInfo(tokenType, false, 0, _movesData);
      _safeMint(msg.sender, tokenId);
      emit NftMinted(msg.sender, tokenId);

      if (tokenType == 0) {
          apeTotal += totalMintCount;
      } else {
          punkTotal += totalMintCount;
      }
  }


  function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._transfer( from, to, tokenId);
        // @dev
        // once a transfer happens, the new owner is allowed to solve the puzzle again and
        // will be able to edit their moves once
        tokenInfo[uint16(tokenId)].editAllowed = true;
    }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    require(!isBaseURIset, "Base URI is locked");
    baseURI = _newBaseURI;
  }

  function lockBaseURI() external onlyOwner {
     isBaseURIset = true;
  }

  function setMintPrice(uint256 newMintPrice) external onlyOwner {
    mintPrice = newMintPrice;
  }

  function setEditPrice(uint256 newEditPrice) external onlyOwner {
    editPrice = newEditPrice;
  }

  function setFreeMintCount(uint16 count) external onlyOwner {
    freeMintCount = count;
  }

  function setMaxBatchMintCount(uint8 count) external onlyOwner {
    maxBatchMintCount = count;
  }

  function pause(bool _state) external onlyOwner {
    paused = _state;
  }

  function editStartWindows(
        uint256 _earlyAccessWindowOpens,
        uint256 _gameStartWindowOpens
    ) external onlyOwner {
        require(
            _gameStartWindowOpens > _earlyAccessWindowOpens,
            "window combination not allowed"
        );
        gameStartWindowOpens = _gameStartWindowOpens;
        earlyAccessWindowOpens = _earlyAccessWindowOpens;
  }

   function getShuffledNumbersForEditMoves(uint16 tokenId) public pure returns (uint8[9] memory shuffledOrder, uint16 shuffleIteration) {
       return _getShuffledNumbersForToken(tokenId);
    }

  function editMoves(
        uint16 tokenId, 
        uint8 tokenType, 
        bytes memory moves, 
        uint256[] memory _movesData, 
        uint16 shuffleIterationCount
    ) external payable {

    require(_exists(tokenId), "EditMoves: TokenId doesn't exist");
    require(tokenInfo[uint16(tokenId)].editAllowed, "EditMoves: Not allowed to edit moves");
    require(msg.sender == ownerOf(tokenId), "Not authorised to edit token type");
    require(msg.value == editPrice, "Incorrect payment");
    require(tokenType == 0 || tokenType == 1, "Invalid tokenType");
    require (verifyMoves(tokenId, moves, shuffleIterationCount), "Puzzle not solved, unable to verify moves");

    tokenInfo[tokenId] = TokenInfo(tokenType, false, 0, _movesData);
  }

  function releaseFunds() public onlyOwner {
    (bool success, ) = payable(0x54caD98D0EFF87A31fB0BF046e2912e836fa832B).call{value: address(this).balance}("");
    require(success);
  }
}