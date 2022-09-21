// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//  ██████╗  ██████╗ ██████╗ ███████╗    ██████╗  █████╗ ███████╗███████╗
// ██╔═══██╗██╔═══██╗██╔══██╗██╔════╝    ██╔══██╗██╔══██╗██╔════╝██╔════╝
// ██║   ██║██║   ██║██████╔╝███████╗    ██████╔╝███████║███████╗███████╗
// ██║   ██║██║   ██║██╔═══╝ ╚════██║    ██╔═══╝ ██╔══██║╚════██║╚════██║
// ╚██████╔╝╚██████╔╝██║     ███████║    ██║     ██║  ██║███████║███████║
//  ╚═════╝  ╚═════╝ ╚═╝     ╚══════╝    ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝
//                                                   @PoKai Chang(AlexPK)

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
																			 
contract OOPSPass is Ownable, EIP712, ERC721A, ERC721AQueryable {

	using SafeMath for uint256;
	using Strings for uint256;
	
	// Sales variables
	// ------------------------------------------------------------------------
	uint256 public MAX_OOPSPass = 1971;

	bool public hasClaimStarted = false;
	bool public hasBurnStarted = false;

	string private _baseTokenURI = "ipfs://QmbFJvRYoLoFBZ6arE7SXC3iyFnsg1sNMdygKCXqSewZ89/";
	address public signer = 0xA33c4879877fDDc8b7EeC3496928E1C4D974B070;

	mapping (address => uint256) public hasClaimed;

	// Events
	// ------------------------------------------------------------------------
	event mintEvent(address owner, uint256 quantity, uint256 totalSupply);
	
	// Constructor
	// ------------------------------------------------------------------------
	constructor()
	EIP712("OOPS Pass", "1.0.0")
	ERC721A("OOPS Pass", "OOPS-1971"){}  

	// Modifiers
	// ------------------------------------------------------------------------
	modifier callerIsUser() {
		require(tx.origin == msg.sender, "CALLER_IS_CONTRACT");
		_;
	}

	// Airdrop functions
	// ------------------------------------------------------------------------
	function airdrop(address[] calldata _to, uint256[] calldata quantity) public onlyOwner{
		uint256 count = _to.length;

		for (uint256 i = 0; i < count; i++){
			require(totalSupply().add(quantity[i]) <= MAX_OOPSPass, "EXCEEDS_MAX_OOPSPass");
			_safeMint(_to[i], quantity[i]);
			emit mintEvent(_to[i], quantity[i], totalSupply());
		}

	}

	// Verify functions
	// ------------------------------------------------------------------------
	function verify(uint256 maxQuantity, bytes memory SIGNATURE) public view returns (bool){
		address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(keccak256("NFT(address addressForClaim,uint256 maxQuantity)"), _msgSender(), maxQuantity))), SIGNATURE);

		return signer == recoveredAddr;
	}

	// Claim functions
	// ------------------------------------------------------------------------
	function claim(uint256 quantity, uint256 maxClaimNum, bytes memory SIGNATURE) external callerIsUser{
		require(hasClaimStarted == true, "CLAIM_NOT_ACTIVE");
		require(verify(maxClaimNum, SIGNATURE), "NOT_ELIGIBLE_FOR_CLAIM");
		require(quantity > 0 && hasClaimed[msg.sender].add(quantity) <= maxClaimNum, "EXCEEDS_CLAIM_QUANTITY");
		require(totalSupply().add(quantity) <= MAX_OOPSPass, "EXCEEDS_MAX_OOPS");
		
		hasClaimed[msg.sender] = hasClaimed[msg.sender].add(quantity);
		
		_safeMint(msg.sender, quantity);

		emit mintEvent(msg.sender, quantity, totalSupply());
	}

	// Base URI Functions
	// ------------------------------------------------------------------------
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "TOKEN_NOT_EXISTS");
		
		return string(abi.encodePacked(_baseTokenURI));
	}

	// Burn Functions
	// ------------------------------------------------------------------------
	function burn(address account, uint256 id) public virtual {
		require(hasBurnStarted == true, "BURN_NOT_ACTIVE");
		require(account == tx.origin || isApprovedForAll(account, _msgSender()), "CALLER_NOT_NFT_OWNER_NOR_APPROVED");
		require(ownerOf(id) == account, "CALLER_NOT_NFT_OWNER");

		_burn(id);
	}

	// setting functions
	// ------------------------------------------------------------------------
	function setURI(string calldata _tokenURI) external onlyOwner {
		_baseTokenURI = _tokenURI;
	}

	function setMAX_OOPSPass(uint256 _MAX_num) external onlyOwner {
		MAX_OOPSPass = _MAX_num;
	}

	function setSwitch(
		bool _hasClaimStarted, 
		bool _hasBurnStarted
	) external onlyOwner {
		hasClaimStarted = _hasClaimStarted;
		hasBurnStarted = _hasBurnStarted;
	}

	function setSigner(address _signer) external onlyOwner {
		require(_signer != address(0), "SETTING_ZERO_ADDRESS");
		signer = _signer;
	}
}