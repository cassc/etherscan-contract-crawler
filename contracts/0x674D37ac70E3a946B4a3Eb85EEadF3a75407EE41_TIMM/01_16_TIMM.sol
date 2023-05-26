//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./SaleLib.sol";

//import "hardhat/console.sol";

contract TIMM is ERC721, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using SaleLib for SaleLib.Sale;

    // Max tokens that will ever exists
    uint256 constant MAX_SUPPLY = 10499;

    // Number of reserved tokens for the team.
    uint256 constant RESERVED_SUPPLY = 1000;

    // Reserved tokens for the TIMM team.
    mapping(address => uint256) public teamMinted;

    // Number of reserved NFTs minted so far
    uint256 public mintedReserved = 0;

    // Number of public NFTs minted so far
    uint256 public mintedPublic = 0;

    // Base URL for tokens metadata
    string public baseTokenURI;

    string _contractURI;

    // Community address where funds will be sent.
    address payable public communityAddress;

    // Keeps track of minted tokens
    uint256 internal _tokenCounter = 0;

    bytes32 public teamMerkleRoot = 0;

    SaleLib.Sale[] public sales;

    constructor() ERC721("The Infinite Machine Movie", "INFINITE") {}

    function getActiveSaleId() public view returns (uint256) {
        for (uint256 i = 0; i < sales.length; i++) {
            if (sales[i].isActive()) {
                return i;
            }
        }

        revert("No active sale found");
    }

    // Public mint sale
    function mint(
        uint256 pSaleId,
        address pAccount,
        uint256 pMintAmount,
        bytes32[] memory pProof
    ) public payable nonReentrant {
        require(pSaleId < sales.length, "Invalid sale id");
        SaleLib.Sale storage sale = sales[pSaleId];
        require(sale.isActive(), "Sale is not active");

        // Check if its whitelisted, if whitelist stage has not finished.
        if (block.timestamp <= sale.whitelistEndTime) {
            require(
                MerkleProof.verify(
                    pProof,
                    sales[pSaleId].merkleRoot,
                    keccak256(abi.encodePacked(pAccount))
                ),
                "Account not whitelisted"
            );
        }

        require(
            pMintAmount > 0 && pMintAmount <= sale.maxMintPerTx,
            "Invalid mint amount"
        );

        // Requested amount should be between 0 and maxMintPerTx
        require(
            balanceOf(pAccount) + pMintAmount <= sale.maxMintPerAccount,
            "Max minting exceeded"
        );

        // Sale not started
        require(block.timestamp >= sale.startTime, "Sale not started");

        // Sale not paused
        require(sale.isPaused == false, "Sale not active");

        require(sale.minted + pMintAmount <= sale.stock, "Not enough stock for mint stage");

        // Sent value should be at least the price * requested amount
        uint256 price = sale.getSalePrice();
        require(msg.value >= price * pMintAmount, "Not enough amount paid");

        // Total requested minted should not exceed for MAX SUPPLY - RESERVED SUPPLY
        require(
            mintedPublic + pMintAmount <= (MAX_SUPPLY - RESERVED_SUPPLY),
            "sold out"
        );

        // mint each requested token
        _mintMultipleUnsafe(pAccount, pMintAmount);
        // update minted public value
        mintedPublic += pMintAmount;
        // Update minted amount of sale
        sales[pSaleId].minted += pMintAmount;
    }

    // Mint reserved tokens
    function teamMint(
        address account,
        uint256 pProofAmount,
        uint256 pMintAmount,
        bytes32[] memory proof
    ) public nonReentrant {
        require(
            isTeamWhitelisted(account, pProofAmount, proof),
            "Team account not whitelisted or invalid amount"
        );
        // Make sure the recipient has reserved amount
        require(
            teamMinted[account] + pMintAmount <= pProofAmount,
            "Ammount exceeds whitelisted amount"
        );

        // Mint multiple unsafe
        _mintMultipleUnsafe(account, pMintAmount);

        // Add amount to mintedReserved
        mintedReserved += pMintAmount;
        teamMinted[account] += pMintAmount;
    }

    /// @dev mint multiple tokens and update the counter after all minted, rather than
    ///  in the loop.
    function _mintMultipleUnsafe(address pAccount, uint256 pAmount) private {
        // Mint each token
        for (uint256 i = 1; i <= pAmount; i++) {
            uint256 newTokenId = _tokenCounter + i;
            _mint(pAccount, newTokenId);
        }
        _tokenCounter += pAmount;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenCounter;
    }

    function publicAvailableSupply() public view returns (uint256) {
        return MAX_SUPPLY - RESERVED_SUPPLY - mintedPublic;
    }

    function reservedAvailableSupply() public view returns (uint256) {
        return RESERVED_SUPPLY - mintedReserved;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function withdrawFunds() public {
        require(communityAddress != address(0), "Community address not set");
        communityAddress.transfer(address(this).balance);
    }

    function isTeamWhitelisted(
        address account,
        uint256 amount,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(account, amount));
        return (MerkleProof.verify(proof, teamMerkleRoot, node));
    }

    function createSale(
        uint256 pStartTime,
        uint256 pWhitelistEndTime,
        uint256 pPrice,
        uint256 pEndPrice,
        uint256 pDutchTimeFrame,
        uint256 pMaxMintPerTx,
        uint256 pMaxMintPerAccount,
        uint256 pStock,
        bytes32 pSaleMerkleRoot
    ) public onlyOwner {
        SaleLib.Sale memory sale = SaleLib.createSale(
            pStartTime,
            pWhitelistEndTime,
            pPrice,
            pEndPrice,
            pDutchTimeFrame,
            pMaxMintPerTx,
            pMaxMintPerAccount,
            false,
            pSaleMerkleRoot,
            pStock
        );

        sales.push(sale);
    }

    function getSalePrice(uint256 pSaleId) public view returns (uint256) {
        return sales[pSaleId].getSalePrice();
    }

    function setSale(
        uint256 pSaleId,
        uint256 pStartTime,
        uint256 pWhitelistEndTime,
        uint256 pPrice,
        uint256 pEndPrice,
        uint256 pDutchTimeFrame,
        uint256 pMaxMintPerTx,
        uint256 pMaxMintPerAccount,
        bool pIsPaused,
        uint256 pStock,
        bytes32 pSaleMerkleRoot
    ) public onlyOwner {
        // Valid sale id
        require(pSaleId < sales.length, "Invalid sale id");
        sales[pSaleId] = sales[pSaleId].updateSale(
            pStartTime,
            pWhitelistEndTime,
            pPrice,
            pEndPrice,
            pDutchTimeFrame,
            pMaxMintPerTx,
            pMaxMintPerAccount,
            pIsPaused,
            pSaleMerkleRoot,
            pStock
        );
    }

    function pauseSale(uint256 pSaleId, bool value) public onlyOwner {
        require(sales[pSaleId].isPaused != value, "Invalid pause state");
        sales[pSaleId].isPaused = value;
    }

    // Update baseURI
    function setBaseTokenURI(string memory newbaseTokenURI) public onlyOwner {
        baseTokenURI = newbaseTokenURI;
    }

    // Set community address
    function setCommunityAddress(address payable pCommunityAddress) public onlyOwner {
        communityAddress = pCommunityAddress;
    }

    function setContractURI(string memory pContractURI) public onlyOwner {
        _contractURI = pContractURI;
    }

    function setTeamMerkleRoot(bytes32 pTeamMerkleRoot) public onlyOwner {
        teamMerkleRoot = pTeamMerkleRoot;
    }
}