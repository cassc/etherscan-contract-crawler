// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MetaDragonz is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    struct Ticket {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    enum TicketType {
        Presale,
        Claim,
        Burn,
        LevelUp
    }

    mapping(address => bool) internal allowed;
    mapping(uint256 => uint256) internal dragonLevels;
    mapping(bytes32 => uint256) internal tokenIncrementer;
    mapping(bytes32 => uint256) internal maxIssuance;
    mapping(bytes32 => uint256) internal mintPrices;
    mapping(bytes32 => mapping(uint256 => string)) internal dragonAttributes;
    mapping(uint256 => bytes32) internal tokenCollectionIndexes;

    string internal baseURI;
    string internal unrevealedURI;
    bool internal revealed = false;
    bool internal isPreMint = true;
    uint256 internal maxAllowed = 3;

    address private immutable _adminSigner;

    event Issue(address indexed _beneficiary, uint256 indexed _tokenId);
    event Allowed(address indexed _operator, bool _allowed);
    event Revealed(bool _revealed);
    event DragonAttributes(bytes32 _key, uint256 _bracket, string _hash);
    event SetMintPrice(uint256 _price);
    event LevelUpDragon(uint256 _tokenId);
    event LevelUpDragonz(uint256[] _dragonz);
    event LevelDownDragonz(uint256[] _dragonz);

    constructor(
        string memory _name,
        string memory _symbol,
        address _operator,
        string memory _baseURI,
        string memory _unrevealedURI,
        address adminSigner
    ) ERC721(_name, _symbol) {
        _adminSigner = adminSigner;
        setAllowed(_operator, true);
        setBaseURI(_baseURI);
        setUnRevealedURI(_unrevealedURI);
    }

    modifier onlyAllowed() {
        require(
            allowed[msg.sender],
            "Only an `allowed` address can call this method"
        );
        _;
    }

    function setAllowed(address _operator, bool _allowed) public onlyOwner {
        require(_operator != address(0), "Invalid address");
        require(
            allowed[_operator] != _allowed,
            "You should set a different value"
        );

        allowed[_operator] = _allowed;
        emit Allowed(_operator, _allowed);
    }

    function isVerifiedTicket(bytes32 _digest, Ticket memory _ticket)
        internal
        view
        returns (bool)
    {
        address signer = ecrecover(_digest, _ticket.v, _ticket.r, _ticket.s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer == _adminSigner;
    }

    function setBaseURI(string memory _uri) public onlyAllowed {
        baseURI = _uri;
    }

    function getKey(string memory _key) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_key));
    }

    function issueToken(
        address _beneficiary,
        bytes32 _key,
        Ticket memory _ticket
    ) external payable {
        require(
            allowed[msg.sender]
                ? msg.value >= 0
                : mintPrices[_key] <= msg.value,
            "Ether value sent is not correct"
        );
        require(
            allowed[msg.sender] || balanceOf(_beneficiary) + 1 <= maxAllowed,
            "Beneficiary already owns max allowed mints"
        );
        uint256 tokenId = tokenIncrementer[_key];
        mint(_beneficiary, tokenId, _key, _ticket);
    }

    function issueTokens(
        uint256 _amount,
        address _beneficiary,
        bytes32 _key,
        Ticket memory _ticket
    ) external payable {
        require(
            allowed[msg.sender]
                ? msg.value >= 0
                : _amount > 0 && mintPrices[_key].mul(_amount) <= msg.value,
            "Ether value sent is not correct"
        );
        require(
            allowed[msg.sender] ||
                balanceOf(_beneficiary) + _amount <= maxAllowed,
            "Beneficiary already owns max allowed mints"
        );

        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = tokenIncrementer[_key];
            mint(_beneficiary, tokenId, _key, _ticket);
        }
    }

    function mint(
        address _beneficiary,
        uint256 _tokenId,
        bytes32 _key,
        Ticket memory _ticket
    ) internal {
        require(tokenIncrementer[_key] > 0, "Collection issuance is not set");
        require(_beneficiary != address(0), "Invalid address");
        require(
            _tokenId > 0 && _tokenId <= maxIssuance[_key],
            "Exhausted collection"
        );

        bytes32 _digest = keccak256(abi.encode(TicketType.Presale, msg.sender));
        require(
            !isPreMint ||
                allowed[msg.sender] ||
                isVerifiedTicket(_digest, _ticket),
            "Only an `whitelisted` address can call this method"
        );

        super._safeMint(_beneficiary, _tokenId);

        tokenIncrementer[_key] = tokenIncrementer[_key] + 1;
        dragonLevels[_tokenId] = 1;
        tokenCollectionIndexes[_tokenId] = _key;
        emit Issue(_beneficiary, _tokenId);
    }

    function claim(bytes32 _key, Ticket memory _ticket) external {
        uint256 _tokenId = tokenIncrementer[_key];
        bytes32 _digest = keccak256(
            abi.encode(TicketType.Claim, _tokenId, msg.sender)
        );
        require(
            isVerifiedTicket(_digest, _ticket),
            "Only an address that can claim can call this method"
        );
        super._safeMint(msg.sender, _tokenId);

        tokenIncrementer[_key] = tokenIncrementer[_key] + 1;
        dragonLevels[_tokenId] = 1;
        tokenCollectionIndexes[_tokenId] = _key;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI called for non existent token");

        if (!revealed) {
            return string(abi.encodePacked(baseURI, unrevealedURI));
        }

        uint256 _bracket = dragonLevels[tokenId];
        bytes32 _collectionkey = tokenCollectionIndexes[tokenId];
        string memory _hash = dragonAttributes[_collectionkey][_bracket];
        return
            string(
                abi.encodePacked(
                    baseURI,
                    _hash,
                    "/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function addDragonAttribute(
        bytes32 _key,
        uint256 _bracket,
        string memory _hash
    ) external onlyAllowed {
        dragonAttributes[_key][_bracket] = _hash;
        emit DragonAttributes(_key, _bracket, _hash);
    }

    function setIssuance(
        bytes32 _key,
        uint256 _incrementer,
        uint256 _maxIssuance
    ) external onlyAllowed {
        tokenIncrementer[_key] = _incrementer;
        maxIssuance[_key] = _maxIssuance;
    }

    function setMaxAllowed(uint256 _allowed) external onlyAllowed {
        maxAllowed = _allowed;
    }

    function setMintPrice(bytes32 _key, uint256 _price) external onlyAllowed {
        mintPrices[_key] = _price;
        emit SetMintPrice(_price);
    }

    function setRevealed(bool _revealed) external onlyAllowed {
        require(revealed != _revealed, "You should set a different value");
        revealed = _revealed;
        emit Revealed(_revealed);
    }

    function setUnRevealedURI(string memory _uri) public onlyAllowed {
        unrevealedURI = _uri;
    }

    function setPreMint(bool _isPreMint) external onlyAllowed {
        isPreMint = _isPreMint;
    }

    function bracketOf(uint256 _tokenId) external view returns (uint256) {
        return dragonLevels[_tokenId];
    }

    function adminLevelUp(uint256[] calldata _dragonz) external onlyAllowed {
        for (uint256 index = 0; index < _dragonz.length; index++) {
            dragonLevels[_dragonz[index]] += 1;
        }
        emit LevelUpDragonz(_dragonz);
    }

    function levelUp(uint256 _tokenId, Ticket memory _ticket) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the owner of the token"
        );
        uint256 level = dragonLevels[_tokenId];
        bytes32 _digest = keccak256(
            abi.encode(TicketType.LevelUp, level, msg.sender)
        );
        require(isVerifiedTicket(_digest, _ticket));

        dragonLevels[_tokenId] += 1;
        emit LevelUpDragon(_tokenId);
    }

    function levelDown(uint256[] calldata _dragonz) external onlyAllowed {
        for (uint256 index = 0; index < _dragonz.length; index++) {
            dragonLevels[_dragonz[index]] -= 1;
        }
        emit LevelDownDragonz(_dragonz);
    }

    function burn(uint256 _tokenId, Ticket memory _ticket) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the owner of the token"
        );
        bytes32 _digest = keccak256(
            abi.encode(TicketType.Burn, _tokenId, msg.sender)
        );
        require(isVerifiedTicket(_digest, _ticket));
        super._burn(_tokenId);
    }

    function getIncrementer(bytes32 key) external view returns (uint256) {
        return tokenIncrementer[key];
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }
}