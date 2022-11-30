// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract Harvestooor is Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
    using Address for address;
    using ERC165Checker for address;

    /**
     * Value each NFT will be harvested for (in wei).
     */
    uint256 public constant FIXED_NFT_VALUE = 1e10;

    /**
     * Maps a NFT to its prior owner.
     */
    mapping(address => mapping(uint256 => address)) private _priorOwnerByToken;

    /**
     * Struct which represent a ERC-721 NFT.
     */
    struct NFT {
        address tokenAddress;
        uint256 tokenId;
    }

    /**
     * Event emitted when ETH is sent to the contract.
     */
    event ValueReceived(address indexed sender, uint256 amount);

    /**
     * Event emitted when non fungible token(s) are harvested by the contract.
     */
    event TokensHarvested(address indexed sender, NFT[] tokens);

    /**
     * Event emitted when non fungible token(s) are repurchased.
     */
    event TokensRepurchased(address indexed sender, NFT[] tokens);

    /**
     * Returns the prior owner of a NFT given its address and tokenId.
     */
    function getPriorOwnerByToken(address tokenAddress, uint256 tokenId)
        external
        view
        returns (address)
    {
        return _priorOwnerByToken[tokenAddress][tokenId];
    }

    /**
     * Function which enables external consumers to sell
     * multiple ERC-721 NFTs to the contract. By calling this function,
     * the contract will transfer the tokens to itself (the contract)
     * and pay the sender a fixed amount of ETH for each token.
     */
    function sellTokens(NFT[] calldata tokens)
        external
        nonReentrant
        whenNotPaused
    {
        // Require 'tokens' to not be empty
        require(tokens.length > 0, "Harvestooor: 'tokens' must not be empty");

        address payable sender = payable(msg.sender);
        uint256 calculatedValue = tokens.length * FIXED_NFT_VALUE;

        // Require contract to contain enough ETH balance
        require(
            address(this).balance >= calculatedValue,
            "Harvestooor: Insufficient Balance"
        );

        for (uint256 i = 0; i < tokens.length; ++i) {
            address tokenAddress = tokens[i].tokenAddress;
            uint256 tokenId = tokens[i].tokenId;

            // Sanity check NFT implements IERC721 interface
            require(
                tokenAddress.supportsInterface(type(IERC721).interfaceId),
                "Harvestooor: Token must implement IERC721 interface"
            );

            IERC721 nft = IERC721(tokenAddress);

            // Sanity check NFT is being sold by its owner
            require(
                nft.ownerOf(tokenId) == sender,
                "Harvestooor: NFT must be sold by its owner"
            );

            // Write owner to ownerByToken map
            _priorOwnerByToken[tokenAddress][tokenId] = sender;

            // Safe Transfer NFT to self (this contract)
            nft.safeTransferFrom(sender, address(this), tokenId);
        }

        // Emit event
        emit TokensHarvested(sender, tokens);

        // Transfer ETH to sender
        Address.sendValue(sender, calculatedValue);
    }

    /**
     * Function which enables external consumers to repurchase multiple
     * ERC-721 NFTs from the contract. By calling this function, the
     * contract will accept a fixed amount of ETH for every token
     * and transfer previously sold tokens back to their previous owner.
     */
    function repurchaseTokens(NFT[] calldata tokens)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        // Require 'tokens' to not be empty
        require(tokens.length > 0, "Harvestooor: 'tokens' must not be empty");

        uint256 calculatedValue = tokens.length * FIXED_NFT_VALUE;

        // Require sender to have provided correct ETH value
        require(
            msg.value == calculatedValue,
            "Harvestooor: Transaction must include correct ETH value"
        );

        for (uint256 i = 0; i < tokens.length; ++i) {
            address tokenAddress = tokens[i].tokenAddress;
            uint256 tokenId = tokens[i].tokenId;

            // Require NFT to have previously been sold to the contract
            require(
                _priorOwnerByToken[tokenAddress][tokenId] == msg.sender,
                "Harvestooor: NFT must have been previously sold to the contract"
            );

            // Remove previous token from storage (must be done before token transfer)
            delete _priorOwnerByToken[tokenAddress][tokenId];

            // Transfer NFT back to sender (regular transfer)
            IERC721 nft = IERC721(tokenAddress);
            nft.transferFrom(address(this), msg.sender, tokenId);
        }

        // Emit event
        emit TokensRepurchased(msg.sender, tokens);
    }

    /**
     * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md#specification
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes memory
    ) public virtual override whenNotPaused returns (bytes4) {
        // Require NFT to have previously been sold to the contract (msg.sender is the NFT contract address)
        require(
            _priorOwnerByToken[msg.sender][tokenId] == from,
            "Harvestooor: NFT must have been previously sold to the contract"
        );

        return this.onERC721Received.selector;
    }

    /**
     * Pause the contract.
     */
    function pause() external nonReentrant onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * Unpause the contract.
     */
    function unpause() external nonReentrant onlyOwner whenPaused {
        _unpause();
    }

    /**
     * Deposit ETH funds into the contract.
     */
    function deposit() external payable nonReentrant whenNotPaused {
        require(msg.value > 0, "Harvestooor: Value must be greater than zero");
        emit ValueReceived(msg.sender, msg.value);
    }

    /**
     * Withdrawal ETH funds to the given recipient address.
     */
    function withdraw(address payable recipient, uint256 amount)
        external
        nonReentrant
        onlyOwner
    {
        require(amount > 0, "Harvestooor: 'amount' must be greater than zero");
        require(
            recipient != address(this),
            "Harvestooor: 'recipient' must be an outside account"
        );

        Address.sendValue(recipient, amount);
    }
}