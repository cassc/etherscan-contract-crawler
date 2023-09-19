// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract depositHandler is Ownable {
    address private treasury;
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    mapping(bytes32 => mapping(address => bool)) public roles;
    event Received(
        uint256 indexed amount,
        address indexed payee,
        uint256 indexed hash
    );

    constructor(address payable _newAdmin) {
        _grantRole(ADMIN, _newAdmin);
        _grantRole(ADMIN, msg.sender);
        treasury = _newAdmin;
    }

    receive() external payable {}

    function deposit(uint256 _amount, uint256 hash) external payable {
        require(_amount > 0 && msg.value == _amount, "Invalid Amount sent.");
        payable(treasury).transfer(_amount);
        emit Received(_amount, msg.sender, hash);
    }

    function setTreasury(address _treasury) external onlyRole(ADMIN) {
        treasury = _treasury;
    }

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "Not authorized.");
        _;
    }

    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
    }

    function grantRole(bytes32 _role, address _account)
        external
        onlyRole(ADMIN)
    {
        _grantRole(_role, _account);
    }

    function _revokeRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = false;
    }

    function revokeRole(bytes32 _role, address _account)
        external
        onlyRole(ADMIN)
    {
        _revokeRole(_role, _account);
    }
}