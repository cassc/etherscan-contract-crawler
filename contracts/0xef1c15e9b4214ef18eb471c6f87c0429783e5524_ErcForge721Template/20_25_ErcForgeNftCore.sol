//SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.0;

import "operator-filter-registry/src/OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "operator-filter-registry/src/lib/Constants.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract ErcForgeNftCore is OperatorFilterer, ERC2981 {
    address public owner;
    mapping(address => bool) public isAdmin;
    bool private _isInitDone = false;

    bool private _isOperatorFilterRegistered = false;

    error InitDone();
    error NotOwner();
    error NotAdmin();
    error ZeroAddress();
    error NotEnoughFunds();
    error NoSupply();
    error AmountShouldNotBeZero();

    constructor() OperatorFilterer(address(0), false) {
        _isInitDone = true;
    }

    function _init(
        address newOwner,
        address royaltyReceiver,
        uint96 royaltyFee
    ) internal {
        if (_isInitDone) {
            revert InitDone();
        }

        owner = newOwner;
        isAdmin[newOwner] = true;
        _setRoyalty(royaltyReceiver, royaltyFee);
        _isInitDone = true;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Owner
     */
    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }
        isAdmin[owner] = false;
        isAdmin[newOwner] = true;
        owner = newOwner;
    }

    /**
     * @dev Admin
     */
    modifier onlyAdmin() {
        if (isAdmin[msg.sender] != true) {
            revert NotAdmin();
        }
        _;
    }

    function setIsAdmin(address adminAddress, bool admin) public onlyOwner {
        isAdmin[adminAddress] = admin;
    }

    /**
     * @dev Royalty
     */
    function setRoyalty(
        address _royaltyReceiver,
        uint256 _royaltyFee
    ) public onlyAdmin {
        _setRoyalty(_royaltyReceiver, uint96(_royaltyFee));
    }

    function _setRoyalty(address _royaltyReceiver, uint96 _royaltyFee) private {
        if (_royaltyReceiver == address(0)) {
            _setDefaultRoyalty(owner, 0);
        } else {
            _setDefaultRoyalty(_royaltyReceiver, _royaltyFee);
        }

        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (_royaltyReceiver != address(0)) {
                if (!_isOperatorFilterRegistered) {
                    OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
                        address(this),
                        CANONICAL_CORI_SUBSCRIPTION
                    );
                    _isOperatorFilterRegistered = true;
                }
            } else {
                if (_isOperatorFilterRegistered) {
                    OPERATOR_FILTER_REGISTRY.unregister(address(this));
                    _isOperatorFilterRegistered = false;
                }
            }
        }
    }
}