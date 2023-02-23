/**
 *Submitted for verification at BscScan.com on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface Erc20Token {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _who) external view returns (uint256);

    function transfer(address _to, uint256 _value) external;

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external;

    function approve(address _spender, uint256 _value) external;

    function burnFrom(address _from, uint256 _value) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Collection {
    using SafeMath for uint256;

    Erc20Token internal constant USDT =
        Erc20Token(0x55d398326f99059fF775485246999027B3197955);

    address public _owner;

    address public _operator;

    mapping(uint256 => address) public _collect;

    mapping(uint256 => address) public _player;

    mapping(uint256 => uint256) public BL;

    constructor() {
        _owner = msg.sender;
        _operator = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Permission denied");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == _operator, "Permission denied");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
    }

    function transferOperatorship(address newOperator) public onlyOwner {
        require(newOperator != address(0));
        _operator = newOperator;
    }

    function setDividendAddressBL(
        address[] calldata NodeAddress,
        uint256[] calldata NodeBL,
        uint256[] calldata index
    ) public onlyOwner {
        require(index.length <= 20);
        for (uint256 i = 0; i < NodeBL.length; i++) {
            uint256 bl = NodeBL[i];
            address add = NodeAddress[i];
            uint256 indexx = index[i];
            BL[indexx] = bl;
            _player[indexx] = add;
        }
    }

    function setCollectionAddressBL(
        address[] calldata cAddress,
        uint256[] calldata index
    ) public onlyOwner {
        require(index.length <= 20);
        for (uint256 i = 0; i < cAddress.length; i++) {
            address add = cAddress[i];
            uint256 indexx = index[i];
            _collect[indexx] = add;
        }
    }

    receive() external payable {}

    function collection(uint256 _quantity) public payable onlyOperator {
        for (uint256 i = 0; i < 20; i++) {
            address add = _collect[i];
            if (add != address(0)) {
                uint256 addBal = _quantity > USDT.balanceOf(add)
                    ? USDT.balanceOf(add)
                    : _quantity;
                if (addBal > 0) {
                    USDT.transferFrom(add, address(this), addBal);
                }
            }
        }
        uint256 thisbal = USDT.balanceOf(address(this));
        require(thisbal > 0, "this balance is 0");
        dividend(thisbal);
    }

    function dividend(uint256 _quantity) public payable onlyOperator {
        for (uint256 i = 0; i < 20; i++) {
            address add = _player[i];
            if (add != address(0)) {
                USDT.transfer(add, _quantity.mul(BL[i]).div(100));
            }
        }
    }

    function withdrawal(address _address, uint256 _quantity) public onlyOwner {
        USDT.transfer(_address, _quantity);
    }
}