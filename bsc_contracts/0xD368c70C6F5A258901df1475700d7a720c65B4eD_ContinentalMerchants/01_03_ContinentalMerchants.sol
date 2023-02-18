// SPDX-License-Identifier: MIT
// https://t.me/continental_gold

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SafeMath.sol";

contract ContinentalMerchants {

    using SafeMath for uint256;

    address payable private _owner;
    uint256 private _percent;
    string private _contacts;
    uint256 private _percentDivider;
    address private _cgtAddress;
    uint256 private _cgtAmount;
    uint256 private _cgtPercent;
    uint256 private _balanceBnb;

    constructor(uint256 percent,string memory contacts,uint256 percentDivider){
        _percent = percent;
        _contacts = contacts;
        _percentDivider = percentDivider;
        _owner = payable(msg.sender);
    }

    struct AddressesERC20 {
        address _addressERC20;
        uint256 _balance;
        bool _status;
    }

    struct MassPayOut {
        uint256 _orderId;
        address _recipient;
        address _addressERC20;
        uint256 _amount;
    }

    struct Merchant{
        address payable _owner;
        uint256 _percent;
        address payable _withdrawalAddress;
        uint256 _balanceBnb;
        bool _statusBnb;
        bool _status;
    }

    Merchant[] private _merchants;
    mapping(address => uint256) private _balancesTokens;
    mapping(uint256 => AddressesERC20[]) private _addressesTokensERC20;

    event addMerchantEvent(uint256 indexed merchantId, address indexed owner, uint256 percent, address withdrawAddress);
    event topUpEvent(uint256 indexed merchantId,uint256 indexed orderId,uint256 amount,address addressERC20,address indexed addressUser);
    event withdrawalEvent(uint256 indexed merchantId,uint256 amount,address indexed addressERC20,address indexed addressUser);
    event massPayOutEvent(uint256 indexed merchantId,uint256 indexed orderId,uint256 amount,address addressERC20,address indexed addressUser);

    function topUp(uint256 _merchantId,uint256 _orderId,address _addressERC20,uint256 _amount,bool _isOrder) public payable {
        require(_merchants[_merchantId]._status == true,"Merchant is disabled");
        uint256 percent = _merchants[_merchantId]._percent;
        if(_cgtAddress != address(0)){
            IERC20 bonusToken = IERC20(_cgtAddress);
            if(bonusToken.balanceOf(_merchants[_merchantId]._owner) >= _cgtAmount){
                percent = _cgtPercent;
            }
        }
        require((_addressERC20 == address(0) && _merchants[_merchantId]._statusBnb == true) || _addressERC20 != address(0));
        if(_addressERC20 == address(0) && _merchants[_merchantId]._statusBnb == true){
            _amount = msg.value;
            if(_merchants[_merchantId]._withdrawalAddress == address(0) || _isOrder == false){
                _merchants[_merchantId]._balanceBnb += _amount.sub(_amount.mul(percent).div(_percentDivider));
                _balanceBnb += _amount.sub(_amount.mul(percent).div(_percentDivider));
            }else{
                _merchants[_merchantId]._withdrawalAddress.transfer(_amount.sub(_amount.mul(percent).div(_percentDivider)));
            }
            if(_amount.mul(percent).div(_percentDivider) > 0){
                _owner.transfer(_amount.mul(percent).div(_percentDivider));
            }
        }else if(_addressERC20 != address(0)){
            require(existsERC20Address(_merchantId,_addressERC20) == true,"Address not exists");
            uint256 row = rowExistsERC20Address(_merchantId, _addressERC20);
            if(_isOrder == true){
                require( _addressesTokensERC20[_merchantId][row]._status == true,"Address not allowed");
            }
            IERC20 token = IERC20(_addressERC20);
            require(token.balanceOf(msg.sender) >= _amount,"You do not have the required amount");
            uint256 allowance = token.allowance(msg.sender, address(this));
            require(allowance >= _amount, "Check the token allowance");
            if(_merchants[_merchantId]._withdrawalAddress == address(0) || _isOrder == false){
                _addressesTokensERC20[_merchantId][row]._balance += _amount.sub(_amount.mul(percent).div(_percentDivider));
                require(token.transferFrom(msg.sender,address(this),_amount.sub(_amount.mul(percent).div(_percentDivider))),"Error transferFrom");
                _balancesTokens[_addressERC20] += _amount.sub(_amount.mul(percent).div(_percentDivider));
            }else{
                require(token.transferFrom(msg.sender,_merchants[_merchantId]._withdrawalAddress,_amount.sub(_amount.mul(percent).div(_percentDivider))),"Error transferFrom");
            }
            if(_amount.mul(percent).div(_percentDivider) > 0){
                require(token.transferFrom(msg.sender,_owner,_amount.mul(percent).div(_percentDivider)),"Error transferFrom");
            }
        }
        if(_isOrder == true){
            emit topUpEvent(_merchantId,_orderId,_amount,_addressERC20,msg.sender);
        }
    }

    function addMerchant(address payable _withdrawalAddress, address _addressERC20, bool _statusBnb) public returns (Merchant memory){
        _merchants.push(Merchant(payable(msg.sender),_percent,_withdrawalAddress,0,_statusBnb,true));
        if(_addressERC20 != address(0)){
            _addressesTokensERC20[(_merchants.length).sub(1)].push(AddressesERC20(_addressERC20,0,true));
        }
        emit addMerchantEvent((_merchants.length).sub(1), msg.sender, _percent, _withdrawalAddress);
        return _merchants[(_merchants.length).sub(1)];
    }

    function withdrawal(uint256 _merchantId,address _addressERC20,uint256 _amount) public {
        require(msg.sender == _merchants[_merchantId]._owner,"Merchant owner only");
        if(_addressERC20 == address(0)){
            require(_merchants[_merchantId]._balanceBnb >= _amount);
            _merchants[_merchantId]._owner.transfer(_amount);
            _merchants[_merchantId]._balanceBnb -= _amount;
            _balanceBnb -= _amount;
        }else{
            require(existsERC20Address(_merchantId, _addressERC20),"No address");
            require(getBalanceERC20(_merchantId, _addressERC20) >= _amount,"There is no required amount on the account");
            IERC20 token = IERC20(_addressERC20);
            require(token.transfer(msg.sender, _amount),"Transfer error");
            subBalance(_merchantId, _addressERC20, _amount);
        }
        emit withdrawalEvent(_merchantId, _amount, _addressERC20, msg.sender);
    }

    function massPayOut(uint256 _merchantId,MassPayOut[] memory listPayout) public {
        require(msg.sender == _merchants[_merchantId]._owner,"Merchant owner only");
        for(uint256 i;i<listPayout.length;i++){
            if(listPayout[i]._addressERC20 == address(0)){
                if(_merchants[_merchantId]._balanceBnb >= listPayout[i]._amount){
                    _merchants[_merchantId]._owner.transfer(listPayout[i]._amount);
                    _merchants[_merchantId]._balanceBnb -= listPayout[i]._amount;
                    _balanceBnb -= listPayout[i]._amount;
                }
            }else{
                if(existsERC20Address(_merchantId, listPayout[i]._addressERC20)){
                    if(getBalanceERC20(_merchantId, listPayout[i]._addressERC20) >= listPayout[i]._amount){
                        IERC20 token = IERC20(listPayout[i]._addressERC20);
                        token.transfer(msg.sender, listPayout[i]._amount);
                        subBalance(_merchantId, listPayout[i]._addressERC20, listPayout[i]._amount);
                        emit massPayOutEvent(_merchantId, listPayout[i]._orderId, listPayout[i]._amount, listPayout[i]._addressERC20, listPayout[i]._recipient);
                    }
                }
            }
            
        }
    }

    function setWithdrawalAddress(uint256 _merchantId,address payable _withdrawalAddress) public {
        require(_merchants[_merchantId]._status == true,"Merchant is disabled");
        require(msg.sender == _merchants[_merchantId]._owner,"Merchant owner only");
        _merchants[_merchantId]._withdrawalAddress = _withdrawalAddress;
    }

    function setStatusERC20Address(uint256 _merchantId,address _addressERC20,bool _status) public {
        require(_merchants[_merchantId]._status == true,"Merchant is disabled");
        require(msg.sender == _merchants[_merchantId]._owner,"Merchant owner only");
        if(existsERC20Address(_merchantId, _addressERC20) == true){
            _addressesTokensERC20[_merchantId][rowExistsERC20Address(_merchantId, _addressERC20)]._status = _status;
        }else{
            _addressesTokensERC20[_merchantId].push(AddressesERC20(_addressERC20,0,_status));
        }
    }

    function setStatusBnb(uint256 _merchantId,bool _statusBnb) public {
        require(_merchants[_merchantId]._status == true,"Merchant is disabled");
        require(msg.sender == _merchants[_merchantId]._owner,"Merchant owner only");
        _merchants[_merchantId]._statusBnb = _statusBnb;
    }

    function withdrawalAvailableTokenERC20(address _addressERC20) public {
        require(msg.sender == _owner,"Only owner");
        IERC20 token = IERC20(_addressERC20);
        require(token.balanceOf(address(this)) > (_balancesTokens[_addressERC20]),"No funds available");
        require(token.balanceOf(address(this)).sub(_balancesTokens[_addressERC20]) > 0,"No funds available");
        uint256 amount = token.balanceOf(address(this)).sub(_balancesTokens[_addressERC20]);
        token.transfer(msg.sender, amount);
    }

    function withdrawalAvailableBnb() public {
        require(msg.sender == _owner,"Only owner");
        require(address(this).balance.sub(_balanceBnb) > 0);
        _owner.transfer(address(this).balance.sub(_balanceBnb));
    }

    function getPercent() public view returns(uint256){
        return _percent;
    }

    function getPercentDivider() public view returns(uint256){
        return _percentDivider;
    }

    function getContacts() public view returns(string memory){
        return _contacts;
    }

    function getCgtAddress() public view returns(address){
        return _cgtAddress;
    }

    function getCgtAmount() public view returns(uint256){
        return _cgtAmount;
    }

    function getCgtPercent() public view returns(uint256){
        return _cgtPercent;
    }

    function getListMerchantsByOwner(address _addressOwner) public view returns(Merchant[] memory){
        uint256 countItems;
        for(uint256 i; i < _merchants.length; i++){
            if(_merchants[i]._owner == _addressOwner){
                countItems++;
            }
        }
        Merchant[] memory items = new Merchant[](countItems);
        uint256 j = 0;
        for(uint256 i; i < _merchants.length; i++){
            if(_merchants[i]._owner == _addressOwner){
               Merchant memory row = _merchants[i];
               items[j] = row;
               j++;
            }
        }
        return items;
    }

    function getListMerchants() public view returns(Merchant[] memory){
        return _merchants;
    }

    function setPercent(uint256 _x) public {
        require(msg.sender == _owner,"Only owner");
        _percent = _x;
    }

    function setPercentDivider(uint256 _x) public {
        require(msg.sender == _owner,"Only owner");
        _percentDivider = _x;
    }

    function setContacts(string memory _x) public {
        require(msg.sender == _owner,"Only owner");
        _contacts = _x;
    }

    function setOwner(address payable _x) public {
        require(msg.sender == _owner,"Only owner");
        _owner = _x;
    }

    function setCgtAddress(address _x) public {
        require(msg.sender == _owner,"Only owner");
        _cgtAddress = _x;
    }

    function setCgtAmount(uint256 _x) public {
        require(msg.sender == _owner,"Only owner");
        _cgtAmount = _x;
    }

    function setCgtPercent(uint256 _x) public {
        require(msg.sender == _owner,"Only owner");
        _cgtPercent = _x;
    }

    function subBalance(uint256 _merchantId,address _addressERC20,uint256 _amount) private returns(bool){
        uint256 row = rowExistsERC20Address(_merchantId, _addressERC20);
        _addressesTokensERC20[_merchantId][row]._balance -= _amount;
        _balancesTokens[_addressERC20] -= _amount;
        return true;
    }

    function getBalanceERC20(uint256 _merchantId,address _addressERC20) public view returns(uint256){
        require(existsERC20Address(_merchantId, _addressERC20),"No address");
        uint256 row = rowExistsERC20Address(_merchantId, _addressERC20);
        return _addressesTokensERC20[_merchantId][row]._balance;
    }

    function getStatusMerchant(uint256 _merchantId) public view returns(bool){
        return _merchants[_merchantId]._status;
    }

    function getWithdrawalAddress(uint256 _merchantId) public view returns(address){
        return _merchants[_merchantId]._withdrawalAddress;
    }

    function getPercentMerchant(uint256 _merchantId) public view returns(uint256){
        return _merchants[_merchantId]._percent;
    }

    function getListERC20(uint256 _merchantId) public view returns(AddressesERC20[] memory){
        return _addressesTokensERC20[_merchantId];
    }

    function getBalanceBnb(uint256 _merchantId) public view returns(uint256){
        return _merchants[_merchantId]._balanceBnb;
    }

    function getStatusBnb(uint256 _merchantId) public view returns(bool){
        return _merchants[_merchantId]._statusBnb;
    }

    function getStatusERC20Address(uint256 _merchantId,address _addressERC20) public view returns(bool){
        require(existsERC20Address(_merchantId, _addressERC20),"No address");
        uint256 row = rowExistsERC20Address(_merchantId, _addressERC20);
        return _addressesTokensERC20[_merchantId][row]._status;
    }

    function existsERC20Address(uint256 _merchantId, address _addressERC20) public view returns(bool){
        for(uint256 i=0;i<_addressesTokensERC20[_merchantId].length;i++){
            if(_addressesTokensERC20[_merchantId][i]._addressERC20 == _addressERC20){
                return true;
            }
        }
        return false;
    }

    function rowExistsERC20Address(uint256 _merchantId, address _addressERC20) private view returns(uint256){
        require(existsERC20Address(_merchantId, _addressERC20));
        uint256 row;
        for(uint256 i=0;i<_addressesTokensERC20[_merchantId].length;i++){
            if(_addressesTokensERC20[_merchantId][i]._addressERC20 == _addressERC20){
                row = i;
            }
        }
        return row;
    }

    function setStatusMerchant(uint256 _merchantId,bool _status) public {
        require(msg.sender == _owner,"Only owner");
        _merchants[_merchantId]._status = _status;
    }

    function setPercentMerchant(uint256 _merchantId,uint256 _x) public {
        require(msg.sender == _owner,"Only owner");
        _merchants[_merchantId]._percent = _x;
    }
}