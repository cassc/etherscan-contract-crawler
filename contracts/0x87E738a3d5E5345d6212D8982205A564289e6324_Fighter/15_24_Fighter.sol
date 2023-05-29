// SPDX-License-Identifier: MIT

/// @title RaidParty Fighter ERC721 Contract

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../interfaces/IFighter.sol";
import "../interfaces/IFighterURIHandler.sol";
import "../interfaces/ISeeder.sol";
import "../randomness/Seedable.sol";
import "../utils/ERC721Enumerable.sol";
import "../utils/ERC721.sol";

contract Fighter is
    IFighter,
    Seedable,
    ERC721,
    ERC721Enumerable,
    AccessControlEnumerable
{
    // Contract state and constants
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _tokenIdCounter = 1;
    uint256 private _burnCounter;

    IFighterURIHandler private _handler;

    constructor(address admin) ERC721("Fighter", "FIGHTER") {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
    }

    /** PUBLIC */

    function mint(address to, uint256 count) external onlyRole(MINTER_ROLE) {
        unchecked {
            uint256 tokenIdCounter = _tokenIdCounter;
            _tokenIdCounter += count;
            ISeeder seeder = ISeeder(_handler.getSeeder());
            for (uint256 i = 0; i < count; i++) {
                seeder.requestSeed(tokenIdCounter + i);
                _mint(to, tokenIdCounter + i);
            }
        }
    }

    function mintBatch(address[] calldata to, uint256[] calldata counts)
        external
        onlyRole(MINTER_ROLE)
    {
        unchecked {
            require(
                to.length == counts.length,
                "Fighter::mintBatch: Parameter length mismatch"
            );
            uint256 tokenIdCounter;
            ISeeder seeder = ISeeder(_handler.getSeeder());

            for (uint256 i = 0; i < to.length; i++) {
                tokenIdCounter = _tokenIdCounter;
                _tokenIdCounter += counts[i];
                for (uint256 j = 0; j < counts[i]; j++) {
                    seeder.requestSeed(tokenIdCounter + j);
                    _mint(to[i], tokenIdCounter + j);
                }
            }
        }
    }

    function setHandler(IFighterURIHandler handler)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _handler = handler;
        emit HandlerUpdated(msg.sender, address(handler));
    }

    function getHandler() external view override returns (address) {
        return address(_handler);
    }

    function getSeeder() external view override returns (address) {
        return _handler.getSeeder();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721, ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public override {
        unchecked {
            _burnCounter += 1;
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721Burnable: caller is not owner nor approved"
            );
            _burn(tokenId);
        }
    }

    function burnBatch(uint256[] calldata tokenIds) external {
        unchecked {
            _burnCounter += tokenIds.length;
            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(
                    _isApprovedOrOwner(_msgSender(), tokenIds[i]),
                    "Fighter::burnBatch: caller is not owner nor approved"
                );
                _burn(tokenIds[i]);
            }
        }
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        unchecked {
            return _tokenIdCounter - _burnCounter - 1;
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        unchecked {
            require(
                index < totalSupply(),
                "Fighter::tokenByIndex: global index out of bounds"
            );
            uint256 indexCounter = 0;

            for (uint256 i = 1; i <= _tokenIdCounter; i++) {
                if (_exists(i)) {
                    if (indexCounter == index) {
                        return i;
                    }
                    indexCounter += 1;
                }
            }

            revert("Fighter::tokenByIndex: unable to get token by index");
        }
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        unchecked {
            require(
                index < balanceOf(owner),
                "Fighter::tokenOfOwnerByIndex: owner index out of bounds"
            );
            address comparedOwner;
            uint256 iterations;

            for (uint256 i = 1; i <= _tokenIdCounter; i++) {
                comparedOwner = _getOwner(i);
                if (comparedOwner == owner) {
                    if (iterations == index) {
                        return i;
                    }

                    iterations += 1;
                }
            }

            revert(
                "Fighter::tokenOfOwnerByIndex: unable to get token of owner by index"
            );
        }
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 balance = balanceOf(owner);
            uint256[] memory tokens = new uint256[](balance);
            uint256 idx;

            for (uint256 i = 1; i <= _tokenIdCounter; i++) {
                if (_getOwner(i) == owner) {
                    tokens[idx] = i;
                    idx += 1;

                    if (idx == balance) {
                        return tokens;
                    }
                }
            }

            revert(
                "Fighter::tokenOfOwnerByIndex: unable to get tokens of owner"
            );
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Fighter::tokenURI: URI query for nonexistent token"
        );

        return _handler.tokenURI(tokenId);
    }

    /** INTERNAL */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}