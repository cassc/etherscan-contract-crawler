// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./ITreasure.sol";
import "./lib/Roles.sol";
import "./lib/Revealable.sol";

contract ThreeLandShips is
    Ownable,
    ERC721,
    ERC721Enumerable,
    ReentrancyGuard,
    Roles,
    Revealable
{
    ITreasure public immutable treasure;
    mapping(Blueprint => uint256) public maxSupply;
    mapping(Blueprint => uint256) public totalSupply;
    mapping(Blueprint => string) public unrevealedURI;
    bool public claimEnabled;

    enum Blueprint { A, B, C, D, S }

    event BuildShip(Blueprint _blueprint, uint256 _amount, address _addr);

    modifier onlySufficient (
        Blueprint _blueprint, 
        address _addr, 
        uint256 _amount
    ) {
        require(_isSufficient(_blueprint, _addr, _amount), "Insufficient materials.");
        _;
    }

    constructor(
        address treasureAddress,
        string memory _tokenName,
        string memory _symbol,
        uint256[] memory _maxSupply,
        string[] memory _unrevealedURI,
        address _coordinator,
        address _linkToken,
        bytes32 _keyHash
    )
        ERC721(_tokenName, _symbol)
        Revealable(_coordinator, _linkToken, _keyHash)
    {
        require(
            _maxSupply.length == uint256(type(Blueprint).max) + 1,
            "Max supply numbers need to be defined for all tiers."
        );
        require(
            _unrevealedURI.length == uint256(type(Blueprint).max) + 1,
            "Unrevealed URLs need to be defined for all tiers."
        );
        treasure = ITreasure(treasureAddress);
        keyHash = _keyHash;
        for (uint256 i = 0; i <= uint256(type(Blueprint).max); i++) {
            Blueprint blueprint = _getBlueprint(i);
            maxSupply[blueprint] = _maxSupply[i];
            unrevealedURI[blueprint] = _unrevealedURI[i];
            totalSupply[blueprint] = 0;
        }
    }

    /**
     * @dev See _getFormula()
     */
    function getFormula(Blueprint _blueprint)
        external
        pure
        returns (uint256[] memory, uint256[] memory)
    {
        return _getFormula(_blueprint);
    }

    /**
     * @dev Retrieve URI for the token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        uint256 lowerBound = 0;
        uint256 upperBound = 0;
        Blueprint blueprint;
        for (uint256 i = 0; i <= uint256(type(Blueprint).max); i += 1) {
            blueprint = _getBlueprint(i);
            lowerBound = upperBound + 1;
            upperBound = lowerBound + maxSupply[blueprint] - 1;
            if (tokenId >= lowerBound && tokenId <= upperBound) {
                break;
            }
        }
        require(
            tokenId >= lowerBound && 
            tokenId < (lowerBound + totalSupply[blueprint]), 
            "Token not exist."
        );

        return isRevealed() 
            ? string(abi.encodePacked(
                revealedBaseURI,
                getShuffledId(
                    lowerBound,
                    upperBound,
                    totalSupply[blueprint],
                    tokenId
                ),
                ".json"
            ))
            : unrevealedURI[blueprint];
    }

    /**
     * @dev Set flag to enable/disable buildShip function.
     */
    function setClaimable(bool _claimEnabled) external onlyOwner {
        claimEnabled = _claimEnabled;
    }

    /**
     * @dev Retrieve supplied amount.
     */
    function getTotalSupply(Blueprint _blueprint)
        public
        view
        returns (uint256)
    {
        return totalSupply[_blueprint];
    }

    /**
     * @dev Retrieve max supply amount.
     */
    function getMaxSupply(Blueprint _blueprint) public view returns (uint256) {
        return maxSupply[_blueprint];
    }

    /**
     * @dev See _isSufficient()
     */
    function isSufficient(
        Blueprint _blueprint,
        address _addr,
        uint256 _amount
    ) external view returns (bool) {
        return _isSufficient(_blueprint, _addr, _amount);
    }

    /**
     * @dev See _getBound()
     */
    function getBound(Blueprint _blueprint)
        external
        view
        onlyOperator
        returns (uint256, uint256)
    {
        return _getBound(_blueprint);
    }

    /**
     * @dev Build ship using blueprint and its materils needed.
     */
    function buildShip(Blueprint _blueprint, uint256 _amount)
        external
        nonReentrant
        onlySufficient(_blueprint, msg.sender, _amount)
        returns (bool)
    {
        require(claimEnabled, "Claiming is disabled.");
        require(
            totalSupply[_blueprint] + _amount <= maxSupply[_blueprint],
            "Exceeding max supply."
        );

        // Burn materials and build ship
        (
            uint256[] memory _material,
            uint256[] memory _consumption
        ) = _getFormula(_blueprint);
        for (uint256 i = 0; i < _material.length; i++) {
            if (_consumption[i] > 0) {
                treasure.burnForAddress(
                    _material[i],
                    msg.sender,
                    _consumption[i] * _amount
                );
            }
        }

        // Mint ERC721 token to sender
        _mintToken(_blueprint, msg.sender, _amount);
        emit BuildShip(_blueprint, _amount, msg.sender);

        return true;
    }

    /**
     * @dev Get enum Blueprint by index.
     */
    function _getBlueprint(uint256 _index) internal pure returns (Blueprint) {
        require(
            _index >= uint256(type(Blueprint).min) &&
                _index <= uint256(type(Blueprint).max),
            "Index out of range"
        );

        if (_index == 0) {
            return Blueprint.A;
        }
        if (_index == 1) {
            return Blueprint.B;
        }
        if (_index == 2) {
            return Blueprint.C;
        }
        if (_index == 3) {
            return Blueprint.D;
        }
        if (_index == 4) {
            return Blueprint.S;
        }

        return Blueprint.S;
    }

    /**
     * @dev Retrieve materials needed details in the blueprint
     */
    function _getFormula(Blueprint _blueprint)
        internal
        pure
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory _material = new uint256[](6);
        uint256[] memory _consumption = new uint256[](6);

        if (_blueprint == Blueprint.D) {
            _material[0] = 6;
            _consumption[0] = 1;
            _material[1] = 11;
            _consumption[1] = 1;
            _material[2] = 12;
            _consumption[2] = 7;
        }
        if (_blueprint == Blueprint.C) {
            _material[0] = 5;
            _consumption[0] = 1;
            _material[1] = 10;
            _consumption[1] = 1;
            _material[2] = 11;
            _consumption[2] = 2;
            _material[3] = 12;
            _consumption[3] = 13;
        }
        if (_blueprint == Blueprint.B) {
            _material[0] = 4;
            _consumption[0] = 1;
            _material[1] = 9;
            _consumption[1] = 1;
            _material[2] = 10;
            _consumption[2] = 2;
            _material[3] = 11;
            _consumption[3] = 4;
            _material[4] = 12;
            _consumption[4] = 25;
        }
        if (_blueprint == Blueprint.A) {
            _material[0] = 3;
            _consumption[0] = 1;
            _material[1] = 8;
            _consumption[1] = 1;
            _material[2] = 9;
            _consumption[2] = 2;
            _material[3] = 10;
            _consumption[3] = 4;
            _material[4] = 11;
            _consumption[4] = 8;
            _material[5] = 12;
            _consumption[5] = 49;
        }
        if (_blueprint == Blueprint.S) {
            _material[0] = 2;
            _consumption[0] = 1;
            _material[1] = 8;
            _consumption[1] = 3;
            _material[2] = 9;
            _consumption[2] = 4;
            _material[3] = 10;
            _consumption[3] = 8;
            _material[4] = 11;
            _consumption[4] = 16;
            _material[5] = 12;
            _consumption[5] = 97;
        }

        return (_material, _consumption);
    }

    /**
     * @dev Check whether the materials are sufficient to build the ship according to the blueprint.
     */
    function _isSufficient(
        Blueprint _blueprint,
        address _addr,
        uint256 _amount
    ) internal view returns (bool) {
        // Retrieve material consumption
        (
            uint256[] memory _material,
            uint256[] memory _consumption
        ) = _getFormula(_blueprint);

        // Calculate material consumption
        for (uint256 i = 0; i < _material.length; i++) {
            if (treasure.balanceOf(_addr, _material[i]) < _consumption[i] * _amount) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Calculate tokenId range for each tiers
     */
    function _getBound(Blueprint _blueprint)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 lowerBound = 0;
        uint256 upperBound = 0;
        for (uint256 i = 0; i <= uint256(type(Blueprint).max); i++) {
            lowerBound = upperBound + 1;
            upperBound = lowerBound - 1 + maxSupply[_getBlueprint(i)];
            if (_blueprint == _getBlueprint(i)) {
                break;
            }
        }
        return (lowerBound, upperBound);
    }

    /**
     * @dev Mint ERC721 token to the address.
     */
    function _mintToken(
        Blueprint _blueprint,
        address _addr,
        uint256 _amount
    ) internal returns (bool) {
        for (uint256 i = 0; i < _amount; i++) {
            (uint256 lowerBound, ) = _getBound(_blueprint);
            uint256 tokenIndex = lowerBound + totalSupply[_blueprint];
            _safeMint(_addr, tokenIndex);
            totalSupply[_blueprint] += 1;
        }
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}