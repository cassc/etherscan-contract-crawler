// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721{
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
	function users(address owner) external view returns (uint256 nftminted);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
	
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
	
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
	
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
	
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
	
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
	
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
		
        _status = _ENTERED;

        _;
		
        _status = _NOT_ENTERED;
    }
}

library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }
}

contract PreSale is Ownable, ReentrancyGuard {
	uint256 public MAX_MINT_NFT = 1;
	uint256 public MAX_BY_MINT_PER_TRANSACTION = 1;
	uint256 public PRESALE_PRICE = 0.05 ether;
	
    bool public whitelistSaleEnable = false;
	
	bytes32 public merkleRoot;
	uint256 public NFT_MINTED;
	
	struct User {
	  uint256 nftminted;
    }
	
	IERC721 public TOADS = IERC721(0x8f393E46Ac410118Fd892011B1432bb7D0fD1A54);
	mapping(address => User) public users;
	
	function mintWhitelistNFT(uint256 _count, bytes32[] calldata merkleProof) external payable nonReentrant{
		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		require(
			whitelistSaleEnable, 
			"WhitelistSale is not enable"
		);
        require(
		   _count <= TOADS.balanceOf(address(this)), 
		   "Exceeds max limit"
		);
		require(
			MerkleProof.verify(merkleProof, merkleRoot, node), 
			"MerkleDistributor: Invalid proof."
		);
		require(
		    users[msg.sender].nftminted + _count <= MAX_MINT_NFT,
		    "Exceeds max mint limit per wallet"
		);
		require(
			_count <= MAX_BY_MINT_PER_TRANSACTION,
			"Exceeds max mint limit per txn"
		);
		require(
		   msg.value >= PRESALE_PRICE * _count,
		   "Value below price"
		);
		for (uint256 i = 0; i < _count; i++) {
		   uint256 tokenID = TOADS.tokenOfOwnerByIndex(address(this), 0);
           TOADS.safeTransferFrom(address(this), address(msg.sender), tokenID, "");
		   NFT_MINTED++;
        }
		users[msg.sender].nftminted += _count;
    }
	
	function withdrawNFT(uint256 _count) external onlyOwner {
        require(
		   _count <= TOADS.balanceOf(address(this)), 
		   "Exceeds max limit"
		);
		for (uint256 i = 0; i < _count; i++) {
		   uint256 tokenID = TOADS.tokenOfOwnerByIndex(address(this), 0);
           TOADS.safeTransferFrom(address(this), address(msg.sender), tokenID, "");
        }
    }
	
	function setWhitelistSaleStatus(bool status) external onlyOwner {
	   require(whitelistSaleEnable != status);
       whitelistSaleEnable = status;
    }
	
	function updateMintLimitPerWallet(uint256 newLimit) external onlyOwner {
        MAX_MINT_NFT = newLimit;
    }
	
	function updateMintLimitPerTransaction(uint256 newLimit) external onlyOwner {
        MAX_BY_MINT_PER_TRANSACTION = newLimit;
    }
	
	function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
	   merkleRoot = newRoot;
	}
	
	function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
	
	function updatePreSalePrice(uint256 newPrice) external onlyOwner {
        PRESALE_PRICE = newPrice;
    }
}