// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Flower is ERC721Enumerable, Ownable {
    string public baseURI;

    mapping(address => bool) oneOfOneCollectors;

    mapping(address => bool) nonCollectors;

    address BuildABetterFutureContract;
    address TimePieceCommunityContract;

    // mintList
    mapping(address => bool) public oneOfOneMintList;
    mapping(address => bool) public nonCollectorsMintList;
    mapping(address => bool) public openEditionCollectorsMintList;
    // tokenId => minted
    mapping(uint256 => bool) public safeHavenTokenMintList;
    mapping(uint256 => bool) public graceIITokenMintList;

    // counters
    // tokenIds 1 to 14
    uint256 private oneOfOneMintedCount = 1;

    // tokenIds 15 to 24
    uint256 private nonCollectorsMintedCount = 15;

    // tokenIds 25 to 54
    uint256 private openEditionCollectorsMintedCount = 25;

    bool private mintOpen = false;

    //these tokens must exists, otherwise the check fails cos of _exists
    uint256[] safeHavenTokens = [4216, 4209, 4213, 4215, 4207, 4214, 4211, 4208, 4210, 4212, 4206]; //babF
    uint256[] graceIITokens = [
        4173, 4168, 4176, 4236, 4171, 4212, 4190, 4098, 4092, 4167, 4112, 4228, 4149, 4209, 4244,
        4146, 4222, 4165, 4158, 4153, 4136, 4139, 4100, 4217, 4208, 4178, 4152, 4221, 4141, 4218,
        4087, 4082, 4097, 4071, 4150, 4204, 4193, 4242, 4220, 4099, 4140, 4077, 4237, 4170, 4162,
        4073, 4101, 4240, 4142, 4085, 4148, 4191, 4129, 4128, 4172, 4253, 4070, 4095, 4199, 4081,
        4108, 4151, 4084, 4206, 4124, 4110, 4230, 4106, 4120, 4216, 4093, 4154, 4198, 4175, 4103,
        4137, 4117, 4118, 4192, 4185, 4076, 4078, 4223, 4213, 4186, 4225, 4159, 4210, 4134, 4116,
        4114, 4145, 4187, 4133, 4243, 4096, 4232, 4111, 4188, 4183, 4090, 4104, 4211, 4219, 4164,
        4089, 4161, 4113, 4235, 4197, 4147, 4207, 4229, 4086, 4094, 4224, 4122, 4157, 4109, 4251,
        4181, 4254, 4125, 4252, 4130, 4248, 4182, 4144, 4163, 4166, 4105, 4184, 4201, 4189, 4156,
        4249, 4123, 4169, 4115, 4231, 4215, 4138, 4234, 4131, 4119, 4247, 4074, 4179, 4202, 4246,
        4155, 4121, 4180, 4102, 4079, 4238, 4143, 4245, 4080, 4083, 4075, 4135, 4195, 4200, 4203,
        4239, 4233, 4196, 4227, 4132, 4250, 4107, 4174, 4160, 4177, 4226, 66, 67, 68, 4194, 4088,
        4205, 4072, 4214, 4241, 4126, 4127, 4091
      ]; // IRB

    modifier whenMintOpened() {
        require(mintOpen == true, "Mint is not yet open");
        _;
    }
    constructor(
        string memory _initBaseURI,
        address buildABetterFutureContract,
        address timePieceCommunityContract
    ) ERC721("Flowers", "FLW") {
        setBaseURI(_initBaseURI);

        BuildABetterFutureContract = buildABetterFutureContract;
        TimePieceCommunityContract = timePieceCommunityContract;

        // define one-of-one-collectors
        oneOfOneCollectors[0x8c9F364bf7a56Ed058fc63Ef81c6Cf09c833e656] = true;
        oneOfOneCollectors[0x9FDf724BcDF9392bD4b99A1C463EC674bC891bB9] = true;
        oneOfOneCollectors[0x1E815a8188F1b84564577C1c998f7E6B4706B752] = true;
        oneOfOneCollectors[0x109Ad81CA063fa1a8237189e31821d3114c52a4e] = true;
        oneOfOneCollectors[0x75259686c1C967399eDA0b4B16f16FB0990f9615] = true;
        oneOfOneCollectors[0xC571147a515a789eB23cbCBf92F86bc1485ab877] = true;
        oneOfOneCollectors[0x30a189710f75c6b60b96081F12B288AbEDeDa260] = true;
        oneOfOneCollectors[0x4E84a91a450aeEF23F0670Fb486d55b1d85A8dD0] = true;
        oneOfOneCollectors[0x3612b2e93b49F6c797066cA8c38b7f522b32c7cb] = true;
        oneOfOneCollectors[0xcF6f5A68d94165081A634AdA997BE3A93426C467] = true;
        oneOfOneCollectors[0x8C94072567b278b9fa12192CcA899B3Ce0ED5FDc] = true;
        oneOfOneCollectors[0x8139bA1a21dB4b924A81D5De90a98980B5D502E5] = true;
        oneOfOneCollectors[0xcA71c095Ac06c5f17e03Da013c8041701Ef438b6] = true;
        oneOfOneCollectors[0x0D48086911270b67bC973B7AA1A1332EF83DD472] = true;

        // define non-collectors
        nonCollectors[0x80Aa4AF1Fb6e8a381b73809cbf06AED2666A7b64] = true;
        nonCollectors[0x7E66dE1A57e6DC63B31FF03B50c103379c840d14] = true;
        nonCollectors[0xeb758d7b02eb8ADfAA553f49Cfa8b034Ab73c1C4] = true;
        nonCollectors[0xFC789C7927aC1cC8CaeFDE8bEbf493961AC5be9B] = true;
        nonCollectors[0x0f2f2F7bFC893aDa1714802924F96B82c9A1fFD3] = true;
        nonCollectors[0x215F7aDd9541Bc097679D9237DF7d42bb114134c] = true;
        nonCollectors[0xb3007FF3c3F40bDF0126fEc7c8E43c3Fc50Ea813] = true;
        nonCollectors[0x1Da98aa4FaEFB6eC93cC1bA6AdcFB59c8aF51152] = true;
        nonCollectors[0x2c11Cf38a6A5Ac74eA438d0037F7f880021FC66f] = true;
        nonCollectors[0x7ed90FDd530Ec92E90E197bA891378b1f9680e0A] = true;
        nonCollectors[0xDc1bc12a38206B010971859DC7177AfF9d27C454] = true;
        nonCollectors[0x5F0ACdE83F858014bc9723B356095E28fc8880B1] = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function isOneOfOneCollector(address _wallet) public view returns (bool) {
        return oneOfOneCollectors[_wallet];
    }

    function isNonCollector(address _wallet) public view returns (bool) {
        return nonCollectors[_wallet];
    }
    function _safeHavenOwner(address _wallet)
        internal
        view
        returns (bool _holder, uint256 _tokenId)
    {
        ERC721 buildABetterFuture = ERC721(BuildABetterFutureContract);

        for (uint256 i = 0; i < safeHavenTokens.length; i++) {
            if (buildABetterFuture.ownerOf(safeHavenTokens[i]) == _wallet) {
                return (true, safeHavenTokens[i]);
            }
        }
        return (false, 0);
    }

    function _graceIIOwner(address _wallet)
        internal
        view
        returns (bool _holder, uint256 _tokenId)
    {
        ERC721 timePieceCommunity = ERC721(TimePieceCommunityContract);

        for (uint256 i = 0; i < graceIITokens.length; i++) {
            if (timePieceCommunity.ownerOf(graceIITokens[i]) == _wallet) {
                return (true, graceIITokens[i]);
            }
        }
        return (false, 0);
    }

    // below function and next following seems like a duplication of above,
    // but its intentional, as below 2 are used by FE cos of gas approximation issue explianed elsewhere
    function isSafeHavenOwner(address _wallet, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        ERC721 buildABetterFuture = ERC721(BuildABetterFutureContract);

        if (buildABetterFuture.ownerOf(_tokenId) == _wallet) {
            return true;
        }
        return false;
    }

    function isGraceIIOwner(address _wallet, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        ERC721 timePieceCommunity = ERC721(TimePieceCommunityContract);

        if (timePieceCommunity.ownerOf(_tokenId) == _wallet) {
            return true;
        }
        return false;
    }

    // function to determine if sender is open-edition collector
    // FYI: Last minute change made this not be used on FE as etherjs couldnot auto detect gas fees,
    function isOpenEditionCollector(address _wallet)
        public
        view
        returns (
            bool isHolder,
            uint256 safeHavenTokenId,
            uint256 graceIITokenId
        )
    {
        (bool _safeHavenHolder, uint256 _safeHavenTokenId) = _safeHavenOwner(
            _wallet
        );
        (bool _graceIIHolder, uint256 _graceIITokenId) = _graceIIOwner(_wallet);

        isHolder = _safeHavenHolder == true || _graceIIHolder == true;
        return (isHolder, _safeHavenTokenId, _graceIITokenId);
    }

    function mint1Of1Holder(address _wallet) external whenMintOpened {
        require(
            oneOfOneMintList[_wallet] == false,
            "Wallet already minted before for this category"
        );
        require(
            isOneOfOneCollector(_wallet) == true,
            "Wallet must be an open edition collector"
        );
        // this condition should actually never be triggered, but having it here incase
        // might remove later to save compiled code space.
        require(
            oneOfOneMintedCount <= 14,
            "INTERNAL ERROR: Reached max tokens allowed for this category"
        );
        uint256 tokenId = oneOfOneMintedCount;

        _safeMint(_wallet, tokenId);

        oneOfOneMintList[_wallet] = true;
        oneOfOneMintedCount += 1;

        emit LogMintOneOfOneHolder(_wallet, tokenId);
    }

    function mintNonCollector(address _wallet) external whenMintOpened {
        require(
            nonCollectorsMintList[_wallet] == false,
            "Wallet already minted before for this category"
        );
        require(
            isNonCollector(_wallet) == true,
            "Wallet must be part of the non-collector list"
        );

        // this condition should actually never be triggered, but having it here incase
        // might remove later to save compiled code space.
        require(
            nonCollectorsMintedCount <= 24,
            "INTERNAL ERROR: Reached max tokens allowed for this category"
        );
        uint256 tokenId = nonCollectorsMintedCount;

        _safeMint(_wallet, tokenId);

        nonCollectorsMintList[_wallet] = true;
        nonCollectorsMintedCount += 1;
        emit LogMintNonCollector(_wallet, tokenId);
    }

    function mintOpenEdition(address _wallet) external whenMintOpened {
        (
            bool isHolder,
            uint256 _safeHavenTokenId,
            uint256 _graceIITokenId
        ) = isOpenEditionCollector(_wallet);
        require(isHolder == true, "Must be a holder of GraceII or SafeHaven");
        require(
            safeHavenTokenMintList[_safeHavenTokenId] == false ||
                graceIITokenMintList[_graceIITokenId] == false,
            "Wallet minted already before for this category"
        );

        require(
            openEditionCollectorsMintedCount <= 54,
            "INTERNAL ERROR: Reached max tokens allowed for this category"
        );
        uint256 tokenId = openEditionCollectorsMintedCount;

        _safeMint(_wallet, tokenId);

        // -- store tokenId and address that minted
        if (_safeHavenTokenId != 0) {
            safeHavenTokenMintList[_safeHavenTokenId] = true;
        } else {
            graceIITokenMintList[_graceIITokenId] = true;
        }

        openEditionCollectorsMintedCount += 1;
        openEditionCollectorsMintList[_wallet] = true;
        emit LogMintOpenEdition(_wallet, tokenId);
    }

    // Only owner - admin methods
    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function setMintOpen(bool value) external onlyOwner {
        require(mintOpen != value, "mintOpen already this value");
        mintOpen = value;
    }

    // these method below should never reallybe used as they may reset the counters for available mints
    // only added here to prevent total lockout
    function addOneOfOneCollector(address _wallet) external onlyOwner {
        require(
            oneOfOneCollectors[_wallet] != true,
            "Wallet has already added to the one of one collector list"
        );
        oneOfOneCollectors[_wallet] = true;
    }

    function addNonCollector(address _wallet) external onlyOwner {
        require(
            nonCollectors[_wallet] != true,
            "Wallet has already added to the non collector list"
        );
        nonCollectors[_wallet] = true;
    }

    // Events
    event LogMintOneOfOneHolder(address indexed _address, uint256 _tokenId);
    event LogMintNonCollector(address indexed _address, uint256 _tokenId);
    event LogMintOpenEdition(address indexed _address, uint256 _tokenId);
}