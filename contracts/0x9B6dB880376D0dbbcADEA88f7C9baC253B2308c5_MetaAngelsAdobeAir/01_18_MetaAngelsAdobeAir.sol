// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error AlreadyClaimedEror();
error InvalidProof();
error MintNotEnabled();

/**
 * @title Meta Angels Specials Contract
 * @author Gabriel Cebrian (https://twitter.com/gabceb)
 * @notice This contract handles the distribution of Meta Angels Special Airdrops ERC1155 tokens.
 */
contract MetaAngelsAdobeAir is ERC1155Supply, Pausable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    mapping(uint256 => mapping(address => bool)) public claimedPerToken;
    mapping(uint256 => string) private tokenUris;

    uint256 public mintToken;
    bool public mintEnabled;

    // Used to validate authorized mint addresses
    address private signerAddress = 0x290Df62917EAb5b06E3c04a583E2250A0B46d55f;

    constructor() ERC1155("") {}

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return tokenUris[tokenId];
    }

    /**
     * Update the base token URI
     */
    function setTokenUri(uint256 tokenId, string calldata _newTokenUri)
        external
        onlyOwner
    {
        tokenUris[tokenId] = _newTokenUri;
    }

    /**
     * Update the base token URI
     */
    function setMintEnabled(bool _mintEnabled) external onlyOwner {
        mintEnabled = _mintEnabled;
    }

    /**
     * Update the signer address
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0));
        signerAddress = _signerAddress;
    }

    /**
     * Prepare new mint
     */
    function prepareTokenMint(
        uint256 tokenId,
        string calldata _newTokenUri,
        bool setAsActiveMint
    ) external onlyOwner {
        tokenUris[tokenId] = _newTokenUri;

        if (setAsActiveMint) {
            mintToken = tokenId;
        }
    }

    function verifyAddressSigner(bytes32 messageHash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return
            signerAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    function mint(bytes32 messageHash, bytes calldata signature, uint256 tokenId)
        external
        payable
    {
        if (!mintEnabled || tokenId != mintToken) {
            revert MintNotEnabled();
        }

        if (claimedPerToken[mintToken][msg.sender]) {
            revert AlreadyClaimedEror();
        }

        if (
            keccak256(abi.encode(msg.sender, tokenId)) != messageHash ||
            !verifyAddressSigner(messageHash, signature)
        ) {
            revert InvalidProof();
        }

        claimedPerToken[mintToken][msg.sender] = true;
        _mint(msg.sender, mintToken, 1, "");
    }

    function adminMint(address[] calldata receivers, uint256 tokenId)
        external
        payable
        onlyOwner
    {
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], tokenId, 1, "");
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Allow contract owner to withdraw funds to its own account.
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}