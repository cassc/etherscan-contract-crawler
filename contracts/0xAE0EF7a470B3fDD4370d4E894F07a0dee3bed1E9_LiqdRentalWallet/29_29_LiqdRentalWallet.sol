// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1271Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "./interface/ILiqdRentalVault.sol";
import "./interface/ILiqdRentalWallet.sol";
import "./interface/IInvokeVerifier.sol";
import "./library/NftTransferLibrary.sol";

contract LiqdRentalWallet is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable,
    IERC1271Upgradeable,
    ILiqdRentalWallet
{
    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes4 internal constant MAGICVALUE = 0x1626ba7e; // bytes4(keccak256("isValidSignature(bytes32,bytes)")

    address public vault; // Liqd Rental Vault address
    address public collection;
    uint256 public tokenId;
    NftTransferLibrary.NftTokenType public nftTokenType;
    uint256 public rentalId;

    function initialize(
        address _owner,
        address _collection,
        uint256 _tokenId,
        NftTransferLibrary.NftTokenType _nftTokenType,
        uint256 _rentalId
    ) public override initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721Holder_init();
        __ERC1155Holder_init();

        _transferOwnership(_owner);
        vault = msg.sender;
        collection = _collection;
        tokenId = _tokenId;
        nftTokenType = _nftTokenType;
        rentalId = _rentalId;
    }

    function invokeVerifier() public view returns (address) {
        return ILiqdRentalVault(vault).invokeVerifier();
    }

    /// @notice return nft back to the rental vault
    function withdrawNft() external override nonReentrant {
        require(msg.sender == vault, "ONLY_VAULT");

        // transfer nft back to vault
        NftTransferLibrary.transferNft(
            address(this),
            msg.sender,
            collection,
            tokenId,
            nftTokenType
        );
    }

    /// @notice invoke external transaction call
    function invoke(
        address target,
        uint256 value,
        bytes calldata data
    ) external nonReentrant returns (bytes memory) {
        require(
            IInvokeVerifier(invokeVerifier()).verify(
                target,
                value,
                data,
                msg.sender,
                owner(),
                ILiqdRentalVault(vault).queryRental(rentalId)
            ),
            "invalid invoke"
        );

        (bool success, bytes memory result) = target.call{value: value}(data);
        require(success, "invoke failed");

        return result;
    }

    /**
     * @notice claims airdrop allocation of holding NFT
     * @dev will return all available token balances to the owner
     * @param _token the airdrop token address
     */
    function claimAirdrop(address _token, address _recipient)
        external
        onlyOwner
        nonReentrant
    {
        // it's safer to check if owner provided collection address
        require(_token != address(0) && _token != collection, "INVALID_TOKEN");

        uint256 available = IERC20Upgradeable(_token).balanceOf(address(this));
        require(available > 0, "NO_CLAIMABLE");

        IERC20Upgradeable(_token).safeTransfer(_recipient, available);
    }

    /**
     * @notice Verifies that the signer is the owner
     * @param _hash hash of sign message
     * @param _signature the signature of sign message
     */
    function isValidSignature(bytes32 _hash, bytes calldata _signature)
        external
        view
        override
        returns (bytes4)
    {
        // Validate signatures
        if (_hash.toEthSignedMessageHash().recover(_signature) == owner()) {
            return MAGICVALUE;
        } else {
            return 0xffffffff;
        }
    }
}