//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Allowlist} from "../extensions/Allowlist.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FixedSale is Allowlist, Pausable, Ownable {
    uint256 public maxSupply;
    uint256 internal _initialSupply;
    uint256 internal _allowlistMinted;

    uint256 public allowlistPrice;
    uint256 public allowlistSupply;
    uint256 public allowlistStartTimestamp;

    uint256 public price;
    uint256 public startTimestamp;
    uint256 public requestMax = 10;

    bool internal initialized = false;
    bool public soldOut;

    modifier validContractState(string memory state) {
        if (compareStrings(contractState(), state) == false) revert InvalidMintPhase(contractState(), state);
        _;
    }

    function contractState() public view returns (string memory) {
        if (paused() == true) return "PAUSED";
        if (initialized == false) return "IDLE";
        if (soldOut == true) return "ENDED";
        if (startTimestamp > 0 && block.timestamp >= startTimestamp) return "PUBLIC";
        if (allowlistSupply > 0 && block.timestamp >= allowlistStartTimestamp) return "ALLOWLIST";
        return "COUNTDOWN";
    }

    function allowlistRemainingSupply() public view returns (uint256) {
        unchecked {
            return allowlistSupply - _allowlistMinted;
        }
    }

    function setAllowlist(bytes32 merkleRoot, string calldata uri) external onlyOwner {
        _updateAllowList(merkleRoot, uri);
    }

    function togglePause() external onlyOwner {
        if (paused() == true) _unpause();
        else _pause();
    }

    function initializeSale(
        uint256 _maxSupply,
        uint256 _allowlistPrice,
        uint256 _allowlistSupply,
        uint256 _allowlistStartTimestamp,
        uint256 _price,
        uint256 _startTimestamp
    ) public onlyOwner {
        if (initialized) revert PreviouslyInitialized();
        if (_allowlistStartTimestamp >= _startTimestamp) revert InvalidInitialization();
        initialized = true;

        maxSupply = _maxSupply;

        allowlistPrice = _allowlistPrice;
        allowlistSupply = _allowlistSupply;
        allowlistStartTimestamp = _allowlistStartTimestamp;

        price = _price;
        startTimestamp = _startTimestamp;
    }

    function setRequestMax(uint256 _max) public onlyOwner {
        requestMax = _max;
    }

    function _allowlistHook(bytes32[] calldata proof) internal validContractState("ALLOWLIST") {
        if (_allowlistMinted == allowlistSupply) revert MaxSupplyReached(allowlistSupply);

        unchecked {
            _allowlistMinted = _allowlistMinted + 1;
        }

        if (_allowlistMinted > allowlistSupply) {
            revert ExceedsMaxSupply(allowlistSupply);
        }

        if (msg.value != allowlistPrice) {
            revert InvalidPaymentAmount(allowlistPrice, msg.value);
        }

        _verifyProofOrRevert(msg.sender, proof);
    }

    function _publicSaleHook(uint128 _mintQuantity, uint256 _totalSupply) internal validContractState("PUBLIC") {
        if (_totalSupply == maxSupply) revert MaxSupplyReached(maxSupply);

        uint256 _requiredEther;
        uint256 _newSupply;

        unchecked {
            _requiredEther = _mintQuantity * price;
            _newSupply = _totalSupply + _mintQuantity;
        }

        if (_mintQuantity == 0 || _mintQuantity > requestMax) {
            revert ExceedsTransactionMaxOrMin(requestMax);
        }

        if (_newSupply > maxSupply) {
            revert ExceedsMaxSupply(maxSupply);
        }

        if (msg.value != _requiredEther) {
            revert InvalidPaymentAmount(_requiredEther, msg.value);
        }

        // set the sale to sold out
        if (_newSupply == maxSupply) soldOut = true;
    }

    function _withdrawFunds(address receiver) internal {
        (bool success, ) = payable(receiver).call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function _setInitialSupply(uint256 supply) internal {
        _initialSupply = supply;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}

error InvalidMintPhase(string current, string requested);
error InvalidInitialization();
error PreviouslyInitialized();
error InvalidPaymentAmount(uint256 required, uint256 sent);
error MaxSupplyReached(uint256 supply);
error ExceedsMaxSupply(uint256 supply);
error ExceedsTransactionMaxOrMin(uint256 max);
error TransferFailed();