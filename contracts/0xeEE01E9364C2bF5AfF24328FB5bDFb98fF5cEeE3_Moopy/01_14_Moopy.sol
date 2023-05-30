// SPDX-License-Identifier: MIT
/*                
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%&@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%#((%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%@@@@@@@((((((((((%@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@(  ((((((((((@@(%%%%%%%%@@           @@(((((((%%@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@     ((((((((((((((%%%%@.      @@@       @&(((((%%[email protected]@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@    ((((((((((((((%%@..    @&&&&&&@      @(((%%%[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@    ((((((((((((((@...   @&**&&&%,@.     @((%%....&@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@ @*(((((((((((((@...     @@**   &@      @%%......,@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@   ((((((((((((@....      [email protected]*  &&@     @&[email protected]@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@     ((((((((((#@....    @ ,,,,,&@     @*.........#@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@      ((((((((((%@....    @@@@@       @*@[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@(     (((((((((((((@@[email protected]@@@@@%............,%%@@@@@@@@@@@@@@@
@@@@@@@@@@@@@((((((((((((((((((@@#(((((((&@@ /@@@............%%%%&@@@@@@@@@@@@@@
@@@@@@@@@@@@@((((((((((((((((((((((((((((@  ****@@..........%%%%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@(((((((((((((((((((((((((((@&   ***@........%%%%%%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@#(((((((((((((((((((((((((((@  ****@((/...%%%%%%%%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@(((((((((((((#(((((((((((((@  ****@((((((((%%%%%%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@((((((%%%......(((((((((((@   .**@(((((((((((((%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%%%%.............(((((((((@  ***@((((((((((((((((%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%%....%%............((((((((@@&(((((((((((((@@((((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%[email protected]@...............(((((((((((((((((((((@@((((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@[email protected]@...................(((((((((((((((((@(((((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%[email protected]@................         /((((((((((@((((@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@%%%#[email protected]@...........                        @@((((@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@%%%%%%%@@...                                @((((@@@@@@@@@@@@@@@@                
*/

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Moopy is ERC721A, Ownable {
	using SafeERC20 for IERC20;
	using Strings for uint256;

	// Maximum supply
	uint256 public  MAX_SUPPLY = 5000;

	// Starting time of auction
	uint256 public  AUCTION_START_TIME = 1657026000; 

	// Maximum ending time of auction
	uint256 public  AUCTION_END_TIME = 1657198800; 

	// Possible ending time of auction
	uint256 public  AUCTION_MARK_TIME = 1657177200; 

	// Metadata URI suffix
	string public constant TOKEN_URI_SUFFIX = ".json";

	// Minimum bid price to qualify for minting
	uint256 public qualifyingPrice;

	// Timelock for owner withdraw function
	uint256 public ownerWithdrawTimelock;

	// Metadata URI
	string public baseTokenURI;

	// Whether the auction has ended
	bool public isAuctionEnded; 

	// Allows whitelisters to mint during their window
	bool public isWhitelistMintActive;

	// All bidder addresses
	address[] public allBidders;

	// Merkle root for Whitelists
	bytes32 public merkleRoot;

	// Whitelisted addresses that have minted
	mapping(address => bool) public whitelistMinted;

	// Bid prices of addresses	
	mapping(address => uint256) public bidPrices;

	// Random ending time of auction
	uint256 private _auctionRandEndTime = AUCTION_END_TIME;

	// Check if auction is ongoing
	modifier auctionLive {
		require(block.timestamp >= AUCTION_START_TIME, "auction not started");

		require(!isAuctionEnded, "auction ended");

		if (block.timestamp >= _auctionRandEndTime) {
			isAuctionEnded = true;
			emit AuctionEnded(block.timestamp, allBidders.length);
			return;
		}
		
		_;
	}

	// Events
	event AuctionEnded(uint256 _endTime, uint256 _totalBids);
	event BidPlaced(address indexed _bidder, uint256 _bidPrice);

	constructor() ERC721A ("Moopy", "MOOPY") {}

	// --PUBLIC--
	// Mint one token for a whitelisted address
	function whitelistMint(bytes32[] calldata _merkleProof) public {
		require(isWhitelistMintActive, "whitelist mint not active");
		require(!whitelistMinted[msg.sender], "address already minted");
		
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "invalid proof");

		uint256 supply = totalSupply();
		require(supply + 1 <= MAX_SUPPLY, "order exceeds supply");

		whitelistMinted[msg.sender] = true;

    	_safeMint(msg.sender, 1);
	}

	// Submit or increase the bid price of an address
	function placeBid() public payable auctionLive {
		require(msg.value > 0, "bid price must be at least 1 wei");

		uint256 lastBidPrice = bidPrices[msg.sender];
		
		if(lastBidPrice == 0) {
			allBidders.push(msg.sender);
		}

		bidPrices[msg.sender] += msg.value;
		
		emit BidPlaced(msg.sender, bidPrices[msg.sender]);
	}

	// Randomly set an ending time for the auction 
	function randomizeAuctionEndTime(uint256 _randNum) public auctionLive {
		require (tx.origin == msg.sender && msg.sender.code.length == 0, "only EOA calls");
		require (block.timestamp >= AUCTION_MARK_TIME, "auction cannot be ended yet");
		
		_auctionRandEndTime = block.timestamp + (_getRandomNumber(_randNum) % (AUCTION_END_TIME - block.timestamp));
	}

	// Handle the result of the auction for each bidder
	function resolveAuctionResults() public {
		_resolveAuctionResults(msg.sender);
	}

	// Allow bidders to withdraw if owner attempts to rug
	function emergencyWithdraw() public {
		require(ownerWithdrawTimelock != 0, "e-withdraw not active");

		uint256 bidPrice = bidPrices[msg.sender];
		require(bidPrice != 0, "no bid submitted");
	
		bidPrices[msg.sender] = 0;

		payable(msg.sender).transfer(bidPrice);
	}

	// --PUBLIC VIEWS--
	// Retrieve all tokens owned by an address
	function walletOfOwner(address _account) public view returns (uint256[] memory _wallet) {
		uint256 count;
		uint256 quantity = balanceOf(_account);
		uint256 length = totalSupply();
		uint256[] memory wallet = new uint256[](quantity);
		for (uint256 i; i < length; i++) {
			if (_account == ownerOf(i)) {
				wallet[count++] = i;
				if (count == quantity) break;
			}
		}
		return wallet;
	}

	// Retrieve the total number of bids
	function getTotalBids() public view returns (uint256) {
		return allBidders.length;
	}

	// Retrieve all addresses who placed bids
	function getAllBidders(uint256 _startIndex, uint256 _endIndex) public view returns (address[] memory) {
		uint256 size = _endIndex - _startIndex + 1;
		address[] memory bidders = new address[](size);
		
		for (uint256 i = 0; i < size; i++) {
			bidders[i] = allBidders[i + _startIndex];
		}

		return bidders;
	}

	// Retrieve the bid prices for an array of addresses
	function getBidsByAddresses(address[] memory _bidders) public view returns (uint256[] memory) {
		uint256[] memory bids = new uint[](_bidders.length);

		for (uint256 i = 0; i < _bidders.length; i++) {
			bids[i] = bidPrices[_bidders[i]];
		}

		return bids;
	}

	// Retrieves the total number of bids above this qualifying price
	function checkQualifyingPrice(uint256 _qualifyingPrice) public view returns (uint256 count) {
		address bidder;
		uint256 bidPrice;

		for (uint256 i = 0; i < allBidders.length; i++) {
			bidder = allBidders[i];
			bidPrice = bidPrices[bidder];

			if (bidPrice >= _qualifyingPrice) {
				++count;
			}
		}		
	}

	// Retrieve the URI of a token
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
	{
		require(_exists(tokenId), "query for nonexistent token");
		return string(abi.encodePacked(baseTokenURI, tokenId.toString(), TOKEN_URI_SUFFIX));
	}

	// --ONLY OWNER--
	// Mint tokens for the team
	function devMint(uint256 _quantity) public onlyOwner {
		uint256 supply = totalSupply();
		require(supply + _quantity <= MAX_SUPPLY, "order exceeds supply");

        while (_quantity > 10) {
            _safeMint(msg.sender, 10);
            _quantity -= 10;
        }
        if (_quantity > 0) {
            _safeMint(msg.sender, _quantity);
        }
	}

	// Set Merkle Root
	function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
		merkleRoot = _merkleRoot;
	}

	// Toggle whitelist sale
	function setWhitelistMintActive() public onlyOwner {
		isWhitelistMintActive = !isWhitelistMintActive;
	}

	// Set qualifying price for auction
	function setQualifyingPrice(uint256 _price) public onlyOwner {	
		qualifyingPrice = _price;
	}

	// Set base URI of token
	function setBaseURI(string calldata _newBaseURI) public onlyOwner {
		baseTokenURI = _newBaseURI;
	}

	// Withdraw funds in contract, 24 hour timelock
	function ownerWithdraw(address _receiver) public onlyOwner {
		if(ownerWithdrawTimelock == 0) {
			ownerWithdrawTimelock = block.timestamp + 86400;
		}else if(ownerWithdrawTimelock < block.timestamp) {
			ownerWithdrawTimelock = 0;

			uint256 balance = address(this).balance;

			payable(_receiver).transfer(balance);
		}
	}   

	// Force the resolution of an address
	function forcedResolve(address _bidder) public onlyOwner {
		_resolveAuctionResults(_bidder);
	}

	// Withdraw ERC20 tokens if necessary
	function transferERC20Token(IERC20 token, uint256 amount) external onlyOwner {
		token.safeTransfer(owner(), amount);
	}

	// --INTERNAL--
	// Resolve the results of the auction
	function _resolveAuctionResults(address _bidder) internal {
		require(qualifyingPrice != 0, "auction not concluded");

		uint256 bidPrice = bidPrices[_bidder];
		require(bidPrice != 0, "no bid submitted");

		uint256 refundAmount = 0;

		if(bidPrice >= qualifyingPrice) {
			// Successful bid, mint one token and refund excess bid amount

			require(totalSupply() < MAX_SUPPLY, "mint exceeds supply");
			
			bidPrices[_bidder] = 0;

			refundAmount = bidPrice - qualifyingPrice;

			_safeMint(_bidder, 1);
		}else {
			// Unsuccessful bid, refund bid amount

			bidPrices[_bidder] = 0;

			refundAmount = bidPrice;
		}

		payable(_bidder).transfer(refundAmount);
	}
	
	// Generate a random number 
	// Unsecure implementation, chosen for scope and gas efficiency
	function _getRandomNumber(uint256 _randNum) private view returns (uint256) {
		return uint256(keccak256(abi.encode(_randNum, allBidders.length, blockhash(block.number - 1))));
	}
}