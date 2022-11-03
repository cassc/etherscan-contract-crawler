// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title: Death Clock by DIS x CHAIN/SAW
/// @notice: https://deathclock.live

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//    ▄▀▀█▄▄   ▄▀▀█▄▄▄▄  ▄▀▀█▄   ▄▀▀▀█▀▀▄  ▄▀▀▄ ▄▄       ▄▀▄▄▄▄   ▄▀▀▀▀▄    ▄▀▀▀▀▄   ▄▀▄▄▄▄   ▄▀▀▄ █   //
//   █ ▄▀   █ ▐  ▄▀   ▐ ▐ ▄▀ ▀▄ █    █  ▐ █  █   ▄▀     █ █    ▌ █    █    █      █ █ █    ▌ █  █ ▄▀   //
//   ▐ █    █   █▄▄▄▄▄    █▄▄▄█ ▐   █     ▐  █▄▄▄█      ▐ █      ▐    █    █      █ ▐ █      ▐  █▀▄    //
//     █    █   █    ▌   ▄▀   █    █         █   █        █          █     ▀▄    ▄▀   █        █   █   //
//    ▄▀▄▄▄▄▀  ▄▀▄▄▄▄   █   ▄▀   ▄▀         ▄▀  ▄▀       ▄▀▄▄▄▄▀   ▄▀▄▄▄▄▄▄▀ ▀▀▀▀    ▄▀▄▄▄▄▀ ▄▀   █    //
//   █     ▐   █    ▐   ▐   ▐   █          █   █        █     ▐    █                █     ▐  █    ▐    //
//   ▐         ▐                ▐          ▐   ▐        ▐          ▐                ▐        ▐         //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////

import './JsonWriter.sol';
import './ERC721R.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import 'solmate/src/utils/SafeTransferLib.sol';

import { DeathClockRemnant } from './DeathClockRemnant.sol';
import './IDeathClockDescriptor.sol';
import './Whitelist.sol';

error AmountMustBeNonZero();
error CannotTransferRemnant();
error DeathWishUsed();
error IncorrectMintPhase();
error IncorrectMintPrice();
error InsufficientFunds();
error InvalidDeathWish();
error NoReset();
error NotMinted();
error Unauthorized();

// Voucher for initial mint
struct DeathWish {
    uint256 minted;
    uint256 expDate;
    address deadman;
    uint256 accidentId;
}

// Voucher for clock update / reassignment
struct DeathReassigment {
    uint256 expDate;
    uint256 tokenId;
    uint256 accidentId;
}

contract DeathClock is EIP712, ERC721r, Whitelist, Ownable, ReentrancyGuard {
    using BitMaps for BitMaps.BitMap;
    using Counters for Counters.Counter;

    string private constant SIGNING_DOMAIN = 'DeathVoucher';
    string private constant SIGNATURE_VERSION = '1';
    uint256 private constant MINT_PRICE = 0.4321 ether;
    uint256 private constant MAX_CLOCKS = 500;
    Counters.Counter private _nextRemnantId;
    mapping(uint256 => uint256) private _mintDates;
    mapping(uint256 => uint256) private _remnants;
    mapping(uint256 => uint256) private _resets;
    mapping(uint256 => address) private _fds;
    mapping(uint256 => bool) private _usedVouchers;
    mapping(address => mapping(uint256 => bool)) private _remnantExists;

    address public deathWishSigner;
    IDeathClockDescriptor public descriptor;
    DeathClockRemnant public remnantContract;
    mapping(uint256 => bool) public canBeReset;
    mapping(uint256 => uint256) public expDates;
    bool public publicCanMint;

    constructor(address _deathWishSigner, address _descriptor)
        ERC721r('DEATH CLOCK', 'DEATHCLOCK', MAX_CLOCKS)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        deathWishSigner = _deathWishSigner;
        descriptor = IDeathClockDescriptor(_descriptor);
        remnantContract = new DeathClockRemnant(address(this));
    }

    modifier ifPriceIsRight() {
        if (msg.value != MINT_PRICE) revert IncorrectMintPrice();
        _;
    }

    /// @notice Redeems a DeathWish for a Death Clock if minter is on active whitelist.
    function preMintDeathClock(
        DeathWish calldata deathWish,
        bytes memory signature,
        uint256 index,
        bytes32[] calldata proof
    ) public payable ifPriceIsRight nonReentrant {
        if (publicCanMint) revert IncorrectMintPhase();
        _verifyProof(index, proof);
        _mintDeathClock(deathWish, signature);
        _setClaimed(index);
    }

    /// @notice Redeems a DeathWish for a Death Clock.
    function mintDeathClock(
        DeathWish calldata deathWish,
        bytes memory signature
    ) public payable ifPriceIsRight nonReentrant {
        if (!publicCanMint) revert IncorrectMintPhase();
        _mintDeathClock(deathWish, signature);
    }

    /// @notice Upon transfer, Death Clocks become eligible for a reset. This allows new
    /// owners to personalize their clocks accurately predict their deaths.
    function reset(DeathReassigment calldata deathWish, bytes memory signature) public {
        if(!_exists(deathWish.tokenId)) revert NotMinted();
        address signer = _verifyReassigment(deathWish, signature);
        if (signer != deathWishSigner) revert InvalidDeathWish();
        if (_usedVouchers[deathWish.accidentId]) revert DeathWishUsed();
        if (!canBeReset[deathWish.tokenId]) revert NoReset();
        if (ownerOf(deathWish.tokenId) != _msgSender()) revert Unauthorized();

        _usedVouchers[deathWish.accidentId] = true;
        expDates[deathWish.tokenId] = deathWish.expDate;
        _resets[deathWish.tokenId] += 1;
        _fds[deathWish.tokenId] = _msgSender();
        canBeReset[deathWish.tokenId] = false;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId) && _msgSender() != address(remnantContract))
            revert NotMinted();
        return
            descriptor.getMetadataJSON(
                IDeathClockDescriptor.MetadataPayload(
                    tokenId,
                    _mintDates[tokenId],
                    expDates[tokenId],
                    _remnants[tokenId],
                    _resets[tokenId],
                    _fds[tokenId]
                )
            );
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // ADMINISTRATIVE STUFF                                                                            //
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    function togglePublicMint() external onlyOwner {
        publicCanMint = !publicCanMint;
    }

    function setDeathWishSigner(address _deathWishSigner) external onlyOwner {
        deathWishSigner = _deathWishSigner;
    }

    function setActiveMerkleRoot(uint256 merkleRootIndex) external onlyOwner {
        _setActiveMerkleRoot(merkleRootIndex);
    }

    function setMerkleRoot(uint256 merkleRootIndex, bytes32 merkleRoot) external onlyOwner {
        _setMerkleRoot(merkleRootIndex, merkleRoot);
    }

    function setViewerCID(string calldata _viewerCID) external onlyOwner {
        descriptor.setViewerCID(_viewerCID);
    }

    function setPreviewCID(string calldata _previewCID) external onlyOwner {
        descriptor.setPreviewCID(_previewCID);
    }

    function withdraw() public onlyOwner {
	      (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		    require(success);
	}

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // INTERNALS & OVERRIDES                                                                           //
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    function _mintDeathClock(DeathWish calldata deathWish, bytes memory signature) internal {
        address signer = _verifyWish(deathWish, signature);
        if (signer != deathWishSigner) revert InvalidDeathWish();
        if (deathWish.deadman != _msgSender()) revert InvalidDeathWish();
        require(_numAvailableTokens > 0, 'Max tokens amount reached');
        if(_usedVouchers[deathWish.accidentId]) revert DeathWishUsed();
        _usedVouchers[deathWish.accidentId] = true;
        uint256 tokenId = _mintRandom(_msgSender(), 1);
        _fds[tokenId] = _msgSender();
        expDates[tokenId] = deathWish.expDate;
        _mintDates[tokenId] = block.timestamp * 1000;
    }

    function _mintRemnant(uint256 deathClockTokenId, address to) internal returns (uint256) {
        uint256 soulboundTokenId = MAX_CLOCKS + _nextRemnantId.current();
        expDates[soulboundTokenId] = expDates[deathClockTokenId];
        _mintDates[soulboundTokenId] = _mintDates[deathClockTokenId];
        _fds[soulboundTokenId] = _fds[deathClockTokenId];
        remnantContract.mintRemnant(to, soulboundTokenId);
        _nextRemnantId.increment();
        _remnants[deathClockTokenId] += 1;
        return soulboundTokenId;
    }

    /// @notice Returns a hash of the given DeathWish, prepared using EIP712 typed data hashing rules.
    /// @param deathWish An DeathWish to hash.
    function _hashWish(DeathWish calldata deathWish) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            'DeathWish(uint256 minted,uint256 expDate,address deadman,uint256 accidentId)'
                        ),
                        deathWish.minted,
                        deathWish.expDate,
                        deathWish.deadman,
                        deathWish.accidentId
                    )
                )
            );
    }

    /// @notice Verifies the signature for a given DeathWish, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify signer is authorized to mint NFTs.
    /// @param deathWish An DeathWish describing an unminted NFT.
    function _verifyWish(DeathWish calldata deathWish, bytes memory signature) internal view returns (address) {
        bytes32 digest = _hashWish(deathWish);
        return ECDSA.recover(digest, signature);
    }

    /// @notice Returns a hash of the given DeathWish, prepared using EIP712 typed data hashing rules.
    /// @param deathReassigment An DeathWish to hash.
    function _hashReassigment(DeathReassigment calldata deathReassigment)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            'DeathReassigment(uint256 expDate,uint256 tokenId,uint256 accidentId)'
                        ),
                        deathReassigment.expDate,
                        deathReassigment.tokenId,
                        deathReassigment.accidentId
                    )
                )
            );
    }

    /// @notice Verifies the signature for a given DeathWish, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify signer is authorized to mint NFTs.
    /// @param deathReassigment An DeathWish describing an unminted NFT.
    function _verifyReassigment(
        DeathReassigment calldata deathReassigment,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 digest = _hashReassigment(deathReassigment);
        return ECDSA.recover(digest, signature);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721r)
        returns (bool)
    {
        return ERC721r.supportsInterface(interfaceId);
    }

    /// @notice Override to mint remnant and enable new owner to reset clock. Each account is limited to
    /// reciept of one remnant for each Death Clock that passes through their hands.
    function _afterTokenTransfer(
        address from,
        address,
        uint256 tokenId
    ) internal override {
        if (from != address(0)) {
            // Skip initial mint
            canBeReset[tokenId] = true;
            if (!_remnantExists[from][tokenId]) {
                _mintRemnant(tokenId, from);
                _remnantExists[from][tokenId] = true;
            }
        }
    }
}