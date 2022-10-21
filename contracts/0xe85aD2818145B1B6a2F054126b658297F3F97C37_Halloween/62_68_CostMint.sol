// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/IMintableERC721.sol';
import '../core/SafeOwnable.sol';

contract CostMint is SafeOwnable {
    using SafeERC20 for IERC20;

    event ReceiverChanged(address oldReceiver, address newReceiver);
    event TokenPriceChanged(IERC20 token, uint price, bool avaliable);

    address immutable public WETH;
    IMintableERC721 public immutable nft;
    uint public immutable startAt;
    uint public immutable finishAt;
    uint public immutable maxNum;
    uint public immutable userLimit;

    mapping(IERC20 => bool) supportTokens;
    mapping(IERC20 => uint) tokensPrice;
    address payable public receiver;

    uint public sellNum;
    mapping(address => uint) public buyNum;

    constructor(
        address _WETH, 
        IMintableERC721 _nft, 
        uint _startAt, 
        uint _finishAt, 
        uint _maxNum, 
        uint _userLimit, 
        IERC20[] memory _tokens, 
        uint[] memory _prices, 
        address payable _receiver
    ) {
        require(_WETH != address(0), "illegal WETH");
        WETH = _WETH;
        require(address(_nft) != address(0), "illegal nft");
        nft = _nft;
        require(_startAt > block.timestamp && _finishAt > _startAt, "illegal time");
        startAt = _startAt;
        finishAt = _finishAt;
        require(_userLimit > 0 && _maxNum > _userLimit, "illegal num");
        maxNum = _maxNum;
        userLimit = _userLimit;
        require(_tokens.length == _prices.length && _tokens.length > 0, "illegal length");
        for (uint i = 0; i < _tokens.length; i ++) {
            require(address(_tokens[i]) != address(0) && !supportTokens[_tokens[i]], "illegal token");
            supportTokens[_tokens[i]] = true;
            tokensPrice[_tokens[i]] = _prices[i];
            emit TokenPriceChanged(_tokens[i], _prices[i], true);
        }
        require(_receiver != address(0), "illegal receiver");
        receiver = _receiver;
        emit ReceiverChanged(address(0), _receiver);
    }

    function addSupportToken(IERC20 _token, uint _price) external onlyOwner {
        require(address(_token) != address(0) && !supportTokens[_token], "illegal token");
        supportTokens[_token] = true;
        tokensPrice[_token] = _price;
        emit TokenPriceChanged(_token, _price, true);
    }

    function setSupportToken(IERC20 _token, uint _price) external onlyOwner {
        require(supportTokens[_token], "token not exist");
        tokensPrice[_token] = _price;
        emit TokenPriceChanged(_token, _price, true);
    }

    function delSupportToken(IERC20 _token) external onlyOwner {
        require(supportTokens[_token], "token not exist");
        delete supportTokens[_token];
        delete tokensPrice[_token];
        emit TokenPriceChanged(_token, 0, false);
    }

    function setReceiver(address payable _receiver) external onlyOwner {
        require(_receiver != address(0), "illegal receiver");
        emit ReceiverChanged(receiver, _receiver);
        receiver = _receiver;
    }

    modifier AlreadyBegin() {
        require(block.timestamp >= startAt, "not begin");
        _;
    }

    modifier NotFinish() {
        require(block.timestamp <= finishAt, "already finish");
        _;
    }

    modifier TokenSupport(IERC20 _token) {
        require(supportTokens[_token], "token not support");
        _;
    }

    modifier Enough(uint _num) {
        require(sellNum + _num <= maxNum, "already full");
        require(buyNum[msg.sender] + _num <= userLimit, "already limit");
        _;
    }

    function buy(IERC20 _payToken, uint _num) external payable AlreadyBegin NotFinish TokenSupport(_payToken) Enough(_num) {
        unchecked {
            uint cost = _num * tokensPrice[_payToken];
            if (cost > 0) {
                if (address(_payToken) == WETH) {
                    require(msg.value == cost, "illegal payment");
                    receiver.transfer(msg.value);
                } else {
                    _payToken.safeTransferFrom(msg.sender, receiver, cost);
                }
            }
            nft.mint(msg.sender, _num);
            sellNum += _num;
            buyNum[msg.sender] += _num;
        }
    }
}