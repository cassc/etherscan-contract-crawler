// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./vendors/contracts/access/Ownable.sol";
import "./vendors/contracts/DelegableToken.sol";
import "./vendors/interfaces/IDelegableERC20.sol";

contract PACT is IDelegableERC20, DelegableToken, Ownable
{

    using SafeMath for uint256;

    constructor() ERC20("PACT community token", "PACT", 1000000000e18) public {}

    function mint(address account, uint amount) external onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(uint amount) external returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    mapping (address => bool) private _allowedBridges;
    address[] private _bridgesList;
    event BridgeRegistration(address indexed newBridge);
    event BridgeDisable(address indexed newBridge);
    function bridgesList() public view virtual returns (address[] memory) {
        return _bridgesList;
    }
    modifier onlyBridge() {
        require(_allowedBridges[_msgSender()], "PACT: caller is not the bridge");
        _;
    }
    function bridgeRegistration(address newBridge) public virtual onlyOwner {
        require(newBridge != address(0), "PACT: new bridge is the zero address");
        _allowedBridges[newBridge] = true;
        _bridgesList.push(newBridge);
        emit BridgeRegistration(newBridge);
    }
    function bridgeDisable(address oldBridge) public virtual onlyOwner {
        require(_allowedBridges[oldBridge], "PACT: bridge is disabled");
        emit BridgeRegistration(oldBridge);
        _allowedBridges[oldBridge] = false;
    }
    function mintByBridge(address account, uint amount) external onlyBridge returns (bool) {
        _mint(account, amount);
        return true;
    }
    function burnByBridge(address account, uint amount) external onlyBridge returns (bool) {
        _burn(account, amount);
        return true;
    }
}