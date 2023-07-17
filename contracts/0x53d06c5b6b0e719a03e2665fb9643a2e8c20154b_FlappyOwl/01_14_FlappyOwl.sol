// SPDX-License-Identifier: MIT
/*********************************
*                ///             *
*              (o,O)             *
*           ///( :~)\\\          *
*              ~"~"~             *
**********************************
*   Flappy Owl #420        * #69 *
**********************************
*   BUY NOW               * \_/" *
**********************************/

/*
* ** author  : Gasless Labs   
* ** package : @contracts/ERC721/FlappyOwl.sol
*/

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "../utils/IFlappyOwlFactory.sol";

contract FlappyOwl is 
    ERC721A,
    DefaultOperatorFilterer,
    Ownable,
    ReentrancyGuard {
    using Strings for uint256;

    mapping(uint256 => uint256) internal seeds;
    mapping(address => uint256) public mintCount;

    bool public isPublicMint = true;

    IFlappyOwlFactory public factory;
    uint256 public maxSupply = 21000;
    uint256 public mintCost = 0.005 ether;
    uint256 public maxMintPerWallet = 21;
    uint256 royalties = 5;

    address public beneficiaryAddress;
    address public royaltyAddress;

    constructor(
        IFlappyOwlFactory newFactory
    ) ERC721A("FlappyOwl", "o,O") {
        beneficiaryAddress = owner();
        royaltyAddress = owner();
        factory = newFactory;
    }

    function mint(uint256 _mintAmount) public payable nonReentrant mintRequire(_mintAmount) {
        require(isPublicMint, "Sold out!");
        require(
            mintCount[msg.sender] + _mintAmount <= maxMintPerWallet,
            "Per wallet limit reached!"
        );
        require(
            msg.value >= mintCost * _mintAmount,
            "Insufficient funds!"
        );
        mintCount[msg.sender] += _mintAmount;

        _genSeed(_mintAmount);
        _safeMint(msg.sender, _mintAmount);
        if (totalSupply() >= maxSupply) {
            isPublicMint = false;
        }
        if (address(this).balance > 0) {
            payable(beneficiaryAddress).transfer(address(this).balance);
        }
    }

    /*---------------------------------------------------------------------
    * this airdrop function, used for project growth, and collaboration.
    -----------------------------------------------------------------------*/
    function airdrop(
        address[] memory _recipients,
        uint256 _mintAmount
    ) external onlyOwner nonReentrant {
        require(_mintAmount > 0, "Invalid mint amount!");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Will exceed maximum supply!"
        );
        uint256 count = _recipients.length;
        for (uint256 i = 0; i < count; i++) {
            _genSeed(_mintAmount);
            _safeMint(_recipients[i], _mintAmount);
        }
        if (totalSupply() >= maxSupply) {
            isPublicMint = false;
        }
    }

    /*---------------------------------------------------------------------
    *                       modifier and other operations
    ---------------------------------------------------------------------*/
    modifier mintRequire(uint256 _mintAmount) {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(_mintAmount > 0, "Invalid mint amount!");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Will exceed maximum supply!"
        );
        _;
    }
    function getmintCount() public view returns (uint256) {
        return mintCount[msg.sender];
    }

    function setSoldOut(bool value) external onlyOwner {
        isPublicMint = value;
    }

    function setFactory(IFlappyOwlFactory newFactory) external onlyOwner {
        factory = newFactory;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist.");
        uint256 seed = seeds[tokenId];
        return factory.tokenURI(tokenId, seed);
    }

    /*---------------------------------------------------------------------
    *                        Seed factory function
    ---------------------------------------------------------------------*/
    function getSeed(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token ID does not exist.");
        return seeds[tokenId];
    }

    function _genSeed(uint256 _mintAmount) internal {
        uint256 nextTokenId = _nextTokenId();
        for (uint256 i = 0; i < _mintAmount; i++) {
            seeds[nextTokenId] = generateSeed(nextTokenId);
            ++nextTokenId;
        }
    }
    
    function generateSeed(uint256 tokenId) private view returns (uint256) {
        uint256 r = random(tokenId);
        uint256 headSeed = 100 * ((r % 7) + 10) + (((r >> 48) % 20) + 10);
        uint256 faceSeed = 100 *
            (((r >> 96) % 6) + 10) +
            (((r >> 96) % 20) + 10);
        uint256 bodySeed = 100 *
            (((r >> 144) % 7) + 10) +
            (((r >> 144) % 20) + 10);
        uint256 legsSeed = 100 *
            (((r >> 192) % 2) + 10) +
            (((r >> 192) % 20) + 10);
        return
            10000 *
            (10000 * (10000 * headSeed + faceSeed) + bodySeed) +
            legsSeed;
    }

    function random(
        uint256 tokenId
    ) private view returns (uint256 pseudoRandomness) {
        pseudoRandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );
        return pseudoRandomness;
    }

    /*---------------------------------------------------------------------
    *                        Foundation setup
    ---------------------------------------------------------------------*/
    function updateFoundationAddress(
        address _beneficiaryReceiver,
        address _royaltiesReceiver
    ) public onlyOwner {
        beneficiaryAddress = _beneficiaryReceiver;
        royaltyAddress = _royaltiesReceiver;
    }

    function updateRoyalties(uint256 _royalties) public onlyOwner {
        royalties = _royalties;
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        _tokenId; // silence solc warning
        receiver = royaltyAddress;
        royaltyAmount = (royalties * _salePrice) / 100;
    }

    /*---------------------------------------------------------------------
    *                        Operator filter
    ---------------------------------------------------------------------*/
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}