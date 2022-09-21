// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
 
import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
 
contract web3nation is ERC721A, Ownable {
    uint256 public TOTAL_SUPPLY = 7777;
    uint256 public RESERVED_SUPPLY = 1000;
    uint256 public mintPrice = 0.0089 ether;
    uint256 public maxPerWallet = 5;
 
    bool isRevealed = false;
    string public baseURI = "";
    string public preRevealedURI = "ipfs://QmNQcA77UhLDoGWBSRGEuTe71Co8PBaSFCwQ4cyX83ri3L";
    bool public saleStarted;
 
    address constant otherWallet = 0x34598784Ed520c3499499119393d388dc16c9C58;
 
    mapping(address => bool) public whitelist;
 
    constructor() ERC721A("web3nation", "w3") {}
 
    // ======== PUBLIC MINTING FUNCTIONS ========
 
    function publicMint(uint256 _quantity) external payable {
        require(_quantity > 0, "quantity invalid");
        require(saleStarted, "sale has not started");
        require(
            _quantity + totalSupply() <= TOTAL_SUPPLY - RESERVED_SUPPLY,
            "Exceed total supply"
        );
        require(
            balanceOf(msg.sender) + _quantity <= maxPerWallet,
            "exceed max per wallet"
        );
        if (whitelist[msg.sender]) {
            require(msg.value >= (_quantity - 1) * mintPrice, "not enough eth");
            _mint(msg.sender, _quantity);
            whitelist[msg.sender] = false;
            RESERVED_SUPPLY -= 1;
        } else {
            require(msg.value >= _quantity * mintPrice, "not enough eth");
            _mint(msg.sender, _quantity);
        }
    }
 
    // ======== UTILS ========
 
 
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!isRevealed) {
            return preRevealedURI;
        }
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            );
    }
 
    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }
 
    // ======== WITHDRAW ========
 
    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool y, ) = payable(owner()).call{value: amount * 97 / 100}("");
        (bool x, ) = payable(otherWallet).call{value: amount * 3 / 100}("");
        require(x);
        require(y);
    }
 
    // ======== SETTERS ========
 
    function teamMint(uint256 _quantity) external onlyOwner {
        require(
            _quantity + totalSupply() <= TOTAL_SUPPLY,
            "Exceed total supply"
        );
        _mint(msg.sender, _quantity);
    }
 
    function setWhitelist(address[] calldata _whitelists) external onlyOwner {
        for (uint256 i = 0; i < _whitelists.length; i++) {
            whitelist[_whitelists[i]] = true;
        }
    }
 
    function setRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }
 
    function setMintPrice(uint256 _public) public onlyOwner {
        mintPrice = _public;
    }
 
    function setBaseURI(string calldata _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
 
    function setPrerevealedURI(string calldata _preRevealedURI)
        public
        onlyOwner
    {
        preRevealedURI = _preRevealedURI;
    }
 
    function setTotalSupply(uint256 _supply) public onlyOwner {
        TOTAL_SUPPLY = _supply;
    }
 
    function setReservedSupply(uint256 _supply) public onlyOwner {
        RESERVED_SUPPLY = _supply;
    }
 
    function setSaleStarted(
        bool _saleStarted
    ) public onlyOwner {
        saleStarted = _saleStarted;
    }
}