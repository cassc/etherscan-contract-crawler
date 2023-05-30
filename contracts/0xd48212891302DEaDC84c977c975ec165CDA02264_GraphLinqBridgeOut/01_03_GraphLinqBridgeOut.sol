//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./libs/SafeMath.sol";

contract GraphLinqBridgeOut {

    event ReceivedBridgedTokens(address _owner, uint256 _amount);
    event ClaimedBridgedTokens(address _owner, uint256 _claimed, uint256 _totalBridged);

    // Use alias imports
    using SafeMath for uint256;

    address private _graphlinqCoin;
    address private _owner;
    mapping (address => uint256) public _bridged;
    mapping (address => uint256) public _totalClaimed;

    constructor(address graphlinqCoin_) {
        _owner = address(msg.sender);
        _graphlinqCoin = graphlinqCoin_;
    }

    function setOneBridged(address owner, uint256 amount) public returns(bool) 
    {
        require(address(msg.sender) == _owner, "unauthorized access");
        
        if (_bridged[owner] != amount) {
            _bridged[owner] = amount;
            emit ReceivedBridgedTokens(owner, amount);
        }
        return true;
    }

    function setMultipleBridged(address[] memory owners, uint256[] memory amounts, uint256 len) public returns(bool)
    {
        require(address(msg.sender) == _owner, "unauthorized access");
        for (uint i = 0; i < len; i++) {
            address owner = owners[i];
            uint256 amount = amounts[i];

            if (_bridged[owner] != amount) {
                _bridged[owner] = amount;
                emit ReceivedBridgedTokens(owner, amount);
            }
        }
        return true;
    }

    function getAddressInfos(address addr) public view returns(uint256, uint256) {
        return (_bridged[addr], _totalClaimed[addr]);
    }

    function getTotalCoinBridged() public view returns(uint256) {
        IERC20 glqToken = IERC20(_graphlinqCoin);
        return glqToken.balanceOf(address(this));
    }

    function withdrawGlq(uint256 amount) public {
        IERC20 glqToken = IERC20(_graphlinqCoin);
        address from = address(this);
        address to = address(msg.sender);

        require(to == _owner, "unauthorized");
        require(glqToken.balanceOf(from) >= amount, "not enough funds");
        require(glqToken.transfer(to, amount), "error on transfer");
    }

    function withdrawBridged() public returns(uint256) {
        IERC20 glqToken = IERC20(_graphlinqCoin);
        address owner = address(msg.sender);
        address from = address(this);
        require(_bridged[owner] != 0, "No GLQ to claim on the bridge!");

        uint256 claimed = _bridged[owner].sub(_totalClaimed[owner]);
        require(claimed > 0, "You already claimed your GLQ, no more are available!");

        _totalClaimed[owner] = _totalClaimed[owner].add(claimed);
        require(glqToken.balanceOf(from) >= claimed, "not enough funds");
        require(glqToken.transfer(owner, claimed), "error on transfer");

        emit ClaimedBridgedTokens(owner, claimed, _bridged[owner]);
        return claimed;
    }

}