// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../interfaces/IMintableERC721.sol';

contract Minter {
    using SafeERC20 for IERC20;
    
    struct PriceInfo {
        IERC20 token;
        uint price;
    }

    address immutable public WETH;
    IERC20[] supportTokens;
    mapping(IERC20 => PriceInfo) tokensPrice;
    uint public immutable startAt;
    uint public immutable finishAt;
    uint public immutable maxNum;
    uint public sellNum;
    address payable public immutable receiver;
    IMintableERC721 public immutable nft;

    constructor(address _WETH, IERC20[] memory _tokens, uint[] memory _prices, uint _startAt, uint _finishAt, uint _maxNum, address payable _receiver, IMintableERC721 _nft) {
        require(_WETH != address(0), "illegal WETH");
        WETH = _WETH;
        require(_tokens.length == _prices.length && _tokens.length > 0, "illegal length");
        for (uint i = 0; i < _tokens.length; i ++) {
            require(address(_tokens[i]) != address(0) && _prices[i] != 0, "illegal token or price");
            require(address(tokensPrice[_tokens[i]].token) == address(0), "token already exist");
            tokensPrice[_tokens[i]] = PriceInfo({
                token: _tokens[i],
                price: _prices[i]
            });
            supportTokens.push(_tokens[i]);
        }
        require(_startAt > block.timestamp && _finishAt > _startAt, "illegal time");
        startAt = _startAt;
        finishAt = _finishAt;
        require(_maxNum > 0, "illegal maxNum");
        maxNum = _maxNum;
        require(_receiver != address(0), "illegal receiver");
        receiver = _receiver;
        require(address(_nft) != address(0), "illegal nft");
        nft = _nft;
    }

    function getPrices() external view returns (PriceInfo[] memory prices) {
        prices = new PriceInfo[](supportTokens.length);
        for (uint i = 0; i < supportTokens.length; i ++) {
            prices[i] = tokensPrice[supportTokens[i]];
        }
    }

    modifier AlreadyBegin() {
        require(block.timestamp >= startAt, "not begin");
        _;
    }

    modifier TokenSupport(IERC20 _token) {
        require(tokensPrice[_token].token == _token, "token not support");
        _;
    }
    
    modifier NotFinish(uint num) {
        require(block.timestamp <= finishAt && sellNum + num <= maxNum, "already finish");
        _;
    }

    function mint(address _to, uint _num, IERC20 _payToken) external payable AlreadyBegin TokenSupport(_payToken) NotFinish(_num) {
        uint cost = _num * tokensPrice[_payToken].price;
        if (address(_payToken) == WETH) {
            require(msg.value == cost, "illegal payment");
            receiver.transfer(msg.value);
        } else {
            _payToken.safeTransferFrom(msg.sender, receiver, cost);
        }
        sellNum += _num;
        nft.mint(_to, _num);
    }
}