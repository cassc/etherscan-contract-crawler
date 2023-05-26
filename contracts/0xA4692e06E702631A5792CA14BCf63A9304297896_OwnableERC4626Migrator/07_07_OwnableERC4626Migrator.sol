// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Ownable} from "oz/access/Ownable.sol";

/**
 * @title ERC4626Migrator
 * @author LHerskind
 * @notice Contract to be used for distributing tokens based on their shares of the total supply.
 * Practically LP tokens that can be migrated to WETH, DAI, and USDC.
 * WETH, Dai and USDC held by the contract will be used to distribute to users, so that the contract
 * is funded before users start using it, as they otherwise could simply sacrifice their share of the
 * assets.
 * With admin functions, allowing an administrator to recover funds from the contract, update rates or
 * emulate migrations by users, if they for some reason are unable to migrate.
 */
contract OwnableERC4626Migrator is Ownable, ReentrancyGuard {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    error InvalidAcceptanceToken(address user, bytes32 acceptanceToken);

    event MigratedAndAgreed(address indexed user, uint256 amount, uint256 wethAmount, uint256 daiAmount, uint256 usdcAmount);
    event MigratedByAdmin(address indexed user, uint256 amount, uint256 wethAmount, uint256 daiAmount, uint256 usdcAmount);

    /**********
    By clicking "I agree to the terms to claim redemption" on the euler.finance web interface or executing the EulerClaims smart contract and accepting the redemption, I hereby irrevocably and unconditionally release all claims I (or my company or other separate legal entity) may have against Euler Labs, Ltd., the Euler Foundation, the Euler Decentralized Autonomous Organization, members of the Euler Decentralized Autonomous Organization, and any of their agents, affiliates, officers, employees, or principals related to this matter, whether such claims are known or unknown at this time and regardless of how such claims arise and the laws governing such claims (which shall include but not be limited to any claims arising out of Euler’s terms of use).  This release constitutes an express and voluntary binding waiver and relinquishment to the fullest extent permitted by law.  If I am acting for or on behalf of a company (or other such separate entity), by clicking "I agree to the terms to claim redemption" on the euler.finance web interface or executing the EulerClaims smart contract and accepting the redemption and agreement, I confirm that I am duly authorised to enter into this contract on its behalf.

    This agreement and all disputes relating to or arising under this agreement (including the interpretation, validity or enforcement thereof) will be governed by and subject to the laws of England and Wales and the courts of London, England shall have exclusive jurisdiction to determine any such dispute.  To the extent that the terms of this release are inconsistent with any previous agreement and/or Euler’s terms of use, I accept that these terms take priority and, where necessary, replace the previous terms.
    **********/

    // The following is a hash of the above terms and conditions.
    // To calculate it, take the raw contents of https://github.com/euler-xyz/euler-claims-contract/blob/master/terms-and-conditions.txt
    // and feed it into keccak256 function.
    //
    // By sending a transaction and claiming the redemption tokens, I understand and manifest my assent
    // and agreement to be bound by the enforceable contract on this page, and agree that all claims or
    // disputes under this agreement will be resolved exclusively by the courts of London, England in
    // accordance with the laws of England and Wales. If I am acting for or on behalf of a company (or
    // other such separate entity), by signing and sending a transaction I confirm that I am duly
    // authorised to enter into this contract on its behalf.
    bytes32 public constant termsAndConditionsHash = 0x427a506ff6e15bd1b7e4e93da52c8ec95f6af1279618a2f076946e83d8294996;

    ERC20 public constant WETH = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ERC20 public constant DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ERC20 public constant USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // Only really safe it not possible to mint or burn tokens with an admin.
    // If admin can burn and mint. Admin could simply mint tokens and exit or burn from the contract to inflate.
    ERC20 public immutable ERC4626Token;

    // @todo Don't need to be a full 256 bits each
    uint256 public wethPerERC4626;
    uint256 public daiPerERC4626;
    uint256 public usdcPerERC4626;

    constructor(ERC20 _erc4626) {
        ERC4626Token = _erc4626;
    }

    /**
     * @notice Updates the asset per ERC4626 token rate based on the floating supply
     * Floating supply provided to allow owner to account for asset held by this contract + euler
     * multisig or other contracts.
     * @param _floatingSupply - The supply of ERC4626 tokens that are "redeemable" for assets
     */
    function updateRates(uint256 _floatingSupply) external onlyOwner returns (uint256, uint256, uint256) {
        if (_floatingSupply == 0) {
            return (0, 0, 0);
        }

        wethPerERC4626 = WETH.balanceOf(address(this)).mulDivDown(1e18, _floatingSupply);
        daiPerERC4626 = DAI.balanceOf(address(this)).mulDivDown(1e18, _floatingSupply);
        usdcPerERC4626 = USDC.balanceOf(address(this)).mulDivDown(1e18, _floatingSupply);
        return (wethPerERC4626, daiPerERC4626, usdcPerERC4626);
    }

    /**
     * @notice Admin function to recover funds from the contract
     * @dev Only owner can call this function
     * @param _token - The token to recover
     * @param _amount - The amount of the token to recover
     * @param _to - The address to send the recovered funds to
     */
    function adminRecover(address _token, uint256 _amount, address _to) external onlyOwner {
        ERC20(_token).safeTransfer(_to, _amount);
    }

    /**
     * @notice Admin function simulate migration of ERC4626 token to WETH, DAI, and USDC without
     * actually sacrificing ERC4626.
     * @param _amount - The amount of ERC4626 token to be migrated
     * @param _to - The address to send the recovered funds to
     * @return The amount of weth sent to the user
     * @return The amount of dai sent to the user
     * @return The amount of usdc sent to the user
     */
    function adminMigrate(uint256 _amount, address _to) external onlyOwner returns (uint256, uint256, uint256) {
        return _exitFunds(_amount, _to, false);
    }

    /**
     * @notice Migrates ERC4626 token to WETH, DAI, and USDC
     * @dev Reentry guard.
     * @param _amount - The amount of ERC4626 token to be migrated
     * @param _acceptanceToken -Custom token demonstrating the caller's agreement with the Terms and Conditions of the claim
     * @return The amount of weth sent to the user
     * @return The amount of dai sent to the user
     * @return The amount of usdc sent to the user
     */
    function migrate(uint256 _amount, bytes32 _acceptanceToken)
        external
        nonReentrant
        returns (uint256, uint256, uint256)
    {
        if (_acceptanceToken != keccak256(abi.encodePacked(msg.sender, termsAndConditionsHash))) {
            revert InvalidAcceptanceToken(msg.sender, _acceptanceToken);
        }

        return _exitFunds(_amount, msg.sender, true);
    }

    /**
     * @notice Internal function to compute the amount of WETH, DAI, and USDC to send to the user.
     * @param _amount - The amount of ERC4626 token to be migrated
     * @param _to - The address to send the recovered funds to
     * @param _pullFunds - Whether to pull ERC4626 token from the user
     * @return The amount of weth sent to the user
     * @return The amount of dai sent to the user
     * @return The amount of usdc sent to the user
     */
    function _exitFunds(uint256 _amount, address _to, bool _pullFunds) internal returns (uint256, uint256, uint256) {
        uint256 wethToSend = _amount.mulDivDown(wethPerERC4626, 1e18);
        uint256 daiToSend = _amount.mulDivDown(daiPerERC4626, 1e18);
        uint256 usdcToSend = _amount.mulDivDown(usdcPerERC4626, 1e18);

        if (_pullFunds) {
            ERC4626Token.safeTransferFrom(msg.sender, address(this), _amount);
            emit MigratedAndAgreed(_to, _amount, wethToSend, daiToSend, usdcToSend);
        } else {
            emit MigratedByAdmin(_to, _amount, wethToSend, daiToSend, usdcToSend);
        }

        if (wethToSend > 0) WETH.safeTransfer(_to, wethToSend);
        if (daiToSend > 0) DAI.safeTransfer(_to, daiToSend);
        if (usdcToSend > 0) USDC.safeTransfer(_to, usdcToSend);

        return (wethToSend, daiToSend, usdcToSend);
    }
}