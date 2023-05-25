/**
 *Submitted for verification at Etherscan.io on 2020-05-13
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-13
*/
/*
 * source        https://github.com/lukso-network/rICO-smart-contracts
 * @name       LUKSO Token
 * @author      Micky Socaci <[email protected]>, Fabian Vogelsteller <@frozeman>
 * @license     Apachae 2.0
 */

/**
 * @dev Implementation of the `IERC777` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 *
 * Support for ERC20 is included in this contract, as specified by the EIP: both
 * the ERC777 and ERC20 interfaces can be safely used when interacting with it.
 * Both `IERC777.Sent` and `IERC20.Transfer` events are emitted on token
 * movements.
 *
 * Additionally, the `granularity` value is hard-coded to `1`, meaning that there
 * are no special restrictions in the amount of tokens that created, moved, or
 * destroyed. This makes integration with ERC20 applications seamless.
 */

pragma solidity ^0.5.0;


interface IERC777 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function granularity() external view returns (uint256);

    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address owner) external view returns (uint256);

    
    function send(address recipient, uint256 amount, bytes calldata data) external;

    
    function burn(uint256 amount, bytes calldata data) external;

    
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    
    function authorizeOperator(address operator) external;

    
    function revokeOperator(address operator) external;

    
    function defaultOperators() external view returns (address[] memory);

    
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

interface IERC777Recipient {
    
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

interface IERC777Sender {
    
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        
        
        
        
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

interface IERC1820Registry {
    
    function setManager(address account, address newManager) external;

    
    function getManager(address account) external view returns (address);

    
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

    
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);

    
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

contract ERC777 is IERC777, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    
    

    
    bytes32 constant private TOKENS_SENDER_INTERFACE_HASH =
        0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;

    
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH =
        0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

    
    address[] private _defaultOperatorsArray;

    
    mapping(address => bool) private _defaultOperators;

    
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

    
    mapping (address => mapping (address => uint256)) private _allowances;

    
    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) public {
        _name = name;
        _symbol = symbol;

        _defaultOperatorsArray = defaultOperators;
        for (uint256 i = 0; i < _defaultOperatorsArray.length; i++) {
            _defaultOperators[_defaultOperatorsArray[i]] = true;
        }

        
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }

    
    function name() public view returns (string memory) {
        return _name;
    }

    
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    
    function decimals() public pure returns (uint8) {
        return 18;
    }

    
    function granularity() public view returns (uint256) {
        return 1;
    }

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address tokenHolder) public view returns (uint256) {
        return _balances[tokenHolder];
    }

    
    function send(address recipient, uint256 amount, bytes calldata data) external {
        _send(msg.sender, msg.sender, recipient, amount, data, "", true);
    }

    
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");

        address from = msg.sender;

        _callTokensToSend(from, from, recipient, amount, "", "");

        _move(from, from, recipient, amount, "", "");

        _callTokensReceived(from, from, recipient, amount, "", "", false);

        return true;
    }

    
    function burn(uint256 amount, bytes calldata data) external {
        _burn(msg.sender, msg.sender, amount, data, "");
    }

    
    function isOperatorFor(
        address operator,
        address tokenHolder
    ) public view returns (bool) {
        return operator == tokenHolder ||
            (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
            _operators[tokenHolder][operator];
    }

    
    function authorizeOperator(address operator) external {
        require(msg.sender != operator, "ERC777: authorizing self as operator");

        if (_defaultOperators[operator]) {
            delete _revokedDefaultOperators[msg.sender][operator];
        } else {
            _operators[msg.sender][operator] = true;
        }

        emit AuthorizedOperator(operator, msg.sender);
    }

    
    function revokeOperator(address operator) external {
        require(operator != msg.sender, "ERC777: revoking self as operator");

        if (_defaultOperators[operator]) {
            _revokedDefaultOperators[msg.sender][operator] = true;
        } else {
            delete _operators[msg.sender][operator];
        }

        emit RevokedOperator(operator, msg.sender);
    }

    
    function defaultOperators() public view returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    )
    external
    {
        require(isOperatorFor(msg.sender, sender), "ERC777: caller is not an operator for holder");
        _send(msg.sender, sender, recipient, amount, data, operatorData, true);
    }

    
    function operatorBurn(address account, uint256 amount, bytes calldata data, bytes calldata operatorData) external {
        require(isOperatorFor(msg.sender, account), "ERC777: caller is not an operator for holder");
        _burn(msg.sender, account, amount, data, operatorData);
    }

    
    function allowance(address holder, address spender) public view returns (uint256) {
        return _allowances[holder][spender];
    }

    
    function approve(address spender, uint256 value) external returns (bool) {
        address holder = msg.sender;
        _approve(holder, spender, value);
        return true;
    }

   
    function transferFrom(address holder, address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");
        require(holder != address(0), "ERC777: transfer from the zero address");

        address spender = msg.sender;

        _callTokensToSend(spender, holder, recipient, amount, "", "");

        _move(spender, holder, recipient, amount, "", "");
        _approve(holder, spender, _allowances[holder][spender].sub(amount));

        _callTokensReceived(spender, holder, recipient, amount, "", "", false);

        return true;
    }

    
    function _mint(
        address operator,
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
    internal
    {
        require(account != address(0), "ERC777: mint to the zero address");

        
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        _callTokensReceived(operator, address(0), account, amount, userData, operatorData, true);

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    
    function _send(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    )
        private
    {
        require(from != address(0), "ERC777: send from the zero address");
        require(to != address(0), "ERC777: send to the zero address");

        _callTokensToSend(operator, from, to, amount, userData, operatorData);

        _move(operator, from, to, amount, userData, operatorData);

        _callTokensReceived(operator, from, to, amount, userData, operatorData, requireReceptionAck);
    }

    
    function _burn(
        address operator,
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    )
        internal
    {
        require(from != address(0), "ERC777: burn from the zero address");

        _callTokensToSend(operator, from, address(0), amount, data, operatorData);

        
        _totalSupply = _totalSupply.sub(amount);
        _balances[from] = _balances[from].sub(amount);

        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
        internal
    {
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    function _approve(address holder, address spender, uint256 value) private {
        
        
        
        require(spender != address(0), "ERC777: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
        private
    {
        address implementer = _erc1820.getInterfaceImplementer(from, TOKENS_SENDER_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
        }
    }

    
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    )
        private
    {
        address implementer = _erc1820.getInterfaceImplementer(to, TOKENS_RECIPIENT_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Recipient(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
        } else if (requireReceptionAck) {
            require(!to.isContract(), "ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        }
    }
}

interface ReversibleICO {
    function getParticipantReservedTokens(address) external view returns (uint256);
}

contract ReversibleICOToken is ERC777 {

    ReversibleICO public rICO;

    bool public frozen; 
    bool public initialized; 
    
    
    address public deployingAddress;
    address public tokenGenesisAddress; 
    address public migrationAddress; 
    address public freezerAddress; 
    address public rescuerAddress; 

    
    event SetRICOaddress(address indexed rICOAddress);
    event SetMigrationAddress(address indexed migrationAddress);
    event Frozen(address indexed freezerAddress);
    event Unfrozen(address indexed freezerAddress);
    event RemovedFreezer(address indexed freezerAddress);
    event ChangedRICO(address indexed rICOAddress, address indexed rescuerAddress);


    

    constructor(
        string memory name,
        string memory symbol,
        address[] memory _defaultOperators
    )
    ERC777(name, symbol, _defaultOperators)
    public
    {
        deployingAddress = msg.sender;
    }

    
    function init(
        address _ricoAddress,
        address _freezerAddress,
        address _rescuerAddress,
        address _tokenGenesisAddress,
        uint256 _initialSupply
    )
    public
    isNotInitialized
    onlyDeployingAddress
    {
        require(_freezerAddress != address(0), "_freezerAddress cannot be 0x");
        require(_rescuerAddress != address(0), "_rescuerAddress cannot be 0x");
        require(_tokenGenesisAddress != address(0), "_tokenGenesisAddress cannot be 0x");

        tokenGenesisAddress = _tokenGenesisAddress;
        freezerAddress = _freezerAddress;
        rescuerAddress = _rescuerAddress;

        _mint(_tokenGenesisAddress, _tokenGenesisAddress, _initialSupply, "", "");

        if(_ricoAddress != address(0)) {
            rICO = ReversibleICO(_ricoAddress);
            emit SetRICOaddress(_ricoAddress);
        }

        initialized = true;
    }

    function setRICOaddress(address _ricoAddress)
    public
    onlyTokenGenesisAddress
    {
        require(address(rICO) == address(0), "rICO address already set!");
        require(_ricoAddress != address(0), "rICO address cannot be 0x.");

        rICO = ReversibleICO(_ricoAddress);
        emit SetRICOaddress(_ricoAddress);
    }

    
    function setMigrationAddress(address _migrationAddress)
    public
    onlyTokenGenesisAddress
    {
        migrationAddress = _migrationAddress;
        emit SetMigrationAddress(migrationAddress);
    }


    
    function removeFreezer()
    public
    onlyFreezerAddress
    isNotFrozen
    {
        freezerAddress = address(0);
        emit RemovedFreezer(freezerAddress);
    }

    function freeze() public onlyFreezerAddress {
        frozen = true;
        emit Frozen(freezerAddress);
    }

    function unfreeze() public onlyFreezerAddress {
        frozen = false;
        emit Unfrozen(freezerAddress);
    }

    
    function changeRICO(address _newRicoAddress)
    public
    onlyRescuerAddress
    isFrozen
    {
        rICO = ReversibleICO(_newRicoAddress);
        emit ChangedRICO(_newRicoAddress, rescuerAddress);
    }

    
    function getLockedBalance(address _owner) public view returns(uint256) {
        
        if(address(rICO) != address(0)) {
            return rICO.getParticipantReservedTokens(_owner);
        } else {
            return 0;
        }
    }

    function getUnlockedBalance(address _owner) public view returns(uint256) {
        uint256 balance = balanceOf(_owner);

        
        if(address(rICO) != address(0)) {
            uint256 locked = rICO.getParticipantReservedTokens(_owner);

            if(balance > 0 && locked > 0) {
                if(balance >= locked) {
                    return balance.sub(locked);
                } else {
                    return 0;
                }
            }
        }

        return balance;
    }


    

    
    
    function _move(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _userData,
        bytes memory _operatorData
    )
    internal
    isNotFrozen
    isInitialized
    {

        
        if(
            _to == address(rICO) ||
            _to == migrationAddress
        ) {
            
            require(_amount <= balanceOf(_from), "Sending failed: Insufficient funds");

        } else {
            
            require(_amount <= getUnlockedBalance(_from), "Sending failed: Insufficient funds");
        }

        ERC777._move(_operator, _from, _to, _amount, _userData, _operatorData);
    }

    
    function _burn(
        address _operator,
        address _from,
        uint256 _amount,
        bytes memory _data,
        bytes memory _operatorData
    )
    internal
    isNotFrozen
    isInitialized
    {
        require(_amount <= getUnlockedBalance(_from), "Burning failed: Insufficient funds");
        ERC777._burn(_operator, _from, _amount, _data, _operatorData);
    }


    
    
    modifier onlyDeployingAddress() {
        require(msg.sender == deployingAddress, "Only the deployer can call this method.");
        _;
    }

    
    modifier onlyTokenGenesisAddress() {
        require(msg.sender == tokenGenesisAddress, "Only the tokenGenesisAddress can call this method.");
        _;
    }

    
    modifier onlyFreezerAddress() {
        require(msg.sender == freezerAddress, "Only the freezer address can call this method.");
        _;
    }

    
    modifier onlyRescuerAddress() {
        require(msg.sender == rescuerAddress, "Only the rescuer address can call this method.");
        _;
    }

    
    modifier isInitialized() {
        require(initialized == true, "Contract must be initialized.");
        _;
    }

    
    modifier isNotInitialized() {
        require(initialized == false, "Contract is already initialized.");
        _;
    }

    
    modifier isFrozen() {
        require(frozen == true, "Token contract not frozen.");
        _;
    }

    
    modifier isNotFrozen() {
        require(frozen == false, "Token contract is frozen!");
        _;
    }
}