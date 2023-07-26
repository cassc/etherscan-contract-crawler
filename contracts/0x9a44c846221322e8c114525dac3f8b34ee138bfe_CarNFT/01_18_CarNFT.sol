// SPDX-License-Identifier: MIT
// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract CarNFT is ERC721A, Ownable, ReentrancyGuard{
    using Address for address;
    using Strings for uint256;    
    string public baseURI;
    string private _collectionURI;

    /**
      * reserve mint are from 1-160 (160 max supply)
      * free mint are from 161-1010 (850 max supply)
      * OG whitelist 50 address, 2 mint each, SL whitelist 750 address, 1 mint eachS
    **/

//    uint256 immutable public numOG = 5;
//    uint256 immutable public numSL = 10;

    uint256 immutable public maxNorm = 1000;
    uint256 immutable public maxHigh = 10;
    uint256 immutable public maxToken = 1010;

    uint public opentime = 1652598300;
    uint public closetime = 1652626500;

    // used merkle tree to validate whitelists
    bytes32 public OGMerkleRoot;  
    bytes32 public SLMerkleRoot;

    constructor(string memory _baseURI, string memory collectionURI) ERC721A("L.E.V.O", "LEVO") {
        setBaseURI(_baseURI);
        setCollectionURI(collectionURI);
    }

    /**
     * @dev validates merkleProof
     */
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

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    /**
    * @dev mints 1 token per whitelisted address, does not charge a fee
    * Max supply: 975 (token ids: 26-1000)
    * charges a fee
    */
    function mintSL(
      bytes32[] calldata merkleProof
    )
        external
        isValidMerkleProof(merkleProof, SLMerkleRoot)
        nonReentrant
    {
        require(_getAux(msg.sender)<1, "NFT is already minted by this address");
        require(_totalMinted() + 1 <= maxNorm,"Not enough tokens remaining to mint");
        require(block.timestamp > opentime ,"mint not open!");
        require(block.timestamp < closetime ,"mint close!");

        _safeMint(msg.sender, 1);        
        _setAux(msg.sender, 1);
    }

    function mintOG(
      bytes32[] calldata merkleProof
    )
        external
        isValidMerkleProof(merkleProof, OGMerkleRoot)
        nonReentrant
    {
        require(_getAux(msg.sender)<2, "Two NFT is already minted by this address");
        require(_totalMinted() + 2 <= maxNorm,"Not enough tokens remaining to mint");
        require(block.timestamp > opentime ,"mint not open!");
        require(block.timestamp < closetime ,"mint close!");
 
        _safeMint(msg.sender, 2 );     
        _setAux(msg.sender, 2);
    }

    function mintRemain( uint256 quantity) external nonReentrant onlyOwner
    {
        require(_totalMinted() + quantity <= maxToken,"Not enough tokens remaining to mint");
        require(block.timestamp > closetime ,"mint not close!");

        _safeMint(msg.sender, quantity);        
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============
    /**
     * @dev See {IERC721Metadata-tokenURI}. use a map save real metaID
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }
    /**
     * @dev we use aux in addressData struct as the address minted flag
     */
    function claimed() public view returns (uint64)
    {
        return _getAux(msg.sender);
    }

    function getMaxToken() public pure returns (uint256 ) {
        return maxToken;
    }

    function contractURI() public view returns (string memory) {
        return _collectionURI;
    }


    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setBaseURI(string memory _baseURI) public onlyOwner {
      baseURI = _baseURI;
    }

    /**
    * @dev set collection URI for marketplace display
    */
    function setCollectionURI(string memory collectionURI) internal virtual onlyOwner {
        _collectionURI = collectionURI;
    }

    function setOpenTime(uint open, uint close) public onlyOwner {
      opentime = open;
      closetime = close;     
    }
    /**
    * @dev set super lisence Root
    */
    function setOGMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        OGMerkleRoot = merkleRoot;
    }
    /**
    * @dev set OG Root
    */    
    function setSLMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        SLMerkleRoot = merkleRoot;
    }

}