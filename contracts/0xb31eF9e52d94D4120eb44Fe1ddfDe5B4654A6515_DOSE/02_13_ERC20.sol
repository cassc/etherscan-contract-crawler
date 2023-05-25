// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ManagedIdentity} from "@animoca/ethereum-contracts-core-1.1.1/contracts/metatx/ManagedIdentity.sol";
import {IERC165} from "@animoca/ethereum-contracts-core-1.1.1/contracts/introspection/IERC165.sol";
import {AddressIsContract} from "@animoca/ethereum-contracts-core-1.1.1/contracts/utils/types/AddressIsContract.sol";
import {IERC20} from "./IERC20.sol";
import {IERC20Detailed} from "./IERC20Detailed.sol";
import {IERC20Allowance} from "./IERC20Allowance.sol";
import {IERC20SafeTransfers} from "./IERC20SafeTransfers.sol";
import {IERC20BatchTransfers} from "./IERC20BatchTransfers.sol";
import {IERC20Metadata} from "./IERC20Metadata.sol";
import {IERC20Permit} from "./IERC20Permit.sol";
import {IERC20Receiver} from "./IERC20Receiver.sol";

/**
 * @title ERC20 Fungible Token Contract.
 */
abstract contract ERC20 is
    ManagedIdentity,
    IERC165,
    IERC20,
    IERC20Detailed,
    IERC20Metadata,
    IERC20Allowance,
    IERC20BatchTransfers,
    IERC20SafeTransfers,
    IERC20Permit
{
    using AddressIsContract for address;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 internal constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    uint256 public immutable deploymentChainId;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    mapping(address => uint256) public override nonces;

    string internal _name;
    string internal _symbol;
    uint8 internal immutable _decimals;
    string internal _tokenURI;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        string memory tokenURI_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _tokenURI = tokenURI_;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        deploymentChainId = chainId;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(chainId, bytes(name_));
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        // recompute the domain separator in case of fork and chainid update
        return chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId, bytes(_name));
    }

    function _calculateDomainSeparator(uint256 chainId, bytes memory name_) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(name_),
                    keccak256("1"),
                    chainId,
                    address(this)
                )
            );
    }

    /////////////////////////////////////////// ERC165 ///////////////////////////////////////

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Detailed).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId ||
            interfaceId == type(IERC20Allowance).interfaceId ||
            interfaceId == type(IERC20BatchTransfers).interfaceId ||
            interfaceId == type(IERC20SafeTransfers).interfaceId ||
            interfaceId == type(IERC20Permit).interfaceId;
    }

    /////////////////////////////////////////// ERC20Detailed ///////////////////////////////////////

    /// @dev See {IERC20Detailed-name}.
    function name() external view override returns (string memory) {
        return _name;
    }

    /// @dev See {IERC20Detailed-symbol}.
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @dev See {IERC20Detailed-decimals}.
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /////////////////////////////////////////// ERC20Metadata ///////////////////////////////////////

    /// @dev See {IERC20Metadata-tokenURI}.
    function tokenURI() external view override returns (string memory) {
        return _tokenURI;
    }

    /////////////////////////////////////////// ERC20 ///////////////////////////////////////

    /// @dev See {IERC20-totalSupply}.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /// @dev See {IERC20-balanceOf}.
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /// @dev See {IERC20-allowance}.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @dev See {IERC20-approve}.
    function approve(address spender, uint256 value) external virtual override returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

    /////////////////////////////////////////// ERC20 Allowance ///////////////////////////////////////

    /// @dev See {IERC20Allowance-increaseAllowance}.
    function increaseAllowance(address spender, uint256 addedValue) external virtual override returns (bool) {
        require(spender != address(0), "ERC20: zero address spender");
        address owner = _msgSender();
        uint256 allowance_ = _allowances[owner][spender];
        if (addedValue != 0) {
            uint256 newAllowance = allowance_ + addedValue;
            require(newAllowance > allowance_, "ERC20: allowance overflow");
            _allowances[owner][spender] = newAllowance;
            allowance_ = newAllowance;
        }
        emit Approval(owner, spender, allowance_);

        return true;
    }

    /// @dev See {IERC20Allowance-decreaseAllowance}.
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual override returns (bool) {
        require(spender != address(0), "ERC20: zero address spender");
        _decreaseAllowance(_msgSender(), spender, subtractedValue);
        return true;
    }

    /// @dev See {IERC20-transfer}.
    function transfer(address to, uint256 value) external virtual override returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    /// @dev See {IERC20-transferFrom}.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external virtual override returns (bool) {
        _transferFrom(_msgSender(), from, to, value);
        return true;
    }

    /////////////////////////////////////////// ERC20MultiTransfer ///////////////////////////////////////

    /// @dev See {IERC20MultiTransfer-multiTransfer(address[],uint256[])}.
    function batchTransfer(address[] calldata recipients, uint256[] calldata values) external virtual override returns (bool) {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");
        address sender = _msgSender();
        uint256 balance = _balances[sender];

        uint256 totalValue;
        uint256 selfTransferTotalValue;
        for (uint256 i; i != length; ++i) {
            address to = recipients[i];
            require(to != address(0), "ERC20: to zero address");

            uint256 value = values[i];
            if (value != 0) {
                uint256 newTotalValue = totalValue + value;
                require(newTotalValue > totalValue, "ERC20: values overflow");
                totalValue = newTotalValue;
                if (sender != to) {
                    _balances[to] += value;
                } else {
                    require(value <= balance, "ERC20: insufficient balance");
                    selfTransferTotalValue += value; // cannot overflow as 'selfTransferTotalValue <= totalValue' is always true
                }
            }
            emit Transfer(sender, to, value);
        }

        if (totalValue != 0 && totalValue != selfTransferTotalValue) {
            uint256 newBalance = balance - totalValue;
            require(newBalance < balance, "ERC20: insufficient balance"); // balance must be sufficient, including self-transfers
            _balances[sender] = newBalance + selfTransferTotalValue; // do not deduct self-transfers from the sender balance
        }
        return true;
    }

    /// @dev See {IERC20MultiTransfer-multiTransferFrom(address,address[],uint256[])}.
    function batchTransferFrom(
        address from,
        address[] calldata recipients,
        uint256[] calldata values
    ) external virtual override returns (bool) {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        uint256 balance = _balances[from];

        uint256 totalValue;
        uint256 selfTransferTotalValue;
        for (uint256 i; i != length; ++i) {
            address to = recipients[i];
            require(to != address(0), "ERC20: to zero address");

            uint256 value = values[i];

            if (value != 0) {
                uint256 newTotalValue = totalValue + value;
                require(newTotalValue > totalValue, "ERC20: values overflow");
                totalValue = newTotalValue;
                if (from != to) {
                    _balances[to] += value;
                } else {
                    require(value <= balance, "ERC20: insufficient balance");
                    selfTransferTotalValue += value; // cannot overflow as 'selfTransferTotalValue <= totalValue' is always true
                }
            }

            emit Transfer(from, to, value);
        }

        if (totalValue != 0 && totalValue != selfTransferTotalValue) {
            uint256 newBalance = balance - totalValue;
            require(newBalance < balance, "ERC20: insufficient balance"); // balance must be sufficient, including self-transfers
            _balances[from] = newBalance + selfTransferTotalValue; // do not deduct self-transfers from the sender balance
        }

        address sender = _msgSender();
        if (from != sender) {
            _decreaseAllowance(from, sender, totalValue);
        }

        return true;
    }

    /////////////////////////////////////////// ERC20SafeTransfers ///////////////////////////////////////

    /// @dev See {IERC20Safe-safeTransfer(address,uint256,bytes)}.
    function safeTransfer(
        address to,
        uint256 amount,
        bytes calldata data
    ) external virtual override returns (bool) {
        address sender = _msgSender();
        _transfer(sender, to, amount);
        if (to.isContract()) {
            require(IERC20Receiver(to).onERC20Received(sender, sender, amount, data) == type(IERC20Receiver).interfaceId, "ERC20: transfer refused");
        }
        return true;
    }

    /// @dev See {IERC20Safe-safeTransferFrom(address,address,uint256,bytes)}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 amount,
        bytes calldata data
    ) external virtual override returns (bool) {
        address sender = _msgSender();
        _transferFrom(sender, from, to, amount);
        if (to.isContract()) {
            require(IERC20Receiver(to).onERC20Received(sender, from, amount, data) == type(IERC20Receiver).interfaceId, "ERC20: transfer refused");
        }
        return true;
    }

    /////////////////////////////////////////// ERC20Permit ///////////////////////////////////////

    /// @dev See {IERC2612-permit(address,address,uint256,uint256,uint8,bytes32,bytes32)}.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override {
        require(owner != address(0), "ERC20: zero address owner");
        require(block.timestamp <= deadline, "ERC20: expired permit");
        bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer == owner, "ERC20: invalid permit");
        _approve(owner, spender, value);
    }

    /////////////////////////////////////////// Internal Functions ///////////////////////////////////////

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(spender != address(0), "ERC20: zero address spender");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) internal {
        uint256 allowance_ = _allowances[owner][spender];

        if (allowance_ != type(uint256).max && subtractedValue != 0) {
            // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
            uint256 newAllowance = allowance_ - subtractedValue;
            require(newAllowance < allowance_, "ERC20: insufficient allowance");
            _allowances[owner][spender] = newAllowance;
            allowance_ = newAllowance;
        }
        emit Approval(owner, spender, allowance_);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        require(to != address(0), "ERC20: to zero address");

        if (value != 0) {
            uint256 balance = _balances[from];
            uint256 newBalance = balance - value;
            require(newBalance < balance, "ERC20: insufficient balance");
            if (from != to) {
                _balances[from] = newBalance;
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    function _transferFrom(
        address sender,
        address from,
        address to,
        uint256 value
    ) internal {
        _transfer(from, to, value);
        if (from != sender) {
            _decreaseAllowance(from, sender, value);
        }
    }

    function _mint(address to, uint256 value) internal virtual {
        require(to != address(0), "ERC20: zero address");
        uint256 supply = _totalSupply;
        if (value != 0) {
            uint256 newSupply = supply + value;
            require(newSupply > supply, "ERC20: supply overflow");
            _totalSupply = newSupply;
            _balances[to] += value; // balance cannot overflow if supply does not
        }
        emit Transfer(address(0), to, value);
    }

    function _batchMint(address[] memory recipients, uint256[] memory values) internal virtual {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        uint256 totalValue;
        for (uint256 i; i != length; ++i) {
            address to = recipients[i];
            require(to != address(0), "ERC20: zero address");

            uint256 value = values[i];
            if (value != 0) {
                uint256 newTotalValue = totalValue + value;
                require(newTotalValue > totalValue, "ERC20: values overflow");
                totalValue = newTotalValue;
                _balances[to] += value; // balance cannot overflow if supply does not
            }
            emit Transfer(address(0), to, value);
        }

        if (totalValue != 0) {
            uint256 supply = _totalSupply;
            uint256 newSupply = supply + totalValue;
            require(newSupply > supply, "ERC20: supply overflow");
            _totalSupply = newSupply;
        }
    }

    function _burn(address from, uint256 value) internal virtual {
        if (value != 0) {
            uint256 balance = _balances[from];
            uint256 newBalance = balance - value;
            require(newBalance < balance, "ERC20: insufficient balance");
            _balances[from] = newBalance;
            _totalSupply -= value; // will not underflow if balance does not
        }
        emit Transfer(from, address(0), value);
    }

    function _burnFrom(address from, uint256 value) internal virtual {
        _burn(from, value);
        address sender = _msgSender();
        if (from != sender) {
            _decreaseAllowance(from, sender, value);
        }
    }

    function _batchBurnFrom(address[] memory owners, uint256[] memory values) internal virtual {
        uint256 length = owners.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        address sender = _msgSender();

        uint256 totalValue;
        for (uint256 i; i != length; ++i) {
            address from = owners[i];
            uint256 value = values[i];
            if (value != 0) {
                uint256 balance = _balances[from];
                uint256 newBalance = balance - value;
                require(newBalance < balance, "ERC20: insufficient balance");
                _balances[from] = newBalance;
                totalValue += value; // totalValue cannot overflow if the individual balances do not underflow
            }
            emit Transfer(from, address(0), value);

            if (from != sender) {
                _decreaseAllowance(from, sender, value);
            }
        }

        if (totalValue != 0) {
            _totalSupply -= totalValue; // _totalSupply cannot underfow as balances do not underflow
        }
    }
}