// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/* ROOTKIT:
A standard ERC20 with an extra hook: An installable transfer
gate allowing for token tax and burn on transfer
*/

import "./ERC20.sol";
import "./ITransferGate.sol";
import "./SafeMath.sol";
import "./TokensRecoverable.sol";
import "./IGatedERC20.sol";

abstract contract GatedERC20 is ERC20, TokensRecoverable, IGatedERC20
{
    using SafeMath for uint256;

    ITransferGate public override transferGate;
    address [] public tokenHolder;
    uint256 public numberOfTokenHolders = 0;
    mapping(address => bool) public exist;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol)
    {
    }

    function setTransferGate(ITransferGate _transferGate) public override ownerOnly()
    {
        transferGate = _transferGate;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override 
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        if(!exist[recipient]){
            tokenHolder.push(recipient);
            numberOfTokenHolders++;
            exist[recipient] = true;
        }
        ITransferGate _transferGate = transferGate;
        uint256 remaining = amount;
        if (address(_transferGate) != address(0)) 
        {
            address splitter = _transferGate.feeSplitter();
            uint256 fees = _transferGate.handleTransfer(msg.sender, sender, recipient, amount);
            if (fees > 0)
            {
               _balanceOf[splitter] = _balanceOf[splitter].add(fees);
                emit Transfer(sender, splitter, fees);
                remaining = remaining.sub(fees);
            }           
        }
        _balanceOf[sender] = _balanceOf[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balanceOf[recipient] = _balanceOf[recipient].add(remaining);
        emit Transfer(sender, recipient, remaining);
    }

    function burn(uint256 amount) public override
    {
        _burn(msg.sender, amount);
    }
}