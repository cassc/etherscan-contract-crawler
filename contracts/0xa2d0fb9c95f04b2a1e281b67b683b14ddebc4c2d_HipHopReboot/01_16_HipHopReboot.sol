// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HipHopReboot is ERC721, ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public supplyLimit;
    uint256 public onceLimit;
    uint256 public maxLimit;
    uint256[2] private _preMintTime;
    uint256[2] private _publicMintTime;
    Counters.Counter private _tokenIdCounter;
    string private __baseURI;
    mapping(address => bool) private _preMintAllowed;
    mapping(address => uint256[2]) private _preMintAllowedLimit;
    mapping(address => uint256) private _publicMintCount;

    constructor(string memory name, string memory symbol, string memory baseURI_, uint256 supplyLimit_, uint256 onceLimit_, uint256 maxLimit_, uint256[2] memory preMintTime, uint256[2] memory publicMintTime)
    ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _tokenIdCounter.increment();

        __baseURI = baseURI_;
        supplyLimit = supplyLimit_;
        onceLimit = onceLimit_;
        maxLimit = maxLimit_;

        _preMintTime[0] = preMintTime[0];
        _preMintTime[1] = preMintTime[1];
        _publicMintTime[0] = publicMintTime[0];
        _publicMintTime[1] = publicMintTime[1];
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyRole(MINTER_ROLE) {
        __baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, '/', tokenId.toString(), '.json'));
    }

    function setPreMintTime(uint256 start, uint256 end) external onlyRole(MINTER_ROLE) {
        _preMintTime[0] = start;
        _preMintTime[1] = end;
    }

    function getPreMintTime() external view returns (uint256, uint256) {
        return (_preMintTime[0], _preMintTime[1]);
    }

    function setPublicMintTime(uint256 start, uint256 end) external onlyRole(MINTER_ROLE) {
        _publicMintTime[0] = start;
        _publicMintTime[1] = end;
    }

    function getPublicMintTime() external view returns (uint256, uint256) {
        return (_publicMintTime[0], _publicMintTime[1]);
    }

    function setSupplyLimit(uint256 limit) external onlyRole(MINTER_ROLE) {
        supplyLimit = limit;
    }

    function setOnceLimit(uint256 limit) external onlyRole(MINTER_ROLE) {
        onceLimit = limit;
    }

    function setMaxLimit(uint256 limit) external onlyRole(MINTER_ROLE) {
        maxLimit = limit;
    }

    function getMintInfo() external view returns (uint256, uint256, uint256, uint256, uint256[2] memory, uint256, uint256, uint256) {
        uint256 balance = 0;
        uint256 _minted = 0;
        uint256 _maxLimit = maxLimit;
        uint256 _onceLimit = onceLimit;

        if (msg.sender != address(0)) {
            balance = balanceOf(address(msg.sender));
        }

        if (block.timestamp <= _preMintTime[1]) {
            if (msg.sender != address(0)) {
                _maxLimit = _preMintAllowedLimit[address(msg.sender)][0];
                _minted   = _preMintAllowedLimit[address(msg.sender)][1];
                _onceLimit = _maxLimit - _minted;
            }

            return (supplyLimit, totalSupply(), balance, 1, _preMintTime, _onceLimit, _minted, _maxLimit);
        }
        if (block.timestamp <= _publicMintTime[1]) {
            _minted = _publicMintCount[address(msg.sender)];
            _onceLimit = _onceLimit - _minted;
            return (supplyLimit, totalSupply(), balance, 3, _publicMintTime, _onceLimit, _minted, _maxLimit);
        }

        return (supplyLimit, totalSupply(), balance, 0, [uint256(0), uint256(0)], 0, 0, _maxLimit);
    }

    function setPreMintList(address[] memory list, uint256[] memory amounts) external onlyRole(MINTER_ROLE) {
        require(list.length == amounts.length, 'wrong input size');

        for (uint i = 0; i < list.length; i++) {
            address allowed = list[i];

            if (_preMintAllowed[allowed] == false) {
                _preMintAllowed[allowed] = true;
            }

            _preMintAllowedLimit[allowed] = [amounts[i], 0];
        }
    }

    function safeMint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _safeMintAmount(to, amount);
    }

    function _safeMintAmount(address to, uint256 amount) internal {
        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();

            require(tokenId <= supplyLimit, 'exceed supply');

            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    function mint(uint256 stageNumber, uint256 amount) external {
        require(address(msg.sender) != address(0) && address(msg.sender) != address(this), 'wrong address');
        require(totalSupply() + amount <= supplyLimit, 'exceed supply');
        require(amount > 0, 'zero amount');

        _beforeMintFor(stageNumber, amount);
        _safeMintAmount(msg.sender, amount);
        _afterMintFor(stageNumber, amount);
    }

    function _beforeMintFor(uint256 stageNumber, uint256 amount) internal view {
        if (stageNumber == 1) {
            require(block.timestamp >= _preMintTime[0], 'pre-mint not started');
            require(block.timestamp <= _preMintTime[1], 'pre-mint timeout');

            require(_preMintAllowed[address(msg.sender)] == true, 'not listed');

            uint256 _maxLimit = _preMintAllowedLimit[address(msg.sender)][0];
            uint256 _minted   = _preMintAllowedLimit[address(msg.sender)][1];
            require(_minted + amount <= _maxLimit, 'exceed pre-mint limit');

        } else if (stageNumber == 3) {
            require(block.timestamp >= _publicMintTime[0], 'public-mint not started');
            require(block.timestamp <= _publicMintTime[1], 'public-mint timeout');
            require(amount <= onceLimit, 'exceed mint limit');

            uint256 _minted = _publicMintCount[address(msg.sender)];
            require(_minted + amount <= maxLimit, 'exceed public-mint limit');

        } else {
            revert('wrong stage number');
        }
    }

    function _afterMintFor(uint256 stageNumber, uint256 amount) internal {
        if (stageNumber == 1) {
            uint256 _minted   = _preMintAllowedLimit[address(msg.sender)][1];
            _preMintAllowedLimit[address(msg.sender)][1] = _minted + amount;

        } else if (stageNumber == 3) {
            uint256 _minted = _publicMintCount[address(msg.sender)];
            _publicMintCount[address(msg.sender)] = _minted + amount;
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}