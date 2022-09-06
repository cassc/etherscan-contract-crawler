/*
 /$$$$$$$$                                /$$$$$$                  /$$           /$$   /$$ /$$$$$$$$ /$$$$$$$$
|_____ $$                                /$$__  $$                | $$          | $$$ | $$| $$_____/|__  $$__/
     /$$/   /$$$$$$   /$$$$$$   /$$$$$$ | $$  \__/  /$$$$$$   /$$$$$$$  /$$$$$$ | $$$$| $$| $$         | $$
    /$$/   /$$__  $$ /$$__  $$ /$$__  $$| $$       /$$__  $$ /$$__  $$ /$$__  $$| $$ $$ $$| $$$$$      | $$
   /$$/   | $$$$$$$$| $$  \__/| $$  \ $$| $$      | $$  \ $$| $$  | $$| $$$$$$$$| $$  $$$$| $$__/      | $$
  /$$/    | $$_____/| $$      | $$  | $$| $$    $$| $$  | $$| $$  | $$| $$_____/| $$\  $$$| $$         | $$
 /$$$$$$$$|  $$$$$$$| $$      |  $$$$$$/|  $$$$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$ \  $$| $$         | $$
|________/ \_______/|__/       \______/  \______/  \______/  \_______/ \_______/|__/  \__/|__/         |__/

Drop Your NFT Collection With ZERO Coding Skills at https://app.zerocodenft.com
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WorldsCollectivePass is ERC721A, Ownable {
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    uint public constant COLLECTION_SIZE = 10000;
    uint public constant FIRSTXFREECAP = 100;
    uint public PRESALE_MINT_PRICE = 0.05 ether;
    uint public MINT_PRICE = 0.083 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    address payable public immutable TREASURY;
    bytes32 public merkleRoot;
    string private _baseURL = "ipfs://QmWGu37Rcv2utvcX3cgkVhYXdcSUDtMd5iWacSoATh7geA";
    
    mapping(address => uint) private _mintedCount;
    mapping(address => uint) private _whitelistMintedCount;

    constructor(address payable treasury_) ERC721A("WorldsCollectivePass", "WCP"){
        TREASURY = treasury_;
    }
    
    /// @notice Update the merkle tree root
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    
    /// @notice Set base metadata URL
    function setBaseURL(string memory url) public onlyOwner {
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

    /// @notice Update mint prices
    function setPrices(uint wl, uint pub) external onlyOwner {
        PRESALE_MINT_PRICE = wl;
        MINT_PRICE = pub;
    }

    /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        
        TREASURY.transfer(balance);
    }

    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_totalMinted() + count <= COLLECTION_SIZE, "Request exceeds collection size");
        _safeMint(to, count);
    }

    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI))
            : "";
    }
    
    function calcTotal(uint count) public view returns(uint) {
        require(saleStatus != SaleStatus.PAUSED, "WorldsCollectivePass: Sales are off");
        require(msg.sender != address(0));

        uint price = MINT_PRICE;

        if(saleStatus == SaleStatus.PRESALE) {
            price = PRESALE_MINT_PRICE;
            bool canGetFreeMint = _whitelistMintedCount[msg.sender] == 0 && _totalMinted() < FIRSTXFREECAP;
            if(canGetFreeMint) {
                count--;
            }
        }

        return count * price;
    }
    
    function redeem(bytes32[] calldata merkleProof, uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "WorldsCollectivePass: Sales are off");
        require(_totalMinted() + count <= COLLECTION_SIZE, "WorldsCollectivePass: Number of requested tokens will exceed collection size");
        require(msg.value >= calcTotal(count), "WorldsCollectivePass: Ether value sent is not sufficient");

        if(saleStatus == SaleStatus.PRESALE) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "WorldsCollectivePass: You are not whitelisted");
            _whitelistMintedCount[msg.sender] += count;
        }
        else {
            _mintedCount[msg.sender] += count;
        }
        _safeMint(msg.sender, count);
    }
    
}