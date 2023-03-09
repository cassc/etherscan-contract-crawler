pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UniswapV2ERC20Upgradeable is Initializable {
	string public name;
	string public symbol;
	uint8 public constant decimals = 18;
	uint256 public totalSupply;
	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	bytes32 public DOMAIN_SEPARATOR;
	// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 public constant PERMIT_TYPEHASH =
		0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
	mapping(address => uint256) public nonces;

	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function __UniswapV2ERC20Upgradeable__init(string memory name_, string memory symbol_)
		public
		virtual
		onlyInitializing
	{
		__UniswapV2ERC20Upgradeable__init_unchained(name_, symbol_);
	}

	function __UniswapV2ERC20Upgradeable__init_unchained(string memory name_, string memory symbol_)
		internal
		onlyInitializing
	{
		name = name_;
		symbol = symbol;
		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				keccak256(
					"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
				),
				keccak256(bytes(name)),
				keccak256(bytes("1")),
				block.chainid,
				address(this)
			)
		);
	}

	// function __UniswapV2ERC20_init_unchained() internal onlyInitializing {
	//     uint chainId;
	//     assembly {
	//         chainId := chainid
	//     }
	//     DOMAIN_SEPARATOR = keccak256(
	//         abi.encode(
	//             keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
	//             keccak256(bytes(name)),
	//             keccak256(bytes('1')),
	//             chainId,
	//             address(this)
	//         )
	//     );
	// }

	function _mint(address to, uint256 value) internal {
		totalSupply = totalSupply + value;
		balanceOf[to] = balanceOf[to] + value;
		emit Transfer(address(0), to, value);
	}

	function _burn(address from, uint256 value) internal {
		balanceOf[from] = balanceOf[from] - value;
		totalSupply = totalSupply - value;
		emit Transfer(from, address(0), value);
	}

	function _approve(
		address owner,
		address spender,
		uint256 value
	) private {
		allowance[owner][spender] = value;
		emit Approval(owner, spender, value);
	}

	function _transfer(
		address from,
		address to,
		uint256 value
	) private {
		balanceOf[from] = balanceOf[from] - value;
		balanceOf[to] = balanceOf[to] + value;
		emit Transfer(from, to, value);
	}

	function approve(address spender, uint256 value) external returns (bool) {
		_approve(msg.sender, spender, value);
		return true;
	}

	function transfer(address to, uint256 value) external returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool) {
		if (allowance[from][msg.sender] != type(uint256).max) {
			allowance[from][msg.sender] = allowance[from][msg.sender] - value;
		}
		_transfer(from, to, value);
		return true;
	}
}