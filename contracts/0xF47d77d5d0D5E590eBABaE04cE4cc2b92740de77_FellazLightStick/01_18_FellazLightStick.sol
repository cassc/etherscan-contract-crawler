//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FellazLightStick is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    struct AllowERC20Wrapper {
        address erc20Address;
        uint256 use;
    }

    struct PriceInfo {
        uint256 price;
        bool free;
    }

    struct SponsorInfo {
        address direction;
        uint256 expired;
    }

    mapping(uint256 => SponsorInfo) private _sponsorList;
    mapping(address => mapping(address => PriceInfo)) private _priceERC20;
    mapping(address => uint256) private _feeERC20;
    mapping(address => PriceInfo) private _priceETH;
    uint256 private _feeETH;
    EnumerableMap.AddressToUintMap private _allowERC20;

    string private baseURI;

    event Activate(
        address indexed direction, 
        address indexed owner, 
        uint256 indexed tokenId, 
        uint256 expired, 
        uint256 active, 
        address payments, 
        uint256 price, 
        uint256 amount
    );
    event Price(address indexed direction, address indexed paymentAddress, uint256 indexed price);
    event Fee(address indexed paymentAddress, uint256 indexed fee);
    event Withdraw(address indexed target, address indexed paymentAddress, uint256 indexed price);
    event AllowERC20(address indexed paymentAddress, uint indexed use);
    event SetBaseURI(address indexed sender, string indexed newUri);

    constructor() ERC721("FellazLightStick", "FLS") {
        _priceETH[address(0)].price = 0.02 ether;
        _feeETH = 0.01 ether;
    }

    /*
    * @dev ERC20 Token Check Supported
    */
    modifier checkERC20(address addressERC20) {
        require(addressERC20 > address(0), "Invalid ERC20 Address");
        require(_allowERC20.get(addressERC20, "Unregistered ERC20 address") == 1, "Unsupported ERC20 Token");
        _;
    }

    /*
    * @dev Get artist NFT's Ethereum price
    */
    function getPriceETH(address directionAddress, uint256 amount) public view returns (uint256) {
        uint256 price = _priceETH[directionAddress].price > 0 ? 
            _priceETH[directionAddress].price : 
            ( _priceETH[directionAddress].free ? 0 : _priceETH[address(0)].price );

        return (price.add(getFeeETH())).mul(amount);
    }

    /*
    * Get ERC20 Token price supported by artist NFT
    */
    function getPriceERC20(address paymentAddress, address directionAddress, uint256 amount) 
        public 
        view 
        checkERC20(paymentAddress) 
        returns(uint256) 
    {
        uint256 price = _priceERC20[paymentAddress][directionAddress].price > 0 ? 
            _priceERC20[paymentAddress][directionAddress].price : 
            (_priceERC20[paymentAddress][directionAddress].free ? 0 : _priceERC20[paymentAddress][address(0)].price);

        return (price.add(getFeeERC20(paymentAddress))).mul(amount);
    }

    /*
    * @dev Set the price for each artist according to ERC20.
    */
    function setPriceERC20(address paymentAddress, address directionAddress, uint256 priceWei) 
        public 
        onlyOwner 
        checkERC20(paymentAddress) 
    {
        _priceERC20[paymentAddress][directionAddress].price = priceWei;
        _priceERC20[paymentAddress][directionAddress].free = priceWei == 0 ? true : false;

        emit Price(directionAddress, paymentAddress, priceWei);
    }

    /*
    * @dev Set the price for each artist according to ETH.
    */
    function setPriceETH(address directionAddress, uint256 priceWei) public onlyOwner {
        _priceETH[directionAddress].price = priceWei;
        _priceETH[directionAddress].free = priceWei == 0 ? true : false;

        emit Price(directionAddress, address(0), priceWei);
    }

    /*
    * @dev The artist sets his or her own price according to ERC20.
    */
    function setPriceByDirectionERC20(address paymentAddress, uint256 priceWei) 
        public 
        checkERC20(paymentAddress) 
    {
        _priceERC20[paymentAddress][msg.sender].price = priceWei;
        _priceERC20[paymentAddress][msg.sender].free = priceWei == 0 ? true : false;

        emit Price(msg.sender, paymentAddress, priceWei);
    }

    /*
    * @dev The artist sets his or her own price according to ETH
    */
    function setPriceByDirectionETH(uint256 priceWei) public {

        _priceETH[msg.sender].price = priceWei;
        _priceETH[msg.sender].free = priceWei == 0 ? true : false;

        emit Price(msg.sender, address(0), priceWei);
    }

    /*
    * @dev Get ETH fees for each artist.
    */
    function getFeeETH() public view returns (uint256) {
        return _feeETH;
    }

    /*
    * @dev Get ERC20 fees for each artist.
    */
    function getFeeERC20(address paymentAddress) 
        public 
        view 
        checkERC20(paymentAddress) 
        returns (uint256) 
    {
        return _feeERC20[paymentAddress];
    }

    /*
    * @dev Set ETH fees for each artist.
    */
    function setFeeETH(uint256 feeWei) public onlyOwner {
        _feeETH = feeWei;

        emit Fee(address(0), feeWei);
    }

    /*
    * @dev Set ERC20 fees for each artist.
    */
    function setFeeERC20(address paymentAddress, uint256 feeWei) 
        public 
        onlyOwner 
        checkERC20(paymentAddress) 
    {
        _feeERC20[paymentAddress] = feeWei;

        emit Fee(paymentAddress, feeWei);
    }

    /*
    * @dev Supported ERC20 Token Settings
    */
    function setAllowERC20(address paymentAddress, uint use) public onlyOwner {
        require(paymentAddress > address(0), "Invalid ERC20 address.");

        _allowERC20.set(paymentAddress, use);

        emit AllowERC20(paymentAddress, use);
    }

    /*
    * @dev Verify that the ERC20 token address is available.
    */
    function getAllowERC20(address paymentAddress) public view returns (uint) {
        return _allowERC20.get(paymentAddress);
    }

    /*
    * @dev Enable the ERC20 token and register the fee.
    */
    function setAllwoFeeERC20(address paymentAddress, uint use, uint256 feeWei) public onlyOwner {
        require(paymentAddress > address(0), "Invalid ERC20 address.");

        setAllowERC20(paymentAddress, use);
        setFeeERC20(paymentAddress, feeWei);
    }

    /*
    * @dev Gets the list of registered ERC20 token addresses.
    */
    function getAllowERC20List() public view returns(AllowERC20Wrapper[] memory) {
        uint256 allowCnt = _allowERC20.length();
        AllowERC20Wrapper[] memory allowAll = new AllowERC20Wrapper[] (allowCnt);

        for(uint256 i = 0; i < allowCnt; i++ ) {
            (address erc20Address, uint256 use) = _allowERC20.at(i);
            allowAll[i] = AllowERC20Wrapper(erc20Address, use);
        }

        return allowAll;
    }

    /*
    * @dev Mint Light Stick with ETH
    */
    function mint(address directionAddress, uint256 amount) public payable nonReentrant{
        uint256 price = getPriceETH(directionAddress, amount);

        require(amount > 0, "Amount is zero");
        require(msg.value == price, "insufficient value");
        require(directionAddress > address(0), "Invalid wallet address");
        
        uint256 tokenId = totalSupply();
        
        _sponsorList[tokenId].direction = directionAddress;
        _sponsorList[tokenId].expired = block.timestamp + ((amount*90) * 1 days);
        _mint(msg.sender, tokenId);

        withdrawETH(directionAddress, amount);

        emit Activate(
            directionAddress, 
            msg.sender, 
            tokenId, 
            _sponsorList[tokenId].expired, 
            0, 
            address(0), 
            price, 
            amount
        );
    }

    /*
    * @dev Extend the Light Stick's expiration with ETH
    */
    function extend(uint256 tokenId, uint256 amount) public payable nonReentrant{
        require(_exists(tokenId), "token not exist");
        address directionAddress = direction(tokenId);
        uint256 price = getPriceETH(directionAddress, amount);

        require(amount > 0, "Amount is zero");
        require(msg.value == price, "insufficient value");
        
        _sponsorList[tokenId].expired = _sponsorList[tokenId].expired + ((amount*90) * 1 days);

        withdrawETH(directionAddress, amount);

        emit Activate(
            direction(tokenId), 
            msg.sender, 
            tokenId, 
            _sponsorList[tokenId].expired, 
            1, 
            address(0), 
            price, 
            amount
        );
    }

    /*
    * @dev Mint Light Stick with ERC20
    */
    function mintWithERC20(address directionAddress, address paymentAddress, uint256 amount)
        public
        nonReentrant
        checkERC20(paymentAddress)
    {
        uint256 price = getPriceERC20(paymentAddress, directionAddress, amount);
        require(amount > 0, "Amount is zero");
        require(price > 0, "This Payments is Unsupported");
        require(directionAddress > address(0), "Invalid wallet address");

        require(
            IERC20(paymentAddress).allowance(msg.sender, address(this)) == price, 
            "insufficient approve"
        );
        require(
            IERC20(paymentAddress).balanceOf(msg.sender) >= price, 
            "insufficient value"
        );

        uint256 tokenId = totalSupply();
        _sponsorList[tokenId].direction = directionAddress;
        _sponsorList[tokenId].expired = block.timestamp + ((amount * 90) * 1 days);
        _mint(msg.sender, tokenId);

        withdrawERC20(directionAddress, paymentAddress, amount);

        emit Activate(
            directionAddress, 
            msg.sender, 
            tokenId, 
            _sponsorList[tokenId].expired, 
            0, 
            paymentAddress, 
            price, 
            amount
        );
    }

    /*
    * @dev Extend the Light Stick's expiration with ERC20
    */
    function extendWithERC20(uint256 tokenId, address paymentAddress, uint256 amount)
        public
        nonReentrant
        checkERC20(paymentAddress)
    {
        require(_exists(tokenId), "token not exist");
        address directionAddress = direction(tokenId);
        uint256 price = getPriceERC20(paymentAddress, directionAddress, amount);
        require(amount > 0, "Amount is zero");
        require(price > 0, "This Payments is Unsupported");
        
        require(
            IERC20(paymentAddress).allowance(msg.sender, address(this)) == price, 
            "insufficient approve"
        );
        require(
            IERC20(paymentAddress).balanceOf(msg.sender) >= price, 
            "insufficient value"
        );

        _sponsorList[tokenId].expired = _sponsorList[tokenId].expired + ((amount*90) * 1 days);

        withdrawERC20(directionAddress, paymentAddress, amount);
        
        emit Activate(
            direction(tokenId), 
            msg.sender, 
            tokenId, 
            _sponsorList[tokenId].expired, 
            1, 
            paymentAddress, 
            price, 
            amount
        );
    }

    /*
    * @dev Gets the artist wallet address of the token.
    */
    function direction(uint256 tokenId) public view returns (address) {
        return _sponsorList[tokenId].direction;
    }

    /*
    * @dev Gets the expiration date of that token.
    */
    function expired(uint256 tokenId) public view returns (uint256) {
        return _sponsorList[tokenId].expired;
    }

    /*
    * @dev Get baseURI(internal function)
    */
    function _baseURI() internal view override virtual returns (string memory) {
        return baseURI;
    }

    /*
    * @dev Set baseURI
    */
    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;

        emit SetBaseURI(msg.sender, baseURI);
    }

    /*
    * @dev Get baseURI
    */
    function uri() public view virtual returns (string memory) {
        return _baseURI();
    }

    /*
    * @dev Returns the array of token id as address
    */
    function tokensOfOwner(address owner) public  view returns (uint256[] memory) {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }

        return ids;
    }

    /*
    * @dev Withdraw ETH as owner and artist
    */
    function withdrawETH(address directionAddress, uint256 amount) internal {
        uint256 fee = getFeeETH().mul(amount);
        (bool feeSuccess, ) = payable(owner()).call{value: fee}("");

        require(feeSuccess, "ETH fee withdraw fail");

        emit Withdraw(owner(), address(0), fee);

        uint256 price = getPriceETH(directionAddress, amount);
        uint256 calculate = SafeMath.sub(price, fee, "SafeMath: subtraction overflow");
        if (calculate > 0) {
            (bool success, ) = payable(directionAddress).call{value: calculate}("");

            require(success, "ETH withdraw fail");

            emit Withdraw(directionAddress, address(0), calculate);
        }
    }

    /*
    * @dev Withdraw ERC20 as owner and artist
    */
    function withdrawERC20(address directionAddress, address paymentAddress, uint256 amount) internal {
        uint256 fee = getFeeERC20(paymentAddress).mul(amount);
        IERC20(paymentAddress).transferFrom(msg.sender, owner(), fee);

        emit Withdraw(owner(), paymentAddress, fee);

        uint256 price = getPriceERC20(paymentAddress, directionAddress, amount);
        uint256 calculate = SafeMath.sub(price, fee, "SafeMath: subtraction overflow");
        if (calculate > 0) {
            IERC20(paymentAddress).transferFrom(msg.sender, directionAddress, calculate);

            emit Withdraw(directionAddress, paymentAddress, calculate);
        }
    }

}