// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IGatewayRouter} from "../interfaces/IGatewayRouter.sol";
import {ICustomGateway} from "../interfaces/ICustomGateway.sol";
import {Whitelistable} from "./Whitelistable.sol";

contract ArbUnionWrapper is ERC20, Whitelistable {
    using SafeERC20 for IERC20;

    address public immutable unionToken;
    address public immutable router;
    address public gateway;
    bool private shouldRegisterGateway;

    constructor(
        address _routerAddr,
        address _gatewayAddr,
        address _unionToken
    ) ERC20("Arb UNION Wrapper", "arbUNION") {
        router = _routerAddr;
        gateway = _gatewayAddr;
        unionToken = _unionToken;
        whitelist(gateway);
    }

    /**
     * Wrap UNION to create Arbitrum compatible token
     */
    function wrap(uint256 _amount) public returns (bool) {
        IERC20 _token = IERC20(unionToken);
        require(_token.balanceOf(address(msg.sender)) >= _amount, "Insufficient balance");
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
        if (allowance(msg.sender, gateway) < _amount) {
            _approve(msg.sender, gateway, type(uint256).max);
        }

        return true;
    }

    /**
     * Burn pegged token and return UNION
     */
    function unwrap(uint256 _amount) external returns (bool) {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        _burn(msg.sender, _amount);
        IERC20(unionToken).safeTransfer(msg.sender, _amount);
        return true;
    }

    /** Safety measure to transfer UNION to owner */
    function emergencyWithdraw() external onlyOwner returns (bool) {
        IERC20 token = IERC20(unionToken);
        uint256 balance = token.balanceOf(address(this));
        return token.transfer(msg.sender, balance);
    }

    function isArbitrumEnabled() external view returns (uint16) {
        require(shouldRegisterGateway, "NOT_EXPECTED_CALL");
        return uint16(0xa4b1);
    }

    function registerTokenOnL2(
        address l2CustomTokenAddress,
        uint256 maxSubmissionCostForCustomBridge,
        uint256 maxSubmissionCostForRouter,
        uint256 maxGas,
        uint256 gasPriceBid
    ) public payable onlyOwner {
        // we temporarily set `shouldRegisterGateway` to true for the callback in registerTokenToL2 to succeed
        bool prev = shouldRegisterGateway;
        shouldRegisterGateway = true;

        uint256 gas1 = maxSubmissionCostForCustomBridge + maxGas * gasPriceBid;
        uint256 gas2 = maxSubmissionCostForRouter + maxGas * gasPriceBid;
        require(msg.value == gas1 + gas2, "OVERPAY");

        ICustomGateway(gateway).registerTokenToL2{value: gas1}(
            l2CustomTokenAddress,
            maxGas,
            gasPriceBid,
            maxSubmissionCostForCustomBridge
        );

        IGatewayRouter(router).setGateway{value: gas2}(gateway, maxGas, gasPriceBid, maxSubmissionCostForRouter);

        // slither-disable-next-line reentrancy-eth
        shouldRegisterGateway = prev;
    }

    function getChainId() public view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}