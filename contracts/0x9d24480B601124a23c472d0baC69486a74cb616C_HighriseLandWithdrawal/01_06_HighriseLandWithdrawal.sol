// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "ECDSA.sol";
import "ERC165Checker.sol";

import "IHighriseLand.sol";

contract HighriseLandWithdrawal {
    using ERC165Checker for address;
    using ECDSA for bytes32;

    event WithdrawLandEvent(address indexed sender, uint256 tokenId);
    event WithdrawalStateChangedEvent(bool enabled);

    enum WithdrawalState {
        ENABLED,
        DISABLED
    }

    address public immutable owner;
    address public immutable landContract;

    // mapping to store which address deposited how much ETH
    WithdrawalState public withdrawalState;

    constructor(address _landContract) {
        require(
            _landContract.supportsInterface(type(IHighriseLand).interfaceId),
            "IS_NOT_HIGHRISE_LAND_CONTRACT"
        );
        owner = msg.sender;
        withdrawalState = WithdrawalState.DISABLED;
        landContract = _landContract;
    }

    modifier enabled() {
        require(
            withdrawalState == WithdrawalState.ENABLED,
            "HLW: Contract not enabled"
        );
        _;
    }

    function withdraw(bytes memory data, bytes memory signature)
        public
        enabled
    {
        require(
            _verify(keccak256(data), signature, owner),
            "HLW: Payload verification failed"
        );
        (uint256 tokenId, address approvedOwner) = abi.decode(
            abi.encodePacked(data),
            (uint256, address)
        );
        require(
            msg.sender == approvedOwner,
            "HLW: Sender not approved to buy token"
        );
        IHighriseLand(landContract).mint(msg.sender, tokenId);
        emit WithdrawLandEvent(msg.sender, tokenId);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "HLW: Sender is not the owner");
        _;
    }

    function enable() public onlyOwner {
        withdrawalState = WithdrawalState.ENABLED;
        emit WithdrawalStateChangedEvent(true);
    }

    function disable() public onlyOwner {
        withdrawalState = WithdrawalState.DISABLED;
        emit WithdrawalStateChangedEvent(false);
    }


    function _verify(
        bytes32 data,
        bytes memory signature,
        address account
    ) internal pure returns (bool) {
        return data.recover(signature) == account;
    }
}