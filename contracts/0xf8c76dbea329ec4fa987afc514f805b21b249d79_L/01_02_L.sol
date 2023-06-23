// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import './libraries/PoolAddress.sol';

contract L {

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 public immutable DOMAIN_SEPARATOR;

    bool public transferable;

    address public owner;

    string public name = "L";

    string public symbol = "L";

    uint8 public constant decimals = 18;

    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;

    mapping (address => mapping(address => uint256)) public allowance;

    mapping (address => uint256) public nonces;

    mapping (address => uint256) public antiSnipping;

    mapping (address => bool) public whitelist;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    event AntiSnippingSet(address indexed pool, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);

        _mint(msg.sender, 1000000000000 * 10 ** 18);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes('1')), chainId, address(this)));
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;

        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) external {
        balanceOf[msg.sender] -= amount;

        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(msg.sender, address(0), amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _beforeTokenTransfer(msg.sender, to, amount);

        balanceOf[msg.sender] -= amount;

        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _beforeTokenTransfer(from, to, amount);

        uint256 allowed = allowance[from][msg.sender];

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'EXPIRED');

        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR,
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) view internal {
        if (!transferable) {
            require(whitelist[from] || whitelist[to], "INVALID_WHITELIST");
        }
        
        if (antiSnipping[from] > 0) {
            require(balanceOf[to] + amount <= antiSnipping[from], "BALANCE_LIMIT");
        }
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }

    function setWhitelist(address account) external onlyOwner {
        whitelist[account] = !whitelist[account];
    }

    function setTransferable() external onlyOwner {
        transferable = !transferable;
    }

    function setAntiSnipping(address factory, address tokenA, address tokenB, uint24 fee, uint256 value) external onlyOwner returns (address pool) {
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(tokenA, tokenB, fee);

        pool = PoolAddress.computeAddress(factory, poolKey);

        antiSnipping[pool] = value;

        emit AntiSnippingSet(pool, value);
    }
}