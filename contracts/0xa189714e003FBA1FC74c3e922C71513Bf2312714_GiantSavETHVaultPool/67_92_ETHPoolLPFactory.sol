// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { StakehouseAPI } from "@blockswaplab/stakehouse-solidity-api/contracts/StakehouseAPI.sol";
import { IDataStructures } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol";

import { LPTokenFactory } from "./LPTokenFactory.sol";
import { LPToken } from "./LPToken.sol";

interface ILSM {
    function isBLSPublicKeyBanned(bytes calldata _blsPublicKey) external view returns (bool);
}

/// @dev For pools accepting ETH for validator staking, this contract will manage issuing LPs for deposits
abstract contract ETHPoolLPFactory is StakehouseAPI {

    /// @notice signalize withdrawing of ETH by depositor
    event ETHWithdrawnByDepositor(address depositor, uint256 amount);

    /// @notice signalize burning of LP token
    event LPTokenBurnt(bytes blsPublicKeyOfKnot, address token, address depositor, uint256 amount);

    /// @notice signalize issuance of new LP token
    event NewLPTokenIssued(bytes blsPublicKeyOfKnot, address token, address firstDepositor, uint256 amount);

    /// @notice signalize issuance of existing LP token
    event LPTokenMinted(bytes blsPublicKeyOfKnot, address token, address depositor, uint256 amount);

    /// @dev Base name and symbol used for deploying new LP tokens per KNOT
    string internal baseLPTokenName;
    string internal baseLPTokenSymbol;

    /// @notice count of unique LP tokens issued for ETH deposits
    uint256 public numberOfLPTokensIssued;

    /// @notice Maximum amount that can be staked per validator in WEI
    uint256 public maxStakingAmountPerValidator;

    /// @notice Minimum amount that can be staked per validator in WEI
    uint256 public constant MIN_STAKING_AMOUNT = 0.001 ether;

    /// @notice Factory for the deployment of KNOT<>LP Tokens that can be used to redeem dETH
    LPTokenFactory public lpTokenFactory;

    /// @notice LP token address deployed for a KNOT's BLS public key
    mapping(bytes => LPToken) public lpTokenForKnot;

    /// @notice KNOT BLS public key associated with the LP token
    mapping(LPToken => bytes) public KnotAssociatedWithLPToken;

    /// @notice Allow users to rotate the ETH from many LP to another in the event that a BLS key is never staked
    /// @param _oldLPTokens Array of old LP tokens to be burnt
    /// @param _newLPTokens Array of new LP tokens to be minted in exchange of old LP tokens
    /// @param _amounts Array of amount of tokens to be exchanged
    function batchRotateLPTokens(
        LPToken[] calldata _oldLPTokens,
        LPToken[] calldata _newLPTokens,
        uint256[] calldata _amounts
    ) external {
        uint256 numOfRotations = _oldLPTokens.length;
        require(numOfRotations > 0, "Empty arrays");
        require(numOfRotations == _newLPTokens.length, "Inconsistent arrays");
        require(numOfRotations == _amounts.length, "Inconsistent arrays");

        for (uint256 i; i < numOfRotations; ++i) {
            rotateLPTokens(
                _oldLPTokens[i],
                _newLPTokens[i],
                _amounts[i]
            );
        }
    }

    /// @notice Allow users to rotate the ETH from one LP token to another in the event that the BLS key is never staked
    /// @param _oldLPToken Instance of the old LP token (to be burnt)
    /// @param _newLPToken Instane of the new LP token (to be minted)
    /// @param _amount Amount of LP tokens to be rotated/converted from old to new
    function rotateLPTokens(LPToken _oldLPToken, LPToken _newLPToken, uint256 _amount) public {
        require(address(_oldLPToken) != address(0), "Zero address");
        require(address(_newLPToken) != address(0), "Zero address");
        require(_oldLPToken != _newLPToken, "Incorrect rotation to same token");
        require(_amount >= MIN_STAKING_AMOUNT, "Amount cannot be zero");
        require(_amount % MIN_STAKING_AMOUNT == 0, "Amount not multiple of min staking");
        require(_amount <= _oldLPToken.balanceOf(msg.sender), "Not enough balance");
        require(_oldLPToken.lastInteractedTimestamp(msg.sender) + 30 minutes < block.timestamp, "Liquidity is still fresh");
        require(_amount + _newLPToken.totalSupply() <= maxStakingAmountPerValidator, "Not enough mintable tokens");

        bytes memory blsPublicKeyOfPreviousKnot = KnotAssociatedWithLPToken[_oldLPToken];
        bytes memory blsPublicKeyOfNewKnot = KnotAssociatedWithLPToken[_newLPToken];

        require(blsPublicKeyOfPreviousKnot.length == 48, "Incorrect BLS public key");
        require(blsPublicKeyOfNewKnot.length == 48, "Incorrect BLS public key");

        require(
            getAccountManager().blsPublicKeyToLifecycleStatus(blsPublicKeyOfPreviousKnot) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
            "Lifecycle status must be one"
        );

        require(
            getAccountManager().blsPublicKeyToLifecycleStatus(blsPublicKeyOfNewKnot) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
            "Lifecycle status must be one"
        );

        // M-02
        ILSM manager = ILSM(_newLPToken.liquidStakingManager());
        require(!manager.isBLSPublicKeyBanned(blsPublicKeyOfNewKnot), "BLS public key is banned");

        // burn old tokens and mint new ones
        _oldLPToken.burn(msg.sender, _amount);
        emit LPTokenBurnt(blsPublicKeyOfPreviousKnot, address(_oldLPToken), msg.sender, _amount);

        _newLPToken.mint(msg.sender, _amount);
        emit LPTokenMinted(KnotAssociatedWithLPToken[_newLPToken], address(_newLPToken), msg.sender, _amount);
    }

    /// @dev Internal business logic for processing staking deposits for single or batch deposits
    function _depositETHForStaking(bytes calldata _blsPublicKeyOfKnot, uint256 _amount, bool _enableTransferHook) internal {
        require(_amount >= MIN_STAKING_AMOUNT, "Min amount not reached");
        require(_amount % MIN_STAKING_AMOUNT == 0, "Amount not multiple of min staking");
        require(_blsPublicKeyOfKnot.length == 48, "Invalid BLS public key");

        // LP token issued for the KNOT
        // will be zero for a new KNOT because the mapping doesn't exist
        LPToken lpToken = lpTokenForKnot[_blsPublicKeyOfKnot];
        if(address(lpToken) != address(0)) {
            // KNOT and it's LP token is already registered
            // mint the respective LP tokens for the user

            // total supply after minting the LP token must not exceed maximum staking amount per validator
            require(lpToken.totalSupply() + _amount <= maxStakingAmountPerValidator, "Amount exceeds the staking limit for the validator");

            // mint LP tokens for the depoistor with 1:1 ratio of LP tokens and ETH supplied
            lpToken.mint(msg.sender, _amount);
            emit LPTokenMinted(_blsPublicKeyOfKnot, address(lpToken), msg.sender, _amount);
        }
        else {
            // check that amount doesn't exceed max staking amount per validator
            require(_amount <= maxStakingAmountPerValidator, "Amount exceeds the staking limit for the validator");

            // mint new LP tokens for the new KNOT
            // add the KNOT in the mapping
            string memory tokenNumber = Strings.toString(numberOfLPTokensIssued);
            string memory tokenName = string(abi.encodePacked(baseLPTokenName, tokenNumber));
            string memory tokenSymbol = string(abi.encodePacked(baseLPTokenSymbol, tokenNumber));

            // deploy new LP token and optionally enable transfer notifications
            LPToken newLPToken = _enableTransferHook ?
                             LPToken(lpTokenFactory.deployLPToken(address(this), address(this), tokenSymbol, tokenName)) :
                             LPToken(lpTokenFactory.deployLPToken(address(this), address(0), tokenSymbol, tokenName));

            // increase the count of LP tokens
            numberOfLPTokensIssued++;

            // register the BLS Public Key with the LP token
            lpTokenForKnot[_blsPublicKeyOfKnot] = newLPToken;
            KnotAssociatedWithLPToken[newLPToken] = _blsPublicKeyOfKnot;

            // mint LP tokens for the depoistor with 1:1 ratio of LP tokens and ETH supplied
            newLPToken.mint(msg.sender, _amount);
            emit NewLPTokenIssued(_blsPublicKeyOfKnot, address(newLPToken), msg.sender, _amount);
        }
    }
}