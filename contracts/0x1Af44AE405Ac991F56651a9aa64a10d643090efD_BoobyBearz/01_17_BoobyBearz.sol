pragma solidity ^0.8.4;

import "./Utils/Stakable.sol";
import "./Utils/Signature.sol";
import "./ERC/ERC173.sol";
import "./ERC/ERC721A.sol";
import "./ERC/ERC2981.sol";
import "./Opeartor-Filter/DefaultOperatorFilterer.sol";

contract BoobyBearz is
    ERC173,
    DefaultOperatorFilterer,
    ERC2981,
    ERC721A,
    Signature,
    Stakable
{
    error GiftAlreadyReceived();
    error PublicMintNotActive();
    error PrivateListMintsNotActive();
    error SoldOut();

    error LimitPerWalletExceeded();
    error LimitPerTxnExceeded();
    error InvalidSignature();
    error IncorrectPrice();
    error InvalidBatchMint();

    error CannotTransferStakedToken();

    error NotUser();
    error NotAnTokenOwner();
    error FailedToWithdrawEther();

    bool public publicMintActive;
    bool public privateListMintsActive;

    string public _baseTokenURI;

    /* MINT DETAILS */

    uint256 public constant maxSupply = 5999;
    uint256 public constant RESERVED_TEAM = 300;

    uint256 public allowlistMintPrice = 0.005 ether;
    uint256 public whitelistMintPrice = 0.0069 ether;
    uint256 public publicMintPrice = 0.009 ether;

    uint96 public mintLimitPerTx = 3;
    uint96 public mintLimitPerWallet = 3;

    /* EVENT */
    event Minted(address indexed receiver, uint256 quantity);
    event PublicMintStateChange(bool active);
    event PrivateListMintStateChange(bool active);

    modifier OnlyWhilePublicMint() {
        if (msg.sender != tx.origin) revert NotUser();
        if (!publicMintActive) revert PublicMintNotActive();
        _;
    }

    modifier OnlyWhilePrivateMints() {
        if (msg.sender != tx.origin) revert NotUser();
        if (!privateListMintsActive) revert PrivateListMintsNotActive();
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        if (msg.sender != ownerOf(tokenId)) revert NotAnTokenOwner();
        _;
    }

    constructor(
        address _owner,
        address _signer,
        string memory _name,
        string memory _symbol,
        string memory _tokenUri,
        address _royaltyReceiver,
        uint96 _royaltyFraction
    )
        ERC721A(_name, _symbol)
        ERC2981(_royaltyReceiver, _royaltyFraction)
        ERC173(_owner)
        Signature(_signer)
    {
        _baseTokenURI = _tokenUri;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, ERC2981, ERC173) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            ERC173.supportsInterface(interfaceId);
    }

    /* ROYALTY */

    function setRoyaltyInfo(
        address receiver,
        uint96 feeBasisPoints
    ) external onlyOwner {
        _setRoyaltyInfo(receiver, feeBasisPoints);
    }

    /* URI */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /* STAKE */

    function stake(
        uint256 tokenId
    ) public override(Stakable) onlyTokenOwner(tokenId) {
        super.stake(tokenId);
    }

    function unstake(
        uint256 tokenId
    ) public override(Stakable) onlyTokenOwner(tokenId) {
        super.unstake(tokenId);
    }

    function ownerUnstake(uint256 tokenId) external onlyOwner {
        super.unstake(tokenId);
    }

    function setCanStake(bool _canStake) external onlyOwner {
        canStake = _canStake;
    }

    /* MINT SETTINGS */

    function setPrivateListMintsState(bool active) external onlyOwner {
        privateListMintsActive = active;
        emit PrivateListMintStateChange(active);
    }

    function setPublicMintState(bool active) external onlyOwner {
        publicMintActive = active;
        emit PublicMintStateChange(active);
    }

    function setMintPrices(
        uint256 _publicMintPrice,
        uint256 _whitelistMintPrice,
        uint256 _allowlistMintPrice
    ) external onlyOwner {
        publicMintPrice = _publicMintPrice;
        whitelistMintPrice = _whitelistMintPrice;
        allowlistMintPrice = _allowlistMintPrice;
    }

    function setMintLimitPerWallet(uint96 limit) external onlyOwner {
        mintLimitPerWallet = limit;
    }

    function setMintLimitPerTx(uint96 limit) external onlyOwner {
        mintLimitPerTx = limit;
    }

    function setSignerAddress(
        address _signerAddress
    ) public override onlyOwner {
        super.setSignerAddress(_signerAddress);
    }

    /* MINT */

    function publicMint(uint256 quantity) external payable OnlyWhilePublicMint {
        if (maxSupply - _totalMinted() - RESERVED_TEAM < quantity)
            revert SoldOut();

        if (_numberMinted(msg.sender) + quantity > mintLimitPerWallet)
            revert LimitPerWalletExceeded();

        if (msg.value != quantity * publicMintPrice) revert IncorrectPrice();

        if (quantity > mintLimitPerTx) revert LimitPerTxnExceeded();

        _mint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    function whitelistMint(
        uint256 quantity,
        bytes calldata signature_
    ) external payable OnlyWhilePrivateMints {
        if (maxSupply - _totalMinted() - RESERVED_TEAM < quantity)
            revert SoldOut();

        if (_numberMinted(msg.sender) + quantity > mintLimitPerWallet)
            revert LimitPerWalletExceeded();

        if (!verifySignature(signature_, 0)) revert InvalidSignature();

        if (msg.value != quantity * whitelistMintPrice) revert IncorrectPrice();

        if (quantity > mintLimitPerTx) revert LimitPerTxnExceeded();

        _mint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    function allowlistMint(
        uint256 quantity,
        bytes calldata signature_
    ) external payable OnlyWhilePrivateMints {
        if (maxSupply - _totalMinted() - RESERVED_TEAM < quantity)
            revert SoldOut();

        if (_numberMinted(msg.sender) + quantity > mintLimitPerWallet)
            revert LimitPerWalletExceeded();

        if (!verifySignature(signature_, 1)) revert InvalidSignature();

        if (msg.value != quantity * allowlistMintPrice) revert IncorrectPrice();

        if (quantity > mintLimitPerTx) revert LimitPerTxnExceeded();

        _mint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    function allowlistMintWithGift(
        uint256 quantity,
        bytes calldata signature_
    ) external payable OnlyWhilePrivateMints {
        if (maxSupply - _totalMinted() - RESERVED_TEAM < quantity)
            revert SoldOut();

        if (_numberMinted(msg.sender) > 0) revert GiftAlreadyReceived();

        if (msg.value != (quantity - 1) * allowlistMintPrice)
            revert IncorrectPrice();

        if (_numberMinted(msg.sender) + quantity > mintLimitPerWallet)
            revert LimitPerWalletExceeded();

        if (!verifySignature(signature_, 1)) revert InvalidSignature();

        if (quantity > mintLimitPerTx) revert LimitPerTxnExceeded();

        _mint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    function receiveGift(
        bytes calldata signature_
    ) external payable OnlyWhilePrivateMints {
        if (maxSupply - _totalMinted() - RESERVED_TEAM < 1) revert SoldOut();

        if (_numberMinted(msg.sender) > 0) revert GiftAlreadyReceived();

        if (!verifySignature(signature_, 1)) revert InvalidSignature();

        if (_numberMinted(msg.sender) + 1 > mintLimitPerWallet)
            revert LimitPerWalletExceeded();

        _mint(msg.sender, 1);
        emit Minted(msg.sender, 1);
    }

    function batchMint(
        uint64[] calldata quantities,
        address[] calldata recipients
    ) external onlyOwner {
        uint256 numRecipients = recipients.length;
        if (numRecipients != quantities.length) revert InvalidBatchMint();

        for (uint256 i = 0; i < numRecipients; ) {
            if (_totalMinted() + quantities[i] > maxSupply) revert SoldOut();

            _safeMint(recipients[i], quantities[i]);

            emit Minted(recipients[i], quantities[i]);

            unchecked {
                i++;
            }
        }
    }

    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    function totalMinted() external view virtual returns (uint256) {
        return _totalMinted();
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        if (tokensLastStakedAt[tokenId] != 0)
            revert CannotTransferStakedToken();

        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        if (tokensLastStakedAt[tokenId] != 0)
            revert CannotTransferStakedToken();
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        if (tokensLastStakedAt[tokenId] != 0)
            revert CannotTransferStakedToken();
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function withdraw(address _address, uint256 _amount) external onlyOwner {
        (bool success, ) = _address.call{value: _amount}("");

        if (success != true) revert FailedToWithdrawEther();
    }
}