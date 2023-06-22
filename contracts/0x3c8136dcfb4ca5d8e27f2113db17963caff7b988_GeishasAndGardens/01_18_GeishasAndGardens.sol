/**
 *  Geishas & Gardens
 * 
 *  Art: Elcin Arpacay
 *  Development: Can Poyrazoglu
 *  Lore Crafting & Community Growth: Sinan Sipahiler
 *  Creative Strategist: Nilsu Ozturk
 * 
 *  2023 Yokai Labs
 * 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract GeishasAndGardens is DefaultOperatorFilterer, ERC721Burnable, Ownable, ReentrancyGuard {

    // original maximum supply of G&G NFTs in the beginning
    uint public constant ORIGINAL_MAX_SUPPLY = 4444;

    /** amount of tokens to premint to team vault on deployment */
    uint private constant VAULT_PREMINT_COUNT = 140;

    uint public constant MAX_MINT_PER_ACCOUNT = 2;

    // Merkle root of addresses that are whitelisted
    bytes32 private _whitelistMerkleRoot;

    string private constant BASE_CID = "bafybeigwoh4s6zlg56366kigaavmr6bcwsmhzrfrg55ck46frimmg2r4m4";

    // current token ID to mint
    uint private _currentTokenId = 1;

    // mapping to keep track of each address' mint count, regardless of token transfers
    mapping(address => uint) private _mintedAmounts;

    // is public minting active?
    bool private _isPublicSaleInProgress = false;

    // is whitelist minting active?
    bool private _isPrivateSaleInProgress = false;


    // support for adding special tokens in the future, with their own base IPFS URLs
    struct Range {
        uint startIndex;
        uint length;
        string cid;
    }

    Range[] private _additionalRanges;

    error TokenNotFound();
    error InvalidTokenRange();
    error SaleNotInProgress();
    
    constructor(bytes32 merkleRoot) ERC721("Geishas & Gardens", "G&G") {
        _whitelistMerkleRoot = merkleRoot;

        // mint predefined amount of tokens to team vault on deployment
        for (uint i = 0; i < VAULT_PREMINT_COUNT; i++) {
            _performMint();
        }
    }

    /** start/stop the public sale. sets the private sale to false */
    function setPublicSale(bool enabled) public onlyOwner {
        _isPrivateSaleInProgress = false;
        _isPublicSaleInProgress = enabled;
    }

    function isPublicSaleInProgress() public view returns (bool) {
        return _isPublicSaleInProgress;
    }

     /** start/stop the private sale. sets the public sale to false */
    function setPrivateSale(bool enabled) public onlyOwner {
        _isPublicSaleInProgress = false;
        _isPrivateSaleInProgress = enabled;
    }

    function isPrivateSaleInProgress() public view returns (bool) {
        return _isPrivateSaleInProgress;
    }

    /** update the whitelisted addresses, if ever needed */
    function setWhitelistMerkleRoot(bytes32 newRoot) public onlyOwner {
        _whitelistMerkleRoot = newRoot;
    }


    /** mints the specified amount of geishas from the public sale */
    function mint(uint count) public nonReentrant {
        require(isPublicSaleInProgress(), "Public sale not in progress.");
        require(count == 2 || count == 1, "Invalid count");
        require(_currentTokenId + count - 1 <= ORIGINAL_MAX_SUPPLY, "Not enough supply.");

        // do we exceed the allowed amount if we mint?
        uint allowedAmount = remainingMintableAmount();

        require(count <= allowedAmount, 
            "Not allowed to mint more than 2 per wallet.");

        for (uint i = 0; i < count; i++) {
            _performMint();
        }
        _mintedAmounts[msg.sender] += count;
    }

    /** mints the specified amount of geishas from the private (whitelisted) sale */
    function whitelistMint(uint count, bytes32[] calldata merkleProof) public nonReentrant {
        if(!isPrivateSaleInProgress()){
            revert SaleNotInProgress();
        }

        // get the leaf node in Merkle tree for the calling address
        bytes32 node = keccak256(abi.encodePacked(msg.sender));

        // check if Merkle tree contains the proof for this address.
        require(MerkleProof.verify(merkleProof, _whitelistMerkleRoot, node), 
            "Address not whitelisted.");

        // do we exceed the allowed amount if we mint?
        uint allowedAmount = remainingMintableAmount();

        require(count > 0 && count <= allowedAmount, 
            "Not allowed to mint more than 2 during presale.");

        for (uint i = 0; i < count; i++) {
            _performMint();
        }

        _mintedAmounts[msg.sender] += count;
    }

    function remainingMintableAmount() public view returns (uint) {
        return MAX_MINT_PER_ACCOUNT - _mintedAmounts[msg.sender];
    }

    function _performMint() private {
        _safeMint(msg.sender, _currentTokenId);
        _currentTokenId++;
    }

    /** returns total supply, taking into account additional 4444+ ranges that
     * might be added in the future
     */
    function totalSupply() public view virtual returns (uint256) {
        if(_additionalRanges.length == 0){
            return _currentTokenId - 1;
        }else{
            uint runningTotal = _currentTokenId - 1;
            for (uint i = 0; i < _additionalRanges.length; i++) {
                Range memory  r = _additionalRanges[i];
                runningTotal += r.length;
            }
            return runningTotal;
        }
    }

    /** adds extended range tokens for upcoming perks, if any. this is for tokens 4444+ */
    function addExtendedRange(uint startIndex, uint length, string memory cid) public onlyOwner {
        require(startIndex > ORIGINAL_MAX_SUPPLY, "Start index invalid");
        require(length > 0, "Length invalid");

        Range memory r;
        r.startIndex = startIndex;
        r.length = length;
        r.cid = cid;
        _additionalRanges.push(r);
        for (uint i = startIndex; i < startIndex + length; i++){
            _safeMint(msg.sender, i);
        }
    }

    function metadataURI(string memory cid, uint tokenId) private pure returns (string memory) {
        string[5] memory metadataBuidler;
        metadataBuidler[0] = 'ipfs://';
        metadataBuidler[1] = cid;
        metadataBuidler[2] = '/';
        metadataBuidler[3] = Strings.toString(tokenId);
        metadataBuidler[4] = '.json';

        string memory url = string(abi.encodePacked(
            metadataBuidler[0], metadataBuidler[1], metadataBuidler[2], metadataBuidler[3], metadataBuidler[4]
        ));
        return url;
    }

    /** returns range for tokens > 4444. after 4444 there is no concept of external/
     * internal mapping so it just simply takes an id.
     */
    function getExtendedRangeForId(uint id) private view returns (Range memory) {
        if(id <= ORIGINAL_MAX_SUPPLY) {
            revert InvalidTokenRange();
        }
        for (uint i = 0; i < _additionalRanges.length; i++) {
            Range memory  r = _additionalRanges[i];
            if(r.startIndex <= id && id < r.startIndex + r.length){
                // token belongs to this range
                return r;
            }
        }
        revert TokenNotFound();
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        if(tokenId <= ORIGINAL_MAX_SUPPLY){
            if(tokenId >= _currentTokenId){
                revert TokenNotFound();
            }
            return metadataURI(BASE_CID, tokenId);
        }else{
            Range memory r = getExtendedRangeForId(tokenId);
            return metadataURI(r.cid, tokenId);
        }
    }

    /* operator filter support */

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /* end operator filter support */

}