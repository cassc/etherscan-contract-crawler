pragma solidity >=0.7.5;

interface ITreasury {
    function mintQWA(address to_, uint256 amount_) external;

    function QWA() external view returns (address);

    function excessReserves() external view returns (uint256);
}