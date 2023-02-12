//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./uniswap_interface.sol";

contract equalize_coin {
    address public owner;
    address public routerAddr = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public factoryAddr = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    uint24[] public arrPoolFee = [100, 200, 500, 3000, 10000];

    address[] public arr_token_address = [0x4Fabb145d64652a948d72533023f6E7A623C7C53, 0xdAC17F958D2ee523a2206206994597C13D831ec7, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd];
    address[] public arr_pool_token_address = [0x4Fabb145d64652a948d72533023f6E7A623C7C53, 0xdAC17F958D2ee523a2206206994597C13D831ec7, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2];

    event errors(string);
    event success_trans(string);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    //----------------------------------------------------------------------
    function swap(uint _slippage, bool _multihop, uint _inaccuracy, uint _limitCurrency, uint _timedead) public {
        uint[] memory _arr = get_balance();
        uint _mean = mean_fun(_arr);

        for (uint8 i = 0; i < _arr.length; i++) {
            if (_arr[i] > _mean + _inaccuracy) {

                for (uint8 j = 0; j < _arr.length; j++) {
                    if ((_arr[j] + _inaccuracy < _mean) && (_arr[j] != 0) && (i != j)) {
                        if (_arr[i] - _mean >= _mean - _arr[j]) {
                            if ( _mean - _arr[j] <= _limitCurrency) {
                                send_transaction(i, j, _mean - _arr[j], _slippage, _multihop, _timedead);
                                _arr[j] = 0;
                            } else {
                                send_transaction(i, j, _limitCurrency, _slippage, _multihop, _timedead);
                                _arr[i] = 0;
                            }
                        } else {
                            if ( _arr[i] - _mean <= _limitCurrency) {
                                _arr[j] += _arr[i] - _mean;
                                send_transaction(i, j, _arr[i] - _mean, _slippage, _multihop, _timedead);
                            } else {
                                _arr[j] += _limitCurrency;
                                send_transaction(i, j, _limitCurrency, _slippage, _multihop, _timedead);
                            }
                            _arr[i] = 0;
                            break;
                        }
                        emit errors(string(abi.encodePacked(string("transaction send: "), i, string(" - "), j)));
                    }
                }
            }
        }
    }

    //------------------------------------------------------------------
    function get_balance() public returns (uint[] memory _arr) {
        uint _len = arr_token_address.length;
        _arr = new uint[](_len);
        for (uint i=0; i < arr_token_address.length; i++) {
            if (IERC20(arr_token_address[i]).balanceOf(msg.sender) != 0) {
                _arr[i] = IERC20(arr_token_address[i]).balanceOf(msg.sender) / 10 ** (IERC20(arr_token_address[i]).decimals() - 2);
            } else {
                _arr[i] = 0;
            }
        }
    }

    function mean_fun(uint[] memory _arr) public pure returns (uint) {
        uint _sum = 0;
        for (uint i = 0; i < _arr.length; i++) {
            _sum = _sum + _arr[i];
        }
        return _sum / _arr.length;
    }

    function get_poolFee(address _coin_a, address _coin_b) public view returns(uint24) {
        IUniswapV3Factory factory = IUniswapV3Factory(factoryAddr);
        for (uint8 i; i < arrPoolFee.length; i++) {
            if (factory.getPool(_coin_a, _coin_b, arrPoolFee[i]) != address(0)) {
                return arrPoolFee[i];
            }
        }
        return 0;
    }

    function getMultiPool(address _coin_a, address _coin_b) public view returns(bytes memory) {
        for (uint8 i; i < arr_pool_token_address.length; i++) {
            if (arr_pool_token_address[i] != _coin_a && arr_pool_token_address[i] != _coin_b) {
                uint24 _poolFeeA = get_poolFee(_coin_a, arr_pool_token_address[i]);
                uint24 _poolFeeB = get_poolFee(_coin_b, arr_pool_token_address[i]);
                if (_poolFeeA != 0 && _poolFeeB != 0) {
                    return abi.encodePacked(_coin_a, _poolFeeA, arr_pool_token_address[i], _poolFeeB, _coin_b);
                }
            }
        }
        uint24 a = 0;
        return abi.encodePacked(a);
    }

    function send_transaction(uint8 _coin_in, uint8 _coin_out, uint _amount, uint _slippage, bool _multihop, uint _timedead) public {
        if (get_poolFee(arr_token_address[_coin_in], arr_token_address[_coin_out]) != 0) {         
            send_transaction_single(_coin_in, _coin_out, _amount, _slippage, _timedead);
        } else {
            if (_multihop == true) {
                bytes memory _path = getMultiPool(arr_token_address[_coin_in], arr_token_address[_coin_out]);
                uint24 a = 0;
                if (keccak256(_path) != keccak256(abi.encodePacked(a))) {
                    send_transaction_multi(_coin_in, _coin_out, _amount, _slippage, _path, _timedead);
                } else {
                    emit errors(string(abi.encodePacked(string("three is no liquidity. Swap faild: "), _coin_in, string(" - "), _coin_out, string(" => "), _amount / 100, string("."), _amount % 100)));
                }
            } else {
                emit errors(string(abi.encodePacked(string("turn on Multihop and maybe swap will complete. Swap faild: "), _coin_in, string(" - "), _coin_out, string(" => "), _amount / 100, string("."), _amount % 100)));
            }
        }
    }

    function send_transaction_single(uint8 _coin_in, uint8 _coin_out, uint _amount, uint _slippage, uint _timedead) public {    
        ISwapRouter router = ISwapRouter(routerAddr);
        IERC20(arr_token_address[_coin_in]).transferFrom(msg.sender, address(this), _amount * 10 ** (IERC20(arr_token_address[_coin_in]).decimals() - 2));

        uint _amountOutMinimum;
        if (_amount <= _slippage) {
            _amountOutMinimum = 1;
        } else {
            _amountOutMinimum = (_amount - _slippage) * 10 ** (IERC20(arr_token_address[_coin_out]).decimals() - 2);
        }

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: arr_token_address[_coin_in],
                tokenOut: arr_token_address[_coin_out],
                fee: get_poolFee(arr_token_address[_coin_in], arr_token_address[_coin_out]),
                recipient: msg.sender,
                deadline: block.timestamp + _timedead,
                amountIn: _amount * 10 ** (IERC20(arr_token_address[_coin_in]).decimals() - 2),
                amountOutMinimum: _amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        router.exactInputSingle(params); 
    }

    function send_transaction_multi(uint8 _coin_in, uint8 _coin_out, uint _amount, uint _slippage, bytes memory _path, uint _timedead) public {
        ISwapRouter router = ISwapRouter(routerAddr);
        IERC20(arr_token_address[_coin_in]).transferFrom(msg.sender, address(this), _amount * 10 ** (IERC20(arr_token_address[_coin_in]).decimals() - 2));

        uint _amountOutMinimum;
        if (_amount <= _slippage) {
            _amountOutMinimum = 1;
        } else {
            _amountOutMinimum = (_amount - _slippage) * 10 ** (IERC20(arr_token_address[_coin_out]).decimals() - 2);
        }

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: _path,
                recipient: msg.sender,
                deadline: block.timestamp + _timedead,
                amountIn: _amount * 10 ** (IERC20(arr_token_address[_coin_in]).decimals() - 2),
                amountOutMinimum: _amountOutMinimum
            });
        router.exactInput(params);
    }

    //-----------------------------------------------------------------
    function approve_token() public onlyOwner {
        for (uint8 i; i < arr_token_address.length; i++) {
            if (IERC20(arr_token_address[i]).allowance(address(this), routerAddr) < 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                IERC20(arr_token_address[i]).approve(routerAddr, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            }
        }
    }

    function setTokenAddr(address[] memory _arr_token_address) public onlyOwner {
        arr_token_address = _arr_token_address;
    }

    function setPoolTokenAddr(address[] memory _arr_pool_token_address) public onlyOwner {
        arr_pool_token_address = _arr_pool_token_address;
    }

    function setISwapRouter(address _routerAddr) public onlyOwner {
        routerAddr = _routerAddr;
    }

    function setISwapFactiry(address _factoryAddr) public onlyOwner {
        factoryAddr = _factoryAddr;
    }

    function setPoolFee(uint24[] memory _arrPoolFee) public onlyOwner {
        arrPoolFee = _arrPoolFee;
    }

    function setNewOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
}