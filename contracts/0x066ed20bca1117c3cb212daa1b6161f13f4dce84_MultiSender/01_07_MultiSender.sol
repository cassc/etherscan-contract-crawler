//SPDX-License-Identifier: MIT
pragma solidity ^0.4.0;

import "./Ownable.sol";
import "./StandardToken.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./ERC20Basic.sol";

contract MultiSender is Ownable {
    using SafeMath for uint256;

    event LogTokenMultiSent(address token, uint256 total);
    event LogGetToken(address token, address receiver, uint256 balance);

    address public receiverAddress;
    uint256 public txFee = 0 ether;
    uint256 public VIPFee = 0 ether;

    /* VIP List */
    mapping(address => bool) public vipList;

    /*
     *  get balance
     */
    function getBalance(address _tokenAddress) public onlyOwner {
        address _receiverAddress = address(uint160(getReceiverAddress()));
        if (_tokenAddress == address(0)) {
            _receiverAddress.transfer(address(this).balance);
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
    function registerVIP() public payable {
        require(msg.value >= VIPFee);
        address _receiverAddress = getReceiverAddress();
        require(address(uint160(_receiverAddress)).send(msg.value));
        vipList[msg.sender] = true;
    }

    /*
     *  VIP list
     */
    function addToVIPList(address[] memory _vipList) public onlyOwner {
        for (uint256 i = 0; i < _vipList.length; i++) {
            vipList[_vipList[i]] = true;
        }
    }

    /*
     * Remove address from VIP List by Owner
     */
    function removeFromVIPList(address[] memory _vipList) public onlyOwner {
        for (uint256 i = 0; i < _vipList.length; i++) {
            vipList[_vipList[i]] = false;
        }
    }

    function isVIP(address _address) internal view returns (bool) {
        return vipList[_address];
    }

    /*
     * set receiver address
     */
    function setReceiverAddress(address _addr) public onlyOwner {
        require(_addr != address(0));
        receiverAddress = _addr;
    }

    /*
     * get receiver address
     */
    function getReceiverAddress() public view returns (address) {
        if (receiverAddress == address(0)) {
            return owner;
        }
        return receiverAddress;
    }

    /*
     * set vip fee
     */
    function setVIPFee(uint256 _fee) public onlyOwner {
        VIPFee = _fee;
    }

    /*
     * set tx fee
     */
    function setTxFee(uint256 _fee) public onlyOwner {
        txFee = _fee;
    }

    function ethSendSameValue(address[] memory _to, uint256 _value) internal {
        uint256 sendAmount = _to.length.sub(1).mul(_value);
        uint256 remainingValue = msg.value;
        bool vip = isVIP(msg.sender);
        if (vip) {
            require(remainingValue >= sendAmount);
        } else {
            require(remainingValue >= sendAmount.add(txFee));
        }
        require(_to.length <= 255);

        for (uint8 i = 1; i < _to.length; i++) {
            remainingValue = remainingValue.sub(_value);
            require(address(uint160(_to[i])).send(_value));
        }

        emit LogTokenMultiSent(
            0x000000000000000000000000000000000000bEEF,
            msg.value
        );
    }

    function ethSendDifferentValue(
        address[] memory _to,
        uint256[] memory _value
    ) internal {
        uint256 sendAmount = _value[0];
        uint256 remainingValue = msg.value;
        bool vip = isVIP(msg.sender);
        if (vip) {
            require(remainingValue >= sendAmount);
        } else {
            require(remainingValue >= sendAmount.add(txFee));
        }
        require(_to.length == _value.length);
        require(_to.length <= 255);

        for (uint8 i = 1; i < _to.length; i++) {
            remainingValue = remainingValue.sub(_value[i]);
            require(address(uint160(_to[i])).send(_value[0]));
        }

        emit LogTokenMultiSent(
            0x000000000000000000000000000000000000bEEF,
            msg.value
        );
    }

    function coinSendSameValue(
        address _tokenAddress,
        address[] memory _to,
        uint256 _value
    ) internal {
        uint256 sendValue = msg.value;
        bool vip = isVIP(msg.sender);
        if (!vip) {
            require(sendValue >= txFee);
        }
        require(_to.length <= 255);

        address from = msg.sender;
        uint256 sendAmount = _to.length.sub(1).mul(_value);

        StandardToken token = StandardToken(_tokenAddress);
        for (uint8 i = 1; i < _to.length; i++) {
            token.transferFrom(from, _to[i], _value);
        }

        emit LogTokenMultiSent(_tokenAddress, sendAmount);
    }

    function coinSendDifferentValue(
        address _tokenAddress,
        address[] memory _to,
        uint256[] memory _value
    ) internal {
        uint256 sendValue = msg.value;
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
    Send ether with the same value by an explicit call method
    */
    function sendEth(address[] memory _to, uint256 _value) public payable {
        ethSendSameValue(_to, _value);
    }

    /*
    Send ether with different values by an explicit call method
    */
    function multisend(
        address[] memory _to,
        uint256[] memory _value
    ) public payable {
        ethSendDifferentValue(_to, _value);
    }

    /*
    Send ether with different values by an implicit call method
    */
    function mutiSendETHWithDifferentValue(
        address[] memory _to,
        uint256[] memory _value
    ) public payable {
        ethSendDifferentValue(_to, _value);
    }

    /*
    Send ether with the same value by an implicit call method
    */
    function mutiSendETHWithSameValue(
        address[] memory _to,
        uint256 _value
    ) public payable {
        ethSendSameValue(_to, _value);
    }

    /*
    Send tokens with the same value by an implicit call method
    */
    function mutiSendCoinWithSameValue(
        address _tokenAddress,
        address[] memory _to,
        uint256 _value
    ) public payable {
        coinSendSameValue(_tokenAddress, _to, _value);
    }

    /*
    Send tokens with different values by an implicit call method, this method can save some fee.
    */
    function mutiSendCoinWithDifferentValue(
        address _tokenAddress,
        address[] memory _to,
        uint256[] memory _value
    ) public payable {
        coinSendDifferentValue(_tokenAddress, _to, _value);
    }

    /*
    Send tokens with different values by an explicit call method
    */
    function multisendToken(
        address _tokenAddress,
        address[] memory _to,
        uint256[] memory _value
    ) public payable {
        coinSendDifferentValue(_tokenAddress, _to, _value);
    }

    /*
    Send tokens with the same value by an explicit call method
    */
    function drop(
        address _tokenAddress,
        address[] memory _to,
        uint256 _value
    ) public payable {
        coinSendSameValue(_tokenAddress, _to, _value);
    }
}