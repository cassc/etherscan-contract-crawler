// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;
import "./IBEP20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./TransferHelper.sol";

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}


interface IPancakeRouter{
       function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract AutoBuyCharge is Ownable
{
    address _usdt=0x55d398326f99059fF775485246999027B3197955;
    address _mem=0xcD3c6882aF3013EABbe34BEd54E9aBC9dAf6f782;
    address _memtrade=0xb2DA3d27a448952eA5009A6959c7628180826903;
    address _router=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    event UsdtCharge(address indexed user,uint256 indexed amount);
    event MEMCharge(address indexed user,uint256 indexed amount,uint256 indexed memcount);

    uint256 buypct=50;
    using SafeMath for uint256;
    address _feeownerU;
    address _feeownerM;

    constructor()
    {
        _feeownerU=0xB6D94423D01Eaed9D3Cf611fbC1Bc60cDb94F1E6;
        _feeownerM=0xFe2AE28c46B91Df83ddd8a908958105deb56F298;

        IBEP20(_usdt).approve(_router, 1e40);
        IBEP20(_mem).approve(_router, 1e40);
    }

    function Approve() public
    {
        IBEP20(_usdt).approve(_router, 1e40);
        IBEP20(_mem).approve(_router, 1e40);
    }

    function setFeeOwner(address owneru,address ownerm) public onlyOwner 
    {
        _feeownerU=owneru;
        _feeownerM=ownerm;
    }

    function setbuyPct(uint256 pct) public onlyOwner 
    {
        buypct=pct;
    }

    function takeOutErrorTransfer(address tokenaddress,address to,uint256 amount) public onlyOwner
    {
        IBEP20(tokenaddress).transfer(to, amount);
    }

    function ChargeByUsdt(uint256 usdtamount) public
    {
        address user=msg.sender;
        uint256 buy= usdtamount.mul(buypct).div(100);
        uint256 towallet= usdtamount.sub(buy);
        IBEP20(_usdt).transferFrom(user, address(this), usdtamount);
        if(towallet > 0)
            IBEP20(_usdt).transfer(_feeownerU, towallet);
        address[] memory path = new address[](2);
        path[0]=_usdt;
        path[1]= _mem;
        IPancakeRouter(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(buy, 0, path, _feeownerM, 1e40);
        emit UsdtCharge(user,usdtamount);
    }

    function ChargeByMEM(uint256 memamount) public
    {
        address user=msg.sender;
         uint256 balancebefore = IBEP20(_mem).balanceOf(address(this));
        IBEP20(_mem).transferFrom(user, address(this), memamount);
        uint256 balance = IBEP20(_mem).balanceOf(address(this)).subwithlesszero(balancebefore);
         IBEP20(_mem).transfer(_feeownerM, balance);
        uint256 usdtvalue=getMemValue(balance);
        emit MEMCharge(user,usdtvalue,balance);
    }

    function getMemValue(uint256 memaount) public view returns(uint256)
    {
        (uint reserve0, uint reserve1,) = IPancakePair(_memtrade).getReserves();
        (uint256 reserveU, uint256 reserveT) = _usdt == IPancakePair(_memtrade).token0() ? (reserve0, reserve1) : (reserve1, reserve0);
        return memaount.mul(reserveU).div(reserveT);
    }
}