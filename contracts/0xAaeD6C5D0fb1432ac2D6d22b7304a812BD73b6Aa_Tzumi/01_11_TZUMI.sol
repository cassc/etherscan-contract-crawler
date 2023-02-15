// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721A, IERC721A} from "erc721a/contracts/ERC721A.sol";
import {OperatorFilterer} from "https://github.com/Vectorized/closedsea/blob/main/src/OperatorFilterer.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title  Tzumi nft
 * @notice This contract is configured to use the DefaultOperatorFilterer, which automatically registers the
 *         token and subscribes it to OpenSea's curated filters.
 *         Adding the onlyAllowedOperator modifier to the transferFrom and both safeTransferFrom methods ensures that
 *         the msg.sender (operator) is allowed by the OperatorFilterRegistry.
 */
contract Tzumi is
    ERC721A,
    OperatorFilterer,
    Ownable,
    ERC2981
{
    //variables and consts
    bool public operatorFilteringEnabled;
    bytes32 public merkleRoot;

    bool public publicMintEnabled = false;
    bool public WhitelistMintEnabled = false;

    mapping(address => bool) public whitelistClaimed;
    mapping(address => bool) public publicClaimed;
    string public uriSuffix = ".json";
    string public baseURI = "";

    uint256 public tzumiSupply = 4000;
    uint256 public whitelistSupply = 6000;
    uint256 public publicSalePrice = 0.01 ether;
    uint256 public tzumiPerTx = 2;

    constructor() ERC721A("Tzumi", "TZ") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _mint(msg.sender, 1);
        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
    }

    function mintPublic(uint256 quantity) public payable{
        uint256 supply = totalSupply();
        require (publicMintEnabled, "Public mint not live yet");
        require(!publicClaimed[msg.sender], "Address already minted");
        require(quantity + supply <= tzumiSupply, "Supply exceeded");
        require(msg.value >= quantity * publicSalePrice, "Invalid input price");
        _mint(msg.sender, quantity);
        publicClaimed[msg.sender] = true;
        delete supply;
    }
    

    function mintWhitelist(uint256 quantity, bytes32[] calldata merkleProof) public payable{
        uint256 mintedTzumi = totalSupply();
        require(WhitelistMintEnabled, "The mint isn't open yet");
        require(quantity == 1, "Invalid quantity to mint");
        require(mintedTzumi + quantity <= tzumiSupply, "Cannot mint over supply");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(!whitelistClaimed[msg.sender], "Whitelist already minted");
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid proof!" );
        _mint(msg.sender, quantity);
        whitelistClaimed[msg.sender] = true;
        delete mintedTzumi;
    }

    function setPublicMintEnabled(bool enabled) public onlyOwner{
        publicMintEnabled = enabled;
    }

    function setWhitelistMintEnabled(bool enabled) public onlyOwner{
        WhitelistMintEnabled = enabled;
    }

    //overriding of functions to apply for Opensea royalties
    function setApprovalForAll(address operator, bool approved)
        public
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

     /**
     * @notice Change merkle root hash
     */
    function setMerkleRoot(bytes32 merkleRootHash) external onlyOwner{
        merkleRoot = merkleRootHash;
    }

    /**
     * @notice Verify merkle proof of the address
     */
    function verifyAddress(bytes32[] calldata merkleProof) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function withdrawBalance() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "WITHDRAW FAILED!");
    }


}