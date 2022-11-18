import "./IERC20Extension.sol";

interface IWETH is IERC20Extension {
    function decimals() external view returns (uint8);

    function deposit() external payable;

    function withdraw(uint256 _amount) external;
}