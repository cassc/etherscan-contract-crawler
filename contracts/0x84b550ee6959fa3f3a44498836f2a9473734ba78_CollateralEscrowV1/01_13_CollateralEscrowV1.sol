pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

// Contracts
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "../interfaces/escrow/ICollateralEscrowV1.sol";

contract CollateralEscrowV1 is OwnableUpgradeable, ICollateralEscrowV1 {
    uint256 public bidId;
    /* Mappings */
    mapping(address => Collateral) public collateralBalances; // collateral address -> collateral

    /* Events */
    event CollateralDeposited(address _collateralAddress, uint256 _amount);
    event CollateralWithdrawn(
        address _collateralAddress,
        uint256 _amount,
        address _recipient
    );

    /**
     * @notice Initializes an escrow.
     * @notice The id of the associated bid.
     */
    function initialize(uint256 _bidId) public initializer {
        __Ownable_init();
        bidId = _bidId;
    }

    /**
     * @notice Returns the id of the associated bid.
     * @return The id of the associated bid.
     */
    function getBid() external view returns (uint256) {
        return bidId;
    }

    /**
     * @notice Deposits a collateral asset into the escrow.
     * @param _collateralType The type of collateral asset to deposit (ERC721, ERC1155).
     * @param _collateralAddress The address of the collateral token.
     * @param _amount The amount to deposit.
     */
    function depositAsset(
        CollateralType _collateralType,
        address _collateralAddress,
        uint256 _amount,
        uint256 _tokenId
    ) external payable virtual onlyOwner {
        require(_amount > 0, "Deposit amount cannot be zero");
        _depositCollateral(
            _collateralType,
            _collateralAddress,
            _amount,
            _tokenId
        );
        Collateral storage collateral = collateralBalances[_collateralAddress];

        //Avoids asset overwriting.  Can get rid of this restriction by restructuring collateral balances storage so it isnt a mapping based on address.
        require(
            collateral._amount == 0,
            "Unable to deposit multiple collateral asset instances of the same contract address."
        );

        collateral._collateralType = _collateralType;
        collateral._amount = _amount;
        collateral._tokenId = _tokenId;
        emit CollateralDeposited(_collateralAddress, _amount);
    }

    /**
     * @notice Withdraws a collateral asset from the escrow.
     * @param _collateralAddress The address of the collateral contract.
     * @param _amount The amount to withdraw.
     * @param _recipient The address to send the assets to.
     */
    function withdraw(
        address _collateralAddress,
        uint256 _amount,
        address _recipient
    ) external virtual onlyOwner {
        require(_amount > 0, "Withdraw amount cannot be zero");
        Collateral storage collateral = collateralBalances[_collateralAddress];
        require(
            collateral._amount >= _amount,
            "No collateral balance for asset"
        );
        _withdrawCollateral(
            collateral,
            _collateralAddress,
            _amount,
            _recipient
        );
        collateral._amount -= _amount;
        emit CollateralWithdrawn(_collateralAddress, _amount, _recipient);
    }

    /**
     * @notice Internal function for transferring collateral assets into this contract.
     * @param _collateralAddress The address of the collateral contract.
     * @param _amount The amount to deposit.
     * @param _tokenId The token id of the collateral asset.
     */
    function _depositCollateral(
        CollateralType _collateralType,
        address _collateralAddress,
        uint256 _amount,
        uint256 _tokenId
    ) internal {
        // Deposit ERC20
        if (_collateralType == CollateralType.ERC20) {
            SafeERC20Upgradeable.safeTransferFrom(
                IERC20Upgradeable(_collateralAddress),
                _msgSender(),
                address(this),
                _amount
            );
        }
        // Deposit ERC721
        else if (_collateralType == CollateralType.ERC721) {
            require(_amount == 1, "Incorrect deposit amount");
            IERC721Upgradeable(_collateralAddress).transferFrom(
                _msgSender(),
                address(this),
                _tokenId
            );
        }
        // Deposit ERC1155
        else if (_collateralType == CollateralType.ERC1155) {
            bytes memory data;

            IERC1155Upgradeable(_collateralAddress).safeTransferFrom(
                _msgSender(),
                address(this),
                _tokenId,
                _amount,
                data
            );
        } else {
            revert("Invalid collateral type");
        }
    }

    /**
     * @notice Internal function for transferring collateral assets out of this contract.
     * @param _collateral The collateral asset to withdraw.
     * @param _collateralAddress The address of the collateral contract.
     * @param _amount The amount to withdraw.
     * @param _recipient The address to send the assets to.
     */
    function _withdrawCollateral(
        Collateral memory _collateral,
        address _collateralAddress,
        uint256 _amount,
        address _recipient
    ) internal {
        // Withdraw ERC20
        if (_collateral._collateralType == CollateralType.ERC20) {
            IERC20Upgradeable(_collateralAddress).transfer(_recipient, _amount);
        }
        // Withdraw ERC721
        else if (_collateral._collateralType == CollateralType.ERC721) {
            require(_amount == 1, "Incorrect withdrawal amount");
            IERC721Upgradeable(_collateralAddress).transferFrom(
                address(this),
                _recipient,
                _collateral._tokenId
            );
        }
        // Withdraw ERC1155
        else if (_collateral._collateralType == CollateralType.ERC1155) {
            bytes memory data;

            IERC1155Upgradeable(_collateralAddress).safeTransferFrom(
                address(this),
                _recipient,
                _collateral._tokenId,
                _amount,
                data
            );
        } else {
            revert("Invalid collateral type");
        }
    }

    // On NFT Received handlers

    function onERC721Received(address, address, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata
    ) external returns (bytes4) {
        require(
            _ids.length == 1,
            "Only allowed one asset batch transfer per transaction."
        );
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }
}