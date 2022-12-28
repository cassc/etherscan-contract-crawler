// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IMarketFeeDispatcher.sol";
import "../interfaces/IBabyRouter.sol";
import "./MarketFeeDispatcher.sol";
import "../interfaces/IWETH.sol";
import "../token/VBabyToken.sol";

contract MarketFeeManager is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    uint constant public PERCENT_RATIO = 1e6;
    IBabyRouter immutable public router;

    bytes32 public INIT_CODE_HASH = keccak256(type(MarketFeeDispatcher).creationCode);

    IERC20[] public tokens;
    mapping(address => IMarketFeeDispatcher) public dispatchers;
    IMarketFeeDispatcher[] public dispatcherList;
    mapping(IMarketFeeDispatcher => bool) public dispatcherBlacklist;
    mapping(address => uint) public receiverPercent;
    mapping(address => IERC20) public receiverToken;
    address[] public receivers;
    address public ownerReceiver;
    IWETH public WETH;
    mapping(address => bool) public callers;

    function addCaller(address _caller) external onlyOwner {
        callers[_caller] = true;
    }

    function delCaller(address _caller) external onlyOwner {
        delete callers[_caller];
    }

    modifier onlyOwnerOrCaller() {
        require(msg.sender == owner() || callers[msg.sender], "illegal operator");
        _;
    }
    
    function addToken(IERC20 _token) external onlyOwner {
        tokens.push(_token);
    }

    function delToken(IERC20 _token) external onlyOwner {
        require(tokens.length > 0, "illegal token");
        uint index = 0;
        for (; index < tokens.length; index ++) {
            if (tokens[index] == _token) {
                break;
            }
        }
        require(index < tokens.length, "token not exists");
        if (index < tokens.length - 1) {
            tokens[index] = tokens[tokens.length - 1];
        }
        tokens.pop();
    }

    function tokenLength() external view returns (uint) {
        return tokens.length;
    }

    function addDispatcherBlacklist(address _receiver) external onlyOwner {
        require(address(dispatchers[_receiver]) != address(0), "not exist");
        IMarketFeeDispatcher dispatcher = dispatchers[_receiver];
        require(!dispatcherBlacklist[dispatcher], "already in blacklist");
        dispatcherBlacklist[dispatcher] = true;
    }

    function delDispatcherBlacklist(address _receiver) external onlyOwner {
        require(address(dispatchers[_receiver]) != address(0), "not exist");
        IMarketFeeDispatcher dispatcher = dispatchers[_receiver];
        require(dispatcherBlacklist[dispatcher], "not in blacklist");
        delete dispatcherBlacklist[dispatcher];
    }

    function addReceiver(address _receiver, uint _percent, IERC20 _receiverToken) external onlyOwner {
        require(_receiver != address(0), "illegal receiver");
        require(receiverPercent[_receiver] == 0, "receiver already exists");
        require(_percent > 0, "illegal percent");
        receivers.push(_receiver);
        uint totalPercent = 0;
        for (uint i = 0; i < receivers.length; i ++) {
            totalPercent = totalPercent.add(receiverPercent[receivers[i]]);
        }
        receiverPercent[_receiver] = _percent;
        receiverToken[_receiver] = _receiverToken;
        require(totalPercent <= PERCENT_RATIO, "illegal percent");
    }

    function delReceiver(address _receiver) external onlyOwner {
        require(receiverPercent[_receiver] != 0, "receiver not exists");
        uint index = 0;
        for ( ; index < receivers.length; index ++) {
            if (receivers[index] == _receiver) {
                break;
            }
        }
        require(index < receivers.length, "receiver not exists");
        if (index < receivers.length - 1) {
            receivers[index] = receivers[receivers.length - 1];
        }
        receivers.pop();
        delete receiverPercent[_receiver];
        delete receiverToken[_receiver];
    }
    
    function receiverLength() external view returns (uint) {
        return receivers.length;
    }

    function setOwnerReceiver(address _receiver) external onlyOwner {
        ownerReceiver = _receiver;
    }

    constructor(IWETH _WETH, IBabyRouter _router, address _ownerReceiver, IERC20[] memory _tokens) {
        WETH = _WETH;
        router = _router;
        require(_ownerReceiver != address(0), "illegal receiver address");
        ownerReceiver = _ownerReceiver;
        tokens = _tokens;
    }

    function createDispatcher(address _receiver, uint _percent) external onlyOwner {
        require(address(dispatchers[_receiver]) == address(0), "already created");
        bytes memory bytecode = type(MarketFeeDispatcher).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_receiver));
        address dispatcher;
        assembly {
            dispatcher := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(dispatcher != address(0), "create2 failed");
        IMarketFeeDispatcher(dispatcher).initialize(address(this), WETH, _receiver, _percent);
        IMarketFeeDispatcher(dispatcher).transferOwnership(owner());
        dispatchers[_receiver] = IMarketFeeDispatcher(dispatcher);
        dispatcherList.push(IMarketFeeDispatcher(dispatcher));
    }

    function expectDispatcher(address _receiver) external view returns (address dispatcher) {
         dispatcher = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                keccak256(abi.encodePacked(_receiver)),
                INIT_CODE_HASH
            ))));
    }

    function getBalance(IERC20 _token) internal returns(uint) {
        if (address(_token) == address(WETH)) {
            uint balance = _token.balanceOf(address(this));
            WETH.withdraw(balance);
            return address(this).balance;
        } else {
            return _token.balanceOf(address(this));
        }
         
    }

    function transfer(IERC20 _token, address _to, uint _amount) internal {
        if (address(_token) == address(WETH)) {
            _to.call{value:_amount}(new bytes(0));
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }

    function swapAndSend(IERC20 _token, IERC20 _receiveToken, address _to, uint _amount) internal {
        if (address(_receiveToken) == address(0)) {
            _receiveToken = _token;
        }
        if (_token == _receiveToken) {
            transfer(_token, _to, _amount);
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(_token); path[1] = address(_receiveToken);
        if (address(_token) == address(WETH)) {
            router.swapExactETHForTokens{value: _amount}(
                0,
                path,
                _to,
                block.timestamp
            );
        } else if (address(_receiveToken) == address(WETH)) {
            _token.approve(address(router), _amount);
            router.swapExactTokensForETH(
                _amount,
                0,
                path,
                _to,
                block.timestamp
            );
        } else {
            _token.approve(address(router), _amount);
            router.swapExactTokensForTokens(
                _amount,
                0,
                path,
                _to,
                block.timestamp
            );
        }
    }

    function dispatch(address _receiver) external onlyOwnerOrCaller {
        IMarketFeeDispatcher dispatcher = dispatchers[_receiver];
        for (uint i = 0; i < tokens.length; i ++) {
            IERC20 token = tokens[i];
            uint balance = getBalance(token);
            for (uint j = 0; j < receivers.length; j ++) {
                address receiver = receivers[j]; 
                uint sendAmount = balance.mul(receiverPercent[receiver]).div(PERCENT_RATIO);
                if (sendAmount > 0) {
                    swapAndSend(token, receiverToken[receiver], receiver, sendAmount);
                }
            }
        }
    }

    function dispatchAll() external onlyOwnerOrCaller {
        for (uint i = 0; i < dispatcherList.length; i ++) {
            IMarketFeeDispatcher dispatcher = dispatcherList[i];
            if (dispatcherBlacklist[dispatcher]) {
                continue;
            }
            dispatcher.dispatch(tokens);
        }
        for (uint i = 0; i < tokens.length; i ++) {
            IERC20 token = tokens[i];
            uint balance = getBalance(token);
            for (uint j = 0; j < receivers.length; j ++) {
                address receiver = receivers[j]; 
                uint sendAmount = balance.mul(receiverPercent[receiver]).div(PERCENT_RATIO);
                if (sendAmount > 0) {
                    swapAndSend(token, receiverToken[receiver], receiver, sendAmount);
                }
            }
        }
    }

    function withdraw(address _receiver) external onlyOwner {
        IMarketFeeDispatcher dispatcher = dispatchers[_receiver];
        require(address(dispatcher) != address(0), "illegal receiver");
        dispatcher.withdraw(tokens);
        for (uint i = 0; i < tokens.length; i ++) {
            IERC20 token = tokens[i];
            uint balance = getBalance(token);
            if (balance > 0) {
                transfer(token, ownerReceiver, balance);
            }
        }
    }

    function withdrawAll() external onlyOwner {
        for (uint i = 0; i < dispatcherList.length; i ++) {
            IMarketFeeDispatcher dispatcher = dispatcherList[i];
            dispatcher.withdraw(tokens);
        }
        for (uint i = 0; i < tokens.length; i ++) {
            IERC20 token = tokens[i];
            uint balance = getBalance(token);
            if (balance > 0) {
                transfer(token, ownerReceiver, balance);
            }
        }
    }

    function setPercent(address _user, uint _percent) external onlyOwner {
        require(address(dispatchers[_user]) != address(0), "_user not exist");
        dispatchers[_user].setPercent(_percent);
    }

    receive () external payable {}
}