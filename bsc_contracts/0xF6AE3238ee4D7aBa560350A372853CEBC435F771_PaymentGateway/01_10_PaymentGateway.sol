// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract PaymentGateway is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event ProductPayed(address indexed user, string product_code, string coupon_code, string referrer_code, uint256 total_charged);

    struct Referrer {
        bool initialized;
        bool active;
        uint8 cut_percent;
        address owner;
        uint256 busd_earned;
    }

    struct Product {
        bool initialized;
        bool active;
        uint256 price;
    }

    struct Coupon {
        bool initialized;
        bool active;
        uint8 discount_percent;
        mapping(string => bool) products;
    }

    uint256 constant public ONE_HUNDRED_PERCENT = 100;
    uint256 constant public MAX_CUT_PERCENT = 90;
    uint256 constant public MAX_DISCOUNT_PERCENT = 90;
    address constant public ZERO_ADDRESS = address(0);
    address constant public GNOSIS_ADDRESS = 0xae7a89781Df7c74F3015bcE4cA551e2EAEd86Fb0;
    IERC20Upgradeable constant public BUSD = IERC20Upgradeable(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    mapping(address => string) public users_referrer_code;
    mapping(address => mapping(string => bool)) public users_coupon_used;

    mapping(string => Referrer) public referrer_data;
    mapping(string => Product) public product_data;
    mapping(string => Coupon) public coupon_data;

    string[] public refererrer_code_list;
    string[] public product_code_list;
    string[] public coupon_code_list;

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    function _checkAddressIsNotZero(address account) internal pure {
        require(account != ZERO_ADDRESS, "NO_ZERO_ADDRESS");
    }

    function _checkSenderIs(address user) internal view {
        require(user == _msgSender(), "INVALID_SENDER");
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function referrerCreate(address user, string calldata code, uint8 cut_percent) public onlyOwner {
        require(cut_percent <= MAX_CUT_PERCENT, "INVALID_CUT_PERCENT");

        Referrer storage referrer = referrer_data[code];

        require(referrer.initialized == false, "CODE_IN_USE");

        string storage user_code = users_referrer_code[user];

        require(bytes(user_code).length == 0, "ALREADY_A_REFERRER");

        users_referrer_code[user] = code;
        refererrer_code_list.push(code);

        referrer.initialized = true;
        referrer.active = true;
        referrer.cut_percent = cut_percent;
        referrer.owner = user;
    }

    function referrerSetActive(address user, bool active) public onlyOwner {
        string storage code = users_referrer_code[user];
        Referrer storage referrer = referrer_data[code];

        require(referrer.initialized == true, "NOT_A_REFERRER");

        referrer.active = active;
    }

    function referrerSetCutPercent(address user, uint8 cut_percent) public onlyOwner {
        require(cut_percent <= MAX_CUT_PERCENT, "INVALID_CUT_PERCENT");
        
        string storage code = users_referrer_code[user];
        Referrer storage referrer = referrer_data[code];

        require(referrer.initialized == true, "NOT_A_REFERRER");

        referrer.cut_percent = cut_percent;
    }

    function referrerWithdrawEarnings(address user) public whenNotPaused nonReentrant {
        _checkSenderIs(user);

        string storage code = users_referrer_code[user];
        Referrer storage referrer = referrer_data[code];

        require(referrer.initialized == true, "NOT_A_REFERRER");
        require(referrer.busd_earned > 0, "NOTHING_TO_WITHDRAW");

        BUSD.safeTransfer(user, referrer.busd_earned);

        referrer.busd_earned = 0;
    }

    function productCreate(string calldata code, uint256 price) public onlyOwner {
        Product storage product = product_data[code];
        
        require(product.initialized == false, "CODE_IN_USE");

        product_code_list.push(code);

        product.initialized = true;
        product.active = true;
        product.price = price;
    }

    function productSetActive(string calldata code, bool active) public onlyOwner {
        Product storage product = product_data[code];
        
        require(product.initialized == true, "NOT_A_PRODUCT");

        product.active = active;
    }

    function productSetPrice(string calldata code, uint256 price) public onlyOwner {
        Product storage product = product_data[code];
        
        require(product.initialized == true, "NOT_A_PRODUCT");

        product.price = price;
    }

    function couponCreate(string calldata code, uint8 discount_percent, string[] calldata product_list) public onlyOwner {
        require(discount_percent <= MAX_DISCOUNT_PERCENT, "INVALID_DISCOUNT_PERCENT");

        Coupon storage coupon = coupon_data[code];

        require(coupon.initialized == false, "CODE_IN_USE");

        coupon_code_list.push(code);

        coupon.initialized = true;
        coupon.active = true;
        coupon.discount_percent = discount_percent;

        for (uint i=0; i < product_list.length; i++) {
            string calldata product_code = product_list[i];
            Product storage product = product_data[product_code];

            require(product.initialized == true, "NOT_A_PRODUCT");

            coupon.products[product_code] = true;
        }
    }

    function couponSetActive(string calldata code, bool active) public onlyOwner {
        Coupon storage coupon = coupon_data[code];
        
        require(coupon.initialized == true, "NOT_A_COUPON");

        coupon.active = active;
    }

    function couponSetDiscountPercent(string calldata code, uint8 discount_percent) public onlyOwner {
        require(discount_percent <= MAX_DISCOUNT_PERCENT, "INVALID_DISCOUNT_PERCENT");

        Coupon storage coupon = coupon_data[code];
        
        require(coupon.initialized == true, "NOT_A_COUPON");

        coupon.discount_percent = discount_percent;
    }

    function couponSetProducts(string calldata code, string[] calldata product_list, bool active) public onlyOwner {
        Coupon storage coupon = coupon_data[code];
        
        require(coupon.initialized == true, "NOT_A_COUPON");

        for (uint i=0; i < product_list.length; i++) {
            string calldata product_code = product_list[i];

            if (active == true) {
                Product storage product = product_data[product_code];
                require(product.initialized == true, "NOT_A_PRODUCT");
            }
            
            coupon.products[product_code] = active;
        }
    }

    function pay(address user, string calldata product_code, string calldata coupon_code, string calldata referrer_code) public whenNotPaused nonReentrant {
        _checkSenderIs(user);

        Product storage product = product_data[product_code];

        require(product.initialized == true, "NOT_A_PRODUCT");
        require(product.active == true, "PRODUCT_NOT_ACTIVE");

        uint256 busd_to_charge = product.price;

        if (bytes(coupon_code).length > 0) {
            Coupon storage coupon = coupon_data[coupon_code];

            require(coupon.initialized == true, "NOT_A_COUPON");
            require(coupon.active == true, "COUPON_NOT_ACTIVE");
            require(users_coupon_used[user][coupon_code] == false, "COUPON_USED");

            users_coupon_used[user][coupon_code] = true;

            busd_to_charge -= (coupon.discount_percent * (busd_to_charge / ONE_HUNDRED_PERCENT));
        }

        uint256 total_charged = busd_to_charge;

        if (bytes(referrer_code).length > 0) {
            Referrer storage referrer = referrer_data[referrer_code];

            require(referrer.initialized == true, "NOT_A_REFERRER");
            require(referrer.active == true, "REFERRER_NOT_ACTIVE");
            require(referrer.owner != user, "CANT_REFER_SELF");
            
            uint256 referrer_cut = (referrer.cut_percent * (busd_to_charge / ONE_HUNDRED_PERCENT));

            referrer.busd_earned += referrer_cut;
            busd_to_charge -= referrer_cut;

            BUSD.safeTransferFrom(user, address(this), referrer_cut);
        }

        BUSD.safeTransferFrom(user, GNOSIS_ADDRESS, busd_to_charge);

        emit ProductPayed(user, product_code, coupon_code, referrer_code, total_charged);
    }
}