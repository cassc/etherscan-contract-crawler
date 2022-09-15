// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/access/Ownable.sol";

import "./IGenesisRenderer.sol";

/// @title An attempt to be the first on-chain NFT minted on POS ETH
/// @author @0x_beans
/// @author @high_byte
contract Genesis is ERC721, Ownable {
    error TokenDoesNotExist();
    error MergeHasNotOccurred();
    error TooLate();

    // cam only mint at most 100 blocks after the merge
    uint256 immutable MAX_MINT_DISTANCE = 100;

    uint256 public genesisMergeBlock;
    uint256 public totalSupply;

    // token renderer
    address public genesisRenderer;

    mapping(address => uint256) public minterToToken;
    mapping(uint256 => uint256) public tokenToBlockNumber;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "only EOA");
        _;
    }

    constructor() ERC721("Sunrise", "SUNRISE") {}

    // can only start minting after the merge has occurred
    // can only mint 1 token, if you submit multiple mint txns,
    // you'll update your token values
    function mint() external onlyEOA {
        // assert merge has occurred
        assertPOS();

        // assert you're minting within 100 blocks
        if (block.number - genesisMergeBlock > MAX_MINT_DISTANCE)
            revert TooLate();

        uint256 tokenId = minterToToken[tx.origin];

        // if you haven't minted yet, mint
        if (tokenId == 0) {
            uint256 currSupply = totalSupply;
            unchecked {
                _mint(tx.origin, ++currSupply);
                tokenToBlockNumber[currSupply] = uint128(block.number);

                minterToToken[tx.origin] = currSupply;
                totalSupply = currSupply;
            }
        } else {
            // update block num if you've already minted
            tokenToBlockNumber[tokenId] = uint128(block.number);
        }
    }

    function assertPOS() public {
        if (!mergeHasOccurred()) revert MergeHasNotOccurred();
        if (genesisMergeBlock == 0) genesisMergeBlock = block.number;
    }

    function mergeHasOccurred() public view returns (bool) {
        return block.difficulty > 2**64 || block.difficulty == 0;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert TokenDoesNotExist();

        if (genesisRenderer == address(0)) {
            return "";
        }

        return
            IGenesisRenderer(genesisRenderer).tokenURI(
                _tokenId,
                tokenToBlockNumber[_tokenId],
                genesisMergeBlock
            );
    }

    function setRenderer(address renderer) external onlyOwner {
        genesisRenderer = renderer;
    }
}