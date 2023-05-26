// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'solady/src/utils/ECDSA.sol';
import 'solady/src/utils/LibString.sol';
import 'solady/src/utils/SafeTransferLib.sol';

contract Homie is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable {
    using ECDSA for bytes32;

    uint256 public constant PS_FREE_LIMIT = 2;

    uint256 public constant PS_PRICE = 0.02 ether;

    uint256 public constant PER_ACCOUNT_SALE_LIMIT = 5;

    uint8 public constant SALE_STATE_OG = 1;

    uint8 public constant SALE_STATE_WL = 2;

    uint8 public constant SALE_STATE_PS = 3;

    string private _unrevealedURI;

    string private _revealedURI;

    address public signer;

    uint16 public maxSupply;

    uint8 public saleState;

    bool public mintLocked;

    bool public maxSupplyLocked;

    bool public tokenURILocked;
    
    constructor() ERC721A('Homie', 'HOMIE') {}
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (bytes(_revealedURI).length != 0) {
            return LibString.replace(_revealedURI, '{id}', _toString(tokenId));
        }
        return _unrevealedURI;
    }

    function mint(uint256 quantity, bytes calldata signature) external payable {
        require(tx.origin == msg.sender, 'Not EOA.');
        unchecked {
            if (saleState == SALE_STATE_OG || saleState == SALE_STATE_WL) {
                _validateSignature(signature);
                _addToMintedAndCheckLimitAndPrice(msg.sender, quantity);
            } else if (saleState == SALE_STATE_PS) {
                _addToMintedAndCheckLimitAndPrice(msg.sender, quantity);
            } else {
                revert('Not open.');
            }            
        }
        _checkMint(quantity);
        _mint(msg.sender, quantity);
    }

    function numberMintedForCurrentSale(address minter) external view returns (uint256) {
        (, uint256 prev, ) = _incrementedAuxForCurrentSale(minter, 0);
        return prev;
    }

    function _checkMint(uint256 quantity) private view {
        unchecked {
            require(mintLocked == false, 'Locked.');
            require(_totalMinted() + quantity <= maxSupply, 'Out of stock!');
        }
    }

    function _incrementedAux(
        address minter, 
        uint256 state, 
        uint256 quantity
    ) private view returns (uint64 packed, uint256 prev, uint256 result) {
        uint64 aux = _getAux(minter);
        assembly {
            let shift := shl(4, sub(byte(state, hex"0001020304"), 1))
            prev := and(shr(shift, aux), 0xffff)
            result := add(prev, quantity)
            packed := xor(aux, shl(shift, xor(prev, result)))
        }
    }

    function _incrementedAuxForCurrentSale(
        address minter,
        uint256 quantity
    ) private view returns (uint64 packed, uint256 prev, uint256 result) {
        uint256 state = saleState;
        assembly {
            state := byte(state, hex"0001010304")
        }
        return _incrementedAux(minter, state, quantity);
    }

    function _addToMintedAndCheckLimitAndPrice(
        address minter,
        uint256 quantity
    ) private {
        unchecked {
            (uint64 packed, uint256 prev, uint256 result) =
                _incrementedAuxForCurrentSale(minter, quantity);
            require(result <= PER_ACCOUNT_SALE_LIMIT, 'No more slots.');
            if (saleState == SALE_STATE_PS) {
                uint256 totalPrice;
                assembly {
                    let resultDiff := mul(sub(result, PS_FREE_LIMIT), gt(result, PS_FREE_LIMIT))
                    let prevDiff := mul(sub(prev, PS_FREE_LIMIT), gt(prev, PS_FREE_LIMIT))
                    totalPrice := mul(sub(resultDiff, prevDiff), PS_PRICE)
                }
                require(msg.value == totalPrice, 'Wrong Ether value.');    
            }
            _setAux(minter, packed);
        }
    }

    function _validateSignature(bytes calldata signature) private view {
        bytes32 hash = keccak256(abi.encode(msg.sender, saleState));
        address recovered = hash.toEthSignedMessageHash().recover(signature);
        require(recovered == signer, 'Invalid signature.');
    }

    // =============================================================
    //                        ADMIN FUNCTIONS
    // =============================================================

    function forceMint(address[] calldata to, uint256 quantity) external onlyOwner {
        unchecked {
            for (uint256 i; i != to.length; ++i) {
                _checkMint(quantity);
                _mint(to[i], quantity);
            }
        }
    }

    function selfMint(uint256 quantity) external onlyOwner {
        _checkMint(quantity);
        unchecked {
            uint256 miniBatchSize = 8;
            uint256 i = quantity % miniBatchSize;
            _mint(msg.sender, i);
            while (i != quantity) {
                _mint(msg.sender, miniBatchSize);
                i += miniBatchSize;
            }
        }
    }

    function setRevealedURI(string calldata value) external onlyOwner {
        require(tokenURILocked == false, "Locked.");
        _revealedURI = value;
    }

    function setUnrevealedURI(string calldata value) external onlyOwner {
        require(tokenURILocked == false, "Locked.");
        _unrevealedURI = value;
    }

    function setMaxSupply(uint16 value) external onlyOwner {
        require(maxSupplyLocked == false, "Locked.");
        maxSupply = value;
    }

    function setSaleState(uint8 value) external onlyOwner {
        if (saleState != 0) {
            require(maxSupply != 0, "Max supply not set.");
            require(signer != address(0), "Signer not set.");
        }
        saleState = value;
    }

    function setSigner(address value) external onlyOwner {
        signer = value;
    }

    function lockMint() external onlyOwner {
        mintLocked = true;
    }

    function lockMaxSupply() external onlyOwner {
        maxSupplyLocked = true;
    }

    function lockTokenURI() external onlyOwner {
        tokenURILocked = true;
    }

    function withdraw() payable external onlyOwner {
        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }
}