/**
SPDX-License-Identifier: MIT
*/
import "./IGaspackAppImplementation.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

pragma solidity ^0.8.13;

contract GaspackNFT is
    IGaspackAppImplementation,
    ERC721A,
    ERC2981,
    EIP712,
    ReentrancyGuard,
    Ownable
{
    using ECDSA for bytes32;

    bytes32 public constant PRIVATE_SALE_TYPEHASH =
        keccak256(
            "PrivateSale(uint256 price,uint256 quantity,uint256 txLimit,uint256 walletLimit,uint256 deadline,uint256 kind,address recipient)"
        );
    uint256 public maxSupply;
    string public baseURI;
    Stage public stage;
    address public signer;
    address private constant WALLET =
        0x83739A8Ec78f74Ed2f1e6256fEa391DB01F1566F;
    PublicSale public publicSale;

    mapping(address => uint256) public PrivateSaleMinter;
    mapping(address => uint256) public PublicSaleMinter;
    mapping(address => uint256) public userNonce;
    mapping(uint256 => PrivateSale) public privateSales;
    mapping(address => bool) public authorizedAddresses;

    event PrivateSaleMint(
        address owner,
        PrivateSale privateSale,
        uint256 nonce,
        uint256 kind
    );

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
        PublicSale memory _publicSaleProperty,
        PrivateSale memory _privateSaleProperty
    ) ERC721A(_name, _symbol) EIP712("GaspackApp", "1.0.0") {
        stage = Stage.Pause;
        baseURI = _previewURI;
        maxSupply = _maxSupply;
        signer = _signer;
        authorizedAddresses[_authorizedAddress] = true;
        publicSale = _publicSaleProperty;
        privateSales[0] = _privateSaleProperty;
        _setDefaultRoyalty(_royaltyAddress, 1000);
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
     * @inheritdoc IGaspackAppImplementation
     */
    function privateSaleMint(
        PrivateSale memory _privateSale,
        uint256 _nonce,
        uint256 _kind,
        bytes calldata _signature
    ) external payable {
        require(stage == Stage.Private || stage == Stage.Mint, "STAGE_NMATCH");
        require(
            signer ==
                _verifyPrivateSale(_privateSale, msg.sender, _kind, _signature),
            "INVALID_SIGNATURE"
        );

        PrivateSale memory privateSale = privateSales[_kind];
        require(_nonce == userNonce[msg.sender], "INVALID_NONCE");
        require(
            block.timestamp <= _privateSale.deadline,
            "INVALID_DEADLINE_SIGNATURE"
        );
        require(
            _privateSale.quantity <= privateSale.txLimit,
            "TX_LIMIT_EXCEEDED"
        );
        require(
            PrivateSaleMinter[msg.sender] + _privateSale.quantity <=
                privateSale.walletLimit,
            "WALLET_LIMIT_EXCEEDED"
        );
        require(
            totalSupply() + _privateSale.quantity <= maxSupply,
            "SUPPLY_EXCEEDED"
        );
        require(
            msg.value >= (privateSale.price * _privateSale.quantity),
            "INSUFFICIENT_FUND"
        );

        userNonce[msg.sender]++;
        PrivateSaleMinter[msg.sender] += _privateSale.quantity;
        _mint(msg.sender, _privateSale.quantity);

        emit PrivateSaleMint(msg.sender, _privateSale, _nonce, _kind);
    }

    /**
     * @inheritdoc IGaspackAppImplementation
     */
    function publicSaleMint(uint256 _quantity) external payable {
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
        PrivateSale memory _privateSale,
        address _sender,
        uint256 _kind,
        bytes calldata _sign
    ) internal view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    PRIVATE_SALE_TYPEHASH,
                    _privateSale.price,
                    _privateSale.quantity,
                    _privateSale.txLimit,
                    _privateSale.walletLimit,
                    _privateSale.deadline,
                    _kind,
                    _sender
                )
            )
        );
        return ECDSA.recover(digest, _sign);
    }

    function setPrivateSale(
        uint256 _kind,
        PrivateSale memory _privateSale
    ) external onlyOwner {
        privateSales[_kind] = _privateSale;
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
     * @inheritdoc IGaspackAppImplementation
     */
    function setStage(Stage _stage) external onlyOwner {
        stage = _stage;
    }

    /**
     * @inheritdoc IGaspackAppImplementation
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /**
     * @inheritdoc IGaspackAppImplementation
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @inheritdoc IGaspackAppImplementation
     */
    function setAuthorizedAddress(
        address _authorizedAddress,
        bool value
    ) external onlyOwner {
        authorizedAddresses[_authorizedAddress] = value;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @inheritdoc IGaspackAppImplementation
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

    /**
     * @inheritdoc IGaspackAppImplementation
     */
    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "BALANCE_ZERO");
        uint256 balance = address(this).balance;

        sendValue(payable(WALLET), balance);
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