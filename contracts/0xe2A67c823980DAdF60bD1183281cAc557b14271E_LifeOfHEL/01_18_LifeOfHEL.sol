/**
SPDX-License-Identifier: MIT
*/
import "../IKomethAppImplementation.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

pragma solidity ^0.8.13;

/// @author [email protected] twitter.com/0xYuru
/// @custom:coauthor Radisa twitter.com/pr0ph0z
/// @dev aa0cdefd28cd450477ec80c28ecf3574 0x8fd31bb99658cb203b8c9034baf3f836c2bc2422fd30380fa30b8eade122618d3ca64095830cac2c0e84bc22910eef206eb43d54f71069f8d9e66cf8e4dcabec1c
contract LifeOfHEL is
    IKomethAppImplementation,
    ERC721A,
    DefaultOperatorFilterer,
    ERC2981,
    EIP712,
    ReentrancyGuard,
    Ownable
{
    using ECDSA for bytes32;

    bytes32 public constant PRIVATE_SALE_TYPEHASH =
        keccak256(
            "PrivateSale(uint256 price,uint256 txLimit,uint256 walletLimit,uint256 deadline,uint256 kind,address recipient)"
        );

    uint256 public maxSupply;
    string public baseURI;
    Stage public stage;
    address public signer;
    address private withdrawalWallet =
        0xE7C72cCD10bE04aD40104905CD8057766036aa45;
    PublicSale public publicSale;

    mapping(uint256 => mapping(address => uint256)) public PrivateSaleMinter;
    mapping(address => uint256) public PublicSaleMinter;
    mapping(uint256 => uint256) public privateSalePrices;
    mapping(address => bool) public authorizedAddresses;

    event PrivateSaleMint(address owner, uint256 kind);

    modifier notContract() {
        require(!_isContract(_msgSender()), "NOT_ALLOWED_CONTRACT");
        require(_msgSender() == tx.origin, "NOT_ALLOWED_PROXY");
        _;
    }

    modifier onlyAuthorizedAddress() {
        require(
            msg.sender == owner() || authorizedAddresses[msg.sender],
            "Caller is not the owner or the minter"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _previewURI,
        uint256 _maxSupply,
        address _signer,
        address _authorizedAddress,
        address _royaltyAddress,
        uint256 _privateSalePrice,
        PublicSale memory _publicSaleProperty
    ) ERC721A(_name, _symbol) EIP712("Kometh", "1.0.0") {
        stage = Stage.Pause;
        baseURI = _previewURI;
        maxSupply = _maxSupply;
        signer = _signer;
        authorizedAddresses[_authorizedAddress] = true;
        publicSale = _publicSaleProperty;
        privateSalePrices[0] = _privateSalePrice;
        _setDefaultRoyalty(_royaltyAddress, 500);
    }

    // Override the start token id because by defaut ERC71A set the
    // start token id to 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function mintTo(
        address[] calldata _to,
        uint256[] calldata _amount
    ) external onlyAuthorizedAddress {
        for (uint256 i = 0; i < _to.length; i++) {
            require(
                totalSupply() + _amount[i] <= maxSupply,
                "MAX_SUPPLY_EXCEEDED"
            );
            _mint(_to[i], _amount[i]);
        }
    }

    /**
     * @inheritdoc IKomethAppImplementation
     */
    function privateSaleMint(
        uint256 _quantity,
        uint256 _txLimit,
        uint256 _walletLimit,
        uint256 _deadline,
        uint256 _kind,
        bytes calldata _signature
    ) external payable notContract nonReentrant {
        require(stage == Stage.Private || stage == Stage.Mint, "STAGE_NMATCH");

        uint256 privateSalePrice = privateSalePrices[_kind];
        require(
            signer ==
                _verifyPrivateSale(
                    privateSalePrice,
                    _txLimit,
                    _walletLimit,
                    _deadline,
                    msg.sender,
                    _kind,
                    _signature
                ),
            "INVALID_SIGNATURE"
        );
        require(block.timestamp <= _deadline, "INVALID_DEADLINE_SIGNATURE");
        require(_quantity <= _txLimit, "TX_LIMIT_EXCEEDED");
        require(
            PrivateSaleMinter[_kind][msg.sender] + _quantity <= _walletLimit,
            "WALLET_LIMIT_EXCEEDED"
        );
        require(totalSupply() + _quantity <= maxSupply, "SUPPLY_EXCEEDED");
        require(
            msg.value >= (privateSalePrice * _quantity),
            "INSUFFICIENT_FUND"
        );

        PrivateSaleMinter[_kind][msg.sender] += _quantity;
        _mint(msg.sender, _quantity);

        emit PrivateSaleMint(msg.sender, _kind);
    }

    /**
     * @inheritdoc IKomethAppImplementation
     */
    function delegateMint(
        uint256 _quantity,
        uint256 _txLimit,
        uint256 _walletLimit,
        uint256 _deadline,
        address _recipient,
        uint256 _kind,
        bytes calldata _signature
    ) external payable notContract nonReentrant {
        require(stage == Stage.Private || stage == Stage.Mint, "STAGE_NMATCH");

        uint256 privateSalePrice = privateSalePrices[_kind];
        require(
            signer ==
                _verifyPrivateSale(
                    privateSalePrice,
                    _txLimit,
                    _walletLimit,
                    _deadline,
                    _recipient,
                    _kind,
                    _signature
                ),
            "INVALID_SIGNATURE"
        );
        require(block.timestamp <= _deadline, "INVALID_DEADLINE_SIGNATURE");
        require(_quantity <= _txLimit, "TX_LIMIT_EXCEEDED");
        require(
            PrivateSaleMinter[_kind][_recipient] + _quantity <= _walletLimit,
            "WALLET_LIMIT_EXCEEDED"
        );
        require(totalSupply() + _quantity <= maxSupply, "SUPPLY_EXCEEDED");
        require(
            msg.value >= (privateSalePrice * _quantity),
            "INSUFFICIENT_FUND"
        );

        PrivateSaleMinter[_kind][_recipient] += _quantity;
        _mint(_recipient, _quantity);

        emit PrivateSaleMint(_recipient, _kind);
    }

    /**
     * @inheritdoc IKomethAppImplementation
     */
    function publicSaleMint(
        uint256 _quantity
    ) external payable notContract nonReentrant {
        require(stage == Stage.Public || stage == Stage.Mint, "STAGE_NMATCH");
        require(_quantity <= publicSale.txLimit, "TX_LIMIT_EXCEEDED");
        require(
            PublicSaleMinter[msg.sender] + _quantity <= publicSale.walletLimit,
            "WALLET_LIMIT_EXCEEDED"
        );
        require(totalSupply() + _quantity <= maxSupply, "SUPPLY_EXCEEDED");
        require(
            msg.value >= (publicSale.price * _quantity),
            "INSUFFICIENT_FUND"
        );

        PublicSaleMinter[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function _verifyPrivateSale(
        uint256 _price,
        uint256 _txLimit,
        uint256 _walletLimit,
        uint256 _deadline,
        address _sender,
        uint256 _kind,
        bytes calldata _sign
    ) internal view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    PRIVATE_SALE_TYPEHASH,
                    _price,
                    _txLimit,
                    _walletLimit,
                    _deadline,
                    _kind,
                    _sender
                )
            )
        );
        return ECDSA.recover(digest, _sign);
    }

    function setPrivateSalePrice(
        uint256 _kind,
        uint256 _price
    ) external onlyOwner {
        privateSalePrices[_kind] = _price;
    }

    function updatePublicSale(
        PublicSale memory _publicSale
    ) external onlyOwner {
        publicSale = _publicSale;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // IERC165: 0x01ffc9a7, IERC721: 0x80ac58cd, IERC721Metadata: 0x5b5e139f, IERC29081: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IKomethAppImplementation
     */
    function setStage(Stage _stage) external onlyOwner {
        stage = _stage;
    }

    /**
     * @inheritdoc IKomethAppImplementation
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /**
     * @inheritdoc IKomethAppImplementation
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @inheritdoc IKomethAppImplementation
     */
    function setAuthorizedAddress(
        address _authorizedAddress,
        bool value
    ) external onlyOwner {
        authorizedAddresses[_authorizedAddress] = value;
    }

    /**
     * @inheritdoc IKomethAppImplementation
     */
    function burn(uint256 _tokenId) external onlyAuthorizedAddress {
        _burn(_tokenId);
    }

    /// @notice Set royalties for EIP 2981.
    /// @param _recipient the recipient of royalty
    /// @param _amount the amount of royalty (use bps)
    function setRoyalties(
        address _recipient,
        uint96 _amount
    ) external onlyOwner {
        _setDefaultRoyalty(_recipient, _amount);
    }

    function setWithdrawalWallet(address _withdrawalWallet) external onlyOwner {
        withdrawalWallet = _withdrawalWallet;
    }

    /**
     * @inheritdoc IKomethAppImplementation
     */
    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "BALANCE_ZERO");
        uint256 walletBalance = address(this).balance;

        sendValue(payable(withdrawalWallet), walletBalance);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function tokenURI(
        uint256 _id
    ) public view override returns (string memory) {
        require(_exists(_id), "Token does not exist");

        return string(abi.encodePacked(baseURI, _toString(_id)));
    }
}