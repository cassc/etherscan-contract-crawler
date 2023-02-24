pragma solidity =0.5.16;
import "./ZirconERC20.sol";
import "./interfaces/IZirconPoolToken.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

contract ZirconPoolToken is ZirconERC20 {
    address public token;
    address public pair;
    bool public isAnchor;
    address public pylon;
    address public pylonFactory;
    address public factory;

    constructor(address _pylonFactory, string memory name, string memory symbol) ZirconERC20(name, symbol) public {
        pylonFactory = _pylonFactory;
        factory = msg.sender;
    }

    modifier onlyPylon {
        require(msg.sender == pylon, 'ZPT: FORBIDDEN');
        _;
    }

    function mint(address account, uint256 amount) external onlyPylon{
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyPylon{
        _burn(account, amount);
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _pair, address _pylon, bool _isAnchor) external {
        require(msg.sender == pylonFactory, 'ZPT: FORBIDDEN');
        // sufficient check
        token = _token0;
        pair = _pair;
        isAnchor = _isAnchor;
        pylon = _pylon;
    }

    function changePylonAddress(address _pylon) external {
        require(msg.sender == factory, 'ZPT: FORBIDDEN');
        pylon = _pylon;
    }

}