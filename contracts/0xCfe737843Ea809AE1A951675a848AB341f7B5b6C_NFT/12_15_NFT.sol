// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./utils/EIP712.sol";
import "../interfaces/IAccessManager.sol";
import "../interfaces/IDisplateManager.sol";

contract NFT is ERC721, EIP712, Ownable {
    uint32 public totalAmountOfEdition;
    uint32 public timeStart;
    uint32 public timeEnd;
    uint32 public nftId;
    uint32 public dropId;
    uint32 public artistRoyaltiesPercentage;
    uint32 public initialRoyaltySalePercentage;
    bool private initialized;
    address public artistAddress;
    string private constant delegatedOperationName = "Delegated Operation";
    string private constant version = "1";
    string _name;
    string _symbol;
    mapping(bytes32 => bool) private saltUsed;
    mapping(uint32 => bool) public isTokenBurned;

    bytes32 immutable TRANSFER_TYPEHASH =
        keccak256(
            "Transfer(address addressTo,uint32 tokenId,uint32 expirationTime,bytes32 salt)"
        );

    bytes32 immutable BURN_TYPEHASH =
        keccak256("Burn(uint32 tokenId,uint32 expirationTime,bytes32 salt)");

    IAccessManager accessManager;
    IDisplateManager displateManager;

    event TokenBurned(
        address _user,
        string _tokenName,
        string _tokenSymbol,
        uint32 _tokenID
    );
    event TokenAwarded(
        address _user,
        string _tokenName,
        string _tokenSymbol,
        uint32 _tokenID,
        string _tokenURI
    );

    constructor()
        ERC721(_name, _symbol)
        EIP712(delegatedOperationName, version)
    {}

    function init(
        address _accessManangerAddress,
        bytes memory _staticData,
        bytes memory _dynamicData
    ) external {
        require(!initialized, "Already initialized");
        initialized = true;

        /**
         * @notice Displate collection owner address
         */
        _transferOwnership(address(0xA450136DC6ec1F50965D2D9AE5365889c003eD8e));
        (
            uint32 _timeStart,
            uint32 _timeEnd,
            uint32 _dropId,
            string memory _tokenSymbol
        ) = abi.decode(_staticData, (uint32, uint32, uint32, string));

        (
            uint32 _totalAmountOfEdition,
            uint32 _nftId,
            uint32 _artistRoyaltiesPercentage,
            uint32 _initialRoyaltySalePercentage,
            address _artistAddress,
            bytes memory _tokenName
        ) = abi.decode(
                _dynamicData,
                (uint32, uint32, uint32, uint32, address, bytes)
            );

        _name = string(_tokenName);
        _symbol = _tokenSymbol;
        totalAmountOfEdition = _totalAmountOfEdition;
        timeStart = _timeStart;
        timeEnd = _timeEnd;
        dropId = _dropId;
        nftId = _nftId;
        artistRoyaltiesPercentage = _artistRoyaltiesPercentage;
        initialRoyaltySalePercentage = _initialRoyaltySalePercentage;
        artistAddress = _artistAddress;

        accessManager = IAccessManager(_accessManangerAddress);
        displateManager = IDisplateManager(msg.sender);

        /**
         * @notice Artist chose FIAT settlement
         */
        if (artistAddress == address(0)) {
            require(
                artistRoyaltiesPercentage == 0,
                "NFT init: artistRoyaltiesPercentage must be equal to zero"
            );
            require(
                initialRoyaltySalePercentage == 0,
                "NFT init: initialRoyaltySalePercentage must be equal to zero"
            );
        } else {
            require(
                artistRoyaltiesPercentage > 0,
                "NFT init: artistRoyaltiesPercentage must be higher then zero"
            );
        }
    }

    function totalSupply() public view returns (uint32) {
        return totalAmountOfEdition;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function awardToken(address _user, uint32 _tokenID) public {
        require(timeStart <= block.timestamp, "Drop is not active yet");
        /**
         * @notice We want to block minting after a week after drop ended. This is to allow extended auctions to mint, and block any further attempts to mint old flopped editions
         */
        require((timeEnd + 604800) >= block.timestamp, "Drop is not active");
        require(
            accessManager.isOperationalAddress(msg.sender) == true,
            "You are not allowed to award tokens"
        );
        require(
            _tokenID <= totalAmountOfEdition,
            "Token ID is bigger then total amount of tokens in this drop"
        );
        require(
            _exists(_tokenID) == false,
            "Token with this ID was minted previously"
        );
        require(isTokenBurned[_tokenID] == false, "Token was burned");

        emit TokenAwarded(
            _user,
            _name,
            _symbol,
            _tokenID,
            tokenURI(uint256(_tokenID))
        );
        _safeMint(_user, _tokenID);
    }

    function tokenURI(uint256 _tokenID)
        public
        view
        override
        returns (string memory)
    {
        string memory baseTokenUri = displateManager.baseTokenUri();
        return
            string(
                abi.encodePacked(
                    baseTokenUri,
                    "/",
                    Strings.toString(dropId),
                    "/",
                    Strings.toString(nftId),
                    "/",
                    Strings.toString(_tokenID),
                    ".json"
                )
            );
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(tokenId <= totalAmountOfEdition, "Token ID is out of range");
        uint256 _royaltyAmount;
        if (_exists(tokenId)) {
            _royaltyAmount = (salePrice * artistRoyaltiesPercentage) / 10000;
        } else {
            require(
                isTokenBurned[uint32(tokenId)] == false,
                "Token was burned"
            );
            _royaltyAmount = (salePrice * initialRoyaltySalePercentage) / 10000;
        }

        return (artistAddress, _royaltyAmount);
    }

    function burnToken(uint32 _tokenID) public {
        require(
            ownerOf(_tokenID) == msg.sender ||
                accessManager.isOperationalAddress(msg.sender) == true,
            "You are not a owner of this token"
        );

        _burn(_tokenID);
        isTokenBurned[_tokenID] = true;
        emit TokenBurned(msg.sender, _name, _symbol, _tokenID);
    }

    function delegatedTransfer(
        address _addressTo,
        uint32 _tokenId,
        uint32 _expirationDate,
        bytes32 _salt,
        bytes memory _signature
    ) public {
        require(_expirationDate > block.timestamp, "Time is out");
        require(saltUsed[_salt] == false, "This salt was used");
        bytes32 _hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    TRANSFER_TYPEHASH,
                    _addressTo,
                    _tokenId,
                    _expirationDate,
                    _salt
                )
            )
        );
        address owner = ECDSA.recover(_hash, _signature);

        saltUsed[_salt] = true;

        _transfer(owner, _addressTo, _tokenId);
    }

    function delegatedBurn(
        uint32 _tokenId,
        uint32 _expirationDate,
        bytes32 _salt,
        bytes memory _signature
    ) public {
        require(_expirationDate > block.timestamp, "Time is out");
        require(saltUsed[_salt] == false, "This salt was used");

        bytes32 _hash = _hashTypedDataV4(
            keccak256(
                abi.encode(BURN_TYPEHASH, _tokenId, _expirationDate, _salt)
            )
        );
        address owner = ECDSA.recover(_hash, _signature);

        require(owner == ownerOf(_tokenId), "Wrong sender");

        saltUsed[_salt] = true;

        _burn(_tokenId);

        isTokenBurned[_tokenId] = true;
    }
}