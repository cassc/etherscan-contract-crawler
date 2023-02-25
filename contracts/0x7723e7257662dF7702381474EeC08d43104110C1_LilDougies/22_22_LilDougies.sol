// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ECDSA} from "solady/utils/ECDSA.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {Owned} from "@solmate/auth/Owned.sol";
import {DefaultOperatorFilterer} from "@operator-filter-registry/DefaultOperatorFilterer.sol";
import {ERC721Enumerable} from "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Burnable} from "@openzeppelin/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721} from "@openzeppelin/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";

/// @title Lil Dougies
/// @author DangyWing
contract LilDougies is ERC721, ERC721Burnable, ERC721Enumerable, Owned(msg.sender), DefaultOperatorFilterer {
    uint256 public immutable MAX_TOKEN_ID = 2110;

    address public _signerAddress;
    bool public areHotsRevealed = false;
    string public hotBaseURI;
    string public mildBaseURI;
    string public hotPreRevealTokenURI;

    // 0 = closed, 1 = open
    uint256 public burnStatus = 0;
    // 0 = closed, 1 = allow list, 2 = public
    uint256 public mintStatus = 0;

    uint256 public hotMintCount = 0;
    uint256 public hotSupply = 0;
    uint256 public maxHot = 420;
    uint256 public maxMild = 1690;
    uint256 public maxPerTx = 10;
    uint256 public mildMintCount = 0;
    uint256 public mildSupply = 0;
    uint256 public price = 0.0069 ether;

    mapping(address => bool) public allowListClaimed;

    /*//////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error AlreadyClaimed();
    error InvalidSig();
    error MildSupplyMet();
    error NotLive();
    error NotOwner();
    error PerTxLimitMet();
    error SupplyMet();
    error TokenDoesNotExist();
    error TooSpicy();
    error WrongEtherAmount();

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param _name The name of the token.
    /// @param _symbol The Symbol of the token.
    /// @param _mildBaseURI The baseURI for the token that will be used for metadata.
    /// @param _hotPreRevealURI The baseURI for the token that will be used for metadata.
    /// @param signerAddress The address of the signer.

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _mildBaseURI,
        string memory _hotPreRevealURI,
        address signerAddress
    ) ERC721(_name, _symbol) {
        mildBaseURI = _mildBaseURI;
        hotPreRevealTokenURI = _hotPreRevealURI;
        _signerAddress = signerAddress;
    }

    /*///////////////////////////////////////////////////////////////
                               MINT
    //////////////////////////////////////////////////////////////*/

    /// @notice claim Lil Dougies based on snapshot
    /// @param lilDougieCount The amount of Lil Dougies to claim.
    /// @param signature The signature of the permit.

    function claimLilDougies(uint256 lilDougieCount, bytes calldata signature) public {
        if (mintStatus != 1) revert NotLive();
        if (mildMintCount + lilDougieCount > maxMild) revert MildSupplyMet();
        if (allowListClaimed[msg.sender]) revert AlreadyClaimed();
        if (!_verifySignature(lilDougieCount, signature)) revert InvalidSig();

        allowListClaimed[msg.sender] = true;

        for (uint256 index = 0; index < lilDougieCount; ++index) {
            _mint(msg.sender, mildMintCount + 1);
            mildMintCount++;
            mildSupply++;
        }
    }

    /// @notice Mint NFT.
    /// @param _mintCount Amount of token that the sender wants to mint.

    function mildMint(uint256 _mintCount) external payable {
        if (mintStatus != 2) revert NotLive();
        if (_mintCount > maxPerTx) revert PerTxLimitMet();
        if (msg.value < price * _mintCount) revert WrongEtherAmount();
        if (mildMintCount + _mintCount > maxMild) revert MildSupplyMet();

        unchecked {
            for (uint256 index = 0; index < _mintCount; ++index) {
                _mint(msg.sender, mildMintCount + 1);
                mildMintCount++;
                mildSupply++;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                               SUPER SECRET
    //////////////////////////////////////////////////////////////*/

    /// @notice Burn NFT.
    /// @param tokenIds Token IDs to burn.

    function burnForHot(uint256[] calldata tokenIds) external {
        if (burnStatus != 1) revert NotLive();

        // rounds down so it handles odd numbered arrays
        uint256 hotCount = tokenIds.length / 2;
        uint256 mildCount = hotCount * 2;

        if (hotCount + hotSupply > maxHot) revert SupplyMet();

        for (uint256 i = 0; i < mildCount; i += 2) {
            if (tokenIds[i] > maxMild) revert TooSpicy();

            burn(tokenIds[i]);
            burn(tokenIds[i + 1]);
            mildSupply -= 2;
            mintHot();
        }
    }

    /// @notice nothing to see here
    function mintHot() internal {
        uint256 tokenId = maxMild + hotSupply + 1;

        unchecked {
            hotSupply++;
            hotMintCount++;
            _mint(msg.sender, tokenId);
        }
    }

    /*///////////////////////////////////////////////////////////////
                               SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice sets whether or not hots are revealed
    function setHotRevealed() external onlyOwner {
        areHotsRevealed = !areHotsRevealed;
    }

    /// @notice sets Mint status
    /// @param _mintStatus Mint status
    function setMintStatus(uint256 _mintStatus) external onlyOwner {
        mintStatus = _mintStatus;
    }

    /// @notice sets URI
    /// @param _baseURI URI
    /// @dev should end with a '/'
    function setMildBaseURI(string memory _baseURI) external onlyOwner {
        mildBaseURI = _baseURI;
    }

    /// @notice sets URI
    /// @param _baseURI URI
    /// @dev should end with a '/'

    function setHotBaseURI(string memory _baseURI) external onlyOwner {
        hotBaseURI = _baseURI;
    }

    /// @notice sets price
    /// @param _price Price
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /// @notice sets burn status
    /// @param _burnStatus Burn status
    function setBurnStatus(uint256 _burnStatus) external onlyOwner {
        burnStatus = _burnStatus;
    }

    /// @notice sets signerAddress for verifying signatures
    /// @param _newSignerAddress new signer address
    function setSignerAddress(address _newSignerAddress) external onlyOwner {
        _signerAddress = _newSignerAddress;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    /*///////////////////////////////////////////////////////////////
                            ETH WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraw all ETH from the contract
    function withdraw() external onlyOwner {
        SafeTransferLib.safeTransferETH(owner, address(this).balance);
    }

    /// @notice returns token URI
    /// @param tokenId Token ID

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (!areHotsRevealed && tokenId > maxMild) return hotPreRevealTokenURI;

        string memory baseURI = tokenId > maxMild ? hotBaseURI : mildBaseURI;

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, LibString.toString(tokenId), ".json")) : "";
    }

    /*///////////////////////////////////////////////////////////////
                            OPENSEA OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Verifies the signature vs. the signer address
    /// @param lilDougieCount Name to verify
    /// @param signature Signature to verify

    function _verifySignature(uint256 lilDougieCount, bytes calldata signature) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, lilDougieCount));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(hash);
        return _signerAddress == ECDSA.recover(ethSignedMessageHash, signature);
    }
}