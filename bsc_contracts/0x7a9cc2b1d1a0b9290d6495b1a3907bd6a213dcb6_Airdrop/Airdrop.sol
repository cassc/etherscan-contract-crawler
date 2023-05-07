/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Airdrop is Ownable {

    using SafeMath for uint256;

    function multiTransfer(address[] calldata _recipients, uint256[] calldata _values, address _tokenAddress) public onlyOwner returns (bool) {
        require(_recipients.length > 0, "Airdrop Error: min airdrop limit is 1 address");
        require(_recipients.length < 2001,"Airdrop Error: max airdrop limit is 2000 addresses"); // to prevent overflow
        require(_recipients.length == _values.length,"Airdrop Error: Mismatch between Address and value");

        IERC20 token = IERC20(_tokenAddress);
        uint256 SCCC = 0;
        for(uint i=0; i < _values.length; i++){
            SCCC = SCCC + _values[i];
        }
        require(token.balanceOf(address(this)) >= SCCC, "Airdrop Error: insufficient token");

        for(uint i = 0; i < _recipients.length; i++){
            token.transfer(_recipients[i], _values[i]);
        }

        return true;
    }

    function multiTransfer_nodecimals(address[] calldata _recipients, uint256[] calldata _values, address _tokenAddress) public onlyOwner returns (bool) {
        require(_recipients.length > 0, "Airdrop Error: min airdrop limit is 1 address");
        require(_recipients.length < 2001,"Airdrop Error: max airdrop limit is 2000 addresses"); // to prevent overflow
        require(_recipients.length == _values.length,"Airdrop Error: Mismatch between Address and value");

        IERC20Metadata token = IERC20Metadata(_tokenAddress);
        uint256 SCCC = 0;
        for(uint i=0; i < _values.length; i++){
            SCCC = SCCC + _values[i].mul(token.decimals());
        }
        require(token.balanceOf(address(this)) >= SCCC, "Airdrop Error: insufficient token");

        for(uint i = 0; i < _recipients.length; i++){
            token.transfer(_recipients[i], _values[i].mul(token.decimals()));
        }

        return true;
    }

    function multiTransfer_fixed(address[] calldata _recipients, uint256 _values, address _tokenAddress) public onlyOwner returns (bool) {
        require(_recipients.length > 0, "Airdrop Error: min airdrop limit is 1 address");
        require(_recipients.length < 2001,"Airdrop Error: max airdrop limit is 2000 addresses"); // to prevent overflow

        IERC20 token = IERC20(_tokenAddress);
        uint256 SCCC = _recipients.length.mul(_values);
        require(token.balanceOf(address(this)) >= SCCC, "Airdrop Error: insufficient token");

        for(uint i = 0; i < _recipients.length; i++){
            token.transfer(_recipients[i], _values);
        }
        return true;
    }

    function multiTransfer_fixed_nodecimals(address[] calldata _recipients, uint256 _values, address _tokenAddress) public onlyOwner returns (bool) {
        require(_recipients.length > 0, "Airdrop Error: min airdrop limit is 1 address");
        require(_recipients.length < 2001,"Airdrop Error: max airdrop limit is 2000 addresses"); // to prevent overflow

        IERC20Metadata token = IERC20Metadata(_tokenAddress);
        uint256 SCCC = _recipients.length.mul(_values).mul(token.decimals());
        require(token.balanceOf(address(this)) >= SCCC, "Airdrop Error: insufficient token");
        
        for(uint i = 0; i < _recipients.length; i++){
            token.transfer(_recipients[i], _values.mul(token.decimals()));
        }
        return true;
    }

    function claimBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount, address to) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function claimAllTokenToOwner(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

}