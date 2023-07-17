// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Payments.sol";
import "./Constants.sol";
import "./Cards.sol";

/**
 * @title Packs
 * @author David Lafeta
 * @notice This contract creates Packs tokens which can be burned to mint Cards.
 * @dev Implementation based on Sector4Cars Contract by Alicenet developers' Troy Salem (Cr0wn_Gh0ul), Hunter Prendergast (et3p), ZJ Lin
 */
contract Packs is ERC721Enumerable, ERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    // Uint256 to string for tokenURI
    using Strings for uint256;
    enum SaleState {
        NO_SALE,
        VIP_SALE,
        PUBLIC_SALE
    }
    Counters.Counter private _packsId;
    Cards internal immutable _cardsContract;
    Payments internal immutable _paymentsContract;
    // Global state storage var
    SaleState internal _saleState;
    // Merke root for allow list
    bytes32 internal _allowedListRoot;
    // Tokens left to mint
    uint256 internal _leftToMint = TOTAL_NUM_PACKS;
    // Tokens left to airdrop
    uint256 internal _leftToAirdrop = TOTAL_NUM_PACKS_AIRDROP;
    // URI for after reveal
    string public baseTokenURI = "";
    // Allow list and VIP minting tracker
    mapping(address => uint256) public listMinted;
    // Number of VIP tokens minted using LightCultCryptoClub tokenID
    mapping(uint256 => uint256) internal _vipMinted;
    // Address of LightCultCryptoClub contract, used for the VIP list sale
    address internal _lcccContract = 0xbE85fBd182af91290be7293438AE67549638189f;
    event PaymentReceived(address from, uint256 amount);
    event SaleStateChanged(SaleState from, SaleState to);

    // Only address in LCCC
    modifier isVIPMinter(uint256 tokenId) {
        require(ERC721(_lcccContract).balanceOf(msg.sender) > 0, "Not an LCCC member");
        require(
            ERC721(_lcccContract).ownerOf(tokenId) == msg.sender,
            "User is not the owner of LCCC tokenId"
        );
        require(
            _vipMinted[tokenId] < MAX_PER_LIST_MINTER,
            "Token already minted maxed allowed of packs in VIP list"
        );
        _;
    }

    // Only address in allow list
    modifier isListMinter(bytes32[] calldata proof_) {
        require(validListMinter(msg.sender, proof_), "Not in allow list");
        _;
    }

    // Only when global sale state is vip sale
    modifier isVIPSale() {
        require(_saleState == SaleState.VIP_SALE, "VIP sale is not open yet");
        _;
    }

    // Only when global sale state is public sale
    modifier isPublicSale() {
        require(_saleState == SaleState.PUBLIC_SALE, "Public sale is not open yet");
        _;
    }

    // Only when global sale state is not public sale
    modifier isNotPublicSale() {
        require(_saleState != SaleState.PUBLIC_SALE, "Airdrop is not open");
        _;
    }

    // Only valid value is sent to public sale
    modifier isValidMintValue() {
        require(msg.value % MINT_PRICE == 0, "Invalid value sent");
        _;
    }

    // Only if vip/whitelist has not minted MAX_PER_LIST_MINTER yet
    modifier isListMintValueAvailable(uint256 amount) {
        require(
            listMinted[msg.sender] + amount <= MAX_PER_LIST_MINTER,
            "User already received max number of packs allowed in VIP list"
        );
        _;
    }

    constructor() ERC721("Area54Packs", "AP") {
        _cardsContract = new Cards(address(this));
        _cardsContract.transferOwnership(msg.sender);
        _paymentsContract = new Payments(address(this));
        _paymentsContract.transferOwnership(msg.sender);
        // Sets secondary sale royalties to 5% of the price and sends them to this contract
        ERC2981._setDefaultRoyalty(address(this), 500);
    }

    receive() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Withdraw all of the ether in this contract slitting it between the contract payees
     */
    function withdraw() external payable {
        (bool success, ) = payable(_paymentsContract).call{value: address(this).balance}("");
        require(success, "Withdraw didn't go through");
        Payments(_paymentsContract).withdraw();
    }

    /**
     * @dev Mint while the Public sale is open
     * Single token price is `MINT_PRICE`
     * the value sent must be equal to or greater than the Mint_Price
     * be a multiple of Mint_Price.
     */
    function mint() public payable isPublicSale isValidMintValue nonReentrant {
        uint256 amount = msg.value / MINT_PRICE;
        require(_leftToMint > 0, "Mint would exceed total supply");
        if ((_totalMinted(_leftToMint) + amount) <= TOTAL_NUM_PACKS) {
            _packMint(msg.sender, amount);
        } else {
            uint256 availableTokens = _leftToMint;
            _packMint(msg.sender, availableTokens);
            uint256 refund = (amount - availableTokens) * MINT_PRICE;
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "Refund didn't go through");
        }
    }

    /**
     * @dev Mint while the VIP Sale is open
     * @param proof_ an array of bytes32 proofs for the merkle tree validaton
     */
    function preMint(uint256 amount_, bytes32[] calldata proof_)
        public
        payable
        isVIPSale
        isListMintValueAvailable(amount_)
    {
        require(proof_.length > 0, "Invalid proof");
        _listMint(amount_, proof_);
    }

    /**
     * @dev Mint while the VIP Sale is open
     */
    function preMint(uint256 amount_, uint256 vipTokenId)
        public
        payable
        isVIPSale
        isListMintValueAvailable(amount_)
    {
        _vipMint(amount_, vipTokenId);
    }

    // Airdrops tokens to pre-defined users
    function airdrop(address user, uint256 amount) public onlyOwner isNotPublicSale {
        require(_leftToAirdrop >= amount, "Not enough tokens left to airdrop");
        _leftToAirdrop -= amount;
        _packMint(user, amount);
    }

    /**
     * @dev opens a pack, given the Id provided
     */
    function openPack(uint256 _packId) public payable isPublicSale {
        _burnToken(_packId);
        _cardsContract.mintCards(msg.sender, _packId);
    }

    /**
     * @dev Set the merkle root hash for the `allowListMint`
     * @param rootHash_ merkle root hash
     */
    function setAllowListRoot(bytes32 rootHash_) public onlyOwner {
        _allowedListRoot = rootHash_;
    }

    function setVIPSale() public onlyOwner {
        SaleState previousState = _saleState;
        _saleState = SaleState.VIP_SALE;
        emit SaleStateChanged(previousState, _saleState);
    }

    function setPublicSale() public onlyOwner {
        SaleState previousState = _saleState;
        _saleState = SaleState.PUBLIC_SALE;
        emit SaleStateChanged(previousState, _saleState);
    }

    function setNoSale() public onlyOwner {
        SaleState previousState = _saleState;
        _saleState = SaleState.NO_SALE;
        emit SaleStateChanged(previousState, _saleState);
    }

    function setVIPContractAddress(address vipContract) public onlyOwner {
        _lcccContract = vipContract;
    }

    /**
     * @dev Set the base uri for the token metadata
     * @notice end the uri with "/"
     * @param _uri the uri to the metadata
     */
    function setBaseTokenURI(string memory _uri) public onlyOwner {
        baseTokenURI = _uri;
    }

    /**
     * @dev View if an address is allow to `allowListMint` with given `_proof`
     * @param addr_ address to use as leaf in merkle trie
     * @param proof_ bytes32 array of merkle hashes
     */
    function validListMinter(address addr_, bytes32[] calldata proof_) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr_));
        return MerkleProof.verify(proof_, _allowedListRoot, leaf);
    }

    /**
     * @dev return metadata for a token id
     * @notice end the uri with "/"
     * @param _tokenId token id for the metadata to be returned
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        return string(abi.encodePacked(baseTokenURI, _tokenId.toString()));
    }

    /**
     * @notice Get the Cards contract address
     */
    function getCardsContractAddress() public view returns (address) {
        return address(_cardsContract);
    }

    /**
     * @notice Get the Payments contract address
     */
    function getPaymentsContractAddress() public view returns (address) {
        return address(_paymentsContract);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Get the total number of packs that the project will have
     */
    function getAvailableSupply() public view returns (uint256) {
        return _leftToMint;
    }

    /**
     * @notice Get current Sale State
     */
    function getSaleState() public view returns (string memory) {
        if (_saleState == SaleState.NO_SALE) {
            return "NO_SALE";
        } else if (_saleState == SaleState.VIP_SALE) {
            return "VIP_SALE";
        } else {
            return "PUBLIC_SALE";
        }
    }

    /**
     * @notice Get the total number of packs that the project will have
     */
    function getInitialSupply() public pure returns (uint256) {
        return TOTAL_NUM_PACKS;
    }

    /**
     * @notice Get the pack mint price
     */
    function getMintPrice() public pure returns (uint256) {
        return MINT_PRICE;
    }

    /**
     * @dev Enable users to burn Packs in order to mint Cards
     * @param tokenId_ packId to burn
     */
    function _burnToken(uint256 tokenId_) internal {
        require(msg.sender == ownerOf(tokenId_), "Not the owner of this id");
        ERC721._burn(tokenId_);
    }

    // Mints tokens for a user in the VIP list
    function _vipMint(uint256 amount_, uint256 vipTokenId) internal isVIPMinter(vipTokenId) {
        _vipMinted[vipTokenId]++;
        listMinted[msg.sender]++;
        _packMint(msg.sender, amount_);
    }

    // Mints a single token for a user in the Whitelist
    function _listMint(uint256 amount_, bytes32[] calldata _proof) internal isListMinter(_proof) {
        listMinted[msg.sender]++;
        _packMint(msg.sender, amount_);
    }

    /**
     * @dev Internal mint function to be called by `mint` || `_listMint` || `_vipMint` || `airdrop` depending on sale state
     * @param amount_ amount of tokens to mint
     */
    function _packMint(address to_, uint256 amount_) internal {
        uint256 leftToMint = _leftToMint;
        for (uint256 i = 0; i < amount_; i++) {
            _packsId.increment();
            leftToMint--;
            ERC721._safeMint(to_, _packsId.current());
        }
        _leftToMint = leftToMint;
    }

    /**
     * @dev Get the total number of minted tokens (even tokens that have been burned)
     * @param leftToMint_ How many are left to mint
     */
    function _totalMinted(uint256 leftToMint_) internal pure returns (uint256) {
        return TOTAL_NUM_PACKS - leftToMint_;
    }
}