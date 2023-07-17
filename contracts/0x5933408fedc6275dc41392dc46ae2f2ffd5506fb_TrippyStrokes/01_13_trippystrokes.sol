// SPDX-License-Identifier: MIT
// This contract is to be used for companion sales with multiple parents.
// Usage:
// - calling `claimAll(parentId)` allows you to claim tokens that you own from a particular parent, generating tokens with token ids (<parentId> * 1M + <tokenId of parent>). Only available during a claim period.
// - calling `claimByTokenIds(parentId, tokenIds[])` allows you to claim specific tokens from a contract with certain tokenIds in a parent, generating tokens with token ids (<parentId> * 1M + <tokenId of parent>). Only available during a claim period.
// - calling `claimSaleByTokenIds(parentId, tokenIds[])` allows you to mint from the contract with certain tokenIds in a parent, generating tokens with token ids (<parentId> * 1M + <tokenId of parent>). Only available during a claim sale period. 
// - calling `mint` will mint tokens from this MultiParentSale contract, which only exist in the range between 0 and 1 million

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract ParentContract {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
    function balanceOf(address owner) external virtual view returns (uint256 balance);    
}

contract TrippyStrokes is ERC721, Ownable, ReentrancyGuard {  

    struct Parent {
        ParentContract parentContract;
        bool isClaimable;
    } 

    mapping(uint256 => Parent) parents;

    bytes32 merkleRoot;
    string public PROVENANCE;
    bool public claimIsActive = false;
    bool public claimSaleIsActive = false;
    bool public allowSaleIsActive = false;
    bool public saleIsActive = false;
    string private baseURI;
    uint256 public constant MAX_PUBLIC_MINT = 3;
    uint256 public constant PRICE_PER_TOKEN = 0.042069 ether;
    uint256 public constant MAX_ALLOWLIST_MINT = 1;
    uint256 constant ONE_MILLION = 1_000_000;
    uint256 public constant SALE_SUPPLY = 1000;
    uint256 internal numberOfMintSales = 0;
    uint256 internal numberOfClaimSales = 0;
    mapping(address => uint256) private _allowListNumMinted;
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;
    

    constructor(uint256[] memory parentId, address[] memory parentAddress, bool[] memory isClaimable) ERC721("Trippy Strokes", "TRIPPY") {
        require(parentId.length == parentAddress.length);
        require(parentId.length == isClaimable.length);

        for (uint i = 0; i < parentAddress.length; i++) {
            require(parentId[i] != 0);
            parents[parentId[i]] = Parent(ParentContract(parentAddress[i]), isClaimable[i]);
        }
    }

    function setProvenanceHash(string memory provenance) external onlyOwner {
        PROVENANCE = provenance;
    }

    function isMinted(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
  
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setClaimState(bool newState) external onlyOwner {
        claimIsActive = newState;
    }

    function setClaimSaleState(bool newState) external onlyOwner {
        claimSaleIsActive = newState;
    }    

    function setSaleState(bool newState) external onlyOwner {
        saleIsActive = newState;
    }

    function setAllowSaleState(bool newState) external onlyOwner {
        allowSaleIsActive = newState;
    }

    function setAllowList(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function totalSalesSupply() public view returns (uint256){
        return numberOfClaimSales + numberOfMintSales;
    }

    function onAllowList(address claimer, bytes32[] memory proof) public view returns(bool){
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function numAvailableToMint(address claimer, bytes32[] memory proof) public view returns (uint) {
        if (onAllowList(claimer, proof)) {
            return MAX_ALLOWLIST_MINT - _allowListNumMinted[claimer];
        } else {
            return 0;
        }
    }

    function claim(uint256 parentId, uint256 startingIndex, uint256 numberOfTokens) internal claimActive{
        require(numberOfTokens > 0, "Must claim at least one token");
        uint balance = parents[parentId].parentContract.balanceOf(msg.sender);
        require(balance >= numberOfTokens, "Insufficient parent tokens");
        require(balance >= startingIndex + numberOfTokens, "Insufficient parent tokens");

        for (uint i = 0; i < numberOfTokens; i++) {
            uint parentTokenId = parents[parentId].parentContract.tokenOfOwnerByIndex(msg.sender, i + startingIndex);
            require(parents[parentId].parentContract.ownerOf(parentTokenId) == msg.sender, "Must own parent tokens");
            require(parents[parentId].isClaimable, "Token must be claimable");            
            uint tokenId = (parentId * ONE_MILLION) + parentTokenId;
            if (!_exists(tokenId)) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function claimAll(uint256 parentId) external nonReentrant{
        claim(parentId, 0, parents[parentId].parentContract.balanceOf(msg.sender));
    }        
  
    function claimByTokenIds(uint256 parentId, uint256[] calldata parentTokenIds) external nonReentrant claimActive{
        require(parentTokenIds.length > 0, "Must claim at least one token");

        for (uint i = 0; i < parentTokenIds.length; i++) {
            require(parents[parentId].parentContract.ownerOf(parentTokenIds[i]) == msg.sender, "Must own parent tokens");
            require(parents[parentId].isClaimable, "Token must be claimable");
            uint256 tokenId = (parentId * ONE_MILLION) + parentTokenIds[i];
            if (!_exists(tokenId)) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function claimSaleByTokenIds(uint256 parentId, uint256[] calldata parentTokenIds) external payable nonReentrant{
        require(claimSaleIsActive, "Claim sale period is not active");
        require(parentTokenIds.length > 0, "Must mint at least one token");
        require(totalSalesSupply() + parentTokenIds.length <= SALE_SUPPLY, "Mint would exceed max supply of tokens");
        require(PRICE_PER_TOKEN * parentTokenIds.length <= msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < parentTokenIds.length; i++) {
            require(parents[parentId].parentContract.ownerOf(parentTokenIds[i]) == msg.sender, "Must own parent tokens");
            require(!parents[parentId].isClaimable, "Token must not be claimable");
            uint256 tokenId = (parentId * ONE_MILLION) + parentTokenIds[i];
            if (!_exists(tokenId)) {
                _claimSale(msg.sender, tokenId);
            }
        }
    } 

    function _mintSale(address to, uint i) internal {
        numberOfMintSales++;
        _safeMint(to, i); 
    }

    function _claimSale(address to, uint i) internal {
        numberOfClaimSales++;
        _safeMint(to, i); 
    }


    function mintAllowList(uint numberOfTokens, bytes32[] memory merkleProof) external payable nonReentrant {
        uint startingIndex = numberOfMintSales;        
        require(allowSaleIsActive, "Allow list is not active");
        require(onAllowList(msg.sender, merkleProof), "Not on allow list");
        require(numberOfTokens <= MAX_ALLOWLIST_MINT - _allowListNumMinted[msg.sender], "Exceeded max available to purchase");
        require(totalSalesSupply() + numberOfTokens <= SALE_SUPPLY, "Mint would exceed max supply of tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");
        _allowListNumMinted[msg.sender] += numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintSale(msg.sender, startingIndex + i);
        }
    }


    function mint(uint numberOfTokens) external payable nonReentrant {
        uint startingIndex = numberOfMintSales;
        require(saleIsActive, "Sale period must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(totalSalesSupply() + numberOfTokens <= SALE_SUPPLY, "Mint would exceed max supply of tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintSale(msg.sender, startingIndex + i);
        }
    }    

    function withdraw() external onlyOwner nonReentrant{
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function parentInfo(uint256 parentId) external view returns (address, bool) {
        return (address(parents[parentId].parentContract), parents[parentId].isClaimable);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return ERC721.supportsInterface(interfaceId)
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE 
            || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 
            || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

   function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }    

    modifier claimActive() {
        require(claimIsActive, "Claim period is not active");
        _;
    }   
}