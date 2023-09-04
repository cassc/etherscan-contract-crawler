// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@chocolate-factory/contracts/admin-mint/AdminMintUpgradable.sol";
import "@chocolate-factory/contracts/supply/SupplyUpgradable.sol";
import "@chocolate-factory/contracts/uri-manager/UriManagerUpgradable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/IPrimordiaKey.sol";

contract PrimordiaLand is
    Initializable,
    OwnableUpgradeable,
    EIP712Upgradeable,
    ERC2981Upgradeable,
    PausableUpgradeable,
    AdminMintUpgradable,
    SupplyUpgradable,
    UriManagerUpgradable,
    ERC721AQueryableUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    address public signer;
    address public payee;
    bool public transfersEnabled;

    struct MintRequest {
        uint256 price;
        uint256 amount;
    }

    struct WhitelistMintRequest {
        uint256 price;
        uint256 amount;
        address account;
    }

    IERC721Upgradeable public constant MOONRUNNERS =
        IERC721Upgradeable(0x1485297e942ce64E0870EcE60179dFda34b4C625);

    IERC721Upgradeable public constant DRAGONHORDE =
        IERC721Upgradeable(0x6b5483b55b362697000d8774d8ea9c4429B261BB);

    IStaking public constant STAKING =
        IStaking(0x717C6dD66Be92E979001aee2eE169aAA8D6D4361);

    IPrimordiaKey public constant PRIMORDIA_KEY =
        IPrimordiaKey(0x0b4DccabF3C011B168574c70D395d6133A14Ddc2);

    uint256 constant PRIMORDIA_KEY_TOKEN_ID = 1;

    bytes32 private constant HOLDER_MINT_REQUEST_TYPE_HASH =
        keccak256("HolderMintRequest(uint256 price,uint256 amount)");

    bytes32 private constant WHITELIST_MINT_REQUEST_TYPE_HASH =
        keccak256(
            "WhitelistMintRequest(uint256 price,uint256 amount,address account)"
        );

    bytes32 private constant PUBLIC_MINT_REQUEST_TYPE_HASH =
        keccak256("PublicMintRequest(uint256 price,uint256 amount)");

    function initialize(
        uint256 maxSupply_,
        string calldata prefix_,
        string calldata suffix_,
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_,
        address signer_,
        address payee_
    ) external initializer initializerERC721A {
        __Ownable_init();
        __EIP712_init_unchained("", "");
        __ERC2981_init();
        __Pausable_init();
        __AdminManager_init_unchained();
        __AdminMint_init_unchained();
        __Supply_init_unchained(maxSupply_);
        __UriManager_init_unchained(prefix_, suffix_);
        __ERC721A_init("Primordia Land", "Primordia");
        __DefaultOperatorFilterer_init();
        _setDefaultRoyalty(royaltyReceiver_, royaltyFeeNumerator_);
        _pause();
        signer = signer_;
        payee = payee_;
    }

    function moonrunnersHolderMint(
        MintRequest calldata request_,
        bytes calldata signature_
    )
        external
        payable
        onlyEOA
        onlyAuthorizedHolderMint(request_, signature_)
        onlyInSupply(request_.amount + _primordiaKeyTotalSupply())
        whenNotPaused
    {
        require(_isMoonrunnersHolder(), "Only Moonrunners holders");
        _callPaidMint(msg.sender, request_.amount, request_.price);
    }

    function dragonhordeHolderMint(
        MintRequest calldata request_,
        bytes calldata signature_
    )
        external
        payable
        onlyEOA
        onlyAuthorizedHolderMint(request_, signature_)
        onlyInSupply(request_.amount + _primordiaKeyTotalSupply())
        whenNotPaused
    {
        require(_isDragonhordeHolder(), "Only dragonhorde holders");
        _callPaidMint(msg.sender, request_.amount, request_.price);
    }

    function withStakedTokensMint(
        MintRequest calldata request_,
        bytes calldata signature_
    )
        external
        payable
        onlyEOA
        onlyAuthorizedHolderMint(request_, signature_)
        onlyInSupply(request_.amount + _primordiaKeyTotalSupply())
        whenNotPaused
    {
        require(_haveStakedTokens(), "Only with staked tokens");
        _callPaidMint(msg.sender, request_.amount, request_.price);
    }

    function whitelistMint(
        WhitelistMintRequest calldata request_,
        bytes calldata signature_
    )
        external
        payable
        onlyEOA
        onlyAuthorizedWhitelistMint(request_, signature_)
        onlyInSupply(request_.amount + _primordiaKeyTotalSupply())
        whenNotPaused
    {
        require(request_.account == msg.sender, "Only whitelisted addresses");
        _callPaidMint(msg.sender, request_.amount, request_.price);
    }

    function publicMint(
        MintRequest calldata request_,
        bytes calldata signature_
    )
        external
        payable
        onlyEOA
        onlyAuthorizedPublicMint(request_, signature_)
        onlyInSupply(request_.amount + _primordiaKeyTotalSupply())
        whenNotPaused
    {
        _callPaidMint(msg.sender, request_.amount, request_.price);
    }

    function paperMint(
        address account_,
        uint256 amount_
    )
        external
        payable
        onlyInSupply(amount_ + _primordiaKeyTotalSupply())
        whenNotPaused
    {
        require(_isPaperMinter(), "Only callable from paper");
        _callMint(account_, amount_);
    }

    function claim(
        uint256 amount_
    ) external onlyEOA onlyInSupply(amount_) whenNotPaused {
        PRIMORDIA_KEY.burn(msg.sender, amount_);
        _callMint(msg.sender, amount_);
    }

    function setSigner(address signer_) external onlyAdmin {
        signer = signer_;
    }

    function setPayee(address payee_) external onlyAdmin {
        payee = payee_;
    }

    function setTransfersEnabled(bool transfersEnabled_) external onlyAdmin {
        transfersEnabled = transfersEnabled_;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function withdrawTest() external onlyAdmin {
        payable(payee).transfer(0.01 ether);
    }

    function withdraw() external onlyAdmin {
        payable(payee).transfer(address(this).balance);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return _buildUri(tokenId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyIfTransfersEnabled
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyIfTransfersEnabled
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyIfTransfersEnabled
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyIfTransfersEnabled
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyIfTransfersEnabled
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _primordiaKeyTotalSupply() internal returns (uint256) {
        return PRIMORDIA_KEY.totalSupply(PRIMORDIA_KEY_TOKEN_ID);
    }

    function _hashHolderMintRequest(
        MintRequest calldata request_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    HOLDER_MINT_REQUEST_TYPE_HASH,
                    request_.price,
                    request_.amount
                )
            );
    }

    function _hashWhitelistMintRequest(
        WhitelistMintRequest calldata request_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    WHITELIST_MINT_REQUEST_TYPE_HASH,
                    request_.price,
                    request_.amount,
                    request_.account
                )
            );
    }

    function _hashPublicMintRequest(
        MintRequest calldata request_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PUBLIC_MINT_REQUEST_TYPE_HASH,
                    request_.price,
                    request_.amount
                )
            );
    }

    function _isMoonrunnersHolder() internal view returns (bool) {
        return MOONRUNNERS.balanceOf(msg.sender) > 0;
    }

    function _isDragonhordeHolder() internal view returns (bool) {
        return DRAGONHORDE.balanceOf(msg.sender) > 0;
    }

    function _haveStakedTokens() internal view returns (bool) {
        return STAKING.getStake(msg.sender).tokenIds.length > 0;
    }

    function _isPaperMinter() internal view returns (bool) {
        return
            msg.sender == 0xd447B0221b29aBb7f61cD4D6Ce15909dc7E6239b ||
            msg.sender == 0x148fEbb2C6F06C96F006f191211c956748D97012 ||
            msg.sender == 0xD98eA98A4aCC0eAcF180c75600e365867D13b51c;
    }

    function _callMint(address account_, uint256 amount_) internal {
        _safeMint(account_, amount_);
    }

    function _handlePayment(uint256 price_) internal {
        require(msg.value >= price_, "Invalid payment");
        uint256 difference = msg.value - price_;
        if (difference > 0) {
            payable(msg.sender).transfer(difference);
        }
    }

    function _callPaidMint(
        address account_,
        uint256 amount_,
        uint256 price_
    ) internal {
        _callMint(account_, amount_);
        _handlePayment(price_);
    }

    function _adminMint(
        address account_,
        uint256 amount_
    ) internal override onlyInSupply(amount_) {
        _callMint(account_, amount_);
    }

    function _currentSupply() internal view override returns (uint256) {
        return totalSupply();
    }

    function _EIP712Name() internal pure override returns (string memory) {
        return "PRIMORDIA";
    }

    function _EIP712Version() internal pure override returns (string memory) {
        return "0.1.0";
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    modifier onlyAuthorizedHolderMint(
        MintRequest calldata request_,
        bytes calldata signature_
    ) {
        bytes32 structHash = _hashHolderMintRequest(request_);
        bytes32 digest = _hashTypedDataV4(structHash);
        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature_);
        require(recoveredSigner == signer, "Unauthorized holder mint request");
        _;
    }

    modifier onlyAuthorizedWhitelistMint(
        WhitelistMintRequest calldata request_,
        bytes calldata signature_
    ) {
        bytes32 structHash = _hashWhitelistMintRequest(request_);
        bytes32 digest = _hashTypedDataV4(structHash);
        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature_);
        require(
            recoveredSigner == signer,
            "Unauthorized whitelist mint request"
        );
        _;
    }

    modifier onlyAuthorizedPublicMint(
        MintRequest calldata request_,
        bytes calldata signature_
    ) {
        bytes32 structHash = _hashPublicMintRequest(request_);
        bytes32 digest = _hashTypedDataV4(structHash);
        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature_);
        require(recoveredSigner == signer, "Unauthorized public mint request");
        _;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Only EOA allowed");
        _;
    }

    modifier onlyIfTransfersEnabled() {
        require(transfersEnabled, "Transfers are not enabled");
        _;
    }
}