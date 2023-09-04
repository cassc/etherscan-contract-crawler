pragma solidity ^0.8.4;
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./INft.sol";

contract SellManager is Ownable, ReentrancyGuard{
    using SafeMath for *;
    IERC20 public umadToken;
    INft public cardNftToken;
    INft public digitalNftToken;
    INft public cpCardNftToken;
    address payable SELLER_ADDRESS;

    // umad discount
    uint umadDiscount = 95;
    //UMAD Price
    uint[] public umadCardPrices = [22863 * 1e8, 108599.25 * 1e8, 514417.50 * 1e8, 971677.50 * 1e8, 1829040 * 1e8];
    //ETH Price
    uint[] public ethCardPrices = [0.04 * 1e16, 0.19 * 1e16, 0.90 * 1e16, 1.70 * 1e16, 3.2 * 1e16];

    constructor(address payable seller) public{
        SELLER_ADDRESS = seller;
    }

    //设置UMAD折扣 和 价格
    function setParams(uint umad_discount, uint[] memory umadPrices, uint[] memory ethPrices) public onlyOwner {
        require((umad_discount > 0 && umad_discount < 100), 'umad_discount error');
        require((umadPrices.length == ethPrices.length), 'price length must equal');
        umadDiscount = umad_discount;
        umadCardPrices = umadPrices;
        ethCardPrices = ethPrices;
    }

    function getUmadCardPrice(uint code, uint types) public view returns (uint256) {
        require((code == 1 || code == 2 || code == 3 || code == 4), 'code value error');
        uint[] memory priceList;
        if(code == 1 || code == 2)priceList = umadCardPrices;
        if(code == 3 || code == 4)priceList = ethCardPrices;
        require(types <= priceList.length, "types than max error");
        return priceList[types - 1];
    }

    //设置收款地址
    function setSeller(address payable value) public onlyOwner {
        require((value != address(0)), 'seller address null error');
        SELLER_ADDRESS = value;
    }

    function setUmadToken(address value) public onlyOwner {umadToken = IERC20(value);}
    function setCardNft(address value) public onlyOwner {cardNftToken = INft(value);}
    function setDigitalNft(address value) public onlyOwner {digitalNftToken = INft(value);}
    function setCpCardNft(address value) public onlyOwner {cpCardNftToken = INft(value);}
    event SellEvent(address user, uint256 method, uint256 types, uint256 nftId);

    //method含义: 1,UMAD买卡，2UMAD买点数，3ETH买卡，4ETH买点数
    //types含义: 点数，数组下标，从1开始，和后台设置的有序卡的顺序一一对应
    function mintCard(uint256 method, uint256 types, uint256 nftId) public  payable { //nonReentrant
        require((method == 1 || method == 2 || method == 3 || method == 4), 'method value error');
        if(method == 2 || method == 4){
            require(cardNftToken.exists(nftId) ,'game card not exist');
        }
        address user = msg.sender;
        uint256 prices = getUmadCardPrice(method, types);
        if(method == 1 || method == 2){
            prices = prices.mul(umadDiscount).div(100);
            umadToken.transferFrom(user, SELLER_ADDRESS, prices);
        }
        if(method == 3 || method == 4){
            require(msg.value >= prices, "Insufficient funds");
            SELLER_ADDRESS.transfer(prices);
            if (msg.value > prices) {
                uint256 change = msg.value - prices;
                (bool success, ) = msg.sender.call{value: change}("");
                require(success, "Failed to refund excess payment");
            }
//            uint256 change = address(this).balance;
//            if (change > 0) {
//                payable(msg.sender).transfer(change);
//            }
        }
        if(method == 1 || method == 3){
            nftId = cardNftToken.mint(user, types);
        }
        emit SellEvent(user, method, types, nftId);
    }
    function balance() public view returns (uint256) {
        return address(this).balance;
    }
    // Owner mint Game Card for user
    function mintGame(address to, uint256 types) public onlyOwner {
        uint256 nftId = cardNftToken.mint(to, types);
        emit SellEvent(to, 300, types, nftId);
    }

    // Owner mint Degit Card for user
    function mintDegit(address to, uint256 types) public onlyOwner {
        uint256 nftId = digitalNftToken.mint(to, types);
        emit SellEvent(to, 100, types, nftId);
    }

    // Owner mint Cp Card for user
    function mintCp(address to, uint256 types) public onlyOwner {
        uint256 nftId = cpCardNftToken.mint(to, types);
        emit SellEvent(to, 400, types, nftId);
    }
}