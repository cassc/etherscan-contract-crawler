// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error OutsideSaleWindow();
error InsufficientFunds();
error TooMany();
error AlreadyMinted();
error NotOnMintlist();
error FullyMinted();
error FailedWithdraw();

contract TeachEmTurtles is ERC721A, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    string public baseURI;

    uint256 public MAX_SUPPLY = 2000;

    enum GROUP { OG, WL, PUBLIC }

    struct SaleConfig {
        uint128 price;
        uint56 startTime;
        uint56 endTime;
        uint16 maxQuantity;
    }

    mapping (GROUP => bytes32) public rootHashes;
    mapping (GROUP => SaleConfig) public saleConfig;
    mapping (GROUP => mapping(address => bool)) public hasMinted;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    constructor (string memory baseURI_) ERC721A("Teach'em Turtles", "TET") {
        baseURI = baseURI_;
    }

    /*///////////////////////////////////////////////////////////////
                              MINTING
    //////////////////////////////////////////////////////////////*/

    function mint(bytes32[] memory _proof, GROUP group, uint16 quantity) external payable {
        SaleConfig memory config = saleConfig[group];

        if (config.startTime > block.timestamp || config.endTime < block.timestamp) revert OutsideSaleWindow();
        if (msg.value < config.price * quantity) revert InsufficientFunds();
        if (quantity > config.maxQuantity) revert TooMany();
        if (hasMinted[group][msg.sender]) revert AlreadyMinted();
        if (_totalMinted() + uint256(quantity) > MAX_SUPPLY) revert FullyMinted();
        if (group != GROUP.PUBLIC) {
            if (!onMintlist(_proof, rootHashes[group])) revert NotOnMintlist();        
        }

        hasMinted[group][msg.sender] = true;
        _mint(msg.sender, quantity);
    }


    /*///////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token.");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(_baseURI(),  _tokenId.toString(), ".json")) : '';
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }


    /*///////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function onMintlist( bytes32[] memory _proof, bytes32 rootHash )
    internal view returns (bool) 
    {
        // Compute the merkle root
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_proof, rootHash, leaf)) {
            return true;
        }
        else {
            return false;
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    /*///////////////////////////////////////////////////////////////
                                OWNER
    //////////////////////////////////////////////////////////////*/

    function teamMint (address to, uint256 quantity) external onlyOwner {
        if (_totalMinted() + quantity > MAX_SUPPLY) revert FullyMinted();
        _mint(to, quantity);
    }

    function setRootHash(GROUP group, bytes32 rootHash) external onlyOwner {
        rootHashes[group] = rootHash;
    }

    function setSaleConfig(GROUP group, uint128 price, uint56 startTime, uint56 endTime, uint16 maxQuantity) external onlyOwner {
        saleConfig[group] = SaleConfig(price, startTime, endTime, maxQuantity);
    }

    function withdraw(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        if (!success) revert FailedWithdraw();
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        MAX_SUPPLY = maxSupply;
    }


    /*///////////////////////////////////////////////////////////////
                    OPENSEA ENFORCING ROYALTIES
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) payable {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) payable
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}