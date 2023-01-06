// SPDX-License-Identifier: MIT

/**
  ____         _____ _____ _   _       _ _ _       _   _                                           ____      _ _           _   _             
 |  _ \ _ __  | ____|_   _| | | |_   _(_) ( )___  | | | | ___  _ __   ___  _ __ __ _ _ __ _   _   / ___|___ | | | ___  ___| |_(_) ___  _ __  
 | | | | '__| |  _|   | | | |_| \ \ / / | |// __| | |_| |/ _ \| '_ \ / _ \| '__/ _` | '__| | | | | |   / _ \| | |/ _ \/ __| __| |/ _ \| '_ \ 
 | |_| | |_   | |___  | | |  _  |\ V /| | | \__ \ |  _  | (_) | | | | (_) | | | (_| | |  | |_| | | |__| (_) | | |  __/ (__| |_| | (_) | | | |
 |____/|_(_)  |_____| |_| |_| |_| \_/ |_|_| |___/ |_| |_|\___/|_| |_|\___/|_|  \__,_|_|   \__, |  \____\___/|_|_|\___|\___|\__|_|\___/|_| |_|
                                                                                          |___/                                              
 */

pragma solidity ^0.8.17;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { Owned } from "solmate/src/auth/Owned.sol";
import { LibString } from "solmate/src/utils/LibString.sol";
import "./DrETHvilHonoraryContractErrors.sol";

/**
 * @title Dr. ETHvil's Honorary Collection contract
 * @author New Fundamentals, LLC
 *
 * @notice a unique NFT collection for supports of Dr. ETHvil
 */
contract DrETHvilHonoraryContract is ERC721A, Owned {
    using LibString for uint256;

    event SetContractURI(string contractURI);
    event SetBaseURI(string baseTokenURI);
    event SetRoyaltyInfo(address royaltyRecipient, uint256 royaltyAmountNumerator);
    event Withdrew(uint256 balance);

    bytes4 private constant INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint64 private constant ROYALTY_AMOUNT_DENOMINATOR = 1e18;
    
    string internal _contractURI;
    string internal _baseTokenURI;

    address internal _royaltyRecipient;
    uint256 internal _royaltyAmountNumerator;

    /**
     * @param baseTokenURI A string you want the token URI to be set to, will be used as placeholder URI until reveal
     */
    constructor(
        string memory baseTokenURI
    ) ERC721A("Dr. ETHvil's Honorary Collection", "HONORARY") Owned(msg.sender) {
        _baseTokenURI = baseTokenURI;
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
     * @notice Get a token's metadata
     * 
     * @param tokenId The ID of the token you wish to get's metadata
     * 
     * @return tokenURI A string that defines the token's URI to obtain the token's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert NonExistentToken(tokenId);
        }

        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"));
    }

    /**
     * @notice Query tokens owned by an address, in a given range.
     *
     * @param owner An address you wish to query for.
     * @param startIndex The starting index of the range you wish to query through.
     * @param endIndex The ending index of the range you wish to query through.
     * 
     * @return tokenIds An array of token IDs within the range provided, that the address owns.
     */
    function tokensOfOwner(address owner, uint256 startIndex, uint256 endIndex) external view returns(uint256[] memory) {
        return _findTokensOfOwner(owner, startIndex, endIndex);
    }

    /**
     * @notice Query all tokens owned by an address.
     *
     * @param owner An address you wish to query for.
     * 
     * @return tokenIds An array of token IDs that the address owns.
     */
    function walletOfOwner(address owner) external view returns(uint256[] memory) {
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
     * @notice Allows the contract owner to mint tokens and to airdrop all tokens to existing FrankenPunks holders.
     * 
     * @param numberToMint The number of tokens to mint
     */
    function mintTokens(uint256 numberToMint) external onlyOwner {
        if (numberToMint == 0) {
            revert MintZeroQuantity();
        }

        _mint(msg.sender, numberToMint);
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
    function _findTokensOfOwner(address owner, uint256 startIndex, uint256 endIndex) internal view returns(uint256[] memory) {
        if (totalSupply() == 0) {
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

        uint256[] memory ownerTokens = new uint256[](maxArraySize);
        
        for (uint256 tokenId = startIndex; tokenId < endIndex; tokenId++) {
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
    function _getMinTokenID() internal view returns(uint256) {
        if (totalSupply() == 0) {
            return 0;
        }

        return _startTokenId();
    }

    /**
     * @dev Returns the largest token ID.
     * 
     * @return minTokenId The largest token ID.
     */
    function _getMaxTokenID() internal view returns(uint256) {
        if (totalSupply() == 0) {
            return 0;
        }

        return _nextTokenId() - 1;
    }
}