// SPDX-License-Identifier: UNLICENSED

import { ProxyOwnable } from "./utils/ProxyOwnable.sol";
import { MerkleProofLib } from "./utils/MerkleProofLib.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "./library/errors/Errors.sol";

pragma solidity >=0.8.4 <0.9.0;

contract BpxClaim is ProxyOwnable {
    struct ClaimWindow {
        IERC20 bpxContract;
        uint48 startTime;
        uint48 endTime;
    }

    event CurrencyClaimed(address indexed claimant, uint256 indexed amount, address indexed operator);

    bytes32 public authRoot;
    ClaimWindow private _claim;

    mapping(address => bool) private _claimed;

    constructor(address bpx) {
        if (bpx.code.length == 0) {
            revert Errors.NotAContract();
        }

        _claim.bpxContract = IERC20(bpx);
    }

    function bpxSupply() public view returns (uint256) {
        return _claim.bpxContract.balanceOf(address(this));
    }

    function getClaimMetadata() public view returns (ClaimWindow memory) {
        return _claim;
    }

    function claimed(address claimant) public view returns (bool) {
        return _claimed[claimant];
    }

    function withdraw(address recipient) external onlyAuthorized {
        _claim.bpxContract.transfer(recipient, bpxSupply());
    }

    function setClaimWindow(uint48 startTime, uint48 endTime, bytes32 merkleRoot) external onlyAuthorized {
        if (endTime < startTime) {
            revert Errors.InvalidTimeRange(startTime, endTime);
        }
        _claim.startTime = startTime;
        _claim.endTime = endTime;
        authRoot = merkleRoot;
    }

    function claim(address recipient, uint256 quantity, bytes32[] calldata proof) external {
        uint256 windowStart = _claim.startTime;
        uint256 windowEnd = _claim.endTime;
        IERC20 bpx = _claim.bpxContract;

        if (block.timestamp < windowStart) {
            revert Errors.ClaimWindowClosed();
        }
        if (block.timestamp > windowEnd) {
            revert Errors.ClaimWindowClosed();
        }
        if (_claimed[recipient]) {
            revert Errors.DuplicateCall();
        }

        bytes32 leaf = keccak256(abi.encodePacked(recipient, quantity));
        if (!MerkleProofLib.verify(proof, authRoot, leaf)) {
            revert Errors.UserPermissions();
        }

        _claimed[recipient] = true;
        emit CurrencyClaimed(recipient, quantity, msg.sender);
        bpx.transfer(recipient, quantity);
    }
}