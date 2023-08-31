// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract KenCorp is Ownable, ERC721A("KenCorp", "KenCorp"), ERC2981 {
    event Promoted(uint[] tokens, uint[] departments);

    mapping(address => bool) public operators;

    bool public mintingEnded = false;
    bool public burningEnded = false;
    bool public promotingEnded = false;

    string public baseURI = "ipfs://bafybeihddva7x4mnexjiotmwwwnckh4ndleifgx6jjtln7negakavsgpn4/";
    bool public revealed = false;

    mapping(uint => uint) public packedDepartments;
    mapping(uint => bool) public burnedTokens;
    mapping(address => bool) public operatorsDisabled;

    constructor() {
        _setDefaultRoyalty(msg.sender, 500);
    }

    /* /////// OnlyOwner /////// */

    function airdrop(
        address[] calldata addresses
    ) external onlyOwner mintingPossible {
        require(addresses.length > 0, "Empty addresses");
        address prev;
        address addr;
        uint count;
        uint first = _nextTokenId();
        for (uint i = 0; i < addresses.length; i++) {
            addr = addresses[i];
            if (addr != prev) {
                if (count > 0) {
                    _mint(prev, count);
                    count = 0;
                }
                prev = addr;
            } else setDepartment(first + i, count + 1);
            count++;
        }
        _mint(addr, count);
    }

    function setBaseURI(string memory uri, bool revealed_) external onlyOwner {
        baseURI = uri;
        revealed = revealed_;
    }

    function setOperator(address addr, bool trusted) external onlyOwner {
        operators[addr] = trusted;
    }

    function setRoyalties(address receiver, uint96 amount) external onlyOwner {
        _setDefaultRoyalty(receiver, amount);
    }

    function endMinting() external onlyOwner {
        mintingEnded = true;
    }

    function endBurning() external onlyOwner {
        burningEnded = true;
    }

    function endPromoting() external onlyOwner {
        promotingEnded = true;
    }

    /* /////// Internal /////// */

    function _startTokenId() internal pure override returns (uint) {
        return 1;
    }

    function setDepartment(uint token, uint dept) internal {
        if (--dept == 0) return;
        require(dept < 16, "Invalid department");
        uint mask = 0xF << ((token % 64) * 4);
        packedDepartments[token / 64] =
            (packedDepartments[token / 64] & ~mask) |
            (dept << ((token % 64) * 4));
    }

    /* /////// Operators /////// */

    function disableOperators() external {
        operatorsDisabled[msg.sender] = true;
    }

    function enableOperators() external {
        delete operatorsDisabled[msg.sender];
    }

    function checkOperatorsAllowed(uint256 token) internal view {
        checkOperatorsAllowed(ownerOf(token));
    }

    function checkOperatorsAllowed(address addr) internal view {
        require(!operatorsDisabled[addr], "Holder disabled operators");
    }

    function burn(
        uint[] calldata tokens
    ) external onlyOperators burningPossible {
        for (uint i = 0; i < tokens.length; i++) {
            uint token = tokens[i];
            require(!burnedTokens[token], "Token is burned");
            checkOperatorsAllowed(token);
            burnedTokens[token] = true;
            _burn(token, false);
        }
    }

    function mint(
        address addr,
        uint[] calldata departments
    ) external onlyOperators mintingPossible {
        checkOperatorsAllowed(addr);
        uint first = _nextTokenId();
        _mint(addr, departments.length);
        for (uint i = 0; i < departments.length; i++) {
            setDepartment(first + i, departments[i]);
        }
    }

    function promote(
        uint[] calldata tokens,
        uint[] calldata departments
    ) external onlyOperators promotingPossible {
        for (uint i = 0; i < tokens.length; i++) {
            uint token = tokens[i];
            require(!burnedTokens[token], "Token is burned");
            checkOperatorsAllowed(token);
            setDepartment(token, departments[i]);
        }
        emit Promoted(tokens, departments);
    }

    /* /////// View /////// */

    function getDepartment(uint token) public view returns (uint) {
        uint256 packedData = packedDepartments[token / 64];
        uint shift = (token % 64) * 4;
        uint dept = (packedData >> shift) & 0xF;
        return dept + 1;
    }

    function tokenURI(uint token) public view override returns (string memory) {
        if (burnedTokens[token])
            return string(abi.encodePacked(baseURI, "burned.json"));

        uint dept = getDepartment(token);
        return
            string(
                revealed
                    ? abi.encodePacked(
                        baseURI,
                        _toString(dept),
                        "-",
                        _toString(token),
                        ".json"
                    )
                    : abi.encodePacked(baseURI, _toString(dept), ".json")
            );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /* /////// Modifiers /////// */

    modifier onlyOperators() {
        require(operators[msg.sender], "Caller is not an operator");
        _;
    }

    modifier burningPossible() {
        require(!burningEnded, "Burning has ended forever");
        _;
    }

    modifier mintingPossible() {
        require(!mintingEnded, "Minting has ended forever");
        _;
    }

    modifier promotingPossible() {
        require(!promotingEnded, "Promoting has ended forever");
        _;
    }
}