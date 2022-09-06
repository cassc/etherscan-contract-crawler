// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**

███╗   ██╗███████╗████████╗███████╗██╗   ██╗███████╗    ██╗     ██╗███████╗███████╗████████╗██╗███╗   ███╗███████╗    ██████╗  █████╗ ███████╗███████╗
████╗  ██║██╔════╝╚══██╔══╝██╔════╝╚██╗ ██╔╝██╔════╝    ██║     ██║██╔════╝██╔════╝╚══██╔══╝██║████╗ ████║██╔════╝    ██╔══██╗██╔══██╗██╔════╝██╔════╝
██╔██╗ ██║█████╗     ██║   █████╗   ╚████╔╝ █████╗      ██║     ██║█████╗  █████╗     ██║   ██║██╔████╔██║█████╗      ██████╔╝███████║███████╗███████╗
██║╚██╗██║██╔══╝     ██║   ██╔══╝    ╚██╔╝  ██╔══╝      ██║     ██║██╔══╝  ██╔══╝     ██║   ██║██║╚██╔╝██║██╔══╝      ██╔═══╝ ██╔══██║╚════██║╚════██║
██║ ╚████║██║        ██║   ███████╗   ██║   ███████╗    ███████╗██║██║     ███████╗   ██║   ██║██║ ╚═╝ ██║███████╗    ██║     ██║  ██║███████║███████║
╚═╝  ╚═══╝╚═╝        ╚═╝   ╚══════╝   ╚═╝   ╚══════╝    ╚══════╝╚═╝╚═╝     ╚══════╝   ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝    ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝
                                                                                                                                                      
 */
contract NFTEyeLifetimePass is ERC721A, Ownable, Pausable, ReentrancyGuard {
    bytes32 private _merkleRoot;
    string private _baseTokenURI;

    uint256 public constant PUBLIC_SALE_PRICE = 0.3 ether;
    uint256 public constant PRESALE_PRICE = 0.1721 ether;
    uint256 public constant DISCOUNT_PRESALE_PRICE = 0.15 ether;
    uint256 public constant MAX_MINT_PER_ADD = 3;
    uint256 public MAX_RESERVE = 721;
    uint256 public MAX_SALE = 7000;
    uint256 public saleMinted;
    uint256 public reserveMinted;
    bool public presaleActive = false;
    bool public referralMintActive = false;
    bool public publicMintActive = false;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Contract is not allowed to mint.");
        _;
    }

    event ReferralMinted(
        address account,
        address referrerAddress,
        uint256 quantity
    );

    constructor() ERC721A("CyberDegens - NFTEye Lifetime Pass", "NLP") {
        _baseTokenURI = "https://api.nfteye.io/api/nlp_meta/";
    }

    function preSale(uint256 quantity, bytes32[] memory proof)
        public
        payable
        whenNotPaused
        callerIsUser
    {
        if (!presaleActive) revert("Presale is not active");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(proof, _merkleRoot, leaf),
            "The current address is not in the whitelist"
        );

        uint256 remainder = MAX_MINT_PER_ADD - _numberMinted(msg.sender);
        require(quantity <= remainder, "Exceeded maximum mints per address");
        require(quantity >= 1, "Quantity should no less than 1");
        require(
            saleMinted + quantity <= MAX_SALE,
            "Exceeded maximum sale supply"
        );
        uint256 totalValue;
        if (remainder > 1) {
            totalValue =
                1 *
                PRESALE_PRICE +
                (quantity - 1) *
                DISCOUNT_PRESALE_PRICE;
        } else {
            totalValue = quantity * PRESALE_PRICE;
        }
        require(msg.value >= totalValue, "Insufficient ether");
        saleMinted += quantity;
        _mint(msg.sender, quantity);
    }

    function referralMint(
        uint256 quantity,
        address referrerAddress,
        bytes32[] memory proof
    ) public payable whenNotPaused callerIsUser {
        if (!referralMintActive) revert("ReferralMint is not active");
        require(
            _numberMinted(referrerAddress) > 0,
            "Referrer account not minted"
        );
        bytes32 leaf = keccak256(abi.encodePacked(referrerAddress));
        require(
            MerkleProof.verify(proof, _merkleRoot, leaf),
            "Referrer address not in whitelist"
        );

        uint256 remainder = MAX_MINT_PER_ADD - _numberMinted(msg.sender);
        require(quantity <= remainder, "Exceeded maximum mints per address");
        require(quantity >= 1, "Quantity should no less than 1");
        require(
            saleMinted + quantity <= MAX_SALE,
            "Exceeded maximum sale supply"
        );
        uint256 totalValue = quantity * PRESALE_PRICE;
        require(msg.value >= totalValue, "Insufficient ether");
        saleMinted += quantity;
        _mint(msg.sender, quantity);
        emit ReferralMinted(msg.sender, referrerAddress, quantity);
    }

    function publicMint(uint256 quantity)
        public
        payable
        whenNotPaused
        callerIsUser
    {
        if (!publicMintActive) revert("PublicMint is not active");
        require(
            saleMinted + quantity <= MAX_SALE,
            "Exceeded maximum sale supply"
        );
        uint256 totalValue = quantity * PUBLIC_SALE_PRICE;
        require(msg.value >= totalValue, "Insufficient ether");
        saleMinted += quantity;
        _mint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity, address to)
        public
        whenNotPaused
        onlyOwner
    {
        require(
            reserveMinted + quantity <= MAX_RESERVE,
            "Exceeded maximum reserve supply"
        );
        reserveMinted += quantity;
        _mint(to, quantity);
    }

    function setPresaleStatus(bool status) public onlyOwner {
        presaleActive = status;
    }

    function setReferralMintStatus(bool status) public onlyOwner {
        referralMintActive = status;
    }

    function setPublicMintStatus(bool status) public onlyOwner {
        publicMintActive = status;
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getMerkleRoot() public view onlyOwner returns (bytes32) {
        return _merkleRoot;
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        _merkleRoot = merkleRoot_;
    }

    function isValidForReferral(address referrerAddress)
        public
        view
        returns (bool)
    {
        return _numberMinted(referrerAddress) > 0;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}