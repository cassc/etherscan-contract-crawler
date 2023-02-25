pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

interface IRouter {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

contract SwapContract is ERC20Upgradeable, OwnableUpgradeable {
    using UQ112x112 for uint224;
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;
    
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant SELECTOR1 = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    address public token1;
    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint public offSet;

    uint public maxToken0;
    uint public maxToken1;

    uint public buyFee;
    uint public sellFee;

    address public WBNB;

    IRouter public router;

    struct BuyEvent {
        address account;
        uint amount;
        bool processed;
    }

    struct AddEvent {
        address account;
        uint amount0;
        uint amount1;
        bool processed;
    }

    struct RemoveEvent {
        address account;
        uint amount;
        bool processed;
    }

    mapping(uint=>BuyEvent) public buyEvents;
    uint public totalBuyEvents;
    uint public processedBuyEvents;

    mapping(uint=>AddEvent) public addEvents;
    uint public totalAddEvents;
    uint public processedAddEvents;

    mapping(uint=>RemoveEvent) public removeEvents;
    uint public totalRemoveEvents;
    uint public processedRemoveEvents;

    uint public totalLockedAmount;
    struct LockedItem {
        uint amount;
        uint lockedDate;
        uint lockedPeriod;
        address account;
    }
    mapping(uint=>LockedItem) public lockedItems;
    uint public totalLockedItems;

    uint public minLockedPeriod;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event AddLiquidity(address indexed account, uint amount0, uint amount1, uint index);
    event RemoveLiquidity(address indexed account, uint amount);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to, uint index);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Buy (
        address indexed account,
        uint amount,
        uint index
    );
    event Sync(uint112 reserve0, uint112 reserve1); 

    event Locked(uint amount, uint lockedPeriod, address indexed account);

    event Unlocked(uint amount, uint lockedPeriod, address indexed account);

    function initialize(string memory _name, string memory _symbol, address _token1) initializer public {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,address verifyingContract)'),
                keccak256(bytes(_name)),
                keccak256(bytes('1')),
                address(this)
            )
        );
        token1 = _token1;

        offSet = 1e4;

        maxToken0 = 100000000000000000000000*1e18;
        maxToken1 = 10*1e18;

        buyFee = 500; // 1%
        sellFee = 3000; // 3%

        minLockedPeriod = 1 hours;

        unlocked = 1;

        _disableInitializers();
    }

    uint private unlocked;

    uint256[50] private __gap;

    modifier lock() {
        if (unlocked != 1) revert('LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function addReserves(uint112 _reserve0, uint112 _reserve1) external onlyOwner {
        if(reserve0 > 0 && reserve1 > 0) revert("Not initial status");
        mint(msg.sender, _reserve0, _reserve1);
    }   

    function setOffSet(uint _offSet) external onlyOwner {
        offSet = _offSet;
    }   

    function setWBNB(address _wbnb) external onlyOwner {
        WBNB = _wbnb;
    } 

    function setRouter(IRouter _router) external onlyOwner {
        router = _router;
    } 

    function setMaxToken(uint _max0, uint _max1) external onlyOwner {
        maxToken0 = _max0;
        maxToken1 = _max1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function setMinLockedPeriod(uint _period) external onlyOwner {
        minLockedPeriod = _period;
    } 

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        if(deadline < block.timestamp) revert('EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        if(recoveredAddress == address(0) || recoveredAddress != owner) revert('INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }    

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        if(!success || !(data.length == 0 || abi.decode(data, (bool)))) revert('TRANSFER_FAILED');
    } 

    function _safeTransferFrom(address token, address from, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR1, from, to, value));
        if(!success || !(data.length == 0 || abi.decode(data, (bool)))) revert('TRANSFER_FAILED');
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to, uint amount0, uint amount1) internal lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings

        uint balance0 = _reserve0 + amount0;
        uint balance1 = _reserve1 + amount1;

        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0*amount1);
        } else {
            liquidity = Math.min(amount0*_totalSupply / _reserve0, amount1*_totalSupply / _reserve1);
        }
        if (liquidity == 0) revert('INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) internal lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token1 = token1;                                // gas savings
        uint liquidity = balanceOf(address(this)) - totalLockedAmount;

        uint _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity*_reserve0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity*_reserve1 / _totalSupply; // using balances ensures pro-rata distribution
        if (amount0 == 0 || amount1 == 0) revert('INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        // add to list
        removeEvents[totalRemoveEvents] = RemoveEvent({account: msg.sender, amount: amount0, processed: false});
        totalRemoveEvents ++;

        _safeTransfer(_token1, to, amount1);
        uint balance0 = _reserve0 - amount0;
        uint balance1 = _reserve1 - amount1;

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to, totalRemoveEvents-1);
    }

    function processRemove(uint index) external onlyOwner {
        if(removeEvents[index].processed) revert("Invalid index");
        removeEvents[index].processed = true;
        processedRemoveEvents++;
    }

    function addLiquidity(uint amount0) external {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint amount1 = amount0*_reserve1/_reserve0;
        _safeTransferFrom(token1, msg.sender, address(this), amount1);

        // add to list
        addEvents[totalAddEvents] = AddEvent({account: msg.sender, amount0: amount0, amount1: amount1, processed: false});
        totalAddEvents ++;

        emit AddLiquidity(msg.sender, amount0, amount1, totalAddEvents-1);
    }

    function processAdd(uint index) external onlyOwner {
        if(addEvents[index].processed) revert("Invalid index");
        address account = addEvents[index].account;
        uint amount0 = addEvents[index].amount0;
        uint amount1 = addEvents[index].amount1;

        mint(account, amount0, amount1);

        addEvents[index].processed = true;
        processedAddEvents++;
    }

    function lockLiquidity(uint amount, uint lockedPeriod) external {
        if(amount > balanceOf(msg.sender)) revert("Not enough balance");
        if(lockedPeriod < minLockedPeriod) revert("Invalid locked period");
        _safeTransferFrom(address(this), msg.sender, address(this), amount);
        totalLockedAmount += amount;
        lockedItems[totalLockedItems] = LockedItem({amount: amount, lockedDate: block.timestamp, lockedPeriod: lockedPeriod, account: msg.sender});
        totalLockedItems ++;      

        emit Locked(amount, lockedPeriod, msg.sender);
    }

    function unLockLiquidity(uint index) external {
        LockedItem memory item = lockedItems[index];
        if(item.account != msg.sender) revert("Invalid user");
        if(item.amount == 0) revert("No balance to unlock");
        if(item.lockedDate + item.lockedPeriod > block.timestamp) revert("Not available now");
        _safeTransfer(address(this), msg.sender, item.amount);
        
        uint amount = item.amount;

        totalLockedAmount -= item.amount;
        lockedItems[index].amount = 0;

        emit Locked(amount, item.lockedPeriod, msg.sender);
    }

    function removeLiquidity(uint amount) external {
        _safeTransferFrom(address(this), msg.sender, address(this), amount);
        burn(msg.sender);
        emit RemoveLiquidity(msg.sender, amount);
    }

    function withdrawTokens(address _token, address _to, uint _amount) external onlyOwner {
        if(_token == token1 || _token == address(this)) revert("Invalid token");
        _safeTransfer(_token, _to, _amount);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, uint256 amount0In, uint256 amount1In, address to) public lock {
        if(amount0Out+amount1Out+amount0In+amount1In == 0) revert("Invalid param");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        if(amount0Out == 0) {
            if(amount1Out == 0) {
                if(amount0In == 0) {
                    amount0Out = getAmountOut(amount1In, _reserve1, _reserve0);
                } else {
                    amount1Out = getAmountOut(amount0In, _reserve0, _reserve1);
                }
            } else {
                amount0In = getAmountIn(amount1Out, _reserve0, _reserve1);
            }
        } else {
            amount1In = getAmountIn(amount0Out, _reserve1, _reserve0);
        }
        if(amount0Out > maxToken0 || amount1Out > maxToken1) revert("Too much amount out");
        if(amount0Out >= _reserve0 || amount1Out >= _reserve1) revert('INSUFFICIENT_LIQUIDITY');

        uint balance0 = reserve0 + amount0In - amount0Out;
        uint balance1 = reserve1 + amount1In - amount1Out;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token1 = token1;
        if (to == _token1) revert('INVALID_TO');

        if(amount0In > 0) {
            if(msg.sender != owner()) revert("Not allowed");
        }
        if(amount1In > 0) _safeTransferFrom(token1, msg.sender, address(this), amount1In);
        
        if (amount0Out > 0) {
            // getting buyFee
            uint buyFee0 = amount0Out * buyFee / 100000;
            balance0 += buyFee0;
            amount0Out -= buyFee0;
            // add to list
            buyEvents[totalBuyEvents] = BuyEvent({account: to, amount: amount0Out, processed: false});
            totalBuyEvents ++;

            emit Buy(to, amount0Out, totalBuyEvents-1);
        }
        if (amount1Out > 0) {
           if(msg.sender != owner()) revert("Caller is not owner"); 

            uint sellFeeAmount = amount1Out*sellFee/100000;

            amount1Out = amount1Out - sellFeeAmount;

            //get sell fee
            if(address(router) != address(0)) {
                _safeTransfer(_token1, address(this), amount1Out);
                ERC20Upgradeable(token1).approve(address(router), sellFeeAmount);
                address[] memory path = new address[](2);
                path[0] = _token1;
                path[1] = WBNB;
                router.swapExactTokensForETH(sellFeeAmount, 0, path, owner(), block.timestamp+2000);
            } else {
                _safeTransfer(_token1, owner(), amount1Out);
            }

            _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        }
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function processBuy(uint index) external onlyOwner {
        if(buyEvents[index].processed) revert("Invalid index");
        buyEvents[index].processed = true;
        processedBuyEvents++;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        if (amountIn == 0) revert('INSUFFICIENT_INPUT_AMOUNT');
        if (reserveIn == 0 && reserveOut == 0) revert('INSUFFICIENT_LIQUIDITY');
        uint numerator = amountIn*reserveOut;
        uint denominator = reserveIn+amountIn;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        if (amountOut == 0) revert('INSUFFICIENT_OUTPUT_AMOUNT');
        if (reserveIn == 0 && reserveOut == 0) revert('INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut;
        uint denominator = reserveOut-amountOut;
        amountIn = (numerator / denominator) + 1;
    }
}