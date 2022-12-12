// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FreemintPass {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}
}

contract GrindPass is ERC721A, Ownable {
    enum SaleStatus{ PAUSED, HOLDERS_ONLY, WHITELIST, PUBLIC }

    uint16 public constant COLLECTION_SIZE = 888;
    
    uint8 public constant TOKENS_PER_TRAN_LIMIT = 2;
    uint8 public constant TOKENS_PER_PERSON_PUB_LIMIT = 2;
    uint8 public constant TOKENS_PER_PERSON_WL_LIMIT = 1;
    uint8 public constant TOKENS_PER_PERSON_HOLDER_LIMIT = 1;

    uint public constant HOLDERS_ONLY_MINT_PRICE = 0 ether;
    uint public constant WHITELIST_MINT_PRICE = 0.0088 ether;
    uint public MINT_PRICE = 0.0099 ether;

    SaleStatus public saleStatus = SaleStatus.PAUSED;

    bytes32 public merkleRoot;
    
    string private _baseURL = "https://freemint-nft.com/ipfs/metadata_grind_pass";

    FreemintPass FreemintPassContract = FreemintPass(0xc816BAAE5fC77395c333CA78625A0F420a16fB99);
    
    mapping(address => uint8) public _mintedCount;
    mapping(address => uint8) public _whitelistMintedCount;
	mapping(uint256 => uint8) public _holderBenefitsMintedCount;

    constructor() ERC721A("Grind Pass", "GP"){}
    
    /// @notice Update the merkle tree root
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    
    function contractURI() external pure returns (string memory) {
        return "https://freemint-nft.com/ipfs/contract_metadata_grind_pass.json";
    }
    
    /// @notice Set base metadata URL
    function setBaseURL(string calldata url) external onlyOwner {
        _baseURL = url;
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Update current sale stage
    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }

    /// @notice Update public mint price
    function setPublicMintPrice(uint price) external onlyOwner {
        MINT_PRICE = price;
    }

    /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");

        payable(owner()).transfer(balance);
    }

    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_totalMinted() + count <= COLLECTION_SIZE, "Request exceeds collection size");

        _safeMint(to, count);
    }

    /// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, "/", _toString(tokenId), ".json")) 
            : "";
    }
    
    function calcTotal(uint count) public view returns(uint) {
        require(saleStatus != SaleStatus.PAUSED, "Sales are off");

        uint price = (
            saleStatus == SaleStatus.HOLDERS_ONLY 
            ? HOLDERS_ONLY_MINT_PRICE 
            : (
                saleStatus == SaleStatus.WHITELIST
                ? WHITELIST_MINT_PRICE
                : MINT_PRICE
                )
            );

        return count * price;
    }
    
    
    function redeem(bytes32[] calldata merkleProof, uint256 benefitTokenId, uint8 count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "Sales are off");
        require(_totalMinted() + count <= COLLECTION_SIZE, "Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT, "Number of requested tokens exceeds allowance (2)");
        require(msg.value >= calcTotal(count), "Ether value sent is not sufficient");

        if (saleStatus == SaleStatus.HOLDERS_ONLY) {
            require(FreemintPassContract.ownerOf(benefitTokenId) == msg.sender, "You must own the token");
            require(_holderBenefitsMintedCount[benefitTokenId] + count <= TOKENS_PER_PERSON_HOLDER_LIMIT, "Number of requested tokens exceeds allowance (1)");

            _holderBenefitsMintedCount[benefitTokenId] += count;
        } else if (saleStatus == SaleStatus.WHITELIST) {
            require(_whitelistMintedCount[msg.sender] + count <= TOKENS_PER_PERSON_WL_LIMIT, "Number of requested tokens exceeds allowance (1)");

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "You are not whitelisted");

            _whitelistMintedCount[msg.sender] += count;
        } else {
            require(_mintedCount[msg.sender] + count <= TOKENS_PER_PERSON_PUB_LIMIT, "Number of requested tokens exceeds allowance (2)");

            _mintedCount[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
    }
    
}