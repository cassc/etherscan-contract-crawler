// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./ITokenERC1155.sol";
import "./IVesting.sol";

interface ITGE {
    /**
    * @notice This structure defines comprehensive TGE settings, including Vesting, Lockup, and distribution rules for these tokens.
    * @dev Initially, such a structure appears as a parameter when creating a proposal in CustomProposal, after which the data from the structure is placed in the storage of the deployed TGE contract.
    * @dev In addition, these data are used as an argument in its original form in the TGEFactory contract, including when creating the initial TGE by the pool owner without a proposal.
    * @param price The price of one token in the smallest unitOfAccount (1 wei when defining the price in ETH, 0.000001 USDT when defining the price in USDT, etc.)
    * @param hardcap The maximum number of tokens that can be sold (note the ProtocolTokenFee for Governance Tokens)
    * @param softcap The minimum number of tokens that buyers must acquire for the TGE to be considered successful
    * @param minPurchase The minimum number of tokens that can be purchased by a single account (minimum one-time purchase)
    * @param maxPurchase The maximum number of tokens that can be purchased by a single account in total during the launched TGE 
    * @param duration The duration of the event in blocks, after which the TGE status will be forcibly changed from Active to another
    * @param vestingParams Vesting settings for tokens acquired during this TGE
    * @param userWhiteList A list of addresses allowed to participate in this TGE. Leave the list empty to make the TGE public.
    * @param unitOfAccount The address of the ERC20 or compatible token contract, in the smallest units of which the price of one token is determined
    * @param lockupDuration The duration of token lockup (in blocks), one of two independent lockup conditions.
    * @param lockupTVL The minimum total pool balance in USD, one of two independent lockup conditions.
    */

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
        address _service,
        address _token,
        uint256 _tokenId,
        string memory _uri,
        TGEInfo calldata _info,
        uint256 _protocolFee
    ) external;

    enum State {
        Active,
        Failed,
        Successful
    }

    function token() external view returns (address);

    function tokenId() external view returns (uint256);

    function state() external view returns (State);

    function getInfo() external view returns (TGEInfo memory);

    function transferUnlocked() external view returns (bool);

    function purchaseOf(address user) external view returns (uint256);

    function redeemableBalanceOf(address user) external view returns (uint256);

    function lockedBalanceOf(address account) external view returns (uint256);

    function getEnd() external view returns (uint256);

    function totalPurchased() external view returns (uint256);

    function isERC1155TGE() external view returns (bool);

    function purchase(uint256 amount) external payable;

    function transferFunds() external;
}