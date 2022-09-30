// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IBag.sol";
import "./interfaces/IUnpacker.sol";
import "./helpers/MinterManaged.sol";

/**
 * @dev ASM The Next Legends - Bag contract
 */
contract Bag is IBag, ERC721Royalty, MinterManaged {
    IUnpacker public unpacker_; // ASM Unpacker contract, used for opening Bags

    uint256 public totalSupply;
    string public baseURI;
    bool public isAllowedToOpen;

    event BaseURIChanged(string newBaseURI);
    event ContractUpgraded(uint256 timestamp, string indexed contractName, address oldAddress, address newAddress);

    constructor(address manager, address asm) MinterManaged(manager, asm) ERC721("TNL Bag", "TNLB") {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(MinterManaged, ERC721Royalty, IBag)
        returns (bool)
    {
        if (MinterManaged.supportsInterface(interfaceId)) {
            return true;
        }
        return
            interfaceId == type(IBag).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(ERC721Royalty).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    /** ----------------------------------
     * ! Public functions
     * ----------------------------------- */

    /**
     * @notice
     * @dev This function can only be called from contracts or wallets with MINTER_ROLE
     * @param recipient The wallet address to receive a minted token
     */
    function mint(address recipient) external onlyRole(MINTER_ROLE) returns (uint256) {
        if (recipient == address(0)) revert InvalidInput(INVALID_ADDRESS);
        _mint(recipient, totalSupply);
        return totalSupply++;
    }

    /**
     * @notice
     * @param tokenId The token ID of a bag
     * @param recipient The wallet address to receive a content of the bag
     */
    function open(uint256 tokenId, address recipient) external whenAllowed {
        if (ownerOf(tokenId) != msg.sender) revert AccessError(WRONG_TOKEN_OWNER);
        if (recipient == address(0)) revert InvalidInput(INVALID_ADDRESS);

        unpacker_.unpack(tokenId, recipient);
        _burn(tokenId);
    }

    /**
     * @notice This function is designed to burn used (opened) bags
     * @dev This function can only be called by MINTER_ROLE
     * @param tokenId ID of token to burn
     */
    function burn(uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _burn(tokenId);
    }

    /** ----------------------------------
     * ! Manager's functions
     * ----------------------------------- */

    /**
     * @notice Upgrade Unpacker contract address
     * @dev This function can only be called from contracts or wallets with MANAGER_ROLE
     * @param newContract Address of new contract
     */
    function upgradeUnpackerContract(address newContract) external onlyRole(MANAGER_ROLE) {
        if (newContract == address(0)) revert InvalidInput(INVALID_ADDRESS);
        unpacker_ = IUnpacker(newContract);

        address oldContract = address(unpacker_);
        unpacker_ = IUnpacker(newContract);
        if (!unpacker_.supportsInterface(type(IUnpacker).interfaceId)) revert UpgradeError(WRONG_UNPACKER_CONTRACT);

        emit ContractUpgraded(block.timestamp, "Unpacker.sol", oldContract, newContract);
    }

    /**
     * @notice Get base URI for the tokenURI
     * @return address the baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Get base URI for the tokenURI
     * @dev emit an Event with new baseURI
     * @dev only MANAGER_ROLE can call this function
     * @param newURI new baseURI to set
     */
    function setBaseURI(string calldata newURI) external onlyRole(MANAGER_ROLE) {
        baseURI = newURI;
        emit BaseURIChanged(newURI);
    }

    /**
     * @notice Set the default royalty amount
     * @dev only MANAGER_ROLE can call this function
     * @param receiver wallet to collect royalties
     * @param feeNumerator percent of royalties, e.g. 2550 = 25.5%,  17.01% = 1701
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(MANAGER_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Set the royalty amount for the specific token
     * @dev only MANAGER_ROLE can call this function
     * @param tokenId specific tokenId to setup royalty
     * @param receiver wallet to collect royalties
     * @param feeNumerator percent of royalties, e.g. 2550 = 25.5%,  17.01% = 1701
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(MANAGER_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyRole(MANAGER_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev Removes default royalty information.
     */
    function deleteDefaultRoyalty() external onlyRole(MANAGER_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * @notice Manager can (dis)allow users to open their bags
     * @dev only MANAGER_ROLE can call this function
     * @param _isAllowedToOpen true of false
     */
    function allowToOpen(bool _isAllowedToOpen) external onlyRole(MANAGER_ROLE) {
        isAllowedToOpen = _isAllowedToOpen;
    }

    modifier whenAllowed() {
        if (isAllowedToOpen) _;
        else revert OpenError(NOT_ALLOWED);
    }
}