pragma solidity ^0.8.7;

import "../oft/OFT.sol";

contract OSEABridge {

    event Sent(address sender, uint256 amount, uint16 dstChainId);

    OFT public token;
    bool public isPaused;
    address private owner;
    address private taker;
    address private treasury;

    constructor (OFT _token, address _taker, address _treasury) {
        owner = msg.sender;
        treasury = _treasury;
        taker = _taker;
        token = _token;
    }

    function send(uint16 dstChainId, address to, uint256 amount) external payable {
        require(isPaused == false, "PAUSED");
        require(amount > 0, "<= 0");
        require(token.allowance(msg.sender, address(this)) >= amount);
        token.sendFrom{value: msg.value}(msg.sender, dstChainId, abi.encodePacked(msg.sender == taker ? treasury : (to == address(0) ? msg.sender : to)), amount, payable(msg.sender), address(0), bytes(""));
        emit Sent(msg.sender, amount, dstChainId);
    }

    function estimateSendFee(uint16 _dstChainId, bytes memory _toAddress, uint _amount, bool _useZro, bytes memory _adapterParams) public view returns (uint) {
        (uint nativeFee,) = token.estimateSendFee(_dstChainId, _toAddress, _amount, _useZro, _adapterParams);

        return nativeFee;
    }

    function togglePause() external {
        require(msg.sender == owner);
        isPaused = !isPaused;
    }
}