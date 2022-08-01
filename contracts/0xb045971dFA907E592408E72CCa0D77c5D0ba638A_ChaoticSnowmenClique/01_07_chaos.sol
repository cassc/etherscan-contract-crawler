// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
  ,--,  .-. .-.  .--.   .---.  _______ ,-.  ,--,   
.' .')  | | | | / /\ \ / .-. )|__   __||(|.' .')   
|  |(_) | `-' |/ /__\ \| | |(_) )| |   (_)|  |(_)  
\  \    | .-. ||  __  || | | | (_) |   | |\  \     
 \  `-. | | |)|| |  |)|\ `-' /   | |   | | \  `-.  
  \____\/(  (_)|_|  (_) )---'    `-'   `-'  \____\ 
       (__)            (_)                         

  .-')        .-') _                (`\ .-') /` _   .-')       ('-.       .-') _  
 ( OO ).     ( OO ) )                `.( OO ),'( '.( OO )_   _(  OO)     ( OO ) ) 
(_)---\_),--./ ,--,'  .-'),-----. ,--./  .--.   ,--.   ,--.)(,------.,--./ ,--,'  
/    _ | |   \ |  |\ ( OO'  .-.  '|      |  |   |   `.'   |  |  .---'|   \ |  |\  
\  :` `. |    \|  | )/   |  | |  ||  |   |  |,  |         |  |  |    |    \|  | ) 
 '..`''.)|  .     |/ \_) |  |\|  ||  |.'.|  |_) |  |'.'|  | (|  '--. |  .     |/  
.-._)   \|  |\    |    \ |  | |  ||         |   |  |   |  |  |  .--' |  |\    |   
\       /|  | \   |     `'  '-'  '|   ,'.   |   |  |   |  |  |  `---.|  | \   |   
 `-----' `--'  `--'       `-----' '--'   '--'   `--'   `--'  `------'`--'  `--'   

 ________  ___       ___  ________  ___  ___  _______      
|\   ____\|\  \     |\  \|\   __  \|\  \|\  \|\  ___ \     
\ \  \___|\ \  \    \ \  \ \  \|\  \ \  \\\  \ \   __/|    
 \ \  \    \ \  \    \ \  \ \  \\\  \ \  \\\  \ \  \_|/__  
  \ \  \____\ \  \____\ \  \ \  \\\  \ \  \\\  \ \  \_|\ \ 
   \ \_______\ \_______\ \__\ \_____  \ \_______\ \_______\
    \|_______|\|_______|\|__|\|___| \__\|_______|\|_______|
                                   \|__|                   

MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMKkkkkkKMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMKkkkkkkkkkkkKMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMKkkKMkkMMMkkMKkkKMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMllMMMKKKkKKKMMMllMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMKkkKMKkkkkkKMKkkKMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMKkkkkkkkkkkkKMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMKkkkkkkkkkkkkkKMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMKkkKMMMMKkKMMMMKkkKMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMKkkKMMMMMMKkKMMMMMMKkkKMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMllMMMMMMMMKkKMMMMMMMMllMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMllMMMMMMMMKkKMMMMMMMMllMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMklKMMMMMMMKkKMMMMMMMKlkMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMKkkKMMMMMKkKMMMMMKkkKMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMKkkkkkkkkkkkkkkkKMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMKkkkkkkkkkkkkkkkKMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMKkkKMMMMMMMMMMMMMKkkKMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMKkkKMMMMMMMMMMMMMMMMMKkkKMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMklKMMMMMMMMMMMMMMMMMMMMMKlkMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMllMMMMMMMMMMMMMMMMMMMMMMMllMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMllMMMMMMMMMMMMMMMMMMMMMMMllMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMllMMMMMMMMMMMMMMMMMMMMMMMllMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMKkkKMMMMMMMMMMMMMMMMMMMKkkKMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMKkkKMMMMMMMMMMMMMMMKkkKMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMKkkKMMMMMMMMMMMKkkKMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMM0lllllllllllllOMMMMMMMMMMMMMMMMMMMMMMMM



As the Crypto Winter loomed above, a clique of chaotic snowmen 
traveled into the grey glacer ready to take on the yeti .......


*/

contract ChaoticSnowmenClique is Ownable, ERC721A, ReentrancyGuard {

  uint256 public immutable maxBatchSize;
  uint256 public immutable amountForDevs;
  uint256 public immutable amountForAuctionAndDev;

  string public cscProvenance = "";

  uint256 public constant SNOWMEN_SUPPLY = 10000;

	uint256 public constant AUCTION_START_PRICE = 2 ether;
	uint256 public constant AUCTION_END_PRICE = 0.08 ether;
	uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 690 minutes;
	uint256 public constant AUCTION_DROP_INTERVAL = 420 seconds;
	uint256 public constant AUCTION_DROP_PER_STEP =
	(AUCTION_START_PRICE - AUCTION_END_PRICE) /
	  (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);

	bool public saleIsActive = false;

  struct SaleConfig {
    uint256 auctionSaleStartTime;
    uint256 auctionSaleEndTime;
  }
  constructor(
      uint256 maxBatchSize_,
      uint256 collectionSize_,
      uint256 amountForAuctionAndDev_,
      uint256 amountForDevs_
    ) ERC721A("Chaotic Snowmen Clique", "CHAOS"){
      maxBatchSize = maxBatchSize_;
      amountForAuctionAndDev = amountForAuctionAndDev_;
      amountForDevs = amountForDevs_;
      require(
        amountForAuctionAndDev_ <= collectionSize_,
        "larger collection size needed"
      );
    }


  SaleConfig public saleConfig;

    modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }


  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }



  function auctionMint(uint256 quantity) external payable callerIsUser {
    uint256 _saleStartTime = uint256(saleConfig.auctionSaleStartTime);
    require(
      _saleStartTime != 0 && block.timestamp >= _saleStartTime,
      "sale has not started yet"
    );
    require(
      totalSupply() + quantity <= amountForAuctionAndDev,
      "not enough remaining reserved for auction to support desired mint amount"
    );
    require(_numberMinted(msg.sender) + quantity <= maxBatchSize, "can not mint this many");
    uint256 totalCost = getAuctionPrice(_saleStartTime) * quantity;
    _safeMint(msg.sender, quantity);
    refundIfOver(totalCost);
  }

	function getAuctionPrice(uint256 _saleStartTime) public view returns (uint256)
{
    if (block.timestamp < _saleStartTime) {
      return AUCTION_START_PRICE;
    }
    if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
      return AUCTION_END_PRICE;
    } else {
      uint256 steps = (block.timestamp - _saleStartTime) /
        AUCTION_DROP_INTERVAL;
      return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
    }
  }




  function endAuctionSale() external onlyOwner {

    saleConfig = SaleConfig(
      0,
      0
    );
    saleIsActive = false;
  }


  function startAuctionSale(uint256 timestamp) external onlyOwner {
    saleConfig.auctionSaleStartTime = timestamp;
    saleConfig.auctionSaleEndTime = timestamp + AUCTION_PRICE_CURVE_LENGTH;
    saleIsActive = true;
  }

  // For marketing etc.
  function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    require(quantity % maxBatchSize == 0, "can only mint a multiple of the maxBatchSize");
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }


  /*     
    * Set provenance 
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        cscProvenance = provenanceHash;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
      }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
      }


}