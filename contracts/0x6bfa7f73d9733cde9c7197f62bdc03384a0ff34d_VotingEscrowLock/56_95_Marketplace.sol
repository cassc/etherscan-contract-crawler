//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Burnable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../utils/ERC20Recoverer.sol";
import "../../core/dividend/libraries/Distributor.sol";
import "../../core/dividend/interfaces/IDividendPool.sol";
import "../../core/governance/Governed.sol";
import "../../core/marketplace/interfaces/IMarketplace.sol";

contract Marketplace is
    Distributor,
    ERC20Recoverer,
    Governed,
    ReentrancyGuard,
    ERC1155Burnable,
    IMarketplace
{
    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20Burnable;
    using SafeMath for uint256;

    uint256 public constant RATE_DENOMINATOR = 10000;

    ERC20Burnable private _commitToken;
    uint256 private _taxRate = 2000; // denominator is 10,000
    mapping(uint256 => Product) private _products;
    uint256[] private _featured;

    modifier onlyManufacturer(uint256 id) {
        require(
            msg.sender == _products[id].manufacturer,
            "allowed only for manufacturer"
        );
        _;
    }

    constructor() ERC1155("") {
        // this constructor will not be called since it'll be cloned by proxy pattern.
        // initalize() will be called instead.
    }

    function initialize(
        address _gov,
        address commitToken_,
        address _dividendPool
    ) public initializer {
        _taxRate = 2000; // denominator is 10,000
        _commitToken = ERC20Burnable(commitToken_);
        ERC20Recoverer.initialize(_gov, new address[](0));
        Governed.initialize(_gov);
        Distributor._setup(_dividendPool);
    }

    function buy(
        uint256 id,
        address to,
        uint256 amount
    ) public override nonReentrant {
        require(amount > 0, "cannot buy 0");
        // check the product is for sale
        Product storage product = _products[id];
        require(product.manufacturer != address(0), "Product not exists");

        if (product.maxSupply != 0) {
            uint256 stock = product.maxSupply.sub(product.totalSupply);
            require(amount <= stock, "Not enough stock");
            require(stock > 0, "Not for sale.");
        }
        uint256 totalPayment = product.price.mul(amount); // SafeMath prevents overflow
        // Vision Tax
        uint256 visionTax = totalPayment.mul(_taxRate).div(RATE_DENOMINATOR);
        // Burn tokens
        uint256 postTax = totalPayment.sub(visionTax);
        uint256 forManufacturer =
            postTax.mul(product.profitRate).div(RATE_DENOMINATOR);
        uint256 amountToBurn = postTax.sub(forManufacturer);
        _commitToken.safeTransferFrom(msg.sender, address(this), visionTax);
        _commitToken.safeTransferFrom(
            msg.sender,
            product.manufacturer,
            forManufacturer
        );
        _commitToken.burnFrom(msg.sender, amountToBurn);
        _distribute(address(_commitToken), visionTax);
        // mint & give
        _mint(to, id, amount, "");
    }

    function manufacture(
        string memory cid,
        uint256 profitRate,
        uint256 price
    ) external override {
        uint256 id = uint256(keccak256(abi.encodePacked(cid, msg.sender)));
        _products[id] = Product(msg.sender, 0, 0, price, profitRate, cid);
        emit NewProduct(id, msg.sender, cid);
    }

    function manufactureLimitedEdition(
        string memory cid,
        uint256 profitRate,
        uint256 price,
        uint256 maxSupply
    ) external override {
        uint256 id = uint256(keccak256(abi.encodePacked(cid, msg.sender)));
        _products[id] = Product(
            msg.sender,
            0,
            maxSupply,
            price,
            profitRate,
            cid
        );
        emit NewProduct(id, msg.sender, cid);
    }

    /**
     * @notice Set max supply and make it a limited edition.
     */
    function setMaxSupply(uint256 id, uint256 _maxSupply)
        external
        override
        onlyManufacturer(id)
    {
        require(_products[id].maxSupply == 0, "Max supply is already set");
        require(
            _products[id].totalSupply <= _maxSupply,
            "Max supply is less than current supply"
        );
        _products[id].maxSupply = _maxSupply;
    }

    function setPrice(uint256 id, uint256 price)
        public
        override
        onlyManufacturer(id)
    {
        // to prevent overflow
        require(price * 1000000000 > price, "Cannot be expensive too much");
        _products[id].price = price;
        emit PriceUpdated(id, price);
    }

    /**
     * @notice The profit rate is based on the post-tax amount of the payment.
     *      For example, when the price is 10000 DCT, tax rate is 2000, and profit rate is 5000,
     *      2000 DCT will go to the vision farm, 4000 DCT will be burnt, and 4000 will be given
     *      to the manufacturer.
     */
    function setProfitRate(uint256 id, uint256 profitRate)
        public
        override
        onlyManufacturer(id)
    {
        require(profitRate <= RATE_DENOMINATOR, "Profit rate is too high");
        _products[id].profitRate = profitRate;
        emit ProfitRateUpdated(id, profitRate);
    }

    function setFeatured(uint256[] calldata featured_)
        external
        override
        governed
    {
        _featured = featured_;
    }

    function setTaxRate(uint256 rate) public override governed {
        require(rate <= RATE_DENOMINATOR);
        _taxRate = rate;
    }

    function commitToken() public view override returns (address) {
        return address(_commitToken);
    }

    function taxRate() public view override returns (uint256) {
        return _taxRate;
    }

    function products(uint256 id)
        public
        view
        override
        returns (Product memory)
    {
        return _products[id];
    }

    function featured() public view override returns (uint256[] memory) {
        return _featured;
    }

    function uri(uint256 id)
        external
        view
        override(IERC1155MetadataURI, ERC1155)
        returns (string memory)
    {
        return string(abi.encodePacked("ipfs://", _products[id].uri));
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        uint256 newSupply = _products[id].totalSupply.add(amount);
        require(
            _products[id].maxSupply == 0 ||
                newSupply <= _products[id].maxSupply,
            "Sold out"
        );
        _products[id].totalSupply = newSupply;
        super._mint(account, id, amount, data);
    }
}