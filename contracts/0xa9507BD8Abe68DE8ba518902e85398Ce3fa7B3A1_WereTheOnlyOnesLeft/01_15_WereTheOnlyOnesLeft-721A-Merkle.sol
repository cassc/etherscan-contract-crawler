//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WereTheOnlyOnesLeft is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant FRIENDS_AND_FAMILY_SUPPLY = 2222;
    uint256 public constant WHITELIST_SUPPLY = 1111;

    uint256 public constant MAX_PER_WALLET = 1;

    uint256 public constant MAX_RESERVED_SUPPLY = 50;

    enum Stage {
        FriendsAndFamily,
        Whitelist,
        Public,
        SaleClosed
    }
    bool public isFriendsAndFamilyStage = false;
    bool public isWhitelistStage = false;
    bool public isPublicStage = false;

    bytes32 public rootFriendsAndFamily;
    bytes32 public rootWhitelist;

    bool public revealed = false;

    string public notRevealedUri;
    string public baseTokenURI;

    event welcomeToWereTheOnlyOnesLeft(uint256 indexed totalMinted);

    constructor(string memory _initNotRevealedUri)
        ERC721A("WereTheOnlyOnesLeft", "WTOOL")
    {
        setNotRevealedURI(_initNotRevealedUri);
    }

    modifier mintIsOpen() {
        require(totalSupply() <= MAX_SUPPLY, "Soldout!");
        require(
            isFriendsAndFamilyStage || isWhitelistStage || isPublicStage,
            "Mint is not open yet!"
        );
        _;
    }

    // For promotional purposes
    function devMint(address to, uint256 quantity) public onlyOwner {
        require(quantity > 0, "Quantity cannot be zero");

        uint256 amountMintedByOwner = numberMinted(to);
        require(
            amountMintedByOwner.add(quantity) <= MAX_RESERVED_SUPPLY,
            "Cannot mint more than reserved!"
        );

        uint256 totalMinted = totalSupply();
        require(totalMinted.add(quantity) <= MAX_SUPPLY, "No more NFTs left");

        _safeMint(to, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _baseNotRevealedURI()
        internal
        view
        virtual
        returns (string memory)
    {
        return notRevealedUri;
    }

    function getCurrentStage() public view returns (uint256) {
        if (isPublicStage) {
            return uint256(Stage.Public);
        }
        if (isWhitelistStage) {
            return uint256(Stage.Whitelist);
        }
        if (isFriendsAndFamilyStage) {
            return uint256(Stage.FriendsAndFamily);
        }

        return uint256(Stage.SaleClosed);
    }

    function setMerkleFriendsAndFamilyRoot(bytes32 _merkleRoot)
        public
        onlyOwner
    {
        rootFriendsAndFamily = _merkleRoot;
    }

    function setMerkleWhitelistRoot(bytes32 _merkleRoot) public onlyOwner {
        rootWhitelist = _merkleRoot;
    }

    function setIsFriendsAndFamilyStage(bool _isFriendsAndFamilyStage)
        public
        onlyOwner
    {
        isFriendsAndFamilyStage = _isFriendsAndFamilyStage;
    }

    function setIsWhitelistStage(bool _isWhitelistStage) public onlyOwner {
        isWhitelistStage = _isWhitelistStage;
    }

    function setIsPublicStage(bool _isPublicStage) public onlyOwner {
        isPublicStage = _isPublicStage;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setReveal(bool _setReveal) public onlyOwner {
        revealed = _setReveal;
    }

    function mint(
        uint256 _amountOfTokens,
        bytes32[] memory _proof,
        uint256 _stage
    ) public payable mintIsOpen {
        require(
            totalSupply() + _amountOfTokens <= MAX_SUPPLY,
            "Reached Max Supply"
        );

        uint256 amountMintedSender = numberMinted(msg.sender);
        require(
            amountMintedSender.add(_amountOfTokens) <= MAX_PER_WALLET,
            "Cannot mint more than maximum!"
        );

        if (isPublicStage) {
            _safeMint(msg.sender, _amountOfTokens);
        } else {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _stage));

            if (isWhitelistStage) {
                require(
                    MerkleProof.verify(_proof, rootWhitelist, leaf) ||
                        MerkleProof.verify(_proof, rootFriendsAndFamily, leaf),
                    "Invalid merkle proof for whitelist or friends and family"
                );
                _safeMint(msg.sender, _amountOfTokens);
            } else if (isFriendsAndFamilyStage) {
                require(
                    totalSupply() + _amountOfTokens <=
                        FRIENDS_AND_FAMILY_SUPPLY,
                    "No more friends and family supply"
                );
                require(
                    MerkleProof.verify(_proof, rootFriendsAndFamily, leaf),
                    "Invalid merkle for friends and family proof"
                );
                _safeMint(msg.sender, _amountOfTokens);
            }
        }

        emit welcomeToWereTheOnlyOnesLeft(totalSupply());
    }

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

        string memory currentBaseURI = _baseURI();

        if (revealed == false) {
            currentBaseURI = _baseNotRevealedURI();
        }

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
}