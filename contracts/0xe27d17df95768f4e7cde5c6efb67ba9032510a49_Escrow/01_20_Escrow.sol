// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {Sendable} from "../Sendable.sol";

import {IEscrow} from "../interfaces/IEscrow.sol";

contract Escrow is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    IERC721Receiver,
    Sendable,
    IEscrow
{
    bytes32 public constant ESCROW_MANAGER_ROLE =
        keccak256("ESCROW_MANAGER_ROLE");

    address public orderBook;

    event Debug(address sender, address endstateOperations);
    event Log(string func);
    event DebugLock(address from, address dis, uint256 tokenId);

    modifier onlyOrderBookOrAdmin() {
        emit Debug(msg.sender, orderBook);
        //require(
        //    msg.sender == orderBook || hasRole(ESCROW_MANAGER_ROLE, msg.sender),
        //    "Escrow: invalid caller"
        //);
        _;
    }

    fallback() external payable {
        emit Log("fallback");
    }

    receive() external payable {
        emit Log("receive");
    }

    function initialize(address _orderBook) external initializer {
        __Ownable_init_unchained();
        orderBook = _orderBook;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function lock(
        address drop,
        uint256 tokenId,
        address from
    ) external override onlyOrderBookOrAdmin {
        //emit DebugLock(from, address(this), tokenId);

        IERC721(drop).safeTransferFrom(from, address(this), tokenId);

        emit LockNFT(from, drop, tokenId);
    }

    function releaseFund(
        address to,
        uint256 price
    ) external override onlyOrderBookOrAdmin {
        sendEth(payable(to), price);

        emit ReleaseFund(to, price);
    }

    function releaseNFT(
        address to,
        address drop,
        uint256 tokenId
    ) external override onlyOrderBookOrAdmin {
        require(
            IERC721(drop).ownerOf(tokenId) == address(this),
            "Escrow: doesn't exist"
        );
        IERC721(drop).safeTransferFrom(address(this), to, tokenId);

        emit ReleaseNFT(to, drop, tokenId);
    }

    function setupManagerRole(
        address account,
        bool isManager
    ) external onlyOwner {
        require(account != address(0), "Escrow: invalid account");

        if (isManager) {
            grantRole(ESCROW_MANAGER_ROLE, account);
        } else {
            revokeRole(ESCROW_MANAGER_ROLE, account);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}