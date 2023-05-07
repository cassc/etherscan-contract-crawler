// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MCC is ERC20("MTFK", "MTFK"), AccessControl {

    bytes32 public constant M_ROLE = keccak256("M_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(M_ROLE, _msgSender());
    }

    function mint(address _to, uint256 _amount) external onlyRole(M_ROLE) {
        _mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount) external onlyRole(M_ROLE) {
        _burn(_to, _amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC20).interfaceId
            || interfaceId == type(IERC20Metadata).interfaceId
            || interfaceId == type(IAccessControl).interfaceId
            || interfaceId == type(IERC165).interfaceId
            || super.supportsInterface(interfaceId);
    }
}