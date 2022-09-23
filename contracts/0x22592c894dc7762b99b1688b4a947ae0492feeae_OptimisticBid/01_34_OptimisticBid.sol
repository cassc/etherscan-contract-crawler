// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";

import {INounletRegistry} from "../interfaces/INounletRegistry.sol";
import {INounletSupply} from "../interfaces/INounletSupply.sol";
import {INounletAuction} from "../interfaces/INounletAuction.sol";
import {IOptimisticBid, BidInfo, State} from "../interfaces/IOptimisticBid.sol";
import {ITransfer} from "../interfaces/ITransfer.sol";
import {IVault} from "../interfaces/IVault.sol";

import {Multicall} from "../utils/Multicall.sol";
import {NFTReceiver} from "../utils/NFTReceiver.sol";
import {NounletToken} from "../NounletToken.sol";
import {Permission} from "../interfaces/IVaultRegistry.sol";
import {SafeSend} from "../utils/SafeSend.sol";

/// @title OptimisticBid
/// @author Tessera
/// @notice Module contract for optimistic bid reconstitution
contract OptimisticBid is IOptimisticBid, Multicall, NFTReceiver, ReentrancyGuard, SafeSend {
    /// @notice Address of VaultRegistry contract
    address public immutable registry;
    /// @notice Address of Supply target contract
    address public immutable supply;
    /// @notice Address of Transfer target contract
    address public immutable transfer;
    /// @notice Address of the minter contract
    address public immutable auction;
    /// @notice Time length of the rejection period
    uint256 public constant REJECTION_PERIOD = 7 days;
    /// @notice Percentage increase in fraction price to outbid a live pool
    uint256 public constant MIN_INCREASE = 5;
    /// @notice Mapping of vault address to bid struct
    mapping(address => BidInfo) public bidInfo;

    /// @notice Initializes registry, supply, transfer, and auction contracts
    constructor(
        address _registry,
        address _supply,
        address _transfer,
        address _auction
    ) {
        registry = _registry;
        supply = _supply;
        transfer = _transfer;
        auction = _auction;
    }

    /// @dev Callback for receiving ether when the calldata is empty
    receive() external payable {}

    /// @notice Starts the auction for a buyout pool
    /// @dev Amounts will always be 1
    /// @param _vault Address of the vault
    /// @param _ids Deposit ids of fractions
    /// @param _amounts Deposit amount of fractions
    function start(
        address _vault,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external payable nonReentrant {
        address token = INounletRegistry(registry).vaultToToken(_vault);
        require(token != address(0), "vault doesn't exist");

        uint256 idsLength = _ids.length;
        uint256 amountsLength = _amounts.length;
        require(idsLength == amountsLength, "length mismatch");

        (, , uint32 endTime) = INounletAuction(auction).auctionInfo(_vault, 100);
        (, uint96 id) = INounletAuction(auction).vaultInfo(_vault);
        /// 100 and after the last auction endTime
        if (id <= uint96(100) || block.timestamp < uint256(endTime)) revert("still minting");

        (, , State current, , , ) = this.bidInfo(_vault);
        State required = State.INACTIVE;
        if (current != required) revert InvalidState(required, current);

        uint256 totalSupply = NounletToken(token).totalSupply();
        uint256 nounletPrice = msg.value / (totalSupply - idsLength);
        uint256 buyoutPrice = idsLength * nounletPrice + msg.value;

        bidInfo[_vault] = BidInfo(
            block.timestamp,
            msg.sender,
            State.LIVE,
            nounletPrice,
            msg.value,
            totalSupply
        );
        emit Start(_vault, msg.sender, block.timestamp, buyoutPrice, nounletPrice);

        NounletToken(token).safeBatchTransferFrom(msg.sender, address(this), _ids, _amounts, "");
    }

    /// @notice Buys fractional tokens in exchange for ether from a pool
    /// @param _vault Address of the vault
    /// @param _ids Deposit ids of fractions
    /// @param _amounts Deposit amounts of fractions
    function buyFractions(
        address _vault,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external payable nonReentrant {
        uint256 idsLength = _ids.length;
        uint256 amountsLength = _amounts.length;
        require(idsLength == amountsLength, "length mismatch");

        address token = INounletRegistry(registry).vaultToToken(_vault);
        require(token != address(0), "vault doesn't exist");

        (uint256 startTime, address proposer, State current, uint256 fractionPrice, , ) = this
            .bidInfo(_vault);

        State required = State.LIVE;
        if (current != required) revert InvalidState(required, current);

        {
            uint256 endTime = startTime + REJECTION_PERIOD;
            uint256 timestamp = block.timestamp;
            if (timestamp > endTime) revert TimeExpired(timestamp, endTime);
        }
        if (msg.value != fractionPrice * idsLength) revert InvalidPayment();

        bidInfo[_vault].ethBalance += msg.value;
        emit BuyFractions(msg.sender, idsLength);

        if (NounletToken(token)._ballots(address(this)) == idsLength)
            _end(_vault, proposer, bidInfo[_vault].ethBalance);
        NounletToken(token).safeBatchTransferFrom(address(this), msg.sender, _ids, _amounts, "");
    }

    /// @notice Ends the auction for a live buyout pool
    /// @param _vault Address of the vault
    /// @param _ids Deposit ids of fractions
    /// @param _amounts Deposit amounts of fractions
    /// @param _burnProof Merkle proof for burning fractional tokens
    function end(
        address _vault,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes32[] calldata _burnProof
    ) external {
        address token = INounletRegistry(registry).vaultToToken(_vault);
        require(token != address(0), "vault doesn't exist");

        (uint256 startTime, address proposer, State current, , uint256 ethBalance, ) = this.bidInfo(
            _vault
        );

        State required = State.LIVE;
        if (current != required) revert InvalidState(required, current);

        uint256 amount = _ids.length;
        if (block.timestamp > startTime + 4 days) {
            require(amount == NounletToken(token)._ballots(address(this)), "missing ids");
            if (amount > 0) {
                bidInfo[_vault].state = State.SUCCESS;
                // Initializes vault transaction
                bytes memory data = abi.encodeCall(INounletSupply.batchBurn, (address(this), _ids));
                // Executes burn of fractional tokens from pool
                IVault(payable(_vault)).execute(supply, data, _burnProof);
            } else {
                delete bidInfo[_vault];
                NounletToken(token).safeBatchTransferFrom(
                    address(this),
                    proposer,
                    _ids,
                    _amounts,
                    ""
                );
                _sendEthOrWeth(proposer, ethBalance);
            }
        } else {
            revert("not endable");
        }
    }

    /// @notice Cashes out proceeds from a successful buyout
    /// @param _vault Address of the vault
    /// @param _ids Deposit amount of fractions
    /// @param _burnProof Merkle proof for burning fractional tokens
    function cash(
        address _vault,
        uint256[] memory _ids,
        bytes32[] calldata _burnProof
    ) external {
        address token = INounletRegistry(registry).vaultToToken(_vault);
        require(token != address(0), "vault doesn't exist");

        (, , State current, , uint256 ethBalance, ) = this.bidInfo(_vault);
        State required = State.SUCCESS;
        if (current != required) revert InvalidState(required, current);

        uint256 amount = _ids.length;
        uint256 totalSupply = NounletToken(token).totalSupply();
        uint256 share = (amount * ethBalance) / totalSupply;
        bidInfo[_vault].ethBalance -= share;

        bytes memory data = abi.encodeCall(INounletSupply.batchBurn, (msg.sender, _ids));
        IVault(payable(_vault)).execute(supply, data, _burnProof);

        _sendEthOrWeth(msg.sender, share);
    }

    /// @notice Withdraws an ERC-721 token from a vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    /// @param _to Address of the receiver
    /// @param _tokenId ID of the token
    /// @param _erc721TransferProof Merkle proof for transferring an ERC-721 token
    function withdrawERC721(
        address _vault,
        address _token,
        address _to,
        uint256 _tokenId,
        bytes32[] calldata _erc721TransferProof
    ) external {
        address token = INounletRegistry(registry).vaultToToken(_vault);
        require(token != address(0), "vault doesn't exist");

        (, address proposer, State current, , , ) = this.bidInfo(_vault);
        State required = State.SUCCESS;
        if (current != required) revert InvalidState(required, current);
        require(msg.sender == proposer, "not winner");

        // Initializes vault transaction
        bytes memory data = abi.encodeCall(
            ITransfer.ERC721TransferFrom,
            (_token, _vault, _to, _tokenId)
        );
        // Executes transfer of ERC721 token to caller
        IVault(payable(_vault)).execute(transfer, data, _erc721TransferProof);
    }

    /// @notice Gets the list of leaf nodes used to generate a merkle tree
    /// @dev Leaf nodes are hashed permissions of the merkle tree
    /// @return nodes Hashes of leaf nodes
    function getLeafNodes() external view returns (bytes32[] memory nodes) {
        // Gets list of permissions from this module
        Permission[] memory permissions = getPermissions();
        uint256 length = permissions.length;
        nodes = new bytes32[](length);
        for (uint256 i; i < length; ) {
            // Hashes permission into leaf node
            nodes[i] = keccak256(abi.encode(permissions[i]));
            // Can't overflow since loop is a fixed size
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions List of vault permissions
    function getPermissions() public view returns (Permission[] memory permissions) {
        permissions = new Permission[](2);
        // Burn function selector from supply contract
        permissions[0] = Permission(address(this), supply, INounletSupply.batchBurn.selector);
        // ERC721TransferFrom function selector from transfer contract
        permissions[1] = Permission(address(this), transfer, ITransfer.ERC721TransferFrom.selector);
    }

    /// @dev Terminates live pool and transfers remaining balance
    function _end(
        address _vault,
        address _proposer,
        uint256 _amount
    ) internal {
        delete bidInfo[_vault];
        _sendEthOrWeth(_proposer, _amount);
    }

    /// @dev Calculates price of fractions and total buyout
    function _calculatePrice(
        uint256 _ethAmount,
        uint256 _fractionAmount,
        uint256 _fractionSupply
    ) internal pure returns (uint256 fractionPrice, uint256 buyoutPrice) {
        fractionPrice = _ethAmount / (_fractionSupply - _fractionAmount);
        buyoutPrice = _fractionAmount * fractionPrice + _ethAmount;
    }
}