/*
╭━━━╮╱╱╱╱╱╱╱╱╱╱╱╱╱╱╭━━━╮╱╱╱╱╱╱╱╱╭╮
┃╭━╮┃╱╱╱╱╱╱╱╱╱╱╱╱╱╱┃╭━╮┃╱╱╱╱╱╱╱╭╯╰╮
┃┃╱┃┣━┳━━┳━╮╭━━┳━━╮┃┃╱╰╋━━┳╮╭┳━┻╮╭╯
┃┃╱┃┃╭┫╭╮┃╭╮┫╭╮┃┃━┫┃┃╱╭┫╭╮┃╰╯┃┃━┫┃
┃╰━╯┃┃┃╭╮┃┃┃┃╰╯┃┃━┫┃╰━╯┃╰╯┃┃┃┃┃━┫╰╮
╰━━━┻╯╰╯╰┻╯╰┻━╮┣━━╯╰━━━┻━━┻┻┻┻━━┻━╯
╱╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
╱╱╱╱╱╱╱╱╱╱╱╱╰━━╯
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./utils/Uri.sol";
import "./interfaces/ICometEvents.sol";

/**
 * @title  ERC721Comet
 * @author Orange Comet
 *
 * @notice Orange Comet standard ERC721 contract
 */
abstract contract ERC721Comet is ERC721A, Uri, ICometEvents, IERC2981 {
    // The provenanceHash
    bytes32 _provenanceHash;

    // The royalty percentage as a percent (e.g. 10 for 10%)
    uint256 _royaltyPercent;

    // The max supply of tokens in this contract.
    uint256 _maxSupply;

    // The beneficiary wallet.
    address _beneficiary;

    // The royalties wallet.
    address _royalties;

    /**
     * @notice ERC721 Auctionable constructor.
     *
     * @param name The token name.
     * @param symbol The token symbol.
     */
    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {
        // set default royalty percent to 10;
        _royaltyPercent = 10;

        // set the default royalty payout to the owner for safety
        _royalties = owner();

        // set the default beneficiary payout to the owner for safety
        _beneficiary = owner();
    }

    /**
     * @notice Gets the Base URI of the token API.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Returns the provenance hash.
     */
    function provenanceHash() external view returns (bytes32) {
        return _provenanceHash;
    }

    /**
     * @notice Override start token ID with #1.
     */
    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Sets the provenance hash.
     *
     * @param value The provenance hash.
     */
    function setProvenanceHash(bytes32 value) external onlyOwner {
        _provenanceHash = value;
    }

    /**
     * @notice Sets the max supply of tokens.
     *
     * @param value The max supply.
     */
    function setMaxSupply(uint256 value) public onlyOwner {
        _maxSupply = value;

        emit MaxSupplyUpdated(value);
    }

    /**
     * @notice Sets the beneficiary wallet address.
     *
     * @param wallet The new wallet address.
     */
    function setBeneficiary(address wallet) public onlyOwner {
        _beneficiary = wallet;
    }

    /**
     * @notice Returns the beneficiary.
     */
    function beneficiary() external view returns (address) {
        return _beneficiary;
    }

    /**
     * @notice Returns the royalties wallet.
     */
    function royalties() external view returns (address) {
        return _royalties;
    }

    /**
     * @notice Returns the maxSupply of the contract.
     */
    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @notice Sets the royalties wallet address.
     *
     * @param wallet The new wallet address.
     */
    function setRoyalties(address wallet) public onlyOwner {
        _royalties = wallet;
    }

    /**
     * @notice Sets the royalty percentage.
     *
     * @param value The value as an integer (e.g. 10 for 10%).
     */
    function setRoyaltyPercent(uint256 value) external onlyOwner {
        _royaltyPercent = value;
    }

    /**
     * @notice Sets the drop config in a single call.
     *
     * @param newMaxSupply The max supply of the contract.
     * @param newRoyalties The address of the royatlies wallet.
     * @param newBeneficiary The address of the beneficiary wallet.
     * @param newBaseURI The metadata baseURI.
     * @param newContractURI The metadata contractURI.
     */
    function setConfig(
        uint256 newMaxSupply,
        address newRoyalties,
        address newBeneficiary,
        string memory newBaseURI,
        string memory newContractURI
    ) external onlyOwner {
        require(
            _totalMinted() == 0,
            "Cannot set config after minting has begun"
        );

        setMaxSupply(newMaxSupply);
        setRoyalties(newRoyalties);
        setBeneficiary(newBeneficiary);
        setBaseURI(newBaseURI);
        setContractURI(newContractURI);

        emit ContractConfigUpdated(
            newMaxSupply,
            newRoyalties,
            newBeneficiary,
            newBaseURI,
            newContractURI
        );
    }

    /**
     * @notice Supporting ERC721, IER165
     *         https://eips.ethereum.org/EIPS/eip-165
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return `true` if the contract implements `interfaceId`
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}