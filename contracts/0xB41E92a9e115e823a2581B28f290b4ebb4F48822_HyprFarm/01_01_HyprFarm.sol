// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// Stake your HyprPepe tokens to earn more HyprPepe tokens!
// How does price go up, supply go down and I earn yeild anon
// What happens every 15 minutes anon?
// HyprPepe from the LP is removed and distributed to the stakers!
// HyprPepe from the LP is removed and burnt!

interface IHyprPepe {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function collectDividendsAndBurn() external;
}

contract HyprFarm {
    mapping(address => uint256) public stakeShares;
    uint256 public totalShares;

    function stake(uint256 tokenAmount) public {
        IHyprPepe(0xC2d2A4Cf2d600Baa498195622FfB2AFa0B31e812)
            .collectDividendsAndBurn(); // Attempt to claim any unclaimed dividends from LP

        // Gets the amount of $HYPR in the contract
        uint256 tokensStaked = IHyprPepe(
            0xC2d2A4Cf2d600Baa498195622FfB2AFa0B31e812
        ).balanceOf(address(this));

        if (totalShares == 0 || tokensStaked == 0) {
            // If no current stake, mint it 1:1 the token amount amount
            stakeShares[msg.sender] = tokenAmount;
            totalShares += tokenAmount;
        } else {
            uint256 shares = (tokenAmount * totalShares) / tokensStaked;
            stakeShares[msg.sender] += shares;
            totalShares += shares;
        }

        IHyprPepe(0xC2d2A4Cf2d600Baa498195622FfB2AFa0B31e812).transferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );
    }

    function unstake(uint256 shareAmount) public {
        IHyprPepe(0xC2d2A4Cf2d600Baa498195622FfB2AFa0B31e812)
            .collectDividendsAndBurn(); // Attempt to claim any unclaimed dividends from LP

        uint256 tokensStaked = IHyprPepe(
            0xC2d2A4Cf2d600Baa498195622FfB2AFa0B31e812
        ).balanceOf(address(this));
        uint256 tokenAmount = (shareAmount * tokensStaked) / totalShares;
        stakeShares[msg.sender] -= shareAmount;
        totalShares -= shareAmount;
        IHyprPepe(0xC2d2A4Cf2d600Baa498195622FfB2AFa0B31e812).transfer(
            msg.sender,
            tokenAmount
        );
    }
}