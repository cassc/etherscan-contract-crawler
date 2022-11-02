// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

// !==== Imports ==== //
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// !==== Contract ==== //
contract CaffeinatedCreatures is ERC721AQueryable, Ownable {

    string  public              customBaseURI; // Variable to override Base URI

    address public              couponSigner; // Address of the wallet that generated the coupons

    uint256 public  constant    maxSupply = 2222; // Maximum tokens available
    uint256 public              reserveSupply = 446; // Reserved tokens

    uint256 public              reservesMinted; // Track reserves minted

    struct MintTypes {
		uint256 _reserveMintsByAddress; // Mint type used to track number of reserve mints by address
        uint256 _allowlistMintsByAddress; // Mint type used to track number of allowlist mints by address
	}
    mapping(address => MintTypes) public addressToMinted;

    struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

    enum CouponType {
		Reserve,
        Allowlist
	}

    enum SalePhase {
        Locked,
        Allowlist,
        Public
    }
    SalePhase   public  phase = SalePhase.Locked; // Set initial phase to "Locked"

    constructor() ERC721A("CaffeinatedCreatures", "CAFF") {}

    // !====== Overrides ====== ** //
    /**
     * * Change Starting Token ID
     * @dev Set starting token ID to 1
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * * Change Base URI
     * @dev Overrides default base URI
     * @notice Default base URI is ""
     */     
    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    // !====== Admin Functions ====== //
    /**
     * * Set Sale Phase
     * @dev Set the phase: Locked, Allowlist, Public
     * @param phase_ The new mint phase
     */
    function setSalePhase(SalePhase phase_) external onlyOwner {
        phase = phase_;
    }

    /**
     * * Set Reserve Supply
     * @dev Set the maximum reserve supply currently available to mint
     * @param reserveSupply_ The new reserve supply available to be minted
     */
    function setReserveSupply(uint256 reserveSupply_) external onlyOwner {
        reserveSupply = reserveSupply_;
    }    

    /**
     * * Set Coupon Signer
     * @dev Set the coupon signing wallet
     * @param couponSigner_ The new coupon signing wallet address
     */
    function setCouponSigner(address couponSigner_) external onlyOwner {
        couponSigner = couponSigner_;
    }

    /**
     * * Set Base URI
     * @dev Set a custom Base URI for token metadata
     * @param newBaseURI_ The new URI to set as the base URI for token metadata
     */
    function setBaseURI(string calldata newBaseURI_) external onlyOwner {
        customBaseURI = newBaseURI_;
    }

    /**
     * * Withdraw Funds
     * @dev Allow owner to withdraw funds
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // !====== Helper Functions ====== //
    /**
     * * Verify Coupon
     * @dev Verify that the coupon sent was signed by the coupon signer and is a valid coupon
     * @notice Valid coupons will include coupon signer, type [Reserve, AllowlistPrime, Allowlist], address, and allotted mints
     * @notice Returns a boolean value
     * @param digest_ The digest
     * @param coupon_ The coupon
     */
	function _isVerifiedCoupon(bytes32 digest_, Coupon memory coupon_) internal view returns (bool) {
		address signer = ecrecover(digest_, coupon_.v, coupon_.r, coupon_.s);
        require(signer != address(0), 'Zero Address');
		return signer == couponSigner;
	}

    // !====== Mint Functions ====== //
    /**
     * * Owner Mint to Address (Airdrop)
     * @dev Allow owner to mint up to Max Supply to specific address(es)
     * @param to_ Address to receive the tokens
     * @param qty_ The number of tokens being minted
     */
    function mintToAddress(address to_, uint256 qty_) external onlyOwner {
        // Owner can mint up to Max Supply at any time
        require(_totalMinted() + qty_ < maxSupply + 1, "Exceeded Max Supply");

        _mint(to_, qty_);
    }

    /**
     * * Mint Reserves
     * @dev Allow "Reserve" coupon holders to mint during any non-Lock phase
     * @notice Valid "Reserve" coupon and available allotment required; allotment control ensures maxSupply will not be exceeded
     * @param qty_ The number of tokens being minted
     * @param coupon_ RSV Coupon
     * @param allotted_ The number of "Reserve" mints allotted to the sender
     */
    function mintReserves(uint256 qty_, Coupon memory coupon_, uint256 allotted_) external {
        // Verify mint phase is not Locked
        require(phase != SalePhase.Locked, "Reserve Mint Not Active");

        // Create a digest to verify against signed coupon
        bytes32 digest = keccak256(
			abi.encode(CouponType.Reserve, allotted_, msg.sender)
		);

        // Verify digest against signed coupon
        require(_isVerifiedCoupon(digest, coupon_), "Invalid Coupon");

        // Verify quantity (including already minted reserves) does not exceed allotted amount
        require(qty_ + addressToMinted[msg.sender]._reserveMintsByAddress < allotted_ + 1, "Exceeds Max Allottment");

        // Increase number of Reserve tokens minted by wallet
        addressToMinted[msg.sender]._reserveMintsByAddress += qty_;

        // Increase number of total Reserve tokens minted
        reservesMinted += qty_;

        // Mint tokens
        _mint(msg.sender, qty_);
    }

    /**
     * * Mint Allowlist
     * @dev Allow "Allowlist" coupon holders to mint during Allowlist phase
     * @notice Valid "Allowlist" coupon and available allotment required
     * @param coupon_ RSV Coupon
     * @param allotted_ The number of "Allowlist" mints allotted to the sender
     */
    function mintAllowlist(Coupon memory coupon_, uint256 allotted_) external {

         // Verify mint phase is set to Allowlist
        require(phase == SalePhase.Allowlist, "Allowlist Prime Mint Not Active");

        // Create a digest to verify against signed coupon
        bytes32 digest = keccak256(
			abi.encode(CouponType.Allowlist, allotted_, msg.sender)
		);

        // Verify digest against signed coupon
        require(_isVerifiedCoupon(digest, coupon_), "Invalid Coupon");

        // Verify quantity (including already minted allotment) does not exceed allotted amount
        require(addressToMinted[msg.sender]._allowlistMintsByAddress < allotted_, "Exceeds Max Allottment");

        // Verify mint does not cause _totalMinted() to exceed maxSupply (excluding reserveSupply)
        require(_totalMinted() - reservesMinted < maxSupply - reserveSupply, "Exceeds Max Supply");

        // Increment number of allowlist tokens minted by wallet
        addressToMinted[msg.sender]._allowlistMintsByAddress += 1;

        // Mint tokens
        _mint(msg.sender, 1);
    }

    /**
     * * Mint
     * @dev Allow public minting during Public phase
     */
    function mint() external {

        // Verify mint phase is set to Public
        require(phase == SalePhase.Public, "Public Mint Phase Not Active");

        // Limit max public per wallet to 2
        require(_numberMinted(msg.sender) - addressToMinted[msg.sender]._allowlistMintsByAddress - addressToMinted[msg.sender]._reserveMintsByAddress < 2, "Exceeded Max Per Wallet");

        // Verify mint does not cause _totalMinted() to exceed maxSupply (excluding reserveSupply)
        require(_totalMinted() - reservesMinted < maxSupply - reserveSupply, "Exceeds Max Supply");

        // Mint tokens
        _mint(msg.sender, 1);
    }
    
}