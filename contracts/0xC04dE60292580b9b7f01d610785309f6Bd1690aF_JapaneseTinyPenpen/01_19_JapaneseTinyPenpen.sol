// SPDX-License-Identifier: MIT

/**
 * ■■■■■■■ ■■■■   ■ ■ ■  ■   ■   ■  ■  ■                 ■  ■■■■■   ■ ■ ■■ ■■■ ■
 *   ■         ■■    ■   ■ ■■   ■■  ■  ■   ■   ■   ■ ■      ■■  ■■ ■■   ■■ ■■ ■  ■■
 *             ■      ■  ■ ■ ■   ■  ■■   ■  ■   ■■            ■   ■  ■■■  ■ ■ ■  ■■
 *    ■        ■      ■ ■■ ■   ■ ■■  ■■■  ■      ■■■    ■■ ■  ■    ■■■■■■    ■  ■■
 *            ■■      ■ ■■ ■  ■■  ■    ■■      ■   ■■  ■     ■■■     ■■■■■■    ■ ■■
 *           ■■       ■ ■■    ■■   ■    ■ ■    ■■■   ■■    ■    ■  ■■   ■■■■■     ■
 *           ■        ■ ■ ■        ■■■     ■■■ ■  ■   ■■■■   ■■ ■   ■■■    ■ ■■■■■■
 *        ■           ■ ■ ■         ■■■     ■■■     ■  ■ ■       ■   ■■■■■     ■■ ■
 *         ■            ■  ■         ■■■■     ■ ■■■■ ■■ ■ ■   ■   ■   ■■■■■■■
 *          ■           ■  ■   ■     ■■  ■■    ■■   ■■■■■■■■     ■ ■       ■■■■■■■■
 *                       ■  ■   ■     ■■  ■■ ■■           ■  ■ ■  ■■   ■    ■■■■■
 *                       ■  ■■         ■■   ■  ■■■■■■■■■     ■    ■■     ■■  ■■■■■
 *               ■        ■  ■■  ■       ■   ■      ■   ■ ■   ■    ■■ ■■ ■ ■  ■■■■■
 *               ■         ■   ■         ■■ ■■ ■     ■■■■  ■   ■   ■■  ■ ■■    ■■■■
 *           ■   ■         ■ ■ ■■     ■■  ■■     ■■             ■  ■■  ■  ■    ■■■■
 *           ■   ■         ■ ■■   ■  ■■■   ■        ■■■■■■■ ■    ■  ■  ■  ■     ■■■
 *          ■■   ■         ■  ■■■  ■  ■■ ■■■■■    ■■■■■■■■■■■■   ■  ■      ■■   ■■■
 *         ■■    ■    ■     ■    ■  ■   ■   ■■■ ■■■  ■■■■■■■■■■  ■■ ■      ■■   ■
 *   ■    ■■■    ■    ■      ■■      ■■  ■      ■   ■■  ■ ■■■ ■■    ■   ■  ■■  ■■ ■
 *  ■    ■■■■    ■            ■■      ■■■ ■     ■■ ■■■■■■■■■   ■■   ■   ■   ■  ■■■■
 *      ■■■■     ■          ■        ■  ■■ ■■ ■■■■  ■■     ■■■  ■■  ■          ■■■■
 *    ■■■■      ■■           ■■   ■ ■    ■■     ■■  ■■ ■■■■■■■  ■   ■     ■   ■■■■■
 *  ■■■■■       ■■             ■       ■■ ■■    ■   ■  ■ ■■■  ■   ■ ■   ■ ■   ■■■■
 * ■■■■■■       ■■        ■     ■■                   ■ ■ ■    ■     ■   ■ ■■  ■■■■■
 *   ■■■     ■■ ■■        ■■  ■  ■■ ■■  ■■■  ■■      ■■            ■■■  ■ ■   ■■ ■■
 *  ■■■      ■■ ■          ■■               ■■■■■■     ■     ■     ■    ■ ■   ■■■ ■
 *  ■■■         ■          ■■■      ■■ ■■ ■■■ ■■       ■■   ■■   ■ ■ ■  ■ ■ ■ ■■■■■
 * ■■■      ■   ■ ■         ■■■ ■■■■■■■   ■■■            ■■            ■ ■■   ■■■■■
 * ■■           ■ ■    ■    ■■ ■  ■  ■  ■■■   ■                  ■ ■     ■■    ■■ ■
 * ■         ■ ■■ ■          ■■■■               ■ ■                ■ ■ ■ ■■   ■   ■
 *         ■■  ■■ ■           ■■  ■■ ■■    ■                       ■ ■ ■ ■  ■■■ ■■■
 *         ■  ■■■ ■■   ■■      ■  ■■■■■■■                          ■■■  ■■  ■■   ■■
 *       ■   ■■■■ ■■  ■■         ■■ ■■■■                           ■■■  ■■■ ■■■■■■
 *      ■■    ■ ■  ■       ■      ■■ ■  ■                           ■■   ■■ ■■■ ■■■
 *     ■■■     ■■■ ■■       ■      ■   ■■                            ■■  ■■ ■■  ■■■
 *     ■       ■■■ ■■        ■     ■■  ■■ ■                         ■■■■  ■ ■■  ■■■
 *            ■■■■ ■■■ ■ ■    ■■    ■  ■                            ■■■■■ ■  ■  ■■■
 *     ■      ■■ ■ ■■■    ■■   ■■  ■■■                 ■■■■         ■ ■■■■■     ■■■
 *   ■■■     ■■■ ■■ ■■■■  ■■■■  ■■■     ■■     ■      ■■■ ■■       ■  ■■■■■     ■ ■
 *     ■   ■■■■■ ■■   ■■■                ■           ■■■           ■   ■■■■     ■
 *  ■■ ■   ■■■■  ■■■         ■■   ■■■■               ■■    ■       ■      ■■    ■
 *  ■■  ■ ■■■■■ ■■ ■■      ■   ■■■ ■ ■              ■■             ■■  ■■    ■  ■■
 * ■■      ■■■■ ■■■■■■ ■■■■■        ■■■            ■■     ■     ■ ■■    ■■   ■   ■■
 * ■   ■■    ■  ■■■   ■    ■■■■■■■■■■■■■           ■■           ■ ■■     ■■■
 *    ■■■  ■   ■■          ■■■■■■■■■■■■■■              ■          ■■       ■ ■  ■■■
 *   ■■■  ■■■  ■■ ■■        ■■■■■■■■■■■■■■                     ■■  ■            ■■
 * ■■■■   ■■       ■ ■   ■■■■■■■■■■■ ■■■■■                     ■   ■         ■  ■
 * ■■■   ■■      ■■■  ■  ■■■■■■■■■■■■■■■■■■                    ■   ■      ■  ■  ■■
 *  ■    ■■      ■ ■■■    ■■■■ ■■■■■■■■■  ■■                   ■   ■            ■
 *      ■■     ■  ■■■■■■ ■■■■■■■■■■■■■■■  ■■■■                ■■   ■     ■  ■■  ■
 *     ■■■       ■■   ■ ■■■■■■■■■■■■■■■■    ■■■ ■■■■■■■■■■■■ ■■    ■       ■    ■
 *    ■■■     ■■■■■  ■   ■■■■■■■■■■■■■■■■ ■■  ■■■■■■■■■■ ■■■■■■ ■■ ■■     ■  ■  ■
 *   ■■■■    ■■  ■■■■  ■■■■■■■■■■■■■■■■■■  ■■  ■■■■■■■■  ■■■■■      ■■  ■■     ■■
 *   ■ ■   ■■■  ■■ ■■■ ■■■■■■■■■■■■■■■■■■  ■■   ■■■■ ■■ ■ ■■■■   ■■■■■ ■■      ■■
 *  ■■ ■  ■■■■■■■  ■■■■■■■■■■■■■■■■■■■■■■■  ■   ■■■■■■■ ■ ■■■    ■■ ■■ ■     ■  ■
 * ■■■■■  ■■■ ■■■  ■■■■■■■■■■■■■■■■■■■■■■■■      ■■■■ ■ ■ ■■  ■ ■     ■      ■  ■
 * ■■■■■ ■■■■   ■ ■■■■■■■■■■■■■■■■■■■■■■■■■      ■■■■■■■    ■■■ ■■■■ ■  ■   ■  ■
 * ■■ ■■ ■■ ■■■■■■ ■■ ■■■■■ ■■■■■■■■■■■■■■        ■■ ■■     ■■■     ■      ■■■■■
 *    ■■ ■■ ■ ■■■■■■■■■■■      ■■■■■■■■■■         ■■   ■■ ■■■■■    ■     ■■■■■■
 *   ■■  ■■■  ■■■■■■■■■■        ■■■■■■■■          ■■■  ■■■■■■■    ■    ■        ■■
 *   ■■  ■■ ■■■■■■■■■■■         ■■■■■   ■          ■■■■■■■■ ■■   ■   ■■      ■■■
 *   ■■  ■■■ ■■■■■■■■■■          ■■■■■■■         ■■■■■■■ ■ ■■■   ■  ■■    ■■■■
 *   ■■  ■■■■■■■■■■■■■   ■■      ■■■■■           ■ ■■■■■   ■■■  ■  ■■ ■■■
 *  ■■■  ■■■■■ ■■■■■■■   ■■■                        ■■■    ■■■ ■   ■ ■■         ■■■
 * ■■■■■ ■■■■■■■■■■■■■   ■■■■                       ■■■   ■■■■     ■■■       ■■■■■
 *  ■■■  ■■■■■ ■■■■■■■   ■■■■                        ■    ■■■■    ■■■     ■■■■■
 * ■■■■  ■■■■■■■■■■■■■    ■■■■                       ■■   ■■■  ■  ■■    ■■■■■
 * ■■    ■■■■■■■■■■■■■    ■■■■                       ■ ■  ■■    ■ ■   ■■■ ■   ■■■■■
 * ■  ■  ■■■■■■■■■■■■■      ■■               ■       ■■■  ■■        ■■■   ■ ■■
 *   ■■  ■■■■■■■■■■■■■                      ■        ■■■ ■■       ■■■  ■■■■■     ■■
 *  ■ ■   ■■■■■■■■■■■■                     ■■        ■   ■       ■■  ■ ■  ■   ■■■
 *    ■    ■■■■■■■■■■■                    ■          ■■  ■     ■■■   ■ ■■■■ ■■
 * ■■■■    ■■■■■■■■■■■■                 ■■          ■■■ ■     ■■   ■■■ ■■  ■■
 * ■■■■      ■■■■■■■■■■                ■■          ■■ ■ ■    ■    ■■■  ■  ■■
 *   ■        ■■■■  ■■■■             ■■■           ■  ■     ■  ■■■■    ■■■■■
 *  ■■          ■■■■■■■ ■■         ■■■                ■   ■■ ■■■■    ■ ■■■■■■
 * ■■        ■    ■■■■ ■■■■■■■■■■■■■■              ■■■   ■■■■■■   ■■     ■■       ■
 *  ■             ■    ■■ ■ ■■■■■                 ■■■■ ■■■ ■■■   ■■              ■■
 * ■■                         ■ ■                ■    ■■■■■■  ■■■■             ■■
 * ■■                  ■          ■■  ■ ■        ■ ■■■■ ■ ■  ■■    ■■       ■■
 */

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract JapaneseTinyPenpen is Ownable, ERC721AQueryable, ERC2981, DefaultOperatorFilterer {
    using Strings for uint256;

    // Token Information
    uint256 public maxSupply = 2_565;
    string private _customURI = "https://arweave.net/-izDDlu4pyGXgry_M2EZ-fR0F0gBNqAroGgVRSAWq04/";
    string private _extension = ".json";

    // Sale Information
    bytes32 private _merkleRoot;
    uint64 public cost;
    uint8 public salePhase;
    uint8 public lastSalePhase;
    uint8 private constant _MAX_PER_TX = 10;

    // Other
    address private _handler = 0x82fEDBC04ddB1BDf63754DFBf97a804C644b5525;
    uint256 private constant _MASK_UINT8 = (1 << 8) - 1;
    uint256 private constant _MASK_UINT16 = (1 << 16) - 1;
    uint256 private constant _MASK_ADDRESS = (1 << 160) - 1;
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                ERROR
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @dev Not allowed to be called from other contracts.
    error NotAllowedCaller();

    /// @dev Not allowed to be called from unauthorized handlers.
    error NotAllowedHandler();

    /// @dev Not on sale.
    error NotOnSale();

    /// @dev Incorrect amount of mint.
    error IncorrectAmountOfMint();

    /// @dev Insufficient funds.
    error InsufficientFunds();

    /// @dev Exceeds the volume of one transaction.
    error ExceedVolumePerTX();

    /// @dev Exceeds supply.
    error ExceedSupply();

    /// @dev OverAllocate.
    error OverAllocate();

    /// @dev Invalid Merkle Proof.
    error InvalidMerkleProof();

    /// @dev Not exist token.
    error NotExistToken();

    /// @dev Incorrect value to set.
    error IncorrectValue();

    /// @dev This function only works the first time.
    error FinishedAirdropPhase();

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Initialize contract and royalty setting.
     * The first argument of the ERC721A constructor is name.
     * The second argument of the ERC721A constructor is symbol.
     * Royalty[contract owner --> x / 10_000].
     */
    constructor() ERC721A("JapaneseTinyPenpen", "JTP") {
        _setDefaultRoyalty(msg.sender, 1_000);
        _mint(_handler, 1);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                  MODIFIER
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    ///  @dev Checking if tx.origin and msg.sender are the same.
    modifier callerIsUser() {
        if (tx.origin != msg.sender) {
            revert NotAllowedCaller();
        }
        _;
    }

    /// @dev Checking if msg.sender are the same as the owner or handler.
    modifier onlyHandler() {
        if (msg.sender != owner() && msg.sender != _handler) {
            revert NotAllowedHandler();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                    SALE
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Set saleInformation.
     * [attention]The same salePhase cannot be used because the check for the amount of minted depends on the salePhase.
     * @param newCost uint64
     * @param newMerkleRoot If not using MerkleProof, use 0x00.
     */
    function setSaleInformation(uint64 newCost, bytes32 newMerkleRoot) external onlyHandler {
        if (salePhase == 0) {
            salePhase = lastSalePhase + 1;
        } else {
            salePhase = salePhase + 1;
        }

        _merkleRoot = newMerkleRoot;
        cost = newCost;
    }

    /**
     * @dev Stop sale[salePhase == 0 is Not on sale].
     * [attention]The same salePhase cannot be used because the check for the amount of minted depends on the salePhase.
     */
    function stopSale() external onlyHandler {
        lastSalePhase = salePhase;
        salePhase = 0;
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                    MINT
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev public mint for sale information.
     * @param _mintAmount is under 2 ** 16.
     * @param _maxMintAmount is under 2 ** 16.
     * @param _merkleProof If MerkleProof is not checked, you can use anything.
     */
    function mint(uint256 _mintAmount, uint256 _maxMintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser
    {
        if (_merkleRoot != 0x00) {
            _checkMerkleProof(_maxMintAmount, _merkleProof);
            _checkMintedAmount(_mintAmount, _maxMintAmount);
        }
        _checkMint(_mintAmount);
        _mint(msg.sender, _mintAmount);
    }

    /**
     * @dev checking various conditions for mint.
     * @param _mintAmount is under 2 ** 16.
     */
    function _checkMint(uint256 _mintAmount) internal {
        if (salePhase == 0) {
            revert NotOnSale();
        }

        if (_mintAmount == 0) {
            revert IncorrectAmountOfMint();
        }

        if (msg.value < cost * _mintAmount) {
            revert InsufficientFunds();
        }

        if (_mintAmount > _MAX_PER_TX) {
            revert ExceedVolumePerTX();
        }

        if (totalSupply() + _mintAmount > maxSupply) {
            revert ExceedSupply();
        }
    }

    /**
     * @dev checking already minted amount on sale.
     * @param _mintAmount is under 2 ** 16.
     * @param _maxMintAmount is under 2 ** 16.
     */
    function _checkMintedAmount(uint256 _mintAmount, uint256 _maxMintAmount) internal {
        uint256 _mintedInfo = ERC721A._getAux(msg.sender);

        uint256 _mintedAmount = _mintedInfo & _MASK_UINT16;

        if (_mintedInfo >> 16 & _MASK_UINT8 != salePhase) {
            _mintedAmount = 0;
        }

        uint256 temp = _mintedAmount + _mintAmount;

        if (temp > _maxMintAmount) {
            revert OverAllocate();
        }

        uint256 newMintedInfo = (uint256(salePhase) << 16) | temp;

        ERC721A._setAux(msg.sender, uint64(newMintedInfo));
    }

    /**
     * @dev checking MerkleProof.
     * @param _maxMintAmount is under 2 ** 16.
     */
    function _checkMerkleProof(uint256 _maxMintAmount, bytes32[] calldata _merkleProof) internal view {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _maxMintAmount));
        if (MerkleProof.verify(_merkleProof, _merkleRoot, leaf) == false) {
            revert InvalidMerkleProof();
        }
    }

    /**
     * @dev Minted by owner with no cost.
     * @param _mintAmount less than 30 is recommended.
     */
    function ownerMint(address _address, uint256 _mintAmount) external onlyOwner {
        if (totalSupply() + _mintAmount > maxSupply) {
            revert ExceedSupply();
        }
        _mint(_address, _mintAmount);
    }

    /**
     * @dev Airdrop by owner with no cost.
     * This airdrop is a collaboration benefit.
     * [attention]slot number/_packedAddressData.
     */
    function airdrop(bytes memory data) external onlyOwner {
        assembly {
            let last := add(data, mload(data))

            // startTokenId
            let _currentIndex := sload(1)

            // check startTokenId
            if lt(1437, _currentIndex) {
                mstore(0x00, 0xe37dc650) // `FinishedAirdropPhase()`
                revert(0x1c, 0x04)
            }

            let time := shr(160, timestamp())
            let initialized := shl(225, 1)
            // [balance/numberMinted]
            let packedAddressData := or(shl(64, 1), 1)

            // free memory pointer
            let ptr1 := mload(0x40)
            let ptr2 := add(ptr1, 0x40)

            // memory space allocate:
            //  - [0x00]_packedOwnerships[tokenId].key
            //  - [0x20]_packedOwnerships[tokenId].slot
            //  - [0x40]_packedAddressData[address].key
            //  - [0x60]_packedAddressData[address].slot

            // [0x20]_packedOwnerships[tokenId].slot
            mstore(add(ptr1, 0x20), 5)

            // [0x60]_packedAddressData[address].slot
            mstore(add(ptr2, 0x20), 6)

            for {
                // memory counter
                let mc := add(data, 0x20)
                let addr
                let value
            } 1 {
                mc := add(mc, 20)
                _currentIndex := add(_currentIndex, 1)
            } {
                addr := shr(96, mload(mc))

                // [0x00]_packedOwnerships[tokenId].key
                mstore(ptr1, _currentIndex)
                // [addr/timestamp/nextInitialized]
                value := or(or(addr, time), initialized)
                // _packedOwnerships[tokenId] = value
                sstore(keccak256(ptr1, 0x40), value)

                // [0x40]_packedAddressData[address].key
                mstore(ptr2, addr)
                // _packedAddressData[address] = packedAddressData
                sstore(keccak256(ptr2, 0x40), packedAddressData)

                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    addr, // `to`.
                    _currentIndex // `tokenId`.
                )

                if lt(last, mc) { break }
            }

            // owner airdrop
            let addr := caller()
            last := add(_currentIndex, 100)

            for { let value } 1 {} {
                _currentIndex := add(_currentIndex, 1)

                // [0x00]_packedOwnerships[tokenId].key
                mstore(ptr1, _currentIndex)
                // [addr/timestamp/nextInitialized]
                value := or(or(addr, time), initialized)
                // _packedOwnerships[tokenId] = value
                sstore(keccak256(ptr1, 0x40), value)

                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    addr, // `to`.
                    _currentIndex // `tokenId`.
                )

                if eq(last, _currentIndex) { break }
            }

            // [balance/numberMinted]
            packedAddressData := mul(packedAddressData, 100)

            // [0x40]_packedAddressData[address].key
            mstore(ptr2, addr)
            // _packedAddressData[address] = packedAddressData
            sstore(keccak256(ptr2, 0x40), packedAddressData)

            // update _currentIndex
            sstore(1, add(_currentIndex, 1))
        }
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                TOKEN CONFIG
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev startTokenId == 1436.
     * Items before token ID 1436 will be in a another collection[TinyPenpen].
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1436;
    }

    /**
     * @dev Return `_customURI`.
     */
    function _baseURI() internal view override returns (string memory) {
        return _customURI;
    }

    /**
     * @dev Return tokenURI(`_customURI` + `_tokenId` + `_extension`).
     */
    function tokenURI(uint256 _tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(_tokenId)) {
            revert NotExistToken();
        }

        return string(abi.encodePacked(ERC721A.tokenURI(_tokenId), _extension));
    }

    /**
     * @dev Set `newCustomURI` to `_customURI`.
     * `_customURI` is used for tokenURI information.
     */
    function setCustomURI(string memory newCustomURI) external onlyHandler {
        _customURI = newCustomURI;
    }

    /**
     * @dev Set `newExtension` to `_extension`.
     * `_extension` is used for tokenURI information.
     */
    function setExtention(string memory newExtension) external onlyHandler {
        _extension = newExtension;
    }

    /**
     * @dev Set `newMaxSupply` to `maxSupply`.
     * [Attension]Note the _startTokenId.
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyHandler {
        if (maxSupply > newMaxSupply) {
            revert IncorrectValue();
        }
        maxSupply = newMaxSupply;
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                    OTHER
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Set `_royaltyAddress` to royalty `receiver`
     * Set `_royaltyFee` to royalty `feeNumerator`.
     * @param _royaltyFee must be less than 10000.
     */
    function setDefaultRoyalty(address _royaltyAddress, uint96 _royaltyFee) external onlyOwner {
        _setDefaultRoyalty(_royaltyAddress, _royaltyFee);
    }

    /**
     * @dev Set `_newExtension` to `_extension`.
     * The `_handler` can manipulate functions for which onlyHandler is set.
     */
    function setHandler(address newHandler) external onlyHandler {
        _handler = newHandler;
    }

    /**
     * @dev Withdraw ETH, etc. accumulated in contract.
     * [Attension]This function must be for owner authority only.
     */
    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                    OpenSea operator-filter-registry
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                IERC165
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A, IERC721A)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}