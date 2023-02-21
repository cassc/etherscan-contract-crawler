// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../helpers/errors.sol";
import "../../ImplBase.sol";
import "../../interfaces/connext.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
}

contract Connext is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IConnextHandler public immutable router;
    address public immutable wETH;

    /**
    @notice Constructor sets the router address and registry address.
    */
    constructor(
        IConnextHandler _router,
        address _registry,
        address _weth
    ) ImplBase(_registry) {
        router = _router;
        wETH = _weth;
    }

    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256,
        bytes memory _data
    ) external payable override onlyRegistry nonReentrant {
        (uint32 dstChainDomain, uint256 slippage, bytes memory callData) = abi
            .decode(_data, (uint32, uint256, bytes));

        if (_token == NATIVE_TOKEN_ADDRESS) {
            IWETH(wETH).deposit{value: _amount}();
            IERC20(wETH).safeIncreaseAllowance(address(router), _amount);
            router.xcall{value: msg.value - _amount}(
                dstChainDomain,
                _receiverAddress,
                wETH,
                msg.sender,
                _amount,
                slippage,
                callData
            );
            return;
        }
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(address(router), _amount);

        router.xcall{value: msg.value}(
            dstChainDomain,
            _receiverAddress,
            _token,
            msg.sender,
            _amount,
            slippage,
            callData
        );
    }
}