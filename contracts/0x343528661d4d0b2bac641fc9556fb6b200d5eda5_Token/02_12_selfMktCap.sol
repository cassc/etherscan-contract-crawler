// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interface/IFactory.sol";
import "../interface/IRouter.sol";

contract TokenDistributor {
    constructor (address token) {
        IERC20(token).approve(msg.sender, uint(~uint(0)));
    }
}

contract MktCap is Ownable {
    using SafeMath for uint;
    address ceo;
    address token0;
    address token1;
    IRouter router;
    address pair;
    TokenDistributor public _tokenDistributor;
    struct autoConfig {
        bool status;
        uint minPart;
        uint maxPart;
        uint parts;
    }
    autoConfig public autoSell;
    struct Allot {
        uint markting;
        uint burn;
        uint addL;
        uint total;
    }
    Allot public allot;

    address[] public marketingAddress;
    uint[] public marketingShare;
    uint internal sharetotal;
    

    constructor(address ceo_,   address router_) { 
        ceo=ceo_;
        token0 = address(this); 
        router = IRouter(router_); 
        
    }

    function setAll(
        Allot memory allotConfig,
        autoConfig memory sellconfig,
        address[] calldata list,
        uint[] memory share
    ) public onlyOwner {
        setAllot(allotConfig);
        setAutoSellConfig(sellconfig);
        setMarketing(list, share);
    }

    function setAutoSellConfig(autoConfig memory autoSell_) public onlyOwner {
        autoSell = autoSell_;
    }

    function setAllot(Allot memory allot_) public onlyOwner {
        allot = allot_;
    }

    function setPair(address token) public  onlyOwner {
        token1 = token;
        _tokenDistributor = new TokenDistributor(token1); 
        IERC20(token1).approve(address(router), uint(2 ** 256 - 1));
        pair = IFactory(router.factory()).getPair(token0, token1);
    }

    function setMarketing(
        address[] calldata list,
        uint[] memory share
    ) public onlyOwner {
        require(list.length > 0, "DAO:Can't be Empty");
        require(list.length == share.length, "DAO:number must be the same");
        uint total = 0;
        for (uint i = 0; i < share.length; i++) {
            total = total.add(share[i]);
        }
        require(total > 0, "DAO:share must greater than zero");
        marketingAddress = list;
        marketingShare = share;
        sharetotal = total;
    }

    function getToken0Price() public view returns (uint) {
        //代币价格
        address[] memory routePath = new address[](2);
        routePath[0] = token0;
        routePath[1] = token1;
        return router.getAmountsOut(1 ether, routePath)[1];
    }

    function getToken1Price() public view returns (uint) {
        //代币价格
        address[] memory routePath = new address[](2);
        routePath[0] = token1;
        routePath[1] = token0;
        return router.getAmountsOut(1 ether, routePath)[1];
    }

    function _sell(uint amount0In) internal {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount0In,
            0,
            path,
            address(_tokenDistributor),
            block.timestamp
        );
        IERC20(token1).transferFrom(address(_tokenDistributor),address(this), IERC20(token1).balanceOf(address(_tokenDistributor)));
    }

    function _buy(uint amount0Out) internal {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token0;
        router.swapTokensForExactTokens(
            amount0Out,
            IERC20(token1).balanceOf(address(this)),
            path,
            address(_tokenDistributor),
            block.timestamp
        );

    }

    function _addL(uint amount0, uint amount1) internal {
        if (
            IERC20(token0).balanceOf(address(this)) < amount0 ||
            IERC20(token1).balanceOf(address(this)) < amount1
        ) return;
        router.addLiquidity(
            token0,
            token1,
            amount0,
            amount1,
            0,
            0,
            ceo,
            block.timestamp
        );
    }

    modifier canSwap(uint t) {
        if (t != 2 || !autoSell.status) return;
        _;
    }

    function splitAmount(uint amount) internal view returns (uint, uint, uint) {
        uint toBurn = amount.mul(allot.burn).div(allot.total);
        uint toAddL = amount.mul(allot.addL).div(allot.total).div(2);
        uint toSell = amount.sub(toAddL).sub(toBurn);
        return (toSell, toBurn, toAddL);
    }

    function trigger(uint t) external canSwap(t) {
        uint balance = IERC20(token0).balanceOf(address(this));
        if (
            balance <
            IERC20(token0).totalSupply().mul(autoSell.minPart).div(
                autoSell.parts
            )
        ) return;
        uint maxSell = IERC20(token0).totalSupply().mul(autoSell.maxPart).div(
            autoSell.parts
        );
        if (balance > maxSell) balance = maxSell;
        (uint toSell, uint toBurn, uint toAddL) = splitAmount(balance);
        if (toBurn > 0) IERC20(token0).transfer(address(0xdead), toBurn);
        if (toSell > 0) _sell(toSell);
        uint amount2 = IERC20(token1).balanceOf(address(this));

        uint total2Fee = allot.total.sub(allot.addL.div(2)).sub(allot.burn);
        uint amount2AddL = amount2.mul(allot.addL).div(total2Fee).div(2);
        uint amount2Marketing = amount2.sub(amount2AddL);

        if (amount2Marketing > 0) {
            uint cake;
            for (uint i = 0; i < marketingAddress.length; i++) {
                cake = amount2Marketing.mul(marketingShare[i]).div(sharetotal);
                IERC20(token1).transfer(marketingAddress[i], cake);
            }
        }
        if (toAddL > 0) _addL(toAddL, amount2AddL);
    }

  
}