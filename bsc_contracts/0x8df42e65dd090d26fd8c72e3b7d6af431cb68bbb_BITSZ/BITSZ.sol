/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
    
}

struct TokenConfig {
    string _name;
    string _symbol;
    uint8 _decimals;
    uint256 _totalSupply;
    bool _isPaused;
    uint256 _totalTransferToOtherChain;
    uint256 _totalTransferFromOtherChain;
    address _admin;
    address _owner;
    uint256 _baseChainId;
}

struct UserDetails {
    uint256 _nonce;
    uint256 _balances;
    uint256 _airdropLocktime;
    uint256 _airdropAmount;

}

contract BITSZ is Context {

    TokenConfig _config;
    mapping(address =>  UserDetails) private _user;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address =>  mapping(bytes32 => bool)) private _tokenIn;
    mapping(address =>  mapping(uint256 => uint256)) private _tokenOut;

    constructor() {
        _config._name = "BITSZ";
        _config._symbol = "BITSZ";
        _config._decimals = 18;
        _config._baseChainId = 56;
        _config._admin = _msgSender();
        _config._owner = 0x3ce10F1641Ff8a44Be759F663662bF0E1b6B926B;

        if(_config._baseChainId == 56){
            _config._totalSupply = 5000000000*1e18;
            _transfer(address(0), _config._owner, _config._totalSupply, false);
        }
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() public view returns (string memory) {
        return _config._name;
    }

    function symbol() public view returns (string memory) {
        return _config._symbol;
    }

    function decimals() public view returns (uint8) {
        return _config._decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _config._totalSupply;
    }

    function tokenConfig() public view returns(TokenConfig memory){
        TokenConfig memory tempConfig = _config;
        return tempConfig;        
    }

    function userDetails(address account) public view returns(UserDetails memory){
        UserDetails memory tempUser = _user[account];
        return tempUser;        
    }

    function balanceOf(address account) public view returns (uint256) {
        return _user[account]._balances;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount, 
        bool isPublic
    ) internal {
        require(!_config._isPaused, "Contract is Paused");

        if(isPublic){
            require(from != to, "ERC20: Transfer to same address");
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");
        }

        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = 0;

        if(_user[from]._airdropLocktime > block.timestamp){
            unchecked { 
                fromBalance = _user[from]._balances - _user[from]._airdropAmount;
            }
        } else {
            if(_user[from]._airdropAmount > 0){
                _user[from]._airdropLocktime = 0;
                _user[from]._airdropAmount = 0;
            }
            fromBalance = _user[from]._balances;
        }
        if(from != address(0)){
            require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        }
        unchecked {
            if(from != address(0)){
                _user[from]._balances -= amount;
            }
            if(to != address(0)){
                _user[to]._balances += amount;
            }
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount, true);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount, true);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = _msgSender();
        unchecked {
            _approve(owner, spender, allowance(owner, spender) + addedValue);
        }
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function multiTransfer(address[] memory toAccounts, uint256[] memory amounts) public returns (bool) {
        address owner = _msgSender(); 
        _beforeProcessArray(toAccounts, amounts);
        require(toAccounts.length == amounts.length, "ERC20: Accounts not matching with amounts list");
        require(toAccounts.length <= 1000, "ERC20: Exceeds the allowed limit");
        require(_user[owner]._balances >= sumAmts(amounts), "Transfer amount exceeds balance");
        for (uint8 i; i < toAccounts.length; i++) {
            _transfer(owner, toAccounts[i], amounts[i], true);
        }       
        _afterProcessArray(toAccounts, amounts); 
        return true;
    }

    function multiTransferFrom(address from, address[] memory toAccounts, uint256[] memory amounts) public returns (bool) {
        address spender = _msgSender(); 
        _beforeProcessArray(toAccounts, amounts);
        require(toAccounts.length == amounts.length, "ERC20: Accounts not matching with amounts list");
        require(toAccounts.length <= 1000, "ERC20: Exceeds the allowed limit");
        _spendAllowance(from, spender, sumAmts(amounts));
        require(_user[from]._balances >= sumAmts(amounts), "Transfer amount exceeds balance");
        for (uint8 i; i < toAccounts.length; i++) {
            _transfer(from, toAccounts[i], amounts[i], true);
        }       
        _afterProcessArray(toAccounts, amounts); 
        return true;
    }

    function airdrop(address[] memory toAccounts, uint256[] memory amounts) public returns (bool) {
        address owner = _msgSender(); 
        _beforeProcessArray(toAccounts, amounts);
        require(owner == _config._owner, "ERC20: Only Token Owner can update");
        require(toAccounts.length == amounts.length, "ERC20: Accounts not matching with amounts list");
        require(toAccounts.length <= 1000, "ERC20: Exceeds the allowed limit");
        require(_user[owner]._balances >= sumAmts(amounts), "Transfer amount exceeds balance");
        uint256 unlockTime;
        uint256 airdropAmount;
        unchecked {
            unlockTime = block.timestamp + (86400 * 365);
        }
        for (uint8 i; i < toAccounts.length; i++) {
            unchecked {
                airdropAmount = amounts[i] + ((amounts[i] * 12) / 100);
            }
            if(_user[toAccounts[i]]._airdropLocktime < block.timestamp && _user[toAccounts[i]]._airdropAmount > 0){
                _user[toAccounts[i]]._airdropLocktime = 0;
                _user[toAccounts[i]]._airdropAmount = 0;
            }
            _transfer(owner, toAccounts[i], airdropAmount, true);
            _user[toAccounts[i]]._airdropLocktime = unlockTime;
            unchecked {
                _user[toAccounts[i]]._airdropAmount += airdropAmount;
            }
        }       
        _afterProcessArray(toAccounts, amounts);  
        return true;
    }

    function transferFromOtherChain(bytes32 txid, uint256 swapNonce, uint256 amount, uint256 fees, uint256 fromChainId, bytes memory sig) public returns (bool) {

        require(!_tokenIn[_msgSender()][txid], "Already Claimed");

        _sigValidate(sig, keccak256(abi.encodePacked(_msgSender(), txid, swapNonce, amount, fees, fromChainId, _config._baseChainId, true)), _config._admin);

        _transfer(address(0), _msgSender(), amount, false);

        unchecked {
            _config._totalTransferFromOtherChain += amount;
            _config._totalSupply += amount;
        }    

        return true;
    }
    
    function transferToOtherChain(uint256 amount, uint256 swapNonce, uint256 toChainId) public returns (bool) {

        _transfer(_msgSender(), address(0), amount, false);

        _tokenOut[_msgSender()][swapNonce] = toChainId;

        unchecked {
            _config._totalTransferToOtherChain += amount;
            _config._totalSupply -= amount;
        }

        return true;
    }

    function updateConfig(bool paused, address owner) public returns (bool) {

        require(_msgSender() == _config._admin, "ERC20: Only admin can update");
        if(_config._isPaused != paused){
            _config._isPaused = paused;
        }
        if(owner != address(0)){
            _config._owner = owner;
        }
        return true;

    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != spender, "ERC20: No need to approve yourself");
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
       return (v, r, s);
    }       
   
    function _sigValidate(bytes memory sig, bytes32 hash, address account) internal pure {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(sig);
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == account, "Not Authorized");
    }

    function sumAmts(uint256[] memory amounts) internal pure returns (uint256) {
		uint256 sum_;
        for (uint8 g; g < amounts.length; g++) {
            unchecked {
                sum_ += amounts[g];  
            }          
        }
        return sum_;
    }

    function _beforeProcessArray(
        address[] memory accounts,
        uint256[] memory amounts
    ) internal {}

    function _afterProcessArray(
        address[] memory accounts,
        uint256[] memory amounts
    ) internal {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}
}