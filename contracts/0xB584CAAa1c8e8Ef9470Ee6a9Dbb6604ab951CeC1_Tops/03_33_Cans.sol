// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "./lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "./lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "./lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "./Constants.sol";

contract Cans is ERC721Enumerable, ERC721Burnable, ReentrancyGuard, AccessControl {
    using Strings for uint;

    bytes32 merkleRoot;
    bool public saleActive;
    uint public pricePerToken = 0.01 ether;
    uint public maxPublicMint = 15;
    uint public maxAllowListMint = 1;
    bool public allowListActive;
    string private _baseURIExtended;

    uint public seriesCount;
    uint constant ONE_MILLION = 1_000_000;
    string private _mysteryTokenURI;
    address public topsContract;

    mapping(uint => uint) public seriesSupply;
    mapping(uint => uint) public seriesMaxSupply;
    mapping(uint => bool) public seriesRevealed;
    mapping(uint => string) public seriesProvenance;
    mapping(uint => mapping(address => uint)) private _seriesAllowListNumMinted;

    mapping(uint => Constants.Tier) public canTier;

    constructor() ERC721("Cans", "CAN") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(Constants.SUPPORT_ROLE, msg.sender);
    }

    function currentSeries() public view returns (uint) {
        return seriesCount - 1;
    }

    function getTokenId(uint series, uint idInSeries) public pure returns (uint) {
         return (series * ONE_MILLION) + idInSeries;
    }

    function getSeries(uint tokenId) public view returns (uint) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenId / ONE_MILLION;
    }

    function getCanTierBatch(uint[] memory ids) public view returns (Constants.Tier[] memory) {
        Constants.Tier[] memory canTiers = new Constants.Tier[](ids.length);

        for (uint i; i < ids.length; i++) {
            canTiers[i] = canTier[ids[i]];
        }

        return canTiers;
    }

    function setMaxSupply(uint seriesMaxSupply_) public onlyRole(Constants.SUPPORT_ROLE) {
        require(seriesMaxSupply_ < ONE_MILLION, "Cannot exceed 1,000,000");
        seriesMaxSupply[currentSeries()] = seriesMaxSupply_;
    }

    function createSeries(uint seriesMaxSupply_) external onlyRole(Constants.SUPPORT_ROLE) {
        require(seriesMaxSupply_ < ONE_MILLION, "Cannot exceed 1,000,000");
        seriesMaxSupply[seriesCount] = seriesMaxSupply_;
        seriesCount++;
    }

    function setCanTier(uint[] calldata ids, Constants.Tier _tier) external onlyRole(Constants.SUPPORT_ROLE) {
        for (uint i; i < ids.length; i++) {
            canTier[ids[i]] = _tier;
        }
    }

    function setSeriesCount(uint seriesCount_) external onlyRole(Constants.SUPPORT_ROLE) {
        seriesCount = seriesCount_;
    }

    function setPricePerToken(uint pricePerToken_) external onlyRole(Constants.SUPPORT_ROLE) {
        pricePerToken = pricePerToken_;
    }

    function setMaxPublicMint(uint maxPublicMint_) external onlyRole(Constants.SUPPORT_ROLE) {
        maxPublicMint = maxPublicMint_;
    }

    function setMaxAllowListMint(uint maxAllowListMint_) external onlyRole(Constants.SUPPORT_ROLE) {
        maxAllowListMint = maxAllowListMint_;
    }

    function setAllowListActive(bool allowListActive_) external onlyRole(Constants.SUPPORT_ROLE) {
        allowListActive = allowListActive_;
    }

    function setAllowList(bytes32 merkleRoot_) external onlyRole(Constants.SUPPORT_ROLE) {
        merkleRoot = merkleRoot_;
    }

    function onAllowList(address claimer, bytes32[] memory proof) public view returns(bool){
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function numAvailableToMint(address claimer, bytes32[] memory proof) external view returns (uint) {
        if (onAllowList(claimer, proof)) {
            return maxAllowListMint - _seriesAllowListNumMinted[currentSeries()][claimer];
        } else {
            return 0;
        }
    }

    function _internalMint(uint numberOfTokens) internal {
        uint series = currentSeries();
        uint startingSupply = seriesSupply[series];
        require(startingSupply + numberOfTokens <= seriesMaxSupply[series], "Purchase would exceed max supply of tokens");
        for (uint i; i < numberOfTokens; i++) {
            _safeMint(msg.sender, getTokenId(currentSeries(), startingSupply + i));
        }
        seriesSupply[series] += numberOfTokens;
    }

    function allowListMint(uint numberOfTokens, bytes32[] memory merkleProof) external payable nonReentrant {
        uint series = currentSeries();
        require(allowListActive, "Allow list is not active");
        require(onAllowList(msg.sender, merkleProof), "Not on allow list");
        require(numberOfTokens <= maxAllowListMint - _seriesAllowListNumMinted[series][msg.sender], "Exceeded max available to purchase");
        require(pricePerToken * numberOfTokens <= msg.value, "Ether value sent is not correct");
        _seriesAllowListNumMinted[series][msg.sender] += numberOfTokens;
        _internalMint(numberOfTokens);
    }

    function setBaseURI(string memory baseURI_) external onlyRole(Constants.SUPPORT_ROLE) {
        _baseURIExtended = baseURI_;
    }

    function setMysteryTokenURI(string memory mysteryTokenURI_) external onlyRole(Constants.SUPPORT_ROLE) {
        _mysteryTokenURI = mysteryTokenURI_;
    }

    function setRevealed(bool revealed_) external onlyRole(Constants.SUPPORT_ROLE) {
        seriesRevealed[currentSeries()] = revealed_;
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        uint series = getSeries(tokenId);

        if (seriesRevealed[series]) {
            return bytes(_baseURIExtended).length > 0 ? string(abi.encodePacked(_baseURIExtended, getTokenId(series, uint(canTier[tokenId])).toString())) : "";
        } else {
            return _mysteryTokenURI;
        }
    }

    function setProvenance(string memory provenance) external onlyRole(Constants.SUPPORT_ROLE) {
        seriesProvenance[currentSeries()] = provenance;
    }

    function devMint(uint n) external onlyRole(Constants.SUPPORT_ROLE) {
        _internalMint(n);
    }

    function setSaleActive(bool saleActive_) external onlyRole(Constants.SUPPORT_ROLE) {
        saleActive = saleActive_;
    }

    function setTopsContract(address topsContract_) external onlyRole(Constants.SUPPORT_ROLE) {
        topsContract = topsContract_;
    }

    function isApprovedForAll(address owner, address operator) public view override(ERC721, IERC721) returns (bool) {
        if (topsContract != address(0) && operator == topsContract) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function mint(uint numberOfTokens) external payable nonReentrant {
        require(saleActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= maxPublicMint, "Exceeded max token purchase");
        require(pricePerToken * numberOfTokens == msg.value, "Ether value sent is not correct");
        _internalMint(numberOfTokens);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}