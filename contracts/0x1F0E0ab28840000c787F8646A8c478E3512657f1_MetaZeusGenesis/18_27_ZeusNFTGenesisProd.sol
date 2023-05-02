// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract MetaZeusGenesis is
ERC721AQueryable,
Ownable,
ReentrancyGuard,
DefaultOperatorFilterer
{
    using Strings for uint256;
    error ContractPaused();
    error MaxSupplyReached();
    error PublicSaleInactive();
    error MaxPerWallet();
    error InvalidAmount();
    error NotAllowedToMint();
    error NotEnoughPass();
    error NotEnoughAvailable();
    error WrongPassID();

    IERC721AQueryable mintPass;

    address private constant treasury = 0x4F590f2E40B27d06d8d5a7b8BEaf0eaaed66b248;
    address private constant mintPassAddress = 0x8c2EeE9d6422b6D998667761aC77ba43b05C44d6;

    uint256 private constant maxSupTotal = 650;

    string private constant uriPrefix = "https://metazeus.s3.eu-central-1.amazonaws.com/metazeus_genesis/metadata/";
    string private constant uriSuffix = ".json";
    string private constant hiddenMetadataUri = "https://metazeus.s3.eu-central-1.amazonaws.com/metazeus_genesis/metadata/hidden.json";

    struct States {
        bool paused;
        bool publicSaleEnabled;
        bool revealed;
    }
    //initialize structs
    States public state;

    uint256[3] public usedPass;

    constructor(
        States memory _state
    ) ERC721A("MetaZeusGenesis", "MetaZeusGenesisNFT") {
        setPaused(_state.paused);
        setPublicSaleActive(_state.publicSaleEnabled);
        setRevealed(_state.revealed);
        mintPass = IERC721AQueryable(mintPassAddress);
    }

    modifier mintCompliancePublic(
        uint256 _mintAmount,
        uint256[] calldata passIDs
    ) {
        if (state.paused) revert ContractPaused();
        if (!(_mintAmount == passIDs.length)) revert NotEnoughPass();

        if (!hasEnoughAvailableMintpass(_mintAmount, passIDs))
            revert NotEnoughAvailable();
        if (_totalMinted() + _mintAmount > maxSupTotal)
            revert MaxSupplyReached();
        if (!state.publicSaleEnabled) revert PublicSaleInactive();

        _;
    }

    receive() external payable {}

    /**                                 ----MINT FUNCTIONS---- */

    // PUBLIC MINT
    function PublicMint(
        uint256 _mintAmount,
        uint256[] calldata passIDs
    ) public payable mintCompliancePublic(_mintAmount, passIDs) {
        for (uint16 i = 0; i < _mintAmount; ) {
            setPassState(passIDs[i]);

        unchecked {
            ++i;
        }
        }

        _mint(_msgSender(), _mintAmount);
    }

    //               ------ HELPERS AND OTHER FUNCTIONS ------

    function hasEnoughAvailableMintpass(
        uint256 _mintAmount,
        uint256[] calldata passIDs
    ) public view returns (bool) {
        bool lastRes = true;
        bool hasEnough = false;
        bool currentRes;

        for (uint16 i = 0; i < _mintAmount; ) {
            currentRes = isOwnerOf(passIDs[i]) && !getPassState(passIDs[i]);

            hasEnough = currentRes && lastRes;
            lastRes = currentRes;
        unchecked {
            ++i;
        }
        }

        return hasEnough;
    }

    function isOwnerOf(uint256 _id) internal view returns (bool) {
        return msg.sender == mintPass.ownerOf(_id);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (state.revealed == false) {
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
    }

    function _baseURI()
    internal
    view
    virtual
    override(ERC721A)
    returns (string memory)
    {
        return uriPrefix;
    }

    //                          -----SETTERS-----
    function setPaused(bool _state) public onlyOwner {
        state.paused = _state;
    }

    function setPublicSaleActive(bool _state) public onlyOwner {
        state.publicSaleEnabled = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        state.revealed = _state;
    }

    function setPassState(uint256 id) internal {
        uint256 bitmapIndex;
        uint256 indexFromRight;

        if (id <= 256) {
            bitmapIndex = 0;
            indexFromRight = id;
        } else if (id >= 257 && id <= 512) {
            bitmapIndex = 1;
            indexFromRight = id - 256;
        } else if (id >= 513 && id <= 650) {
            bitmapIndex = 2;
            indexFromRight = id - 512;
        } else {
            revert WrongPassID();
        }
        _setBitData(bitmapIndex, indexFromRight);
    }

    function _setBitData(uint256 bitmapIndex, uint256 indexFromRight) internal {
        uint256 tempuint = usedPass[bitmapIndex] | (1 << indexFromRight);
        usedPass[bitmapIndex] = tempuint;
    }

    function getPassState(uint256 id) public view returns (bool) {
        uint256 bitmapIndex;
        uint256 indexFromRight;

        if (id <= 256) {
            bitmapIndex = 0;
            indexFromRight = id;
        } else if (id >= 257 && id <= 512) {
            bitmapIndex = 1;
            indexFromRight = id - 256;
        } else if (id >= 513 && id <= 650) {
            bitmapIndex = 2;
            indexFromRight = id - 512;
        } else {
            revert WrongPassID();
        }

        return _readBitData(bitmapIndex, indexFromRight);
    }

    function _readBitData(
        uint256 bitmapIndex,
        uint256 indexFromRight
    ) internal view returns (bool) {
        uint256 bitAtIndex = usedPass[bitmapIndex] & (1 << indexFromRight);

        return bitAtIndex > 0;
    }

    //                          -----TRANSFERS FUNCTIONS-----
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(treasury).call{value: address(this).balance}("");
        require(os);
    }
}