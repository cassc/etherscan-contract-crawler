// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/access/Ownable.sol";

import "./IConclusionRenderer.sol";

/// @title An attempt to be the last on-chain NFT minted on POW ETH
/// @author @0x_beans
/// @author @high_byte
contract Conclusion is ERC721, Ownable {
    error AlreadyMinted();
    error TokenDoesNotExist();
    error MergeHasOccurred();

    struct MintInfo {
        uint128 blockNumber;
        uint128 blockDifficulty;
    }

    uint256 public lastWorkBlock;
    uint256 public totalSupply;

    // token renderer
    address public conclusionRenderer;

    mapping(address => uint256) public minterToToken;
    mapping(uint256 => MintInfo) public tokenToBlockNumber;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "only EOA");
        _;
    }

    constructor() ERC721("Sunset", "SUNSET") {}

    // can only start minting before the merge has occurred
    // can only mint 1 token, if you submit multiple mint txns,
    // you'll update your token values
    function mint() external onlyEOA {
        // assert we're still POW
        assertPOW();

        uint256 tokenId = minterToToken[tx.origin];

        // mint if wallet hasn't minted already
        if (tokenId == 0) {
            uint256 currSupply = totalSupply;
            unchecked {
                _mint(tx.origin, ++currSupply);
                tokenToBlockNumber[currSupply] = MintInfo(
                    uint128(block.number),
                    uint128(block.difficulty)
                );

                minterToToken[tx.origin] = currSupply;
                totalSupply = currSupply;
            }
        } else {
            // update token values if wallet has already minted
            tokenToBlockNumber[tokenId] = MintInfo(
                uint128(block.number),
                uint128(block.difficulty)
            );
        }
    }

    function assertPOW() public {
        if (mergeHasOccurred()) {
            revert MergeHasOccurred();
        }

        lastWorkBlock = block.number;
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

        if (conclusionRenderer == address(0)) {
            return "";
        }

        MintInfo memory info = tokenToBlockNumber[_tokenId];

        return
            IConclusionRenderer(conclusionRenderer).tokenURI(
                _tokenId,
                info.blockNumber,
                info.blockDifficulty
            );
    }

    function setRenderer(address renderer) external onlyOwner {
        conclusionRenderer = renderer;
    }
}