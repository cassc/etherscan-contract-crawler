// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LOTTY Token
 * @author @Xirynx
 */
contract Lotty is ERC20, Ownable {
    //============================================//
    //                Definitions                 //
    //============================================//

    struct BipsFeeRate {
        uint256 feeFrom;
        uint256 feeTo;
    }

    //============================================//
    //                  Errors                    //
    //============================================//

    error InvalidFee();
    error InvalidAddress();

    //============================================//
    //                 Constants                  //
    //============================================//

    uint256 internal constant FEE_BIPS_BASE = 10_000;

    //============================================//
    //              State Variables               //
    //============================================//

    address public feeAccumulator;
    mapping(address => BipsFeeRate) public feeRate;
    mapping(address => bool) public isFeeExempt;

    //============================================//
    //              Admin Functions               //
    //============================================//

    /**
     * @notice Mints 1 trillion tokens to the deployer's address
     * @dev Deployer address is set as default fee accumulator
     * @dev Deployer address is exempt from all fees
     */
    constructor() ERC20("Lotty", "LOTTY") {
        feeAccumulator = msg.sender;
        isFeeExempt[msg.sender] = true;
        _mint(msg.sender, 1_000_000_000_000 * 10 ** decimals());
    }

    /**
     * @notice Sets the wallet that will accumulate trading fees
     * @dev Caller must be contract owner
     * @dev `wallet` cannot be zero address
     * @param wallet Address that will accumulate fees
     */
    function setFeeAccumulator(address wallet) public onlyOwner {
        if (wallet == address(0)) revert InvalidAddress();
        feeAccumulator = wallet;
    }

    /**
     * @notice Exempts/Un-exempts a wallet from any trading fees
     * @dev Caller must be contract owner
     * @dev `wallet` cannot be zero address
     * @param wallet Address to exempt/un-exempt from fees
     * @param isExempt Whether the wallet is exempt or not
     */
    function setFeeExempt(address wallet, bool isExempt) public onlyOwner {
        if (wallet == address(0)) revert InvalidAddress();
        isFeeExempt[wallet] = isExempt;
    }

    /**
     * @notice Sets a to/from fee rate for a specific address, e.g. Uniswap V2 Pair Address
     * @dev Caller must be contract owner
     * @dev `wallet` cannot be zero address
     * @dev Fee cannot be greater than 10%
     * @dev Fee rate is set in basis points
     * @param wallet Address to set a fee on
     * @param feeFrom Fee rate (in basis points) when transferring from `wallet`
     * @param feeTo Fee rate (in basis points) when transferring to `wallet`
     */
    function setFeeRate(address wallet, uint256 feeFrom, uint256 feeTo) public onlyOwner {
        if (wallet == address(0)) revert InvalidAddress();
        if (feeFrom > 1000) revert InvalidFee();
        if (feeTo > 1000) revert InvalidFee();
        feeRate[wallet] = BipsFeeRate(feeFrom, feeTo);
    }

    //============================================//
    //               ERC20 Overrides              //
    //============================================//

    /**
     * @notice Overridden ERC20 transfer to allow for trading fees.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        uint256 fee;
        if (isFeeExempt[owner] || isFeeExempt[to]) {
            fee = 0;
        } else {
            uint256 bipsFeeRate = feeRate[owner].feeFrom + feeRate[to].feeTo;
            fee = (bipsFeeRate * amount) / FEE_BIPS_BASE;
        }
        if (fee > 0) _transfer(owner, feeAccumulator, fee);
        _transfer(owner, to, amount - fee);
        return true;
    }

    /**
     * @notice Overridden ERC20 transferFrom to allow for trading fees.
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        uint256 fee;
        if (isFeeExempt[from] || isFeeExempt[to]) {
            fee = 0;
        } else {
            uint256 bipsFeeRate = feeRate[from].feeFrom + feeRate[to].feeTo;
            fee = (bipsFeeRate * amount) / FEE_BIPS_BASE;
        }
        if (fee > 0) _transfer(from, feeAccumulator, fee);
        _transfer(from, to, amount - fee);
        return true;
    }
}