// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

import {ERC721} from "@solmate/tokens/ERC721.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/utils/cryptography/MerkleProof.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";

interface IGoldenPass {
    function burn(address from, uint256 amount) external;
}

interface IFoodzPartyLegacy {
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;
}

interface IOddworxStaking {
    function buyItem(
        uint256 itemSKU,
        uint256 amount,
        address nftContract,
        uint256[] calldata nftIds,
        address user
    ) external;
}

contract FoodzPartyV2 is ERC721, Ownable {
    using Strings for uint256;

    /// @dev 0xb36c1284
    error MaxSupply();
    /// @dev 0xa99edc71
    error MigrationOff();
    /// @dev 0xb9968551
    error PassSaleOff();
    /// @dev 0x3afc8ce9
    error SaleOff();
    /// @dev 0xb52aa4c0
    error QueryForNonExistentToken();
    /// @dev 0xe6c4247b
    error InvalidAddress();
    /// @dev 0x2c5211c6
    error InvalidAmount();
    /// @dev 0xab143c06
    error Reentrancy();

    // Immutable

    uint256 internal constant MIGRATION_START_INDEX = 0;
    uint256 internal constant MIGRATION_END_INDEX = 1160;
    uint256 internal constant MIGRATION_EXTRAS_START_INDEX = 1161;
    uint256 internal constant MIGRATION_EXTRAS_END_INDEX = 2321;
    uint256 internal constant REGULAR_START_INDEX = 2322;
    uint256 internal constant REGULAR_END_INDEX = 2975;
    uint256 internal constant GOLDEN_PASS_START_INDEX = 2976;
    uint256 internal constant GOLDEN_PASS_END_INDEX = 3475;
    uint256 internal constant HANDMADE_START_INDEX = 3476;
    uint256 internal constant HANDMADE_END_INDEX = 3499;

    /// @notice address of the oddx staking contract
    IOddworxStaking internal immutable staking;
    /// @notice address of the golden pass contract
    IGoldenPass internal immutable goldenPass;
    /// @notice address of the legacy foodz party contract
    IFoodzPartyLegacy internal immutable foodzLegacy;
    /// @notice address of the genzee contract
    address internal immutable genzee;

    // Mutable

    /// @notice amount of regular mints
    /// @dev starts at 1 cuz constructor mints #0
    uint256 public migrationSupply = 1;
    uint256 public migrationExtrasSupply;
    uint256 public regularSupply;
    uint256 public goldenPassSupply;
    uint256 public handmadeSupply;
    string public baseURI;
    uint256 public mintPriceOddx = 200 ether;
    /// @notice if users can migrate their tokens from the legacy contract
    /// @dev 1 = not active; 2 = active;
    uint256 private _isMigrationActive = 1;
    /// @notice if users can redeem their golden passes
    /// @dev 1 = not active; 2 = active;
    uint256 private _isPassSaleActive = 1;
    /// @notice if users can redeem their golden passes
    /// @dev 1 = not active; 2 = active;
    uint256 private _isSaleActive = 1;

    /// @dev reentrancy lock
    uint256 private _locked = 1;

    // Constructor

    constructor(
        IOddworxStaking staking_,
        IGoldenPass goldenPass_,
        IFoodzPartyLegacy foodzLegacy_,
        address genzee_,
        string memory baseURI_
    ) ERC721("Foodz Party", "FP") {
        staking = staking_;
        goldenPass = goldenPass_;
        foodzLegacy = foodzLegacy_;
        genzee = genzee_;
        baseURI = baseURI_;
        _safeMint(0x067423C244442ca0Eb6d6fd6B747c2BD21414107, 0);
    }

    // Owner Only

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setIsPassSaleActive(bool newIsPassSaleActive) external onlyOwner {
        _isPassSaleActive = newIsPassSaleActive ? 2 : 1;
    }

    function setIsSaleActive(bool newIsSaleActive) external onlyOwner {
        _isSaleActive = newIsSaleActive ? 2 : 1;
    }

    function setIsMigrationActive(bool newIsMigrationActive)
        external
        onlyOwner
    {
        _isMigrationActive = newIsMigrationActive ? 2 : 1;
    }

    function setMintPriceOddx(uint256 newMintPriceOddx) external onlyOwner {
        mintPriceOddx = newMintPriceOddx;
    }

    function handmadeMint(address to) external onlyOwner {
        unchecked {
            uint256 tokenId = HANDMADE_START_INDEX + handmadeSupply;
            if (tokenId > HANDMADE_END_INDEX) revert MaxSupply();
            // slither-disable-next-line events-maths
            ++handmadeSupply;
            _safeMint(to, tokenId);
        }
    }

    // User

    /// @notice Migrate a token from legacy Foodz contract to this contract.
    ///         It "burns" the token on the other contract so it requires the tokens to be approved first.
    function migrate(uint256[] calldata ids) external {
        if (_isMigrationActive != 2) revert MigrationOff();
        if (msg.sender == address(0)) revert InvalidAddress();
        if (_locked == 2) revert Reentrancy();
        _locked = 2;

        uint256 length = ids.length;
        uint256 i = 0;

        unchecked {
            migrationSupply += length;
        }

        for (i = 0; i < length; ) {
            foodzLegacy.transferFrom(
                msg.sender,
                address(0x000000000000000000000000000000000000dEaD),
                ids[i]
            );
            unchecked {
                ++i;
            }
        }

        unchecked {
            uint256 extraMingStartIndex = MIGRATION_EXTRAS_START_INDEX +
                migrationExtrasSupply;
            migrationExtrasSupply += length;
            for (i = 0; i < length; i++) {
                _safeMint(msg.sender, ids[i]);
                _safeMint(msg.sender, extraMingStartIndex + i);
            }
        }

        _locked = 1;
    }

    function mint(uint256 amount, uint256[] calldata nftIds) external {
        if (amount == 0) revert InvalidAmount();
        if (_isSaleActive != 2) revert SaleOff();
        uint256 startIndex;
        unchecked {
            startIndex = REGULAR_START_INDEX + regularSupply;
            if (startIndex + amount - 1 > REGULAR_END_INDEX) revert MaxSupply();
        }

        staking.buyItem(
            0x0105,
            amount * mintPriceOddx,
            genzee,
            nftIds,
            msg.sender
        );

        unchecked {
            // slither-disable-next-line events-maths
            regularSupply += amount;
            for (uint256 i = 0; i < amount; i++) {
                _safeMint(msg.sender, startIndex + i);
            }
        }
    }

    function passmint(uint256 amount) external {
        if (_isPassSaleActive != 2) revert PassSaleOff();
        uint256 startIndex;
        unchecked {
            startIndex = GOLDEN_PASS_START_INDEX + goldenPassSupply;
            if (startIndex + amount - 1 > GOLDEN_PASS_END_INDEX)
                revert MaxSupply();
        }

        goldenPass.burn(msg.sender, amount);

        unchecked {
            // slither-disable-next-line events-maths
            goldenPassSupply += amount;
            for (uint256 i = 0; i < amount; i++) {
                _safeMint(msg.sender, startIndex + i);
            }
        }
    }

    // View

    function currentSupply() external view returns (uint256) {
        unchecked {
            return
                migrationSupply +
                migrationExtrasSupply +
                regularSupply +
                goldenPassSupply +
                handmadeSupply;
        }
    }

    function isMigrationActive() external view returns (bool) {
        return _isMigrationActive == 2 ? true : false;
    }

    function isPassSaleActive() external view returns (bool) {
        return _isPassSaleActive == 2 ? true : false;
    }

    function isSaleActive() external view returns (bool) {
        return _isSaleActive == 2 ? true : false;
    }

    // Overrides

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (_ownerOf[id] == address(0)) revert QueryForNonExistentToken();
        return string(abi.encodePacked(baseURI, id.toString()));
    }
}