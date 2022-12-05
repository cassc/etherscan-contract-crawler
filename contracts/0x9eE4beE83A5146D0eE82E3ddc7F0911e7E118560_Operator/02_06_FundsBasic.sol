// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./lib/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract FundsBasic {
    address internal constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    using TransferHelper for address;
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    // EVENTS
    // event Push(address token, uint256 amt);
    event Pull(address token, uint256 amt, address to);

    /**
     * @notice deposit token into contract
     * @param _token token address
     * @param _amt amount in decimals
     * @return amt actual amount
     */
    // function push(address _token, uint256 _amt)
    //     external
    //     payable
    //     virtual
    //     returns (uint256 amt);

    /**
     * @notice withdraw token from this contract
     * @param _token token address
     * @param _amt amount in decimals
     * @return amt actual amount
     */
    function pull(
        address _token,
        uint256 _amt,
        address _to
    ) external virtual returns (uint256 amt);

    // INTERNAL FUNCTION
    // function _push(address _token, uint256 _amt)
    //     internal
    //     virtual
    //     returns (uint256 amt)
    // {
    //     amt = _amt;

    //     if (_token != NATIVE_TOKEN) {
    //         require(msg.value == 0, "Invalid msg.value");
    //         _token.safeTransferFrom(msg.sender, address(this), _amt);
    //     } else {
    //         require(msg.value == _amt, "Invalid Amount");
    //     }
    //     emit Push(_token, _amt);
    // }

    function _pull(
        address _token,
        uint256 _amt,
        address _to
    ) internal noReentrant returns (uint256 amt) {
        amt = _amt;
        if (_token == NATIVE_TOKEN) {
            _to.safeTransferETH(_amt);
        } else {
            _token.safeTransfer(_to, _amt);
        }
        emit Pull(_token, _amt, _to);
    }

    /**
     * @notice get balances of the given tokens
     * @param _tokens array of token addresses, support NATIVE TOKEN
     * @return balances balance array
     */
    function getBalance(address[] memory _tokens)
        external
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == NATIVE_TOKEN) {
                balances[i] = address(this).balance;
            } else {
                balances[i] = IERC20(_tokens[i]).balanceOf(address(this));
            }
        }
    }

    receive() external payable {}
}