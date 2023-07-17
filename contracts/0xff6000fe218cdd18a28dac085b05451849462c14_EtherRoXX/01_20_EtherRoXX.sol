// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721} from "solady/tokens/ERC721.sol";
import {Rockify} from "./Rockify.sol";
import {EtherRoXXConstantsEventsAndErrors} from "./EtherRoXXConstantsEventsAndErrors.sol";
import {XXYYZZ} from "xxyyzz/XXYYZZ.sol";
import {Base64} from "solady/utils/Base64.sol";
import {LibString} from "solady/utils/LibString.sol";
import {IERC4906, IERC165} from "./interfaces/IERC4906.sol";
import {Ownable} from "solady/auth/Ownable.sol";

/**
 * @title EtherRoXX
 * @author emo.eth, aspyn.eth
 * @notice EtherRoXX is a collection of fully onchain, collectible rocks. Each rock has a unique hex value.
 *         Rocks may be "rerolled" to new hex values, provided that the rock's owner also owns
 *         the corresponding XXYYZZ color.
 *
 *         Tokens may be burned, which removes it from the token supply, but unless the token was finalized, its
 *         particular hex value may be minted or rerolled again.
 *
 *         Mints are pseudorandom by default, leveraging the pseudorandomness defined in the XXYYZZ contract, unless
 *         one of the "Specific" methods is called. To prevent front-running "specific" mint transactions, the rocks
 *         contract uses a commit-reveal scheme. Users must commit a hash of their desired hex value with a secret salt,
 *         wait at least one minute, and then submit their mint transaction with the original hex value(s) and salt.
 *         Multiple IDs may be minted in a single transaction by committing the result of hash of all IDs in order
 *         with a single secret salt.
 */
contract EtherRoXX is ERC721, EtherRoXXConstantsEventsAndErrors, IERC4906, Ownable {
    using Base64 for bytes;
    using LibString for uint256;

    address payable immutable XXYYZZ_ADDRESS;

    uint256 public numMinted;

    constructor(address initialOwner, address payable _xxyyzzAddress) payable {
        XXYYZZ_ADDRESS = _xxyyzzAddress;
        _initializeOwner(initialOwner);
        _mintTo(initialOwner, 69);
    }

    /**
     * @dev allows receiving ether refunds from XXYYZZ mints
     */
    receive() external payable {}

    /**
     * @notice Withdraw any ETH in the contract to the owner. OnlyOwner.
     * @dev This is a safety function to allow the owner to withdraw any ETH sent to the contract
     */
    function withdraw() public onlyOwner {
        address _owner = owner();
        assembly {
            if iszero(call(gas(), _owner, selfbalance(), 0, 0, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    //////////////
    // METADATA //
    //////////////

    ///@notice Returns the name of the token
    function name() public pure override returns (string memory) {
        // note that this is unsafe to call internally, as it abi-encodes the name and
        // performs a low-level return
        assembly {
            mstore(0x20, 0x20)
            mstore(0x4a, 0x0a457468657220526f5858)
            return(0x20, 0x80)
        }
    }

    ///@notice Returns the symbol of the token
    function symbol() public pure override returns (string memory) {
        // note that this is unsafe to call internally, as it abi-encodes the name and
        // performs a low-level return
        assembly {
            mstore(0x20, 0x20)
            mstore(0x44, 0x04524f5858)
            return(0x20, 0x80)
        }
    }

    ///@notice Returns the base64-encoded token-level metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert TokenDoesNotExist();
        }

        return string.concat(
            "data:application/json;base64,",
            bytes(
                string.concat(
                    '{"name":"#',
                    tokenId.toHexStringNoPrefix(3),
                    '","description":"Ether RoXX are onchain rocks composable with XXYYZZ colors","image":"data:image/svg+xml;base64,',
                    bytes(Rockify.rockify(tokenId)).encode(),
                    '","traits":[{"trait_type":"XXYYZZ Color","value":"#',
                    tokenId.toHexStringNoPrefix(3),
                    '"}]}'
                )
            ).encode()
        );
    }

    ///@notice Return the base64-encoded contract-level metadata
    function contractURI() public pure returns (string memory) {
        return string.concat("data:application/json;base64,", bytes(_stringContractURI()).encode());
    }

    ///@inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(ERC721, IERC165)
        returns (bool result)
    {
        assembly {
            let s := shr(224, interfaceId)
            // ERC165: 0x01ffc9a7, ERC721: 0x80ac58cd, ERC721Metadata: 0x5b5e139f. ERC4906: 0x49064906
            result := or(or(or(eq(s, 0x01ffc9a7), eq(s, 0x80ac58cd)), eq(s, 0x5b5e139f)), eq(s, 0x49064906))
        }
    }

    ///@dev Return a contract-level JSON string
    function _stringContractURI() internal pure returns (string memory) {
        return string.concat(
            '{"name":"Ether RoXX","description":"Collectible, customizable rocks, entirely onchain. Powered by XXYYZZ.","external_link":"https://xxyyzz.art","image":"',
            string.concat("data:application/json;base64,", bytes(Rockify.rockify(0xff6000)).encode()),
            '"}'
        );
    }

    //////////
    // MINT //
    //////////

    /**
     * @notice Mint EtherRoXX tokens along with underlying XXYYZZ colors.
     * @param quantity The number of tokens to mint.
     */
    function mint(uint256 quantity) public payable returns (uint256[] memory) {
        return mintTo(msg.sender, quantity);
    }

    /**
     * @notice Mint EtherRoXX tokens along with underlying XXYYZZ colors to a specific address.
     * @param recipient The address to mint tokens to.
     * @param quantity The number of tokens to mint.
     */
    function mintTo(address recipient, uint256 quantity) public payable returns (uint256[] memory) {
        // Check max mint per transaction not exceeded
        if (quantity > MAX_MINT_PER_TRANSACTION) {
            revert MaxMintPerTransactionExceeded();
        }

        return _mintTo(recipient, quantity);
    }

    /**
     * @notice Mint a token for a specific XXYYZZ color held by the minter.
     * @param color The XXYYZZ color to mint. The caller must own the color.
     */
    function mintWithColor(uint256 color) public {
        uint256 numMinted_;
        unchecked {
            numMinted_ = numMinted + 1;
        }
        // Check max supply not exceeded
        if (numMinted_ > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        _validateXXYYZZOwner(color);

        // Increment number minted
        numMinted = numMinted_;

        // Mint token with color
        _mint(msg.sender, color);
    }

    /**
     * @notice Mint EtherRoXX tokens for XXYYZZ colors held by the minter.
     * @param colors The XXYYZZ colors to mint. The caller must own the colors.
     */
    function batchMintWithColor(uint256[] calldata colors) public {
        if (colors.length == 0) {
            revert ArrayLengthMustBeGreaterThanZero();
        }
        uint256 numMinted_;
        unchecked {
            numMinted_ = numMinted + colors.length;
        }

        // Check max supply not exceeded
        if (numMinted_ > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        // Check caller owns all colors
        for (uint256 i; i < colors.length;) {
            _validateXXYYZZOwner(colors[i]);
            unchecked {
                ++i;
            }
        }

        // Update number minted
        numMinted = numMinted_;
        // Mint tokens with colors
        for (uint256 i; i < colors.length;) {
            uint256 color = colors[i];
            // increment before skipping
            unchecked {
                ++i;
            }
            // skip if already minted
            if (_ownerOf(color) != address(0)) {
                continue;
            }
            _mint(msg.sender, color);
        }
    }

    /**
     * @notice Mint EtherRoXX token along with the specific underlying XXYYZZ color and validate it was committed to.
     * @param id The XXYYZZ color to mint.
     * @param salt The user-specific salt used in the previous commitment. It will be further hashed to derive the salt used in the XXYYZZ mint.
     */
    function mintSpecific(uint256 id, bytes32 salt) public payable {
        uint256 numMinted_ = numMinted;
        unchecked {
            numMinted_ = numMinted_ + 1;
        }
        if (numMinted_ > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }
        bytes32 newSalt = deriveUserSalt(msg.sender, bytes32(salt));
        XXYYZZ(XXYYZZ_ADDRESS).mintSpecific{value: msg.value}(id, newSalt);
        numMinted = numMinted_;
        _mint(msg.sender, id);
    }

    /**
     * @notice Mint EtherRoXX tokens along with the specific underlying XXYYZZ colors.
     * @param colors The XXYYZZ colors to mint.
     * @param salt The user-specific salt used in the previous commitment. It will be further hashed to derive the salt used in the XXYYZZ mint.
     */
    function batchMintSpecific(uint256[] calldata colors, bytes32 salt) public payable {
        if (colors.length == 0) {
            revert ArrayLengthMustBeGreaterThanZero();
        }
        if (colors.length > MAX_MINT_PER_TRANSACTION) {
            revert MaxMintPerTransactionExceeded();
        }
        uint256 numMinted_ = numMinted;
        unchecked {
            numMinted_ = numMinted_ + colors.length;
        }
        if (numMinted_ > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }
        bytes32 newSalt = deriveUserSalt(msg.sender, bytes32(salt));
        bool[] memory minted = XXYYZZ(XXYYZZ_ADDRESS).batchMintSpecific{value: msg.value}(colors, newSalt);
        uint256 actualNumMinted;
        uint256 mintedLength = minted.length;
        for (uint256 i; i < mintedLength;) {
            // only mint if xxyyzz mint was successful
            if (minted[i]) {
                unchecked {
                    ++actualNumMinted;
                }
                _transferXXYYZZ(msg.sender, colors[i]);
                _mint(msg.sender, colors[i]);
            }
            unchecked {
                ++i;
            }
        }

        numMinted += actualNumMinted;
        uint256 mintPrice = 0.005 ether;

        if (actualNumMinted < colors.length) {
            assembly {
                let diff := sub(colors.length, actualNumMinted)
                let refund := mul(diff, mintPrice)
                if iszero(call(gas(), caller(), refund, 0, 0, 0, 0)) {
                    mstore(0, ETHER_TRANSFER_FAILED_SELECTOR) // revert with EtherTransferFailed()
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /**
     * @dev low-level helper function to transfer XXYYZZ tokens to intended recipient
     * @param to address to transfer to
     * @param id token id to transfer
     */
    function _transferXXYYZZ(address to, uint256 id) internal {
        address xxyyzz = XXYYZZ_ADDRESS;
        assembly {
            // cache free mem ptr
            let ptr := mload(0x40)
            // clobber first four words of memory
            mstore(0, TRANSFER_FROM_SELECTOR)
            mstore(0x20, address())
            mstore(0x40, to)
            mstore(0x60, id)
            // call transferFrom and check result
            if iszero(call(gas(), xxyyzz, 0, 0x1c, 0x64, 0, 0)) {
                // revert with return data
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
            // restore free mem ptr
            mstore(0x40, ptr)
            // restore zero pointer
            mstore(0x60, 0)
        }
    }

    /**
     * @dev Mint EtherRoXX tokens along with underlying XXYYZZ colors to a specific address.
     * @param recipient The address to mint tokens to
     * @param quantity The number of tokens to mint
     */
    function _mintTo(address recipient, uint256 quantity) internal returns (uint256[] memory) {
        uint256 numMinted_ = numMinted;

        uint256 newSupply;
        unchecked {
            newSupply = numMinted_ + quantity;
        }
        // Check max supply not exceeded
        if (newSupply > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }
        // Mint colors
        uint256[] memory mintedColors = XXYYZZ(XXYYZZ_ADDRESS).mintTo{value: msg.value}(recipient, quantity);
        unchecked {
            numMinted = newSupply;
        }
        for (uint256 i; i < quantity;) {
            // Increment token id
            unchecked {
                ++numMinted_;
            }

            _mint(recipient, mintedColors[i]);

            unchecked {
                ++i;
            }
        }
        return mintedColors;
    }

    ////////////
    // REROLL //
    ////////////

    /**
     * @notice Reroll an existing EtherRoXX for one with a new color. The user must own the XXYYZZ token of the new color.
     * @param originalId The old token id
     * @param newId The new token id – the user must own the XXYYZZ token with this ID
     */
    function reroll(uint256 originalId, uint256 newId) public {
        // Check caller owns original token
        if (ownerOf(originalId) != msg.sender) {
            revert CallerDoesNotOwnEtherRoXX();
        }
        _validateXXYYZZOwner(newId);

        // Burn original token
        _burn(originalId);

        // Mint new token
        _mint(msg.sender, newId);
    }

    ////////////
    // COMMIT //
    ////////////

    /**
     * @notice Commit to a specific XXYYZZ color. Derives a new salt to pass through to the original XXYYZZ contract.
     */
    function commit(bytes32 commitHash) public {
        XXYYZZ(XXYYZZ_ADDRESS).commit(commitHash);
    }

    /**
     * @notice Derive the salt that EtherRoXX will pass to the original XXYYZZ contract given a user's salt.
     * @dev this allows for user commitments to be unique, so other users cannot copy others' commitments.
     */
    function deriveUserSalt(address caller_, bytes32 salt) public pure returns (bytes32 newSalt) {
        assembly {
            mstore(0, caller_)
            mstore(0x20, salt)
            newSalt := keccak256(0, 0x40)
        }
    }

    //////////////
    // INTERNAL //
    //////////////

    /**
     * @dev Validate that the caller owns the XXYYZZ color with the given id.
     */
    function _validateXXYYZZOwner(uint256 id) internal view {
        address token = XXYYZZ_ADDRESS;
        assembly {
            mstore(0, OWNER_OF_SELECTOR)
            // store id in second word
            mstore(0x20, id)
            // call ownerOf(id), check result, and store result in first word
            if iszero(staticcall(gas(), token, 0x1c, 0x24, 0, 0x20)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
            // compare result to caller
            if iszero(eq(mload(0), caller())) {
                // revert with error if not equal
                mstore(0, CALLER_DOES_NOT_OWN_XXYYZZ_COLOR_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }
    }
}