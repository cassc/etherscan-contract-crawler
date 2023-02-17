// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./ERC2981/ERC2981.sol";

/**
 * @dev Learn more about this project on alphafounders.xyz
 *
 *         _          _                ___                          _
 *        | |        | |              / __)                        | |
 *  _____ | |  ____  | |__   _____  _| |__  ___   _   _  ____    __| | _____   ____  ___
 * (____ || | |  _ \ |  _ \ (____ |(_   __)/ _ \ | | | ||  _ \  / _  || ___ | / ___)/___)
 * / ___ || | | |_| || | | |/ ___ |  | |  | |_| || |_| || | | |( (_| || ____|| |   |___ |
 * \_____| \_)|  __/ |_| |_|\_____|  |_|   \___/ |____/ |_| |_| \____||_____)|_|   (___/
 *            |_|
 *
 **/

contract AlphafoundersCharity is
    ERC1155,
    AccessControl,
    ERC1155Burnable,
    ERC2981,
    ERC1155Supply
{
    // Access Control Roles
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    // Token name
    string public name;
    // Token symbol
    string public symbol;
    // Base URI
    string public _baseTokenURI;

    // Sale Stages Enabled / Disabled
    mapping(uint256 => bool) public identifierMintable;
    // Token prices in wei
    mapping(uint256 => uint256) public identifierMintprice;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory _name, string memory _symbol) ERC1155("") {
        name = _name;
        symbol = _symbol;
        _setDefaultRoyalty(msg.sender, 1000);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(WITHDRAWER_ROLE, msg.sender);
        // Setup First Token Right away
        identifierMintable[1] = true;
        identifierMintprice[1] = 0.0135 ether;
    }

    /**
     * @dev Helper to manage minting enabled and price for a token
     * @param tokenId token id to change the settings for
     * @param mintingEnabled whether or not minting is enabled
     * @param tokenPrice the price of the token
     */
    function setTokenSettings(
        uint256 tokenId,
        bool mintingEnabled,
        uint256 tokenPrice
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        identifierMintable[tokenId] = mintingEnabled;
        identifierMintprice[tokenId] = tokenPrice;
    }

    /**
     * @dev Setter for baseURI
     */
    function setBaseURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _baseTokenURI = newuri;
    }

    /**
     * @dev Getter for baseURI
     */
    function _baseURI() internal view virtual returns (string memory) {
        if (bytes(_baseTokenURI).length > 0) {
            return _baseTokenURI;
        }
        return
            string(
                abi.encodePacked(
                    "https://metadata.bowline.app/",
                    Strings.toHexString(uint256(uint160(address(this))), 20),
                    "/"
                )
            );
    }

    /**
     * @dev Helper to set the token uri for a specific token
     *
     * @param tokenId token id to set the uri for
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory tokenURI = _tokenURIs[tokenId];

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return
            bytes(tokenURI).length > 0
                ? tokenURI
                : string(abi.encodePacked(_baseURI(), _toString(tokenId)));
    }

    /**
     * @dev Contract uri getter
     *
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract-info.json"));
    }

    /**
     * @dev Admin mint to enable airdrops
     *
     * @param account token receiver
     * @param id the token id to mint
     * @param amount the amount of tokens to mint
     * @param data the data to pass to the receiver
     */
    function adminMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    /**
     * @dev Public mint
     *
     * @param account token receiver
     * @param id the token id to mint
     * @param amount the amount of tokens to mint
     * @param data the data to pass to the receiver
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public payable {
        require(
            identifierMintable[id] == true,
            "AlphafoundersCharity: Minting for this Identifier is not enabled"
        );
        require(
            msg.value >= identifierMintprice[id] * amount,
            "AlphafoundersCharity: Insufficient Amount"
        );

        _mint(account, id, amount, data);
    }

    /**
     * @dev Public mint in batches
     *
     * @param to token receiver
     * @param ids the token ids to mint
     * @param amounts the amounts of tokens to mint
     * @param data the data to pass to the receiver
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Hook for before transfer to only work when not paused
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory str)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /**
     * @dev Sends all funds sent to this contract to the the `msg.sender`.
     *
     * Requirements:
     * - `msg.sender` needs to have {WITHDRAWER_ROLE} and be payable
     */
    function withdrawalAll() external onlyRole(WITHDRAWER_ROLE) {
        require(payable(msg.sender).send(address(this).balance));
    }
}

/** created with bowline.app **/