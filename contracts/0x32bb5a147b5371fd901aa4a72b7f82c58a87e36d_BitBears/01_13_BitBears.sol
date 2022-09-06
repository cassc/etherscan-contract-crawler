pragma solidity 0.8.16;

import {ERC721, ERC721Enumerable} from "@oz/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@oz/access/Ownable.sol";

/// @notice ERC721 that allows owners of other ERC721's to claim a new token
/// @dev We utilize Openzepplin ERC721Enumerable to allow automating the claim process by being
/// able to iterate through an owners set of bears. Sucks that the openzeppelin ones are kinda
/// bad on gas but it eeezzz what it ezzzzzz. This code has not been overly optimized just kinda naively
/// works, no special tricks or anything, definitely room to improve if you want to giga optimize.
/// If someone wants to contribute to a library to modularize this legacy code, definitely ping me
/// itsdevbear, could do some funky stuff with CREATE2 and a router for sure! But for now we deploy
/// contracts manually like this, one day we will move all the bears over to a nice reference rebasing
/// implementation but sadly today is not the day!
contract BitBears is ERC721Enumerable, Ownable {
    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    string public baseURI;
    uint256 public immutable MINT_PRICE = 0.33e18;
    uint256 public immutable MAX_SUPPLY = 2355;
    uint256 public immutable NUM_BONG_BEARS = 100;
    uint256 public immutable NUM_BOND_BEARS = 126;
    uint256 public immutable NUM_BOO_BEARS = 271;
    uint256 public immutable NUM_BABY_BEARS = 571;
    uint256 public immutable NUM_BAND_BEARS = 1175;

    uint256 public airdropTokenIDs = 1;
    uint256 public claimOpen = 0;
    uint256 public mintOpen = 0;
    uint256 public fairSaleTokenID;

    /* Mapping to check if a particular bear has had it's rebase claimed */
    mapping(bytes32 => bool) public hasClaimedRebase;

    address BOND_BEARS = 0xF17Bb82b6e9cC0075ae308e406e5198BA7320545;
    address BOO_BEARS = 0x2c889A24AF0d0eC6337DB8fEB589fa6368491146;
    address BABY_BEARS = 0x9E629D779bE89783263D4c4A765c38Eb3f18671C;
    address BAND_BEARS = 0xB4E570232D3E55D2ee850047639DC74DA83C7067;

    constructor() ERC721("Bit Bears", "BITB") Ownable() {
        /* Start the fairsale from above the rebase tokens */
        fairSaleTokenID = (NUM_BONG_BEARS + NUM_BOND_BEARS + NUM_BOO_BEARS + NUM_BABY_BEARS + NUM_BAND_BEARS) + 1;
    }

    function mint() external payable {
        require(mintOpen > 0, "BitBears: Minting not enabled");
        require(msg.value >= MINT_PRICE, "BitBears: Not Enough ETH");
        require(fairSaleTokenID <= MAX_SUPPLY, "BitBears: Sold Out");
        unchecked {
            _mint(msg.sender, fairSaleTokenID++);
        }
    }

    function claim() external {
        bytes32 _hash;
        uint256 tokenID;
        uint256 bondOwned;
        uint256 booOwned;
        uint256 babyOwned;
        uint256 bandOwned;
        uint256 sum;

        require(claimOpen > 0, "BitBears: Claiming not enabled");
        unchecked {
            bondOwned = ERC721(BOND_BEARS).balanceOf(msg.sender);
            for (uint256 j = 0; j < bondOwned; j += 1) {
                tokenID = ERC721Enumerable(BOND_BEARS).tokenOfOwnerByIndex(msg.sender, j);
                _hash = keccak256(abi.encodePacked(BOND_BEARS, tokenID));
                if (!hasClaimedRebase[_hash]) {
                    hasClaimedRebase[_hash] = true;
                    _mint(msg.sender, tokenID + NUM_BONG_BEARS);
                    ++sum;
                }
            }

            booOwned = ERC721(BOO_BEARS).balanceOf(msg.sender);
            for (uint256 j = 0; j < booOwned; j += 1) {
                tokenID = ERC721Enumerable(BOO_BEARS).tokenOfOwnerByIndex(msg.sender, j);
                _hash = keccak256(abi.encodePacked(BOO_BEARS, tokenID));
                if (!hasClaimedRebase[_hash]) {
                    hasClaimedRebase[_hash] = true;
                    _mint(msg.sender, tokenID + NUM_BONG_BEARS + NUM_BOND_BEARS);
                    ++sum;
                }
            }

            babyOwned = ERC721(BABY_BEARS).balanceOf(msg.sender);
            for (uint256 j = 0; j < babyOwned; j += 1) {
                tokenID = ERC721Enumerable(BABY_BEARS).tokenOfOwnerByIndex(msg.sender, j);
                _hash = keccak256(abi.encodePacked(BABY_BEARS, tokenID));
                if (!hasClaimedRebase[_hash]) {
                    hasClaimedRebase[_hash] = true;
                    _mint(msg.sender, tokenID + NUM_BONG_BEARS + NUM_BOND_BEARS + NUM_BOO_BEARS);
                    ++sum;
                }
            }

            bandOwned = ERC721(BAND_BEARS).balanceOf(msg.sender);
            for (uint256 j = 0; j < bandOwned; j += 1) {
                tokenID = ERC721Enumerable(BAND_BEARS).tokenOfOwnerByIndex(msg.sender, j);
                _hash = keccak256(abi.encodePacked(BAND_BEARS, tokenID));
                if (!hasClaimedRebase[_hash]) {
                    hasClaimedRebase[_hash] = true;
                    _mint(msg.sender, tokenID + NUM_BONG_BEARS + NUM_BOND_BEARS + NUM_BOO_BEARS + NUM_BABY_BEARS);
                    ++sum;
                }
            }

            require(bondOwned + booOwned + babyOwned + bandOwned != 0 && sum > 0, "BitBears: None to claim");
        }
    }

    function eligibleForClaim(address user) external view returns (uint256 sum) {
        uint256 tokenID;
        bytes32 _hash;
        unchecked {
            uint256 bondOwned = ERC721(BOND_BEARS).balanceOf(user);
            for (uint256 j = 0; j < bondOwned; j += 1) {
                tokenID = ERC721Enumerable(BOND_BEARS).tokenOfOwnerByIndex(user, j);
                _hash = keccak256(abi.encodePacked(BOND_BEARS, tokenID));
                if (!hasClaimedRebase[_hash]) {
                    ++sum;
                }
            }

            uint256 booOwned = ERC721(BOO_BEARS).balanceOf(user);
            for (uint256 j = 0; j < booOwned; j += 1) {
                tokenID = ERC721Enumerable(BOO_BEARS).tokenOfOwnerByIndex(user, j);
                _hash = keccak256(abi.encodePacked(BOO_BEARS, tokenID));
                if (!hasClaimedRebase[_hash]) {
                    ++sum;
                }
            }

            uint256 babyOwned = ERC721(BABY_BEARS).balanceOf(user);
            for (uint256 j = 0; j < babyOwned; j += 1) {
                tokenID = ERC721Enumerable(BABY_BEARS).tokenOfOwnerByIndex(user, j);
                _hash = keccak256(abi.encodePacked(BABY_BEARS, tokenID));
                if (!hasClaimedRebase[_hash]) {
                    ++sum;
                }
            }

            uint256 bandOwned = ERC721(BAND_BEARS).balanceOf(user);
            for (uint256 j = 0; j < bandOwned; j += 1) {
                tokenID = ERC721Enumerable(BAND_BEARS).tokenOfOwnerByIndex(user, j);
                _hash = keccak256(abi.encodePacked(BAND_BEARS, tokenID));
                if (!hasClaimedRebase[_hash]) {
                    ++sum;
                }
            }
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function airdrop(address[] memory addrs) external onlyOwner {
        unchecked {
            uint256 length = addrs.length;

            for (uint256 i = 0; i < length; ++i) {
                _mint(addrs[i], airdropTokenIDs++);
            }
            require(airdropTokenIDs <= NUM_BONG_BEARS + 1, "BitBears: Airdrop too large");
        }
    }

    function withdrawAll() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setClaim(uint256 value) external onlyOwner {
        claimOpen = value;
    }

    function setMint(uint256 value) external onlyOwner {
        mintOpen = value;
    }
}