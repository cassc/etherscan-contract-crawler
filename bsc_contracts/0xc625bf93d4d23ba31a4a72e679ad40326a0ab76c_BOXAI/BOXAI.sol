/**
 *Submitted for verification at BscScan.com on 2023-05-04
*/

/**

    BOX-AI: is the governance token of 
    our DeFi Rewards Platform. The project 
    will provide a decentralized investment option, 
    so that investors always have control over their 
    funds, 100% automated and instantaneous. A secure 
    staking solution, farms, exchange and AI-powered 
    trading technology coming soon so you can 
    earn without having to trade.

    https://www.boxai.app/
    https://t.me/BoxAI_ecosystem
    https://twitter.com/BoxAi_Ecosystem
    https://www.instagram.com/boxai_ecosystem/
    https://www.youtube.com/channel/UCUR_wPAmcrUp5op4cLK00AQ
    https://github.com/BoxAI-Ecosystem
    https://www.reddit.com/r/BoxAI_Community/
    https://medium.com/@boxai.ecosystem


*/



// SPDX-License-Identifier: UNLICENSE


pragma solidity 0.8.10;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

}



contract BOXAI is Context, IBEP20, Ownable {

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcluded;

    address[] private _excluded;

    address public deployer;

    address public pair;

    string public webSite;
    string public telegram;
    string public twitter;

    uint8 private constant _decimals = 18;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 5000000 * 10 **_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public minimumToSend = 1500 * 10**_decimals;

    address public deadWallet       = 0x000000000000000000000000000000000000dEaD;
    address public marketingWallet  = 0x9B4Bf2A339fb7CE666875eCF7CE33A06738fA682;

    address public addressPCVS2     = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    string private constant _name = "BOX AI";
    string private constant _symbol = "BOX-AI";

    //Taxes only on sale
    struct Taxes {
        uint256 rfi;
        uint256 marketing;
    }
    Taxes public taxes = Taxes(3, 2);

    struct TotFeesPaidStruct {
        uint256 rfi;
        uint256 marketing;
    }

    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rRfi;
        uint256 rMarketing;
        uint256 tTransferAmount;
        uint256 tRfi;
        uint256 tMarketing;
    }
    
    event ExcludeFromFee(address indexed account);
    event ExcludeFromReward(address indexed account);

    constructor() {
        IRouter _router = IRouter(addressPCVS2);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());

        pair = _pair;

        deployer = owner();

        webSite = "boxai.app";
        telegram = "t.me/BoxAI_ecosystem";
        twitter = "twitter.com/BoxAi_Ecosystem";

        excludeFromReward(pair);
        excludeFromReward(deadWallet);

        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[deadWallet] = true;
        emit Transfer(address(0), owner(), _tTotal);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {

        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    //Required function for presale
    //@dev kept original RFI naming -> "reward" as in reflection
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);

        emit ExcludeFromReward(account);
    }

    //Required function for presale
    function excludeFromFee(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -= rRfi;
        totFeesPaid.rfi += tRfi;
    }

    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totFeesPaid.marketing += tMarketing;

        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] += tMarketing;
        }
        _rOwned[address(this)] += rMarketing;
    }

    function _getValues(
        uint256 tAmount,
        bool takeFee
    ) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (
            to_return.rAmount,
            to_return.rTransferAmount,
            to_return.rRfi,
            to_return.rMarketing
        ) = _getRValues(to_return, tAmount, takeFee, _getRate());

        return to_return;
    }

    function _getTValues(
        uint256 tAmount,
        bool takeFee
    ) private view returns (valuesFromGetValues memory s) {
        if (!takeFee) {
            s.tTransferAmount = tAmount;
            return s;
        }

        s.tRfi = (tAmount * taxes.rfi) / 100;
        s.tMarketing = (tAmount * taxes.marketing) / 100;

        s.tTransferAmount =
            tAmount -
            s.tRfi -
            s.tMarketing;

        return s;
    }

    function _getRValues(
        valuesFromGetValues memory s,
        uint256 tAmount,
        bool takeFee,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rRfi,
            uint256 rMarketing
        )
    {
        rAmount = tAmount * currentRate;

        if (!takeFee) {
            return (rAmount, rAmount, 0, 0);
        }

        rRfi = s.tRfi * currentRate;
        rMarketing = s.tMarketing * currentRate;

        rTransferAmount =
            rAmount -
            rRfi -
            rMarketing;

        return (rAmount, rTransferAmount, rRfi, rMarketing);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
                return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            amount <= balanceOf(from),
            "You are trying to transfer more than your balance"
        );

        if (balanceOf(address(this)) >= minimumToSend) sendToMarketing();

        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) takeFee = false;

        //No fees on buy
        if (from == pair) takeFee = false;

        //Common transfer
        if (from != pair && to != pair) takeFee = false;

        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
        ) private {

        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender]) {
            //from excluded
            _tOwned[sender] = _tOwned[sender] - tAmount;
        }
        if (_isExcluded[recipient]) {
            //to excluded
            _tOwned[recipient] = _tOwned[recipient] + s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender] - s.rAmount;
        _rOwned[recipient] = _rOwned[recipient] + s.rTransferAmount;

        if (s.rRfi > 0 || s.tRfi > 0) _reflectRfi(s.rRfi, s.tRfi);
        if (s.rMarketing > 0 || s.tMarketing > 0) _takeMarketing(s.rMarketing, s.tMarketing);
        emit Transfer(sender, recipient, s.tTransferAmount);
    }

    function sendToMarketing() private {
       
        uint256 contractBalance = balanceOf(address(this));

        _tokenTransfer(address(this), marketingWallet, contractBalance, false);

    }

    //Deployer is used to prevent loss of funds on contracts if are renouncced
    //BNB and tokens will not be lost if deposited in the contract and the owner is address(0)

    function rescueBNB() external {
        payable(deployer).transfer(address(this).balance);
    }

    function rescueAnyBEP20Tokens(address _tokenAddr) external {
        require(_tokenAddr != address(this), "Cannot claim native tokens");
        uint256 balanceOfTokens = IBEP20(_tokenAddr).balanceOf(address(this));
        IBEP20(_tokenAddr).transfer(deployer, balanceOfTokens);
    }

}