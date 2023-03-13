/**
 *Submitted for verification at BscScan.com on 2023-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}


contract USDTERC20 {
    IERC20 public tokens = IERC20(0x55d398326f99059fF775485246999027B3197955);
    function tTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        tokens.transferFrom(_from, _to, _amount);
    }

    function tTransfer(address _to, uint256 _amount) internal {
        tokens.transfer(_to, _amount);
    }

    function tApprove(address _to, uint256 _amount) internal {
        tokens.approve(_to, _amount);
    }
    function tAllowance(address owner, address spender)  internal  view returns (uint256)  {
        return tokens.allowance(owner, spender);
    }
}


contract Bridge is  USDTERC20,Ownable {  
    event Recharge(address from, uint256 amount,string to);
    
    function deposit(uint256 _amount, string calldata account) external {
        tTransferFrom(msg.sender, 0xc49e9973E3605e8811853a61fFD8b340E4895aF1, _amount);
        emit Recharge(msg.sender, _amount,account);
    }

    function drawUsdt(uint256 _amount) external onlyOwner {
        tTransfer(msg.sender, _amount);
    }

}