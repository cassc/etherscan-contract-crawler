// import openzeppelin-solidity/contracts/token/ERC20/ERC20.sol;
// import openzeppelin-solidity/contracts/math/SafeMath.sol;
// import ownable as well
// import access controls

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract wTAO is ERC20, Ownable, AccessControl {
    using SafeMath for uint256;
    // Roles
    // access role to call bridgedTo
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    uint256 public _nonce = 0;
    uint256 public BITTENSOR_FEE = 125000145; // 0.1251 wTAO

    uint256 public cumulative_bridged = 0;
    uint256 public cumulative_bridged_back = 0;

    // events
    event Mint(address indexed to, uint256 amount);
    event BridgedTo(string from, address indexed to, uint256 amount, uint256 nonce);
    // burn events include a signed message of where to bridge funds to
    event BridgedBack(address indexed from, uint256 amount, string to, uint256 nonce);
    event BridgeSet(address indexed bridge);

    constructor() ERC20("Wrapped TAO", "wTAO") {
        // set owner as admin
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function setBridge(address _bridge) public onlyOwner returns(bool) {
        _setupRole(BRIDGE_ROLE, _bridge);
        return true;
    }

    
    function bridgedTo(string[] memory _froms, address[] memory _tos, uint256[] memory _amounts) public returns(bool) {
        require(hasRole(BRIDGE_ROLE, _msgSender()), "Caller is not the bridge");
        // require all arrays are the same length
        require(_froms.length == _tos.length && _froms.length == _amounts.length, "Arrays are not the same length");
        // loop through arrays and mint
        for (uint256 i = 0; i < _froms.length; i++) {
            _mint(_tos[i], _amounts[i]);
            cumulative_bridged = cumulative_bridged.add(_amounts[i]);
            emit BridgedTo(_froms[i], _tos[i], _amounts[i], _nonce);
            _nonce++;
        }
        return true;
    }

    function bridgeBack(uint256 _amount, string memory _to) public returns(bool) {
        require(_amount <= balanceOf(_msgSender()), "Not enough balance");
        // require greater than 0.1251 wTAO for gas purposes.
        require(_amount > BITTENSOR_FEE, "Does not meet minimum amount for gas (0.125000144 wTAO)");
        _burn(msg.sender, _amount);
        _nonce++;
        cumulative_bridged_back = cumulative_bridged_back.add(_amount);
        emit BridgedBack(_msgSender(), _amount, _to, _nonce);
        return true;
    }

    function deployer() public view returns (address) {
        return owner();
    }

    // reclaim stuck sent tokens
    function reclaimToken(address _token) public onlyOwner {
        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
        payable(owner()).transfer(address(this).balance);
    }
    
}