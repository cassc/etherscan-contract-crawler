import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VRSW is ERC20 {
    constructor() ERC20("Virtuswap Token", "VRSW") {
        _mint(msg.sender, 1000000000000000000000000000);
    }
}