// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Monotonic.sol";
import "./OwnerPausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract SimejiSeller is OwnerPausable, ReentrancyGuard {
    using Address for address payable;
    using Monotonic for Monotonic.Increaser;
    using Strings for uint256;
    mapping(address => uint256) private _bought;
    
    struct SellerConfig {
        uint256 totalInventory;
        uint248 airdropQuota;
        uint248 reserveQuota;
        bool reserveFreeQuota;
        bool lockFreeQuota;
        bool lockTotalInventory;
        uint256 maxPerAddress;
        uint256 maxPerTx;
    }

    SellerConfig public  sellerConfig;

    constructor(SellerConfig memory config) {
        sellerConfig = config;
    }

    function _handlePurchase(
        address to,
        uint256 n
    ) internal virtual;

    Monotonic.Increaser private _totalSold;

    function totalSold() public view returns (uint256) {
        return _totalSold.current();
    }

    event Refund(address indexed buyer, uint256 amount);

    event Revenue(
        address indexed beneficiary,
        uint256 numPurchased,
        uint256 amount
    );

    Monotonic.Increaser private airdrop;
    Monotonic.Increaser private reserve;

    function _airdrop(address to, uint256 n)
    internal
    onlyOwner
    whenNotPaused
    {
        SellerConfig storage config = sellerConfig;
        require(sellerConfig.reserveFreeQuota, "SimejiSeller: reserveFreeQuota is false.");
        uint256 remain = config.airdropQuota - airdrop.current();
        n = Math.min(n, remain);
        require(n > 0, "SimejiSeller: airdrop quota exceeded");

        n = Math.min(n, config.totalInventory - _totalSold.current());
        require(n > 0, "SimejiSeller: Sold out");
        
        _handlePurchase(to, n);
        
        _totalSold.add(n);
        airdrop.add(n);
    }

    function _reserve(uint256 requested)
    internal
    onlyOwner
    whenNotPaused
    {
        SellerConfig storage config = sellerConfig;
        require(sellerConfig.reserveFreeQuota, "SimejiSeller: reserveFreeQuota is false.");
        uint256 remain = config.reserveQuota - reserve.current();
        require(remain > 0, "SimejiSeller: reserver quota exceeded");
        uint256 n = Math.min(requested, remain);
        require(n > 0, "SimejiSeller: Sold out");

        _handlePurchase(_msgSender(), n);

        _totalSold.add(n);
        reserve.add(n);
    }

    function _purchase(address to, uint256 requested)
        internal
        nonReentrant
        whenNotPaused
    {
        SellerConfig storage config = sellerConfig;

        uint256 n = config.maxPerTx == 0 ? requested : Math.min(requested, config.maxPerTx);
        
        uint256 maxAvailable = config.reserveFreeQuota
            ? config.totalInventory - (config.airdropQuota + config.reserveQuota)
            : config.totalInventory;
        n = Math.min(n, maxAvailable - (_totalSold.current() - airdrop.current() - reserve.current()));
        require(n > 0, "SimejiSeller: Sold out");

        if (config.maxPerAddress > 0) {
            n = howManyCanBuy(n, to, "Buyer limit");
            _bought[to] += n;
        }

        _handlePurchase(to, n);
        _totalSold.add(n);
        assert(_totalSold.current() <= config.totalInventory);
    }
    
    function howManyCanBuy(uint256 requested, address addr, string memory info) internal view returns(uint256) {
        uint256 left = sellerConfig.maxPerAddress - _bought[addr];
        if (left == 0) {
            revert(string(abi.encodePacked("Seller: ", info)));
        }
        
        return Math.min(requested, left);
    }
    
    function _hadBought(address addr) internal view returns(bool) {
        return _bought[addr] > 0 ? true : false;
    }
}