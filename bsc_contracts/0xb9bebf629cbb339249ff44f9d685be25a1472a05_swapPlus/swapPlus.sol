/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }


    // struct Bytes32Set {
    //     Set _inner;
    // }

    // function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    //     return _add(set._inner, value);
    // }

    // function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    //     return _remove(set._inner, value);
    // }

    // function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
    //     return _contains(set._inner, value);
    // }

    // function length(Bytes32Set storage set) internal view returns (uint256) {
    //     return _length(set._inner);
    // }

    // function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
    //     return _at(set._inner, index);
    // }

    // function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
    //     return _values(set._inner);
    // }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // struct UintSet {
    //     Set _inner;
    // }

    // function add(UintSet storage set, uint256 value) internal returns (bool) {
    //     return _add(set._inner, bytes32(value));
    // }

    // function remove(UintSet storage set, uint256 value) internal returns (bool) {
    //     return _remove(set._inner, bytes32(value));
    // }

    // function contains(UintSet storage set, uint256 value) internal view returns (bool) {
    //     return _contains(set._inner, bytes32(value));
    // }

    // function length(UintSet storage set) internal view returns (uint256) {
    //     return _length(set._inner);
    // }

    // function at(UintSet storage set, uint256 index) internal view returns (uint256) {
    //     return uint256(_at(set._inner, index));
    // }

    // function values(UintSet storage set) internal view returns (uint256[] memory) {
    //     bytes32[] memory store = _values(set._inner);
    //     uint256[] memory result;
    //     assembly {
    //         result := store
    //     }
    //     return result;
    // }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "k002");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "k003");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "s1");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "s2");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "s3");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "s4");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "s5");
        return a % b;
    }
}

interface Ifactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface Irouter {
    function factory() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface Ipair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

contract swapPlus is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    enum setType {factorySet, routerSet}
    enum getPairType {getPair, pairFor}
    EnumerableSet.AddressSet private factorySet;
    EnumerableSet.AddressSet private routerSet;
    getPairType public PairType = getPairType.getPair;
    uint256 public zero = 0;
    bytes public empty = new bytes(0);
    address public WETH;
    mapping(Ifactory => bytes32) public init_code_hash_list;
    mapping(Irouter => Ifactory) public routerTofactoryList;
    mapping(Irouter => string) public routerNameList;


    struct routerItem {
        Irouter _router;
        Ifactory _factory;
        bytes32 _init_code_hash;
        string _routerName;
    }

    struct swapItem {
        address input;
        address output;
        address token0;
        address to;
        address[] path_;
        Ipair pair;
        uint256 amountInput;
        uint256 amountOutput;
        uint256 reserve0;
        uint256 reserve1;
        uint256 reserveInput;
        uint256 reserveOutput;
        uint256 amount0Out;
        uint256 amount1Out;
    }

    struct swapItem2 {
        address _swapOutToken;
        address _to;
        uint256 balanceBefore;
        uint256 balanceAfter;
        uint256 amountOut;
    }

    constructor (address _WETH) {
        WETH = _WETH;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "swapPlus: EXPIRED");
        _;
    }

    function setETH(address _WETH) external onlyOwner {
        WETH = _WETH;
    }

    function setPairType(getPairType _type) external {
        PairType = _type;
    }

    function setRouterTofactoryList(string memory _routerName, Irouter _routerAddress, Ifactory _factory, bytes32 _init_code_hash) external onlyOwner {
        routerTofactoryList[_routerAddress] = _factory;
        routerNameList[_routerAddress] = _routerName;
        if (!factorySet.contains(address(_factory))) {
            factorySet.add(address(_factory));
        }
        if (!routerSet.contains(address(_routerAddress))) {
            routerSet.add(address(_routerAddress));
        }
        init_code_hash_list[_factory] = _init_code_hash;
    }

    function getRouterItemList() public view returns (routerItem[] memory _list) {
        address[] memory _routerList = routerSet.values();
        uint256 _num = routerSet.length();
        _list = new routerItem[](_num);
        for (uint256 i = 0; i < _num; i++) {
            Irouter _router = Irouter(_routerList[i]);
            _list[i] = routerItem({
            _router : _router,
            _factory : routerTofactoryList[_router],
            _init_code_hash : init_code_hash_list[routerTofactoryList[_router]],
            _routerName : routerNameList[_router]
            });
        }
    }

    function getSet(setType _type) public view returns (address[] memory _list) {
        if (_type == setType.factorySet) {
            _list = factorySet.values();
        }
        if (_type == setType.routerSet) {
            _list = routerSet.values();
        }
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "swapPlus: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "swapPlus: ZERO_ADDRESS");
    }

    function pairFor(Ifactory factory, address tokenA, address tokenB) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex"ff",
                address(factory),
                keccak256(abi.encodePacked(token0, token1)),
                init_code_hash_list[factory]
            )))));
    }

    function checkRouter(Irouter _routerAddress) private view returns (Ifactory _factory) {
        require(routerSet.contains(address(_routerAddress)), "swapPlus: IDENTICAL_ROUTER_ADDRESS");
        require(address(routerTofactoryList[_routerAddress]) != address(0), "swapPlus: IDENTICAL_FACTORY_ADDRESS");
        _factory = routerTofactoryList[_routerAddress];
    }
    /*
   以下为单DEX兑换功能
   */

    function _swapSupportingFeeOnTransferTokens1(
        Irouter _routerAddress,
        Ifactory _factory,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            swapItem memory x = new swapItem[](1)[0];
            (x.input, x.output) = (path[i], path[i + 1]);
            (x.token0,) = sortTokens(x.input, x.output);
            x.pair = Ipair(pairFor(_factory, x.input, x.output));
            (x.reserve0, x.reserve1,) = x.pair.getReserves();
            (x.reserveInput, x.reserveOutput) = x.input == x.token0 ? (x.reserve0, x.reserve1) : (x.reserve1, x.reserve0);
            x.amountInput = IERC20(x.input).balanceOf(address(x.pair)).sub(x.reserveInput);
            //这一行不能少
            x.path_ = new address[](2);
            x.path_[0] = x.input;
            x.path_[1] = x.output;
            x.amountOutput = (_routerAddress.getAmountsOut(x.amountInput, x.path_))[1];
            (x.amount0Out, x.amount1Out) = x.input == x.token0 ? (zero, x.amountOutput) : (x.amountOutput, zero);
            x.to = i < path.length - 2 ? pairFor(_factory, path[i + 1], path[i + 2]) : _to;
            x.pair.swap(x.amount0Out, x.amount1Out, x.to, empty);
        }
    }

    function _swapSupportingFeeOnTransferTokens2(
        Irouter _routerAddress,
        Ifactory _factory,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            swapItem memory x = new swapItem[](1)[0];
            (x.input, x.output) = (path[i], path[i + 1]);
            (x.token0,) = sortTokens(x.input, x.output);
            x.pair = Ipair(_factory.getPair(x.input, x.output));
            (x.reserve0, x.reserve1,) = x.pair.getReserves();
            (x.reserveInput, x.reserveOutput) = x.input == x.token0 ? (x.reserve0, x.reserve1) : (x.reserve1, x.reserve0);
            x.amountInput = IERC20(x.input).balanceOf(address(x.pair)).sub(x.reserveInput);
            //这一行不能少
            x.path_ = new address[](2);
            x.path_[0] = x.input;
            x.path_[1] = x.output;
            x.amountOutput = (_routerAddress.getAmountsOut(x.amountInput, x.path_))[1];
            (x.amount0Out, x.amount1Out) = x.input == x.token0 ? (zero, x.amountOutput) : (x.amountOutput, zero);
            x.to = i < path.length - 2 ? _factory.getPair(path[i + 1], path[i + 2]) : _to;
            x.pair.swap(x.amount0Out, x.amount1Out, x.to, empty);
        }
    }

    function _swapSupportingFeeOnTransferTokens(Irouter _routerAddress, Ifactory _factory, address[] memory path, address _to) private {
        if (PairType == getPairType.getPair) {
            _swapSupportingFeeOnTransferTokens2(_routerAddress, _factory, path, _to);
        }
        if (PairType == getPairType.pairFor) {
            _swapSupportingFeeOnTransferTokens1(_routerAddress, _factory, path, _to);
        }
    }

    function _swapForSingleDex(
        Irouter _routerAddress,
        Ifactory _factory,
        address[] calldata path,
        uint256 amountOutMin,
        address to
    ) private {
        swapItem2 memory y = new swapItem2[](1)[0];
        y._swapOutToken = path[path.length - 1];
        y._to = y._swapOutToken == WETH ? address(this) : to;
        y.balanceBefore = IERC20(y._swapOutToken).balanceOf(y._to);
        _swapSupportingFeeOnTransferTokens(_routerAddress, _factory, path, y._to);
        y.balanceAfter = IERC20(y._swapOutToken).balanceOf(y._to);
        y.amountOut = y.balanceAfter.sub(y.balanceBefore);
        require(y.amountOut >= amountOutMin, "swapPlus: INSUFFICIENT_OUTPUT_AMOUNT");
        if (y._swapOutToken == WETH) {
            IWETH(WETH).withdraw(y.amountOut);
            TransferHelper.safeTransferETH(to, y.amountOut);
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        Irouter _routerAddress,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) {
        Ifactory _factory = checkRouter(_routerAddress);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _factory.getPair(path[0], path[1]), amountIn
        );
        _swapForSingleDex(_routerAddress, _factory, path, amountOutMin, to);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        Irouter _routerAddress,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
    external
    payable
    ensure(deadline)
    {
        Ifactory _factory = checkRouter(_routerAddress);
        require(path[0] == WETH, "swapPlus: INVALID_PATH");
        uint256 amountIn = msg.value;
        IWETH(WETH).deposit{value : amountIn}();
        assert(IWETH(WETH).transfer(_factory.getPair(path[0], path[1]), amountIn));
        _swapForSingleDex(_routerAddress, _factory, path, amountOutMin, to);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        Irouter _routerAddress,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
    external
    ensure(deadline)
    {
        Ifactory _factory = checkRouter(_routerAddress);
        require(path[path.length - 1] == WETH, "swapPlus: INVALID_PATH");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _factory.getPair(path[0], path[1]), amountIn
        );
        _swapForSingleDex(_routerAddress, _factory, path, amountOutMin, to);
    }

    /*
    以下为多DEX兑换功能
    */

    function _swapSupportingFeeOnTransferTokensForMultiDex(
        Irouter[] memory _routerAddressList,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            Ifactory _factory = _routerAddressList.length > 1 ? checkRouter(_routerAddressList[i]) : checkRouter(_routerAddressList[0]);
            swapItem memory x = new swapItem[](1)[0];
            (x.input, x.output) = (path[i], path[i + 1]);
            (x.token0,) = sortTokens(x.input, x.output);
            x.pair = Ipair(_factory.getPair(x.input, x.output));
            (x.reserve0, x.reserve1,) = x.pair.getReserves();
            (x.reserveInput, x.reserveOutput) = x.input == x.token0 ? (x.reserve0, x.reserve1) : (x.reserve1, x.reserve0);
            x.amountInput = IERC20(x.input).balanceOf(address(x.pair)).sub(x.reserveInput);
            //这一行不能少
            x.path_ = new address[](2);
            x.path_[0] = x.input;
            x.path_[1] = x.output;
            x.amountOutput = _routerAddressList.length > 1 ? ((_routerAddressList[i].getAmountsOut(x.amountInput, x.path_))[1]) : (_routerAddressList[0].getAmountsOut(x.amountInput, x.path_))[1];
            (x.amount0Out, x.amount1Out) = x.input == x.token0 ? (zero, x.amountOutput) : (x.amountOutput, zero);
            if (i < path.length - 2) {
                Ifactory _factory2 = _routerAddressList.length > 1 ? checkRouter(_routerAddressList[i + 1]) : checkRouter(_routerAddressList[0]);
                x.to = _factory2.getPair(path[i + 1], path[i + 2]);
            } else {
                x.to = _to;
            }
            x.pair.swap(x.amount0Out, x.amount1Out, x.to, empty);
        }
    }

    function _swapForMultiDex(
        Irouter[] memory _routerAddressList,
        address[] memory path,
        uint256 amountOutMin,
        address to
    ) private {
        swapItem2 memory y = new swapItem2[](1)[0];
        y._swapOutToken = path[path.length - 1];
        y._to = y._swapOutToken == WETH ? address(this) : to;
        y.balanceBefore = IERC20(y._swapOutToken).balanceOf(y._to);
        _swapSupportingFeeOnTransferTokensForMultiDex(_routerAddressList, path, y._to);
        y.balanceAfter = IERC20(y._swapOutToken).balanceOf(y._to);
        y.amountOut = y.balanceAfter.sub(y.balanceBefore);
        require(y.amountOut >= amountOutMin, "swapPlus: INSUFFICIENT_OUTPUT_AMOUNT");
        if (y._swapOutToken == WETH) {
            IWETH(WETH).withdraw(y.amountOut);
            TransferHelper.safeTransferETH(to, y.amountOut);
        }
    }

    function checkAr(
        Irouter[] memory _routerAddressList,
        address[] memory path
    ) public pure {
        if (_routerAddressList.length > 1) {
            require(_routerAddressList.length == path.length.sub(1), "swapPlus: INVALID_ROUTER_ADDRESS_LIST");
        }
        if (_routerAddressList.length == 1) {
            require(path[path.length - 1] != path[0], "swapPlus: INVALID_SWAP_TOKEN");
        }
    }

    //多DEX---代币兑换ETH
    function swapExactTokensForETHSupportingFeeOnTransferTokensForMultiDex(
        Irouter[] memory _routerAddressList,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    )
    external
    ensure(deadline)
    {
        checkAr(_routerAddressList, path);
        Ifactory _factory = checkRouter(_routerAddressList[0]);
        require(path[path.length - 1] == WETH, "swapPlus: INVALID_PATH");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _factory.getPair(path[0], path[1]), amountIn
        );
        _swapForMultiDex(_routerAddressList, path, amountOutMin, to);
    }

    //多DEX---代币兑换代币
    function swapExactTokensForTokensSupportingFeeOnTransferTokensForMultiDex(
        Irouter[] calldata _routerAddressList,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) {
        checkAr(_routerAddressList, path);
        Ifactory _factory = checkRouter(_routerAddressList[0]);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _factory.getPair(path[0], path[1]), amountIn
        );
        _swapForMultiDex(_routerAddressList, path, amountOutMin, to);
    }

    //多DEX---ETH兑换代币
    function swapExactETHForTokensSupportingFeeOnTransferTokensForMultiDex(
        Irouter[] calldata _routerAddressList,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
    external
    payable
    ensure(deadline)
    {
        checkAr(_routerAddressList, path);
        Ifactory _factory = checkRouter(_routerAddressList[0]);
        require(path[0] == WETH, "swapPlus: INVALID_PATH");
        uint256 amountIn = msg.value;
        IWETH(WETH).deposit{value : amountIn}();
        assert(IWETH(WETH).transfer(_factory.getPair(path[0], path[1]), amountIn));
        _swapForMultiDex(_routerAddressList, path, amountOutMin, to);
    }

    function claimToken(IERC20 _token) external onlyOwner {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    function claimETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() payable external {
        assert(msg.sender == WETH);
    }
}