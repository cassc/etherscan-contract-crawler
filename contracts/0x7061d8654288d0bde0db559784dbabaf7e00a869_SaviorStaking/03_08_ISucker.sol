import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISucker is IERC20 {
    function mint(address receiver, uint256 amount) external;
}