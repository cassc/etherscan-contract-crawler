import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity >=0.5.16;

interface IERC20BurnNMintable {


    function mint(address to, uint256 value) external;
    function burnFrom(address from, uint256 value) external;
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
}