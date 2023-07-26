/**
SPDX-License-Identifier: MIT
*/
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
contract Supernormal is
    ERC721A,
    DefaultOperatorFilterer,
    ERC2981,
    EIP712,
    ReentrancyGuard,
    Ownable
{
    using ECDSA for bytes32;

    enum Stage {
        Pause,
        Private,
        Public
    }

    uint256 public constant PUBLIC_LIMIT = 3;
    uint256 public constant TX_LIMIT = 3;
    bytes32 public constant PRIVATE_SALE_TYPEHASH =
        keccak256("PrivateSale(address recipient,uint256 limit,uint256 kind)");

    uint256 public price = 0.016 ether;
    Stage public stage;
    uint256 public maxSupply = 5000;
    string public baseURI;
    address public signer;
    address private gaspackWallet = 0x83739A8Ec78f74Ed2f1e6256fEa391DB01F1566F;
    address private supernormalWallet =
        0xC13dAB2E39b8D017c44B7E0EB2f521ad56d272C0;
    address private authorizedWallet =
        0xDB607848298e071f482C6fB0ba48fA535B5dd127;

    mapping(uint256 => mapping(address => uint256)) public PrivateSaleMinter;
    mapping(address => uint256) public PublicSaleMinter;

    modifier notContract() {
        require(!_isContract(_msgSender()), "NOT_ALLOWED_CONTRACT");
        require(_msgSender() == tx.origin, "NOT_ALLOWED_PROXY");
        _;
    }

    constructor(
        string memory _previewURI,
        address _signer,
        address _royaltyAddress
    ) ERC721A("Supernormal", "SUPERNORMAL") EIP712("Supernormal", "1.0.0") {
        stage = Stage.Pause;
        baseURI = _previewURI;
        signer = _signer;
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
    ) external onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            require(
                totalSupply() + _amount[i] <= maxSupply,
                "MAX_SUPPLY_EXCEEDED"
            );
            _mint(_to[i], _amount[i]);
        }
    }

    function privateSaleMint(
        uint256 _quantity,
        uint256 _limit,
        uint256 _kind,
        bytes calldata _signature
    ) external payable notContract nonReentrant {
        require(stage == Stage.Private, "STAGE_NMATCH");
        require(
            signer == _verifyPrivateSale(msg.sender, _limit, _kind, _signature),
            "INVALID_SIGNATURE"
        );
        require(_quantity <= TX_LIMIT, "TX_LIMIT_EXCEEDED");
        require(
            PrivateSaleMinter[_kind][msg.sender] + _quantity <= _limit,
            "WALLET_LIMIT_EXCEEDED"
        );
        require(totalSupply() + _quantity <= maxSupply, "SUPPLY_EXCEEDED");
        require(msg.value >= (price * _quantity), "INSUFFICIENT_FUND");

        PrivateSaleMinter[_kind][msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function publicSaleMint(
        uint256 _quantity
    ) external payable notContract nonReentrant {
        require(stage == Stage.Public, "STAGE_NMATCH");
        require(_quantity <= TX_LIMIT, "TX_LIMIT_EXCEEDED");
        require(
            PrivateSaleMinter[0][msg.sender] == 0 &&
                PrivateSaleMinter[1][msg.sender] == 0,
            "MINTED_IN_PRIVATE_SALE"
        );
        require(
            PublicSaleMinter[msg.sender] + _quantity <= PUBLIC_LIMIT,
            "WALLET_LIMIT_EXCEEDED"
        );
        require(totalSupply() + _quantity <= maxSupply, "SUPPLY_EXCEEDED");
        require(msg.value >= (price * _quantity), "INSUFFICIENT_FUND");

        PublicSaleMinter[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function _verifyPrivateSale(
        address _sender,
        uint256 _limit,
        uint256 _kind,
        bytes calldata _sign
    ) internal view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(PRIVATE_SALE_TYPEHASH, _sender, _limit, _kind))
        );
        return ECDSA.recover(digest, _sign);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // IERC165: 0x01ffc9a7, IERC721: 0x80ac58cd, IERC721Metadata: 0x5b5e139f, IERC29081: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setStage(Stage _stage) external onlyOwner {
        stage = _stage;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
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

    function setGaspackWallet(address _gaspackWallet) external onlyOwner {
        gaspackWallet = _gaspackWallet;
    }

    function setSupernormalWallet(
        address _supernormalWallet
    ) external onlyOwner {
        supernormalWallet = _supernormalWallet;
    }

    function setAuthorizedWallet(address _authorizedWallet) external onlyOwner {
        authorizedWallet = _authorizedWallet;
    }

    function withdrawAll() external {
        require(msg.sender == authorizedWallet, "UNAUTHORIZED");
        require(address(this).balance > 0, "BALANCE_ZERO");
        uint256 gaspackBalance = (address(this).balance * 7000) / 10000;
        uint256 supernormalBalance = (address(this).balance * 3000) / 10000;

        sendValue(payable(gaspackWallet), gaspackBalance);
        sendValue(payable(supernormalWallet), supernormalBalance);
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