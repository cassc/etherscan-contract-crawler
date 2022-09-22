// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

/**
 * @title ValeriaChampions
 */
contract ValeriaChampions is ERC721AQueryable, ERC721ABurnable, Ownable {
    using Strings for uint256;

    // @dev Base uri for the nft
    string private baseURI;

    // @dev Hidden uri for the unrevealed nft
    string private hiddenURI =
        "ipfs://bafybeihr6ta6rurqvhcqeimd656h6scswh2hsezgrypowjdeqzn5zgaf5y/hidden.json";

    // @dev The merkle root proof
    bytes32 public merkleRoot =
        0x504c411597990ad3e891ef6b839f3c83e255b570e703015e494342b9b2ca6573;

    // @dev The team wallet address
    address public team = payable(0x7d26b65599a86f99B477F7Ef6414a5Abca1a5e4e);

    // @dev The reveal state
    bool public isRevealed = false;

    // @dev The live state
    bool public isLive = false;

    // @dev The address mint counter
    mapping(address => uint256) public addressToMinted;

    constructor() ERC721A("Valeria Champions", "VC") {
        _mintERC2309(team, 170); // Team mints, 1/1s, and giveaways
    }

    /**
     * @notice Whitelist mint with allowance which requires a merkle proof
     * @param _amount The amount to mint
     * @param _allowance The allowance of the address
     * @param _proof The bytes32 array proof to verify the merkle root
     */
    function mint(
        uint256 _amount,
        uint256 _allowance,
        bytes32[] calldata _proof
    ) external {
        require(isLive, "Not Live.");
        bytes32 leaf = keccak256(
            abi.encodePacked(
                string(abi.encodePacked(_msgSender())),
                Strings.toString(_allowance)
            )
        );
        require(
            MerkleProof.verify(_proof, merkleRoot, leaf),
            "Not whitelisted."
        );
        require(
            addressToMinted[_msgSender()] + _amount <= _allowance,
            "Exceeds whitelist supply."
        );
        addressToMinted[_msgSender()] += _amount;
        _mint(_msgSender(), _amount);
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Returns the URI for a given token id
     * @param _tokenId A tokenId
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();
        if (!isRevealed) return hiddenURI;
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")
            );
    }

    /**
     * @notice Sets the live state
     * @param _isLive a flag for whether the collection mint is live
     */
    function setIsLive(bool _isLive) external onlyOwner {
        isLive = _isLive;
    }

    /**
     * @notice Sets the reveal flag
     * @param _isRevealed a flag for whether the collection is revealed
     */
    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    /**
     * @notice Sets the hidden URI of the NFT
     * @param _hiddenURI A base uri
     */
    function setHiddenURI(string calldata _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _baseURI A base uri
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}