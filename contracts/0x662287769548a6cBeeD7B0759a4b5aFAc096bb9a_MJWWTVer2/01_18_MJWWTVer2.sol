// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// @author Yumenosuke Kokata (Founder / CTO of NEXUM)
// @title MJWWT NFT

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract MJWWTVer2 is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable,
    IERC2981Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using MerkleProofUpgradeable for bytes32[];
    using StringsUpgradeable for uint256;

    function initialize() public initializer {
        __ERC721_init("MJWWT NFT", "MJWWT");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __Ownable_init();

        // set collect values from deploy script!
        baseURI = "/";
        mintLimit = 0;
        isPublicMintPaused = true;
        isAllowlistMintPaused = true;
        publicPrice = 1 ether;
        allowListPrice = 0.01 ether;
        allowlistedMemberMintLimit = 1;
        isRevealed = false;
        _keccakPrefix = "";
        _royaltyFraction = 1000; // 10%
        _royaltyReceiver = msg.sender;
        _withdrawalReceiver = msg.sender;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ///////////////////////////////////////////////////////////////////
    //// ERC2981
    ///////////////////////////////////////////////////////////////////

    uint96 private _royaltyFraction;

    /**
     * @dev set royalty in percentage x 100. e.g. 5% should be 500.
     */
    function setRoyaltyFraction(uint96 royaltyFraction) external onlyOwner {
        _royaltyFraction = royaltyFraction;
    }

    address private _royaltyReceiver;

    function setRoyaltyReceiver(address receiver) external onlyOwner {
        _royaltyReceiver = receiver;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        checkTokenIdExists(tokenId)
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyReceiver;
        royaltyAmount = (salePrice * _royaltyFraction) / 10_000;
    }

    ///////////////////////////////////////////////////////////////////
    //// URI
    ///////////////////////////////////////////////////////////////////

    //////////////////////////////////
    //// Base URI
    //////////////////////////////////

    string public baseURI;

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    //////////////////////////////////
    //// Token URI
    //////////////////////////////////

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        checkTokenIdExists(tokenId)
        returns (string memory)
    {
        return isRevealed ? _tokenURIAfterReveal(tokenId) : _tokenURIBeforeReveal();
    }

    //////////////////////////////////
    //// Reveal
    //////////////////////////////////

    bool public isRevealed;

    event Revealed(bool state);

    function setIsRevealed(bool state) external onlyOwner {
        isRevealed = state;
        emit Revealed(state);
    }

    string private _keccakPrefix;

    function setKeccakPrefix(string memory prefix) external onlyOwner {
        _keccakPrefix = prefix;
    }

    function _tokenURIAfterReveal(uint256 tokenId) private view returns (string memory) {
        bytes32 keccak = keccak256(abi.encodePacked(_keccakPrefix, tokenId.toString()));
        return _toLower(string(abi.encodePacked(_baseURI(), _toHex(keccak), ".json")));
    }

    function _tokenURIBeforeReveal() private view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "seed.json"));
    }

    //////////////////////////////////
    //// Contract URI
    //////////////////////////////////

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "index.json"));
    }

    ///////////////////////////////////////////////////////////////////
    //// Minting Tokens
    ///////////////////////////////////////////////////////////////////

    CountersUpgradeable.Counter private _tokenIdCounter;

    function _safeMintTokens(address to, uint256 quantity) private checkMintLimit(quantity) {
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            _safeMint(to, _tokenIdCounter.current()); // tokenId starts from 1
        }
    }

    //////////////////////////////////
    //// Allowlist Mint
    //////////////////////////////////

    mapping(address => uint256) public allowListMemberMintCount;

    function allowlistMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        whenAllowlistMintNotPaused
        checkAllowlist(merkleProof)
        checkAllowlistMintLimit(quantity)
        checkPay(allowListPrice, quantity)
    {
        _incrementNumberAllowlistMinted(msg.sender, quantity);
        _safeMintTokens(msg.sender, quantity);
    }

    function _incrementNumberAllowlistMinted(address owner, uint256 quantity) private {
        allowListMemberMintCount[owner] += quantity;
        _allowListMemberMintAddresses.push(owner);
    }

    function resetNumberAllowlistMinted() external onlyOwner {
        for (uint256 i = 0; i < _allowListMemberMintAddresses.length; i++)
            delete allowListMemberMintCount[_allowListMemberMintAddresses[i]];
        delete _allowListMemberMintAddresses;
    }

    //////////////////////////////////
    //// Public Mint
    //////////////////////////////////

    function publicMint(uint256 quantity) external payable whenPublicMintNotPaused checkPay(publicPrice, quantity) {
        _safeMintTokens(msg.sender, quantity);
    }

    //////////////////////////////////
    //// Admin Mint
    //////////////////////////////////

    function adminMint(uint256 quantity) external onlyOwner {
        _safeMintTokens(msg.sender, quantity);
    }

    function adminMintTo(address to, uint256 quantity) external onlyOwner {
        _safeMintTokens(to, quantity);
    }

    ///////////////////////////////////////////////////////////////////
    //// Minting Limit
    ///////////////////////////////////////////////////////////////////

    uint256 public mintLimit;

    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    modifier checkMintLimit(uint256 quantity) {
        require(_tokenIdCounter.current() + quantity <= mintLimit, "minting exceeds the limit");
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //// Pricing
    ///////////////////////////////////////////////////////////////////

    uint256 public allowListPrice;

    function setAllowListPrice(uint256 allowListPrice_) external onlyOwner {
        allowListPrice = allowListPrice_;
    }

    uint256 public publicPrice;

    function setPublicPrice(uint256 publicPrice_) external onlyOwner {
        publicPrice = publicPrice_;
    }

    modifier checkPay(uint256 price, uint256 quantity) {
        require(msg.value >= price * quantity, "not enough eth");
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //// Allowlist
    ///////////////////////////////////////////////////////////////////

    bytes32 private _merkleRoot;

    function setAllowlist(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    uint256 public allowlistedMemberMintLimit;

    function setAllowlistedMemberMintLimit(uint256 quantity) external onlyOwner {
        allowlistedMemberMintLimit = quantity;
    }

    function isAllowlisted(bytes32[] calldata merkleProof) public view returns (bool) {
        return merkleProof.verify(_merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    modifier checkAllowlist(bytes32[] calldata merkleProof) {
        require(isAllowlisted(merkleProof), "invalid merkle proof");
        _;
    }

    modifier checkAllowlistMintLimit(uint256 quantity) {
        require(
            allowListMemberMintCount[msg.sender] + quantity <= allowlistedMemberMintLimit,
            "allowlist minting exceeds the limit"
        );
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //// Pausing
    ///////////////////////////////////////////////////////////////////

    event PublicMintPaused();
    event PublicMintUnpaused();
    event AllowlistMintPaused();
    event AllowlistMintUnpaused();

    //////////////////////////////////
    //// Public Mint
    //////////////////////////////////

    bool public isPublicMintPaused;

    function pausePublicMint() external onlyOwner whenPublicMintNotPaused {
        isPublicMintPaused = true;
        emit PublicMintPaused();
    }

    function unpausePublicMint() external onlyOwner whenPublicMintPaused {
        isPublicMintPaused = false;
        emit PublicMintUnpaused();
    }

    modifier whenPublicMintNotPaused() {
        require(!isPublicMintPaused, "public mint: paused");
        _;
    }

    modifier whenPublicMintPaused() {
        require(isPublicMintPaused, "public mint: not paused");
        _;
    }

    //////////////////////////////////
    //// Allowlist Mint
    //////////////////////////////////

    bool public isAllowlistMintPaused;

    function pauseAllowlistMint() external onlyOwner whenAllowlistMintNotPaused {
        isAllowlistMintPaused = true;
        emit AllowlistMintPaused();
    }

    function unpauseAllowlistMint() external onlyOwner whenAllowlistMintPaused {
        isAllowlistMintPaused = false;
        emit AllowlistMintUnpaused();
    }

    modifier whenAllowlistMintNotPaused() {
        require(!isAllowlistMintPaused, "allowlist mint: paused");
        _;
    }

    modifier whenAllowlistMintPaused() {
        require(isAllowlistMintPaused, "allowlist mint: not paused");
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //// Withdraw
    ///////////////////////////////////////////////////////////////////

    address private _withdrawalReceiver;

    function setWithdrawalReceiver(address receiver) external onlyOwner {
        _withdrawalReceiver = receiver;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(_withdrawalReceiver).transfer(amount);
    }

    ///////////////////////////////////////////////////////////////////
    //// Admin Force Transfer
    ///////////////////////////////////////////////////////////////////

    function adminForceTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        _safeTransfer(from, to, tokenId, "");
    }

    ///////////////////////////////////////////////////////////////////
    //// Utilities
    ///////////////////////////////////////////////////////////////////

    modifier checkTokenIdExists(uint256 tokenId) {
        require(_exists(tokenId), "tokenId not exist");
        _;
    }

    function _toHex(bytes32 data) private pure returns (string memory) {
        return string(abi.encodePacked(_toHex16(bytes16(data)), _toHex16(bytes16(data << 128))));
    }

    function _toHex16(bytes16 data) private pure returns (bytes32 result) {
        result =
            (bytes32(data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
            ((bytes32(data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64);
        result =
            (result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
            ((result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32);
        result =
            (result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
            ((result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16);
        result =
            (result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
            ((result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8);
        result =
            ((result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4) |
            ((result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8);
        result = bytes32(
            0x3030303030303030303030303030303030303030303030303030303030303030 +
                uint256(result) +
                (((uint256(result) + 0x0606060606060606060606060606060606060606060606060606060606060606) >> 4) &
                    0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
                7
        );
    }

    function _toLower(string memory str) private pure returns (string memory) {
        bytes memory b = bytes(str);
        bytes memory l = new bytes(b.length);
        for (uint256 i = 0; i < b.length; i++)
            l[i] = (uint8(b[i]) >= 65) && (uint8(b[i]) <= 90) ? bytes1(uint8(b[i]) + 32) : b[i];
        return string(l);
    }

    ///////////////////////////////////////////////////////////////////
    //// Upgradeable (Added variables in upgrading)
    ///////////////////////////////////////////////////////////////////

    address[] private _allowListMemberMintAddresses;
}