// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title Ex Paradiso
 * @author Mai Akiyoshi and Ben Yu
 * @notice This contract handles minting Ex Paradiso tokens.
 */
contract ExParadiso is ERC721A, Ownable, ERC2981 {
    using ECDSA for bytes32;

    uint256 public constant publicPrice = 0.06 ether;
    uint256 public constant presalePrice = 0.05 ether;
    uint256 public constant maxSupply = 5555;

    address public withdrawAddress = 0xF7Bf897c40e4c7D5A0261a26CbA4d071AEfe6d32;
    address public royaltyAddress = 0xF7Bf897c40e4c7D5A0261a26CbA4d071AEfe6d32;
    uint96 public royaltyFee = 600;

    uint256 public presaleMintsAllowedPerAddress = 5;
    string public baseTokenURI;

    bool public isPresaleActive = false;
    bool public isPublicSaleActive = false;

    /**
     * @param name Token name
     * @param symbol Token symbol
     * @param baseTokenURI_ Base URI for all tokens
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI_
    ) ERC721A(name, symbol) {
        baseTokenURI = baseTokenURI_;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }
    // Used to validate authorized mint addresses
    address private signerAddress = 0xabcde159f1612A68074fB889A37410C97156Db95;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice start minting tokens at id 1
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Wraps and exposes publicly _numberMinted() from ERC721A
     */
    function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
    }

    /**
     * @notice To be updated by contract owner to allow presale minting 
     */
    function setPresaleState(bool _saleActiveState) public onlyOwner {
        require(isPresaleActive != _saleActiveState, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        isPresaleActive = _saleActiveState;
    }

    /**
     * @notice To be updated by contract owner to allow public sale minting
     */
    function setPublicSaleState(bool _saleActiveState) public onlyOwner {
        require(isPublicSaleActive != _saleActiveState, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        isPublicSaleActive = _saleActiveState;
    }

    /**
     * @notice Set the signer address used to verify presale minting
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0));
        signerAddress = _signerAddress;
    }

    /**
     * @notice Set the withdraw address
     */
    function setWithdrawAddress(address _withdrawAddress) external onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    /**
     * @notice Set the maximum public mints allowed per a given address
     */
    function setPresaleMintsAllowedPerAddress(uint256 _mintsAllowed) public onlyOwner {
        presaleMintsAllowedPerAddress = _mintsAllowed;
    }
    
    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Verify that a signed message is validly signed by the signerAddress
     */
    function verifyAddressSigner(bytes32 messageHash, bytes memory signature) private view returns (bool) {
        return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    /**
     * @notice Verify that the hashed message is accurate
     */
    function hashMessage(address sender) private pure returns (bytes32) {
        return keccak256(abi.encode(sender));
    }

    /**
     * @notice Turn off all sales
     */
    function turnOffAllSales() private {
        isPresaleActive = false;
        isPublicSaleActive = false;
    }

    /**
     * @notice Allow for allowlist minting of up to presaleMintsAllowedPerAddress tokens
     */
    function presaleMint(
        bytes32 messageHash,
        bytes calldata signature,
        uint256 numTokens
    ) external payable {
        require(isPresaleActive, "PRESALE_IS_NOT_ACTIVE");
        require(_numberMinted(msg.sender) + numTokens <= presaleMintsAllowedPerAddress, "MAX_MINTS_EXCEEDED");
        require(totalSupply() + numTokens <= maxSupply, "MAX_SUPPLY_EXCEEDED");
        require(msg.value == presalePrice * numTokens, "PAYMENT_INSUFFICIENT");
        require(hashMessage(msg.sender) == messageHash, "MESSAGE_INVALID");
        require(verifyAddressSigner(messageHash, signature), "SIGNATURE_VALIDATION_FAILED");

        _safeMint(msg.sender, numTokens);

        if (totalSupply() >= maxSupply) {
            turnOffAllSales();
        }
    }

    /**
     * @notice Allow for public minting of up to publicMintsAllowedPerAddress tokens
     */
    function mint(
        uint256 numTokens
    ) external payable {
        require(isPublicSaleActive, "PUBLIC_SALE_IS_NOT_ACTIVE");
        require(totalSupply() + numTokens <= maxSupply, "MAX_SUPPLY_EXCEEDED");
        require(msg.value == publicPrice * numTokens, "PAYMENT_INSUFFICIENT");

        _safeMint(msg.sender, numTokens);

        if (totalSupply() >= maxSupply) {
            turnOffAllSales();
        }
    }

    /**
     * @notice Allow owner to send `mintNumber` tokens without cost to multiple addresses
     */
    function gift(address[] calldata receivers, uint256 mintNumber) external onlyOwner {
        require((totalSupply() + (receivers.length * mintNumber)) <= maxSupply, "MINT_TOO_LARGE");

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], mintNumber);
        }
    }

    /**
     * @notice  Allow contract owner to withdraw ETH funds split between partners.
     */
    function withdraw() external onlyOwner {
        payable(withdrawAddress).transfer(address(this).balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}