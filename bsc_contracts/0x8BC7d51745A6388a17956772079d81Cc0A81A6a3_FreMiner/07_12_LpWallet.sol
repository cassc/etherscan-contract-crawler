// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./IBEP20.sol";

//EMPTY CONTRACT TO HOLD THE USERS assetS
contract LpWallet {
    address lptoken;
    address fretoken;
    address _MainContract;
    address _feeowner;
    address _owner;
    uint256 tvlBalancea;
    uint256 tvlBalanceb;

    mapping(address => uint256) _balancesa;
    mapping(address => uint256) _balancesb;

    using TransferHelper for address;
    using SafeMath for uint256;

    event eventWithDraw(
        address indexed to,
        uint256 indexed amounta,
        uint256 indexed amountb
    );

    constructor(
        address tokena,
        address tokenb,
        address feeowner,
        address owner //Create by fremain
    ) {
        _MainContract = msg.sender; // The fremain CONTRACT
        lptoken = tokena;
        fretoken = tokenb;
        _feeowner = feeowner;
        _owner = owner;
    }

    function getBalance(address user, bool isa) public view returns (uint256) {
        if (isa) return _balancesa[user];
        else return _balancesb[user];
    }

    function gettvlBalance(bool isa) public view returns (uint256) {
        if (isa) return tvlBalancea;
        else return tvlBalanceb;
    }

    function addBalance(
        address user,
        uint256 amounta,
        uint256 amountb
    ) public {
        require(_MainContract == msg.sender); //Only fremain can do this
        _balancesa[user] = _balancesa[user].add(amounta);
        _balancesb[user] = _balancesb[user].add(amountb);
        tvlBalancea = tvlBalancea.add(amounta);
        tvlBalanceb = tvlBalanceb.add(amountb);
    }

    function resetTo(address newcontract) public {
        require(msg.sender == _owner);
        _MainContract = newcontract;
    }

    function decBalance(
        address user,
        uint256 amounta,
        uint256 amountb
    ) public {
        require(_MainContract == msg.sender); //Only fremain can do this
        _balancesa[user] = _balancesa[user].sub(amounta);
        _balancesb[user] = _balancesb[user].sub(amountb);
        tvlBalancea = tvlBalancea.sub(amounta);
        tvlBalanceb = tvlBalanceb.sub(amountb);
    }

    function TakeBack(
        address to,
        uint256 amounta,
        uint256 amountb
    ) public {
        require(_MainContract == msg.sender); //Only fremain can do this
        _balancesa[to] = _balancesa[to].sub(amounta);
        _balancesb[to] = _balancesb[to].sub(amountb);
        tvlBalancea = tvlBalancea.sub(amounta);
        tvlBalanceb = tvlBalanceb.sub(amountb);
        if (lptoken != address(2)) //BNB
        {
            uint256 mainfee = amounta.div(100);
            lptoken.safeTransfer(to, amounta.sub(mainfee));
            lptoken.safeTransfer(_feeowner, mainfee);
        }
    }
}
