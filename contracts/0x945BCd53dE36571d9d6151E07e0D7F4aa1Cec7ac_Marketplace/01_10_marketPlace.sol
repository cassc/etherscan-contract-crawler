pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is AccessControl, ReentrancyGuard {

    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");

    mapping(bytes32 => uint256) public orders;

    address public collectionERC1155;

    constructor(address _collectionERC1155) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SELLER_ROLE, msg.sender);
        collectionERC1155 = _collectionERC1155;
    }

    function createOrder(
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external onlySeller {
        require(price > 0, "Price must be more 0");
        require(amount > 0, "Amount must be more 0");
        IERC1155(collectionERC1155)
        .safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        bytes32 orderHash = keccak256(
            abi.encodePacked(
                msg.sender,
                tokenId,
                price
            )
        );
        orders[orderHash] += amount;
        emit CreateOrder(msg.sender, tokenId, amount, price);
    }

    function returnTokensFromOrder(
        address recepient,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external {
        require(price > 0, "Price must be more 0");
        require(amount > 0, "Amount must be more 0");
        require(recepient != address(0), "Null recepient address");
        bytes32 orderHash = keccak256(
            abi.encodePacked(
                msg.sender,
                tokenId,
                price
            )
        );
        orders[orderHash] -= amount;
        IERC1155(collectionERC1155)
        .safeTransferFrom(address(this), recepient, tokenId, amount, "");
        emit ReturnTokensFromOrder(recepient, msg.sender, tokenId, amount, price);
    }

    function buyTokens(
        address owner,
        uint256 tokenId,
        uint256 price
    ) external payable nonReentrant {
        require(price > 0, "Price must be more 0");
        uint256 amount = msg.value / price;
        bytes32 orderHash = keccak256(
            abi.encodePacked(
                owner,
                tokenId,
                price
            )
        );
        orders[orderHash] -= amount;
        IERC1155(collectionERC1155)
        .safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        emit BuyTokens(msg.sender, owner, tokenId, amount, price);
    }

    function changePrice(
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 newPrice
    ) external {
        require(price > 0, "New price must be more 0");
        require(amount > 0, "Amount must be more 0");
        bytes32 orderHash = keccak256(
            abi.encodePacked(
                msg.sender,
                tokenId,
                price
            )
        );
        bytes32 orderHashNewOrder = keccak256(
            abi.encodePacked(
                msg.sender,
                tokenId,
                newPrice
            )
        );
        orders[orderHash] -= amount;
        orders[orderHashNewOrder] += amount;

        emit ChangePrice(msg.sender, tokenId, amount, price, newPrice);
    }

    function addToWhiteList(address seller) external onlyAdmin {
        _setupRole(SELLER_ROLE, seller);
    }

    function withdrawByAdmin(address payable _destination) external onlyAdmin {
        (bool success,) = _destination.call{value : address(this).balance}("");
        require(success, "Failed to send money");
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory)
    public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
    public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function getVersion() external pure returns (uint8) {
        uint8 version = 1;
        return version;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Function only for admin"
        );
        _;
    }

    modifier onlySeller() {
        require(
            hasRole(SELLER_ROLE, msg.sender),
            "Function only for seller in whiteList"
        );
        _;
    }

    event CreateOrder(
        address owner,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price
    );

    event ReturnTokensFromOrder(
        address recepient,
        address owner,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price
    );

    event BuyTokens(
        address buyer,
        address owner,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price
    );

    event ChangePrice(
        address owner,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price,
        uint256 newPrice
    );
}