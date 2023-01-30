// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IERC20.sol";
import "./lib/SafeMath.sol";
import "./role/Member.sol";

import "./interface/IMinterPool.sol";
import "./interface/IInviteManager.sol";

contract TestToken is IERC20, Member {
    using SafeMath for uint256;

    event TransferEventReceiverAdd(address receiver);
    event TransferEventReceiverRemove(address receiver);

    string public override name;
    string public override symbol;
    uint8 public decimals;

    uint256 public override totalSupply;
    uint256 public remainedSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor() {
        name = "XXMMTT";

        symbol = "XMT";
        decimals = 18;
        remainedSupply = 50000000 * 1e18;

        mint(msg.sender, remainedSupply);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "zero address");
        require(remainedSupply >= amount, "mint too much");

        remainedSupply = remainedSupply.sub(amount);
        totalSupply = totalSupply.add(amount);
        balanceOf[to] = balanceOf[to].add(amount);

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) private {
        require(balanceOf[from] >= amount, "balance not enough");

        balanceOf[from] = balanceOf[from].sub(amount);
        totalSupply = totalSupply.sub(amount);

        emit Transfer(from, address(0), amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) external {
        require(allowance[from][msg.sender] >= amount, "allowance not enough");

        allowance[from][msg.sender] = allowance[from][msg.sender].sub(amount);
        _burn(from, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(balanceOf[from] >= amount, "balance not enough");

        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);

        _afterTransfer(from, to, amount);

        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        require(allowance[from][msg.sender] >= amount, "allowance not enough");

        allowance[from][msg.sender] = allowance[from][msg.sender].sub(amount);
        _transfer(from, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        require(spender != address(0), "zero address");

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function _afterTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (to == address(0)) {
            address minterPool = getMember("MinePool");
            if (minterPool != address(0)) {
                IMinterPool(minterPool).onTransferToBlackHole(from, to, amount);
            }
        } else {
            address inviteManager = getMember("InviteManager");
            if (inviteManager != address(0)) {
                IInviteManager(inviteManager).onTransferToNozeroAddress(
                    from,
                    to,
                    amount
                );
            }
        }
    }
}