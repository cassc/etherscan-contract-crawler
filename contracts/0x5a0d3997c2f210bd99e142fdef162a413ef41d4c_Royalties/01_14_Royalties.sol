// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Controllable} from "./abstract/Controllable.sol";
import {IRoyalties} from "./interfaces/IRoyalties.sol";
import {IControllable} from "./interfaces/IControllable.sol";
import {RoyaltySchedule, CustomRoyalty} from "./structs/Royalty.sol";
import {TokenData, TokenType} from "./structs/TokenData.sol";
import {RaiseData, TierType} from "./structs/RaiseData.sol";
import {RaiseToken} from "./libraries/RaiseToken.sol";

uint256 constant BPS_DENOMINATOR = 10_000;

/// @title Royalties - Royalty registry
/// @notice Calculates ERC-2981 token royalties.
contract Royalties is IRoyalties, Controllable {
    using RaiseToken for uint256;

    string public constant NAME = "Royalties";
    string public constant VERSION = "0.0.1";

    address public receiver;
    RoyaltySchedule public royaltySchedule = RoyaltySchedule({fanRoyalty: 150, brandRoyalty: 1000});

    /// tokenId => CustomRoyalty
    mapping(uint256 => CustomRoyalty) public customRoyalties;

    constructor(address _controller, address _receiver) Controllable(_controller) {
        if (_receiver == address(0)) revert ZeroAddress();
        receiver = _receiver;
    }

    /// @inheritdoc IRoyalties
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override
        returns (address to, uint256 royaltyAmount)
    {
        uint256 royaltyBps;

        CustomRoyalty memory customRoyalty = customRoyalties[tokenId];

        if (customRoyalty.receiver == address(0)) {
            to = receiver;
            (TokenData memory token, RaiseData memory raise) = tokenId.decode();
            if (token.tokenType == TokenType.Raise) {
                if (raise.tierType == TierType.Fan) {
                    royaltyBps = royaltySchedule.fanRoyalty;
                }
                if (raise.tierType == TierType.Brand) {
                    royaltyBps = royaltySchedule.brandRoyalty;
                }
            }
        } else {
            to = customRoyalty.receiver;
            royaltyBps = customRoyalty.royaltyBps;
        }

        royaltyAmount = (salePrice * royaltyBps) / BPS_DENOMINATOR;
    }

    /// @inheritdoc IRoyalties
    function setCustomRoyalty(uint256 tokenId, CustomRoyalty calldata customRoyalty) external override onlyController {
        if (customRoyalty.receiver == address(0)) revert InvalidReceiver();
        if (customRoyalty.royaltyBps >= BPS_DENOMINATOR) revert InvalidRoyalty();
        customRoyalties[tokenId] = customRoyalty;
        emit SetCustomRoyalty(tokenId, customRoyalty);
    }

    /// @inheritdoc IRoyalties
    function setRoyaltySchedule(RoyaltySchedule calldata newRoyaltySchedule) external override onlyController {
        if (newRoyaltySchedule.fanRoyalty >= BPS_DENOMINATOR || newRoyaltySchedule.brandRoyalty >= BPS_DENOMINATOR) {
            revert InvalidRoyalty();
        }
        emit SetRoyaltySchedule(royaltySchedule, newRoyaltySchedule);
        royaltySchedule = newRoyaltySchedule;
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address _contract)
        external
        override (Controllable, IControllable)
        onlyController
    {
        if (_contract == address(0)) revert ZeroAddress();
        else if (_name == "receiver") _setReceiver(_contract);
        else revert InvalidDependency(_name);
    }

    function _setReceiver(address _receiver) internal {
        emit SetReceiver(receiver, _receiver);
        receiver = _receiver;
    }
}