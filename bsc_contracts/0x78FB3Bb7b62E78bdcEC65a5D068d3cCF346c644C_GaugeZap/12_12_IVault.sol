pragma solidity 0.8.15;
import "@openzeppelin/contracts-v4/token/ERC20/IERC20.sol";



interface IVault is IERC20 {
    function token() external returns (address);
    function deposit(uint256 _amount) external;
    function depositAll() external;
    function withdraw(uint256 _share) external;
    function withdrawAll() external;
    function getPricePerFullShare() external returns (uint256);
}