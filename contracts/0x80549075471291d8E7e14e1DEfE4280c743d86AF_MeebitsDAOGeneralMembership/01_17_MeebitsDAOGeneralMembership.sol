// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Token contract for MeebitsDAO General Membership
 * @dev This contract allows the distribution of MeebitsDAO General Membership tokens.
 *
 * Smart contract work done by joshpeters.eth
 */
contract MeebitsDAOGeneralMembership is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable
{
    using Address for address;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _daoTokenCounter;

    // Base URI
    string private _uri;

    // Sale toggle
    bool public isSaleActive;

    // 0.05 ETH
    uint256 public constant MINT_PRICE = 50000000000000000;

    // Max number of tokens
    uint256 public immutable maxSupply;
    uint256 public immutable daoMaxSupply;

    // Merkle tree root
    bytes32 public immutable root;

    // Track addresses that have bought
    mapping(address => bool) private bought;

    constructor(
        uint256 _maxSupply,
        uint256 _daoMaxSupply,
        bytes32 _root
    ) ERC721("MeebitsDAOMembershipToken", "MDM") {
        isSaleActive = false;
        maxSupply = _maxSupply;
        daoMaxSupply = _daoMaxSupply;
        root = _root;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // @dev Allows to enable/disable minting of sale
    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    // @dev Allows to set the baseURI dynamically
    // @param uri The base uri for the metadata store
    function setBaseURI(string memory uri) external onlyOwner {
        _uri = uri;
    }

    function _getMetadataIndex() private view returns (uint256) {
        /* solhint-disable not-rely-on-time */
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        _tokenIdCounter.current()
                )
            )
        );
        /* solhint-enable not-rely-on-time */

        uint256 randNum = (seed - ((seed / 1000) * 1000));
        if (randNum < 575) {
            return randNum % 8;
        } else if (randNum >= 575 && randNum < 875) {
            return (randNum % 5) + 8;
        } else if (randNum >= 875 && randNum < 965) {
            return (randNum % 3) + 13;
        } else if (randNum >= 965 && randNum < 995) {
            return (randNum % 2) + 16;
        } else {
            return 18;
        }
    }

    function _mintToken(address to) private {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);

        _setTokenURI(tokenId, Strings.toString(_getMetadataIndex()));
        _tokenIdCounter.increment();
    }

    // @dev Main minting function
    function mintGeneralMembership() external payable {
        require(isSaleActive, "Sale must be active");
        require(
            _tokenIdCounter.current() < maxSupply,
            "Token count exceeds limit"
        );
        require(MINT_PRICE == msg.value, "Ether value sent is not correct");
        require(!bought[msg.sender], "Address can only mint 1 token");
        require(
            !Address.isContract(msg.sender),
            "Caller must not be a contract"
        );

        bought[msg.sender] = true;
        _mintToken(msg.sender);
    }

    // @dev Whitelisted minting function
    // @param proof Merkel tree proof
    function mintWhitelistGeneralMembership(bytes32[] calldata proof) external {
        require(isSaleActive, "Sale must be active");
        require(
            _tokenIdCounter.current() < maxSupply,
            "Token count exceeds limit"
        );
        require(!bought[msg.sender], "Address can only mint 1 token");
        require(
            !Address.isContract(msg.sender),
            "Caller must not be a contract"
        );
        require(
            MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Caller not whitelisted"
        );

        bought[msg.sender] = true;
        _mintToken(msg.sender);
    }

    // @dev Private mint function reserved for dao
    // @param to Address to mint token(s) to
    // @param tokenCount Number of tokens to mint
    function mint(address to, uint256 tokenCount) external onlyOwner {
        require(
            _tokenIdCounter.current() < maxSupply,
            "Token count exceeds limit"
        );
        require(
            _daoTokenCounter.current() + tokenCount <= daoMaxSupply,
            "Token count exceeds dao limit"
        );
        for (uint256 i = 0; i < tokenCount; i++) {
            _mintToken(to);
            _daoTokenCounter.increment();
        }
    }

    // @dev Returns if an address is whitelisted & hasn't minted a token
    // @param proof Merkel tree proof
    // @param _address Address to check
    function isEligibleWhitelist(bytes32[] calldata proof, address _address)
        external
        view
        returns (bool)
    {
        if (
            MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(_address))
            ) && !bought[_address]
        ) {
            return true;
        }
        return false;
    }

    // @dev Returns if an address is hasn't minted a token
    // @param _address Address to check
    function isEligibleMint(address _address) external view returns (bool) {
        return !bought[_address];
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}