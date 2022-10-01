// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "0xa-template-contracts/contracts/ERC721/ERC721AdminMintable.sol";
import "0xa-template-contracts/contracts/ERC721/ERC721AdminBurnable.sol";
import "0xa-template-contracts/contracts/ERC721/ERC721NativePurchasable.sol";
import "0xa-template-contracts/contracts/ERC721/ERC721OperatorApprovable.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract Token is ERC721AdminMintable, ERC721AdminBurnable, ERC721NativePurchasable, ERC721OperatorApprovable {
    uint256 private _tokenPrice;
    address public bclWalletAddress;

    constructor(
        uint256 _price,
        uint256 _tokenMaxSupply,
        address _bclWalletAddress,
        address _approvedOperator,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _contractURI,
        address[] memory _adminAddresses
    )
        ERC721NativePurchasable(_tokenMaxSupply, _name, _symbol, _baseURI, _contractURI)
        AdminControlled(_adminAddresses)
    {
        bclWalletAddress = _bclWalletAddress;
        approvedOperator = _approvedOperator;
        _tokenPrice = _price;
    }

    /**
     * @dev See {ERC721Purchasable-tokenPrice}.
     */
    function tokenPrice(uint256) public view override returns (uint256) {
        return _tokenPrice;
    }

    /**
     * @notice Updates token price
     * @param _price Token new price to be set
     * @dev Only admin addresses allowed
     */
    function setTokenPrice(uint256, uint256 _price) external override onlyAdminAddress {
        _tokenPrice = _price;
    }

    function _getPaymentDetails(uint256 amount, uint256)
        internal
        view
        override
        returns (address[] memory receiverAddresses, uint[] memory amounts)
    {
        receiverAddresses = new address[](1);
        receiverAddresses[0] = bclWalletAddress;

        amounts = new uint256[](1);
        amounts[0] = amount;

        return (receiverAddresses, amounts);
    }

    /**
     * @dev Updates BCL wallet address
     * @param _bclWalletAddress New BCL wallet address to be set
     */
    function setBCLWalletAddress(address _bclWalletAddress) external onlyAdminAddress {
        bclWalletAddress = _bclWalletAddress;
    }

    /**
     * @notice Updates token max supply
     * @param _maxSupply Token max supply to be set
     * @dev Only admin addresses allowed
     */
    function setTokenMaxSupply(uint256 _maxSupply) external onlyAdminAddress {
        totalMaxSupply = _maxSupply;
    }

    /**
     * @dev See {ERC721OperatorApprovable-isApprovedForAll}.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721, ERC721OperatorApprovable)
        returns (bool)
    {
        return ERC721OperatorApprovable.isApprovedForAll(_owner, _operator);
    }
}