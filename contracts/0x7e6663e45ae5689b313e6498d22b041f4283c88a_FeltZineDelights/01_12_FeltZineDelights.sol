// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~ Gardens of Felt Zine Delights ~~~
~~~ Executive Producer: Mark Sabb ~~ 
~~~ Artist: Ty Vadovich ~~~~~~~~~~~~
~~~ Developer: Max Bochman ~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FeltZineDelights is 
    ERC721A, 
    IERC2981, 
    ReentrancyGuard, 
    Ownable 
{

    // =========== CONSTANTS ==========

    // Calculated using merkletreejs
    bytes32 public merkleRoot =
        0xa6f5476e67c0641efc5c7bc19198e5768c87ab6bc6a0ed05712ceed4432e82df;

    uint16 public MAX_SUPPLY = 750;

    uint8 public MAX_MINT_BATCH_SIZE = 5;

    uint256 public FZ_HOLDERS_MINT_PRICE = 20000000000000000;

    uint256 public PUBLIC_MINT_PRICE = 40000000000000000;

    string public contractURI =
        "ipfs://QmUzAt4dBhkZk4uZ3JZh9n36Mh4ivmfs6rVXbm56pLMhZz";

    string private baseURI;


    // ========== MODIFIERS ==========

    // Allows user to mint tokens at a quantity
    modifier canMintTokens(uint256 quantity) {
        require(quantity + _totalMinted() <= MAX_SUPPLY, "Trying to mint over limit set by MAX_SUPPLY");

        _;
    }

    // ========== CONSTRUCTOR ==========

    constructor(string memory baseURI_) ERC721A("Gardens of Felt Zine Delights", "GFZD") {
        baseURI = baseURI_;
        _currentIndex = _startTokenId();
    }

    // ========== SINNERS & SAINTS ==========

    mapping(uint256 => string) public sinners_and_saints;

    // Updates mapping for token Ids minted with a judgmenet value passed in by minter
    function updateSinnersAndSaints(uint256 tokenId, string memory judgement) private {
        sinners_and_saints[tokenId] = judgement ;
    }

    // ========== MINTING FUNCTIONALITY ==========

    // Start token ID for minting (1-100 vs 0-99)
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    uint256 private _currentIndex;

    // Internal Mint Function
    function _mintNFTs(address to, uint256 quantity) internal {
        do {
            uint256 toMint = quantity > MAX_MINT_BATCH_SIZE
                ? MAX_MINT_BATCH_SIZE
                : quantity;
            _mint({to: to, quantity: toMint });
            quantity -= toMint;
        } while (quantity > 0);
    }

    // Public Mint Function
    function publicMint(uint256 quantity, string memory judgement)
        canMintTokens(quantity)
        nonReentrant
        external
        payable
    {
        require(msg.value == PUBLIC_MINT_PRICE * quantity, "Wrong price");

        _mintNFTs(msg.sender, quantity);

        uint256 tokenToMap = _currentIndex;

        _currentIndex += quantity;

        for(uint i = 0; i < quantity; i++)  {
            updateSinnersAndSaints(tokenToMap, judgement);
            tokenToMap += 1;
        } 
    }

    // Felt Zine Holders Mint Function
    function fzHoldersMint(
        uint256 quantity,
        bytes32[] calldata _merkleProof,
        string memory judgement
    )
        canMintTokens(quantity)
        nonReentrant
        external
        payable
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "msg.sender not on holders list"
        );

        require(msg.value == FZ_HOLDERS_MINT_PRICE * quantity, "Wrong price");

        _mintNFTs(msg.sender, quantity);

        uint256 tokenToMap = _currentIndex;

        _currentIndex += quantity;

        for(uint i = 0; i < quantity; i++)  {
            updateSinnersAndSaints(tokenToMap, judgement);
            tokenToMap += 1;
        } 
    }

    // ========== URI FUNCTIONALITY ==========

    function setBaseURI(string memory newBaseURI_) external onlyOwner {
        baseURI = newBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId)));
    }

    // ========== ROYALTY FUNCTIONALITY ==========

    function royaltyInfo(uint256, uint256 salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * 1000) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    receive() external payable {}

    // ========== PAYOUT FUNCTIONALITY ==========

    address private constant payoutAddress1 =
        0x5e080D8b14c1DA5936509c2c9EF0168A19304202;

    address private constant payoutAddress2 =
        0x6eE3b72BE4Af576d15949649Adb8EDC0858DD6FE;

        address private constant payoutAddress3 =
        0x806164c929Ad3A6f4bd70c2370b3Ef36c64dEaa8;

    // Distributes value held in contract to the 3 defined payout addresses
    function withdraw() public nonReentrant {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(payoutAddress1), balance * 375 / 1000);

        Address.sendValue(payable(payoutAddress2), balance * 375 / 1000);
        
        Address.sendValue(payable(payoutAddress3), balance * 250 / 1000);
    }

    function withdrawTokens(IERC20 token) public nonReentrant onlyOwner {
        uint256 balance = token.balanceOf(address(this));

        token.transfer(payoutAddress1, balance * 375 / 1000);

        token.transfer(payoutAddress2, balance * 375 / 1000);
        
        token.transfer(payoutAddress3, balance * 250 / 1000);
    }   

}