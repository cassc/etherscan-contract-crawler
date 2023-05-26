// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { EIP712 } from "./external/openzeppelin/draft-EIP712.sol";
import { ECDSA } from "./external/openzeppelin/ECDSA.sol";

import { IERC20 } from "./interfaces/IERC20.sol";
import { Ownable } from "./abstract/Ownable.sol";
import { TransactionThrottler } from "./abstract/TransactionThrottler.sol";
import { Constants } from "./libraries/Constants.sol";

contract SynapseNetwork is IERC20, EIP712, Ownable, TransactionThrottler {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // keccak256("Transfer(address owner,address to,uint256 value,uint256 nonce,uint256 deadline)");
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public constant TRANSFER_TYPEHASH = 0x42ce63790c28229c123925d83266e77c04d28784552ab68b350a9003226cbd59;
    mapping(address => uint256) public override nonces;

    mapping(address => bool) private _excludedFromFees;
    // Basis points means divide by 10,000 to get decimal
    uint256 private constant MAX_TRANSFER_FEE_BASIS_POINTS = 1000;
    uint256 private constant BASIS_POINTS_MULTIPLIER = 10000;
    uint256 public transferFeeBasisPoints;
    address public feeContract;

    event MarkedExcluded(address indexed account, bool isExcluded);
    event FeeBasisPoints(uint256 feeBasisPoints);
    event FeeContractChanged(address feeContract);

    constructor(address _admin) EIP712(Constants.getName(), "1") {
        transferFeeBasisPoints = 50;
        setExcludedFromFees(_admin, true);

        _setOwner(_admin);

        _balances[_admin] = Constants.getTotalSupply();
        emit Transfer(address(0), _admin, Constants.getTotalSupply());
    }

    function name() external pure returns (string memory) {
        return Constants.getName();
    }

    function symbol() external pure returns (string memory) {
        return Constants.getSymbol();
    }

    function decimals() external pure override returns (uint8) {
        return Constants.getDecimals();
    }

    function totalSupply() external pure override returns (uint256) {
        return Constants.getTotalSupply();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        if (currentAllowance < type(uint256).max) {
            // DEXes can use max allowance
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private transactionThrottler(sender, recipient, amount) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount is 0");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        uint256 fee;
        if (feeContract != address(0) && transferFeeBasisPoints > 0 && !_excludedFromFees[sender] && !_excludedFromFees[recipient]) {
            fee = (amount * transferFeeBasisPoints) / BASIS_POINTS_MULTIPLIER;
            _balances[feeContract] += fee;
            emit Transfer(sender, feeContract, fee);
        }

        uint256 sendAmount = amount - fee;
        _balances[sender] -= amount;
        _balances[recipient] += sendAmount;
        emit Transfer(sender, recipient, sendAmount);
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function permit(
        address _owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // Revert faster here then later on signature (gas saving for user)
        require(_owner != address(0), "ERC20Permit: Permit from zero address");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, _owner, spender, value, nonces[_owner]++, deadline));
        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == _owner, "ERC20Permit: invalid signature");

        _approve(_owner, spender, value);
    }

    function transferWithPermit(
        address _owner,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (bool) {
        // Revert faster here then later on signature (gas saving for user)
        require(_owner != address(0) && to != address(0), "ERC20Permit: Zero address");
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(TRANSFER_TYPEHASH, _owner, to, value, nonces[_owner]++, deadline));
        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == _owner, "ERC20Permit: invalid signature");

        _transfer(_owner, to, value);
        return true;
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _excludedFromFees[account];
    }

    function setExcludedFromFees(address account, bool isExcluded) public onlyOwner {
        require(account != address(0), "Zero address");
        _excludedFromFees[account] = isExcluded;
        emit MarkedExcluded(account, isExcluded);
    }

    function setTransferFeeBasisPoints(uint256 fee) external onlyOwner {
        require(fee <= MAX_TRANSFER_FEE_BASIS_POINTS, "Fee is outside of range 0-1000");
        transferFeeBasisPoints = fee;
        emit FeeBasisPoints(transferFeeBasisPoints);
    }

    function changeFeeContract(address newContract) external onlyOwner {
        feeContract = newContract;
        emit FeeContractChanged(feeContract);
    }
}