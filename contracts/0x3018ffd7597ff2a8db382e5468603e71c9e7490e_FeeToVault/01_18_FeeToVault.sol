// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";
import "./interfaces/IBurner.sol";

interface IBurnerManager {
    function burners(address) external returns (IBurner);
}

interface SwapPair {
    function mintFee() external;

    function burn(address to) external returns (uint amount0, uint amount1);

    function balanceOf(address account) external returns (uint256);

    function transfer(address to, uint value) external returns (bool);
}

contract FeeToVault is Ownable2StepUpgradeable, PausableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("Operator_Role");

    address public burnerManager;
    address public underlyingBurner;
    address public HOPE;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _burnerManager, address _underlyingBurner, address _HOPE) public initializer {
        require(_burnerManager != address(0), "Zero address not valid");
        require(_underlyingBurner != address(0), "Zero address not valid");

        __Ownable2Step_init();
        __Pausable_init();
        burnerManager = _burnerManager;
        underlyingBurner = _underlyingBurner;
        HOPE = _HOPE;
    }

    function withdrawAdminFee(address pool) external whenNotPaused onlyRole(OPERATOR_ROLE) {
        _withdrawAdminFee(pool);
    }

    function withdrawMany(address[] memory pools) external whenNotPaused onlyRole(OPERATOR_ROLE) {
        for (uint256 i = 0; i < pools.length && i < 256; i++) {
            _withdrawAdminFee(pools[i]);
        }
    }

    function _withdrawAdminFee(address pool) internal {
        SwapPair pair = SwapPair(pool);
        pair.mintFee();
        uint256 tokenPBalance = SwapPair(pool).balanceOf(address(this));
        if (tokenPBalance > 0) {
            pair.transfer(address(pair), tokenPBalance);
            pair.burn(address(this));
        }
    }

    struct SwapBurnerInput {
        address token;
        uint256 amountIn;
        uint256 amountOutMin;
        address[] path;
    }

    function _burn(SwapBurnerInput calldata input) internal {
        uint256 balanceOfThis = IERC20Upgradeable(input.token).balanceOf(address(this));
        require(input.amountIn > 0 && input.amountIn <= balanceOfThis, "Wrong amount in");

        if (input.token == HOPE) {
            TransferHelper.doTransferOut(input.token, underlyingBurner, input.amountIn);
            return;
        }

        IBurner burner = IBurnerManager(burnerManager).burners(input.token);
        require(burner != IBurner(address(0)), "Set burner first");
        TransferHelper.doApprove(input.token, address(burner), input.amountIn);
        burner.burn(
            underlyingBurner,
            input.token,
            input.amountIn,
            input.amountOutMin,
            input.path
        );
    }

    function burn(SwapBurnerInput calldata input) external whenNotPaused onlyRole(OPERATOR_ROLE) {
        _burn(input);
    }

    function burnMany(SwapBurnerInput[] calldata inputs) external whenNotPaused onlyRole(OPERATOR_ROLE) {
        for (uint i = 0; i < inputs.length && i < 128; i++) {
            _burn(inputs[i]);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function isOperator(address _operator) external view returns (bool) {
        return hasRole(OPERATOR_ROLE, _operator);
    }

    function addOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Zero address not valid");
        _grantRole(OPERATOR_ROLE, _operator);
    }

    function removeOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Zero address not valid");
        _revokeRole(OPERATOR_ROLE, _operator);
    }
}