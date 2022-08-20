//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "hardhat/console.sol";

/**
    _______  _______  __   __  _______  ___      _______  ______    _______ 
    |       ||       ||  | |  ||       ||   |    |   _   ||    _ |  |       |
    |  _____||       ||  |_|  ||   _   ||   |    |  |_|  ||   | ||  |  _____|
    | |_____ |       ||       ||  | |  ||   |    |       ||   |_||_ | |_____ 
    |_____  ||      _||       ||  |_|  ||   |___ |       ||    __  ||_____  |
    _____| ||     |_ |   _   ||       ||       ||   _   ||   |  | | _____| |
    |_______||_______||__| |__||_______||_______||__| |__||___|  |_||_______| V2

*/

contract W3bScholarsV2 is ERC721A, IERC2981, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant PRICE_PER_TOKEN = 0.01 ether;
    uint256 public constant MAX_MINT_PER_COLLAB = 250;
    uint256 public constant VAULTED_SCHOLARS = 231;
    uint256 public constant MAX_PUBLIC_MINT = 5;

    bool public scholarsVaultAvailable = true;

    mapping(address => uint256) public publicMinted;

    bytes32 public merkleRoot;
    mapping(address => bool) private _alreadyMinted;

    bool public isPrivateSaleStarted = false;
    bool public isPublicSaleStarted = false;
    bool public isSaleFinalized = false;

    address public beneficiary;
    string public baseURI;

    address public immutable scholarsGenesisAddress;
    mapping(uint256 => bool) public genesisMinted;

    address[] public collabAddresses;
    mapping(uint256 => mapping(uint256 => bool))
        public collabTokensMintedIndexes;
    mapping(uint256 => uint256) public collabMintCounts;

    constructor(
        address _beneficiary,
        string memory _initialBaseURI,
        address _scholarsGenesis,
        address[] memory _collabAddresses
    ) ERC721A("W3b Scholars NFT", "SCHLRS") {
        beneficiary = _beneficiary;
        baseURI = _initialBaseURI;
        scholarsGenesisAddress = _scholarsGenesis;
        collabAddresses = _collabAddresses;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function isAllowListAlreadyMinted(address addr)
        external
        view
        returns (bool)
    {
        return _alreadyMinted[addr];
    }

    function mintAllowList(bytes32[] calldata merkleProof) public nonReentrant {
        require(isPrivateSaleStarted, "Private sale is not yet started");
        require(!isSaleFinalized, "Sale is already finalized");
        address sender = _msgSender();
        uint256 ts = totalSupply();
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(!_alreadyMinted[sender], "Insufficient mints left");
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(sender))
            ),
            "Invalid proof"
        );

        _alreadyMinted[sender] = true;
        _safeMint(sender, 1);
    }

    function setPrivateSaleStarted(bool _isSaleStarted) public onlyOwner {
        isPrivateSaleStarted = _isSaleStarted;
    }

    function setPublicSaleStarted(bool _isSaleStarted) public onlyOwner {
        isPublicSaleStarted = _isSaleStarted;
    }

    function finalizeSale() public onlyOwner {
        isSaleFinalized = true;
    }

    function mint(uint256 quantity) external payable {
        require(isPublicSaleStarted, "Public sale is not yet started");
        require(!isSaleFinalized, "Sale is already finalized");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        require(
            publicMinted[msg.sender] + quantity <= MAX_PUBLIC_MINT,
            "Maximum of 5 public mints per address"
        );
        require(
            PRICE_PER_TOKEN * quantity <= msg.value,
            "Not enough ETH to purchase"
        );
        publicMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function collabMint(uint256[][] calldata tokenIndexes) external {
        require(
            tokenIndexes.length == collabAddresses.length,
            "Mismatch tokenIndexes length"
        );
        require(isPrivateSaleStarted, "Private sale is not yet started");
        require(!isSaleFinalized, "Sale is already finalized");

        // make sure all the tokens specified are owned by the sender
        for (uint256 i = 0; i < collabAddresses.length; i++) {
            IERC721 collab = IERC721(collabAddresses[i]);
            for (uint256 n = 0; n < tokenIndexes[i].length; n++) {
                uint256 tokenIndex = tokenIndexes[i][n];
                require(
                    collab.ownerOf(tokenIndex) == msg.sender,
                    "Token is not owned by sender"
                );
                // make sure coin isn't already minted
                require(
                    !collabTokensMintedIndexes[i][tokenIndex],
                    "Token is already minted"
                );
            }
        }

        // mint the tokens
        uint256 quantity = 0;
        for (uint256 i = 0; i < collabAddresses.length; i++) {
            for (uint256 n = 0; n < tokenIndexes[i].length; n++) {
                uint256 tokenIndex = tokenIndexes[i][n];
                // if the collection has already minted more than the max or the max supply is exceeded, move on
                if (
                    collabMintCounts[i] == MAX_MINT_PER_COLLAB ||
                    totalSupply() + quantity >= MAX_SUPPLY
                ) {
                    break;
                } else {
                    collabTokensMintedIndexes[i][tokenIndex] = true; // mark token as minted
                    quantity++;
                    collabMintCounts[i]++;
                }
            }
        }

        require(quantity > 0, "No tokens left to mint");
        _safeMint(msg.sender, quantity);
    }

    function isCollabMinted(uint256[][] calldata tokenIndexes)
        external
        view
        returns (bool[] memory)
    {
        uint256 size = 0;
        for (uint256 i = 0; i < tokenIndexes.length; i++) {
            for (uint256 j = 0; j < tokenIndexes[i].length; j++) {
                size++;
            }
        }

        bool[] memory results = new bool[](size);
        uint256 n = 0;
        for (uint256 i = 0; i < tokenIndexes.length; i++) {
            for (uint256 j = 0; j < tokenIndexes[i].length; j++) {
                results[n] = collabTokensMintedIndexes[i][tokenIndexes[i][j]];
                n++;
            }
        }
        return results;
    }

    function mintGenesis(uint256[] calldata tokenIndexes) external {
        require(isPrivateSaleStarted, "Private sale is not yet started");
        require(!isSaleFinalized, "Sale is already finalized");
        require(tokenIndexes.length > 0, "No token indexes provided");
        require(
            MAX_SUPPLY - totalSupply() > 0,
            "Purchase would exceed max supply"
        );

        // make sure all the tokens specified are owned by the sender
        IERC721 scholarContract = IERC721(scholarsGenesisAddress);
        for (uint256 i = 0; i < tokenIndexes.length; i++) {
            require(
                scholarContract.ownerOf(tokenIndexes[i]) == msg.sender,
                "Token is not owned by sender"
            );
            require(
                !genesisMinted[tokenIndexes[i] - 1],
                "Token already used to mint"
            );
        }

        // record as minted
        for (uint256 i = 0; i < tokenIndexes.length; i++) {
            genesisMinted[tokenIndexes[i] - 1] = true;
        }

        uint256 quantity = tokenIndexes.length * 2;
        uint256 remaining = MAX_SUPPLY - totalSupply();
        if (remaining < quantity) {
            quantity = remaining;
        }

        _safeMint(msg.sender, quantity);
    }

    function isGenesisMinted(uint256[] calldata tokenIndexes)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory results = new bool[](tokenIndexes.length);
        for (uint256 i = 0; i < tokenIndexes.length; i++) {
            results[i] = genesisMinted[tokenIndexes[i] - 1];
        }
        return results;
    }

    function mintVault() external onlyOwner {
        require(scholarsVaultAvailable, "Vault is already minted");
        require(
            totalSupply() + VAULTED_SCHOLARS <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        scholarsVaultAvailable = false;
        _safeMint(beneficiary, VAULTED_SCHOLARS);
    }

    function withdraw() public onlyOwner {
        // determine proceeds from the mint
        uint256 contractBalance = address(this).balance;

        // send out 100% to beneficiary
        (bool success, ) = beneficiary.call{value: contractBalance}("");
        require(success, "Withdraw failed");
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "collection.json"));
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice * 750) / 10000;
        return (beneficiary, royaltyAmount);
    }
}