// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {MerkleProof} from "@openzeppelin/utils/cryptography/MerkleProof.sol";

import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";

interface IPRTCStore {
    function isClosed() external view returns (bool);

    function hasClaimed(address user) external view returns (bool);

    function buyPRTC(bytes32[] calldata merkleProof) external payable;

    function previewPRTCAmount(uint256 ethAmount) external view returns (uint256 prtc);
}

error AlreadyBought();
error BuyPeriodClosed();
error ETHTransferFailed();
error InvalidETHAmount();
error NotInvited();
error ShopStillOpen();

contract PRTCStore is IPRTCStore {
    uint256 private constant PRICE_PER_PRTC = 51_500_000_000_000;
    bytes32 private constant MERKLE_ROOT =
        0xf873326f5c38edff9b566e265525762f885559baf5dd6daca049a5ae2d547b36;
    address private constant MULTISIG = 0x2A1Aa732Fe04494bE2A24E90b120Ba1864Da3b17;

    IERC20 private constant PRTC = IERC20(0xb9098D3669A78e9AfE8b94a97290407400D9dA31);

    uint256 private immutable endTime;

    mapping(address => bool) public hasClaimed;

    constructor() {
        endTime = block.timestamp + 25 hours;
    }

    function isClosed() public view returns (bool) {
        return block.timestamp > endTime;
    }

    function previewPRTCAmount(uint256 _ethAmount) public pure returns (uint256) {
        return _ethAmount * 1e18 / PRICE_PER_PRTC;
    }

    function buyPRTC(bytes32[] calldata _mp) external payable {
        if (isClosed()) revert BuyPeriodClosed();
        if (msg.value == 0) revert InvalidETHAmount();
        if (hasClaimed[msg.sender]) revert AlreadyBought();
        if (!MerkleProof.verifyCalldata(_mp, MERKLE_ROOT, keccak256(abi.encodePacked(msg.sender))))
        {
            revert NotInvited();
        }

        hasClaimed[msg.sender] = true;

        uint256 prtcAmount = previewPRTCAmount(msg.value);

        PRTC.transfer(msg.sender, prtcAmount);
    }

    function closeShop() external {
        if (!isClosed()) revert ShopStillOpen();

        PRTC.transfer(MULTISIG, PRTC.balanceOf(address(this)));

        (bool success,) = MULTISIG.call{value: address(this).balance}("");
        if (!success) revert ETHTransferFailed();
    }
}