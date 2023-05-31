/**
 * @title  Spirit Animal Smart Contract for Divine Anarchy
 * @author Diveristy - twitter.com/DiversityETH
 *
 * 8888b.  88 Yb    dP 88 88b 88 888888      db    88b 88    db    88""Yb  dP""b8 88  88 Yb  dP
 *  8I  Yb 88  Yb  dP  88 88Yb88 88__       dPYb   88Yb88   dPYb   88__dP dP   `" 88  88  YbdP
 *  8I  dY 88   YbdP   88 88 Y88 88""      dP__Yb  88 Y88  dP__Yb  88"Yb  Yb      888888   8P
 * 8888Y"  88    YP    88 88  Y8 888888   dP""""Yb 88  Y8 dP""""Yb 88  Yb  YboodP 88  88  dP
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A-Custom.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SpiritAnimals is Ownable, ERC721A {
	using ECDSA for bytes32;
	using Strings for uint256;

	uint256 public constant MAX_SUPPLY = 2510;
	string public baseUri;

	// Mint
	address private signer;
	uint128 public  dutchSupply    = 0;
	uint128 public  claimSupply    = 0;
	uint128 public  freeSupply     = 0;
	uint64  public  dutchMaxMint   = 5;
	uint64  public  freeStartTime  = 1653318000; // May 23rd, 11AM
	bool    private enableAuthMint = true;
	bool    public  paused         = false;

	// Auction pricing
	uint64 public startPrice = 0.50 ether;
	uint64 public stepAmount = 0.05 ether;

	// Auction timing
	uint64 public startTime   = 1653231600; // May 22nd, 11AM
	uint32 public length      = 200 minutes;
	uint16 public interval    = 20 minutes;
	uint64 public endTime     = startTime + length;

	// Tracking
	struct MintTotals {
		uint128 claim;
		uint64 dutch;
		uint64 free;
	}
	mapping(address => MintTotals) public mintTracking;
	MintTotals mintTotals;

	constructor(string memory uri, uint128 reserved_amount, address[] memory monarchs) ERC721A("Spirit Animals", "DAS") {
		baseUri      = uri;
		claimSupply  = reserved_amount;
		dutchSupply  = uint128(MAX_SUPPLY - claimSupply);
		freeSupply   = (dutchSupply * 10 / 100); // 10% of the Da supply
		dutchSupply -= uint128(freeSupply);

		require(claimSupply + freeSupply + dutchSupply == MAX_SUPPLY, "Supplies do not add up.");

		// Mint to monarchs
		for(uint8 i = 1; i <= 10; i++) {
			airdrop(monarchs[i - 1], 1);
		}
		mintTotals.claim = 10;
	}

	modifier authMint(uint8 quantity, bytes calldata signature) {
		if(enableAuthMint) {
			require(signer == keccak256(abi.encodePacked(
				msg.sender,
				quantity,
				msg.sig
			)).toEthSignedMessageHash().recover(signature), "Auth: Reject");
		}
		_;
	}

	modifier callerIsUser() {
		require(tx.origin == msg.sender, "The caller is another contract");
		_;
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseUri;
	}

	function claim(uint8 quantity, bytes calldata signature) public callerIsUser authMint(quantity, signature) {
		require(!paused, "Claiming is paused");
		require(mintTracking[msg.sender].claim < 1, "Claim has already been executed.");
		require(mintTotals.claim + quantity <= claimSupply, "Exceeds claim supply");

		mintTracking[msg.sender].claim = quantity;
		mintTotals.claim += quantity;

		_safeMint(msg.sender, quantity);
	}

	function dutchMint(uint8 quantity) public payable callerIsUser {
		require(!paused, "Dutch auction is paused");
		require(mintTracking[msg.sender].dutch + quantity <= dutchMaxMint, "Exceeds dutch max mint");
		require(mintTotals.dutch + quantity <= dutchSupply, "Exceeds dutch supply");
		require(block.timestamp < endTime, "Dutch auction ended.");

		uint256 price = getAuctionPrice() * quantity;
		require(msg.value >= price, "Need to send more ETH.");

		mintTracking[msg.sender].dutch += quantity;
		mintTotals.dutch += quantity;

		_safeMint(msg.sender, quantity);

		// Refund any money that was sent over the current auction price as of minting
		if(msg.value > price) {
			payable(msg.sender).transfer(msg.value - price);
		}
	}

	function freeMint(uint8 quantity, bytes calldata signature) public callerIsUser authMint(quantity, signature) {
		require(!paused, "Free mints are paused");
		require(mintTracking[msg.sender].free < 1, "Free Claim has already been executed");
		require(mintTotals.free + quantity <= freeSupply, "Exceeds max supply");
		require(freeStartTime <= block.timestamp, "Free mint has not started yet");

		mintTracking[msg.sender].free = quantity;
		mintTotals.free += quantity;

		_safeMint(msg.sender, quantity);
	}

	function teamMint(uint64 quantity, address wallet) public onlyOwner {
		require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
		_safeMint(wallet, quantity);
	}

	function getAuctionPrice() public view returns (uint256) {
		if (block.timestamp < startTime) {
			return startPrice;
		}

		if (block.timestamp - startTime >= length) {
			return 0;
		}

		uint256 steps = (block.timestamp - startTime) / interval;
		return startPrice - (steps * stepAmount);
	}

	function getUserStates() public view returns (bool[3] memory) {
		MintTotals memory userTotals = mintTracking[msg.sender];

		return [
			userTotals.claim > 0, // Claim
			userTotals.dutch >=dutchMaxMint, // Dutch
			userTotals.free > 0 // Free
		];
	}

	function setDutchMaxMint(uint64 amount) public onlyOwner {
		dutchMaxMint = amount;
	}

	function setSigner(address signer_) public onlyOwner {
		signer = signer_;
	}

	function setBaseUri(string memory uri) public onlyOwner {
		baseUri = uri;
	}

	function setFreeStart(uint64 time) public onlyOwner {
		freeStartTime = time;
	}

	function setAuctionStart(uint32 time) public onlyOwner {
		startTime = time;
		endTime = time + length;
	}

	function setAuctionStartPrice(uint64 amount) public onlyOwner {
		startPrice = amount;
	}

	function setAuctionStep(uint64 amount) public onlyOwner {
		stepAmount = amount;
	}

	function setAuctionInterval(uint16 amountOfSeconds) public onlyOwner {
		interval = amountOfSeconds;
	}

	function setAuctionLength(uint16 amountOfSeconds) public onlyOwner {
		length = amountOfSeconds;
	}

	function togglePause() public onlyOwner {
		paused = !paused;
	}

	function toggleAuthMinting() public onlyOwner {
		enableAuthMint = !enableAuthMint;
	}

	function setDutchSupply(uint128 amount) public onlyOwner {
		dutchSupply = amount;
	}

	function withdrawAll() external onlyOwner {
		uint256 currentBalance = address(this).balance;
		(bool sent,) = address(msg.sender).call{value: currentBalance}("");
		require(sent);
	}
}