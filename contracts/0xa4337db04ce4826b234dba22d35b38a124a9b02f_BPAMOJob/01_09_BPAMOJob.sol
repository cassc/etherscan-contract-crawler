// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../interfaces/external/curve/IMetaPool2.sol";
import "../../interfaces/IAMO.sol";
import "../../interfaces/IAMOMinter.sol";
import "../../interfaces/ICurveBPAMO.sol";

/// @title ConvexBPAMOJob
/// @author Angle Core Team
/// @notice Keeper permisionless contract to rebalance an AMO dealing with Curve pools where an
/// agXXX is paired with another pegged asset
/// @dev This contract can be called to mint on a Curve pool an agXXX when there are less of this agXXX than of the
/// other asset. Similarly, it can be called to withdraw when there are more of the agXXX than of the other asset.
contract BPAMOJob is Initializable {
    /// @notice Decimal normalizer between agTokens and the other token
    uint256 private constant _DECIMAL_NORMALIZER = 10**12;

    /// @notice Reference to the `AmoMinter` contract
    IAMOMinter public amoMinter;
    /// @notice Maps an address to whether it is whitelisted
    mapping(address => uint256) public whitelist;

    // =================================== ERRORS ==================================

    error ZeroAddress();
    error NotGovernor();
    error NotKeeper();

    // =============================== INITIALIZATION ==============================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Initializes the contract
    /// @param amoMinter_ Address of the AMOMinter
    function initialize(address amoMinter_) external initializer {
        if (amoMinter_ == address(0)) revert ZeroAddress();
        amoMinter = IAMOMinter(amoMinter_);
    }

    // ================================= MODIFIERS =================================

    /// @notice Checks whether the `msg.sender` is governor
    modifier onlyGovernor() {
        if (!amoMinter.isGovernor(msg.sender)) revert NotGovernor();
        _;
    }

    /// @notice Checks whether the `msg.sender` is approved
    modifier onlyKeeper() {
        if (whitelist[msg.sender] == 0) revert NotKeeper();
        _;
    }

    // =================================== SETTER ==================================

    /// @notice Toggles the approval right for an address
    /// @param whitelistCaller Address of the caller that needs right on `adjust`
    function toggleWhitelist(address whitelistCaller) public onlyGovernor {
        if (address(whitelistCaller) == address(0)) revert ZeroAddress();
        whitelist[whitelistCaller] = 1 - whitelist[whitelistCaller];
    }

    // =============================== VIEW FUNCTION ===============================

    /// @notice Returns the current state of the AMO that is to say whether liquidity should be added or removed
    /// and how much should be added or removed
    /// @param amo Address of the AMO to check
    /// @return addLiquidity Whether liquidity should be added or removed through the AMO on the Curve pool
    /// @return delta How much can be added or removed
    function currentState(ICurveBPAMO amo) public view returns (bool addLiquidity, uint256 delta) {
        (address curvePool, address agToken, uint256 indexAgToken) = amo.keeperInfo();
        return _currentState(curvePool, amo, agToken, indexAgToken);
    }

    // ============================== KEEPER FUNCTION ==============================

    /// @notice Adjusts the AMO by automatically minting and depositing, or withdrawing and burning the exact
    /// amount needed to put the Curve pool back at balance
    /// @param amo Address of the AMO to adjust
    /// @return addLiquidity Whether liquidity was added or removed after calling this function
    /// @return delta How much was added or removed from the Curve pool
    function adjust(ICurveBPAMO amo) external onlyKeeper returns (bool addLiquidity, uint256 delta) {
        (address curvePool, address agToken, uint256 indexAgToken) = amo.keeperInfo();
        (addLiquidity, delta) = _currentState(curvePool, amo, agToken, indexAgToken);

        uint256[] memory amounts = new uint256[](1);
        IERC20[] memory tokens = new IERC20[](1);
        bool[] memory isStablecoin = new bool[](1);
        address[] memory to = new address[](1);
        bytes[] memory data = new bytes[](1);
        amounts[0] = delta;
        tokens[0] = IERC20(agToken);
        isStablecoin[0] = true;
        data[0] = addLiquidity ? abi.encode(0) : abi.encode(type(uint256).max);

        if (addLiquidity) amoMinter.sendToAMO(IAMO(address(amo)), tokens, isStablecoin, amounts, data);
        else amoMinter.receiveFromAMO(IAMO(address(amo)), tokens, isStablecoin, amounts, to, data);
    }

    // ================================== INTERNAL =================================

    /// @notice Internal version of the `currentState` function
    function _currentState(
        address curvePool,
        ICurveBPAMO amo,
        address agToken,
        uint256 indexAgToken
    ) public view returns (bool addLiquidity, uint256 delta) {
        uint256[2] memory balances = IMetaPool2(curvePool).get_balances();
        // we need to mint agTokens
        if (balances[indexAgToken] < balances[1 - indexAgToken] * _DECIMAL_NORMALIZER)
            return (true, balances[1 - indexAgToken] * _DECIMAL_NORMALIZER - balances[indexAgToken]);
        else {
            uint256 currentDebt = amoMinter.amoDebts(IAMO(address(amo)), IERC20(address(agToken)));
            delta = balances[indexAgToken] - balances[1 - indexAgToken] * _DECIMAL_NORMALIZER;
            delta = currentDebt > delta ? delta : currentDebt;
            return (false, delta);
        }
    }
}