// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/Ownable.sol";
import "./libraries/Strings.sol";
import "./libraries/ERC721.sol";
import "./libraries/IERC2981.sol";

interface IZzoopersRandomizer {
    function getMetadataId(uint256 batchNo, uint256 zzoopersEVOTokenId)
        external
        returns (uint256);
}

/**
 * @title Zzoopers contract
 */
contract Zzoopers is ERC721, IERC2981, Ownable {
    using Strings for *;

    address private _zzoopersEVOAddress;
    IZzoopersRandomizer private _randomizer;

    mapping(uint256 => string) private _baseURIs; //batchNo => baseURI
    string private _contractURI;

    uint256 constant LIMIT_AMOUNT = 2929;

    bool public _contractLocked = false;

    address private _mintFeeReceiver;
    address private _royaltyReceiver;
    uint256 private _royaltyRate = 75; //7.5%

    event ZzoopersRevealed(
        address indexed owner,
        uint256 tokenId,
        uint256 zzoopersEVOTokenId
    );

    constructor(
        address zzoopersEVOAddress,
        address randomizerAddress,
        string memory contractUri
    ) ERC721("Zzoopers", "Zzoopers") Ownable() {
        _zzoopersEVOAddress = zzoopersEVOAddress;
        _randomizer = IZzoopersRandomizer(randomizerAddress);
        _contractURI = contractUri;
    }

    function setZzoopersEVOAddress(address newZzoopersEVOAddress)
        public
        onlyOwner
    {
        require(!_contractLocked, "Zzoopers: Contract has been locked");
        _zzoopersEVOAddress = newZzoopersEVOAddress;
    }

    function setRandomizer(address randomizer) public onlyOwner {
        _randomizer = IZzoopersRandomizer(randomizer);
    }

    function mint(
        uint256 batchNo,
        uint256 zzoopersEVOTokenId,
        address to
    ) external returns (uint256 tokenId) {
        require(
            msg.sender == _zzoopersEVOAddress,
            "Zzoopers: Caller not authorized"
        );
        require(
            zzoopersEVOTokenId <= LIMIT_AMOUNT,
            "ZzoopersRandomizer: TokenId cannot larger than max size"
        );

        tokenId = _randomizer.getMetadataId(batchNo, zzoopersEVOTokenId);
        require(
            tokenId < LIMIT_AMOUNT,
            "ZzoopersRandomizer: tokenId cannot larger than max size"
        );
        _safeMint(to, tokenId);

        emit ZzoopersRevealed(msg.sender, tokenId, zzoopersEVOTokenId);
        return tokenId;
    }

    function totalSupply() public pure returns (uint256) {
        return LIMIT_AMOUNT;
    }

    function setBaseURI(uint256 batchNo, string calldata baseURI)
        public
        onlyOwner
    {
        require(
            batchNo >= 1 && batchNo <= 4,
            "Zzoopers: BatchNo must between: 1 and 4"
        );
        require(!_contractLocked, "Zzoopers: Contract has been locked");
        _baseURIs[batchNo] = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Zzoopers: TokenId not exists");

        uint256 batchNo;
        if (tokenId <= 585) {
            batchNo = 1;
        } else if (tokenId <= 1171) {
            batchNo = 2;
        } else if (tokenId <= 2050) {
            batchNo = 3;
        } else if (tokenId <= 2928) {
            batchNo = 4;
        } else {
            return "";
        }

        return
            string(
                abi.encodePacked(_baseURIs[batchNo], Strings.toString(tokenId))
            );
    }

    function setContractURI(string calldata contractUri) public onlyOwner {
        require(!_contractLocked, "Zzoopers: Contract has been locked");
        _contractURI = contractUri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function lockContract() public onlyOwner {
        _contractLocked = true;
    }

    function setMintFeeReceiver(address newMintFeeReceiver) public onlyOwner {
        _mintFeeReceiver = newMintFeeReceiver;
    }

    function setRoyaltyReceiver(address newRoyaltyReceiver) public onlyOwner {
        _royaltyReceiver = newRoyaltyReceiver;
    }

    function getMintFeeReceiver() public view returns (address) {
        if (_mintFeeReceiver == address(0)) {
            return this.owner();
        }
        return _mintFeeReceiver;
    }

    function getRoyaltyReceiver() public view returns (address) {
        if (_royaltyReceiver == address(0)) {
            return this.owner();
        }
        return _royaltyReceiver;
    }

    function setRoyaltyRate(uint256 newRoyaltyRate) public onlyOwner {
        require(
            newRoyaltyRate >= 0 && newRoyaltyRate <= 1000,
            "Zzoopers: newRoyaltyRate should between [0, 1000]"
        );
        _royaltyRate = newRoyaltyRate;
    }

    function getRoyaltyRate() public view returns (uint256) {
        return _royaltyRate;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = getRoyaltyReceiver();
        royaltyAmount = (salePrice * _royaltyRate) / 1000;
        return (receiver, royaltyAmount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}