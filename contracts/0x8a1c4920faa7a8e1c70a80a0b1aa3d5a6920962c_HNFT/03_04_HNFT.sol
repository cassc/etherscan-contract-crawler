// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "./MintableToken.sol";

contract HNFT is ERC721, ERC721TokenReceiver {
    string public baseURI;
    MintableToken public immutable token;
    ERC721 public immutable underlyingNFT;

    constructor(
        string memory nameNFT,
        string memory symbolNFT,
        string memory _baseURI,
        string memory nameToken,
        string memory symbolToken,
        address _underlyingNFT
    ) ERC721(nameNFT, symbolNFT) {
        baseURI = _baseURI;
        token = new MintableToken(nameToken, symbolToken, 18);
        underlyingNFT = ERC721(_underlyingNFT);
    }

    function mint(address from, address to, uint256[] calldata tokenIds) external {
        require(from == msg.sender || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            underlyingNFT.transferFrom(from, address(this), tokenIds[i]);
            _mint(to, tokenIds[i]);
        }
        // Cannot overflow as that would require giant amounts of NFTS to be transfered
        unchecked {
            token.mint(to, 1e18 * tokenIds.length);
        }
    }

    function onERC721Received(
        address, //operator
        address from,
        uint256 tokenId,
        bytes calldata data
    ) override external returns (bytes4)  {
        require(msg.sender == address(underlyingNFT), "NOT_AUTHORIZED");

        address to = abi.decode(data, (address));
        if(to == address(0)) {
            to = from;
        }

        _mint(to, tokenId);
        token.mint(to, 1e18);

        return ERC721TokenReceiver.onERC721Received.selector;
    }

    function burn(address from, address to, uint256[] calldata tokenIds) external {
        require(from == msg.sender || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Transfer underlying back to sender
            underlyingNFT.transferFrom(address(this), to, tokenIds[i]);
            // Burn HNFT
            // Check ownership
            require(ownerOf(tokenIds[i]) == from, "NOT_OWNER");
            _burn(tokenIds[i]);
        }
        
        // Cannot underflow as that would require giant amounts of NFTS to be transfered
        unchecked {
            token.burn(from, 1e18 * tokenIds.length);
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId));
    }
}