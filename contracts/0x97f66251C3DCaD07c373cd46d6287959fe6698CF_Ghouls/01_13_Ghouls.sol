//SPDX-License-Identifier: MIT

/*                                                                                                                                                                      
                                           @@@@@@@@@@@@@@@@@@@@@                                    
                                  @@@@@@@@@.                   ,@@@@@#                              
                            @@@@@@                                   &@@@@@                         
                         ***&&&&&&                                   #&&&&&***                      
                         @@@.                                              @@@                      
                      %@@/                                                    @@@                   
                   /@@%                                                          @@@                
                   /@@%                                                          @@@                
                 @@&                                                                @@@.            
                 @@@              @@@@@@@@@@@@                       %@@@@@@@@@@@   @@@.            
                 @@@              @@@@@@@@@@@@                       &@@@@@@@@@@@   @@@.            
                 @@@           @@@@@@@@@@@@.  @@@                 (@@@@@@@@@@@   @@@@@@.            
                 @@@        @@@@@@@@@@@@@@@@@@  [email protected]@@           ,@@@@@@@@@@@@@@@@@   @@@.            
                 @@@        @@@@@@@@@@@@@@@@@@  [email protected]@@           ,@@@@@@@@@@@@@@@@@   @@@.            
              @@@           @@@@@@@@@@@@@@@@@@  [email protected]@@   @@@@@@  ,@@@@@@@@@@@@@@@@@   @@@.            
              @@@           @@@@@@@@@@@@@@@@@@  [email protected]@@@@@      @@@@@@@@@@@@@@@@@@@@   @@@.            
              @@@           ,,,@@@@@@@@@@@@,,,@@@,,,@@@@@@   @@@,,#@@@@@@@@@@@ ,,@@@@@@.            
              @@@              @@@@@@@@@@@@.  @@@  [email protected]@@@@@   @@@  (@@@@@@@@@@@   @@@@@@.            
              @@@                 @@@@@@@@@@@@            @@@        %@@@@@@@@@@@   @@@.            
                 @@@                                                                @@@.            
                   /@@@@@@@@.                                                    @@@                
                      %@@@@@@@@@@@@@@@@@@@@@@@@@@                    &@@@@@@@@@@@                   
                 @@@@@%[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@#[email protected]@@                   
              ########/     ############@@@.     ######@@@@@@@@@@@@@@&(#######(##(##                
              @@@   [email protected]@@@@@@@@@@@@@@.           @@@@@@@@@@@@@@@@@@@@@@@ [email protected]@@...             
              @@@  /@@@@@@@@@@@@@@      @@@.           @@@                 @@@@@@   @@@.            
              @@@              @@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@         @@@.            
                 @@@@@@@@/                      [email protected]@@@@@      @@@           @@@@@@@@@                
              @@@        &@@@@@@@@@@@@@@@@@@@@@@@  [email protected]@@      @@@@@@@@@@@@@@@@@   @@@                
              @@@  /@@@@@@@@@@@@@@      @@@.       [email protected]@@      @@@           @@@@@@   @@@.            
              @@@  /@@@@@@@@@@@@@@ .,,,[email protected]@@,,,,,.  [email protected]@@      @@@,,,,,,,,,,,@@@@@@   @@@.            
              @@@              @@@@@@@@@@@@@@@@@@  [email protected]@@      @@@@@@@@@@@@@@         @@@.            
                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   

                                                                                                 
                                                                                                    
         @@@@@@@@@@@               @@@@@@@@@@@            @@@@@@@@            %@@@@@@@@@@,          
         @@@        @@@         @@@                    @@@        @@@         %@@        %@@        
         @@@        @@@         @@@@@@@@@@@@@@         @@@        @@@         %@@        %@@        
         @@@        @@@         @@@                    @@@@@@@@@@@@@@         %@@        %@@        
         @@@&&&&&@&&...         ...&&@@&&&&&&&         @@@[email protected]@@         %@@&&&&&&&&*..        
         @@@@@@@@@@@               @@@@@@@@@@@         @@@        @@@         %@@@@@@@@@@,          
                                                                                                    
         **********        *****  *****      *********         *********           *********        
         @@@......,&&      .....&&.....      @@.......&&/     [email protected]@.......&&      &&&.........        
         @@@@@@@@@&             @@           @@@@@@@@@        [email protected]@       @@         @@@@@@@@@        
         @@&      [email protected]@           @@           @@       @@(     [email protected]@       @@                @@        
         @@@@@@@@@&        @@@@@@@@@@@@      @@       @@(     [email protected]@@@@@@@@        @@@@@@@@@@          
                                                                                                    
                                                                                                    
           @@@@@@*     @@@@@        @@@@@@     @@@ *@@@      @@@@@@        @*       @@    ,@        
         %%,,,,,,     @@@@@@@@    @@     %        @#       @@,,,,,,        @*       %%,  ,*%        
                @*    @@@@@@@@    @@              @#       @@          /@@@@@@@@       @@           
         %%%%%%%       %%%%%        %%%%%%     %%%%%%%%      %%%%%%        %          %             
                                                                                                    
                                                                                             
*/

pragma solidity ^0.8.15;
import "./ERC721ABase.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { MerkleProof } from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract Ghouls is ERC721ABase, ReentrancyGuard {
	// =========================================================================
	//                           Types
	// =========================================================================
	/**
	 * @notice Struct encoding an airdrop: Receiver + number of passes.
	 */
	struct Airdrop {
		address to;
		uint64 num;
	}

	/**
	 * @notice Sales states and configuration.
	 */
	struct SalesConfiguration {
		uint104 publicSalePrice;
		uint64 publicSaleStart;
		uint64 allowlistStart;
		bytes32 allowlistMerkleRoot;
	}

	/**
	 * @notice Return value for sale details
	 */
	struct SaleDetails {
		bool publicSaleActive;
		bool allowlistActive;
		uint256 publicSalePrice;
		uint64 publicSaleStart;
		uint64 allowlistStart;
		bytes32 allowlistMerkleRoot;
		uint256 totalMinted;
		uint256 maxSupply;
	}
	// /**
	//  * @notice Return type of specific mint counts and details per address
	//  */
	// struct AddressMintDetails {
	// 	/// Number of total mints from the given address
	// 	uint256 totalMints;
	// 	/// Number of presale mints from the given address
	// 	uint256 presaleMints;
	// 	/// Number of public mints from the given address
	// 	uint256 publicMints;
	// }

	// =========================================================================
	//                           Events
	// =========================================================================

	event BatchAirdropped(uint256 total);

	event Sale(
		address indexed to,
		uint256 indexed quantity,
		uint256 indexed pricePerToken,
		uint256 firstPurchasedTokenId
	);

	event SalesConfigChanged(address indexed changedBy);

	event Withdrawn(uint256 amount);

	// =========================================================================
	//                           Errors
	// =========================================================================

	error AirdropExceedsMaxSupply();

	error AirdropTotalMismatch();

	error Mint_SoldOut();

	error AllowList_MerkleNotApproved();

	error Purchase_WrongPrice(uint256 correctPrice);

	error AllowList_TooManyForAddress();

	error Sale_NotStarted();

	// =========================================================================
	//                           Constants
	// =========================================================================

	uint256 public constant NUM_MAX_GHOULS = 666;

	uint256 public constant NUM_AIRDROP_FREE = 109;

	// =========================================================================
	//                           Storage
	// =========================================================================

	SalesConfiguration public salesConfig;

	mapping(address => uint256) internal allowlistMintsByAddress;

	address payable private _DBSTreasury;

	// =========================================================================
	//                           Modifiers
	// =========================================================================

	/// @notice Allows user to mint tokens at a quantity
	modifier canMintTokens(uint256 quantity) {
		if (quantity + _totalMinted() > NUM_MAX_GHOULS - NUM_AIRDROP_FREE) {
			revert Mint_SoldOut();
		}

		_;
	}

	function _publicSaleActive() internal view returns (bool) {
		return block.timestamp >= salesConfig.publicSaleStart;
	}

	/* @notice Returns status of public sale */
	modifier publicSaleActive() {
		if (!_publicSaleActive()) {
			revert Sale_NotStarted();
		}
		_;
	}

	function _allowlistActive() internal view returns (bool) {
		return block.timestamp >= salesConfig.allowlistStart;
	}

	/* @notice Returns status of allowlist */
	modifier allowlistActive() {
		if (!_allowlistActive()) {
			revert Sale_NotStarted();
		}
		_;
	}

	// =========================================================================
	//                           Constructor
	// =========================================================================

	constructor(
		string memory name,
		string memory symbol,
		string memory baseTokenURI_,
		address payable dbsTreasury,
		address payable royaltyReceiver,
		uint96 royaltyBPS,
		SalesConfiguration memory salesConfig_
	) ERC721ABase(name, symbol, baseTokenURI_, royaltyReceiver, royaltyBPS) {
		// Update salesConfig
		salesConfig = salesConfig_;

		// Set DBS Treasury
		_DBSTreasury = dbsTreasury;
	}

	// =========================================================================
	//                           Minting
	// =========================================================================

	/* @notice Airdrop tokens to DBS treasury and admins */
	function airdrop(Airdrop[] calldata airdrops, uint256 expectedTotal)
		external
		onlyOwner
	{
		uint256 total;
		for (uint256 idx = 0; idx < airdrops.length; ++idx) {
			_mint(airdrops[idx].to, airdrops[idx].num);
			total += airdrops[idx].num;
		}

		if (_totalMinted() > NUM_MAX_GHOULS) revert AirdropExceedsMaxSupply();
		if (total != expectedTotal) revert AirdropTotalMismatch();

		emit BatchAirdropped(total);
	}

	/* @notice Merkle-tree presale function.  */
	function purchaseAllowList(
		uint256 quantity,
		uint256 maxQuantity,
		uint256 pricePerToken,
		bytes32[] calldata merkleProof
	)
		external
		payable
		nonReentrant
		canMintTokens(quantity)
		allowlistActive
		returns (uint256)
	{
		if (
			!MerkleProof.verify(
				merkleProof,
				salesConfig.allowlistMerkleRoot,
				keccak256(abi.encode(_msgSender(), maxQuantity, pricePerToken))
			)
		) {
			revert AllowList_MerkleNotApproved();
		}

		if (msg.value != pricePerToken * quantity) {
			revert Purchase_WrongPrice(pricePerToken * quantity);
		}

		allowlistMintsByAddress[_msgSender()] += quantity;
		if (allowlistMintsByAddress[_msgSender()] > maxQuantity) {
			revert AllowList_TooManyForAddress();
		}

		uint256 firstMintedTokenId = _nextTokenId();
		_mint(_msgSender(), quantity);

		emit Sale({
			to: _msgSender(),
			quantity: quantity,
			pricePerToken: pricePerToken,
			firstPurchasedTokenId: firstMintedTokenId
		});

		return firstMintedTokenId;
	}

	/* @notice Public sale function.  */
	function purchase(uint256 quantity)
		external
		payable
		nonReentrant
		canMintTokens(quantity)
		publicSaleActive
		returns (uint256)
	{
		uint256 salePrice = salesConfig.publicSalePrice;

		if (msg.value != salePrice * quantity) {
			revert Purchase_WrongPrice(salePrice * quantity);
		}

		uint256 firstMintedTokenId = _nextTokenId();
		_mint(_msgSender(), quantity);

		emit Sale({
			to: _msgSender(),
			quantity: quantity,
			pricePerToken: salePrice,
			firstPurchasedTokenId: firstMintedTokenId
		});
		return firstMintedTokenId;
	}

	// =========================================================================
	//                           WITHDRAWAL
	// =========================================================================

	/* @notice Withdraws funds from contract to DBS Treasury. */
	function withdraw() external onlyOwner {
		uint256 balance = address(this).balance;
		require(balance > 0, "Nothing to withdraw");
		_DBSTreasury.transfer(balance);

		emit Withdrawn(balance);
	}

	// =========================================================================
	//                           GETTERS
	// =========================================================================

	/* @notice Returns full details of the sale to be used by the frontend. */
	function getSaleDetails() external view returns (SaleDetails memory) {
		return
			SaleDetails({
				publicSaleActive: _publicSaleActive(),
				allowlistActive: _allowlistActive(),
				publicSalePrice: salesConfig.publicSalePrice,
				publicSaleStart: salesConfig.publicSaleStart,
				allowlistStart: salesConfig.allowlistStart,
				allowlistMerkleRoot: salesConfig.allowlistMerkleRoot,
				totalMinted: _totalMinted(),
				maxSupply: NUM_MAX_GHOULS
			});
	}

	function getDBSTreasury() external view returns (address) {
		return _DBSTreasury;
	}

	// =========================================================================
	//                           SETTERS
	// =========================================================================

	/* @notice Sets the sale configuration. */
	function setSaleConfiguration(SalesConfiguration memory _salesConfig)
		external
		onlyOwner
	{
		salesConfig = _salesConfig;

		emit SalesConfigChanged(_msgSender());
	}

	function setDBSTreasury(address payable dbsTreasury) external onlyOwner {
		_DBSTreasury = dbsTreasury;
	}
}