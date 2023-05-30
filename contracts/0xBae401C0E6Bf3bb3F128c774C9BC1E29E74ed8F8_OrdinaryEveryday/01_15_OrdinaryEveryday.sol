//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract OrdinaryEveryday is ERC721A, Ownable, ReentrancyGuard {
    enum MintStatus {
        Guarantee,
        PublicMint,
        Paused
    }

    using Strings for uint256;

    MintStatus public mintStatus = MintStatus.Paused;
    bytes32 public merkleRoot;
    uint256 public constant maxSupply = 7777;
    uint256 public price = 0.033 ether;
    uint256 public maxPerWallet = 4;

    uint256 public constant maxFreeSupply = 2222;
    uint256 public totalFreeMintSupply;

    bool public revealed;
    string public baseURI;
    string public hiddenMetadataUri = "ipfs://QmUUA3nNodQGYN2edr21ohu2vzmmwGRHu8WCZwZbRVbgq5";
    mapping (address => bool) public freeMinted;
    mapping (address => uint256) public userMinted;

    constructor (bytes32 _merkleRoot) ERC721A("Ordinary Everyday", "ODED") {
        merkleRoot = _merkleRoot;
        _safeMint(msg.sender, 1);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function publicMint(uint256 amount) public payable callerIsUser nonReentrant {
        require(mintStatus == MintStatus.PublicMint, "Public mint is not active");
        require(userMinted[msg.sender] + amount <= maxPerWallet, "Requested Mint Amount Exceeds Limit Per Wallet");
        require(totalSupply() + amount <= maxSupply, "Purchase would exceed max supply of Tokens");
        require(msg.value >= price * amount, "Insufficient funds");

        _safeMint(msg.sender, amount);
        userMinted[msg.sender] += amount;
    }

    function freeMint(uint256 amount, bytes32[] calldata proof) public payable callerIsUser nonReentrant {
        require(mintStatus == MintStatus.Guarantee || mintStatus == MintStatus.PublicMint, "Free mint is not active");
        require(!freeMinted[msg.sender],"Can only mint once during free mint");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid MerkleProof");
        require(totalFreeMintSupply + amount <= maxFreeSupply, "Purchase would exceed max supply of Tokens");

        _safeMint(msg.sender, amount);
        freeMinted[msg.sender] = true;
        totalFreeMintSupply += amount;
    }

    function setMintStatus(MintStatus status) public onlyOwner {
        mintStatus = status;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxPerWallet(uint256 _newAmount) external onlyOwner {
        maxPerWallet = _newAmount;
    }

    function setURI(uint256 _type, string memory _uri) external onlyOwner {
        if(_type == 1) {
            hiddenMetadataUri = _uri;
        } else if(_type == 2) {
            baseURI = _uri;
            revealed = true;
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
            : "";
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;
        address community     = payable(0x83748611C94e32A0fC4B0AF3d84FC51b3240B689);
        address marketing   = payable(0x5f3f603Bdc0BB0Af3f28a2F4e211852131752C9A);
        address developer   = payable(0x7A244e747953e8043ACc9c851C431284242E9686);

        bool success;

        (success, ) = community.call{value: (sendAmount * 75/100)}(""); // 70%
        require(success, "Transaction Unsuccessful");

        (success, ) = marketing.call{value: (sendAmount * 125/1000)}(""); // 12.5%
        require(success, "Transaction Unsuccessful");

        (success, ) = developer.call{value: (sendAmount * 125/1000)}(""); // 12.5%
        require(success, "Transaction Unsuccessful");
    }

    function withdrawToken(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transferFrom(address(this), owner(), _amount);
    }
}