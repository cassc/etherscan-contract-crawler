/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@YJP#@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@
@@@@@G5?77JPB&@@@@@@@@@@@@@&[email protected]@@@
@@@@G7YPGG5J77?5B&@@@@@&GY?!7JPGG5J7&@@@
@@@@[email protected]@@
@@@@#[email protected]#PJ77?5B#J~~~5#GY?!7YG#@[email protected]@@@
@@@@@B!~5&@@@#J^[email protected]~~~#@!~5&@@@BJ~?&@@@@
@@@@@@&[email protected][email protected]~~~#@[email protected][email protected]@@@@@
@@@@@@@@@#[email protected][email protected]~~~#@[email protected]&@@@@@@@@
@@@@@@@@@@@@@@Y^[email protected]!!!&&[email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@#J~7P#&#5!!Y&@@@@@@@@@@@@@
@@@@@@@@@@@@&&@@#[email protected]~5&@@&@@@@@@@@@@@@
@@@@@@@@@@@@[email protected]@Y^[email protected][email protected]&5!#@@@@@@@@@@@
@@@@@@@@@@@@&[email protected]@@@@@@@@@@@
@@@@@@@@@@@@@@#Y5#GJ?YB#Y5&@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer, OperatorFilterer} from "./enforce/DefaultOperatorFilterer.sol";

contract LeagueLionsOpen is
    ERC721A,
    Pausable,
    Ownable,
    DefaultOperatorFilterer
{
    /*============================VIP_SALE_VARS==========================================*/
    bytes32 public MERKLE_ROOT_VIP = 0x0;
    bool public VIP_MINT_STATUS = false;
    // Price is Free

    /*============================PARTNER_SALE_VARS======================================*/
    bytes32 public MERKLE_ROOT_PARTNER = 0x0;
    uint256 public PRICE_PARTNER = .015 ether;
    bool public PARTNER_MINT_STATUS = false;

    /*============================LEAGUELIST_SALE_VARS===================================*/
    bytes32 public MERKLE_ROOT_LEAGUELIST = 0x0;
    uint256 public PRICE_LEAGUELIST = .019 ether;
    bool public LEAGUELIST_MINT_STATUS = false;

    /*============================PUBLIC_SALE_VARS=======================================*/
    uint256 public PRICE = .024 ether;
    bool public PUBLIC_MINT_STATUS = false;

    uint256 public maxMint = 5;
    string public baseURI;
    string public uriSuffix = ".json";
    bool public isRevealed = false;
    string public preRevealURI = "asdnsajkd.json";

    address public swapContract;

    bytes32 private NFTS_ROOT;
    mapping(address => uint256) public walletMints;

    constructor() ERC721A("League of Lions - One", "LOL1") {}

    /*============================PARTNER_SALE_FUNCS======================================*/
    function setPricePartnerSale(uint256 newPrice) public onlyOwner {
        PRICE_PARTNER = newPrice;
    }

    function setRootPartnerSale(bytes32 root) public onlyOwner {
        MERKLE_ROOT_PARTNER = root;
    }

    function togglePartnerSaleStatus() public onlyOwner {
        PARTNER_MINT_STATUS = !PARTNER_MINT_STATUS;
    }

    /*============================LEAGUELIST_SALE_FUNCS===================================*/
    function setPriceLeagueListSale(uint256 newPrice) public onlyOwner {
        PRICE_LEAGUELIST = newPrice;
    }

    function setRootLeagueListSale(bytes32 root) public onlyOwner {
        MERKLE_ROOT_LEAGUELIST = root;
    }

    function toggleLeagueListSaleStatus() public onlyOwner {
        LEAGUELIST_MINT_STATUS = !LEAGUELIST_MINT_STATUS;
    }

    /*============================VIP_SALE_FUNCS==========================================*/
    function setRootVIPSale(bytes32 root) public onlyOwner {
        MERKLE_ROOT_VIP = root;
    }

    function toggleVIPSaleStatus() public onlyOwner {
        VIP_MINT_STATUS = !VIP_MINT_STATUS;
    }

    /*============================PUBLIC_SALE_FUNCS=======================================*/
    function setPrice(uint256 newPrice) public onlyOwner {
        PRICE = newPrice;
    }

    function setPreRevealURL(string memory _url) public onlyOwner {
        preRevealURI = _url;
    }

    function togglePublicSaleStatus() public onlyOwner {
        PUBLIC_MINT_STATUS = !PUBLIC_MINT_STATUS;
    }

    function setMaxMint(uint256 newMax) public onlyOwner {
        maxMint = newMax;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _url) public onlyOwner {
        baseURI = _url;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERROR: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            isRevealed
                ? (
                    bytes(currentBaseURI).length > 0
                        ? string(
                            abi.encodePacked(
                                currentBaseURI,
                                Strings.toString(_tokenId),
                                uriSuffix
                            )
                        )
                        : ""
                )
                : preRevealURI;
    }

    function ownerMint(address to, uint256 qty) public onlyOwner {
        _safeMint(to, qty);
    }

    function mint(
        address to,
        uint256 qty,
        bytes32[] calldata _merkleProof
    ) public payable {
        require(
            walletMints[msg.sender] + qty <= maxMint,
            "Sorry, You minted the max amount per wallet"
        );
        require(qty > 0, "Need to mint at least 1");
        bytes32 leaf = keccak256(abi.encode(msg.sender));
        if (mintCheck(_merkleProof, MERKLE_ROOT_VIP, leaf) && VIP_MINT_STATUS) {
            walletMints[msg.sender] += qty;
            _safeMint(to, qty);
        } else if (
            mintCheck(_merkleProof, MERKLE_ROOT_PARTNER, leaf) &&
            PARTNER_MINT_STATUS
        ) {
            require(msg.value >= PRICE_PARTNER * qty, "Error: Wrong Amount");
            walletMints[msg.sender] += qty;
            _safeMint(to, qty);
        } else if (
            mintCheck(_merkleProof, MERKLE_ROOT_LEAGUELIST, leaf) &&
            LEAGUELIST_MINT_STATUS
        ) {
            require(msg.value >= PRICE_LEAGUELIST * qty, "Error: Wrong Amount");
            walletMints[msg.sender] += qty;
            _safeMint(to, qty);
        } else {
            require(PUBLIC_MINT_STATUS, "Error: Public Mint is not Live!");
            require(msg.value >= PRICE * qty, "Error: Wrong Amount public");
            walletMints[msg.sender] += qty;
            _safeMint(to, qty);
        }
    }

    function mintCheck(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        if (from != address(0)) {
            for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
                if (msg.sender != swapContract) {
                    address owner = ownerOf(i);
                    require(
                        owner == msg.sender,
                        "Only the owner of NFT can transfer or burn it"
                    );
                }
            }
        }
    }

    function setSwapContract(address newSwap) public onlyOwner {
        swapContract = newSwap;
    }

    function burnCustom(uint256 tokenId) public {
        require(
            swapContract == msg.sender,
            "ONLY OUR SMART CONTRACT CAN CALL THIS"
        );
        _burn(tokenId, false);
    }

    function setReveal(bool status, string memory revealURI) public onlyOwner {
        isRevealed = status;
        baseURI = revealURI;
    }

    function setNFTsRoot(bytes32 root) public onlyOwner {
        NFTS_ROOT = root;
    }

    function verifyDNA(
        bytes32[] memory proof,
        uint256 id,
        uint256 adn
    ) public view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(id, adn))));
        return MerkleProof.verify(proof, NFTS_ROOT, leaf);
    }

    // OpenSea Enforcer functions
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}