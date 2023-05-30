// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "ECDSA.sol";
import "ERC165Checker.sol";
import "Address.sol";

import "IHighriseLand.sol";

contract HighriseLandFund {
    using ERC165Checker for address;
    using ECDSA for bytes32;

    event FundLandEvent(address indexed sender, uint256 fundAmount);
    event FundStateChangedEvent(bool enabled);

    enum FundState {
        ENABLED,
        DISABLED
    }

    address public immutable owner;
    address public immutable landContract;

    // mapping to store which address deposited how much ETH
    mapping(address => uint256) public addressToAmountFunded;
    FundState public fundState;

    constructor(address _landContract) {
        require(
            _landContract.supportsInterface(type(IHighriseLand).interfaceId),
            "IS_NOT_HIGHRISE_LAND_CONTRACT"
        );
        owner = msg.sender;
        fundState = FundState.DISABLED;
        landContract = _landContract;
    }

    modifier enabled() {
        require(
            fundState == FundState.ENABLED,
            "Contract not enabled for funding"
        );
        _;
    }

    function fund(bytes memory data, bytes memory signature)
        public
        payable
        enabled
    {
        require(_verify(keccak256(data), signature, owner), "Payload verification failed");
        (uint256 tokenId, uint256 expiry, uint256 cost, address approvedOwner) = abi.decode(
            abi.encodePacked(data),
            (uint256, uint256, uint256, address)
        );
        require(msg.sender == approvedOwner, "Sender not approved to buy token");
        require(expiry > block.timestamp, "Reservation expired");
        require(msg.value == cost, "Amount sent does not match land price");
        addressToAmountFunded[msg.sender] += msg.value;
        IHighriseLand(landContract).mint(msg.sender, tokenId);
        emit FundLandEvent(msg.sender, msg.value);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not the owner");
        _;
    }

    function enable() public onlyOwner {
        fundState = FundState.ENABLED;
        emit FundStateChangedEvent(true);
    }

    function disable() public onlyOwner {
        fundState = FundState.DISABLED;
        emit FundStateChangedEvent(false);
    }

    modifier disabled() {
        require(
            fundState == FundState.DISABLED,
            "Disable contract before withdrawing"
        );
        _;
    }

    function withdraw() public onlyOwner disabled {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function _verify(
        bytes32 data,
        bytes memory signature,
        address account
    ) internal pure returns (bool) {
        return data.recover(signature) == account;
    }
}