// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Nijigen is ERC721A, ERC2981 ,ReentrancyGuard,Ownable, Pausable  {
    using Strings for uint256;

    string private baseURI = "ar://Mw9MwSeC7lzz-u_jR8LwgQbA9w8SZaq9YbRoExPFxrw/";

    bool public publicSale = false;
    uint256 public publicCost = 0.07 ether;

    bool public mintable = false;
    address public royaltyAddress;
    uint96 public royaltyFee = 1000;

    uint256 constant public MAX_SUPPLY = 3333;
    string constant private BASE_EXTENSION = ".json";
    uint256 constant private PUBLIC_MAX_PER_TX = 12;
    uint256 constant private PRE_MAX_CAP = 6;

    address constant private DEFAULT_ROYALITY_ADDRESS = 0x7c7cda26Fd518d5202234e3B4b389102a79F7eC5;
    address constant private BULK_TRANSFER_ADDRESS = 0xcBE664d197f27f8D26F272Dd71f2a20B89C953EC;

    mapping(TicketID => uint256) public presaleCost;
    mapping(TicketID => bool) public presalePhase;
    mapping(TicketID => bytes32) public merkleRoot;
    mapping(TicketID => mapping(address => uint256)) public whiteListClaimed;

    enum TicketID {
        WL1,
        WL2
    }

    constructor() ERC721A("Nijigen", "NIJIGEN") {
        _setDefaultRoyalty(DEFAULT_ROYALITY_ADDRESS, royaltyFee);
        _mintERC2309(BULK_TRANSFER_ADDRESS, 332);
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

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot, TicketID ticket) external onlyOwner {
        merkleRoot[ticket] = _merkleRoot;
    }

    function publicMint(uint256 _mintAmount) public
    payable
    whenNotPaused
    whenMintable
    callerIsUser
    nonReentrant
    {
        uint256 cost = publicCost * _mintAmount;
        mintCheck(_mintAmount, cost);
        require(publicSale, "Public Sale is not Active.");
        require(
            _mintAmount <= PUBLIC_MAX_PER_TX,
            "Mint amount over"
        );

        _mint(msg.sender, _mintAmount);
    }


    function preMint(uint256 _mintAmount, uint256 _presaleMax, bytes32[] calldata _merkleProof, TicketID ticket)
        public
        payable
        whenMintable
        callerIsUser
        whenNotPaused
        nonReentrant
    {
        uint256 cost = presaleCost[ticket] * _mintAmount;
        require(_presaleMax <= PRE_MAX_CAP,"presale max can not exceed");
        mintCheck(_mintAmount,  cost);
        require(presalePhase[ticket], "Presale is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot[ticket], leaf),
            "Invalid Merkle Proof"
        );

        require(
            whiteListClaimed[ticket][msg.sender] + _mintAmount <= _presaleMax,
            "Already claimed max"
        );

        _mint(msg.sender, _mintAmount);
         whiteListClaimed[ticket][msg.sender] += _mintAmount;
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

    function setPresalePhase(bool _state, TicketID ticket) public onlyOwner {
        presalePhase[ticket] = _state;
    }

    function setPreCost(uint256 _preCost, TicketID ticket) public onlyOwner {
        presaleCost[ticket] = _preCost;
    }

    function setPublicCost(uint256 _publicCost) public onlyOwner {
        publicCost = _publicCost;
    }

    function setPublicPhase(bool _state) public onlyOwner {
        publicSale = _state;
    }

    function setMintable(bool _state) public onlyOwner {
        mintable = _state;
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
        Address.sendValue(payable(0x7c7cda26Fd518d5202234e3B4b389102a79F7eC5), address(this).balance);
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
        // - CantBeEvil
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

}