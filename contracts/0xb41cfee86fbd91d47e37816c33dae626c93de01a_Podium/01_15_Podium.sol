//  ____   ___  ____ ___ _   _ __  __ 
// |  _ \ / _ \|  _ \_ _| | | |  \/  |
// | |_) | | | | | | | || | | | |\/| |
// |  __/| |_| | |_| | || |_| | |  | |
// |_|    \___/|____/___|\___/|_|  |_|
//                                   
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/* ----------------------------------------------------------------------------
* Podium Genesis NFT miniting
* Used ERC721-R for refund mechanism with customizable cliff settings.
* More infomration about refund on github and in ERC721R.sol
* There is more work to be done in the space. This is a good start. BAG_TIME
/ -------------------------------------------------------------------------- */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721R.sol";
import "./MerkleProof.sol";

contract Podium is Ownable, ERC721R, ReentrancyGuard, Pausable {

	// Declerations
	// ------------------------------------------------------------------------

	uint256 public maxMintPublic = 2;
	uint256 internal collectionSize_ = 777;
	uint256 internal reservedQuantity_ = 57; // For dev mint
	uint256 internal refundTimeIntervals_ = 14 days; // When refund cliffs
	uint256 internal refundIncrements_ = 20; // How much decrease % at cliff

	uint64 public mintListPrice = 0.12 ether;
	uint64 public publicPrice 	= 0.15 ether;

	uint32 public publicSaleStart;
	uint32 public mintListSaleStart;
	uint256 public refundPaidSum; // Not init bc 0 to save gas How much was actually paid out

	mapping(address => bool) public mintListClaimed; // Did they claim ML
	mapping(address => bool) public teamMember; 
	mapping(bytes4 => bool) public functionLocked;

	string private _baseTokenURI; // metadata URI
	address private teamRefundTreasury = msg.sender; // Address where refunded tokens sent
	bytes32 public merkleRoot; // Merkle Root for WL verification

	constructor(
	  uint32 publicSaleStart_,
	  uint32 mintListSaleStart_,
	  bytes32 merkleRoot_
	) 
	ERC721R("Podium",
			"PODIUM", 
			reservedQuantity_, 
			collectionSize_, 
			refundTimeIntervals_, 
			refundIncrements_) 
	{
	  publicSaleStart = publicSaleStart_;
	  mintListSaleStart = mintListSaleStart_;
	  merkleRoot = merkleRoot_;
	  teamMember[msg.sender] = true;
	}

	// Modifiers
	// ------------------------------------------------------------------------

	/*
	 * Make sure the caller is sender and not bot
	 */
	modifier callerNotBot() {
    	require(tx.origin == msg.sender, "The caller is another contract");
    	_;
  	}

  	/**
     * @dev Throws if called by any account other than team members
     */
    modifier onlyTeamMember() {
        require(teamMember[msg.sender], "Caller is not an owner");
        _;
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
    	require(!functionLocked[msg.sig], "Function has been locked");
        _;
    }


	// Mint functions and helpers
	// ------------------------------------------------------------------------

	/*
	 * WL Mint default quanitiy is 1. Uses merkle tree proof
	 */
	function mintListMint(bytes32[] calldata _merkleProof) 
	external payable  
	nonReentrant
	callerNotBot
	whenNotPaused
	{

		// Overall checks
	  	require(totalSupply() + 1 <= collectionSize,"All tokens minted");
    	require(isMintListSaleOn(), "Mintlist not active");

    	// Merkle check for WL verification
    	require(!mintListClaimed[msg.sender],"Already minted WL");
    	bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    	require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Not on ML");

    	// Please pay us
    	require(msg.value == mintListPrice, "Invalid Ether amount");

	    mintListClaimed[msg.sender] = true;
	    _safeMint(msg.sender, 1, mintListPrice); // Mint list quantity 1
	    refundEligbleSum += mintListPrice;
	}

	/*
	 * Public mint 
	 */
	function publicSaleMint(uint256 quantity)
	external payable
	nonReentrant
	callerNotBot
	whenNotPaused
	{ 

		// Overall checks
	  	require(
	  		totalSupply() + quantity <= collectionSize,
	  		 "All tokens minted"
	  	);

	    require(
	      numberMinted(msg.sender) + quantity <= maxMintPublic,
	      "Allowance allocated"
	    );

	    require(isPublicSaleOn(), "Public sale not active");

	    // Please pay us
    	require(msg.value == (publicPrice * quantity), "Invalid Ether amount");


	    _safeMint(msg.sender, quantity, publicPrice);
	    refundEligbleSum += (publicPrice * quantity);
	}


	/*
	 * Has public sale started
	 */
	function isPublicSaleOn() 
	public view returns (bool) {
	  	return
	      block.timestamp >= publicSaleStart;
	}

	/*
	 * Has WL sale started
	 */
	function isMintListSaleOn()
	public view returns (bool) {
	  	return
	      block.timestamp >= mintListSaleStart &&
	      block.timestamp < publicSaleStart;
	}

	/*
	 * Is specific address on WL
	 * Need merkle proof and root (mint page call)
	 */
	function isOnMintList(bytes32[] calldata _merkleProof, address _wallet)
	public view returns (bool) {
    	bytes32 leaf = keccak256(abi.encodePacked(_wallet));
    	return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
	}



	// Remaining Public functions
	// ------------------------------------------------------------------------

	/*
	 * How many were minted by owner
	 */
	function numberMinted(address owner) public view returns (uint256) {
	  	return _numberMinted(owner);
	}

	/*
	 * Who owns this token and since when
	 */
	function getOwnershipData(uint256 tokenId)
	  external
	  view
	  returns (TokenOwnership memory) {
	 	return ownershipOf(tokenId);
	}


	// Refund logic
	// ------------------------------------------------------------------------


	/**
     * Refund owner token at refund rate mint price
     * If elgible (not been transfered)
     */
    function refund(uint256 tokenId) external nonReentrant callerNotBot whenNotPaused {

    	require(isRefundActive(), "Refund is over");

    	// Confirm origin and refund activity
    	uint256 purchaseValueCurrent = _checkPurchasePriceCurrent(tokenId);
    	require(purchaseValueCurrent > 0, "Token was minted by devs or transfered");

        require(ownerOf(tokenId) == msg.sender, "You do not own token");

        // Send token to refund Address
        _refund(msg.sender, teamRefundTreasury, tokenId);

        // Refund based on purchase price and time
        uint256 refundValue;
        refundValue = purchaseValueCurrent * refundRate()/100;
        payable(msg.sender).transfer(refundValue);
        refundPaidSum += refundValue;
    }


    /**
     * Allow only withdrawal of non refund locked-up funds
     */
    function withdrawPossibleAmount() external onlyTeamMember whenNotPaused {

		if(isRefundActive()) {
			// How much can be withdrawn
			uint256 amount = address(this).balance - fundsNeededForRefund();
			(bool success, ) = msg.sender.call{value: amount}("");
			require(success, "Transfer failed.");
		}
    	else {
        	(bool success, ) = msg.sender.call{value: address(this).balance}("");
    		require(success, "Transfer failed.");
        } 
    }

    /**
     * How much ETH is eligible for refund
     * 
     */
    function checkRefundEligbleSum() public view onlyTeamMember returns (uint256) {
    	return refundEligbleSum;
    }

    /**
     * Amount needed for refunds at current rate
     */
    function fundsNeededForRefund() public view returns(uint256) {
    	return refundEligbleSum * refundRate() / 100;
    }


    /**
     * Will return refund rate in as int (i.e. 100, 80, etc)
     * To be devided by 100 for percentage
     */
    function refundRate() public view returns (uint256) {
      return (100 - (_currentPeriod(publicSaleStart) * refundIncrements));
    }


  	/**
     * How much ETH was paid out for redunds
     */
    function checkRefundedAmount() public view onlyTeamMember returns(uint256) {
    	return refundPaidSum;
    }

	/**
  	 * Is refund live
  	 */
     function isRefundActive() public view returns(bool) {
     	return (
     		block.timestamp 
     		< (publicSaleStart + (5 * refundTimeIntervals))
     	);
     }


	// Admin only functions (WL, update data, dev mint, etc.) 
	// Note: Withdraw in refund
	// ------------------------------------------------------------------------

	/*
	 * Change where refund NFTs are sent
	 */
	function changeTeamRefundTreasury(address _teamRefundTreasury) external onlyTeamMember {
	    require(_teamRefundTreasury != address(0));
	    teamRefundTreasury = _teamRefundTreasury;
	}


	/*
	 * Update prices and dates
	 */
	function manageSale(
	  uint64 _mintListPrice,
	  uint64 _publicPrice,
	  uint32 _publicSaleStart,
	  uint32 _mintListSaleStart,
	  uint256 _maxMintPublic,
	  uint256 _collectionSize
	) external onlyTeamMember lockable {
		  mintListPrice = _mintListPrice;
		  publicPrice = _publicPrice;
		  publicSaleStart = _publicSaleStart;
		  mintListSaleStart = _mintListSaleStart;
		  maxMintPublic = _maxMintPublic;
		  collectionSize = _collectionSize;
	}


	/**
     * Mintlist update by using new merkle root
     */
    function updateMintListHash(bytes32 _newMerkleroot) external onlyTeamMember {
    	merkleRoot = _newMerkleroot;
  	}

  	/*
	 * Regular dev mint without override
	 */
	function teamInitMint(
	  uint256 quantity
	) public 
	  onlyTeamMember {
	  	teamInitMint(msg.sender, quantity, false, 0);
	}

	/*
	 * Emergency override if needed to be called by external contract
	 * To maintain token continuity
	 */
	function teamInitMint(
	  address to,
	  uint256 quantity,
	  bool emergencyOverride,
	  uint256 purchasePriceOverride

	) public 
	  onlyTeamMember {
		if (!emergencyOverride) 
		require(
			quantity <= maxBatchSize,
			"Dev cannot mint more than allocated"
		);
		_safeMint(to, quantity, purchasePriceOverride); // Team mint list price = 0
	}


	/*
	 * Override internal ERC URI 
	 */	
	function _baseURI() internal view virtual override returns (string memory) {
    	return _baseTokenURI;
  	}

	/*
	 * Update BaseURI (for reaveal)
	 */	
	function setBaseURI(string calldata baseURI) external onlyTeamMember {
	  	_baseTokenURI = baseURI;
	}

	/*
	 * Set owners of tokens explicitly with ERC721A
	 */	
	function setOwnersExplicit(uint256 quantity) external onlyTeamMember nonReentrant {
    	_setOwnersExplicit(quantity);
  	}

  	// ------------------------------------------------------------------------
  	// Security and ownership

  	/**
     * Pause functions as needed (in case of exploits)
     */
    function pause() public onlyTeamMember {
        _pause();
    }

    /**
     * Unpause functions as needed 
     */
    function unpause() public onlyTeamMember {
        _unpause();
    }

    /**
     * Add new team meber role with admin permissions
     */
    function addTeamMemberAdmin(address newMember) external onlyTeamMember {
    	teamMember[newMember] = true;
    }

    /**
     * Remove team meber role from admin permissions
     */
    function removeTeamMemberAdmin(address newMember) external onlyTeamMember {
    	teamMember[newMember] = false;
    }

    /**
     * Returns true if address is team member
     */
    function isTeamMemberAdmin(address checkAddress) public view onlyTeamMember returns (bool) {
        return teamMember[checkAddress];
    }


    /**
     * @notice Lock individual functions that are no longer needed
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) public onlyTeamMember {
        functionLocked[id] = true;
    }

}