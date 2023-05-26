// SPDX-License-Identifier: MIT

/**
 ______ _____            _   _ _  ________ _   _ __  __  ____  _   _  _____ _______ ______ _____   _____ 
|  ____|  __ \     /\   | \ | | |/ /  ____| \ | |  \/  |/ __ \| \ | |/ ____|__   __|  ____|  __ \ / ____|
| |__  | |__) |   /  \  |  \| | ' /| |__  |  \| | \  / | |  | |  \| | (___    | |  | |__  | |__) | (___  
|  __| |  _  /   / /\ \ | . ` |  < |  __| | . ` | |\/| | |  | | . ` |\___ \   | |  |  __| |  _  / \___ \ 
| |    | | \ \  / ____ \| |\  | . \| |____| |\  | |  | | |__| | |\  |____) |  | |  | |____| | \ \ ____) |
|_|    |_|  \_\/_/    \_\_| \_|_|\_\______|_| \_|_|  |_|\____/|_| \_|_____/   |_|  |______|_|  \_\_____/ 
                                                                                                         
 */

pragma solidity ^0.8.17;

import { ERC721 } from "solmate/src/tokens/ERC721.sol";
import { Owned } from 'solmate/src/auth/Owned.sol';
import { LibString } from 'solmate/src/utils/LibString.sol';
import { IFrankenPunks } from "./IFrankenPunks.sol";
import "./FrankenMonstersErrors.sol";

/**
 * @title FrankenMonsters contract
 * @author New Fundamentals, LLC
 *
 * @notice 10,000 NFT collection to support the original 10,000 NFT collection of 3D FrankenPunks
 */
contract FrankenMonsters is ERC721, Owned {
    using LibString for uint256;

    event SetContractURI(string contractURI);
    event SetBaseURI(string baseTokenURI);
    event SetIsRevealed(bool isRevealed);
    event SetRoyaltyInfo(address royaltyRecipient, uint256 royaltyAmountNumerator);
    event SetFrankenPunksContractAddress(address frankenPunksContractAddress);
    event Withdrew(uint256 balance);

    bytes4 private constant INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint16 public constant STARTING_INDEX = 10000;
    uint8 public constant LEGENDARY_SUPPLY = 10;
    uint16 public constant MAX_SUPPLY = 10000 + LEGENDARY_SUPPLY;
    uint64 private constant ROYALTY_AMOUNT_DENOMINATOR = 1e18;
    
    bool internal _isRevealed;

    uint16 internal _totalSupply;

    string internal _contractURI;
    string internal _baseTokenURI;

    address internal _royaltyRecipient;
    uint256 internal _royaltyAmountNumerator;

    address internal _frankenPunksContractAddress;

    /**
     * @param baseTokenURI A string you want the token URI to be set to, will be used as placeholder URI until reveal
     * @param frankenPunksContractAddress The contract address to access FrankenPunks ownership from
     */
    constructor(
        string memory baseTokenURI,
        address frankenPunksContractAddress
    ) ERC721("FrankenMonsters", "FM") Owned(msg.sender) {
        _baseTokenURI = baseTokenURI;
        _frankenPunksContractAddress = frankenPunksContractAddress;
    }

    /**
     * @dev Define all interfaces this contract supports. Make sure to always leave the super call at the end.
     * 
     * @notice Check support for a specific interface.
     * 
     * @param interfaceId An interface ID in byte4 to check support for.
     * 
     * @return isSupported A boolean defining support for the interface ID.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return (
            interfaceId == INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId)
        );
    }

    /**
     * @notice Get the contract's metadata.
     * 
     * @return contractURI A string that defines the contract's URI to obtain the contract's metadata.
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Get the total current supply of tokens.
     * 
     * @return totalSupply A number of the current supply of tokens within this contract.
     */
    function totalSupply() external view returns (uint16) {
        return _totalSupply;
    }

    /**
     * @notice Get a token's metadata
     * 
     * @param tokenId The ID of the token you wish to get's metadata
     * 
     * @return tokenURI A string that defines the token's URI to obtain the token's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_ownerOf[tokenId] == address(0)) {
            revert NonExistentToken(tokenId);
        }

        string memory baseURI = _baseTokenURI;

        if (!_isRevealed) {
            return baseURI;
        }

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    /**
     * @dev Adapted from Nanopass: https://etherscan.io/address/0xf54cc94f1f2f5de012b6aa51f1e7ebdc43ef5afc#code
     * 
     * @notice Query tokens owned by an address, in a given range.
     *
     * @param owner An address you wish to query for.
     * @param startIndex The starting index of the range you wish to query through.
     * @param endIndex The ending index of the range you wish to query through.
     * 
     * @return tokenIds An array of token IDs within the range provided, that the address owns.
     */
    function tokensOfOwner(address owner, uint16 startIndex, uint16 endIndex) external view returns(uint16[] memory) {
        return _findTokensOfOwner(owner, startIndex, endIndex);
    }

    /**
     * @dev Adapted from Nanopass: https://etherscan.io/address/0xf54cc94f1f2f5de012b6aa51f1e7ebdc43ef5afc#code
     * 
     * @notice Query all tokens owned by an address.
     *
     * @param owner An address you wish to query for.
     * 
     * @return tokenIds An array of token IDs that the address owns.
     */
    function walletOfOwner(address owner) external view returns(uint16[] memory) {
        return _findTokensOfOwner(owner, _getMinTokenID(), _getMaxTokenID() + 1);
    }

    /**
     * @notice Implements ERC-2981 royalty info interface.
     * 
     * @param salePrice The sale price of the token.
     * 
     * @return royaltyInfo The royalty info consisting of (the address to pay, the amount to be paid).
     */
    function royaltyInfo(uint256 /* tokenId */, uint256 salePrice) external view returns (address, uint256) {
        return (_royaltyRecipient, salePrice * _royaltyAmountNumerator / ROYALTY_AMOUNT_DENOMINATOR);
    }

    /**
     * @notice Allows contract owner to set the contract URI. This is used to set metadata for thid-parties.
     * 
     * @param newContractURI A string you want the contract URI to be set to.
     */
    function setContractURI(string calldata newContractURI) external onlyOwner {
        _contractURI = newContractURI;
        emit SetContractURI(newContractURI);
    }

    /**
     * @notice Allows contract owner to set the base token URI. This is used in #tokenURI after reveal to compute the final URI of a token.
     * 
     * @param baseTokenURI A string you want the base token URI to be set to.
     */
    function setBaseURI(string calldata baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
        emit SetBaseURI(baseTokenURI);
    }

    /**
     * @notice Allows contract owner to set if the tokens are revealed or not.
     * 
     * @param isRevealed A boolean value used to set if the contract should reveal the tokens or not.
     * @param baseTokenURI A string you want the base token URI to be set to.
     */
    function setIsRevealed(bool isRevealed, string calldata baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
        _isRevealed = isRevealed;
        emit SetBaseURI(baseTokenURI);
        emit SetIsRevealed(isRevealed);
    }

    /**
     * @notice Allows contract owner to set royalty information.
     * 
     * @param royaltyRecipient An address to a wallet or contract who should get paid the royalties.
     * @param royaltyAmountNumerator A uint256 number used to calculate royalty amount.
     */
    function setRoyaltyInfo(address royaltyRecipient, uint256 royaltyAmountNumerator) external onlyOwner {
        _royaltyRecipient = royaltyRecipient;
        _royaltyAmountNumerator = royaltyAmountNumerator;
        emit SetRoyaltyInfo(royaltyRecipient, royaltyAmountNumerator);
    }

    /**
     * @notice Allows contract owner to set the FrankenPunks contrat address
     * 
     * @param frankenPunksContractAddress The FrankenPunks contract address
     */
    function setFrankenPunksContractAddress(address frankenPunksContractAddress) external onlyOwner {
        _frankenPunksContractAddress = frankenPunksContractAddress;
        emit SetFrankenPunksContractAddress(frankenPunksContractAddress);
    }

    /**
     * @notice Allows the contract owner to mint tokens and to airdrop all tokens to existing FrankenPunks holders.
     * 
     * @param numberToMint The number of tokens to mint
     * @param airdropEnabled A flag used to enable aidrops to FrankenPunks holders
     */
    function mintTokens(uint16 numberToMint, bool airdropEnabled) external onlyOwner {
        if (_totalSupply == MAX_SUPPLY) {
            revert AllTokensMinted();
        }

        if (numberToMint == 0) {
            revert MintZeroQuantity();
        }

        if (_totalSupply + numberToMint > MAX_SUPPLY) {
            revert  MintOverMaxSupply(numberToMint, MAX_SUPPLY - _totalSupply);   
        }

        IFrankenPunks frankenPunks = IFrankenPunks(_frankenPunksContractAddress);

        for (uint16 i = _totalSupply; i < _totalSupply + numberToMint; i++) {
            uint16 tokenId = STARTING_INDEX + i;
            address receiver = msg.sender;

            if (i < MAX_SUPPLY - LEGENDARY_SUPPLY && airdropEnabled) {
                try frankenPunks.ownerOf(i) returns (address frankenPunksOwner) {
                    receiver = frankenPunksOwner;
                } catch (bytes memory) {}
            }

            _mint(receiver, tokenId);
        }

        _totalSupply = _totalSupply + numberToMint;
    }

    /**
     * @notice Allows the contract owner to withdraw the balance of the contract.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit Withdrew(balance);
    }

    /**
     * @dev We don't intend on external folks sending payments to this contract.
     * 
     * @notice Allow the contract to receive a transaction.
     */
    receive() external payable {}

    /**
     * @dev Takes an address and an index range and looks to return all owned token IDs.
     * 
     * @param owner An address you wish to query for.
     * @param startIndex The starting index of the range you wish to query through.
     * @param endIndex The ending index of the range you wish to query through.
     * 
     * @return tokenIds An array of token IDs within the range provided, that the address owns.
     */
    function _findTokensOfOwner(address owner, uint16 startIndex, uint16 endIndex) internal view returns(uint16[] memory) {
        if (_totalSupply == 0) {
            revert SearchNotPossible();
        }

        uint256 maxTokenID = _getMaxTokenID();

        if (endIndex < startIndex || startIndex > maxTokenID || endIndex > maxTokenID + 1) {
            revert SearchOutOfRange(startIndex, endIndex, _getMinTokenID(), maxTokenID);
        }

        uint256 tokenCount = balanceOf(owner);
        uint256 rangeCount = endIndex - startIndex;
        uint256 maxArraySize = rangeCount < tokenCount ? rangeCount : tokenCount;
        uint256 ownerIndex = 0;

        uint16[] memory ownerTokens = new uint16[](maxArraySize);
        
        for (uint16 tokenId = startIndex; tokenId < endIndex; tokenId++) {
            if (ownerIndex == maxArraySize) break;

            if (ownerOf(tokenId) == owner) {
                ownerTokens[ownerIndex] = tokenId;
                ownerIndex++;
            }
        }

        return ownerTokens;
    }

    /**
     * @dev Returns the smallest token ID.
     * 
     * @return minTokenId The smallest token ID.
     */
    function _getMinTokenID() internal view returns(uint16) {
        if (_totalSupply == 0) {
            return 0;
        }

        return STARTING_INDEX;
    }

    /**
     * @dev Returns the largest token ID.
     * 
     * @return minTokenId The largest token ID.
     */
    function _getMaxTokenID() internal view returns(uint16) {
        if (_totalSupply == 0) {
            return 0;
        }

        return STARTING_INDEX + _totalSupply - 1;
    }
}