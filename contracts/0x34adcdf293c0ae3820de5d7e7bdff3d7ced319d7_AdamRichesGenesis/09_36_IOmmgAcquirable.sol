// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgAcquirable
/// @author NotAMeme aka nxlogixnick
/// @notice This interface serves for the simple minting functionality of the OMMG Artist Contracts.
interface IOmmgAcquirable {
    /// @notice Mints `amount` NFTs of this contract. The more minted at once, the cheaper gas is for each token.
    /// However, the upper limit for `amount` can be queried via `maxBatchSize`. Fails if the user does not provide
    /// the correct amount of eth, if sale is paused, if the supply catch is reached, or if `maxBatchSize` is exceeded.
    /// @param amount the amount of NFTs to mint.
    function acquire(uint256 amount) external payable;

    /// @notice Mints `amount` NFTs of this contract to `receiver`. The more minted at once, the cheaper gas is for each token.
    /// However, the upper limit for `amount` can be queried via `maxBatchSize`. Fails if the supply catch is reached,
    /// or if `maxBatchSize` is exceeded.
    /// @param receiver the receiver of the NFTs.
    /// @param amount the amount of NFTs to mint.
    function acquireForCommunity(address receiver, uint256 amount) external;
}