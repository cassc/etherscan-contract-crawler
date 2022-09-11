// SPDX-License-Identifier: MIT
//
//
//                                         .:~!!~^.
//             .~?Y5PP5Y?~:            .7G&@@@@@@@@@#Y^
//         :J#@@@@&###&@@@@@#5^      :[email protected]@BJ!~^^::~Y&@@@&7
//       ?&@@#J:   ..::::^[email protected]@@&J   [email protected]@?!YB&&@@@#Y. [email protected]@@#.
//     [email protected]@@J.  :Y#@@@@@@@&G!:7&@@@P&@G^[email protected]@B. .#@@@.
//    [email protected]@5   7&@@&P??Y55?!P&@[email protected]@@@G.~:J&@@@@P  [email protected]@.  &@@B
//   #@@?  .#@@&~.J&@@@@@?  :#@^[email protected]@@. :@@@@@@@J    [email protected]  ^@@@.
//  [email protected]@G   #@@G [email protected]@@@@@@@Y    [email protected]:[email protected]&  [email protected]@@@@#~      &&   @@@~
//  @@@:  [email protected]@& [email protected]@@@@@@@5      [email protected]@. .JP57.   .~.  @#  :@@@:
// [email protected]@@.  [email protected]@B [email protected]@@@@@P:       J&[email protected]@G          &@G [email protected]^  #@@&
//  &@@!  :@@&  :7?!:     ~!.  #Y^@@@P          ^J&@^  [email protected]@@:
//  [email protected]@&   [email protected]@G          [email protected]@B Y#.&@@@@&?^~!!7?5G#B!  [email protected]@@&:
//   [email protected]@#.  [email protected]@&!         [email protected]@@@@@@@GJ7!!~^:^[email protected]@@&?
//    [email protected]@@7   ?&@@BJ~:::~75GY^!&@@@B::?G&@@@@@@@@@@@#5^
//     [email protected]@@Y:  .~YGBBGPY7^^?&@@@#~       .:^~!~~^.
//       .7#@@@BY!^:::^!JG&@@@&Y:
//          .~JG#&@@@@@@&&BY!.
//                 ....
//
//
//    WhoopRooms (https://whooprooms.com)
//    Author: @GrizzlyDesign

pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./MerkleProof.sol";
import "./Address.sol";

contract Rooms is ERC721AQueryable, ERC721ABurnable, Ownable {
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public mintableSupply = MAX_SUPPLY;

    uint256 private maxMintGuestList = 3;
    uint256 private maxMintVip = 2;
    uint256 public mintRound = 0;

    uint256 public publicMintPrice = 0.04 ether;
    uint256 public guestListMintPrice = 0.02 ether;

    bool public publicSale = false;
    bool public guestListSale = false;
    bool public revealed = false;
    bytes32 private guestListMerkleRoot;
    bytes32 private vipListMerkleRoot;
    mapping(uint256 => mapping(address => uint256)) private vipMintCount;
    mapping(uint256 => mapping(address => uint256)) private guestMintCount;

    string private baseURI;
    string private notRevealedUri;
    string private baseExtension = ".json";

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A(_name, _symbol) {
        baseURI = _initBaseURI;
        notRevealedUri = _initNotRevealedUri;
    }

    /**
     * @notice Toggle the public sale
     */
    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    modifier publicSaleActive() {
        require(publicSale, "Public Sale Not Started");
        _;
    }

    /**
     * @notice Toggle the guestList sale
     */
    function toggleGuestListSale() external onlyOwner {
        guestListSale = !guestListSale;
    }

    modifier guestListSaleActive() {
        require(guestListSale, "guestList Sale Not Started");
        _;
    }

    /**
     * @notice Public minting
     * @param _quantity - Quantity to mint
     */
    function mintPublic(uint256 _quantity)
        public
        payable
        publicSaleActive
        hasCorrectAmount(publicMintPrice, _quantity)
        withinMintableSupply(_quantity)
    {
        _mint(msg.sender, _quantity);
    }

    modifier hasCorrectAmount(uint256 price, uint256 quantity) {
        require(msg.value >= price * quantity, "Insufficent Funds");
        _;
    }

    modifier withinMintableSupply(uint256 quantity) {
        require(
            _totalMinted() + quantity <= mintableSupply,
            "Surpasses Supply"
        );
        _;
    }

    /**
     * @notice Set the merkle root for the guestList verification
     * @param merkleRoot - guestList merkle root
     */
    function setGuestListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        guestListMerkleRoot = merkleRoot;
    }

    /**
     * @notice Set the merkle root for the vipList verification
     * @param merkleRoot - guestList merkle root
     */
    function setVipListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        vipListMerkleRoot = merkleRoot;
    }

    /**
     * @param quantity - The quantity to mint
     * @param merkleProof - Proof to verify guestList
     */
    function mintGuestList(uint256 quantity, bytes32[] calldata merkleProof)
        public
        payable
        guestListSaleActive
        hasValidMerkleProof(merkleProof, guestListMerkleRoot)
        hasCorrectAmount(guestListMintPrice, quantity)
        withinMintableSupply(quantity)
    {
        uint256 netMinted = (guestMintCount[mintRound][msg.sender] += quantity);
        require((netMinted <= maxMintGuestList), "Max Guest List Mints.");
        _mint(msg.sender, quantity);
    }

    function mintVip(uint256 quantity, bytes32[] calldata merkleProof)
        public
        payable
        hasValidMerkleProof(merkleProof, vipListMerkleRoot)
        withinMintableSupply(quantity)
    {
        uint256 netMinted = (vipMintCount[mintRound][msg.sender] += quantity);
        require((netMinted <= maxMintVip), "Max Free Mints.");
        _mint(msg.sender, quantity);
    }

    modifier hasValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address Not Listed"
        );
        _;
    }

    /**
     * @notice Admin mint
     * @param recipient - The receiver of the NFT
     * @param quantity - The quantity to mint
     */
    function mintAdmin(address recipient, uint256 quantity)
        external
        onlyOwner
        withinMintableSupply(quantity)
    {
        _mint(recipient, quantity);
    }

    /**
     * @notice Allow adjustment of minting price
     * @param publicPrice - Public mint price in wei
     * @param guestListPrice - guestList mint price in wei
     */
    function setMintPrice(uint256 publicPrice, uint256 guestListPrice)
        external
        onlyOwner
    {
        publicMintPrice = publicPrice;
        guestListMintPrice = guestListPrice;
    }

    /**
     * @notice Allow adjustment of minting price
     * @param guestListLimit - guestList mint price in wei
     */
    function setMaxMintGuestList(uint256 guestListLimit) external onlyOwner {
        maxMintGuestList = guestListLimit;
    }

    /**
     * @notice Allow adjustment of mintable supply
     * @param supply - Mintable supply, limited to the maximum supply
     */
    function setMintableSupply(uint256 supply) external onlyOwner {
        require(
            supply >= _totalMinted() && supply <= MAX_SUPPLY,
            "Invalid Supply"
        );
        mintableSupply = supply;
    }

    /**
     * @dev Set the minting round
     */
    function setMintRound(uint256 round) external onlyOwner {
        mintRound = round;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param baseURI_ - The Base URI of the NFT
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    /**
     * @dev Returns the Base URI of the NFT
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (revealed == false) {
            return notRevealedUri;
        }

        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, _toString(tokenId), baseExtension)
                )
                : "";
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Withdrawal of funds
     */

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}