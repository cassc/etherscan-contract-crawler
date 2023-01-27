pragma solidity ^0.8.4;

import "./Utils/Ownable.sol";
import "./Utils/ECDSA.sol";
import "./ERC/ERC721A.sol";
import "./ERC/ERC2981.sol";

error PublicMintNotActive();
error WhitelistMintNotActive();
error SoldOut();
error LimitPerWalletExceeded();
error LimitPerTxnExceeded();
error InvalidSignature();
error IncorrectPrice();
error InvalidBatchMint();

error StakingNotOpen();
error AlreadyStaked();
error NotStaked();
error CannotTransferStakedToken();

error ZeroAddress();
error NotUser();
error NotAnTokenOwner();
error FailedToWithdrawEther();

contract Token is Ownable, ERC2981, ERC721A {
    bool public canStake;
    bool public publicMintActive;
    bool public whitelistMintActive;
    string public _baseTokenURI;

    /* MINT DETAILS */

    uint256 public constant maxSupply = 1984;
    uint256 public constant RESERVED_ALLOWLIST = 838;
    uint256 public constant RESERVED_TEAM = 200;

    uint256 public publicMintPrice = 0.003 ether;

    uint96 public mintLimitPerTx = 2;
    uint96 public mintLimitPerWallet = 2;

    /* SIGNATURE */
    using ECDSA for bytes32;
    address public signerAddress;

    mapping(uint256 => uint256) public tokensLastStakedAt; // tokenId => timestamp

    /* EVENT */
    event Stake(uint256 indexed tokenId, address indexed by, uint256 stakedAt);
    event Unstake(
        uint256 indexed tokenId,
        address indexed by,
        uint256 stakedAt,
        uint256 unstakedAt
    );
    event Minted(address indexed receiver, uint256 quantity);
    event PublicMintStateChange(bool active);
    event WhitelistMintStateChange(bool active);

    modifier isPublicMintActive() {
        if (msg.sender != tx.origin) revert NotUser();
        if (!publicMintActive) revert PublicMintNotActive();
        _;
    }

    modifier isWhitelistActive() {
        if (msg.sender != tx.origin) revert NotUser();
        if (!whitelistMintActive) revert WhitelistMintNotActive();
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
        string memory _baseUri,
        address _royaltyReceiver,
        uint96 _royaltyFraction
    )
        ERC721A(_name, _symbol)
        ERC2981(_royaltyReceiver, _royaltyFraction)
        Ownable(_owner)
    {
        setSignerAddress(_signer);
        _baseTokenURI = _baseUri;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
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

    function stake(uint256 tokenId) external onlyTokenOwner(tokenId) {
        if (canStake != true) revert StakingNotOpen();

        if (tokensLastStakedAt[tokenId] != 0) revert AlreadyStaked();

        tokensLastStakedAt[tokenId] = block.timestamp;
        emit Stake(tokenId, msg.sender, tokensLastStakedAt[tokenId]);
    }

    function unstake(uint256 tokenId) external onlyTokenOwner(tokenId) {
        if (tokensLastStakedAt[tokenId] == 0) revert NotStaked();

        uint256 tokenLastStakedAt = tokensLastStakedAt[tokenId];

        tokensLastStakedAt[tokenId] = 0;
        emit Unstake(tokenId, msg.sender, tokenLastStakedAt, block.timestamp);
    }

    function ownerUnstake(uint256 tokenId) external onlyOwner {
        if (tokensLastStakedAt[tokenId] == 0) revert NotStaked();

        uint256 tokenLastStakedAt = tokensLastStakedAt[tokenId];

        tokensLastStakedAt[tokenId] = 0;

        emit Unstake(tokenId, msg.sender, tokenLastStakedAt, block.timestamp);
    }

    function setCanStake(bool _canStake) external onlyOwner {
        canStake = _canStake;
    }

    /* MINT SETTINGS */

    function setWhitelistMintActive(bool active) external onlyOwner {
        whitelistMintActive = active;
        emit WhitelistMintStateChange(active);
    }

    function setPublicMintActive(bool active) external onlyOwner {
        publicMintActive = active;
        emit PublicMintStateChange(active);
    }

    function setPublicMintPrice(uint256 price) external onlyOwner {
        publicMintPrice = price;
    }

    function setMintLimitPerWallet(uint96 limit) external onlyOwner {
        mintLimitPerWallet = limit;
    }

    function setMintLimitPerTx(uint96 limit) external onlyOwner {
        mintLimitPerTx = limit;
    }

    function setSignerAddress(address _signerAddress) public onlyOwner {
        if (_signerAddress == address(0)) revert ZeroAddress();
        signerAddress = _signerAddress;
    }

    /* MINT */

    function publicMint(uint256 quantity) external payable isPublicMintActive {
        if (
            maxSupply - _totalMinted() - RESERVED_TEAM <
            quantity
        ) revert SoldOut();

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
    ) external payable isWhitelistActive {
        if (
            maxSupply - _totalMinted() - RESERVED_ALLOWLIST - RESERVED_TEAM <
            quantity
        ) revert SoldOut();

        if (!verifySignature(signature_, quantity, 0))
            revert InvalidSignature();

        if (_numberMinted(msg.sender) + quantity > mintLimitPerWallet)
            revert LimitPerWalletExceeded();

        if (quantity > mintLimitPerTx) revert LimitPerTxnExceeded();

        _mint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    function allowlistMint(
        uint256 quantity,
        bytes calldata signature_
    ) external payable {
        if (
            maxSupply - _totalMinted() - RESERVED_TEAM <
            quantity
        ) revert SoldOut();

        if (!verifySignature(signature_, quantity, 1))
            revert InvalidSignature();

        if (_numberMinted(msg.sender) + quantity > mintLimitPerWallet)
            revert LimitPerWalletExceeded();

        if (quantity > mintLimitPerTx) revert LimitPerTxnExceeded();

        _mint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
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

    function verifySignature(
        bytes memory signature,
        uint256 mintQuantity,
        uint256 mintType
    ) internal view returns (bool) {
        return
            signerAddress ==
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    mintQuantity,
                    _numberMinted(msg.sender),
                    mintType,
                    address(this)
                )
            ).toEthSignedMessageHash().recover(signature);
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
    ) public payable override(ERC721A) {
        if (tokensLastStakedAt[tokenId] != 0)
            revert CannotTransferStakedToken();

        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable override(ERC721A) {
        if (tokensLastStakedAt[tokenId] != 0)
            revert CannotTransferStakedToken();
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}