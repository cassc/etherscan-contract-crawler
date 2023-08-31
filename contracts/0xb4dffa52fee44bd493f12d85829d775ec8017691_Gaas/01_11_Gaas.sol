// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity 0.7.5;

import "../libs/ERC20Permit.sol";
import "../libs/VaultOwned.sol";
import "../libs/interface/IaGaas.sol";

contract Gaas is ERC20Permit, VaultOwned {

    using SafeMath for uint256;
	address aGaas;
	bool isLBPComplete = false;
	
	uint256 maxSupply = 1_000_000 * 10**9;
	
    constructor(address aGaas_) ERC20("Congruent DAO Token", "Gaas", 9) {
		aGaas = aGaas_;
    }
	
	function migration() external {
		uint256 userBalance = IERC20(aGaas).balanceOf(msg.sender);
        IaGaas(aGaas).burnFrom(msg.sender, userBalance);
		_mint(msg.sender , userBalance);
    }
	
	//enable transfer
	function completeLBP() external onlyOwner(){
		isLBPComplete = true;
	}

    function mint(address account_, uint256 amount_) external onlyVault() {
        if(_totalSupply + amount_ > maxSupply)
			amount_ = maxSupply - _totalSupply;
		_mint(account_, amount_);
    }
	
	function setMaxSupply(uint256 newMaxSupply) external onlyOwner(){
		maxSupply = newMaxSupply;
	}
	
	function transfer(address account_, uint256 amount_) public override returns (bool) {
        //only enable transfer after add liquidity
		require(isLBPComplete || tx.origin == owner(), "no transfer");
		return super.transfer(account_, amount_);
    }
	
	function transferFrom(address from_, address to_, uint256 amount_) public override returns (bool) {
        //only enable transfer after add liquidity
		require(isLBPComplete || tx.origin == owner(), "no transfer");
		return super.transferFrom(from_, to_, amount_);
    }
	
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal virtual {
        uint256 decreasedAllowance_ =
            allowance(account_, msg.sender).sub(
                amount_,
                "ERC20: burn amount exceeds allowance"
            );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}