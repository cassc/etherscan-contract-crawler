pragma solidity ^0.5.5;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Metadata.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

import "./Minter.sol";
import "./Utils.sol";

interface ITokenCategories {
    function getTokenCategory(uint256 tokenId) external pure returns (string memory);
}

contract HPToken is Utils, ERC721Metadata, Ownable, Minter {

    string private _baseURI;
    address private _categoriesContrAddr;
    uint256 private _totalSupply;
    bytes32 private _rootHash;

    constructor(
        address addr,
        string memory baseURI,
        address[] memory mintersWhitelist,
        bytes32 rootHash
    ) public Ownable() ERC721Metadata("Postereum", "PE20") Minter() {
        _categoriesContrAddr = addr;
        _baseURI = baseURI;
        _rootHash = rootHash;

        addMinter(msg.sender);

        uint256 accountsCount = mintersWhitelist.length;
        for (uint256 i = 0; i < accountsCount; i++) {
            addMinter(mintersWhitelist[i]);
        }
    }

    modifier onlyMinter() {
      require(isMinter(msg.sender) == true, "Caller is not a valid minter");
      _;
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function setCategoriesContrAddr(address addr) public onlyOwner {
        _categoriesContrAddr = addr;
    }

    /**
     * @dev External function to mint a single new token.
     * Reverts if the given token ID already exists.
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function mint(address to, uint256 tokenId) external onlyMinter {
        require(tokenId>0 && tokenId <501, "Token ID has to be in rage [1,500]");
        _mint(to, tokenId);
        _totalSupply = _totalSupply.add(1);
    }

    function mintMultiple(uint256 _tokenIdStart, address[] calldata _owners)
        external
        onlyMinter
    {
        uint256 addrcount = _owners.length;
        for (uint256 i = 0; i < addrcount; i++) {
            _mint(_owners[i], _tokenIdStart + i);
            _totalSupply = _totalSupply.add(1);
        }
    }

    /**
     * @dev Public function to set calculated root hash.
     * @param rootHash bytes32 Calculated root hash of merkle proof tree
     */
    function setRootHash(bytes32 rootHash) public onlyOwner
    {
        _rootHash = rootHash;
    }

    /**
     * @dev Public function to check merkleProof and reedem token to owner.
     * @param index uint256- Token index in sorted merkle tree
     * @param tokenId uint256 - Token id
     * @param merkleProof bytes32[] memory array of a storage proof
     */
    function redeem(uint256 index, uint256 tokenId, address owner, bytes32[] memory merkleProof)
        public
        returns (uint256)
    {
        bytes32 leaf = keccak256(abi.encodePacked(index, tokenId, owner));
        require(MerkleProof.verify(merkleProof, _rootHash, leaf), "Merkle proof verification failed");

        _mint(owner, tokenId);
        _totalSupply = _totalSupply.add(1);

        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory tokenCategoryId = ITokenCategories(_categoriesContrAddr).getTokenCategory(tokenId);

        return string(abi.encodePacked(_baseURI, "/api/v1/category/", tokenCategoryId, "/stamp/", toString(tokenId)));
    }
}