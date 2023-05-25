// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./SafeMath.sol";


contract Deri {

    using SafeMath for uint256;

    event ChangeController(address oldController, address newController);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    string public constant name = "Deri";

    string public constant symbol = "DERI";

    uint8 public constant decimals = 18;

    uint256 public maxSupply = 1_000_000_000e18; // 1 billion

    uint256 public totalSupply;

    address public controller;

    mapping (address => uint256) internal balances;

    mapping (address => mapping (address => uint256)) internal allowances;

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    bytes32 public constant MINT_TYPEHASH = keccak256("Mint(address account,uint256 amount,uint256 nonce,uint256 deadline)");

    mapping (address => uint256) public nonces;

    constructor (address treasury) {
        uint256 treasuryAmount = 400_000_000e18; // 40% DERI into treasury
        totalSupply = treasuryAmount;
        balances[treasury] = treasuryAmount;
        emit Transfer(address(0), treasury, treasuryAmount);

        controller = msg.sender;
        emit ChangeController(address(0), controller);
    }

    // In order to prevent setting controller to an incorrect newController and forever lost the controll of this contract,
    // a signature of message keccak256(bytes(name)) from the newController must be provided.
    function setController(address newController, uint8 v, bytes32 r, bytes32 s) public {
        require(msg.sender == controller, "Deri.setController: only controller can set controller");
        require(v == 27 || v == 28, "Deri.setController: v not valid");
        bytes32 message = keccak256(bytes(name));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        address signatory = ecrecover(hash, v, r, s);
        require(signatory == newController, "Deri.setController: newController is not the signatory");

        emit ChangeController(controller, newController);
        controller = newController;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Deri.approve: approve to zero address");
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Deri.transfer: transfer to zero address");
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Deri.transferFrom: transfer to zero address");

        uint256 oldAllowance = allowances[from][msg.sender];
        if (msg.sender != from && oldAllowance != uint256(-1)) {
            uint256 newAllowance = oldAllowance.sub(amount, "Deri.transferFrom: amount exceeds allowance");
            allowances[from][msg.sender] = newAllowance;
            emit Approval(from, msg.sender, newAllowance);
        }

        _transfer(from, to, amount);
        return true;
    }

    function mint(address account, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        require(block.timestamp <= deadline, "Deri.mint: signature expired");

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), _getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(MINT_TYPEHASH, account, amount, nonces[account]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == controller, "Deri.mint: unauthorized");

        balances[account] = balances[account].add(amount);
        totalSupply = totalSupply.add(amount);

        require(totalSupply <= maxSupply, "Deri.mint: totalSupply exceeds maxSupply");
        emit Transfer(address(0), account, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        balances[from] = balances[from].sub(amount, "Deri._transfer: amount exceeds balance");
        balances[to] = balances[to].add(amount, "Deri._transfer: amount overflows");
        emit Transfer(from, to, amount);
    }

    function _getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

}