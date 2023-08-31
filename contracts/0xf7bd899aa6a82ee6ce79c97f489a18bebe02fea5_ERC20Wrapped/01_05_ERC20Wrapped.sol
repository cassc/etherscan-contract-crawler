// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "../Pausable.sol";
import "../Initializable.sol";

contract ERC20Wrapped is IERC20, Pausable, Initializable {
    event MinterUpdated(address sender, address oldMinter, address minter);

    address public minter;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    uint256 public override totalSupply;
    uint8 public override decimals;
    string public override name;
    string public override symbol;

    function init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address admin_
    ) external whenNotInitialized {
        require(admin_ != address(0), "zero address");

        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        admin = admin_;
        minter = admin_;
        pauser = admin_;
        isInited = true;
    }

    function transfer(address to_, uint256 amount_)
        external
        override
        whenNotPaused
        returns (bool)
    {
        require(to_ != address(0), "zero address");
        uint256 fromBalance_ = balanceOf[msg.sender];
        require(fromBalance_ >= amount_, "amount exceeds balance");
        unchecked {
            balanceOf[msg.sender] = fromBalance_ - amount_;
        }
        balanceOf[to_] += amount_;
        emit Transfer(msg.sender, to_, amount_);
        return true;
    }

    function approve(address spender_, uint256 amount_)
        external
        override
        returns (bool)
    {
        require(spender_ != address(0), "zero address");
        allowance[msg.sender][spender_] = amount_;
        emit Approval(msg.sender, spender_, amount_);
        return true;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external override whenNotPaused returns (bool) {
        require(from_ != address(0), "from zero address");
        require(to_ != address(0), "to zero address");
        _transfer(from_, msg.sender, amount_);
        balanceOf[to_] += amount_;
        emit Transfer(from_, to_, amount_);
        return true;
    }

    function burn(uint256 amount_) external whenNotPaused {
        uint256 accountBalance_ = balanceOf[msg.sender];
        require(accountBalance_ >= amount_, "amount exceeds balance");
        unchecked {
            balanceOf[msg.sender] = accountBalance_ - amount_;
        }
        totalSupply -= amount_;
        emit Transfer(msg.sender, address(0), amount_);
    }

    function burnFrom(address from_, uint256 amount_) external whenNotPaused {
        require(from_ != address(0), "zero address");
        _transfer(from_, msg.sender, amount_);
        totalSupply -= amount_;
        emit Transfer(from_, address(0), amount_);
    }

    function mint(address to_, uint256 amount_) external whenNotPaused {
        require(to_ != address(0), "zero address");
        require(minter == msg.sender, "only minter");
        totalSupply += amount_;
        balanceOf[to_] += amount_;
        emit Transfer(address(0), to_, amount_);
    }

    function updateMinter(address minter_) external onlyAdmin {
        require(minter_ != address(0), "zero address");
        emit MinterUpdated(msg.sender, minter, minter_);
        minter = minter_;
    }

    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal {
        uint256 currentAllowance_ = allowance[from_][to_];
        if (currentAllowance_ != type(uint256).max) {
            require(currentAllowance_ >= amount_, "insufficient allowance");
            unchecked {
                allowance[from_][to_] = currentAllowance_ - amount_;
                emit Approval(from_, to_, currentAllowance_ - amount_);
            }
        }
        uint256 fromBalance_ = balanceOf[from_];
        require(fromBalance_ >= amount_, "amount exceeds balance");
        unchecked {
            balanceOf[from_] = fromBalance_ - amount_;
        }
    }
}