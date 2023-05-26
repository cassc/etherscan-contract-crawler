pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../common/SafeAmount.sol";
import "./IReshapableToken.sol";

abstract contract ReshapableERC20 is ERC20Burnable, IReshapableToken, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 public cap;
    uint256 constant RATIO_PADDING = 10 ** (18 + 9);
    uint256 constant DECIMALS = 10 ** 18;

    mapping (address=>uint256) internal _ratios;
    event Deposit(address from, address to, address source, uint256 sourceAmount,
     address target, uint256 targetAmount);

    /**
     * @dev ratio must be padded by the ratio_padding amount. 
     * For example if 1 wBTC (dec 8) -> 0.0001 (dec 18) SuperBTC, ratio is calculated as
     * Ratio =  0.0001 / 10**8 = 10**-12, then pad the ratio to make it positive. 10**-12 * 10**36
     * 10**8 wBTC -> 10**[(8 - 12 + 36) - 36 + 18]
     */
    function setRatio(address token, uint256 paddedRatio)
    external virtual onlyOwner() returns (bool) {
        _setRatio(token, paddedRatio);
        return true;
    }

    /**
     * Owner can set the cap. If the cap lower than supply it will have no effect.
     * Setting this to zero will open up the cap.
     */
    function setCap(uint256 _cap)
    external virtual onlyOwner() returns (bool) {
        cap = _cap;
        return true;
    }

    function _setRatio(address token, uint256 ratio) internal {
        require(token != address(0), "ReshapableERC20: Bad token");
        require(ratio != 0, "ReshapableERC20: Ratio must be set");
        require(ratio < 2 ** 127, "ReshapableERC20: Ratio too large");
        require(ratio.mul(DECIMALS) != 0, "ReshapableERC20: Ratio or token decimals too small");
        _ratios[token] = ratio.mul(DECIMALS);
    }

    function deposit(address token, uint256 amount) external virtual override returns(uint256) {
        return _deposit(msg.sender, msg.sender, token, amount);
    }

    function getInAmount(address token, uint256 outAmount)
        external virtual view returns(uint256) {
        require(token != address(0), "ReshapableERC20: Bad token");
        require(outAmount != 0, "ReshapableERC20: Amount was zero");
        require(outAmount < 2 ** 127, "ReshapableERC20: Amount too large");
        return _getInAmount(token, outAmount);
    }

    function _getInAmount(address token, uint256 amountOut)
        internal virtual view returns(uint256) {
        uint256 ratio = _ratios[token];
        require(ratio != 0, "ReshapableERC20: Unsupported token");
        return amountOut.mul(RATIO_PADDING).div(ratio);
    }

    function _deposit(address from, address to, address token, uint256 amount) internal returns (uint256) {
        require(from != address(0), "ReshapableERC20: Bad from");
        uint256 ratio = _ratios[token];
        require(ratio != 0, "ReshapableERC20: Unsupported token");
        require(amount != 0, "ReshapableERC20: Amount was zero");
        require(amount < 2 ** 127, "ReshapableERC20: Amount too large");
        uint256 _totalSupply = totalSupply();
        require(cap == 0 || _totalSupply < cap, "ReshapableERC20: Cap reached"); // Shortcut
        // Support fee-on-transfer tokens
        require(IERC20(token).allowance(from, address(this)) >= amount, "Not enough allowance");
        amount = SafeAmount.safeTransferFrom(token, from, address(this), amount);
        uint256 mintAmount = amount.mul(ratio).div(RATIO_PADDING);
        require(mintAmount != 0, "ReshapableERC20: Mint amount will be zero");
        uint256 newSupply = _totalSupply.add(mintAmount);
        if (cap != 0 && newSupply > cap) {
            uint256 extra = newSupply - cap;
            uint amountExtra = amount.mul(extra).div(mintAmount);
            amount = amount.sub(amountExtra);
            mintAmount = amount.mul(ratio).div(RATIO_PADDING);
            IERC20(token).safeTransfer(from, amountExtra);  // Sorry you will be hit by fee twice if token charges fee
        }
        _mint(to, mintAmount);
        emit Deposit(from, to, token, amount, address(this), mintAmount);
        return mintAmount;
    }
}