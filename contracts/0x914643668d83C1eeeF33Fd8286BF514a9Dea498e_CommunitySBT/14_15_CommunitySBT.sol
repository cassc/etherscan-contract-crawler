// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC5192.sol";

contract CommunitySBT is Ownable, ERC721URIStorage, IERC5192 {

    struct RootData {
        bool isValid;
        string metadataURI;
    }
    struct TokenData {
        uint96 badgeId;
        bytes32 merkleRoot;
    }

    /// @dev mapping used to track whitelisted merkle roots
    mapping(bytes32 => RootData) public rootData;

    // the root used to claim a given token ID. Required to get the base URI. 
    mapping(uint256 => TokenData) public tokenData;

    /// @notice tracks the number of minted badges
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    /// @notice leaf details that seat at the bottom of each merkle tree
    struct LeafInfo {
        address account;
        uint96 badgeId;
    }

    /** @notice Information needed for the NewValidRoot event. It is used to track
     * badges registration in the subgraph. Everything other than the merkleRoot is discarded.
     */
    struct RootInfo {
        bytes32 merkleRoot; 
        string baseMetadataURI; // The folder URI from which individual token URIs can be derived. Must therefore end with a slash.
        uint32 startTimestamp; // Only logged, not stored
        uint32 endTimestamp; // Only logged, not stored
    }

    event RedeemCommunitySBT(LeafInfo leafInfo, uint256 tokenId);
    event NewValidRoot(RootInfo rootInfo);
    event InvalidatedRoot(bytes32 merkleRoot);
    
    constructor(string memory name, string memory symbol)
    ERC721(name, symbol){}

    /** @notice Registers a new root as being valid. This allows it to be used in badges verifications.
     * @dev Apart from the root and the URI, the input values are only used for logging 
     */
    function addNewRoot(RootInfo memory rootInfo) public onlyOwner { 
        rootData[rootInfo.merkleRoot].isValid = true;
        require(bytes(rootInfo.baseMetadataURI).length > 0, "cannot set empty root URI");
        require(bytes(rootData[rootInfo.merkleRoot].metadataURI).length == 0, "cannot overwrite non-empty URI");
        rootData[rootInfo.merkleRoot].metadataURI = rootInfo.baseMetadataURI;
        emit NewValidRoot(rootInfo);
    }

    /** @notice Removes a root from whitelist. It ca no longer be used for badges validations.
     * @notice This should only be used in case a faulty root was submitted.
     * @notice If a user already redeemed a badge based on the faulty root, 
     * the badge cannot be burnt.
     */
    function invalidateRoot(bytes32 merkleRoot) public onlyOwner { 
        rootData[merkleRoot].isValid = false;
        emit InvalidatedRoot(merkleRoot);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override virtual {
        require(from == address(0), "Soul Bound Token");   
        super._beforeTokenTransfer(from, to, tokenId);  
    }

    /** @notice Total supply getter. Returns the total number of minted badges so far.
     */
    function totalSupply() public view returns (uint256) { 
        return _tokenSupply.current();
    }

    /** @notice Total supply getter. Returns the total number of minted badges so far.
     * @param account: user's address
     * @param merkleRoot: merkle root associated with this badge
     * @param badgeId: badge ID
     */
    function getTokenIdHash(address account,bytes32 merkleRoot, uint96 badgeId) public view returns (bytes32) {
        return keccak256(abi.encodePacked(account, merkleRoot, badgeId));
    }

    /// @inheritdoc IERC5192
    function locked(uint256 tokenId) external override(IERC5192) view returns (bool) {
        return true; // All tokens are locked.
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        string memory rootURI = rootData[tokenData[tokenId].merkleRoot].metadataURI;
        return string(abi.encodePacked(rootURI, Strings.toString(uint256(tokenData[tokenId].badgeId)), ".json"));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC5192).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /** @notice Total supply getter. Returns the total number of minted badges so far.
     * @param leafInfo: merkle tree leaf with badge information
     * @param proof: merkle tree proof of the leaf
     * @param merkleRoot: merkle tree root based on which the proof is verified
     */
    function redeem(LeafInfo memory leafInfo, bytes32[] calldata proof, bytes32 merkleRoot) public returns (uint256) {
        require(_verify(_leaf(leafInfo), proof, merkleRoot), "Invalid Merkle proof"); 

        bytes32 tokenIdHash = getTokenIdHash(leafInfo.account, merkleRoot, leafInfo.badgeId);
        uint256 tokenId = uint256(tokenIdHash);

        _tokenSupply.increment();
        _safeMint(leafInfo.account, tokenId);

        tokenData[tokenId].merkleRoot = merkleRoot;
        tokenData[tokenId].badgeId = leafInfo.badgeId;

        emit RedeemCommunitySBT(leafInfo, tokenId);
        // https://eips.ethereum.org/EIPS/eip-5192
        emit Locked(tokenId);

        return tokenId;
    }

    /** @notice Supports redemption of multiple SBTs in one transaction
     * @dev Each claim must present its own root and a full proof, even if this involves duplication
     * @param leafInfos the leaves of the merkle trees from which to claim an SBT
     * @param proofs the proofs - one bytes32[] for each leaf
     * @param merkleRoots the merkel roots - one bytes32 for each leaf
     */ 
    function multiRedeem(LeafInfo[] memory leafInfos, bytes32[][] calldata proofs, bytes32[] memory merkleRoots) public returns (uint256[] memory tokenIds) {
        require(leafInfos.length == proofs.length && leafInfos.length == merkleRoots.length, "Bad input");
        tokenIds = new uint256[](leafInfos.length);

        for (uint256 i=0; i < leafInfos.length; i++) {
            tokenIds[i] = redeem(leafInfos[i], proofs[i], merkleRoots[i]);
        }
        return tokenIds;
    }

    /** @notice Encoded the leaf information
     * @param leafInfo: merkle tree leaf with badge information
     */
    function _leaf(LeafInfo memory leafInfo)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(leafInfo.account, leafInfo.badgeId));
    }


    /** @notice Verification that the hash of the actor address and information
     * is correctly stored in the Merkle tree i.e. the proof is validated
     */
    function _verify(bytes32 encodedLeaf, bytes32[] memory proof, bytes32 merkleRoot)
    internal view returns (bool)
    {
        require(rootData[merkleRoot].isValid, "Unrecognised merkle root");
        return MerkleProof.verify(proof, merkleRoot, encodedLeaf);
    }

}