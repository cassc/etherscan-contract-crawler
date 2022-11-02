// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "solmate/src/utils/MerkleProofLib.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "solmate/src/utils/ReentrancyGuard.sol";

contract Djin is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI;

    uint256 public maxSupply = 6000;
    uint256 public mintPrice = 0.029 ether;
    uint256 public maxPerWallet = 10;

    bool public saleActive;

    bytes32 merkleRoot;

    mapping (address => bool) public whiteListClaimed;
    mapping (address => uint256) public publicMints;

    modifier stockCount(uint256 amount_) {
        require(totalSupply() + amount_ <= maxSupply, "Better luck next time, sold out.");
        _;
    }

    constructor() ERC721A("Djin", "Djin") {}

    function mint(uint256 amount_, bytes32[] calldata proof_, bool isWl_) external payable nonReentrant stockCount(amount_) {
        uint256 cost = mintPrice;

        require(saleActive, "Sale has not commenced");
        require(tx.origin == msg.sender, "You can not interact from a contract.");

        if (isWl_) {
            require(!whiteListClaimed[msg.sender], "You have already claimed your mints.");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount_));
            bool isValid = MerkleProofLib.verify(proof_, merkleRoot, leaf);
            if (!isValid) revert("Incorrect Proof");
            cost = 0 ether;
        }

        require(msg.value == amount_ * cost, "Please send the correct amount of ETH in order to mint");
        if (!isWl_) require(publicMints[msg.sender] + amount_ <= maxPerWallet, "You have minted max amount per wallet");

        _mint(msg.sender, amount_);

        if (cost == 0) whiteListClaimed[msg.sender] = true;
        else publicMints[msg.sender] += amount_;
    }

    function teamMint(uint256 amount_) external onlyOwner stockCount(amount_) nonReentrant {
        _mint(msg.sender, amount_);
    }

    function setSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function setMerkleRoot(bytes32 newRoot_) external onlyOwner {
        merkleRoot = newRoot_;
    }

    function setBaseURI(string calldata newURI_) external onlyOwner {
        baseURI = newURI_;
    }

    function changeMintPrice(uint256 newPrice_) external onlyOwner {
        mintPrice = newPrice_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}