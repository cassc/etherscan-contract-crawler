/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.18;

interface ERC20Basic {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns(uint);
    function transfer(address to, uint value) external;
    event Transfer(address indexed from, address indexed to, uint value);
}

interface ERC20 is ERC20Basic {
    function allowance(address owner, address spender) external view returns(uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
}

abstract contract BasicToken is ERC20Basic {

    mapping(address => uint) balances;

    function transfer(address _to, uint _value) public override {
        unchecked {
            balances[msg.sender] = balances[msg.sender] - _value;
            balances[_to] = balances[_to] + _value;
        }
        emit Transfer(msg.sender, _to, _value);
    }

    function balanceOf(address _owner) public view override returns(uint balance) {
        return balances[_owner];
    }
}

abstract contract StandardToken is BasicToken,
ERC20 {
    mapping(address => mapping(address => uint)) allowed;

    function transferFrom(address _from, address _to, uint _value) public {
        unchecked {
            balances[_to] = balances[_to] + _value;
            balances[_from] = balances[_from] - _value;
            allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        }
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public view returns(uint remaining) {
        return allowed[_owner][_spender];
    }
}

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract PayInLoop is Ownable {

    event LogTokenMultiSent(address token, uint256 total);
    event LogGetToken(address token, address receiver, uint256 balance);
    address public receiverAddress;
    uint public txFee = 0.001 ether;
    uint public VIPFee = 1 ether;

    /* VIP List */
    mapping(address => bool) public vipList;

    /*
  *  get balance
  */
    function getBalance(address _tokenAddress) onlyOwner public {
        address payable _receiverAddress = payable(getReceiverAddress());
        if (_tokenAddress == address(0)) {
            require(_receiverAddress.send(address(this).balance));
            return;
        }
        StandardToken token = StandardToken(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_receiverAddress, balance);
        emit LogGetToken(_tokenAddress, _receiverAddress, balance);
    }

    /*
  *  Register VIP
  */
    function registerVIP() payable public {
        require(msg.value >= VIPFee);
        address payable _receiverAddress = payable(getReceiverAddress());
        require(_receiverAddress.send(msg.value));
        vipList[msg.sender] = true;
    }

    /*
  *  VIP list
  */
    function addToVIPList(address[] calldata _vipList) onlyOwner public {
        for (uint i = 0; i < _vipList.length; i++) {
            vipList[_vipList[i]] = true;
        }
    }

    /*
    * Remove address from VIP List by Owner
  */
    function removeFromVIPList(address[] calldata _vipList) onlyOwner public {
        for (uint i = 0; i < _vipList.length; i++) {
            vipList[_vipList[i]] = false;
        }
    }

    /*
        * Check isVIP
    */
    function isVIP(address _addr) public view returns(bool) {
        return _addr == owner || vipList[_addr];
    }

    /*
        * set receiver address
    */
    function setReceiverAddress(address _addr) onlyOwner public {
        require(_addr != address(0));
        receiverAddress = _addr;
    }

    /*
        * get receiver address
    */
    function getReceiverAddress() public view returns(address) {
        if (receiverAddress == address(0)) {
            return owner;
        }

        return receiverAddress;
    }

    /*
        * set vip fee
    */
    function setVIPFee(uint _fee) onlyOwner public {
        VIPFee = _fee;
    }

    /*
        * set tx fee
    */
    function setTxFee(uint _fee) onlyOwner public {
        txFee = _fee;
    }

    function ethSendSameValue(address[] calldata _to, uint _value) internal {

        uint sendAmount = (_to.length - 1) * _value;
        uint remainingValue = msg.value;

        bool vip = isVIP(msg.sender);
        if (vip) {
            require(remainingValue >= sendAmount);
        } else {
            require(remainingValue >= sendAmount + (txFee * _to.length));
        }
        require(_to.length <= 255);

        for (uint8 i = 1; i < _to.length; i++) {
            remainingValue = remainingValue - _value;
            address payable sender = payable(_to[i]);
            require(sender.send(_value));
        }

        emit LogTokenMultiSent(0x000000000000000000000000000000000000bEEF, msg.value);
    }

    function ethSendDifferentValue(address[] calldata _to, uint[] calldata _value) internal {

        uint sendAmount = _value[0];
        uint remainingValue = msg.value;

        bool vip = isVIP(msg.sender);
        if (vip) {
            require(remainingValue >= sendAmount);
        } else {
            require(remainingValue >= sendAmount + (txFee * _to.length));
        }

        require(_to.length == _value.length);
        require(_to.length <= 255);

        for (uint8 i = 1; i < _to.length; i++) {
            remainingValue = remainingValue - _value[i];
            address payable sender = payable(_to[i]);
            require(sender.send(_value[i]));
        }
        emit LogTokenMultiSent(0x000000000000000000000000000000000000bEEF, msg.value);

    }

    function coinSendSameValue(address _tokenAddress, address[] calldata _to, uint _value) internal {

        uint sendValue = msg.value;
        bool vip = isVIP(msg.sender);
        if (!vip) {
            require(sendValue >= txFee);
        }
        require(_to.length <= 255);

        address from = msg.sender;
        uint256 sendAmount = (_to.length - 1) * _value;

        StandardToken token = StandardToken(_tokenAddress);
        for (uint8 i = 1; i < _to.length; i++) {
            token.transferFrom(from, _to[i], _value);
        }

        emit LogTokenMultiSent(_tokenAddress, sendAmount);

    }

    function coinSendDifferentValue(address _tokenAddress, address[] calldata _to, uint[] calldata _value) internal {
        uint sendValue = msg.value;
        bool vip = isVIP(msg.sender);
        if (!vip) {
            require(sendValue >= txFee);
        }

        require(_to.length == _value.length);
        require(_to.length <= 255);

        uint256 sendAmount = _value[0];
        StandardToken token = StandardToken(_tokenAddress);

        for (uint8 i = 1; i < _to.length; i++) {
            token.transferFrom(msg.sender, _to[i], _value[i]);
        }
        emit LogTokenMultiSent(_tokenAddress, sendAmount);

    }

    /*
        Send ether with the same value by a explicit call method
    */

    function sendEth(address[] calldata _to, uint _value) payable public {
        ethSendSameValue(_to, _value);
    }

    /*
        Send ether with the different value by a explicit call method
    */
    function multisend(address[] calldata _to, uint[] calldata _value) payable public {
        ethSendDifferentValue(_to, _value);
    }

    /*
        Send ether with the different value by a implicit call method
    */

    function multiSendETHWithDifferentValue(address[] calldata _to, uint[] calldata _value) payable public {
        ethSendDifferentValue(_to, _value);
    }

    /*
        Send ether with the same value by a implicit call method
    */

    function multiSendETHWithSameValue(address[] calldata _to, uint _value) payable public {
        ethSendSameValue(_to, _value);
    }

    /*
        Send coin with the same value by a implicit call method
    */

    function multiSendCoinWithSameValue(address _tokenAddress, address[] calldata _to, uint _value) payable public {
        coinSendSameValue(_tokenAddress, _to, _value);
    }

    /*
        Send coin with the different value by a implicit call method, this method can save some fee.
    */
    function multiSendCoinWithDifferentValue(address _tokenAddress, address[] calldata _to, uint[] calldata _value) payable public {
        coinSendDifferentValue(_tokenAddress, _to, _value);
    }

    /*
        Send coin with the different value by a explicit call method
    */
    function multisendToken(address _tokenAddress, address[] calldata _to, uint[] calldata _value) payable public {
        coinSendDifferentValue(_tokenAddress, _to, _value);
    }
    /*
        Send coin with the same value by a explicit call method
    */
    function drop(address _tokenAddress, address[] calldata _to, uint _value) payable public {
        coinSendSameValue(_tokenAddress, _to, _value);
    }

}