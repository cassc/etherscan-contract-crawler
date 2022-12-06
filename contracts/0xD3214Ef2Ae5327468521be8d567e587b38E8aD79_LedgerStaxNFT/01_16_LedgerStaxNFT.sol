// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../Helpers.sol";
import "../artPass/IArtOfStaxMintPass.sol";
import "./ReentrancyGuard.sol";
import "./Signable.sol";
import "./Errors.sol";

contract LedgerStaxNFT is ERC721, ReentrancyGuard, Signable, AccessControl {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    enum Phase {
        NONE,
        PRE_SALE,
        MAIN_SALE
    }

    Phase private _phase;

    uint256 public orginalMaxSupply;
    uint256 public maxSupply;

    uint256 public mintPrice = 0.3 ether;

    uint256 public mintsPerAccountOnPublicSale = 5;

    address private _withdrawalAddress;

    uint256 private _nextTokenCount = 1;

    string private _baseTokenURI;
    string private _baseContractURI;

    IArtOfStaxMintPass private _artOfStaxMintPass;

    mapping(address => uint256) public minted;

    modifier phaseRequired(Phase phase_) {
        if (phase_ != _phase) revert Errors.MintNotAvailable();
        _;
    }

    modifier costs(uint256 amount) {
        if (msg.value < mintPrice * amount) revert Errors.InsufficientFunds();
        _;
    }

    constructor(
        uint256 _maxSupply,
        string memory baseTokenURI_,
        string memory baseContractURI_,
        string memory _name,
        string memory _symbol,
        address withdrawalAddress_
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        maxSupply = _maxSupply;
        orginalMaxSupply = _maxSupply;
        _baseTokenURI = baseTokenURI_;
        _baseContractURI = baseContractURI_;

        _withdrawalAddress = withdrawalAddress_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function ownerMint(address to, uint256 amount) external onlyOwner lock {
        if (_nextTokenCount + amount - 1 > maxSupply)
            revert Errors.SupplyLimitReached();

        for (uint256 i; i < amount; ) {
            _safeMint(to, _nextTokenCount);

            unchecked {
                ++_nextTokenCount;
                ++i;
            }
        }

        _mintArtOfStaxLogic(to, amount);
    }

    function preSaleMint(
        uint256 amount,
        uint256 maxAmount,
        bytes calldata signature
    ) external payable costs(amount) phaseRequired(Phase.PRE_SALE) lock {
        if (!_verify(signer(), _hash(msg.sender, maxAmount), signature))
            revert Errors.InvalidSignature();

        if (minted[msg.sender] + amount > maxAmount)
            revert Errors.AccountAlreadyMintedMax();

        _mintLogic(amount);
        _mintArtOfStaxLogic(msg.sender, amount);
    }

    function mint(uint256 amount)
        external
        payable
        costs(amount)
        phaseRequired(Phase.MAIN_SALE)
        lock
    {
        if (minted[msg.sender] + amount > mintsPerAccountOnPublicSale)
            revert Errors.AccountAlreadyMintedMax();

        _mintLogic(amount);
        _mintArtOfStaxLogic(msg.sender, amount);
    }

    function burn(uint256 id, address tokenOwner)
        external
        onlyRole(BURNER_ROLE)
    {
        _burnLogic(id, tokenOwner);
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert Errors.NothingToWithdraw();
        (_withdrawalAddress.call{value: balance}(""));
    }

    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    function reduceMaxSupply(uint256 newMaxSupply) external onlyOwner {
        if (newMaxSupply < _nextTokenCount - 1)
            revert Errors.MaxSupplyTooSmall();

        if (newMaxSupply > orginalMaxSupply)
            revert Errors.CanNotIncreaseMaxSupply();

        maxSupply = newMaxSupply;
    }

    function setMintsPerAccountOnPublicSale(
        uint256 mintsPerAccountOnPublicSale_
    ) external onlyOwner {
        mintsPerAccountOnPublicSale = mintsPerAccountOnPublicSale_;
    }

    function setContractURI(string calldata baseContractURI_)
        external
        onlyOwner
    {
        _baseContractURI = baseContractURI_;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setPhase(Phase phase_) external onlyOwner {
        _phase = phase_;
    }

    function setArtOfStaxMintPass(address artOfStaxMintPass_)
        external
        onlyOwner
    {
        _artOfStaxMintPass = IArtOfStaxMintPass(artOfStaxMintPass_);
    }

    function totalSupply() external view returns (uint256) {
        return _nextTokenCount - 1;
    }

    function contractURI() external view returns (string memory) {
        return _baseContractURI;
    }

    function phase() external view returns (Phase) {
        return _phase;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (ownerOf(tokenId) == address(0)) revert Errors.TokenDoesNotExist();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, Helpers.uint2string(tokenId))
                )
                : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function _mintLogic(uint256 amount) private {
        if (_nextTokenCount + amount - 1 > maxSupply)
            revert Errors.SupplyLimitReached();

        for (uint256 i; i < amount; ) {
            _safeMint(msg.sender, _nextTokenCount);

            unchecked {
                ++_nextTokenCount;
                ++i;
            }
        }

        minted[msg.sender] += amount;
    }

    function _verify(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) private pure returns (bool) {
        return signer == ECDSA.recover(hash, signature);
    }

    function _hash(address account, uint256 amount)
        private
        pure
        returns (bytes32)
    {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(account, amount))
            );
    }

    function _burnLogic(uint256 id, address tokenOwner) private {
        address owner_ = ownerOf(id);

        if (tokenOwner != owner_) revert Errors.InvalidOwner();

        _burn(id);
    }

    function _mintArtOfStaxLogic(address to, uint256 amount) private {
        if (address(_artOfStaxMintPass) == address(0))
            revert Errors.ArtOfStaxMintPassNotSet();

        _artOfStaxMintPass.mint(to, amount);
    }

    // Contract by Alexander Zimin for Ledger
}