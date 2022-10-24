//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WomansWorld is ERC721A, Ownable, ReentrancyGuard {

    struct CustomMetadata {
        string URI;
        bool status;
    }

    struct UpdateMetadata {
        uint256 tokenId;
        string uri;
    }

    uint256 public maxSupply = 2222;
    uint256 public maxMintNum = 5;
    uint256 public mintPrice;
    uint256 public whitePrice = 0.005 ether;
    uint256 public blackPrice = 0.007 ether;
    uint256 public whiteMintCount = 5;
    uint256 public publicMintCount = 3;

    bool public revealed;
    bool public isPublic;

    string private defaultURI;
    string private BaseURI;
    bytes32 public whitelistRoot;

    mapping(uint256 => CustomMetadata) private customizedMetadata;
    mapping(address => uint256) public mintedNumber;
    mapping(address => uint256) public whiteMintedNumber;
    mapping(address => bool) public excludedAccount;

    event Revealed(uint256 revealedTimestamp);
    event Withdraw(address to, uint256 amount);

    constructor(string memory _BaseURI, string memory _defaultURI) ERC721A("Woman's world", "WW") {
        BaseURI = _BaseURI;
        defaultURI = _defaultURI;
    }

    function mint(uint256 quality, bytes32[] memory proof) public nonReentrant payable {
        require(quality + totalSupply() <= maxSupply, "NFT supply is full");

        if (!excludedAccount[msg.sender] && msg.sender != owner()) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            bool whitelisted = MerkleProof.verify(proof, whitelistRoot, leaf);
            uint256 payFee;

            require(balanceOf(msg.sender) <= 5, "Exiceed maximum balance limit" );

            uint256 whited = whiteMintedNumber[msg.sender];
            uint256 minted = mintedNumber[msg.sender];

            if (!isPublic) {

                
                require(quality <= whiteMintCount, "Exceed maximum mint count");
                require(whitelisted, "Sender is not in whitelist");
                require(minted + quality <= whiteMintCount && balanceOf(msg.sender) + quality <= whiteMintCount , "Exceed maximum");
                
                if (minted + quality > 2) {
                    payFee = whitePrice * (quality - (2 - whited));
                }
    
                if (whited < 2) whiteMintedNumber[msg.sender] = (minted + quality) >= 2 ? 2 : ++ whited;
            } else {
                
                require(quality <= publicMintCount, "Exceed maximum mint count");
                
                if (whitelisted) {
                    if (minted + quality > 3) {
                        payFee = blackPrice * (quality - (3 - whited));
                    }

                    if (whited < 3) whiteMintedNumber[msg.sender] = (minted + quality) >= 3 ? 3 : (whited + quality);
                }
                else {
                    if (whited == 0) whiteMintedNumber[msg.sender] ++;
                    payFee = blackPrice * (quality - (1 - whited));
                }
            }
            
            require(msg.value >= payFee, "Not enough fee");
    
            if (msg.value - payFee > 0) payable(msg.sender).transfer(msg.value - payFee);        
            mintedNumber[msg.sender] += quality;
        }
        _mint(msg.sender, quality);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (!revealed) return defaultURI;
        if (customizedMetadata[tokenId].status) return customizedMetadata[tokenId].URI;

        string memory baseURI = _baseURI();
        
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : defaultURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return BaseURI;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        require(balanceOf(to) < 5, "Exceed maximum balance limit");
        super.transferFrom(from, to, tokenId);
    }

    function reveal() external onlyOwner {
        revealed = true;
        emit Revealed(block.timestamp);
    }

    function updateMetadata(UpdateMetadata[] memory _URIs) external onlyOwner {
        require(_URIs.length > 0, "WW: empty uris");
        for (uint256 i; i < _URIs.length; i ++) {
            customizedMetadata[_URIs[i].tokenId] = CustomMetadata(_URIs[i].uri, true);
        }
    }

    function updateMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function updateWhitelistRoot(bytes32 root) external onlyOwner {
        whitelistRoot = root;
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
        emit Withdraw(to, amount);
    }

    function updateBulkExcludeAccounts(address[] memory accounts, bool status) external onlyOwner {
        require(accounts.length > 0, "empty list");
        for (uint i; i < accounts.length; i ++) {
            require(accounts[i] != address(0), "invalid address");
            excludedAccount[accounts[i]] = status;
        }
    }

    function updateExcludeAccount(address account, bool status) external onlyOwner {
        require(account != address(0), "invalid address");
        excludedAccount[account] = status;
    }

    function goToPublic(bool status) external onlyOwner {
        isPublic = status;
    }

    function updateWhitePrice(uint256 newPrice) external onlyOwner {
        require(whitePrice != newPrice, "Already set");
        whitePrice = newPrice;
    }

    function updateBlackPrice(uint256 newPrice) external onlyOwner {
        require(blackPrice != newPrice, "Already set");
        blackPrice = newPrice;
    }

    function updateWhiteMintCount(uint256 count) external onlyOwner {
        require(count > 0, "People can mint 1 NFT at least");
        require(!isPublic, "Minting is gone to public");

        whiteMintCount = count;
    }

    function updatePublicMintCount(uint256 count) external onlyOwner {
        require(count > 0, "People can mint 1 NFT at least");

        publicMintCount = count;
    }

    receive() external payable {

    }
}