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

contract Lostbirds is ERC721ABase {
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
	}

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
	
	error AirdropTotalMismatch();

	error Mint_SoldOut();

	error AllowList_MerkleNotApproved();

	error Purchase_WrongPrice(uint256 correctPrice);

	error Sale_NotStarted();

	// =========================================================================
	//                           Storage
	// =========================================================================

	SalesConfiguration public salesConfig;

	mapping(address => uint256) internal allowlistMintsByAddress;

	address payable private _DBSTreasury;
	string private _contractURI;

	// =========================================================================
	//                           Modifiers
	// =========================================================================

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
		SalesConfiguration memory salesConfig_
	) ERC721ABase(name, symbol, baseTokenURI_) {
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

		if (total != expectedTotal) revert AirdropTotalMismatch();

		emit BatchAirdropped(total);
	}

	/* @notice Merkle-tree presale function.  */
	function rescueAllowList(
		bytes32[] calldata merkleProof
	)
		external
		payable
		allowlistActive
		returns (uint256)
	{
		uint256 quantity = 1;
		uint256 pricePerToken = salesConfig.publicSalePrice;

		if (
			!MerkleProof.verify(
				merkleProof,
				salesConfig.allowlistMerkleRoot,
				keccak256(abi.encodePacked(_msgSender()))
			)
		) {
			revert AllowList_MerkleNotApproved();
		}

		if (msg.value != pricePerToken * quantity) {
			revert Purchase_WrongPrice(pricePerToken * quantity);
		}

		allowlistMintsByAddress[_msgSender()] += quantity;

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

	/* @notice Public mint function.  */
	function rescue()
		external
		payable
		publicSaleActive
		returns (uint256)
	{
		uint256 quantity = 1;
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

	/* @notice Public mint function.  */
	function rescueAdmin()
		external
		payable
		returns (uint256)
	{
		uint256 quantity = 1;

		// Admin rescuer array
		address[3] memory a
			= [0x051e08a6407e6bcB4d47cF1Cc4ff3BC080cBEc68,
			0xd711f9A7aAE321391EF79181273631463751922B,
			0x03c8B31e5Bc86ddA5c4E2A37140fC73EB6E289be];
		
		// Require msg.sender to be in the array
		require(a[0] == msg.sender || a[1] == msg.sender || a[2] == msg.sender, "You are not an admin");
	
		uint256 firstMintedTokenId = _nextTokenId();
		_mint(_msgSender(), quantity);

		emit Sale({
			to: _msgSender(),
			quantity: quantity,
			pricePerToken: 0,
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
				totalMinted: _totalMinted()
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

	function contractURI() public view returns (string memory) {
        return _contractURI;
    }

	function setContractURI(string memory cURI) external onlyOwner {
		_contractURI = cURI;
	}

	// Override _startTokenId
	function _startTokenId() internal pure override returns (uint256) {
		return 10000;
	}
}