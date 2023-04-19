// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./IVesting.sol";

interface ITGE {

    struct TGEInfo {
        uint256 price;
        uint256 hardcap;
        uint256 softcap;
        uint256 minPurchase;
        uint256 maxPurchase;
        uint256 duration;
        IVesting.VestingParams vestingParams;
        address[] userWhitelist;
        address unitOfAccount;
        uint256 lockupDuration;
        uint256 lockupTVL;
    }

    function initialize(
        address service,
        IToken token_,
        TGEInfo calldata info_,
        uint256 protocolFee_
    ) external;

    enum State {
        Active,
        Failed,
        Successful
    }

    function token() external view returns (IToken);

    function state() external view returns (State);

    function getInfo() external view returns (TGEInfo memory);

    function transferUnlocked() external view returns (bool);

    function purchaseOf(address user) external view returns (uint256);

    function redeemableBalanceOf(address user) external view returns (uint256);

    function lockedBalanceOf(address account) external view returns (uint256);

    function getEnd() external view returns (uint256);
}