// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract InfiniteERC721 is ERC721 {
    uint256 internal _numTokens;
    uint256 internal constant _mintPrice = 0.001 ether;

    constructor() ERC721("InfiniteERC721", "IERC") {
        _numTokens = 0;
    }

    function getMintPrice() public pure returns(uint256) {
        return _mintPrice;
    }

    function mint(address toAddress, uint8 numToMint) public {
        for (uint8 i = 0; i < numToMint; i++) {
            _numTokens++;
            _safeMint(toAddress, _numTokens - 1);
        }
    }

    function safeMint(address toAddress, uint8 numToMint) public {
        mint(toAddress, numToMint);
    }

    function unsafeMint(address toAddress, uint8 numToMint) public {
        for (uint8 i = 0; i < numToMint; i++) {
            _numTokens++;
            _mint(toAddress, _numTokens - 1);
        }
    }

    function paidMint(address toAddress, uint8 numToMint) payable public {
        require(msg.value == _mintPrice * numToMint, 'invalid mint price');
        mint(toAddress, numToMint);
    }

    function safePaidMint(address toAddress, uint8 numToMint) payable public {
        require(msg.value == _mintPrice * numToMint, 'invalid mint price');
        safeMint(toAddress, numToMint);
    }

    function unsafePaidMint(address toAddress, uint8 numToMint) payable public {
        require(msg.value == _mintPrice * numToMint, 'invalid mint price');
        unsafeMint(toAddress, numToMint);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        validTokenId(tokenId)
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes('{"name": "Supercool Infinite Minter", "description": "A demo of the Supercool Checkout. Buy with credit card or crypto. Bring your own wallet, or we can make a secure non-custodial wallet for you!", "seller_fee_basis_points": 0, "fee_recipient": "0x3af8bd79c26cf9e2b84a56215eb27013b2b00015", "image": "ipfs://bafkreiah44jcifjqscek4fquladxkjoujne2zkhjs7ekootfaiulmmztma"}')
                )
            )
        );
    }

    modifier validTokenId(uint256 tokenId) {
        require(_exists(tokenId), "tokenId does not exist");
        _;
    }
}