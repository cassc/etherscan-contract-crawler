// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {OperatorFilterer} from "./common/OperatorFilterer.sol";
import "./ERC721PVM.sol";

contract Moonshiners is Ownable, ERC721PVM, OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    struct MintState {
        uint256 liveAt;
        uint256 expiresAt;
        bytes32 merkleRoot;
        uint256 maxPerWallet;
        uint256 maxSupply;
        uint256 maxMintSupply;
        uint256 totalSupply;
        uint256 viralityFactor;
        bool hasMinted;
    }

    // @notice Base URI for the nft
    string private baseURI = "ipfs://cid/";

    // @notice The merkle root
    bytes32 public merkleRoot;

    // @notice Max mints per wallet (n-1)
    uint256 public maxPerWallet = 2;

    // @notice Max supply for mints
    uint256 public maxMintSupply = 1001;

    // @notice Live date 12pm PST
    uint256 public liveAt = 1668888000;

    // @notice Expiration date 1pm PST
    uint256 public expiresAt = 1668891600;

    /// @dev Tracks whether wallet has already minted
    mapping(address => bool) public addressToMinted;

    constructor()
        ERC721PVM("Moonshiners", "MNSHN")
        OperatorFilterer(DEFAULT_SUBSCRIPTION, true)
    {
        _safeMint(address(0xb5164865b185acbB02710D36F18b6513409B8ef5), 1);
    }

    /**
     * @notice Mint a moonshiner, LFG
     * @param _proof The bytes32 array proof to verify the merkle root
     */
    function mint(bytes32[] calldata _proof) public payable {
        uint256 timestamp = block.timestamp;
        require(timestamp > liveAt && timestamp < expiresAt, "Mint not live");
        require(totalSupply() + 1 < maxMintSupply, "Sold out");
        require(tx.origin == _msgSender(), "Must be user");
        require(!addressToMinted[_msgSender()], "Already minted");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof");
        addressToMinted[_msgSender()] = true;
        _safeMint(_msgSender(), 1);
    }

    /**
     * @notice Sets the merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _newBaseURI A base uri
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Sets the max mint supply (n-1)
     * @param _maxMintSupply The max supply
     */
    function setMintMaxSupply(uint256 _maxMintSupply) external onlyOwner {
        maxMintSupply = _maxMintSupply;
    }

    /**
     * @notice Sets the max mints per wallet
     * @param _maxPerWallet The max mints per wallet
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets the collection max supply of entire collection (n-1)
     * @param _maxSupply The amount
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        _setMaxSupply(_maxSupply);
    }

    /**
     * @notice Sets timestamps for live and expires timeframe
     * @param _liveAt A unix timestamp for live date
     * @param _expiresAt A unix timestamp for expiration date
     */
    function setMintWindow(uint256 _liveAt, uint256 _expiresAt)
        external
        onlyOwner
    {
        liveAt = _liveAt;
        expiresAt = _expiresAt;
    }

    /// @dev Gets the index of the last minted token
    function getCurrentIndex() external view returns (uint256 currentIndex) {
        return _currentIndex;
    }

    /// @dev Get an array of tokenIds for a given wallet
    function getTokenIds(address _address)
        public
        view
        returns (uint16[] memory tokenIds)
    {
        return _addressData[_address].tokenIds;
    }

    /**
     * @dev Returns mint state for a particular address
     * @param _address The address
     */
    function getMintState(address _address)
        external
        view
        returns (MintState memory)
    {
        return
            MintState({
                liveAt: liveAt,
                expiresAt: expiresAt,
                merkleRoot: merkleRoot,
                maxPerWallet: maxPerWallet,
                maxMintSupply: maxMintSupply,
                maxSupply: _maxSupply,
                totalSupply: totalSupply(),
                viralityFactor: _passiveVirality(),
                hasMinted: addressToMinted[_address]
            });
    }

    // @dev Overrides base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev Overrides the start token id
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // @dev Overrides the base virality factor
    function _passiveVirality()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return 2;
    }

    /******************************************************************************************************************
     * Royalty enforcement via registry filterer
     ******************************************************************************************************************/

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}