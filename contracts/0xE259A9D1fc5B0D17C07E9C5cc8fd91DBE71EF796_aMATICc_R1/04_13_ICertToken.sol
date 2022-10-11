pragma solidity ^0.8.0;

interface ICertToken {

    event PoolContractChanged(address oldPool, address newPool);

    event BondTokenChanged(address oldBondToken, address newBondToken);

    function changePoolContract(address newPoolContract) external;

    function changeBondToken(address newBondToken) external;

    function burn(address account, uint256 amount) external;

    function mint(address account, uint256 amount) external;

    function bondTransferTo(address account, uint256 shares) external;

    function bondTransferFrom(address account, uint256 shares) external;

    function balanceWithRewardsOf(address account) external returns (uint256);

    function isRebasing() external returns (bool);

    function ratio() external view returns (uint256);
}