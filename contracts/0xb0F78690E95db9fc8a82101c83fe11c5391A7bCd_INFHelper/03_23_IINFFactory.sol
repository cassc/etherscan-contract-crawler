import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IINFFactory {
    function getAuctions(IERC20 token) external view returns (address[] memory);
}