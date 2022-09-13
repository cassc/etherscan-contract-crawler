//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";

interface INFT {
    function totalSupply() external view returns (uint256);
    function depositRewards(uint256 amount) external;
}

interface IStaking {
    function depositRewards(uint256 amount) external;
}

contract RewardDistributor {

    uint256 public constant conversionRate = 5_000 * 10**18;
    uint256 private constant PRECISION = 10**18;

    address public immutable infinity;
    address public immutable staking;
    address public immutable nft;

    constructor(address infinity_, address staking_, address nft_) {
        infinity = infinity_;
        staking = staking_;
        nft = nft_;
    }

    function distribute() external payable {
        _distribute();
    }

    receive() external payable{
        _distribute();
    }

    function _distribute() internal {

        // Infinity Balances In Each
        uint nftBal = infBalanceNFT();
        uint stakingBal = infBalanceStaking();

        // Which Pool Has A Larger Balance
        bool nftHasMore = nftBal > stakingBal;

        // Ratio Of Bigger Balance / Smaller Balance
        uint ratio = nftHasMore ? ( nftBal * PRECISION ) / stakingBal : ( stakingBal * PRECISION ) / nftBal;

        // Value / ( Ratio + 1 )
        uint smallerShare = ( address(this).balance * PRECISION ) / ( ratio + PRECISION );

        // split up amounts to their correct pools
        _send(nftHasMore ? staking : nft, smallerShare);
        _send(nftHasMore ? nft : staking, address(this).balance);
    }

    function splitAmounts(uint256 amount) public view returns (uint256 stakingValue, uint256 nftValue) {

        // Infinity Balances In Each
        uint nftBal = infBalanceNFT();
        uint stakingBal = infBalanceStaking();

        // Which Pool Has A Larger Balance
        bool nftHasMore = nftBal > stakingBal;

        // Ratio Of Bigger Balance / Smaller Balance
        uint ratio = nftHasMore ? ( nftBal * PRECISION ) / stakingBal : ( stakingBal * PRECISION ) / nftBal;

        // Value / ( Ratio + 1 )
        uint smallerShare = ( amount * PRECISION ) / ( ratio + PRECISION );

        stakingValue = nftHasMore ? smallerShare : amount - smallerShare;
        nftValue = nftHasMore ? amount - smallerShare : smallerShare;
    }

    function infBalanceNFT() public view returns (uint256) {
        return INFT(nft).totalSupply() * conversionRate;
    }

    function infBalanceStaking() public view returns (uint256) {
        return IERC20(infinity).balanceOf(staking);
    }

    function _send(address to, uint amount) internal {
        (bool s,) = payable(to).call{value: amount}("");
        require(s);
    }
}