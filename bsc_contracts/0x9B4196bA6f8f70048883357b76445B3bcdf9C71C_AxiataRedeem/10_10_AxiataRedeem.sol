// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

contract AxiataRedeem is Initializable, ContextUpgradeable, OwnableUpgradeable {
    /**
     * @dev Controller address
     */
    address private _controller;

    /**
     * @dev Faucet listing information.
     * Mapping: ERC1155 contract address => tokenId => depositor account => faucetQty
     */
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        private _faucetListing;

    /**
     * @dev Faucet event
     */
    event Deposit(
        address indexed nftContract,
        uint256 indexed tokenId,
        address from,
        uint256 qty
    );
    event Withdraw(
        address indexed nftContract,
        uint256 indexed tokenId,
        address to,
        uint256 qty
    );
    event Redeem(
        address indexed nftContract,
        uint256 indexed tokenId,
        address to,
        uint256 qty
    );

    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @dev Assign contract controller.
     * Permission: Contract owner.
     * @param to Controller address.
     */
    function setController(address to) external onlyOwner {
        _controller = to;
    }

    /**
     * @dev Getter for controller.
     */
    function controller() external view returns (address) {
        return _controller;
    }

    /**
     * @dev Get listing quantity.
     * @param nftContract NFT contract address.
     * @param tokenId Token ID.
     * @param owner Listing owner.
     */
    function listing(
        address nftContract,
        uint256 tokenId,
        address owner
    ) external view returns (uint256) {
        return _faucetListing[nftContract][tokenId][owner];
    }

    /**
     * @dev Private function to get qty.
     * @param nftContract NFT contract address.
     * @param qty Quantity for distribution.
     */
    function getSafeQty(address nftContract, uint256 qty)
        private
        view
        returns (uint256)
    {
        // Quantity must be bigger than 0
        require(qty > 0, "Faucet: Quantity cannot be zero");

        // Check for NFT type
        if (
            IERC165Upgradeable(nftContract).supportsInterface(
                type(IERC721Upgradeable).interfaceId
            )
        ) {
            return 1; // Always force to 1 if nft type is ERC721
        } else if (
            IERC165Upgradeable(nftContract).supportsInterface(
                type(IERC1155Upgradeable).interfaceId
            )
        ) {
            return qty;
        }

        return qty;
    }

    /**
     * @dev Private function to transfer nft.
     * @param from From address.
     * @param to To address.
     * @param nftContract NFT contract address.
     * @param tokenId Token ID.
     * @param qty Quantity for distribution.
     */
    function runTransfer(
        address from,
        address to,
        address nftContract,
        uint256 tokenId,
        uint256 qty
    ) private {
        // Check for NFT type
        if (
            IERC165Upgradeable(nftContract).supportsInterface(
                type(IERC721Upgradeable).interfaceId
            )
        ) {
            // Note: This contract must obtain approval
            // Execute transfer
            IERC721Upgradeable(nftContract).safeTransferFrom(from, to, tokenId);
        } else if (
            IERC165Upgradeable(nftContract).supportsInterface(
                type(IERC1155Upgradeable).interfaceId
            )
        ) {
            // Note: This contract must obtain approval
            // Execute transfer
            IERC1155Upgradeable(nftContract).safeTransferFrom(
                from,
                to,
                tokenId,
                qty,
                ""
            );
        }
    }

    /**
     * @dev Deposit NFTs for distribution.
     * @param nftContract NFT contract address.
     * @param tokenId Token ID.
     * @param qty Quantity for distribution.
     */
    function deposit(
        address nftContract,
        uint256 tokenId,
        uint256 qty
    ) external {
        uint256 _qty = getSafeQty(nftContract, qty);

        // Stake NFT to contract for distribution
        runTransfer(_msgSender(), address(this), nftContract, tokenId, _qty);

        // Update faucet information
        uint256 currentQty = _faucetListing[nftContract][tokenId][_msgSender()];
        _faucetListing[nftContract][tokenId][_msgSender()] = currentQty + _qty;

        // Event update
        emit Deposit(nftContract, tokenId, _msgSender(), _qty);
    }

    /**
     * @dev Withdraw deposited NFTs.
     * @param nftContract NFT contract address.
     * @param tokenId Token ID.
     * @param qty Quantity for distribution.
     */
    function withdraw(
        address nftContract,
        uint256 tokenId,
        uint256 qty
    ) external {
        uint256 _qty = getSafeQty(nftContract, qty);

        // Quantity must be valid
        require(
            _faucetListing[nftContract][tokenId][_msgSender()] >= _qty,
            "Faucet: Not enough token balance"
        );

        // Execute transfer
        runTransfer(address(this), _msgSender(), nftContract, tokenId, _qty);

        // Update faucet information
        uint256 currentQty = _faucetListing[nftContract][tokenId][_msgSender()];
        _faucetListing[nftContract][tokenId][_msgSender()] = currentQty - _qty;

        // Event update
        emit Withdraw(nftContract, tokenId, _msgSender(), _qty);
    }

    /**
     * @dev Execute NFT redeem. Can only be call from Controller.
     * @param nftContract NFT contract address.
     * @param tokenId Token ID.
     * @param from Token owner.
     * @param to Recipient address.
     * @param qty Quantity for distribution.
     */
    function redeem(
        address nftContract,
        uint256 tokenId,
        address from,
        address to,
        uint256 qty
    ) external {
        // Caller must be controller
        require(
            _msgSender() == _controller,
            "Faucet: Caller must be authorized controller"
        );

        uint256 _qty = getSafeQty(nftContract, qty);

        // Quantity must be valid
        require(
            _faucetListing[nftContract][tokenId][from] >= _qty,
            "Faucet: Not enough token balance"
        );

        // Execute transfer
        runTransfer(address(this), to, nftContract, tokenId, _qty);

        // Update faucet information
        uint256 currentQty = _faucetListing[nftContract][tokenId][from];
        _faucetListing[nftContract][tokenId][from] = currentQty - _qty;

        // Event update
        emit Redeem(nftContract, tokenId, to, _qty);
    }

    /**
     * @dev Implimentation which is called upon a safe transfer.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev Implimentation which is called upon a safe transfer.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}