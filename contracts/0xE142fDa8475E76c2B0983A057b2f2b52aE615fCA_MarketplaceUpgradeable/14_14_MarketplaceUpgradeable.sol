pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';

contract MarketplaceUpgradeable is AccessControlUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint8 private constant _version = 3;
    bytes32 public constant SELLER_ROLE = keccak256('SELLER_ROLE');

    address public _paymentToken;

    mapping(address => bool) public tokenToWhitelisted;
    mapping(bytes32 => mapping(uint256 => uint256)) public orders;

    function __Marketplace_init(
        address owner,
        address paymentToken
    ) external initializer {
        __AccessControl_init_unchained();
        __Marketplace_init_unchained(owner, paymentToken);
    }

    function __Marketplace_init_unchained(
        address owner,
        address paymentToken
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(SELLER_ROLE, owner);
        _setPaymentToken(paymentToken);
    }

    function createOrder(
        address token,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external checkPrice(price) onlySeller() onlyWhitelistedAddress(token) {
        IERC1155Upgradeable(token).safeTransferFrom(_msgSender(), address(this), tokenId, amount, '');
        bytes32 orderHash = keccak256(
            abi.encodePacked(
                token,
                _msgSender(),
                tokenId
            )
        );
        orders[orderHash][price] += amount;
        emit CreateOrder(token, _msgSender(), tokenId, amount, price);
    }

    function returnTokensFromOrder(
        address token,
        address recepient,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external {
        bytes32 orderHash = keccak256(
            abi.encodePacked(
                token,
                _msgSender(),
                tokenId
            )
        );
        uint256 balance = orders[orderHash][price];
        require(balance >= amount, 'Marketplace: return amount exceeds balance');
        unchecked {
            orders[orderHash][price] -= amount;
        }
        IERC1155Upgradeable(token).safeTransferFrom(address(this), recepient, tokenId, amount, '');
        emit ReturnTokensFromOrder(token, recepient, _msgSender(), tokenId, amount, price);
    }

    function buyTokens(
        address token,
        address seller,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external {
        _checkRole(SELLER_ROLE, seller);
        IERC20Upgradeable(_paymentToken).safeTransferFrom(
            msg.sender,
            seller,
            amount * price
        );
        bytes32 orderHash = keccak256(
            abi.encodePacked(
                token,
                seller,
                tokenId
            )
        );
        uint256 balance = orders[orderHash][price];
        require(balance >= amount, 'Marketplace: buy amount exceeds balance');
        unchecked {
            orders[orderHash][price] -= amount;
        }
        IERC1155Upgradeable(token).safeTransferFrom(address(this), _msgSender(), tokenId, amount, '');
        emit BuyTokens(token, _msgSender(), seller, tokenId, amount, price);
    }

    function changePrice(
        address token,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 newPrice
    ) external checkPrice(newPrice) {
        bytes32 orderHash = keccak256(
            abi.encodePacked(
                token,
                _msgSender(),
                tokenId
            )
        );
        uint256 oldPriceBalance = orders[orderHash][price];
        require(oldPriceBalance >= amount, 'Marketplace: change price amount exceeds balance');
        bytes32 orderHashNewOrder = keccak256(
            abi.encodePacked(
                token,
                _msgSender(),
                tokenId
            )
        );
        unchecked {
            orders[orderHash][price] -= amount;
        }
        orders[orderHashNewOrder][newPrice] += amount;

        emit ChangePrice(token, _msgSender(), tokenId, amount, price, newPrice);
    }

    function setPaymentToken(address paymentToken) external onlyAdmin() {
        _setPaymentToken(paymentToken);
    }
    function addTokenToWhiteList(address token) external onlyAdmin() onlyContract(token) {
        tokenToWhitelisted[token] = true;
    }

    function removeTokenFromWhiteList(address token) external onlyAdmin() {
        tokenToWhitelisted[token] = false;
    }

    function addSellerRole(address seller) external onlyAdmin() {
        _setupRole(SELLER_ROLE, seller);
    }

    function removeSellerRole(address seller) external onlyAdmin() {
        _revokeRole(SELLER_ROLE, seller);
    }

    function withdrawByAdmin(
        address payable recipient,
        bytes memory payload,
        uint256 value
    ) external onlyAdmin {
        (bool flag, ) = recipient.call{value: value}(payload);
        require(flag, 'Marketplace: fail while calling method');
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256, 
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory, 
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function getVersion() external pure returns (uint8) {
        return _version;
    }

    function _setPaymentToken(address paymentToken) private {
        _paymentToken = paymentToken;
    }

    modifier onlyWhitelistedAddress(address addr) {
        require(tokenToWhitelisted[addr], 'Marketplace: not whitelisted address');
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'Marketplace: function only for admin'
        );
        _;
    }
  
    modifier onlySeller() {
        require(
            hasRole(SELLER_ROLE, _msgSender()),
            'Marketplace: function only for seller'
        );
        _;
    }

    modifier onlyContract(address addr) {
        require(
            AddressUpgradeable.isContract(addr),
            'Marketplace: not contract address'
        );
        _;
    }

    modifier checkPrice(uint256 price) {
        require(price > 0, 'Marketplace: price must be more 0');
        _;
    }

    event CreateOrder(
        address token,
        address seller,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price
    );

    event ReturnTokensFromOrder(
        address token,
        address recepient,
        address seller,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price
    );

    event BuyTokens(
        address token,
        address buyer,
        address seller,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price
    );

    event ChangePrice(
        address token,
        address seller,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price,
        uint256 newPrice
    );

    uint256[200] private __gap;
}