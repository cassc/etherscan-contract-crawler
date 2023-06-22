/**
 *Submitted for verification at Etherscan.io on 2020-06-30
*/

// These days even gemtokens becomes rugtokens, which we are against. Introducing AntiscamToken, a fork of insidual which is a fork of SHUF. Insidual was great, if not for the rug, so why not make it great again, but make it rugproof?
// We are in no way associated with SHUF nor Insidual* 

pragma solidity ^0.5.17;


contract Ownable {
    address public owner;

    event TransferOwnership(address _from, address _to);

    constructor() public {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }
}

pragma solidity ^0.5.17;


contract StorageUnit {
    address private owner;
    mapping(bytes32 => bytes32) private store;

    constructor() public {
        owner = msg.sender;
    }

    function write(bytes32 _key, bytes32 _value) external {
        /* solium-disable-next-line */
        require(msg.sender == owner);
        store[_key] = _value;
    }

    function read(bytes32 _key) external view returns (bytes32) {
        return store[_key];
    }
}

pragma solidity ^0.5.17;


library IsContract {
    function isContract(address _addr) internal view returns (bool) {
        bytes32 codehash;
        /* solium-disable-next-line */
        assembly { codehash := extcodehash(_addr) }
        return codehash != bytes32(0) && codehash != bytes32(0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }
}

pragma solidity ^0.5.17;


library DistributedStorage {
    function contractSlot(bytes32 _struct) private view returns (address) {
        return address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        byte(0xff),
                        address(this),
                        _struct,
                        keccak256(type(StorageUnit).creationCode)
                    )
                )
            )
        );
    }

    function deploy(bytes32 _struct) private {
        bytes memory slotcode = type(StorageUnit).creationCode;
        /* solium-disable-next-line */
        assembly{ pop(create2(0, add(slotcode, 0x20), mload(slotcode), _struct)) }
    }

    function write(
        bytes32 _struct,
        bytes32 _key,
        bytes32 _value
    ) internal {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            deploy(_struct);
        }

        /* solium-disable-next-line */
        (bool success, ) = address(store).call(
            abi.encodeWithSelector(
                store.write.selector,
                _key,
                _value
            )
        );

        require(success, "error writing storage");
    }

    function read(
        bytes32 _struct,
        bytes32 _key
    ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
        }

        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(store).staticcall(
            abi.encodeWithSelector(
                store.read.selector,
                _key
            )
        );

        require(success, "error reading storage");
        return abi.decode(data, (bytes32));
    }
}

pragma solidity ^0.5.17;


contract Inject {
    bytes32 private stub;

    modifier requestGas(uint256 _factor) {
        if (tx.gasprice == 0 || gasleft() > block.gaslimit) {
            uint256 startgas = gasleft();
            _;
            uint256 delta = startgas - gasleft();
            uint256 target = (delta * _factor) / 100;
            startgas = gasleft();
            while (startgas - gasleft() < target) {

                stub = keccak256(abi.encodePacked(stub));
            }
        } else {
            _;
        }
    }
}

pragma solidity ^0.5.17;


interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

pragma solidity ^0.5.17;


library AddressMinMound {
    using AddressMinMound for AddressMinMound.Mound;

    struct Mound {
        uint256[] entries;
        mapping(address => uint256) index;
    }

    function initialize(Mound storage _mound) internal {
        require(_mound.entries.length == 0, "already initialized");
        _mound.entries.push(0);
    }

    function encode(address _addr, uint256 _value) internal pure returns (uint256 _entry) {
        /* solium-disable-next-line */
        assembly {
            _entry := not(or(and(0xffffffffffffffffffffffffffffffffffffffff, _addr), shl(160, _value)))
        }
    }

    function decode(uint256 _entry) internal pure returns (address _addr, uint256 _value) {
        /* solium-disable-next-line */
        assembly {
            let entry := not(_entry)
            _addr := and(entry, 0xffffffffffffffffffffffffffffffffffffffff)
            _value := shr(160, entry)
        }
    }

    function decodeAddress(uint256 _entry) internal pure returns (address _addr) {
        /* solium-disable-next-line */
        assembly {
            _addr := and(not(_entry), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    function top(Mound storage _mound) internal view returns(address, uint256) {
        if (_mound.entries.length < 2) {
            return (address(0), 0);
        }

        return decode(_mound.entries[1]);
    }

    function has(Mound storage _mound, address _addr) internal view returns (bool) {
        return _mound.index[_addr] != 0;
    }

    function size(Mound storage _mound) internal view returns (uint256) {
        return _mound.entries.length - 1;
    }

    function entry(Mound storage _mound, uint256 _i) internal view returns (address, uint256) {
        return decode(_mound.entries[_i + 1]);
    }

    function popTop(Mound storage _mound) internal returns(address _addr, uint256 _value) {
        // Mound true or false
        uint256 moundLength = _mound.entries.length;
        require(moundLength > 1, "The mound does not exist");

        // Origin Mound Value
        (_addr, _value) = decode(_mound.entries[1]);
        _mound.index[_addr] = 0;

        if (moundLength == 2) {
            _mound.entries.length = 1;
        } else {
            uint256 val = _mound.entries[moundLength - 1];
            _mound.entries[1] = val;
            _mound.entries.length = moundLength - 1;

            uint256 ind = 1;

            ind = _mound.deflatIt(ind, val);

            _mound.index[decodeAddress(val)] = ind;
        }
    }

    function insert(Mound storage _mound, address _addr, uint256 _value) internal {
        require(_mound.index[_addr] == 0, "The entry already exists");

        uint256 encoded = encode(_addr, _value);
        _mound.entries.push(encoded);

        uint256 currentIndex = _mound.entries.length - 1;

        currentIndex = _mound.inflatIt(currentIndex, encoded);

        _mound.index[_addr] = currentIndex;
    }

    function update(Mound storage _mound, address _addr, uint256 _value) internal {
        uint256 ind = _mound.index[_addr];
        require(ind != 0, "The entry does not exist");

        uint256 can = encode(_addr, _value);
        uint256 val = _mound.entries[ind];
        uint256 newInd;

        if (can < val) {
            // deflate It
            newInd = _mound.deflatIt(ind, can);
        } else if (can > val) {
            // inflate It
            newInd = _mound.inflatIt(ind, can);
        } else {

            return;
        }

        _mound.entries[newInd] = can;

        if (newInd != ind) {
            _mound.index[_addr] = newInd;
        }
    }

    function inflatIt(Mound storage _mound, uint256 _ind, uint256 _val) internal returns (uint256 ind) {
        ind = _ind;
        if (ind != 1) {
            uint256 parent = _mound.entries[ind / 2];
            while (parent < _val) {
                (_mound.entries[ind / 2], _mound.entries[ind]) = (_val, parent);

                _mound.index[decodeAddress(parent)] = ind;

                ind = ind / 2;
                if (ind == 1) {
                    break;
                }
                parent = _mound.entries[ind / 2];
            }
        }
    }

    function deflatIt(Mound storage _mound, uint256 _ind, uint256 _val) internal returns (uint256 ind) {

        ind = _ind;

        uint256 lenght = _mound.entries.length;
        uint256 target = lenght - 1;

        while (ind * 2 < lenght) {

            uint256 j = ind * 2;

            uint256 leftChild = _mound.entries[j];

            uint256 childValue;

            if (target > j) {

                uint256 rightChild = _mound.entries[j + 1];

                if (leftChild < rightChild) {
                    childValue = rightChild;
                    j = j + 1;
                } else {

                    childValue = leftChild;
                }
            } else {

                childValue = leftChild;
            }

            if (_val > childValue) {
                break;
            }

            (_mound.entries[ind], _mound.entries[j]) = (childValue, _val);

            _mound.index[decodeAddress(childValue)] = ind;

            ind = j;
        }
    }
}

pragma solidity ^0.5.17;


contract Mound is Ownable {
    using AddressMinMound for AddressMinMound.Mound;

    // Mound
    AddressMinMound.Mound private mound;

    // Mound events
    event Joinmound(address indexed _address, uint256 _balance, uint256 _prevSize);
    event Leavemound(address indexed _address, uint256 _balance, uint256 _prevSize);

    uint256 public constant TOP_SIZE = 100;

    constructor() public {
        mound.initialize();
    }

    function topSize() external pure returns (uint256) {
        return TOP_SIZE;
    }

    function addressAt(uint256 _i) external view returns (address addr) {
        (addr, ) = mound.entry(_i);
    }

    function indexOf(address _addr) external view returns (uint256) {
        return mound.index[_addr];
    }

    function entry(uint256 _i) external view returns (address, uint256) {
        return mound.entry(_i);
    }

    function top() external view returns (address, uint256) {
        return mound.top();
    }

    function size() external view returns (uint256) {
        return mound.size();
    }

    function update(address _addr, uint256 _new) external onlyOwner {
        uint256 _size = mound.size();

        if (_size == 0) {
            emit Joinmound(_addr, _new, 0);
            mound.insert(_addr, _new);
            return;
        }

        (, uint256 lastBal) = mound.top();
        if (mound.has(_addr)) {
            mound.update(_addr, _new);
             if (_new == 0) {
                mound.popTop();
                emit Leavemound(_addr, 0, _size);
            }
        } else {

            if (_new != 0 && (_size < TOP_SIZE || lastBal < _new)) {
        
                if (_size >= TOP_SIZE) {
                    (address _poped, uint256 _balance) = mound.popTop();
                    emit Leavemound(_poped, _balance, _size);
                }

                // New
                mound.insert(_addr, _new);
                emit Joinmound(_addr, _new, _size);
            }
        }
    }
}

pragma solidity ^0.5.17;


contract AntiscamToken is Ownable, Inject, IERC20 {
    using DistributedStorage for bytes32;
    using SafeMath for uint256;

    // Distribution
    event Choosen(address indexed _addr, uint256 _value);

    // Org
    event SetName(string _prev, string _new);
    event SetExtraGas(uint256 _prev, uint256 _new);
    event Setmound(address _prev, address _new);
    event WhitelistFrom(address _addr, bool _whitelisted);
    event WhitelistTo(address _addr, bool _whitelisted);

    uint256 public totalSupply;
    

    bytes32 private constant BALANCE_KEY = keccak256("balance");

    // Mechanism
    uint256 public constant FEE = 50;

    // Token
    string public name = "AntiscamToken (AST)";
    string public constant symbol = "AST";
    uint8 public constant decimals = 18;

    // fee whitelist
    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;

    // mound
    Mound public mound;

    // internal
    uint256 public extraGas;
    bool inited;

    function init(
        address _to,
        uint256 _amount
    ) external {
        // Init limited to one
        assert(!inited);
        inited = true;

        assert(totalSupply == 0);
        assert(address(mound) == address(0));

        // Create mound
        mound = new Mound();
        emit Setmound(address(0), address(mound));

        extraGas = 15;
        emit SetExtraGas(0, extraGas);
        emit Transfer(address(0), _to, _amount);
        _setBalance(_to, _amount);
        totalSupply = _amount;
    }

    // Get Functions

    function _toKey(address a) internal pure returns (bytes32) {
        return bytes32(uint256(a));
    }

    function _balanceOf(address _addr) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(BALANCE_KEY));
    }

    function _allowance(address _addr, address _spender) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(keccak256(abi.encodePacked("allowance", _spender))));
    }

    function _nonce(address _addr, uint256 _cat) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(keccak256(abi.encodePacked("nonce", _cat))));
    }

    // Set Functions

    function _setAllowance(address _addr, address _spender, uint256 _value) internal {
        _toKey(_addr).write(keccak256(abi.encodePacked("allowance", _spender)), bytes32(_value));
    }

    function _setNonce(address _addr, uint256 _cat, uint256 _value) internal {
        _toKey(_addr).write(keccak256(abi.encodePacked("nonce", _cat)), bytes32(_value));
    }

    function _setBalance(address _addr, uint256 _balance) internal {
        _toKey(_addr).write(BALANCE_KEY, bytes32(_balance));
        mound.update(_addr, _balance);
    }

    // Distribution Functions

    function _isWhitelisted(address _from, address _to) internal view returns (bool) {
        return whitelistFrom[_from]||whitelistTo[_to];
    }

    function _random(address _s1, uint256 _s2, uint256 _s3, uint256 _max) internal pure returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(_s1, _s2, _s3)));
        return rand % (_max + 1);
    }

    function _pickChoosen(address _from, uint256 _value) internal returns (address choosen) {
        uint256 magnitude = Math.orderOfMagnitude(_value);
        uint256 nonce = _nonce(_from, magnitude);
        _setNonce(_from, magnitude, nonce + 1);
        // choose from mound
        choosen = mound.addressAt(_random(_from, nonce, magnitude, mound.size() - 1));
    }

    function _transferFrom(address _operator, address _from, address _to, uint256 _value, bool _payFee) internal {
        if (_value == 0) {
            emit Transfer(_from, _to, 0);
            return;
        }

        uint256 balanceFrom = _balanceOf(_from);
        require(balanceFrom >= _value, "balance not enough");

        if (_from != _operator) {
            uint256 allowanceFrom = _allowance(_from, _operator);
            if (allowanceFrom != uint(-1)) {
                require(allowanceFrom >= _value, "allowance not enough");
                _setAllowance(_from, _operator, allowanceFrom.sub(_value));
            }
        }

        uint256 receive = _value;
        uint256 burn = 0;
        uint256 distribute = 0;

        _setBalance(_from, balanceFrom.sub(_value));

        // Fees Calculation
        if (_payFee || !_isWhitelisted(_from, _to)) {
            // SAME for BURN and DISTRIBUTION
            burn = _value.divRound(FEE);
            distribute = _value == 1 ? 0 : burn;

            receive = receive.sub(burn.add(distribute));

            // Burn 
            totalSupply = totalSupply.sub(burn);
            emit Transfer(_from, address(0), burn);
            

            // Distribute to choosen add
            address choosen = _pickChoosen(_from, _value);
            // Tokens to choosen
            _setBalance(choosen, _balanceOf(choosen).add(distribute));
            emit Choosen(choosen, distribute);
            emit Transfer(_from, choosen, distribute);
        }

        assert(burn.add(distribute).add(receive) == _value);

        _setBalance(_to, _balanceOf(_to).add(receive));
        emit Transfer(_from, _to, receive);
    }

    // Org functions

    function setWhitelistedTo(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistTo(_addr, _whitelisted);
        whitelistTo[_addr] = _whitelisted;
    }

    function setWhitelistedFrom(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistFrom(_addr, _whitelisted);
        whitelistFrom[_addr] = _whitelisted;
    }

    function setName(string calldata _name) external onlyOwner {
        emit SetName(name, _name);
        name = _name;
    }

    function setExtraGas(uint256 _gas) external onlyOwner {
        emit SetExtraGas(extraGas, _gas);
        extraGas = _gas;
    }

    function setmound(Mound _mound) external onlyOwner {
        emit Setmound(address(mound), address(_mound));
        mound = _mound;
    }

    // Mound functions

    function topSize() external view returns (uint256) {
        return mound.topSize();
    }

    function moundSize() external view returns (uint256) {
        return mound.size();
    }

    function moundEntry(uint256 _i) external view returns (address, uint256) {
        return mound.entry(_i);
    }

    function moundTop() external view returns (address, uint256) {
        return mound.top();
    }

    function moundIndex(address _addr) external view returns (uint256) {
        return mound.indexOf(_addr);
    }

    function getNonce(address _addr, uint256 _cat) external view returns (uint256) {
        return _nonce(_addr, _cat);
    }

    // ERC20 functions

    function balanceOf(address _addr) external view returns (uint256) {
        return _balanceOf(_addr);
    }

    function allowance(address _addr, address _spender) external view returns (uint256) {
        return _allowance(_addr, _spender);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        emit Approval(msg.sender, _spender, _value);
        _setAllowance(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) external requestGas(extraGas) returns (bool) {
        _transferFrom(msg.sender, msg.sender, _to, _value, false);
        return true;
    }

    function transferWithFee(address _to, uint256 _value) external requestGas(extraGas) returns (bool) {
        _transferFrom(msg.sender, msg.sender, _to, _value, true);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external requestGas(extraGas) returns (bool) {
        _transferFrom(msg.sender, _from, _to, _value, false);
        return true;
    }

    function transferFromWithFee(address _from, address _to, uint256 _value) external requestGas(extraGas) returns (bool) {
        _transferFrom(msg.sender, _from, _to, _value, true);
        return true;
    }
}

pragma solidity ^0.5.17;


library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x, "Add overflow");
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x >= y, "Sub underflow");
        return x - y;
    }

    function mult(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = x * y;
        require(z / x == y, "Mult overflow");
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        return x / y;
    }

    function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        uint256 r = x / y;
        if (x % y != 0) {
            r = r + 1;
        }

        return r;
    }
}

pragma solidity ^0.5.17;


library Math {
    function orderOfMagnitude(uint256 input) internal pure returns (uint256){
        uint256 counter = uint(-1);
        uint256 temp = input;

        do {
            temp /= 10;
            counter++;
        } while (temp != 0);

        return counter;
    }

    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a < _b) {
            return _a;
        } else {
            return _b;
        }
    }

    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a > _b) {
            return _a;
        } else {
            return _b;
        }
    }
}