// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

interface IPancakeRouter {
    function getAmountsOut(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
interface ICOMM {
    function handleComm(address _fromUser, uint _amount, IERC20 tokenBuy) external;
}
interface IRefferal {
    function userInfos(address _user) external view returns(address user,
        address refferBy,
        uint dateTime,
        uint totalRefer,
        uint totalRefer7,
        bool top10Refer);
    function isReferrer(address _user) external view returns(bool);
}
interface ISellBox {
    function childBuyBox(address _user) external view returns(uint totalChildBuy);
}
contract SellBoxBySOT is Ownable {
    IPancakeRouter public pancakeRouter;
    IRefferal public refer;
    ISellBox  sellBox;
    IERC20 public immutable tokenBuy;
    address public immutable BUSD;
    address public immutable WBNB;
    address public immutable SOW;
    IERC1155 public immutable box;
    ICOMM public commTreasury;

    address public ceo;
    mapping(uint => uint) public remains; // token Id => price
    struct ChildBuyBox {
        mapping(address => bool) isChildBuy;
        uint totalChildBuy;
    }
    mapping(address => ChildBuyBox) public childBuyBoxs; // user => info

    mapping(uint => uint) public prices; // token Id => price

    modifier onlyCeo() {
        require(ceo == _msgSender(), "SellBox: caller is not the ceo");
        _;
    }

    constructor(ISellBox _sellBox, IPancakeRouter _pancakeRouteAddress, address _WBNBAddress, address _BUSDAddress, address _SOW, IRefferal _refer, IERC1155 _box, IERC20 _tokenBuy, address _ceo) {
        sellBox = _sellBox;
        pancakeRouter = _pancakeRouteAddress;
        WBNB = _WBNBAddress;
        BUSD = _BUSDAddress;
        SOW = _SOW;
        refer = _refer;
        box = _box;
        tokenBuy = _tokenBuy;
        ceo = _ceo;
        prices[1] = 150 ether;
        remains[1] = 10000;
        prices[2] = 100 ether;
        remains[2] = 10000;
        prices[3] = 50 ether;
        remains[3] = 10000;
        prices[4] = 25 ether;
        remains[4] = 10000;
    }
    function setTreasury(ICOMM _commTreasury) external onlyOwner {
        commTreasury = _commTreasury;
    }
    function childBuyBox(address user) external view returns(uint totalChildBuy) {
        totalChildBuy = sellBox.childBuyBox(user) + childBuyBoxs[user].totalChildBuy;
    }
    function bnbPrice() public view returns (uint[] memory amounts){
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = WBNB;
        amounts = IPancakeRouter(pancakeRouter).getAmountsIn(1 ether, path);
    }

    function tokenPrice(address token) public view returns (uint[] memory amounts){
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = BUSD;
        amounts = IPancakeRouter(pancakeRouter).getAmountsIn(1 ether, path);
    }
    function busd2Token(address token, uint busd) public view returns (uint amount){
        uint[] memory amounts = tokenPrice(token);
        amount = amounts[0] * busd / 1 ether;
    }
    function buy(uint _tokenId, uint _amount) external {
        require(prices[_tokenId] > 0 , "SellBox::buy: Invalid token id");
        require(remains[_tokenId] >= _amount, "SellBox::buy: remain not enough");
        uint totalBill = busd2Token(address(tokenBuy), prices[_tokenId] * _amount);
        uint buyBack = totalBill * 20 / 100;
        uint comm = totalBill * 35 / 100;

        box.safeTransferFrom(owner(), _msgSender(), _tokenId, _amount, '0x');
        remains[_tokenId] -= _amount;

        address _refferBy;
        (,_refferBy,,,,) = refer.userInfos(_msgSender());
        if(_tokenId == 1 || _tokenId == 2) {
            if(!childBuyBoxs[_refferBy].isChildBuy[_msgSender()]) {
                childBuyBoxs[_refferBy].isChildBuy[_msgSender()] = true;
                childBuyBoxs[_refferBy].totalChildBuy++;
            } else childBuyBoxs[_refferBy].totalChildBuy++;
        }

        if(refer.isReferrer(_msgSender())) {
            tokenBuy.transferFrom(_msgSender(), ceo, totalBill - comm - buyBack);
            tokenBuy.transferFrom(_msgSender(), address(commTreasury), comm);

            commTreasury.handleComm(_msgSender(), totalBill, tokenBuy);
        } else {
            tokenBuy.transferFrom(_msgSender(), ceo, totalBill - buyBack);
        }
        tokenBuy.transferFrom(_msgSender(), address(this), buyBack);
        address[] memory path = new address[](3);
        path[0] = address(tokenBuy);
        path[1] = BUSD;
        path[2] = SOW;
        uint[] memory amounts = IPancakeRouter(pancakeRouter).getAmountsOut(buyBack, path);
        tokenBuy.approve(address(pancakeRouter), buyBack);
        pancakeRouter.swapExactTokensForTokens(buyBack, amounts[2], path, address(this), block.timestamp);
        ERC20Burnable(SOW).burn(IERC20(SOW).balanceOf(address(this)));
    }
    function setCeo(address _ceo) public onlyCeo {
        ceo = _ceo;
    }
    function setPrice(uint _tokenId, uint _price, uint _remain) public onlyOwner {
        prices[_tokenId] = _price;
        remains[_tokenId] = _remain;
    }
    function setSellBox(ISellBox _sellBox) external onlyOwner {
        sellBox = _sellBox;
    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}