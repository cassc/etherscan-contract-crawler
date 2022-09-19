// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../interfaces/IAdminRole.sol";
import "../../interfaces/ITokenCreator.sol";
import "../../interfaces/ICreatorApproval.sol";
import "./BlockMelonERC721TokenBase.sol";

abstract contract BlockMelonERC721Creator is
    ITokenCreator,
    BlockMelonERC721TokenBase
{
    using AddressUpgradeable for address;

    event AdminContractUpdated(address indexed adminContract);
    event CreatorApprovalContractUpdated(address indexed approvalContract);

    /// @dev bytes4(keccak256('tokenCreator(uint256)')) == 0x40c1a064
    bytes4 private constant _INTERFACE_ID_TOKEN_CREATOR = 0x40c1a064;
    ///@dev The contract address which manages admin accounts
    IAdminRole public adminContract;
    ///@dev The contract address which manages creator approvals
    ICreatorApproval public approvalContract;
    /// @dev Mapping from each NFT ID to its creator
    mapping(uint256 => address payable) private _tokenIdToCreator;

    function __BlockMelonERC721Creator_init_unchained()
        internal
        onlyInitializing
    {}

    modifier onlyBlockMelonAdmin() {
        require(
            adminContract.isAdmin(_msgSender()),
            "caller is not a BlockMelon admin"
        );
        _;
    }

    modifier isContract(address _contract) {
        require(_contract.isContract(), "address is not a contract");
        _;
    }

    function _updateAdminContract(address _adminContract)
        internal
        isContract(_adminContract)
    {
        adminContract = IAdminRole(_adminContract);
        emit AdminContractUpdated(_adminContract);
    }

    function _updateApprovalContract(address _approvalContract)
        internal
        isContract(_approvalContract)
    {
        approvalContract = ICreatorApproval(_approvalContract);
        emit CreatorApprovalContractUpdated(_approvalContract);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            _INTERFACE_ID_TOKEN_CREATOR == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        delete _tokenIdToCreator[tokenId];
    }

    /**
     * @dev Internal function to set the creator of a token ID.
     */
    function _setCreator(uint256 tokenId, address account) internal virtual {
        _tokenIdToCreator[tokenId] = payable(account);
    }

    /**
     * @dev See {ITokenCreator-tokenCreator}
     */
    function tokenCreator(uint256 tokenId)
        public
        view
        override
        returns (address payable)
    {
        return _tokenIdToCreator[tokenId];
    }

    uint256[50] private __gap;
}