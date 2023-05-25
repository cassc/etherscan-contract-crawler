// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./UsingLiquidityProtectionService.sol";

contract SporesToken is
	UsingLiquidityProtectionService(0xBA2bF7693E0903B373077ace7b002Bd925913df2),
	ERC20PresetMinterPauser,
	Ownable
{
	uint256 private TOKEN_MAX_CAP;
	uint8 private TOKEN_DECIMALS;
	bytes32 public constant SENDER_ROLE = keccak256("SENDER_ROLE");

	// to be included in the variables at the beginning
	address public launchPool; // holds the address of the uniswap pool

	constructor(
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		uint256 _cap
	) ERC20PresetMinterPauser(_name, _symbol) {
		TOKEN_MAX_CAP = _cap;
		TOKEN_DECIMALS = _decimals;

		_setupRole(SENDER_ROLE, _msgSender());
		
		launchPool = getLiquidityPool();
	}

// function to be called only by the owner of the contract. This will add the account to the list of addresses that can send the tokens before liquidity addition
	function addSender(address account) external onlyOwner { 
		_setupRole(SENDER_ROLE, account);
	}

	modifier launchRestrict(address sender) {
		// check if the uniswap pool tokens count is 0. If balance is 0, there are no lp tokens yet.
		// When there are no LP tokens, allow only those who has sender role to send tokens.
		if (balanceOf(launchPool) == 0) { 
			require(hasRole(SENDER_ROLE, sender),"Token: transfers are disabled"); 
		}
		_;
	}

	// Add launchRestrict modifier on the transfer function, all transfer transactions go through this
	function _transfer(address sender, address recipient, uint256 amount) internal override launchRestrict(sender) {
		super._transfer(sender, recipient, amount);
	}

	/**
	 * @dev Returns the cap on the token's total supply.
	 */
	function cap() public view returns (uint256) {
		return TOKEN_MAX_CAP;
	}

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 */
	function decimals() public view virtual override returns (uint8) {
		return TOKEN_DECIMALS;
	}

	/**
	 * @dev Creates `amount` new tokens for `to`.
	 *
	 * See {ERC20-_mint}.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `MINTER_ROLE`.
	 */
	function mint(address to, uint256 amount) public virtual override {
		require(
			ERC20.totalSupply() + amount <= cap(),
			"ERC20Capped: cap exceeded"
		);
		require(
			hasRole(MINTER_ROLE, _msgSender()),
			"ERC20PresetMinterPauser: must have minter role to mint"
		);
		_mint(to, amount);
	}

	/**
	 * @dev Add minter role of token contract to `to` address.
	 *
	 * See {ERC20-_setupRole}.
	 *
	 * Requirements:
	 *
	 * - the caller must have the owner of token contract.
	 */
	function addMinterRoleTo(address to) public onlyOwner {
		_setupRole(MINTER_ROLE, to);
	}

	/**
	 * @dev these function use to integrate with anti bot protection
	 */
	function token_transfer(
		address _from,
		address _to,
		uint256 _amount
	) internal override {
		_transfer(_from, _to, _amount); // Expose low-level token transfer function.
	}

	function token_balanceOf(address _holder)
		internal
		view
		override
		returns (uint256)
	{
		return balanceOf(_holder); // Expose balance check function.
	}

	function protectionAdminCheck() internal view override onlyOwner {} // Must revert to deny access.

	function uniswapVariety() internal pure override returns (bytes32) {
		return UNISWAP; // UNISWAP / PANCAKESWAP / QUICKSWAP.
	}

	function uniswapVersion() internal pure override returns (UniswapVersion) {
		return UniswapVersion.V2; // V2 or V3.
	}

	function uniswapFactory() internal pure override returns (address) {
		return 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // Replace with the correct address.
	}

	function _beforeTokenTransfer(
		address _from,
		address _to,
		uint256 _amount
	) internal override {
		super._beforeTokenTransfer(_from, _to, _amount);
		LiquidityProtection_beforeTokenTransfer(_from, _to, _amount);
	}

	function protectionChecker() internal view override returns (bool) {
		return ProtectionSwitch_manual(); // Switch off protection by calling disableProtection(); from owner. Default.
	}

	// This token will be pooled in pair with:
	function counterToken() internal pure override returns (address) {
		return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
		// return 0xc778417E063141139Fce010982780140Aa0cD5Ab; // WETH9
	}
}