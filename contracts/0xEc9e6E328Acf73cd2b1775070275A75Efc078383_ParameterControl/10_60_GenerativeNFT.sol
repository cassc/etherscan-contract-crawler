// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../lib/helpers/Random.sol";
import "../lib/helpers/Errors.sol";
import "../lib/helpers/BoilerplateParam.sol";
import "./GenerativeBoilerplateNFT.sol";
import "../interfaces/IGenerativeNFT.sol";

contract GenerativeNFT is ERC721PresetMinterPauserAutoId, ReentrancyGuard, IERC2981, IGenerativeNFT {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    // admin of collection -> owner, creator, ...
    address public _admin;
    // linked boilerplate address
    address public _boilerplateAddr;
    // linked projectId in boilerplate
    uint256 public _boilerplateId;
    // params value for rendering -> mapping with tokenId of NFT
    mapping(uint256 => BoilerplateParam.ParamsOfProject) public _paramsValues;

    // 
    mapping(uint256 => string) _customUri;
    // creator of nft tokenID, set from boilerplate calling
    mapping(uint256 => address) public _creators;

    string public _name;
    string public _symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseuri
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseuri) {
    }

    function initAdmin(address _newAdmin) internal {
        require(msg.sender == _boilerplateAddr, "INV_SENDER_INIT_ADMIN");
        require(_newAdmin != address(0x0), "INV_ADD");

        _admin = _newAdmin;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MINTER_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
    }

    function init(
        string memory name,
        string memory symbol,
        address admin,
        address boilerplateAdd,
        uint256 boilerplateId
    ) external {
        require(boilerplateAdd != address(0x0), "INV_ADD");
        require(admin != address(0x0), "INV_ADD");
        require(_boilerplateId == 0, "EXISTED");

        _name = name;
        _symbol = symbol;
        _boilerplateAddr = boilerplateAdd;
        _boilerplateId = boilerplateId;
        initAdmin(admin);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    modifier creatorOnly(uint256 _id) {
        require(_creators[_id] == _msgSender(), "ONLY_CREATOR");
        _;
    }

    modifier adminOnly() {
        require(_msgSender() == _admin, "ONLY_ADMIN_ALLOWED");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ONLY_ADMIN_ALLOWED");
        _;
    }

    function changeAdmin(address _newAdmin) public adminOnly {
        address _previousAdmin = _admin;
        _admin = _newAdmin;

        grantRole(DEFAULT_ADMIN_ROLE, _admin);
        grantRole(MINTER_ROLE, _admin);
        grantRole(PAUSER_ROLE, _admin);

        revokeRole(DEFAULT_ADMIN_ROLE, _previousAdmin);
        revokeRole(MINTER_ROLE, _previousAdmin);
        revokeRole(PAUSER_ROLE, _previousAdmin);
    }

    function mint(address to) public override {}

    function mint(address mintTo, address creator, string memory uri, BoilerplateParam.ParamsOfProject calldata _paramsTemplateValue, bool clientSeed) external {
        require(msg.sender == _boilerplateAddr, Errors.INV_BOILERPLATE_ADD);
        require(_boilerplateAddr != address(0x0), Errors.INV_PROJECT);
        require(_boilerplateId > 0, Errors.INV_PROJECT);

        // verify seed
        if (!clientSeed) {
            bytes32 seed = _paramsTemplateValue._seed;
            for (uint256 i = 0; i < _paramsTemplateValue._params.length; i++) {
                BoilerplateParam.ParamTemplate memory param = _paramsTemplateValue._params[i];
                if (param._typeValue != 0) {
                    if (param._availableValues.length == 0) {
                        require(Random.randomValueRange(uint256(seed), param._min, param._max) == param._value, Errors.SEED_INV_1);
                    } else {
                        require(Random.randomValueIndexArray(uint256(seed), param._availableValues.length) == param._value, Errors.SEED_INV_2);
                    }
                }
                seed = keccak256(abi.encodePacked(seed, param._value));
            }
        }

        GenerativeBoilerplateNFT boilerplateNFT = GenerativeBoilerplateNFT(_boilerplateAddr);
        require(boilerplateNFT.exists(_boilerplateId), Errors.INV_PROJECT);
        require(boilerplateNFT.mintMaxSupply(_boilerplateId) == 0 || boilerplateNFT.mintTotalSupply(_boilerplateId) < boilerplateNFT.mintMaxSupply(_boilerplateId), Errors.REACH_MAX);

        _nextTokenId.increment();
        uint256 currentTokenId = _nextTokenId.current();
        if (bytes(uri).length > 0) {
            _customUri[currentTokenId] = uri;
        }
        _creators[currentTokenId] = creator;
        _paramsValues[currentTokenId] = _paramsTemplateValue;
        _safeMint(mintTo, currentTokenId);

    }

    function _setCreator(address _to, uint256 _id) internal creatorOnly(_id)
    {
        _creators[_id] = _to;
    }

    function setCreator(
        address _to,
        uint256[] memory _ids
    ) public {
        require(_to != address(0), Errors.INV_ADD);

        _grantRole(MINTER_ROLE, _to);
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            _setCreator(_to, id);
        }
    }

    function totalSupply() public view override returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _baseURI();
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        bytes memory customUriBytes = bytes(_customUri[_tokenId]);
        if (customUriBytes.length > 0) {
            return _customUri[_tokenId];
        } else {
            return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
        }
    }

    function setCustomURI(
        uint256 _tokenId,
        string memory _newURI
    ) public creatorOnly(_tokenId) {
        _customUri[_tokenId] = _newURI;
    }

    /** @dev EIP2981 royalties implementation. */
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
        bool isValue;
    }

    mapping(uint256 => RoyaltyInfo) public royalties;

    function setTokenRoyalty(
        uint256 _tokenId,
        address _recipient,
        uint256 _value
    ) public adminOnly {
        require(_value <= 10000, Errors.REACH_MAX);
        royalties[_tokenId] = RoyaltyInfo(_recipient, uint24(_value), true);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalty = royalties[_tokenId];
        if (royalty.isValue) {
            receiver = royalty.recipient;
            royaltyAmount = (_salePrice * royalty.amount) / 10000;
        } else {
            receiver = _creators[_tokenId];
            royaltyAmount = (_salePrice * 500) / 10000;
        }
    }
}