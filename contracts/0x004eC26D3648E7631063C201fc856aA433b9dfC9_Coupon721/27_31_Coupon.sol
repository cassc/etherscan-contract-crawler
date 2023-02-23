// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../token/IDollar.sol";
import "./Juicing721.sol";
import "../dao/IDAO.sol";

contract Coupon721 is Juicing721 {
    using SafeMath for uint256;
    using Strings for uint256;

    struct Coupon {
        uint256 level;
        uint256 value;
        uint256 discount;
        uint256 maxSupply;
        uint256 couponEpochDecay;
        string name;
        address artist;
        string artistName;
    }

    struct CouponInfo {
        Coupon c;
        uint256 purchaseEpoch;
        uint256 redeemableEpoch;
        uint256 purchaseValue;
    }

    /*
    coupon config
    */
    uint256 private constant peg = 1e18; // 1 dollar
    //default coupon
    Coupon private c1;
    Coupon private c2;
    Coupon private c3;
    Coupon private c4;

    mapping(uint256 => Coupon) private coupon;
    mapping(uint256 => CouponInfo) private couponInfo;

    IDAO private dao;
    IDollar private dollar;

    string internal baseImgURI;

    function initialize(address _dollar) public initializer {
        __ERC721_init("Meme Coupon", "Coupon");
        __ERC721URIStorage_init();
        __AccessControlEnumerable_init();

        _setDefaultRoyalty(msg.sender, 500);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        dollar = IDollar(_dollar);

        c1 = Coupon(1, 1000e18, 100, 1000, 240, "", address(0), ""); // 1,000 pina, 1000 supply, no discount, 2 month redeemable
        c2 = Coupon(2, 10000e18, 98, 100, 480, "", address(0), ""); // 10,000 pina, 100 supply, 98% discount, 4 month redeemable
        c3 = Coupon(3, 100000e18, 96, 10, 960, "", address(0), ""); // 100,000 pina, 10 supply, 96% discount, 8 month redeemable
        c4 = Coupon(4, 1000000e18, 94, 3, 1440, "", address(0), ""); // 100,000 pina, 3 supply, 94% discount, 12 month redeemable
    }

    function setDao(address daoAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dao = IDAO(daoAddress);
    }

    /*
        URI on-chain
    */

    function getBaseImgURI() internal view returns (string memory) {
        return baseImgURI;
    }

    function setBaseImgURI(string memory _baseImgURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseImgURI = _baseImgURI;
    }

    function _generateImgURI(uint256 _baseTokenID) internal view returns (string memory) {
        return
            string(
            abi.encodePacked(getBaseImgURI(), _baseTokenID.toString())
        );
     }

    function _generateAttribute(uint256 value, uint256 purchaseValue, uint256 redeemableEpoch, string memory artistName) internal pure returns (string memory) {
        bytes memory attributes = '[';
        attributes = abi.encodePacked(attributes, attributeJson('value', value.div(1e18).toString()));
        attributes = abi.encodePacked(attributes, ',', attributeJson('burnt', purchaseValue.div(1e18).toString()));
        attributes = abi.encodePacked(attributes, ',', attributeJson('redeemable', redeemableEpoch.toString()));
        attributes = abi.encodePacked(attributes, ',', attributeJson('artist', artistName));
        attributes = abi.encodePacked(attributes, ']');
        return string(attributes);
    }

    function attributeJson(string memory traitType, string memory traitValue) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '{',
                    abi.encodePacked('"trait_type": "', traitType, '",'),
                    abi.encodePacked('"value": "', traitValue, '"'),
                '}'
            );
    }

    function getTokenURI(uint256 baseTokenID, uint256 tokenId, string memory name, uint256 value, uint256 purchaseValue, uint256 redeemableEpoch, string memory artistName) internal view returns (string memory){        
        bytes memory dataURI = abi.encodePacked(
        '{',
            '"name": "',name," #", tokenId.sub(baseTokenID).toString(), '",',
            '"description": "$PINA Coupons on chain, https://www.dontdiememe.com/pina",',
            '"image": "', _generateImgURI(baseTokenID), '",',
            '"attributes": ', _generateAttribute(value, purchaseValue, redeemableEpoch, artistName), '',
        '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    /*
        help functions
    */
    function ownerOf(uint256[] calldata tokenIds)
        public
        view
        returns (address)
    {
        require(tokenIds.length > 0, "invalid tokenids");
        address ownerAddress = ownerOf(tokenIds[0]);
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            require(ownerOf(tokenIds[i]) == ownerAddress, "different owners");
        }
        return ownerAddress;
    }

    function getCoupon(uint256 _baseTokenID)
        external
        view
        returns (Coupon memory)
    {
        return coupon[_baseTokenID];
    }

    function getCouponInfo(uint256 _tokenID)
        external
        view
        returns (CouponInfo memory)
    {
        return couponInfo[_tokenID];
    }

    function getCouponPrice(uint256 _baseTokenID)
        public
        view
        returns (uint256)
    {
        uint256 _price = dao.getPrice();
        if(dao.bootstrapping()){
            _price = 9e17; //fix to 0.9$ during the bootstrapping phase
        }
        if(_price < 33e16){ //min 0.33$
            _price = 33e16;
        }
        Coupon memory c = coupon[_baseTokenID];
        uint256 cPrice = _price.mul(c.value).div(peg);
        uint256 cPriceDiscount = cPrice.mul(c.discount).div(100).div(1e18).mul(1e18);
        return cPriceDiscount;
    }

    function getCouponPurchaseValue(uint256 _tokenID)
        public
        view
        returns (uint256)
    {
        CouponInfo memory cInfo = couponInfo[_tokenID];
        return cInfo.purchaseValue;
    }

    function getCouponValue(uint256 _tokenID) public view returns (uint256) {
        CouponInfo memory cInfo = couponInfo[_tokenID];
        return cInfo.c.value;
    }

    function getCouponsValue(uint256[] calldata tokenIds)
        public
        view
        returns (uint256)
    {
        uint256 value = 0;
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            CouponInfo memory cInfo = couponInfo[tokenIds[i]];
            value = value.add(cInfo.c.value);
        }
        return value;
    }

    /*
    coupon core functions
    */
    function createCoupon(
        uint256 _type,
        string memory _name,
        address _artist,
        string memory _artistName
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 baseTokenID) {
        require(_type <= 3, "invalid type");
        Coupon memory c;
        if (_type == 0) c = c1;
        else if (_type == 1) c = c2;
        else if (_type == 2) c = c3;
        else if (_type == 3) c = c4;
        c.name = _name;
        c.artist = _artist;
        c.artistName = _artistName;
        baseTokenID = create(c.maxSupply);
        coupon[baseTokenID] = c;
    }

    function createCoupon(
        uint256 _level,
        uint256 _value,
        uint256 _discount,
        uint256 _maxSupply,
        uint256 _couponEpochDecay,
        string memory _name,
        address _artist,
        string memory _artistName
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 baseTokenID) {
        Coupon memory c;
        c.level = _level;
        c.value = _value;
        c.discount = _discount;
        c.maxSupply = _maxSupply;
        c.couponEpochDecay = _couponEpochDecay;
        c.name = _name;
        c.artist = _artist;
        c.artistName = _artistName;

        baseTokenID = create(c.maxSupply);
        coupon[baseTokenID] = c;
    }

    function purchaseCoupon(uint256 _baseTokenID) external {
        uint256 _purchasePrice = getCouponPrice(_baseTokenID);
        require(
            dollar.balanceOf(msg.sender) >= _purchasePrice,
            "not enough balance"
        );

        dollar.burnFrom(msg.sender, _purchasePrice);

        uint256 _currentEpoch = dao.epoch();
        Coupon memory c = coupon[_baseTokenID];
        if(c.artist != address(0)){
            uint256 artistFee = _purchasePrice.div(100);  // 1% fee
            _purchasePrice = _purchasePrice.sub(artistFee);
            dollar.mint(c.artist, artistFee);
        }
        CouponInfo memory cInfo;
        cInfo.c = c;
        cInfo.purchaseValue = _purchasePrice;
        cInfo.purchaseEpoch = _currentEpoch;
        cInfo.redeemableEpoch = _currentEpoch.add(c.couponEpochDecay);

        uint256 tokenID = mint(msg.sender, _baseTokenID);
        _setTokenURI(tokenID, getTokenURI(_baseTokenID, tokenID, cInfo.c.name, cInfo.c.value, cInfo.purchaseValue, cInfo.redeemableEpoch, cInfo.c.artistName));
        couponInfo[tokenID] = cInfo;
    }

    function redeemCoupon(uint256 _tokenID) external {
        require(msg.sender == ownerOf(_tokenID), "not the owner");
        uint256 _currentEpoch = dao.epoch();
        CouponInfo memory cInfo = couponInfo[_tokenID];
        uint256 epochPeriod = dao.epochPeriod();
        require(_currentEpoch >= cInfo.redeemableEpoch.mul(21600).div(epochPeriod), "not redeemable now!");

        dollar.mint(msg.sender, cInfo.purchaseValue);
        _burn(_tokenID);
    }

    function setTokenURI(uint256 baseTokenID, uint256 tokenID, string memory name, uint256 value, uint256 purchaseValue, uint256 redeemableEpoch, string memory artistName) external onlyRole(DEFAULT_ADMIN_ROLE){   
        _setTokenURI(tokenID, getTokenURI(baseTokenID, tokenID, name, value, purchaseValue, redeemableEpoch, artistName));
    }

    // function owner() public view virtual returns (address) {
    //     return getRoleMember(0x0000000000000000000000000000000000000000000000000000000000000000, 0);
    // }
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return getRoleMember(0x0000000000000000000000000000000000000000000000000000000000000000, 0);
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}