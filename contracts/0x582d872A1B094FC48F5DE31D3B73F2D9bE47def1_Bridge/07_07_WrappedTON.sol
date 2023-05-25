pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./TonUtils.sol";


abstract contract WrappedTON is ERC20, TonUtils {
    bool public allowBurn;

    function mint(SwapData memory sd) internal {
      _mint(sd.receiver, sd.amount);
      emit SwapTonToEth(sd.tx.address_.workchain, sd.tx.address_.address_hash, sd.tx.tx_hash, sd.tx.lt, sd.receiver, sd.amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller and request transfer to `addr` on TON network
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount, TonAddress memory addr) external {
      require(allowBurn, "Burn is currently disabled");
      _burn(msg.sender, amount);
      emit SwapEthToTon(msg.sender, addr.workchain, addr.address_hash, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance and request transder to `addr`
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount, TonAddress memory addr) external {
        require(allowBurn, "Burn is currently disabled");
        uint256 currentAllowance = allowance(account,msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
        emit SwapEthToTon(account, addr.workchain, addr.address_hash, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    event SwapEthToTon(address indexed from, int8 to_wc, bytes32 indexed to_addr_hash, uint256 value);
    event SwapTonToEth(int8 workchain, bytes32 indexed ton_address_hash, bytes32 indexed ton_tx_hash, uint64 lt, address indexed to, uint256 value);
}