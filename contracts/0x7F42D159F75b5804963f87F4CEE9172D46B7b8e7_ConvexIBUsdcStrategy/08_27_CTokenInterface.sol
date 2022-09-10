pragma solidity >=0.8.0 <0.9.0;

interface CTokenInterface {
    function mint(uint256) external returns (uint256);

    function redeem(uint redeemTokens) external returns (uint);

    function borrow(uint256) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);
    function borrowBalanceStored(address) external view returns (uint256);
    function getCash() external view returns (uint);
    function totalBorrows() external view returns (uint);
    function totalReserves() external view returns (uint);
    function interestRateModel() external view returns(address);

    function repayBorrow(uint256) external returns (uint256);

    function underlying() external view returns (address);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
        
    function exchangeRateStored() external view returns (uint256);
}