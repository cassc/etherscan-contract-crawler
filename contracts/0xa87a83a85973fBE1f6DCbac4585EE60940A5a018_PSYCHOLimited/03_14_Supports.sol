// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Master.sol";
import "./Metadata.sol";
import "../interfaces/IERC165.sol";

/**
 * @dev Supports bundle
 */
contract Supports is
    IERC165,
    Metadata,
    Master {

    receive() external payable {}
    fallback() external payable {}

    // Activation variable
    bool private _activeGenesis = false;

    // Lockdown variable
    bool private _locked = false;

    // Wei fee variable
    uint256 private _weiFee = 222000000000000000;

    // Master avatar generation count
    uint256 private _masterCount = 0;

    // Withdraw event
    event Withdraw(address operator, address receiver, uint256 value);

    /**
     * @dev Constructs the Metadata and Master contracts
     */
    constructor(
    ) Metadata(
        "PSYCHO Limited",
        "PSYCHO",
        "ipfs://bafybeidob7iaynjg6h6c3igqnac2qnprlzsfatybuqkxhcizcgpfowwgm4",
        "ipfs://bafybeifqi27soekjrmrgyhrbp3zauxjdpfwi7myiu7iwfveaunzuertdya"
    ) Master(msg.sender) {
        _genesis(msg.sender, 1);
    }

    /**
     * @dev Private contract withdrawal
     */
    function _withdraw(
        address _to
    ) private {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_to).call{
            value: address(this).balance
        }("");
        require(success, "Ether transfer failed");
        emit Withdraw(msg.sender, _to, balance);
    }

    /**
     * @dev See {IPSYCHOLimited-active}
     */
    function _active(
    ) internal view returns (bool) {
        return _activeGenesis;
    }

    /**
     * @dev See {IPSYCHOLimited-fee}
     */
    function _fee(
        uint256 _multiplier
    ) internal view returns (uint256) {
        return _weiFee * _multiplier;
    }

    /**
     * @dev See {IPSYCHOLimited-unstoppable}
     */
    function _unstoppable(
    ) internal view returns (bool) {
        return _locked;
    }

    /**
     * @dev Relinquishes master role and sets fee to zero
     */
    function relinquish(
        bool _bool
    ) public master {
        require(
            _bool == true
        );
        _weiFee = 0;
        _withdraw(msg.sender);
        _transferOwnership(address(0));
        _locked = true;
    }

    /**
     * @dev Use `true` to activate genesis `false` to deactivate genesis
     */
    function activate(
        bool _bool
    ) public master {
        if (
            _bool == true
        ) {
            _activeGenesis = true;
        }
        else {
            _activeGenesis = false;
        }
    }

    /**
     * @dev Use wei amount to set fee
     */
    function setFee(
        uint256 _wei
    ) public master {
        _weiFee = _wei;
    }

    /**
     * @dev Generates up to 99 avatars for the master
     */
    function masterGenesis(
        address _to,
        uint256 _quantity
    ) public master {
        if (
            _masterCount + _quantity > 99
        ) {
            revert ExceedsGenesisLimit();
        }
        _masterCount += _quantity;
        _genesis(_to, _quantity);
    }

    /**
     * @dev Withdraws ether from contract
     */
    function withdraw(
        address _to
    ) public master {
        _withdraw(_to);
    }

    /**
     * @dev Supports interface
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(
        IERC165
    ) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC173).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }
}