/**
 *Submitted for verification at Etherscan.io on 2020-05-11
*/

// File: contracts/DkargoPrefix.sol

pragma solidity >=0.5.0 <0.6.0;

/// @title DkargoPrefix
/// @notice 디카르고 컨트랙트 여부 식별용 prefix 컨트랙트 정의
/// @author jhhong
contract DkargoPrefix {
    
    string internal _dkargoPrefix; // 디카르고-프리픽스
    
    /// @author jhhong
    /// @notice 디카르고 프리픽스를 반환한다.
    /// @return 디카르고 프리픽스 (string)
    function getDkargoPrefix() public view returns(string memory) {
        return _dkargoPrefix;
    }

    /// @author jhhong
    /// @notice 디카르고 프리픽스를 설정한다.
    /// @param prefix 설정할 프리픽스
    function _setDkargoPrefix(string memory prefix) internal {
        _dkargoPrefix = prefix;
    }
}

// File: contracts/authority/Ownership.sol

pragma solidity >=0.5.0 <0.6.0;

/// @title Onwership
/// @dev 오너 확인 및 소유권 이전 처리
/// @author jhhong
contract Ownership {
    address private _owner;

    event OwnershipTransferred(address indexed old, address indexed expected);

    /// @author jhhong
    /// @notice 소유자만 접근할 수 있음을 명시한다.
    modifier onlyOwner() {
        require(isOwner() == true, "Ownership: only the owner can call");
        _;
    }

    /// @author jhhong
    /// @notice 컨트랙트 생성자이다.
    constructor() internal {
        emit OwnershipTransferred(_owner, msg.sender);
        _owner = msg.sender;
    }

    /// @author jhhong
    /// @notice 소유권을 넘겨준다.
    /// @param expected 새로운 오너 계정
    function transferOwnership(address expected) public onlyOwner {
        require(expected != address(0), "Ownership: new owner is the zero address");
        emit OwnershipTransferred(_owner, expected);
        _owner = expected;
    }

    /// @author jhhong
    /// @notice 오너 주소를 반환한다.
    /// @return 오너 주소
    function owner() public view returns (address) {
        return _owner;
    }

    /// @author jhhong
    /// @notice 소유자인지 확인한다.
    /// @return 확인 결과 (boolean)
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}

// File: contracts/libs/refs/SafeMath.sol

pragma solidity >=0.5.0 <0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/chain/AddressChain.sol

pragma solidity >=0.5.0 <0.6.0;


/// @title AddressChain
/// @notice 주소 체인 정의 및 관리
/// @dev 토큰홀더, 회원정보 등과 같은 유저 리스트 관리에 쓰인다.
/// @author jhhong
contract AddressChain {
    using SafeMath for uint256;

    // 구조체 : 노드 정보
    struct NodeInfo {
        address prev; // 이전 노드
        address next; // 다음 노드
    }
    // 구조체 : 노드 체인
    struct NodeList {
        uint256 count; // 노드의 총 개수
        address head; // 체인의 머리
        address tail; // 체인의 꼬리
        mapping(address => NodeInfo) map; // 계정에 대한 노드 정보 매핑
    }

    // 변수 선언
    NodeList private _slist; // 노드 체인 (싱글리스트)

    // 이벤트 선언
    event AddressChainLinked(address indexed node); // 이벤트: 체인에 추가됨
    event AddressChainUnlinked(address indexed node); // 이벤트: 체인에서 빠짐

    /// @author jhhong
    /// @notice 체인에 연결된 원소의 개수를 반환한다.
    /// @return 체인에 연결된 원소의 개수
    function count() public view returns(uint256) {
        return _slist.count;
    }

    /// @author jhhong
    /// @notice 체인 헤드 정보를 반환한다.
    /// @return 체인 헤드 정보
    function head() public view returns(address) {
        return _slist.head;
    }

    /// @author jhhong
    /// @notice 체인 꼬리 정보를 반환한다.
    /// @return 체인 꼬리 정보
    function tail() public view returns(address) {
        return _slist.tail;
    }

    /// @author jhhong
    /// @notice node의 다음 노드 정보를 반환한다.
    /// @param node 노드 정보 (체인에 연결되어 있을 수도 있고 아닐 수도 있음)
    /// @return node의 다음 노드 정보
    function nextOf(address node) public view returns(address) {
        return _slist.map[node].next;
    }

    /// @author jhhong
    /// @notice node의 이전 노드 정보를 반환한다.
    /// @param node 노드 정보 (체인에 연결되어 있을 수도 있고 아닐 수도 있음)
    /// @return node의 이전 노드 정보
    function prevOf(address node) public view returns(address) {
        return _slist.map[node].prev;
    }

    /// @author jhhong
    /// @notice node가 체인에 연결된 상태인지를 확인한다.
    /// @param node 체인 연결 여부를 확인할 노드 주소
    /// @return 연결 여부 (boolean), true: 연결됨(linked), false: 연결되지 않음(unlinked)
    function isLinked(address node) public view returns (bool) {
        if(_slist.count == 1 && _slist.head == node && _slist.tail == node) {
            return true;
        } else {
            return (_slist.map[node].prev == address(0) && _slist.map[node].next == address(0))? (false) :(true);
        }
    }

    /// @author jhhong
    /// @notice 새로운 노드 정보를 노드 체인에 연결한다.
    /// @param node 노드 체인에 연결할 노드 주소
    function _linkChain(address node) internal {
        require(node != address(0), "AddressChain: try to link to the zero address");
        require(!isLinked(node), "AddressChain: the node is aleady linked");
        if(_slist.count == 0) {
            _slist.head = _slist.tail = node;
        } else {
            _slist.map[node].prev = _slist.tail;
            _slist.map[_slist.tail].next = node;
            _slist.tail = node;
        }
        _slist.count = _slist.count.add(1);
        emit AddressChainLinked(node);
    }

    /// @author jhhong
    /// @notice node 노드를 체인에서 연결 해제한다.
    /// @param node 노드 체인에서 연결 해제할 노드 주소
    function _unlinkChain(address node) internal {
        require(node != address(0), "AddressChain: try to unlink to the zero address");
        require(isLinked(node), "AddressChain: the node is aleady unlinked");
        address tempPrev = _slist.map[node].prev;
        address tempNext = _slist.map[node].next;
        if (_slist.head == node) {
            _slist.head = tempNext;
        }
        if (_slist.tail == node) {
            _slist.tail = tempPrev;
        }
        if (tempPrev != address(0)) {
            _slist.map[tempPrev].next = tempNext;
            _slist.map[node].prev = address(0);
        }
        if (tempNext != address(0)) {
            _slist.map[tempNext].prev = tempPrev;
            _slist.map[node].next = address(0);
        }
        _slist.count = _slist.count.sub(1);
        emit AddressChainUnlinked(node);
    }
}

// File: contracts/introspection/ERC165/IERC165.sol

pragma solidity >=0.5.0 <0.6.0;

/// @title IERC165
/// @dev EIP165 interface 선언
/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
/// @author jhhong
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: contracts/introspection/ERC165/ERC165.sol

pragma solidity >=0.5.0 <0.6.0;


/// @title ERC165
/// @dev EIP165 interface 구현
/// @author jhhong
contract ERC165 is IERC165 {
    
    mapping(bytes4 => bool) private _infcs; // INTERFACE ID별 지원여부를 저장하기 위한 매핑 변수

    /// @author jhhong
    /// @notice 컨트랙트 생성자이다.
    /// @dev bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
    constructor() internal {
        _registerInterface(0x01ffc9a7); // supportsInterface()의 INTERFACE ID 등록
    }

    /// @author jhhong
    /// @notice 컨트랙트가 INTERFACE ID를 지원하는지의 여부를 반환한다.
    /// @param infcid 지원여부를 확인할 INTERFACE ID (Function Selector)
    /// @return 지원여부 (boolean)
    function supportsInterface(bytes4 infcid) external view returns (bool) {
        return _infcs[infcid];
    }

    /// @author jhhong
    /// @notice INTERFACE ID를 등록한다.
    /// @param infcid 등록할 INTERFACE ID (Function Selector)
    function _registerInterface(bytes4 infcid) internal {
        require(infcid != 0xffffffff, "ERC165: invalid interface id");
        _infcs[infcid] = true;
    }
}

// File: contracts/token/ERC20/IERC20.sol

pragma solidity >=0.5.0 <0.6.0;

/// @title IERC20
/// @notice EIP20 interface 선언
/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
/// @author jhhong
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/token/ERC20/ERC20.sol

pragma solidity >=0.5.0 <0.6.0;



/// @title ERC20
/// @notice EIP20 interface 정의 및 mint/burn (internal) 함수 구현
/// @author jhhong
contract ERC20 is IERC20 {
    using SafeMath for uint256;
    
    uint256 private _supply; // 총 통화량
    mapping(address => uint256) private _balances; // 계정별 통화량 저장소
    mapping(address => mapping(address => uint256)) private _allowances; // 각 계정에 대해 "계정별 위임량"을 저장
    
    /// @author jhhong
    /// @notice 컨트랙트 생성자이다.
    /// @param supply 초기 발행량
    constructor(uint256 supply) internal {
        uint256 pebs = supply;
        _mint(msg.sender, pebs);
    }
    
    /// @author jhhong
    /// @notice 계정(spender)에게 통화량(value)을 위임한다.
    /// @param spender 위임받을 계정
    /// @param amount 위임할 통화량
    /// @return 정상처리 시 true
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    /// @author jhhong
    /// @notice 계정(recipient)에게 통화량(amount)을 전송한다.
    /// @param recipient 전송받을 계정
    /// @param amount 금액
    /// @return 정상처리 시 true
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    /// @author jhhong
    /// @notice 계정(sender)이 계정(recipient)에게 통화량(amount)을 전송한다.
    /// @param sender 전송할 계정
    /// @param recipient 전송받을 계정
    /// @param amount 금액
    /// @return 정상처리 시 true
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /// @author jhhong
    /// @notice 발행된 총 통화량을 반환한다.
    /// @return 총 통화량
    function totalSupply() public view returns (uint256) {
        return _supply;
    }
    
    /// @author jhhong
    /// @notice 계정(account)이 보유한 통화량을 반환한다.
    /// @param account 계정
    /// @return 계정(account)이 보유한 통화량
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    /// @author jhhong
    /// @notice 계정(approver)이 계정(spender)에게 위임한 통화량을 반환한다.
    /// @param approver 위임할 계정
    /// @param spender 위임받을 계정
    /// @return 계정(approver)이 계정(spender)에게 위임한 통화량
    function allowance(address approver, address spender) public view returns (uint256) {
        return _allowances[approver][spender];
    }
    
    /// @author jhhong
    /// @notice 계정(approver)이 계정(spender)에게 통화량(value)을 위임한다.
    /// @param approver 위임할 계정
    /// @param spender 위임받을 계정
    /// @param value 위임할 통화량
    function _approve(address approver, address spender, uint256 value) internal {
        require(approver != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[approver][spender] = value;
        emit Approval(approver, spender, value);
    }
    
    /// @author jhhong
    /// @notice 계정(sender)이 계정(recipient)에게 통화량(amount)을 전송한다.
    /// @param sender 위임할 계정
    /// @param recipient 위임받을 계정
    /// @param amount 금액
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /// @author jhhong
    /// @notice 통화량(amount)만큼 주조하여 계정(account)의 통화량에 더해준다.
    /// @dev ERC20Mint에 정의하면 private 속성인 supply와 balances에 access할 수 없어서 ERC20에 internal로 정의함.
    /// @param account 주조된 통화량을 받을 계정
    /// @param amount 주조할 통화량
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _supply = _supply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /// @author jhhong
    /// @notice 통화량(value)만큼 소각하여 계정(account)의 통화량에서 뺀다.
    /// @dev ERC20Mint에 정의하면 private 속성인 supply와 balances에 access할 수 없어서 ERC20에 internal로 정의함.
    /// @param account 통화량을 소각시킬 계정
    /// @param value 소각시킬 통화량
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(value, "ERC20: burn amount exceeds balance");
        _supply = _supply.sub(value);
        emit Transfer(account, address(0), value);
    }
}

// File: contracts/token/ERC20/ERC20Safe.sol

pragma solidity >=0.5.0 <0.6.0;



/// @title ERC20Safe
/// @notice Approve Bug Fix 버전 (중복 위임 방지)
/// @author jhhong
contract ERC20Safe is ERC20 {
    using SafeMath for uint256;

    /// @author jhhong
    /// @notice 계정(spender)에게 통화량(amount)을 위임한다.
    /// @dev 값이 덮어써짐을 방지하기 위해 기존에 위임받은 통화량이 0인 경우에만 호출을 허용한다.
    /// @param spender 위임받을 계정
    /// @param amount 위임할 통화량
    /// @return 정상처리 시 true
    function approve(address spender, uint256 amount) public returns (bool) {
        require((amount == 0) || (allowance(msg.sender, spender) == 0), "ERC20Safe: approve from non-zero to non-zero allowance");
        return super.approve(spender, amount);
    }

    /// @author jhhong
    /// @notice 계정(spender)에 위임된 통화량에 통화량(addedValue)를 더한값을 위임한다.
    /// @dev 위임된 통화량이 있을 경우, 통화량 증가는 상기 함수로 수행할 것
    /// @param spender 위임받을 계정
    /// @param addedValue 더해질 통화량
    /// @return 정상처리 시 true
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        uint256 amount = allowance(msg.sender, spender).add(addedValue);
        return super.approve(spender, amount);
    }
    
    /// @author jhhong
    /// @notice 계정(spender)에 위임된 통화량에 통화량(subtractedValue)를 뺀값을 위임한다.
    /// @dev 위임된 통화량이 있을 경우, 통화량 감소는 상기 함수로 수행할 것
    /// @param spender 위임받을 계정
    /// @param subtractedValue 빼질 통화량
    /// @return 정상처리 시 true
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 amount = allowance(msg.sender, spender).sub(subtractedValue, "ERC20: decreased allowance below zero");
        return super.approve(spender, amount);
    }
}

// File: contracts/DkargoToken.sol

pragma solidity >=0.5.0 <0.6.0;






/// @title DkargoToken
/// @notice 디카르고 토큰 컨트랙트 정의 (메인넷 deploy용)
/// @dev burn 기능 추가 (public)
/// @author jhhong
contract DkargoToken is Ownership, ERC20Safe, AddressChain, ERC165, DkargoPrefix {
    
    string private _name; // 토큰 이름
    string private _symbol; // 토큰 심볼
    
    /// @author jhhong
    /// @notice 컨트랙트 생성자이다.
    /// @dev 초기 발행량이 있을 경우, msg.sender를 홀더 리스트에 추가한다.
    /// @param name 토큰 이름
    /// @param symbol 토큰 심볼
    /// @param supply 초기 발행량
    constructor(string memory name, string memory symbol, uint256 supply) ERC20(supply) public {
        _setDkargoPrefix("token"); // 프리픽스 설정 (token)
        _registerInterface(0x946edbed); // INTERFACE ID 등록 (getDkargoPrefix)
        _name = name;
        _symbol = symbol;
        _linkChain(msg.sender);
    }

    /// @author jhhong
    /// @notice 본인의 보유금액 중 지정된 금액만큼 소각한다.
    /// @param amount 소각시킬 통화량
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @author jhhong
    /// @notice 토큰을 전송한다. (전송주체: msg.sender)
    /// @dev 전송 후 변경된 토큰 홀더 상태를 체인에 기록한다.
    /// @param to 토큰을 받을 주소
    /// @param value 전송 금액 (토큰량)
    function transfer(address to, uint256 value) public returns (bool) {
        bool ret = super.transfer(to, value);
        if(isLinked(msg.sender) && balanceOf(msg.sender) == 0) {
            _unlinkChain(msg.sender);
        }
        if(!isLinked(to) && balanceOf(to) > 0) {
            _linkChain(to);
        }
        return ret;
    }

    /// @author jhhong
    /// @notice 토큰을 전송한다. (전송주체: from)
    /// @dev 전송 후 변경된 토큰 홀더 상태를 체인에 기록한다.
    /// @param from 토큰을 보낼 계정
    /// @param to 토큰을 받을 계정
    /// @param value 전송 금액 (토큰량)
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        bool ret = super.transferFrom(from, to, value);
        if(isLinked(from) && balanceOf(from) == 0) {
            _unlinkChain(from);
        }
        if(!isLinked(to) && balanceOf(to) > 0) {
            _linkChain(to);
        }
        return ret;
    }

    /// @author jhhong
    /// @notice 토큰의 이름을 반환한다.
    /// @return 토큰 이름
    function name() public view returns(string memory) {
        return _name;
    }
    
    /// @author jhhong
    /// @notice 토큰의 심볼을 반환한다.
    /// @return 토큰 심볼
    function symbol() public view returns(string memory) {
        return _symbol;
    }

    /// @author jhhong
    /// @notice 토큰 데시멀을 반환한다.
    /// @dev 데시멀 값은 18 (peb) 로 고정이다.
    /// @return 토큰 데시멀
    function decimals() public pure returns(uint256) {
        return 18;
    }
}