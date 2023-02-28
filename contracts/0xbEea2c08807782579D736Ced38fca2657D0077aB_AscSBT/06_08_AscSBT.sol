// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AscSBT is ERC721A, Ownable, Pausable {
    /* ============ State Variables ============ */
    uint256 public MAX_SUPPLY = 100000;
    uint256 public MAX_PERSONALITY = 10;
    uint256 public MAX_MINT_PER_WALLET = 1;
    uint256 public MAX_MINT_PER_TX = 1;

    string public uriSuffix = ".json";
    string public baseURI;
    string public defaultURI;

    mapping(address => uint256) private _mintedAddresses;
    mapping(uint256 => uint256) private _tokenPersonalities;

    /* ============ Constructor ============ */
    constructor(
        string memory _baseURI,
        string memory _defaultURI
    ) ERC721A("AscSBT", "ASCSBT") {
        baseURI = _baseURI;
        defaultURI = _defaultURI;
    }

    /* ============ Main Public Functions ============ */
    /**
     * @notice Mint the SBT and set a personality
     * @param quantity the quantity of tokens to mint
     * @param personalityId the personality ID that will be set
     */
    function mint(
        uint256 quantity,
        uint256 personalityId
    ) external payable whenNotPaused {
        require(quantity <= MAX_MINT_PER_TX, "Max mint per TX exceeded");
        require(
            _mintedAddresses[msg.sender] == 0,
            "Max mint per wallet exceeded"
        );

        _mintedAddresses[msg.sender] = _mintedAddresses[msg.sender] + 1;
        _mint(msg.sender, quantity);
        _setTokenPersonality(_nextTokenId() - 1, personalityId);
    }

    /**
     * @notice Change the personality for token ID (Only owner of token can set)
     * @param tokenId the token ID to set
     * @param personalityId the personality ID that will be set
     */
    function setTokenPersonality(
        uint256 tokenId,
        uint256 personalityId
    ) external payable whenNotPaused {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only the owner of SBT can set the personality"
        );

        _setTokenPersonality(tokenId, personalityId);
    }


    /* ============ Getter Functions ============ */
     /**
     * @notice Get the token total minted count
     * @param _address the address to query
     */
    function getAddressMintedCount(
        address _address
    ) public view returns (uint256) {
        return _mintedAddresses[_address];
    }

     /**
     * @notice get the token personality
     * @param tokenId the token ID to set
     */
    function getTokenPersonality(
        uint256 tokenId
    ) public view returns (uint256) {
        return _tokenPersonalities[tokenId];
    }

    /* ============ Owner Setter Functions ============ */
    /**
     * @notice Change the personality for token ID (Only owner of token can set)
     * @param tokenId the token ID to set
     * @param personalityId the personality ID that will be set
     */
    function ownerSetTokenPersonality(
        uint256 tokenId,
        uint256 personalityId
    ) external payable onlyOwner {
        _setTokenPersonality(tokenId, personalityId);
    }

    /**
     * @notice Set the baseURI
     * @param _newBaseURI the URI that will be set
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Set the URI suffix (e.g. .json)
     * @param _uriSuffix the URI suffix that will be set
     */
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /**
     * @notice Pause the contract
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Set the max supply
     */
    function setMaxSupply(uint256 maxSupply) public onlyOwner {
        MAX_SUPPLY = maxSupply;
    }

    /**
     * @notice Set the max per tx
     */
    function setMaxPerTx(uint256 maxPerTx) public onlyOwner {
        MAX_MINT_PER_TX = maxPerTx;
    }

    /**
     * @notice Set the max personality
     */
    function setMaxPersonality(uint256 maxPersonality) public onlyOwner {
        MAX_PERSONALITY = maxPersonality;
    }

    /* ============ Internal Functions ============ */
    /**
     * @notice SOULBOUND TOKEN: No transfer is allowed
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        require(from == address(0), "Asc SBT: token transfer is BLOCKED");

        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    /**
     * @notice Set the personality for token
     */
    function _setTokenPersonality(
        uint256 tokenId,
        uint256 personalityId
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        require(
            personalityId <= MAX_PERSONALITY && personalityId > 0,
            "Invalid personality supplied"
        );

        _tokenPersonalities[tokenId] = personalityId;
    }

    /* ============ Overwritten Public Functions ============ */
    /**
     * @notice SOULBOUND TOKEN: No approval is allowed
     */
    function approve(
        address,
        uint256
    ) public payable virtual override(ERC721A) {
        revert("Asc SBT: approval is BLOCKED");
    }

    /**
     * @notice SOULBOUND TOKEN: Block approvals.
     */
    function setApprovalForAll(address, bool) public virtual override(ERC721A) {
        revert("Asc SBT: approval is BLOCKED");
    }

    /**
     * @notice Token URI mapping is stored seperately
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 _tokenPersonality = _tokenPersonalities[tokenId];
        string memory base = baseURI;

        // If there is no base URI, return the return the default URI.
        if (bytes(base).length == 0) {
            return defaultURI;
        }

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        return
            string(
                abi.encodePacked(
                    base,
                    Strings.toString(_tokenPersonality),
                    uriSuffix
                )
            );
    }
}