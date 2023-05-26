/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

import {ERC721} from "ERC721.sol";
import {ERC721Enumerable} from "ERC721Enumerable.sol";
import {Trust} from "Trust.sol";

contract BabyBears is ERC721Enumerable, Trust {
    uint256 immutable MINT_PRICE = 0.42069e18;
    uint256 immutable MAX_SUPPLY = 571;
    uint256 immutable NUM_BONG_BEARS = 101;
    uint256 immutable NUM_BOND_BEARS = 126;
    uint256 immutable NUM_BOO_BEARS = 271;

    uint256 airdropTokenIDs = 1;
    uint256 claimOpen = 0;
    uint256 mintOpen = 0;
    uint256 fairSaleTokenID; // defined in constructor

    string baseURI;
    address BOND_BEARS = 0xF17Bb82b6e9cC0075ae308e406e5198BA7320545;
    address BOO_BEARS = 0x2c889A24AF0d0eC6337DB8fEB589fa6368491146;
    mapping(bytes32 => bool) hasConsumedRebase;

    constructor(string memory baseURI_, address bondBears, address booBears) ERC721("Baby Bears", "BABYB") Trust(msg.sender) {
        BOND_BEARS = bondBears;
        BOO_BEARS = booBears;
        setBaseURI(baseURI_);
        fairSaleTokenID = NUM_BONG_BEARS + NUM_BOND_BEARS + NUM_BOO_BEARS + 1;
    }

    function mint() external payable {
        require(mintOpen > 0, "BabyBears: Minting not enabled");
        require(msg.value >= MINT_PRICE, "BabyBears: NOT_ENOUGH_ETH");
        require(
            fairSaleTokenID <= MAX_SUPPLY,
            "BabyBears: MAX_SUPPLY_EXCEEDED"
        );
        _mint(msg.sender, fairSaleTokenID++); 
    }

    function claim() external {
        require(claimOpen > 0, "BabyBears: Claiming not enabled");
        uint256 numOwned = ERC721(BOND_BEARS).balanceOf(msg.sender);
        for (uint256 j = 0; j < numOwned; j += 1) {
            uint256 tokenID = ERC721Enumerable(BOND_BEARS)
                .tokenOfOwnerByIndex(msg.sender, j);
            bytes32 _hash = keccak256(abi.encodePacked(BOND_BEARS, tokenID));
            if(!hasConsumedRebase[_hash]) {
                hasConsumedRebase[_hash] = true;
                _mint(msg.sender, tokenID + NUM_BONG_BEARS);
            }
        }

        numOwned = ERC721(BOO_BEARS).balanceOf(msg.sender);
        for (uint256 j = 0; j < numOwned; j += 1) {
            uint256 tokenID = ERC721Enumerable(BOO_BEARS)
                .tokenOfOwnerByIndex(msg.sender, j);
            bytes32 _hash = keccak256(abi.encodePacked(BOO_BEARS, tokenID));
            if(!hasConsumedRebase[_hash]) {
                hasConsumedRebase[_hash] = true;
                _mint(msg.sender, tokenID + NUM_BONG_BEARS + NUM_BOND_BEARS);
            }
        }
    }

    function eligibleForClaim(address user) external view returns (uint256) {
        uint256 numOwned = ERC721(BOND_BEARS).balanceOf(user);
        uint256 sum;
        for (uint256 j = 0; j < numOwned; j += 1) {
            uint256 tokenID = ERC721Enumerable(BOND_BEARS)
                .tokenOfOwnerByIndex(user, j);
            bytes32 _hash = keccak256(abi.encodePacked(BOND_BEARS, tokenID));
            if(!hasConsumedRebase[_hash]) {
                sum += 1;
            }
        }
        numOwned = ERC721(BOO_BEARS).balanceOf(user);
        for (uint256 j = 0; j < numOwned; j += 1) {
            uint256 tokenID = ERC721Enumerable(BOO_BEARS)
                .tokenOfOwnerByIndex(user, j);
            bytes32 _hash = keccak256(abi.encodePacked(BOO_BEARS, tokenID));
            if(!hasConsumedRebase[_hash]) {
                sum += 1;
            }
        }
        return sum;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function setBaseURI(string memory newBaseURI) public requiresTrust {
        baseURI = newBaseURI;
    }

    function airdrop(address[] calldata addrs) external requiresTrust {
        for (uint16 i = 0; i < addrs.length; i += 1) {
            _mint(addrs[i], airdropTokenIDs++);
        }
    }

    function withdrawAll() public requiresTrust {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setClaim(uint256 value) external requiresTrust {
        claimOpen = value;
    }

    function setMint(uint256 value) external requiresTrust {
        mintOpen = value;
    }
}