pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Initializable.sol";

contract Token is ERC20, Ownable, AccessControl, Initializable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); 

    event Mint (
        address indexed to,
        uint256 amount
    );

    event Burn (
        address indexed from,
        uint256 amount
    );

    modifier onlyMinter() {
        require(msg.sender == minter, "ONLY MINTER");
        _;
    }

    address public minter;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    }

    function init(address[] memory  _minters) external onlyOwner notInitialized {
        for(uint256 i = 0; i < _minters.length; i++) {
            _setupRole(MINTER_ROLE, _minters[i]);
        }
        initialized = true;
    }

    function mint(address _to, uint256 _amount) onlyRole(MINTER_ROLE) external {
        _mint(_to, _amount);

        emit Mint(_to, _amount);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
        
        emit Burn(msg.sender, _amount);
    }
}