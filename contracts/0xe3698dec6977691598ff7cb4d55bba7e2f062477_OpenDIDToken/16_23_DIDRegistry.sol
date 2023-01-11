// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721.sol";
import "./IRegistry.sol";
import "./INameValidator.sol";

/**
 * DIDRegistry that holds name records.
 */
contract DIDRegistry is ERC721, Ownable, IRegistry {
    uint256 constant LABEL_ENABLED = 1;
    uint256 constant LABEL_DISABLED = 2;

    mapping(address => bool) public controllers;

    // uint256(keccake(bytes(label)))
    mapping(uint256 => uint256) public labels;

    mapping(address => bool) public proxies;

    mapping(uint256 => mapping(uint256 => string)) internal records;

    // reverse lookup address => name:
    mapping(address => string) internal names;

    string public uri;

    INameValidator internal validator;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        Ownable()
    {}

    // modifiers

    modifier onlyController() {
        require(controllers[msg.sender], "only controller");
        _;
    }

    // Management

    function setProxy(address proxy, bool supported) external onlyOwner {
        proxies[proxy] = supported;
        emit Proxy(proxy, supported);
    }

    function setBaseURI(string memory _uri) external override onlyOwner {
        uri = _uri;
    }

    function setController(address controller, bool supported)
        external
        override
        onlyOwner
    {
        controllers[controller] = supported;
        emit Controller(controller, supported);
    }

    function addLabels(string[] memory _labels) external override onlyOwner {
        uint256 i;
        for (i = 0; i < _labels.length; i++) {
            labels[_toId(_labels[i])] = LABEL_ENABLED;
            emit Label(_labels[i], true);
        }
    }

    function setLabel(string memory label, bool supported)
        external
        override
        onlyOwner
    {
        labels[_toId(label)] = supported ? LABEL_ENABLED : LABEL_DISABLED;
        emit Label(label, supported);
    }

    function setNameValidator(address _validator) external override onlyOwner {
        emit NameValidator(address(validator), _validator);
        validator = INameValidator(_validator);
    }

    // public logic

    function lookup(string memory name)
        external
        view
        override
        returns (address)
    {
        return _owners[_toId(name)];
    }

    function batchLookup(string[] calldata _names)
        external
        view
        override
        returns (address[] memory)
    {
        address[] memory results = new address[](_names.length);
        uint256 i;
        for (i = 0; i < _names.length; i++) {
            results[i] = _owners[_toId(_names[i])];
        }
        return results;
    }

    function reverseLookup(address registrant)
        external
        view
        override
        returns (string memory)
    {
        return names[registrant];
    }

    function batchReverseLookup(address[] calldata registrants)
        external
        view
        override
        returns (string[] memory)
    {
        string[] memory results = new string[](registrants.length);
        uint256 i;
        for (i = 0; i < registrants.length; i++) {
            results[i] = names[registrants[i]];
        }
        return results;
    }

    function queryRecord(uint256 tokenId, string calldata label)
        external
        view
        override
        returns (string memory)
    {
        return records[tokenId][_toId(label)];
    }

    function queryRecords(uint256 tokenId, string[] calldata _labels)
        external
        view
        override
        returns (string[] memory)
    {
        string[] memory results = new string[](_labels.length);
        uint256 i;
        for (i = 0; i < _labels.length; i++) {
            results[i] = records[tokenId][_toId(_labels[i])];
        }
        return results;
    }

    function register(string memory name, address registrant)
        external
        override
        onlyController
        returns (uint256, uint256)
    {
        uint256 len = validator.validateName(name);
        require(len > 0 && len <= 100, "invalid name length");
        uint256 tokenId = _toId(name);
        // emit Register event before transfer:
        emit Register(registrant, tokenId, name);
        _mint(registrant, tokenId);
        names[registrant] = name;
        return (tokenId, len);
    }

    function batchBind(
        uint256 tokenId,
        string[] calldata bindLabels,
        string[] calldata values,
        address registrant
    ) external override onlyController {
        require(ownerOf(tokenId) == registrant, "not name owner");
        uint256 len = bindLabels.length;
        require(len == values.length, "not same length");

        for (uint256 i = 0; i < len; i++) {
            _bind(tokenId, bindLabels[i], values[i], registrant);
        }
    }

    function bind(
        uint256 tokenId,
        string calldata label,
        string calldata value,
        address registrant
    ) external override onlyController {
        require(ownerOf(tokenId) == registrant, "not name owner");
        _bind(tokenId, label, value, registrant);
    }

    function _bind(
        uint256 tokenId,
        string calldata label,
        string calldata value,
        address registrant
    ) internal {
        bytes memory valueBytes = bytes(value);
        uint256 len = valueBytes.length;
        require(len <= 255, "Value too long");
        uint256 labelId = _toId(label);

        if (len == 0) {
            require(labels[labelId] > 0, "unsupported label"); // label is enabled or disabled
            delete records[tokenId][labelId];
        } else {
            require(labels[labelId] == LABEL_ENABLED, "unsupported label"); // label is enabled
            records[tokenId][labelId] = value;
        }
        emit Bind(registrant, tokenId, label, value);
    }

    function validateName(string memory name)
        external
        view
        override
        returns (uint256)
    {
        return validator.validateName(name);
    }

    function isApprovedForAll(address registrant, address operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool)
    {
        if (proxies[operator]) {
            return true;
        }

        return ERC721.isApprovedForAll(registrant, operator);
    }

    function toTokenId(string memory s)
        external
        pure
        override
        returns (uint256)
    {
        return _toId(s);
    }

    // internal logic
    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function _toId(string memory s) internal pure returns (uint256) {
        return uint256(keccak256(bytes(s)));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal view override {
        require(balanceOf(to) == 0, "registered");
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // not after mint:
        if (from != address(0)) {
            names[to] = names[from];
            delete names[from];
        }
    }
}