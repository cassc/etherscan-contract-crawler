// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IPulseRaiserEvents.sol";

interface IPulseRaiser is IPulseRaiserEvents {
    // - VIEWS
    //
    // @dev Calculate the number of points that an amount of a token will pay for during this stint.
    //      Use the wrapped ERC20 equivalent to estimate a contribution in native currency. If you need
    //      to estimate both at the same time, call `estimate` twice.
    //
    // @param A whitelisted ERC20 token.
    // @amount The amount to assess.
    //
    // Requirements:
    // - Token is whitelisted;
    // - The sale is in progress.
    function estimate(
        address token,
        uint256 amount
    ) external view returns (uint256);

    // @dev Get normalized amount for a token. 
    // 
    // @param A whitelisted ERC20 token.
    // @amount The amount to assess.
    function normalize(
        address token,
        uint256 amount
    ) external view returns (uint256);

    // current normalized price of 10k points
    function currentPrice() external view returns (uint256);

    // tomorrow's normalized price of 10k points; 0 if sale ends before that
    function nextPrice() external view returns (uint256);

    //
    // - MUTATORS
    //
    // @dev Contribute an amount of token in exchange for points. Native currency sent along
    //      will be considered as well and normalized using the wrapped ERC20 equivalent.
    //
    // Requirements:
    // - Token is whitelisted;
    // - The sale is in progress.
    // - The contract is not paused.
    function contribute(address token, uint256 tokenAmount, string calldata referral) external payable;

    // @dev Claim token based on accumulated points. If a Merkle proof is supplied,
    //      will also claim based on tokens accumulated on other chains. If not, only
    //      the accounting in this contract will apply. Either claim (contract-based accounting
    //      or Merkle-based) can only be executed once.
    function claim(
        uint256 index_,
        uint256 points_,
        bytes32[] calldata proof_
    ) external;

    //
    // - MUTATORS (ADMIN)
    //
    // @dev Owner-only. Modify price base for a single day.
    //
    // @param dayIndex_ The day to modify pricing for. Must range from 0
    //        (which represents the first day of the sale) to 19 (inclusive,
    //         which represents the 20th day).
    // @param priceBase_ The price base per 10k points. Must range from 1 to
    //        1023 and will be divided by 100 to infer the normalized (dollar) value.
    //        E.g., 950 translates to $9.50.
    function modifyPriceBase(uint8 dayIndex_, uint16 priceBase_) external;

    // @dev Owner-only. Simultaneously modify pricing for all days.
    // @param priceBases See `modifyPriceBase` for per-element requirements. Element 0
    //        of the array corresponds to day 1, element 19 corresponds to day 20. The
    //        array must include exactly 20 non-zero elements.
    //
    function modifyPriceBases(uint16[] calldata priceBases) external;

    // @dev Owner-only. Must be called after the sale is completed. Can only be called once.
    //                  Set the Merkle tree to support claiming of tokens based on points
    //                  accumulated on other chains. Enable claiming.
    //
    // @param merkleRoot_ Merkle tree root.
    // @param pointsOtherNetworks The total of points accumulated by contributors on other chains.
    //
    function distribute(bytes32 merkleRoot_, uint256 pointsOtherNetworks) external;

    // @dev Owner-only. Set launch time. 
    //
    // @param at If 0, sets the launch time to block.timestamp and starts the sale immediately.
    //           Must be above block.timestamp otherwise (in the future).
    function launch(uint32 at) external;
     

    // @dev Owner-only. Change the raise wallet address.
    // 
    // @param wallet_ The address of the new wallet. Cannot be address(0).
    function setRaiseWallet(address wallet_) external;
}