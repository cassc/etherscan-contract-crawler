/**
 *Submitted for verification at BscScan.com on 2023-05-13
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Usdtify is Ownable {
    mapping(bytes32 => uint256) private validHashes;
    IERC20 private token;
    uint256 private constant AMOUNT = 100 * 10**18;

    event TokensUnlocked(address beneficiary, uint256 amount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        token = IERC20(_tokenAddress);
    }
    
    function addSecrets(bytes32[] memory _hashedSecrets, uint256[] memory _amounts) external onlyOwner {
        require(_hashedSecrets.length == _amounts.length, "Mismatched arrays");
        for (uint256 i = 0; i < _hashedSecrets.length; i++) {
            validHashes[_hashedSecrets[i]] = _amounts[i];
        }
    }

    function unlockTokens(string memory _secret, address _beneficiary) external {
        bytes32 secretHash = keccak256(abi.encodePacked(_secret));
        uint256 amount = validHashes[secretHash];
        require(amount > 0, "Invalid secret");
        require(token.balanceOf(address(this)) >= amount, "Insufficient tokens");

        validHashes[secretHash] = 0;

        token.transfer(_beneficiary, amount);

        emit TokensUnlocked(_beneficiary, amount);
    }

    function depositTokens(uint256 _amount) external {
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function rescueTokens(IERC20 _token) external onlyOwner {
        _token.transfer(owner(), _token.balanceOf(address(this)));
    }

    receive() external payable {}
}