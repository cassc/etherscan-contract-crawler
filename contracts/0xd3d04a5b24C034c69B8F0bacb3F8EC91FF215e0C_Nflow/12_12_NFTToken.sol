pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract NFTToken is ERC20Burnable {
    string private publicName;

    string private publicSymbol;

    address immutable factory;

    constructor() ERC20("", "") {
        factory = msg.sender;
    }

    modifier onlyFactory() {
        require(factory == msg.sender, "Caller is not the factory");
        _;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return publicName;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return publicSymbol;
    }

    function initialize(
        string calldata _name,
        string calldata _symbol
    ) external onlyFactory {
        publicName = _name;
        publicSymbol = _symbol;
    }

    function mint(address _to, uint256 amount) external onlyFactory {
        _mint(_to, amount);
    }
}