// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "../interfaces/IAccessManager.sol";
import "../interfaces/IAddressesRegistry.sol";
import "../libraries/Errors.sol";
import {IAccessNFT} from "../interfaces/IAccessNFT.sol";

/**
 * @title AccessNFT
 * @author Souq.Finance
 * @notice The ERC1155 Access NFT Contract that enables users to interact with the Pool at approved times and get discounts if set
 * @notice License: https://souq-peripheral-v1.s3.amazonaws.com/LICENSE.md
 */

contract AccessNFT is ERC1155PresetMinterPauser, IAccessNFT {
    bool public deadlinesOn;
    address public immutable addressesRegistry;
    //function hashes -> tokenIDs -> deadline
    mapping(bytes32 => mapping(uint256 => uint256)) public deadlines;
    //tokenIDs -> fee discount percentage
    mapping(uint256 => uint256) public discountPercentage;
    //flashloan protection
    mapping(uint256 => bytes32) public tokenUsedInTransaction;

    constructor(address _addressesRegistry, bool _deadlinesOn) ERC1155PresetMinterPauser("") {
        addressesRegistry = _addressesRegistry;
        deadlinesOn = _deadlinesOn;
    }

    /**
     * @dev modifier for when the address is the pool admin only
     */
    modifier onlyPoolAdmin() {
        require(
            IAccessManager(IAddressesRegistry(addressesRegistry).getAccessManager()).isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_POOL_ADMIN
        );
        _;
    }

    /// @inheritdoc IAccessNFT
    function HasAccessNFT(address user, uint256 tokenId, string calldata functionName) external view returns (bool) {
        bytes32 hashedName = keccak256(bytes(functionName));
        require(!isContract(user), Errors.USER_CANNOT_BE_CONTRACT);
        require(deadlines[hashedName][tokenId] != 0, Errors.DEADLINE_NOT_FOUND);
        //Everyone has access after deadline ends
        //Using block.timestamp is safer than block number
        //See: https://ethereum.stackexchange.com/questions/11060/what-is-block-timestamp/11072#11072
        if ((block.timestamp > deadlines[hashedName][tokenId]) || (deadlinesOn == false)) {
            return true;
        }
        return this.balanceOf(user, tokenId) > 0;
    }

    /**
     * @dev Safely transfers NFTs from one address to another with flashloan protection
     * @param from The account to transfer from
     * @param to The account to transfer to
     * @param id the token id
     * @param amount The amount
     * @param data The data of the transaction
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
        bytes32 currentTransaction = keccak256(abi.encodePacked(block.number));
        require(tokenUsedInTransaction[id] != currentTransaction, Errors.FLASHLOAN_PROTECTION_ENABLED);
        tokenUsedInTransaction[id] = keccak256(abi.encodePacked(block.number));
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev Safely transfers multiple NFTs from one address to another with flashloan protection
     * @param from The account to transfer from
     * @param to The account to transfer to
     * @param ids the token ids array
     * @param amounts The amounts array
     * @param data The data of the transaction
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        bytes32 currentTransaction = keccak256(abi.encodePacked(block.number));
        for (uint256 i = 0; i < ids.length; i++) {
            require(tokenUsedInTransaction[ids[i]] != currentTransaction, Errors.FLASHLOAN_PROTECTION_ENABLED);
            tokenUsedInTransaction[ids[i]] = keccak256(abi.encodePacked(block.number));
        }
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @inheritdoc IAccessNFT
    function setDeadline(string calldata functionName, uint256 deadline, uint256 tokenId) external onlyPoolAdmin {
        bytes32 hashedName = keccak256(bytes(functionName));
        deadlines[hashedName][tokenId] = deadline;

        emit DeadlineSet(functionName, hashedName, deadline, tokenId);
    }

    /// @inheritdoc IAccessNFT
    function getDeadline(bytes32 hashedFunctionName, uint256 tokenId) external view returns (uint256) {
        return deadlines[hashedFunctionName][tokenId];
    }

    /// @inheritdoc IAccessNFT
    function toggleDeadlines() external onlyPoolAdmin {
        deadlinesOn = !deadlinesOn;

        emit ToggleDeadlines(deadlinesOn);
    }

    /// @inheritdoc IAccessNFT
    function setFeeDiscount(uint256 tokenId, uint256 discount) external onlyPoolAdmin {
        require(discount >= 0, "Discount must not be less than 0");
        require(discount <= 100, "Discount must be less than or equal to 100");
        discountPercentage[tokenId] = discount;
    }

    /**
     * @dev Checks if an account address is a contract
     * @param account The account address
     */
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470; // hash of empty string
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /// @inheritdoc IAccessNFT
    function setURI(string memory newuri) external onlyPoolAdmin {
        _setURI(newuri);
    }

    /// @inheritdoc IAccessNFT
    function adminBurn(address account, uint256 id, uint256 amount) external onlyPoolAdmin {
        _burn(account, id, amount);
    }
}