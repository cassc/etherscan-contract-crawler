//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721APausable.sol";

contract RetroArcadeCollection is ERC721APausable, Ownable, ReentrancyGuard {
    string private baseURI;
    string public baseExtension = ".json";

    uint256 nftPerAddressLimit = 1;

    uint256 public RETRO_PRICE = 0;

    uint256 public TOTAL_TOKENS = 3999;
    uint256 public WHITELIST_MINT_COUNT = 2289;

    bytes32 public preSaleMerkleRoot;

    bool public revealed = false;
    bool public publicSaleOpen = false;

    address public creatorAddress = 0x6b0f422A3f461B6ef20Eacc5BdB329e3e3712871;

    string private notRevealedUri;

    mapping(address => uint256) public addressMintedBalance;

    event retroArcadeNFTMinted(address sender, uint256 tokenId);

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier underMaxSupply(uint256 quantity) {
        require(totalSupply() + quantity <= TOTAL_TOKENS, "Exceeds max supply");
        _;
    }

    modifier underWalletMintLimit(uint256 quantity) {
        require(
            addressMintedBalance[msg.sender] + quantity <= nftPerAddressLimit
        );
        _;
    }

    constructor(string memory _initNotRevealedUri)
        ERC721A("Retro Arcade Collection", "RAC")
    {
        setNotRevealedURI(_initNotRevealedUri);
    }

    function mintRAC(uint256 quantity) public payable underMaxSupply(quantity) {
        if (msg.sender != owner()) {
            require(publicSaleOpen == true);
            require(
                addressMintedBalance[msg.sender] + quantity <=
                    nftPerAddressLimit
            );
            require(msg.value >= RETRO_PRICE * quantity, "insufficient funds");
            addressMintedBalance[msg.sender] += quantity;
            _safeMint(msg.sender, quantity);
        }
        if (msg.sender == owner()) {
            addressMintedBalance[msg.sender] = 0;
            _safeMint(msg.sender, quantity);
        }
    }

    function mintPresale(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        isValidMerkleProof(merkleProof, preSaleMerkleRoot)
        underMaxSupply(quantity)
        underWalletMintLimit(quantity)
    {
        require(msg.value >= RETRO_PRICE * quantity, "insufficient funds");
        require(
            totalSupply() + quantity <= WHITELIST_MINT_COUNT,
            "Whitelist mints closed"
        );
        addressMintedBalance[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        preSaleMerkleRoot = _root;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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

        if (revealed == false) {
            return
                string(
                    abi.encodePacked(
                        notRevealedUri,
                        "/",
                        Strings.toString(tokenId),
                        baseExtension
                    )
                );
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        "/",
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function setCreatorAddress(address _creatorAddress) public onlyOwner {
        creatorAddress = _creatorAddress;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNFTPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setWhiteListMintCount(uint256 _newCount) public onlyOwner {
        WHITELIST_MINT_COUNT = _newCount;
    }

    function setRetroPrice(uint256 _newPrice) public onlyOwner {
        RETRO_PRICE = _newPrice * (10**16);
    }

    function setPublicSaleOpen(bool _state) public onlyOwner {
        publicSaleOpen = _state;
    }

    function togglePause() public onlyOwner {
        if (paused() == true) {
            _unpause();
        } else if (paused() != true) {
            _pause();
        }
    }

    function setTotalSupply(uint256 _totalTokens) public onlyOwner {
        require(_totalTokens < TOTAL_TOKENS, "Cannot increase supply");
        TOTAL_TOKENS = _totalTokens;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}