//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IMeebitsLand.sol";

contract MeebitsLand is IMeebitsLand, ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    uint256 public constant TOKEN_LIMIT = 20000;

    Counters.Counter private _tokenIdCounter;
    string private baseURI;

    mapping(address => bool) internal hasMinted;

    //// Random index assignment
    uint256 internal nonce = 0;
    uint256[TOKEN_LIMIT] internal indices;

    bool internal contractMintable;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {
        _pause();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _randomIndex() internal returns (uint256) {
        uint256 totalSize = TOKEN_LIMIT - _tokenIdCounter.current();

        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;
        uint256 value = 0;
        // if there's a cache at indices[i] then use it
        // otherwise use i itself
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value + 1;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    /**
     * @notice Toggles if contracts are allowed to mint tokens for
     */
    function toggleContractMintable() external onlyOwner {
        contractMintable = !contractMintable;
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function mint() external returns (uint256) {
        require(!paused(), "MeebitsLand::mint: mint while paused");
        if (!contractMintable) {
            require(
                msg.sender == tx.origin,
                "MeebitsLand::mint: Minting from smart contracts is disallowed"
            );
        }
        // only allow one minting per account
        require(
            !hasMinted[msg.sender],
            "MeebitsLand::mint: You cannot mint more than once from this contract"
        );

        require(
            _tokenIdCounter.current() < TOKEN_LIMIT,
            "Token limit reached."
        );

        uint256 tokenId = _randomIndex();

        hasMinted[msg.sender] = true;
        _tokenIdCounter.increment();

        _mint(msg.sender, tokenId);

        emit Mint(msg.sender, tokenId);
        return tokenId;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}