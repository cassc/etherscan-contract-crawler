//  _______  ______    _______  ___   _  _______  __    _    _______  ___      __   __  _______ 
// |  _    ||    _ |  |       ||   | | ||       ||  |  | |  |       ||   |    |  | |  ||  _    |
// | |_|   ||   | ||  |   _   ||   |_| ||    ___||   |_| |  |       ||   |    |  | |  || |_|   |
// |       ||   |_||_ |  | |  ||      _||   |___ |       |  |       ||   |    |  |_|  ||       |
// |  _   | |    __  ||  |_|  ||     |_ |    ___||  _    |  |      _||   |___ |       ||  _   | 
// | |_|   ||   |  | ||       ||    _  ||   |___ | | |   |  |     |_ |       ||       || |_|   |
// |_______||___|  |_||_______||___| |_||_______||_|  |__|  |_______||_______||_______||_______|
// 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MerkleProof.sol";

interface IBrokenToken {
    function update(address from, address to) external;
}

contract BrokenClub is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    IBrokenToken public BrokenToken;
    
    uint256 public PUBLIC_MINT_PRICE = 0.05 ether;
    uint256 public WL_MINT_PRICE = 0.03 ether;
    uint256 private MAX_TOKENS_PER_TRANSACTION = 100;
    uint256 public MAX_SUPPLY = 6263;
    uint256 public PUBLIC_MINT_MAX_SUPPLY = 5263;
    uint256 private FREE_MINTS = 1000;

    bool public revealed = false;
    bool public whitelistEnabled = false;
    bool public saleStatus = false;

    string private notRevealedUri = "ipfs://QmQamMwgW5zscetw15RXdwuBBgvMCkmrbL2K8YWNa76ZF6";

    string public _baseTokenURI = "";
    string private _baseTokenSuffix = ".json";

    address stream = 0xdB6646776D2766Be4A0528936738fBDeD256Bc4B;

    constructor() ERC721A("BrokenClub", "BrokenClub") {
    }

    // START - Setters
    function setBrokenTokenAddress(address account) public onlyOwner {
        BrokenToken = IBrokenToken(account);
    }

    function setWhitelistStatus(bool status) external onlyOwner {
        whitelistEnabled = status;
    }

    function setSaleStatus(bool status) external onlyOwner {
        saleStatus = status;
    }

    function setMintMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        MAX_SUPPLY = _newMaxSupply;
    }

    function setPublicMintMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        PUBLIC_MINT_MAX_SUPPLY = _newMaxSupply;
    }

    function setPublicMintPrice(uint256 _newPrice) external onlyOwner {
        PUBLIC_MINT_PRICE = _newPrice;
    }

    function setWLMintPrice(uint256 _newPrice) external onlyOwner {
        WL_MINT_PRICE = _newPrice;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function setRevealStatus(bool status) public onlyOwner {
        revealed = status;
    }
    // END - Setters

    // START - Overrides
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        virtual
        nonReentrant 
    {
        if (address(BrokenToken) != address(0)) {
            BrokenToken.update(from, to);
        }
        ERC721A.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        virtual
        nonReentrant
    {
        if (address(BrokenToken) != address(0)) {
            BrokenToken.update(from, to);
        }

        ERC721A.safeTransferFrom(from, to, tokenId, data);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Provided token ID doesnot exist."
        );

        if (!revealed) {
            return notRevealedUri;
        }
        string memory baseURI = _baseTokenURI;
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        _baseTokenSuffix
                    )
                )
                : "";
    }
    // END - Overrides

    // START - Minting
    function whitelistMint(uint256 _count, bytes32[] calldata proof, bytes32 merkleRoot) external payable {
        require(whitelistEnabled, "Whitelist sale is not yet active!");
        uint256 supply = totalSupply();
        require(_count < MAX_TOKENS_PER_TRANSACTION, "Count exceeded max tokens per transaction.");
        require(supply + _count < MAX_SUPPLY, "Exceeds max supply.");
        require(_verify(_leaf(msg.sender), proof, merkleRoot), "Not a whitelisted member!");
        require(msg.value >= WL_MINT_PRICE * _count, "Ether sent is not correct.");

        _safeMint(msg.sender, _count, "");
    }

    function mint(uint256 _count) external payable {
        uint256 supply = totalSupply();
        require(_count < MAX_TOKENS_PER_TRANSACTION, "Count exceeded max tokens per transaction.");
        require(supply + _count < PUBLIC_MINT_MAX_SUPPLY, "No more minting possible.");
        require(saleStatus, "Public sale is not yet active!");

        if (supply + _count > FREE_MINTS) {
            require(msg.value >= PUBLIC_MINT_PRICE * _count, "Ether sent is not correct.");
        }

        _safeMint(msg.sender, _count, "");
    }
    // END - Minting

    // START - Transactions
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(stream).transfer(balance);
    }
    // END - Transactions

    // START - Merkle whitelisting
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }
    // Verify that a given leaf is in the tree.
    function _verify(bytes32 _leafNode, bytes32[] memory proof, bytes32 merkleRoot) internal pure returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, _leafNode);
    }
    // END - Merkle whitelisting
}