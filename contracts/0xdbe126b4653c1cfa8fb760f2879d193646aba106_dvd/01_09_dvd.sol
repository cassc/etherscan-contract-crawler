// SPDX-License-Identifier: MIT
//
// ⠀⠀⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣶⣦⡀
// ⠀⢠⣿⣿⡿⠀⠀⠈⢹⣿⣿⡿⣿⣿⣇⠀⣠⣿⣿⠟⣽⣿⣿⠇⠀⠀⢹⣿⣿⣿
// ⠀⢸⣿⣿⡇⠀⢀⣠⣾⣿⡿⠃⢹⣿⣿⣶⣿⡿⠋⢰⣿⣿⡿⠀⠀⣠⣼⣿⣿⠏
// ⠀⣿⣿⣿⣿⣿⣿⠿⠟⠋⠁⠀⠀⢿⣿⣿⠏⠀⠀⢸⣿⣿⣿⣿⣿⡿⠟⠋⠁⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣸⣟⣁⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⣠⣴⣶⣾⣿⣿⣻⡟⣻⣿⢻⣿⡟⣛⢻⣿⡟⣛⣿⡿⣛⣛⢻⣿⣿⣶⣦⣄⡀⠀
// ⠉⠛⠻⠿⠿⠿⠷⣼⣿⣿⣼⣿⣧⣭⣼⣿⣧⣭⣿⣿⣬⡭⠾⠿⠿⠿⠛⠉⠀

pragma solidity 0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DefaultOperatorFilterer.sol";
import "./ERC721A.sol";

contract dvd is ERC721A, Ownable, DefaultOperatorFilterer {
    uint256 public maxSupply = 5000;
    uint256 public maxMintPerAddress = 5;
    uint256 public freeMintPerAddress = 1;
    uint256 public price = 0.004 ether;
    bool public isSalePaused = true;
    string public baseURI;
    mapping (address => uint256) public addressMints;

    constructor() ERC721A("dvd", "dvd") {}

    function mint(uint256 amount) external payable {
        require(tx.origin == msg.sender, "Contract caller");
        require(!isSalePaused, "Minting is paused");
        require(totalSupply() + amount <= maxSupply, "Amount exceeds max supply");
        require(amount > 0 && amount <= maxMintPerAddress, "Amount exceeds max mint per address");
        require(addressMints[msg.sender] + amount <= maxMintPerAddress, "Amount exceeds max mints for your address");
        
        if (freeMintPerAddress >= addressMints[msg.sender] + amount) {
            addressMints[msg.sender] += amount;
            _safeMint(msg.sender, amount);
        } else {
            require(maxMintPerAddress >= addressMints[msg.sender] + amount && 
                    freeMintPerAddress < addressMints[msg.sender] + amount, "Amount exceeds max mints for address");
            require(msg.value >= price * ((addressMints[msg.sender] + amount) - freeMintPerAddress), "Not enough ETH");
            addressMints[msg.sender] += amount;
            _safeMint(msg.sender, amount);
        }
    }

    function airdrop(uint256 amount, address recipient) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Amount exceeds max supply");
        _safeMint(recipient, amount);
    }

    function setFreeMintPerAddress(uint256 amount) external onlyOwner {
        freeMintPerAddress = amount;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function toggleSalePaused() external onlyOwner {
        isSalePaused = !isSalePaused;
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success);
    }
   
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}