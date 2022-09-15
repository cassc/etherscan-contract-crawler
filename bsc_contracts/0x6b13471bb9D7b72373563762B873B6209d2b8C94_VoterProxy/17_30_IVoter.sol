// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoter {
    function listingFee() external view returns (uint);

    function isWhitelisted(address) external view returns (bool);

    function poolsLength() external view returns (uint256);

    function pools(uint256) external view returns (address);

    function gauges(address) external view returns (address);

    function bribes(address) external view returns (address);

    function factory() external view returns (address);

    function gaugeFactory() external view returns (address);

    function vote(
        uint256,
        address[] memory,
        int256[] memory
    ) external;

    function whitelist(address, uint256) external;

    function updateFor(address[] memory _gauges) external;

    function claimRewards(address[] memory _gauges, address[][] memory _tokens)
        external;

    function distribute(address _gauge) external;

    function usedWeights(uint256) external returns (uint256);

    function reset(uint256 _tokenId) external;
}