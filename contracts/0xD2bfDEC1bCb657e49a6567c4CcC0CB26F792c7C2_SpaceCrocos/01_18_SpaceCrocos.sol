// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract SpaceCrocos is ERC721A, ERC2981 , Ownable, Pausable {
    using Strings for uint256;

    string private baseURI = "ar://4xEOmNvDzaljGQFt1M9hxiqZ73O6TGN9UrUzjgjXfkM/";

    uint256 public preCost = 0.025 ether;
    uint256 public publicCost = 0.04 ether;
    bool public presale = true;
    uint256 public presale_max = 5;
    bool public mintable = true;
    address public royaltyAddress;
    uint96 public royaltyFee = 500;

    uint256 constant public MAX_SUPPLY = 2200;
    string constant private BASE_EXTENSION = ".json";
    uint256 constant private PUBLIC_MAX_PER_TX = 5;
    address constant private BULK_TRANSFER_ADDRESS = 0x8C4da4F8a860dd2d1F79c1a9370D6400b1aFc452;
    address constant private DEFAULT_ROYALITY_ADDRESS = 0x8C4da4F8a860dd2d1F79c1a9370D6400b1aFc452;
    bytes32 public merkleRoot;
    mapping(address => uint256) private whiteListClaimed;


    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {
        _setDefaultRoyalty(DEFAULT_ROYALITY_ADDRESS, royaltyFee);
        _mintERC2309(BULK_TRANSFER_ADDRESS, 198);
        for (uint256 i; i < 19; ++i) {
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

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION));
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function publicMint(uint256 _mintAmount) public
    payable
    whenNotPaused
    whenMintable
    callerIsUser
    {
        uint256 cost = publicCost * _mintAmount;
        mintCheck(_mintAmount, cost);
        require(!presale, "Presale is active.");
        require(
            _mintAmount <= PUBLIC_MAX_PER_TX,
            "Mint amount over"
        );

        _mint(msg.sender, _mintAmount);
    }

    function preMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        whenMintable
        whenNotPaused
    {
        uint256 cost = preCost * _mintAmount;
        mintCheck(_mintAmount,  cost);
        require(presale, "Presale is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        require(
            whiteListClaimed[msg.sender] + _mintAmount <= presale_max,
            "Already claimed max"
        );

        _mint(msg.sender, _mintAmount);
         whiteListClaimed[msg.sender] += _mintAmount;
    }

    function mintCheck(
        uint256 _mintAmount,
        uint256 cost
    ) private view {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "MAXSUPPLY over"
        );
        require(msg.value >= cost, "Not enough funds");
    }

    function ownerMint(address _address, uint256 count) public onlyOwner {
       _mint(_address, count);
    }

    function setPresale(bool _state) public onlyOwner {
        presale = _state;
    }

    function setPreCost(uint256 _preCost) public onlyOwner {
        preCost = _preCost;
    }

    function setPublicCost(uint256 _publicCost) public onlyOwner {
        publicCost = _publicCost;
    }

    function setMintable(bool _state) public onlyOwner {
        mintable = _state;
    }

    function setPreMax(uint256 _max) public onlyOwner {
        presale_max = _max;
    }

    function getCurrentCost() public view returns (uint256) {
        if (presale) {
            return preCost;
        } else{
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
        Address.sendValue(payable(0xbbb55a828da5e37180C8806cC583384a0C49708D), address(this).balance);
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