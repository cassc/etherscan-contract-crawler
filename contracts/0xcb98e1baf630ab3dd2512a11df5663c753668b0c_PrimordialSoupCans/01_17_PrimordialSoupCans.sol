// SPDX-License-Identifier: MIT
/***
 *    __________        .__                         .___.__       .__    _________                   _________                       
 *    \______   \_______|__| _____   ___________  __| _/|__|____  |  |  /   _____/ ____  __ ________ \_   ___ \_____    ____   ______
 *     |     ___/\_  __ \  |/     \ /  _ \_  __ \/ __ | |  \__  \ |  |  \_____  \ /  _ \|  |  \____ \/    \  \/\__  \  /    \ /  ___/
 *     |    |     |  | \/  |  Y Y  (  <_> )  | \/ /_/ | |  |/ __ \|  |__/        (  <_> )  |  /  |_> >     \____/ __ \|   |  \\___ \ 
 *     |____|     |__|  |__|__|_|  /\____/|__|  \____ | |__(____  /____/_______  /\____/|____/|   __/ \______  (____  /___|  /____  >
 *                               \/                  \/         \/             \/             |__|           \/     \/     \/     \/ 
 */

pragma solidity 0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/IERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract PrimordialSoupCans is ERC721A, ERC721AQueryable, DefaultOperatorFilterer, Ownable {

    string public baseURI = "ipfs://bafybeibwudsqk5cee7wbrl7sedotuj46jlos3toz7lcyxkay3nv3p64rku/";
    uint256 public price = 0.0025 ether;
    uint256 public publicPrice = 0.0049 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxPerTransaction = 25;
    uint256 public maxPerAuthrTransaction = 50;
    uint256 public maxPerWallet = 100;
    uint256 public maxPerAuthrWallet = 250;

    bool public saleActive;
    bool public holdersSaleActive;
    bytes32 public root = 0xf6c17c1b221873fefff135a770370ff453214be63b3f48c90aec8f36ce337bd8;
    mapping(address => uint256) private redeemedTokens;
    
    constructor () ERC721A("PrimordialSoupCans", "Psoup") {
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function startSale() external onlyOwner {
        require(saleActive == false);
        saleActive = true;
    }

    function startHoldersSale() external onlyOwner {
        require(holdersSaleActive == false);
        holdersSaleActive = true;
    }

    function stopSale() external onlyOwner {
        require(saleActive == true);
        saleActive = false;
    }

    function stopHoldersSale() external onlyOwner {
        require(holdersSaleActive == true);
        holdersSaleActive = false;
    }

    function mint(uint256 value, uint256 amount, bytes32[] calldata proof) public payable {
        require(holdersSaleActive);
        if (proof.length > 0) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, value));
            require(MerkleProof.verify(proof, root, leaf), "Incorrect proof");
            if (redeemedTokens[msg.sender] < value) {
                if (amount + redeemedTokens[msg.sender] <= value) {
                    // Mint the entire amount for free
                    require(totalSupply() + amount <= maxSupply);
                    _safeMint(msg.sender, amount);
                } else {
                    uint256 free;
                    uint256 paid;
                    free = value - redeemedTokens[msg.sender];
                    paid = amount - free;
                    uint256 totalPrice = price * paid;
                    require(msg.value >= totalPrice, "Insufficient funds");
                    require(totalSupply() + amount <= maxSupply);
                    _safeMint(msg.sender, amount);
                }
            }
            else {
                uint256 totalPrice = price * amount;
                require((_numberMinted(msg.sender) + amount) -  value <= maxPerAuthrWallet);
                require(amount <= maxPerAuthrTransaction);
                require(msg.value >= totalPrice, "Insufficient funds");
                require(totalSupply() + amount <= maxSupply);
                _safeMint(msg.sender, amount);
            }
        }
        else{
            require(saleActive);
            require(_numberMinted(msg.sender) + amount <= maxPerWallet);
            require(amount <= maxPerTransaction);
            uint256 totalPrice = publicPrice * amount;
            require(msg.value >= totalPrice, "Insufficient funds");
            require(totalSupply() + amount <= maxSupply);
            _safeMint(msg.sender, amount);
        }

        redeemedTokens[msg.sender] += amount;
    }


    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function updateRoot(bytes32 newRoot) external onlyOwner {
    root = newRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply);
        _safeMint(msg.sender, quantity);
    }

    function treasuryMint(uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= maxSupply);
        require(quantity > 0, "Invalid mint amount");
        require(
            totalSupply() + quantity <= maxSupply,
            "Maximum supply exceeded"
        );
        _safeMint(msg.sender, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }
}