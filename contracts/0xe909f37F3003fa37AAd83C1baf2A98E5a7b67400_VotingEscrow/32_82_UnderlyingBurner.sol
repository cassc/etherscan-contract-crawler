// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";

interface IFeeDistributor {
    function burn(uint256 amount) external returns (bool);
}

interface ISwapRouter {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract UnderlyingBurner is Ownable2StepUpgradeable, PausableUpgradeable {
    event ToFeeDistributor(address indexed feeDistributor, uint256 amount);

    event RecoverBalance(address indexed token, address indexed emergencyReturn, uint256 amount);

    event SetEmergencyReturn(address indexed emergencyReturn);

    event SetRouters(ISwapRouter[] _routers);

    address public feeDistributor;
    address public gaugeFeeDistributor;
    address public emergencyReturn;
    address public hopeToken;

    ISwapRouter[] public routers;
    mapping(ISwapRouter => mapping(IERC20Upgradeable => bool)) public approved;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract constructor
     * @param _hopeToken HOPE token address
     * @param _feeDistributor total feeDistributor address
     * @param _gaugeFeeDistributor gauge feeDistributor address
     * @param _emergencyReturn Address to transfer `_token` balance to if this contract is killed
     */
    function initialize(
        address _hopeToken,
        address _feeDistributor,
        address _gaugeFeeDistributor,
        address _emergencyReturn
    ) external initializer {
        require(_hopeToken != address(0), "Invalid Address");
        require(_feeDistributor != address(0), "Invalid Address");
        require(_gaugeFeeDistributor != address(0), "Invalid Address");

        __Ownable2Step_init();

        hopeToken = _hopeToken;
        feeDistributor = _feeDistributor;
        gaugeFeeDistributor = _gaugeFeeDistributor;
        emergencyReturn = _emergencyReturn;

        IERC20Upgradeable(hopeToken).approve(feeDistributor, 2 ** 256 - 1);
        IERC20Upgradeable(hopeToken).approve(gaugeFeeDistributor, 2 ** 256 - 1);
    }

    /**
     * @notice  transfer HOPE to the fee distributor and  gauge fee distributor 50% each
     */
    function transferHopeToFeeDistributor() external whenNotPaused returns (uint256) {
        uint256 balance = IERC20Upgradeable(hopeToken).balanceOf(address(this));
        require(balance > 0, "insufficient balance");

        uint256 amount = balance / 2;

        IFeeDistributor(feeDistributor).burn(amount);
        IFeeDistributor(gaugeFeeDistributor).burn(amount);

        emit ToFeeDistributor(feeDistributor, amount);
        emit ToFeeDistributor(gaugeFeeDistributor, amount);
        return amount * 2;
    }

    /**
     * @notice Recover ERC20 tokens from this contract
     * @dev Tokens are sent to the emergency return address.
     * @return bool success
     */
    function recoverBalance(address token) external onlyOwner returns (bool) {
        uint256 amount = IERC20Upgradeable(token).balanceOf(address(this));
        TransferHelper.doTransferOut(token, emergencyReturn, amount);
        emit RecoverBalance(token, emergencyReturn, amount);
        return true;
    }

    /**
     * @notice Set routers
     * @param _routers routers implment ISwapRouter
     */
    function setRouters(ISwapRouter[] calldata _routers) external onlyOwner {
        require(_routers.length != 0, "invalid param");
        for (uint i = 0; i < _routers.length; i++) {
            require(address(_routers[i]) != address(0), "invalid address");
        }
        routers = _routers;
        emit SetRouters(_routers);
    }

    function burn(IERC20Upgradeable token, uint amount, uint amountOutMin) external {
        require(msg.sender == tx.origin, "not EOA");
        require(address(token) != hopeToken, "HOPE dosent need burn");

        ISwapRouter bestRouter = routers[0];
        uint bestExpected = 0;
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(hopeToken);

        for (uint i = 0; i < routers.length; i++) {
            uint[] memory expected = routers[i].getAmountsOut(amount, path);
            if (expected[1] > bestExpected) {
                bestExpected = expected[1];
                bestRouter = routers[i];
            }
        }

        require(bestExpected >= amountOutMin, "less than expected");
        if (!approved[bestRouter][token]) {
            TransferHelper.doApprove(address(token), address(bestRouter), type(uint).max);
            approved[bestRouter][token] = true;
        }

        bestRouter.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);
    }

    /**
     * @notice Set the token emergency return address
     * @param _addr emergencyReturn address
     */
    function setEmergencyReturn(address _addr) external onlyOwner {
        require(_addr != address(0), "CE000");
        emergencyReturn = _addr;
        emit SetEmergencyReturn(_addr);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}