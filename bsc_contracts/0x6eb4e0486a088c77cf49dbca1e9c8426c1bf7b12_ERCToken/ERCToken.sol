/**
 *Submitted for verification at BscScan.com on 2023-05-09
*/

pragma solidity ^0.4.26;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract SafeMath {
	function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
		c = a + b;
		require(c >= a);
	}
	function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
		require(b <= a);
		c = a - b;
	}
	function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
		if(a == 0) {
			return 0;
		}
		c = a * b;
		require(c / a == b);
	}
	function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
		require(b > 0);
		c = a / b;
	}
}

contract ERC20Interface {
	function totalSupply() public view returns (uint256);
	function balanceOf(address tokenOwner) public view returns (uint balance);
	function allowance(address tokenOwner, address spender) public view returns (uint remaining);
	function transfer(address to, uint tokens) public returns (bool success);
	function approve(address spender, uint tokens) public returns (bool success);
	function transferFrom(address from, address to, uint tokens) public returns (bool success);
	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
	function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
	address public owner;

	event OwnershipChange(address indexed _from, address indexed _to);

	constructor() public {
		owner=msg.sender;
	}
	modifier onlyOwner {
		require(msg.sender==owner,"METAQ: No ownership.");
		_;
	}
	function transferOwnership(address newOwner) external onlyOwner {
		require(newOwner!=address(0),"METAQ: Ownership to the zero address");
		emit OwnershipChange(owner,newOwner);
		owner=newOwner;
	}
}

contract ERCToken is ERC20Interface, Owned, SafeMath {
	string public name;
	string public symbol;
	uint8 public decimals = 8;
	uint256 public _totalSupply;

	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;


	constructor(
		uint256 initialSupply,
		string memory tokenName,
		string memory tokenSymbol
	) public {
		_totalSupply=safeMul(initialSupply,10 ** uint256(decimals)); 
		balances[msg.sender]=_totalSupply; 
		name=tokenName;   
		symbol=tokenSymbol;
        emit Transfer(msg.sender,msg.sender,_totalSupply);
	}

	function totalSupply() public view returns (uint) {
		return _totalSupply;
	}

	function balanceOf(address tokenOwner) public view returns (uint balance) {
		return balances[tokenOwner];
	}

	function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
		return allowed[tokenOwner][spender];
	}

	function _transfer(address _from, address _to, uint _value) internal {
        require(_to!=0x0,"METAQ: Transfer to the zero address");
        require(balances[_from]>=_value,"METAQ: Transfer Balance is insufficient.");
        balances[_from]=safeSub(balances[_from],_value);
        balances[_to]=safeAdd(balances[_to],_value);
        emit Transfer(_from,_to,_value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from,address _to,uint256 _value) public returns (bool success) {
 		require(_value<=allowed[_from][msg.sender],"METAQ: TransferFrom Allowance is insufficient.");  
		allowed[_from][msg.sender]=safeSub(allowed[_from][msg.sender],_value);
		_transfer(_from,_to,_value);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0),"METAQ: Approve to the zero address");
        require(spender != address(0),"METAQ: Approve to the zero address");
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

	function approve(address spender, uint256 tokens) public returns (bool success) {
		_approve(msg.sender,spender,tokens);
		return true;
	}

	function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
		require(spender!=address(0),"METAQ: ApproveAndCall to the zero address");
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
		return true;
	}

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(msg.sender,spender,safeAdd(allowed[msg.sender][spender],addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		_approve(msg.sender,spender,safeSub(allowed[msg.sender][spender],subtractedValue));
        return true;
    }

	function () external payable {
		revert();
	}

	function transferAnyERC20Token(address tokenAddress, uint tokens) external onlyOwner returns (bool success) {
		return ERC20Interface(tokenAddress).transfer(owner, tokens);
	}
}