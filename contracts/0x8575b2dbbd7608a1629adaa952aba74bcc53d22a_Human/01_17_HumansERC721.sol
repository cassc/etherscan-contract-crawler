// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author: HodlCaulfield
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import './RandomlyAssigned.sol';

/*
  __    __   ____  ____  ___      ___       __      _____  ___    ________  
 /" |  | "\ ("  _||_ " ||"  \    /"  |     /""\    (\"   \|"  \  /"       ) 
(:  (__)  :)|   (  ) : | \   \  //   |    /    \   |.\\   \    |(:   \___/  
 \/      \/ (:  |  | . ) /\\  \/.    |   /' /\  \  |: \.   \\  | \___  \    
 //  __  \\  \\ \__/ // |: \.        |  //  __'  \ |.  \    \. |  __/  \\   
(:  (  )  :) /\\ __ //\ |.  \    /:  | /   /  \\  \|    \    \ | /" \   :)  
 \__|  |__/ (__________)|___|\__/|___|(___/    \___)\___|\____\)(_______/   
                                                                            
               ';;;;;'                                                              
            ~uPPK%ggg%qwz,                                                           
         '7WN%%%gg%%DDbqADX*'                               ,~LDQQQQXj>.             
       =6QQ8%%%%%%%%%%%%%DKKKy;                           rUBQ8%MW#NgDDKy~           
      |QQ#%%%%%%%%%%%g%%%%%DqWK`                         L#QgRNWR%%##%Rb%q!          
      MQQN%%%%%%ggggRDDDRg%%RqgD                         WQQBQ8bR8QQQB8&DQj          
      6QQQN%%%%ggDbKDDDRRDR%%D8D                      ,[email protected]@@[email protected]@[email protected]~``         
      `[email protected]%NQ8dqkmSmSSPRN%MNQR;                      %[email protected]@@[email protected]            
       ,[email protected]#BQRDRXgQd%g&@Q8|'                       LdkQ%[email protected]@WDS;`            
         ;[email protected]~                          `[email protected]%Xi'              
           ,;x%RUPm6%UmKb7'                              ,RQBdPm%%QDXI_              
              'PBK%QgUn_                                 u%dqQgK%K%DZaQ7             
           ^jXywUwwk6Sz~                                ?%dRP^XNPmSXRbQc             
          zDZPR5I5SSwz{Qx                               ;fKdm|UMXwfjQ#Q7 `````       
         ;DAKdvSPYSmsPdQt                                 ,\6KD8BKjyQgWi,,,:,,'`     
         =yodPrPqfPStNBQt                                    XQQQQu=;D}!L7c*==r!,    
           ,\Dg%DqSu7N%RP~                                  yP7\i*r^~dn^|Li||\7?'    
             .PQdqWq\nN&Qy`                                 qm>^^*|r~di`,;;;^^~.     
              wbZRKkPZQQXNy                                 qB%m;.'wdQi              
             =qdKBuzDwQn;;`                                 [email protected]   [email protected]              
             X%q8| ,q6Q7                                    [email protected]   [email protected]'             
             XWQJ   66#7                                 `''[email protected]@7   `[email protected]@I'`           
             XgQJ   ADNo,                              `[email protected]    [email protected]@Qmyi         
             k#QJ   ,UMQJ                              `BQQQBDQ7    [email protected]         
          DQNDKQJ    XQDDQy                             mDKqKkd=    YDKKKUKc       

    ______    _______    				  _____  ___    _______  ___________               
   /    " \  /"     "|   				 (\"   \|"  \  /"     "|("     _   ")              
  // ____  \(: ______)   				 |.\\   \    |(: ______) )__/  \\__/               
 /  /    ) :)\/    |     				 |: \.   \\  | \/    |      \\_ /                  
(: (____/ // // ___)     				 |.  \    \. | // ___)      |.  |                  
 \        / (:  (       				  |    \    \ |(:  (         \:  |                  
  \"_____/   \__/        				  \___|\____\) \__/          \__| 
*/

contract Human is ERC721, ERC1155Holder, Ownable, RandomlyAssigned {
	using Strings for uint256;

	/*
	 * Private Variables
	 */
	uint256 private constant NUMBER_OF_GENESIS_HUMANS = 229; // there are 229 Humans in the Genesis Collection
	uint256 private constant NUMBER_OF_RESERVED_HUMANS = 35;
	uint256 private constant MAX_HUMANS_SUPPLY = 1500; // collection size (including genesis and honoraries)
	uint256 private constant MAX_TEAM_HUMANS = 69; // reserved for the team and marketing
	uint256 private constant MAX_MINTS_PER_ADDRESS = 4; // max total mints (incl. presale, excl. author and genesis claims)
	uint256 private constant MAX_PRESALE_MINTS_PER_ADDRESS = 2; // max mints during presale per address

	struct MintTypes {
		uint256 _numberOfAuthorMintsByAddress;
		uint256 _numberOfMintsByAddress;
	}

	struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

	enum CouponType {
		Genesis,
		Author,
		Presale
	}

	enum SalePhase {
		Locked,
		PreSale,
		PublicSale
	}

	address private immutable _teamAddress =
		0x5ad0A1eA6d7863c3930a0125bC22770A358Ebee9;

	address private immutable _adminSigner;
	address private immutable _openseaSharedContractAddress;

	string private _defaultUri;

	string private _tokenBaseURI;

	/*
	 * Public Variables
	 */

	bool public claimActive = false;
	bool public metadataIsFrozen = false;

	SalePhase public phase = SalePhase.Locked;

	uint256 public mintPrice = 0.025 ether;
	uint256 public teamTokensMinted;

	mapping(address => MintTypes) public addressToMints;

	/*
	 * Constructor
	 */
	constructor(
		string memory uri,
		address adminSigner,
		address openseaAddress
	)
		ERC721('Humans Of NFT', 'HUMAN')
		RandomlyAssigned(
			MAX_HUMANS_SUPPLY,
			NUMBER_OF_GENESIS_HUMANS + NUMBER_OF_RESERVED_HUMANS
		)
	{
		_defaultUri = uri;
		_adminSigner = adminSigner;
		_openseaSharedContractAddress = openseaAddress;
	}

	// ======================================================== Owner Functions

	/// Set the base URI for the metadata
	/// @dev modifies the state of the `_tokenBaseURI` variable
	/// @param URI the URI to set as the base token URI
	function setBaseURI(string memory URI) external onlyOwner {
		require(!metadataIsFrozen, 'Metadata is permanently frozen');
		_tokenBaseURI = URI;
	}

	/// Freezes the metadata
	/// @dev sets the state of `metadataIsFrozen` to true
	/// @notice permamently freezes the metadata so that no more changes are possible
	function freezeMetadata() external onlyOwner {
		require(!metadataIsFrozen, 'Metadata is already frozen');
		metadataIsFrozen = true;
	}

	/// Adjust the mint price
	/// @dev modifies the state of the `mintPrice` variable
	/// @notice sets the price for minting a token
	/// @param newPrice_ The new price for minting
	function adjustMintPrice(uint256 newPrice_) external onlyOwner {
		mintPrice = newPrice_;
	}

	/// Advance Phase
	/// @dev Advance the sale phase state
	/// @notice Advances sale phase state incrementally
	function enterPhase(SalePhase phase_) external onlyOwner {
		require(uint8(phase_) > uint8(phase), 'can only advance phases');
		phase = phase_;
	}

	/// Activate claiming
	/// @dev set the state of `claimActive` variable to true
	/// @notice Activate the claiming event
	function activateClaiming() external onlyOwner {
		claimActive = true;
	}

	/// Reserve tokens for the team + marketing
	/// @dev Mints the number of tokens passed in as count to the _teamAddress
	/// @param count The number of tokens to mint
	function devReserveTokens(uint256 count)
		external
		onlyOwner
		ensureAvailabilityFor(count)
	{
		require(
			count + teamTokensMinted <= MAX_TEAM_HUMANS,
			'Exceeds the reserved supply of team tokens'
		);
		for (uint256 i = 0; i < count; i++) {
			_mintRandomId(_teamAddress);
		}
		teamTokensMinted += count;
	}

	/// Disburse payments
	/// @dev transfers amounts that correspond to addresses passeed in as args
	/// @param payees_ recipient addresses
	/// @param amounts_ amount to payout to address with corresponding index in the `payees_` array
	function disbursePayments(
		address[] memory payees_,
		uint256[] memory amounts_
	) external onlyOwner {
		require(
			payees_.length == amounts_.length,
			'Payees and amounts length mismatch'
		);
		for (uint256 i; i < payees_.length; i++) {
			makePaymentTo(payees_[i], amounts_[i]);
		}
	}

	/// Make a payment
	/// @dev internal fn called by `disbursePayments` to send Ether to an address
	function makePaymentTo(address address_, uint256 amt_) private {
		(bool success, ) = address_.call{value: amt_}('');
		require(success, 'Transfer failed.');
	}

	// ======================================================== External Functions

	/// Claim Genesis Tokens
	/// @dev mints genesis token IDs using verified coupons signed by an admin address
	/// @notice uses the the coupon supplied to confirm that only the owner of the original ID can claim
	/// @param idxsToClaim the indexes for the IDs array of the tokens claimed in this TX
	/// @param idsOfOwner IDs of genesis tokens belonging to the caller used to verify the coupon
	/// @param coupon coupon for verifying the signer
	function claimReservedTokensByIds(
		address owner_,
		uint256[] calldata idxsToClaim,
		uint256[] calldata idsOfOwner,
		Coupon memory coupon
	) external {
		require(claimActive, 'Claim event is not active');
		bytes32 digest = keccak256(
			abi.encode(CouponType.Genesis, idsOfOwner, owner_)
		);
		require(_isVerifiedCoupon(digest, coupon), 'Invalid coupon');

		for (uint256 i; i < idxsToClaim.length; i++) {
			uint256 tokenId = idsOfOwner[idxsToClaim[i]];
			_claimReservedToken(owner_, tokenId);
		}
	}

	/// Claim Author Tokens
	/// @dev mints the qty of tokens verified using coupons signed by an admin signer
	/// @notice claims free tokens earned by Authors
	/// @param count number of tokens to claim in transaction
	/// @param allotted total number of tokens author is allowed to claim
	/// @param coupon coupon for verifying the signer
	function claimAuthorTokens(
		uint256 count,
		uint256 allotted,
		Coupon memory coupon
	) public ensureAvailabilityFor(count) {
		require(claimActive, 'Claim event is not active');
		bytes32 digest = keccak256(
			abi.encode(CouponType.Author, allotted, msg.sender)
		);
		require(_isVerifiedCoupon(digest, coupon), 'Invalid coupon');
		require(
			count + addressToMints[msg.sender]._numberOfAuthorMintsByAddress <=
				allotted,
			'Exceeds number of earned Tokens'
		);
		addressToMints[msg.sender]._numberOfAuthorMintsByAddress += count;
		for (uint256 i; i < count; i++) {
			_mintRandomId(msg.sender);
		}
	}

	/// Mint during presale
	/// @dev mints by addresses validated using verified coupons signed by an admin signer
	/// @notice mints tokens with randomized token IDs to addresses eligible for presale
	/// @param count number of tokens to mint in transaction
	/// @param coupon coupon signed by an admin coupon
	function mintPresale(uint256 count, Coupon memory coupon)
		external
		payable
		ensureAvailabilityFor(count)
		validateEthPayment(count)
	{
		require(phase == SalePhase.PreSale, 'Presale event is not active');
		require(
			count + addressToMints[msg.sender]._numberOfMintsByAddress <=
				MAX_PRESALE_MINTS_PER_ADDRESS,
			'Exceeds number of presale mints allowed'
		);
		bytes32 digest = keccak256(abi.encode(CouponType.Presale, msg.sender));
		require(_isVerifiedCoupon(digest, coupon), 'Invalid coupon');

		addressToMints[msg.sender]._numberOfMintsByAddress += count;

		for (uint256 i; i < count; i++) {
			_mintRandomId(msg.sender);
		}
	}

	/// Public minting open to all
	/// @dev mints tokens during public sale, limited by `MAX_MINTS_PER_ADDRESS`
	/// @notice mints tokens with randomized IDs to the sender's address
	/// @param count number of tokens to mint in transaction
	function mint(uint256 count)
		external
		payable
		validateEthPayment(count)
		ensureAvailabilityFor(count)
	{
		require(phase == SalePhase.PublicSale, 'Public sale is not active');
		require(
			count + addressToMints[msg.sender]._numberOfMintsByAddress <=
				MAX_MINTS_PER_ADDRESS,
			'Exceeds maximum allowable mints'
		);
		addressToMints[msg.sender]._numberOfMintsByAddress += count;
		for (uint256 i; i < count; i++) {
			_mintRandomId(msg.sender);
		}
	}

	/// override ERC1155Received to mint replacement tokens
	/// @dev receive a verified token and mint its replacement
	/// @param from the account who initiated the transfer and will claim the mint
	/// @param id the opensea token ID
	/// @param data encoded genesis ID and coupon
	function onERC1155Received(
		address,
		address from,
		uint256 id,
		uint256,
		bytes memory data
	) public virtual override returns (bytes4) {
		require(
			msg.sender == _openseaSharedContractAddress,
			'Sender not approved'
		);
		(uint256 genesisId, Coupon memory coupon) = abi.decode(
			data,
			(uint256, Coupon)
		);

		bytes32 digest = keccak256(
			abi.encode(CouponType.Genesis, genesisId, id)
		);
		require(_isVerifiedCoupon(digest, coupon), 'Invalid coupon');
		_claimReservedToken(from, genesisId);
		return this.onERC1155Received.selector;
	}

	/// Override the batch receive
	/// @dev revert as nobody should ever call this and we don't want the contract to receive any other tokens
	function onERC1155BatchReceived(
		address,
		address,
		uint256[] memory,
		uint256[] memory,
		bytes memory
	) public override returns (bytes4) {
		revert('Batch Receiving not allowed.');
	}

	// ======================================================== Overrides

	/// Return the tokenURI for a given ID
	/// @dev overrides ERC721's `tokenURI` function and returns either the `_tokenBaseURI` or a custom URI
	/// @notice reutrns the tokenURI using the `_tokenBase` URI if the token ID hasn't been suppleid with a unique custom URI
	function tokenURI(uint256 tokenId)
		public
		view
		override(ERC721)
		returns (string memory)
	{
		require(_exists(tokenId), 'Cannot query non-existent token');

		return
			bytes(_tokenBaseURI).length > 0
				? string(
					abi.encodePacked(_tokenBaseURI, '/', tokenId.toString())
				)
				: _defaultUri;
	}

	/// override supportsInterface because two base classes define it
	/// @dev See {IERC165-supportsInterface}.
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC721, ERC1155Receiver)
		returns (bool)
	{
		return
			ERC721.supportsInterface(interfaceId) ||
			ERC1155Receiver.supportsInterface(interfaceId);
	}

	// ======================================================== Internal Functions

	/// @dev check that the coupon sent was signed by the admin signer
	function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon)
		internal
		view
		returns (bool)
	{
		// address signer = digest.recover(signature);
		address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
		require(signer != address(0), 'ECDSA: invalid signature'); // Added check for zero address
		return signer == _adminSigner;
	}

	/// @dev internal check to ensure a genesis token ID, or ID outside of the collection, doesn't get minted
	function _mintRandomId(address to) private {
		uint256 id = nextToken();
		assert(
			id > NUMBER_OF_GENESIS_HUMANS + NUMBER_OF_RESERVED_HUMANS &&
				id <= MAX_HUMANS_SUPPLY
		);
		_safeMint(to, id);
	}

	/// @dev mints a token with a known ID, must fall within desired range
	function _claimReservedToken(address to, uint256 id) internal {
		assert(id != 0);
		assert(id <= NUMBER_OF_GENESIS_HUMANS + NUMBER_OF_RESERVED_HUMANS);
		if (!_exists(id)) {
			_safeMint(to, id);
		}
	}

	// ======================================================== Modifiers

	/// Modifier to validate Eth payments on payable functions
	/// @dev compares the product of the state variable `_mintPrice` and supplied `count` to msg.value
	/// @param count factor to multiply by
	modifier validateEthPayment(uint256 count) {
		require(
			mintPrice * count <= msg.value,
			'Ether value sent is not correct'
		);
		_;
	}
} // End of Contract