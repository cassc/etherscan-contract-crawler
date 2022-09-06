// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title: WasteStinNYC
/// @author: HayattiQ (NFTBoil)

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract WasteStinNYC is ERC721A, ERC2981 , Ownable, Pausable {
    using Strings for uint256;

    string public baseURI = "ar://dFXEk_-aFdHHuP4HGbuBM7u1jhZYesTAFTFeikuj_KA/";
    uint256 public preCost = 0.185 ether;
    uint256 public publicCost = 0.25 ether;

    bool public presale = true;
    bool public mintable = true;

    address public royaltyAddress = 0xeC2C16A4aBD441ef48e1b48D644330302F010923;
    uint96 public royaltyFee = 750;

    uint256 constant public MAX_SUPPLY = 300;
    uint256 constant public PUBLIC_MAX_PER_TX = 2;
    string public constant BASE_EXTENSION = '.json';

    bytes32 public merkleRoot;
    mapping(address => uint256) private whiteListClaimed;


    constructor() ERC721A("WasteStinNYC", "WASTE") {
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
        _mintERC2309(0xf181a3D60AFaB49d93e3f701862C22946F238434, 10);
        _mintERC2309(0xEE26F31b5E27aE18205dBE7f4023f4759933331E , 34);
        for (uint256 i; i < 4; ++i) {
            _initializeOwnershipAt(i * 10);
        }
    }

    modifier whenMintable() {
        require(mintable == true, "Mintable: paused");
        _;
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION));
    }

    function publicMint(uint256 _mintAmount)
        public
        payable
        whenMintable
        whenNotPaused
        callerIsUser
    {
        uint256 cost = publicCost * _mintAmount;
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "MAXSUPPLY over"
        );
        require(msg.value >= cost, "Not enough funds");
        require(!presale, "Presale is active.");
        require(
            _mintAmount <= PUBLIC_MAX_PER_TX,
            "Mint amount over"
        );

        _mint(msg.sender, _mintAmount);
    }

    function preMint(uint256 _mintAmount,uint256 _presaleMax,bytes32[] calldata _merkleProof)
        public
        payable
        whenNotPaused
        whenMintable
    {
        uint256 cost = preCost * _mintAmount;
        require(presale, "Presale is not active.");
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "MAXSUPPLY over"
        );
        require(msg.value >= cost, "Not enough funds");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        require(
            whiteListClaimed[msg.sender] + _mintAmount <= _presaleMax,
            "Already claimed max"
        );

        _mint(msg.sender, _mintAmount);
        whiteListClaimed[msg.sender] += _mintAmount ;
    }


    function ownerMint(address _address, uint256 count) public onlyOwner {
       _mint(_address, count);
    }

    function setPresale(bool _state) public onlyOwner {
        presale = _state;
    }

    function setMintable(bool _state) public onlyOwner {
        mintable = _state;
    }

    function setPreCost(uint256 _preCost) public onlyOwner {
        preCost = _preCost;
    }

    function setPublicCost(uint256 _publicCost) public onlyOwner {
        publicCost = _publicCost;
    }

    function getCurrentCost() public view returns (uint256) {
        if (presale) {
            return preCost;
        } else {
            return publicCost;
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(0x6528575C6D73FD6D349597e5B767CDDb85a0Ae32), address(this).balance);
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
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
}