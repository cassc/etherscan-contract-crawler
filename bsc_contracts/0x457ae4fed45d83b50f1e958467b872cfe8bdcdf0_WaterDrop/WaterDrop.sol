/**
 *Submitted for verification at BscScan.com on 2023-05-01
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.9;

   abstract contract Context {
   function _msgSender() internal view virtual returns (address payable) {
       return msg.sender;
   }

   function _msgData() internal view virtual returns (bytes memory) {
       this;

       return msg.data;
   }
   }


   contract Ownable is Context {
   address private _owner;

   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 
      constructor () internal {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
      }

 
      function owner() public view returns (address) {
      return _owner;
      }

      modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
      }

  
      function renounceOwnership() public virtual onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
      }


      function transferOwnership(address newOwner) public virtual onlyOwner {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
      }
      }


   interface IERC20 {

      function totalSupply() external view returns (uint256);

      function balanceOf(address account) external view returns (uint256);

      function transfer(address recipient, uint256 amount) external returns (bool);

   
      function allowance(address owner, address spender) external view returns (uint256);

  
      function approve(address spender, uint256 amount) external returns (bool);

  
      function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  
      event Transfer(address indexed from, address indexed to, uint256 value);

  
      event Approval(address indexed owner, address indexed spender, uint256 value);
      }


   library SafeMath {
  
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
        }

 
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
        }

   
        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
        }

 
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
        }

        function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
        }

   
        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
        }

 
        function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
        }

 
        function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
        }
        }


   library Address {
  
      function isContract(address account) internal view returns (bool) {
     
      bytes32 codehash;
      bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
      
      assembly {codehash := extcodehash(account)}
      return (codehash != accountHash && codehash != 0x0);
      }


      function sendValue(address payable recipient, uint256 amount) internal {
      require(address(this).balance >= amount, "Address: insufficient balance");

      // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
      (bool success,) = recipient.call{value : amount}("");
      require(success, "Address: unable to send value, recipient may have reverted");
      }

  
      function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
      }

      function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
      return _functionCallWithValue(target, data, 0, errorMessage);
      }

  
      function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
      return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
      }

      function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
      require(address(this).balance >= value, "Address: insufficient balance for call");
      return _functionCallWithValue(target, data, value, errorMessage);
      }

   function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
       require(isContract(target), "Address: call to non-contract");

     
       (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
       if (success) {
           return returndata;
       } else {
           
           if (returndata.length > 0) {

               assembly {
                   let returndata_size := mload(returndata)
                   revert(add(32, returndata), returndata_size)
               }
           } else {
               revert(errorMessage);
           }
       }

   }
   }


   contract ERC20 is Context, IERC20 {
   using SafeMath for uint256;
   using Address for address;

   mapping(address => uint256) private _balances;

   mapping(address => mapping(address => uint256)) private _allowances;

   uint256 private _totalSupply;

   string private _name;
   string private _symbol;
   uint8 private _decimals;


      constructor (string memory name, string memory symbol) public {
      _name = name;
      _symbol = symbol;
      _decimals = 18;
      }

      function name() public view returns (string memory) {
      return _name;
      }


      function symbol() public view returns (string memory) {
      return _symbol;
      }


      function decimals() public view returns (uint8) {
      return _decimals;
      }


      function totalSupply() public view override returns (uint256) {
      return _totalSupply;
      }


      function balanceOf(address account) public view override returns (uint256) {
      return _balances[account];
      }

        function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
        }

      function allowance(address owner, address spender) public view virtual override returns (uint256) {
      return _allowances[owner][spender];
      }


        function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
        }


      function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
      _transfer(sender, recipient, amount);
      _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
      return true;
      }


        function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
        }


      function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
      _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
      return true;
      }

        function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        }

        function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        }


        function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        }


        function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        }

      function _setupDecimals(uint8 decimals_) internal {
      _decimals = decimals_;
      }

      function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
      }


library EnumerableSet {

    struct Set {

        bytes32[] _values;

        mapping (bytes32 => uint256) _indexes;
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
    
        if (valueIndex != 0) { // Equivalent to contains(set, value)
           
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
    

    
            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;

            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    
    struct Bytes32Set {
        Set _inner;
    }
    

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }
    

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }


    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }
    

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }
    

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }


    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet
    
    struct UintSet {
        Set _inner;
    }
    

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
    

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
    

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
    

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

abstract contract DelegateERC20 is ERC20 {

    mapping (address => address) internal _delegates;


    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }
    
 
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    

    mapping (address => uint32) public numCheckpoints;
    

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    

    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping (address => uint) public nonces;

    function _mint(address account, uint256 amount) internal override virtual {
        super._mint(account, amount);
    
        // add delegates to the minter
        _moveDelegates(address(0), _delegates[account], amount);
    }


    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        super._transfer(sender, recipient, amount);
        _moveDelegates(_delegates[sender], _delegates[recipient], amount);
    }


    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }
    

    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );
    
        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );
    
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );
    
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "BSCToken::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "BSCToken::delegateBySig: invalid nonce");
        require(now <= expiry, "BSCToken::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }
    

    function getCurrentVotes(address account)
    external
    view
    returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }
    

    function getPriorVotes(address account, uint blockNumber)
    external
    view
    returns (uint256)
    {
        require(blockNumber < block.number, "BSCToken::getPriorVotes: not yet determined");
    
        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }
    
        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }
    
    function _delegate(address delegator, address delegatee)
    internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying balances (not scaled);
        _delegates[delegator] = delegatee;
    
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    
        emit DelegateChanged(delegator, currentDelegate, delegatee);
    }
    
    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
    
            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }
    
    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
    internal
    {
        uint32 blockNumber = safe32(block.number, "BSCToken::_writeCheckpoint: block number exceeds 32 bits");
    
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }
    
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
    
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
    
    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
    
        return chainId;
    }

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    
   
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

}

contract WaterDrop is DelegateERC20, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;
    uint256 private constant maxSupply = 2100000000 * 1e18;     // the total supply
    constructor() public ERC20("WaterDrop", "WD"){
    }

    // mint with max supply
    function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {
        if (_amount.add(totalSupply()) > maxSupply) {
          return false;
        }
        _mint(_to, _amount);
        return true;
    }
    
    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), "BSCToken: _addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }
    
    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "BSCToken: _delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }
    
    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }
    
    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }
    
    function getMinter(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getMinterLength() - 1, "BSCToken: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }
    
    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }

}