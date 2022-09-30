// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Amabiee is ERC721A, Ownable {
    enum MintStatus {
        PENDING,
        WHITELIST_MINT,
        PUBLIC_MINT,
        FINISHED
    }

    string  public baseTokenURI;

    string  public defaultTokenURI;

    uint256 constant public maxSupply = 6666;

    uint256 public whitelistStartTime = 1664542800; // Tue Sep 30 2022 22:00:00 GMT+07

    uint256 public publicStartTime = 1664546400; // Tue Sep 30 2022 23:00:00 GMT+07

    uint256 constant public publicPrice = 0.008 ether;

    uint256 public whitelistMinted;

    uint256 public publicMinted;

    mapping(address => uint256) public whitelistMintedMap;

    mapping(address => uint256) public publicMintedMap;

    bytes32 private _merkleRoot;
    
    MintStatus public mintStatus;

    constructor(
        string memory defaultTokenURI_,
        bytes32 merkleRoot_
    ) ERC721A("Amabiee", "AMB") {
        defaultTokenURI = defaultTokenURI_;
        _merkleRoot = merkleRoot_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "caller is another contract");
        _;
    }

    function whiteListMint(uint256 quantity, bytes32[] calldata _merkleProof) external callerIsUser {
        require(mintStatus == MintStatus.WHITELIST_MINT && block.timestamp >= whitelistStartTime, "Not in whitelist stage");
        require(_totalMinted() + quantity <= maxSupply, "Exceed supply");
        require(whitelistMinted + quantity <= 1400, "Exceed whitelist supply");
        require(isInWhitelist(msg.sender, _merkleProof), "Caller is not in whitelist");
        require(whitelistMintedMap[msg.sender] + quantity <= 2, "Exceed per-user whitelist supply");

        whitelistMinted += quantity;
        whitelistMintedMap[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external callerIsUser payable {
        require(
            (mintStatus == MintStatus.PUBLIC_MINT && block.timestamp >= publicStartTime) || whitelistMinted >= 1400,
            "Not in public stage"
        );

        uint256 totalMinted = _totalMinted();
        require(totalMinted + quantity <= maxSupply, "Exceed supply");
        require(publicMintedMap[msg.sender] + quantity <= 2, "This address has finished public mint");

        uint256 remainFree = 0;
        if (3000 > totalMinted) {
            remainFree = 3000 - totalMinted;
        }
        if (quantity > remainFree) {
            uint256 price = (quantity - remainFree) * publicPrice;
            require(msg.value >= price, "Not enough ether paid for");
        }

        publicMinted += quantity;
        publicMintedMap[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    function isInWhitelist(address _address, bytes32[] calldata _signature) public view returns (bool) {
        return MerkleProof.verify(_signature, _merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : defaultTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setMintStatus(uint256 status) external onlyOwner {
        mintStatus = MintStatus(status);
    }

    function setPublicStartTime(uint256 startime) external onlyOwner {
        publicStartTime = startime;
    }

    function setAllowlistStartTime(uint256 startime) external onlyOwner {
        whitelistStartTime = startime;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setBaseURI(string calldata baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function withdraw() external onlyOwner {
        (bool success,) = payable(owner()).call{value : address(this).balance}("");
        require(success, "Withdraw failed.");
    }
}