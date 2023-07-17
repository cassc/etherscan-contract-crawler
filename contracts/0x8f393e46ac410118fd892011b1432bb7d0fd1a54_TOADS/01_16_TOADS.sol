// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ERC721A.sol";

contract TOADS is Ownable, ERC721A, ReentrancyGuard {
    using SafeERC20 for IERC20;
	
	uint256 public SALE_NFT = 3500;
	uint256 public RESERVED_NFT = 821;
	
	uint256 public MAX_MINT_SALE = 10;
	uint256 public MAX_BY_MINT_IN_TRANSACTION_SALE = 5;
	
	uint256 public SALE_PRICE =  0.05 ether;
	
	address public USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
	
	uint256 public SALE_MINTED;
	uint256 public RESERVED_MINTED;
	
	bool public saleEnable = false;
	uint256 public precisionFactor = 1 * 10**18;
	uint256 public accTokenPerShare;
	
	string public _baseTokenURI;
	
	struct airdropInfo{
	  uint256 rewardDebt;
    }
	
	struct User {
	  uint256 salemint;
    }
	
	mapping (address => User) public users;
	mapping(uint256 => airdropInfo) public mapAirdropInfo;
    constructor() ERC721A("Toad Friends", "TOADS"){}
	
	function mintReservedNFT(address[] calldata _to, uint256[] calldata _count) external onlyOwner nonReentrant{
        require(
		  _to.length == _count.length,
		  "Mismatch between Address and count"
		);
		for(uint i=0; i < _to.length; i++) {
		    require (
			  RESERVED_MINTED + _count[i] <= RESERVED_NFT, 
			  "Max limit reached"
			);
			
			uint256 totalSupply = totalSupply();
			for (uint256 j = 0; j < _count[i]; j++) 
			{
		       mapAirdropInfo[totalSupply + j].rewardDebt += accTokenPerShare / precisionFactor ;
			}
		    _safeMint(_to[i], _count[i]);
		    RESERVED_MINTED += _count[i];
		}
    }
	
    function mintSaleNFT(uint256 _count) public payable nonReentrant{
		require(
		  saleEnable, 
		  "Sale is not enable"
		);
        require(
		  SALE_MINTED + _count <= SALE_NFT, 
		  "Exceeds max limit"
		);
		require(
		  users[msg.sender].salemint + _count <= MAX_MINT_SALE,
		  "Exceeds max mint limit per wallet"
		);
		require(
		  _count <= MAX_BY_MINT_IN_TRANSACTION_SALE,
		  "Exceeds max mint limit per txn"
		);
		require(
		  msg.value >= SALE_PRICE * _count,
		  "Value below price"
		);
		
		uint256 totalSupply = totalSupply();
		for(uint256 i = 0; i < _count; i++) 
		{
		    mapAirdropInfo[totalSupply + i].rewardDebt += accTokenPerShare / precisionFactor ;
        }
		_safeMint(msg.sender, _count);
	    SALE_MINTED += _count;
		users[msg.sender].salemint += _count;
    }
	
    function _baseURI() internal view virtual override returns (string memory) {
	   return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
	    _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
       uint256 balance = address(this).balance;
       payable(msg.sender).transfer(balance);
    }
	
    function numberMinted(address owner) public view returns (uint256) {
	   return _numberMinted(owner);
    }
	
	function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
	   return ownershipOf(tokenId);
	}
	
	function updateSalePrice(uint256 newPrice) external onlyOwner {
        SALE_PRICE = newPrice;
    }
	
	function setSaleStatus(bool status) public onlyOwner {
        require(saleEnable != status);
		saleEnable = status;
    }
	
	function updateSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_MINT_SALE = newLimit;
    }
	
	function updateMintLimitPerTransactionSale(uint256 newLimit) external onlyOwner {
	    require(
		  SALE_NFT >= newLimit, 
		  "Incorrect value"
		);
        MAX_BY_MINT_IN_TRANSACTION_SALE = newLimit;
    }
	
	function updateSaleSupply(uint256 newSupply) external onlyOwner {
	    require(
		  newSupply >= SALE_MINTED, 
		  "Incorrect value"
		);
        SALE_NFT = newSupply;
    }
	
	function updateReservedSupply(uint256 newSupply) external onlyOwner {
	    require(
		  newSupply >= RESERVED_MINTED,
		  "Incorrect value"
		);
        RESERVED_NFT = newSupply;
    }
	
	function airdropUSDT(uint256 amount) external onlyOwner {
	   require(
		 IERC20(USDT).balanceOf(msg.sender) >= amount, 
		 "balance not available for transfer"
	   );
	   require(
		  totalSupply() >= 1, 
		  "NFT not minted yet"
	   );
       IERC20(USDT).safeTransferFrom(address(msg.sender), address(this), amount);
	   accTokenPerShare = accTokenPerShare + (amount * precisionFactor / totalSupply());
	}
	
	function withdrawAirdrop(uint256[] calldata ids) external {
	   for(uint i=0; i < ids.length; i++) {
		 require(
		   ownerOf(ids[i]) == address(msg.sender), 
		   "Incorrect request submitted"
		 );
		 uint256 pending = pendingReward(ids[i]);
		 IERC20(USDT).safeTransfer(address(msg.sender), pending);
		 mapAirdropInfo[ids[i]].rewardDebt += pending;
	   }
	}
	
	function pendingReward(uint256 id) public view returns (uint256) {
	   require(
		  totalSupply() >= id, 
		  "NFT not minted yet"
	   );
	   uint256 pending = (accTokenPerShare / precisionFactor) - mapAirdropInfo[id].rewardDebt;
	   return pending;
    }
}