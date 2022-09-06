// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import "VM.sol";
import "EnumerableSet.sol";
import "IERC20.sol";
import "SafeERC20.sol";

/**
@title Trade Handler
@author yearn.finance
@notice TradeHandler is in charge of tracking which strategy wants to do certain
trade. The strategy registers what they have and what they want and wait for an
async trade. TradeHandler trades are executed by mechs through a weiroll VM.
*/

contract TradeHandler is VM {
    using EnumerableSet for EnumerableSet.AddressSet;

    address payable public governance;
    address payable public pendingGovernance;

    // Mechs are addresses authorized to execute trades
    mapping(address => bool) public mechs;

    event AddedMech(address mech);
    event RemovedMech(address mech);
    event TradeEnabled(address indexed seller, address indexed tokenIn, address indexed tokenOut);
    event TradeDisabled(address indexed seller, address indexed tokenIn, address indexed tokenOut);

    constructor(address payable _governance) {
        governance = _governance;
        mechs[_governance] = true;
    }

    function setGovernance(address payable _governance) external {
        require(msg.sender == governance);
        pendingGovernance = _governance;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance);
        governance = pendingGovernance;
        delete pendingGovernance;
    }

    function addMech(address _mech) external {
        require(msg.sender == governance);
        mechs[_mech] = true;
        emit AddedMech(_mech);
    }

    function removeMech(address _mech) external {
        require(msg.sender == governance);
        delete mechs[_mech];
        emit RemovedMech(_mech);
    }

    function enable(address _tokenIn, address _tokenOut) external {
        require(_tokenIn != address(0));
        require(_tokenOut != address(0));

        emit TradeEnabled(msg.sender, _tokenIn, _tokenOut);
    }

    function disable(address _tokenIn, address _tokenOut) external {
        _disable(msg.sender, _tokenIn, _tokenOut);
    }

    function disableByAdmin(
        address _strategy,
        address _tokenIn,
        address _tokenOut
    ) external {
        require(msg.sender == governance);
        _disable(_strategy, _tokenIn, _tokenOut);
    }

    function _disable(
        address _strategy,
        address _tokenIn,
        address _tokenOut
    ) internal {
        emit TradeDisabled(_strategy, _tokenIn, _tokenOut);
    }

    function execute(bytes32[] calldata commands, bytes[] memory state)
        external
        returns (bytes[] memory)
    {
        require(mechs[msg.sender]);
        return _execute(commands, state);
    }

    function sweep(address _token) external {
        require(msg.sender == governance);

        uint256 amount;
        if (_token == address(0)) {
            amount = address(this).balance;
            (bool success, ) = governance.call{value: amount}("");
            require(success, "!transfer");
        } else {
            amount = IERC20(_token).balanceOf(address(this));
            SafeERC20.safeTransfer(IERC20(_token), governance, amount);
        }
    }

    receive() external payable {}
}