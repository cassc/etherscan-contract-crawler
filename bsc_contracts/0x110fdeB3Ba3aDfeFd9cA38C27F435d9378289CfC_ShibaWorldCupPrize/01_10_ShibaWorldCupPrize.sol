// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract ShibaWorldCupPrize is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Burnable;

    IERC20Burnable public immutable WINNER;
    IERC20 public immutable SWC;
    IERC20 public immutable BUSD;

    uint256 public constant POINTS_DIVISOR = 10**18;
    uint256 public swcRatio;
    uint256 public busdRatio;

    event Claimed(
        address account,
        uint256 amountIn,
        uint256 swcOut,
        uint256 busdOut
    );

    constructor(
        address _winner,
        address _swc,
        address _busd
    ) {
        WINNER = IERC20Burnable(_winner);
        SWC = IERC20(_swc);
        BUSD = IERC20(_busd);
    }

    /**
     * @dev Disallows direct send by setting a default function without the `payable` flag.
     */
    fallback() external {}

    function availableOutput() public view returns (uint256 swc, uint256 busd) {
        swc = SWC.balanceOf(address(this));
        busd = BUSD.balanceOf(address(this));
    }

    function claim(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Invalid amount");
        uint256 amountIn = _amount;
        address account = _msgSender();
        WINNER.safeTransferFrom(account, address(this), amountIn);
        uint256 swcOut = amountIn.mul(swcRatio).div(POINTS_DIVISOR);
        uint256 busdOut = amountIn.mul(busdRatio).div(POINTS_DIVISOR);
        (uint256 swc, uint256 busd) = availableOutput();
        require(swc >= swcOut && busd >= busdOut, "Ouputs mistake");
        SWC.safeTransfer(account, swcOut);
        BUSD.safeTransfer(account, busdOut);
        emit Claimed(account, amountIn, swcOut, busdOut);
    }

    function setRatios(uint256 _swcRatio, uint256 _busdRatio)
        external
        onlyOwner
    {
        require(_swcRatio > 0 && _busdRatio > 0, "Invalid ratios");
        swcRatio = _swcRatio;
        busdRatio = _busdRatio;
    }

    function burnWinner() external onlyOwner {
        uint256 balance = WINNER.balanceOf(address(this));
        WINNER.burn(balance);
    }

    function withdrawnTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_amount > 0, "Zero amount");
        require(_to != address(0) && _token != address(0), "Invalid address");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        _amount = _amount > balance ? balance : _amount;
        require(_amount > 0, "Zero balance");
        IERC20(_token).transfer(_to, _amount);
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }
}