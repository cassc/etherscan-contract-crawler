// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 *
 *
 * Chainbox Proxy by Robin Syihab
 *
 * Chainbox proxy smart contract
 *
 */
import "Ownable.sol";
import "HasAdmin.sol";
import "SigVerifier.sol";

contract ChainboxProxy is Ownable, HasAdmin, SigVerifier {
    uint256 public minPrice = 0.0001 ether;

    mapping(uint128 => address) private _ownerOf;

    event Payment(
        address indexed sender,
        uint128 indexed projectId,
        uint256 indexed amount
    );

    constructor(address admin) {
        _setAdmin(admin);
    }

    function changeAdmin(address newAdmin) external onlyOwner {
        _setAdmin(newAdmin);
    }

    modifier onlyAdminOrOwner() {
        require(
            _isAdmin(_msgSender()) || _msgSender() == owner(),
            "Only admin or owner"
        );
        _;
    }

    function setMinPrice(uint256 newMinPrice) external onlyAdminOrOwner {
        minPrice = newMinPrice;
    }

    function deployPayment(uint128 projectId) external payable {
        require(projectId != 0, "Project ID cannot be 0");
        require(msg.value >= minPrice, "Not enough payment amount");

        address _sender = _msgSender();

        if (_ownerOf[projectId] != 0x0000000000000000000000000000000000000000) {
            require(
                _ownerOf[projectId] == _sender,
                "You are not the owner of this project"
            );
        }

        _ownerOf[projectId] = _sender;

        emit Payment(_sender, projectId, msg.value);
    }

    function ownerOf(uint128 projectId) external view returns (address) {
        return _ownerOf[projectId];
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No amount to withdraw");
        payable(_msgSender()).transfer(address(this).balance);
    }
}