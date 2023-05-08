// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract MinArtClub is
    ERC721A,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    //Basic Settings
    uint256 public maxSupply = 4999 ; //Collection supply - change to 8888
    uint256 public price = 0 ether; //Sale Price
    uint256 public perTxCap = 3; //Max NFT per transaction
    uint256 public maxMint = 3; //Max NFT per wallet

    bool public paused = true;

    //Reveal-Non Reveal
    string public _baseTokenURI;
    string public _baseTokenEXT;
    string public notRevealedUri;
    bool public revealed = false;

    //Whitelist Settings
    bool public whitelistSale = false;
    uint256 public whitelistMaxMint = 1; //Max NFT per wallet during WL
    uint256 public whitelistPrice = 0 ether;
    bytes32 public merkleRoot;

    //Admin Reserve Count
    uint256 public reserved = 549; //Admin Reserve Count
    uint256 public reservedClaimed = 0; //Admin Reserve Claimed Count

    //Royalty Settings
    address public royaltyAddress = 0x26CC086A7e561F7329d2529172872dc1609A80FB;
    uint96 public royaltyFee = 750; //7.5% royalty

    //MAP User mints
    mapping(address => uint256) public userWLMints;
    mapping(address => uint256) public userMints;

    constructor() ERC721A("min Art Club", "MAC") {
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //Mints NFTs
    function mint(uint256 _mintAmount) public payable nonReentrant {
        require(tx.origin == msg.sender, "No Contracts Allowed");
        require(!paused, "Contract Minting Paused");
        require(!whitelistSale, ": Cannot Mint During Whitelist Sale");
        require(_mintAmount <= perTxCap, "Exceeds per Transaction Limit");
        require(msg.value >= price * _mintAmount, "Insufficient Fund");
        require(
            userMints[msg.sender] + _mintAmount <= maxMint,
            "Exceeds Max Mint Limit"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            ": No more NFTs to mint,decrease the quantity or check out OpenSea."
        );
        _safeMint(msg.sender, _mintAmount);
        userMints[msg.sender] += _mintAmount;
    }

    //Whitelist mint function
    function whitelistMint(
        uint256 _mintAmount,
        bytes32[] calldata merkleProof
    ) public payable nonReentrant {
        require(tx.origin == msg.sender, "No Contracts Allowed");
        require(!paused, "Contract Minting Paused");
        require(whitelistSale, ": Cannot Mint During Regular Sale");
        require(_mintAmount <= whitelistMaxMint, "Exceeds Presale Limit");
        require(msg.value >= whitelistPrice * _mintAmount, "Insufficient Fund");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            ": No more NFTs to mint,decrease the quantity or check out OpenSea."
        );
        require(
            userWLMints[msg.sender] + _mintAmount <= whitelistMaxMint,
            "You have already minted the max allowed"
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "You are Not whitelisted"
        );
        _safeMint(msg.sender, _mintAmount);
        userWLMints[msg.sender] += _mintAmount;
    }

    //Airdrop function
    function _airdrop(
        uint256 amount,
        address[] memory _address
    ) public onlyOwner {
        uint256 _mintAmount = _address.length * amount;
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Airdrop Exceeds MaxSupply"
        );
        require(
            _mintAmount + reservedClaimed <= reserved,
            "Airdrop Exceeds Reserved Supply"
        );
        for (uint256 i = 0; i < _address.length; i++) {
            _safeMint(_address[i], amount);
        }
        reservedClaimed += _mintAmount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        } else {
            string memory currentBaseURI = _baseURI();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            _baseTokenURI,
                            tokenId.toString(),
                            _baseTokenEXT
                        )
                    )
                    : "";
        }
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    // Enable Whitelist
    function toggleWhiteList() public onlyOwner {
        whitelistSale = !whitelistSale;
    }

    //Pause-Unpause
    function togglePause() public onlyOwner {
        paused = !paused;
    }

    //SET BASE URI
    function changeURLParams(
        string memory _nURL,
        string memory _nBaseExt
    ) public onlyOwner {
        _baseTokenURI = _nURL;
        _baseTokenEXT = _nBaseExt;
    }

    //SET REGULAR MINT MAX
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    //SET Whitelist Price
    function setWLPrice(uint256 newPrice) public onlyOwner {
        whitelistPrice = newPrice;
    }

    //SET Merkle Root
    function setMerkleRoot(bytes32 merkleHash) public onlyOwner {
        merkleRoot = merkleHash;
    }

    //Change the royalty fee for the collection - denominator out of 10000

    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
        emit RoyaltyFees(royaltyAddress, royaltyFee);
    }

    //Change the royalty address where royalty payouts are sent
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
        emit RoyaltyFees(royaltyAddress, royaltyFee);
    }

    //Withdraw Balance
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    event RoyaltyFees(address, uint96);
    event Received(address, uint256);

    //Receive external funds
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    //OpenSea registry overrides
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

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