// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GoldenTicket is
    ERC721AQueryable,
    ERC2981,
    Ownable,
    Pausable,
    DefaultOperatorFilterer
{
    string private _name;
    string private _symbol;
    string public baseUri;

    mapping(uint256 => bool) private lockedTokens;
    mapping(address => bool) public permittedOperators;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory _baseUri,
        address recipient,
        uint96 value
    ) ERC721A(_name, _symbol) {
        _name = __name;
        _symbol = __symbol;
        baseUri = _baseUri;
        _setDefaultRoyalty(recipient, value);
    }

    /// @notice The name of the ERC721 token.
    function name()
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        return _name;
    }

    /// @notice The symbol of the ERC721 token.
    function symbol()
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        return _symbol;
    }

    /// @notice Sets the name and symbol of the ERC721 token.
    /// @param newName The new name for the token.
    /// @param newSymbol The new symbol for the token.
    function setNameAndSymbol(
        string calldata newName,
        string calldata newSymbol
    ) external onlyOwner {
        _name = newName;
        _symbol = newSymbol;
    }

    /// @notice The token base URI.
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    /// @notice Sets the base URI for the token metadata.
    /// @param _baseUri The new base URI for the token metadata.
    function setBaseUri(string calldata _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    /// @notice Pauses the contract, preventing token transfers.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, allowing token transfers.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Mints multiple tokens and assigns them to the specified addresses.
    /// @param to An array of addresses to which tokens will be minted.
    /// @param value An array of values representing the number of tokens to mint for each address.
    function mintMany(
        address[] calldata to,
        uint256[] calldata value
    ) external onlyOwner {
        require(to.length == value.length, "Mismatched lengths");
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], value[i]);
        }
    }

    /// @notice Sets the royalty fee for the specified recipient.
    /// @param recipient The address of the royalty recipient.
    /// @param value The value of the royalty fee.
    function setRoyalties(address recipient, uint96 value) public onlyOwner {
        _setDefaultRoyalty(recipient, value);
    }

    /// @notice Locks the specified tokens, preventing them from being transferred.
    /// @param tokenIds An array of token IDs to be locked.
    function lockTokens(uint256[] memory tokenIds) public {
        require(
            permittedOperators[msg.sender] || msg.sender == owner(),
            "Not an allowed operator"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(!lockedTokens[tokenIds[i]], "Token is already locked");
            lockedTokens[tokenIds[i]] = true;
        }
    }

    /// @notice Admin function to unlock the specified golden tickets, allowing them to be transferred.
    /// @param tokenIds An array of token IDs to be unlocked.
    function unlockTokens(uint256[] memory tokenIds) public {
        require(
            permittedOperators[msg.sender] || msg.sender == owner(),
            "Not an allowed operator"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(lockedTokens[tokenIds[i]], "Token is already unlocked");
            lockedTokens[tokenIds[i]] = false;
        }
    }

    /// @notice Admin function to burn and redeem the golden ticket.
    /// @param tokenIds An array of locked token IDs to be burned.
    function burnLockedTokens(uint256[] memory tokenIds) public {
        require(
            permittedOperators[msg.sender] || msg.sender == owner(),
            "Not an allowed operator"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                lockedTokens[tokenIds[i]],
                "Token must be locked before burning"
            );
            _burn(tokenIds[i]);
        }
    }

    /// @notice Adds multiple addresses as permitted operators.
    /// @param operators An array of addresses to be added as permitted operators.
    function addPermittedOperators(
        address[] memory operators
    ) public onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            if (!permittedOperators[operators[i]]) {
                permittedOperators[operators[i]] = true;
            }
        }
    }

    /// @notice Removes multiple addresses from the permitted operators list.
    /// @param operators An array of addresses to be removed from the permitted operators list.
    function removePermittedOperators(
        address[] memory operators
    ) public onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            permittedOperators[operators[i]] = false;
        }
    }

    /// @notice Retrieves the lock statuses of the specified tokens.
    /// @param tokenIds An array of token IDs to check the lock status.
    /// @return An array of boolean values representing the lock statuses of the tokens.
    function getTokenLockStatuses(
        uint256[] memory tokenIds
    ) public view returns (bool[] memory) {
        bool[] memory lockStatuses = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            lockStatuses[i] = lockedTokens[tokenIds[i]];
        }
        return lockStatuses;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
            if (
                from != address(0) &&
                from != owner() &&
                !permittedOperators[from]
            ) {
                require(
                    !lockedTokens[i],
                    "Token is locked and cannot be transferred"
                );
            }
            if (lockedTokens[i]) {
                require(
                    msg.sender == owner() || permittedOperators[msg.sender],
                    "Not an allowed operator"
                );
            }
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
        whenNotPaused
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
        whenNotPaused
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
        whenNotPaused
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}