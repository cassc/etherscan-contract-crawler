// SPDX-License-Identifier: MIT

/// @title: Club Astraea NFT Contract (Free Mint)
/// @author: First Piece
/// @notice: For more information checkout https://twitter.com/ClubAstraea
/// @dev: This is Version 1.0
//
//   _______     __     ___       __                   
//  / ___/ /_ __/ /    / _ | ___ / /________ ____ ___ _
// / /__/ / // / _ \  / __ |(_-</ __/ __/ _ `/ -_) _ `/
// \___/_/\_,_/_.__/ /_/ |_/___/\__/_/  \_,_/\__/\_,_/ 
//                                                  


pragma solidity ^0.8.4;
// import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
contract clubAstraeaMembership is ERC721AQueryable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_NFT_SUPPLY = 1000;
    uint256 public MAX_NFT_WL = 1000;

    uint256 public price = 0 ether; //0 Ether = Free Mint
    uint256 public WL_price = 0 ether; //0 Ether = Free Mint

    uint256 public MAX_SALE_MINTS_PER_ADDRESS = 1;
    uint256 public MAX_PRESALE_MINTS_PER_ADDRESS = 1;

    uint256 public MINT_OPEN_TIMESTAMP;
    uint256 public WL_OPEN_TIMESTAMP;
    uint256 public REVEAL_TIMESTAMP = 0;

    string baseTokenURI;

    // used to validate whitelists
    bytes32 public whitelistMerkleRoot;
    
    constructor(string memory baseURI, uint256 mintTimestamp, uint256 wlTimestamp) ERC721A("Club Astraea Membership", "Club Astraea") {
        setBaseURI(baseURI);
        setMintOpenTimestamp(mintTimestamp);
        setWLOpenTimestamp(wlTimestamp);
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }


    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setMintOpenTimestamp(uint256 _timestamp) public onlyOwner {
        MINT_OPEN_TIMESTAMP = _timestamp;
    }

    function setWLOpenTimestamp(uint256 _timestamp) public onlyOwner {
        WL_OPEN_TIMESTAMP = _timestamp;
    }

    function setNewMaxPreSaleMintsPerAddress(uint256 _newMaxPreSaleMintsPerAddress) public onlyOwner {
        MAX_PRESALE_MINTS_PER_ADDRESS = _newMaxPreSaleMintsPerAddress;
    }

    function setNewMaxSaleMintsPerAddress(uint256 _newMaxSaleMintsPerAddress) public onlyOwner {
        MAX_SALE_MINTS_PER_ADDRESS = _newMaxSaleMintsPerAddress;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setWLPrice(uint256 _newPrice) public onlyOwner {
        WL_price = _newPrice;
    }

    function setWLSupply(uint256 _amount) public onlyOwner {
        MAX_NFT_WL = _amount;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function reveal(uint256 _revealTimeStamp, string memory baseURI) external onlyOwner {
        REVEAL_TIMESTAMP = _revealTimeStamp;
        setBaseURI(baseURI);
    } 

    function withdrawAll() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
    //mint NFTTokens
    function mintNFTTokens(uint256 _count) public payable {
        if (msg.sender != owner()) {
            require(block.timestamp > MINT_OPEN_TIMESTAMP, 'Sale is not open yet');
            require(
            _count <= (MAX_SALE_MINTS_PER_ADDRESS - balanceOf(msg.sender)),
            "Amount exceeds max limit per user"
            );
        }
        require(
            _count > 0,
            "Min 1 token can be minted"
        );
        require(
            totalSupply() + _count <= MAX_NFT_SUPPLY,
            "Transaction will exceed maximum supply"
        );
        require(
            msg.value >= price * _count,
            "Ether sent with this transaction is not correct"
        );

        _safeMint(msg.sender, _count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        if (REVEAL_TIMESTAMP == 0) return string(abi.encodePacked(baseURI, '0'));

        string memory _tokenURI = '';
        if (bytes(baseURI).length > 0) {
            _tokenURI = string(abi.encodePacked(baseURI, tokenId.toString()));
        }
        return _tokenURI;
    }

    function tokensMinted() public view returns (uint256) {
        return totalSupply();
    }

    function totalTokenSupply() public pure returns (uint256) {
        return MAX_NFT_SUPPLY;
    }

    function collectionInWallet(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        uint256 x = 0;
        for(uint256 i; i < MAX_NFT_SUPPLY; i++){
            if (_owner == ownerOf(i)) {
                tokensId[x] = i;
                x = x + 1;
            }
            if(x == tokenCount) return tokensId;
        }
        return tokensId;
    }

    function isOnWhitelist(bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    function mintPresale(uint256 _count, bytes32[] calldata merkleProof) public payable isValidMerkleProof(merkleProof, whitelistMerkleRoot) {
        require( 
            block.timestamp > WL_OPEN_TIMESTAMP, 
            'Presale is not open yet'
        );         
        require(
            _count > 0,
            "Min 1 token can be minted"
        );
        require(
            _count + balanceOf(msg.sender) <= MAX_PRESALE_MINTS_PER_ADDRESS,
            'Amount exceeds max presale limit per user'
        ); 
        require(
            totalSupply() + _count <= MAX_NFT_WL,
            "Transaction will exceed maximum WL supply"
        );
        require(
            msg.value >= WL_price * _count,
            "Ether sent with this transaction is not correct"
        );
        
        _safeMint(msg.sender, _count);
    }
}