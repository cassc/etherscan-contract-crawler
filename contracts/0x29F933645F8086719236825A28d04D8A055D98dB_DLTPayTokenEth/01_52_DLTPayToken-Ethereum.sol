// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@arbitrum/token-bridge-contracts/contracts/tokenbridge/ethereum/gateway/L1CustomGateway.sol";
import "@arbitrum/token-bridge-contracts/contracts/tokenbridge/ethereum/gateway/L1GatewayRouter.sol";

// ---------------------------------------------------------------- //
// Support for arbitrum
interface IL1CustomGateway {
    function registerTokenToL2(
        address _l2Address,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress
    ) external payable returns (uint256);
}

interface IGatewayRouter2 {
    function setGateway(
        address _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress
    ) external payable returns (uint256);
}

// ---------------------------------------------------------------- //

contract DLTPayTokenEth is ERC20, ERC20Burnable, Pausable, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant SENDER_ROLE = keccak256("SENDER_ROLE");

    // ---------------------------------------------------------------- //
    // Support for arbitrum
    address public gateway;
    address public router;
    bool private shouldRegisterGateway;

    // ---------------------------------------------------------------- //
    // Support for anyswap/multichain.org
    // according to https://docs.multichain.org/developer-guide/how-to-develop-under-anyswap-erc20-standards
    // and https://github.com/anyswap/chaindata/blob/main/AnyswapV6ERC20.sol
    address public immutable underlying;

    event LogSwapin(
        bytes32 indexed txhash,
        address indexed account,
        uint amount
    );
    event LogSwapout(
        address indexed account,
        address indexed bindaddr,
        uint amount
    );

    function mint(
        address to,
        uint256 amount
    ) external onlyRole(BRIDGE_ROLE) returns (bool) {
        _mint(to, amount);
        return true;
    }

    function burn(
        address from,
        uint256 amount
    ) external onlyRole(BRIDGE_ROLE) returns (bool) {
        _burn(from, amount);
        return true;
    }

    // For backwards compatibility
    function Swapin(
        bytes32 txhash,
        address account,
        uint256 amount
    ) external onlyRole(BRIDGE_ROLE) returns (bool) {
        _mint(account, amount);
        emit LogSwapin(txhash, account, amount);
        return true;
    }

    // For backwards compatibility
    function Swapout(uint256 amount, address bindaddr) external returns (bool) {
        require(bindaddr != address(0), "AnyswapV6ERC20: address(0)");
        _burn(msg.sender, amount);
        emit LogSwapout(msg.sender, bindaddr, amount);
        return true;
    }

    // ---------------------------------------------------------------- //
    // Support for arbitrum
    /// @dev we only set shouldRegisterGateway to true when in `registerTokenOnL2`
    function isArbitrumEnabled() external view returns (uint8) {
        require(shouldRegisterGateway, "NOT_EXPECTED_CALL");
        return uint8(0xb1);
    }

    function registerTokenOnL2(
        address l2CustomTokenAddress,
        uint256 maxSubmissionCostForCustomGateway,
        uint256 maxSubmissionCostForRouter,
        uint256 maxGasForCustomGateway,
        uint256 maxGasForRouter,
        uint256 gasPriceBid,
        uint256 valueForGateway,
        uint256 valueForRouter,
        address creditBackAddress
    ) public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        // we temporarily set `shouldRegisterGateway` to true for the callback in registerTokenToL2 to succeed
        bool prev = shouldRegisterGateway;
        shouldRegisterGateway = true;

        IL1CustomGateway(gateway).registerTokenToL2{value: valueForGateway}(
            l2CustomTokenAddress,
            maxGasForCustomGateway,
            gasPriceBid,
            maxSubmissionCostForCustomGateway,
            creditBackAddress
        );

        IGatewayRouter2(router).setGateway{value: valueForRouter}(
            gateway,
            maxGasForRouter,
            gasPriceBid,
            maxSubmissionCostForRouter,
            creditBackAddress
        );

        shouldRegisterGateway = prev;
    }

    function bridgeMint(
        address account,
        uint256 amount
    ) public onlyRole(BRIDGE_ROLE) {
        _mint(account, amount);
    }

    function bridgeBurn(
        address account,
        uint256 amount
    ) public onlyRole(BRIDGE_ROLE) {
        _burn(account, amount);
    }

    // ---------------------------------------------------------------- //

    constructor(
        address arb_router,
        address arb_gateway
    ) ERC20("DLTPAY", "DLTP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(SENDER_ROLE, msg.sender);
        underlying = address(0);
        router = arb_router;
        gateway = arb_gateway;
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function setArb(
        address arb_router,
        address arb_gateway
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        router = arb_router;
        gateway = arb_gateway;
    }

    function senderTransfer(
        address to,
        uint256 amount
    ) external onlyRole(SENDER_ROLE) whenPaused {
        _unpause();
        _transfer(msg.sender, to, amount);
        _pause();
    }
}