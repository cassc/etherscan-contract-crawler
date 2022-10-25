// SPDX-License-Identifier: GPL-3.0

// ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
// █░░░░░░░░░░░░░░█░░░░░░██░░░░░░█░░░░░░░░░░░░░░████░░░░░░██░░░░░░█░░░░░░░░░░░░░░█░░░░░░██████████░░░░░░█░░░░░░░░░░░░██████░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█
// █░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░████░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░░░░░░░░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀░░░░████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█
// █░░░░░░▄▀░░░░░░█░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░░░░░████░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░██░░▄▀░░█░░▄▀░░░░▄▀▄▀░░████░░░░░░░░░░▄▀░░█░░░░░░░░░░▄▀░░█░░▄▀░░░░░░░░░░█░░░░░░░░░░▄▀░░█
// █████░░▄▀░░█████░░▄▀░░██░░▄▀░░█░░▄▀░░████████████░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░████████████░░▄▀░░█████████░░▄▀░░█░░▄▀░░█████████████████░░▄▀░░█
// █████░░▄▀░░█████░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░░░░░████░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░██░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░████████████░░▄▀░░█░░░░░░░░░░▄▀░░█░░▄▀░░░░░░░░░░█████████░░▄▀░░█
// █████░░▄▀░░█████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░████████████░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█████████░░▄▀░░█
// █████░░▄▀░░█████░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░░░░░████░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░██░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░████████████░░▄▀░░█░░▄▀░░░░░░░░░░█░░░░░░░░░░▄▀░░█████████░░▄▀░░█
// █████░░▄▀░░█████░░▄▀░░██░░▄▀░░█░░▄▀░░████████████░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░░░░░▄▀░░█░░▄▀░░██░░▄▀░░████████████░░▄▀░░█░░▄▀░░█████████████████░░▄▀░░█████████░░▄▀░░█
// █████░░▄▀░░█████░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░░░░░████░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░░░▄▀▄▀░░████████████░░▄▀░░█░░▄▀░░░░░░░░░░█░░░░░░░░░░▄▀░░█████████░░▄▀░░█
// █████░░▄▀░░█████░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░████░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░██░░░░░░░░░░▄▀░░█░░▄▀▄▀▄▀▄▀░░░░████████████░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█████████░░▄▀░░█
// █████░░░░░░█████░░░░░░██░░░░░░█░░░░░░░░░░░░░░████░░░░░░██░░░░░░█░░░░░░██░░░░░░█░░░░░░██████████░░░░░░█░░░░░░░░░░░░██████████████░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█████████░░░░░░█
// ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract THEHAND7257 is
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    ReentrancyGuard
{
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        SET_BASE_URI(_initBaseURI);
        ROYALTY_INFO(OWNER, RBPS);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
        onlyOwner
    {
        super._burn(tokenId);
    }

    function contractURI() public view returns (string memory) {
        return URI;
    }

    function setContractURI(string calldata _uri) public onlyOwner {
        URI = _uri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function UPDATE_ROOT(bytes32 _root) public onlyOwner {
        ROOT = _root;
    }

    function SET_BASE_URI(string memory _newBaseURI) public onlyOwner {
        BASE_URI = _newBaseURI;
    }

    function SET_EXTENSION(string memory _newBaseExtension) public onlyOwner {
        EXT = _newBaseExtension;
    }

    function UPDATE_TOKEN_URI(uint256 tokenid, string memory newURI)
        public
        onlyOwner
    {
        _setTokenURI(tokenid, newURI);
    }

    function PAUSE_MINT(bool _state) public onlyOwner {
        PAUSED = _state;
    }

    function REFUND_TOKEN(uint256 tokenid) public onlyOwner {
        THEREFUNDED[tokenid] = 1;
    }

    function UPP(uint256 _nP) public onlyOwner {
        PP = _nP;
    }

    function UPP2(uint256 _nP) public onlyOwner {
        PP2 = _nP;
    }

    function UPP3(uint256 _nP) public onlyOwner {
        PP3 = _nP;
    }

    function SET_PRICES_PUBLIC(
        uint256 _nP,
        uint256 _nP2,
        uint256 _nP3
    ) public onlyOwner {
        PP = _nP;
        PP2 = _nP2;
        PP3 = _nP3;
    }

    function UPPRP(uint256 _nP) public onlyOwner {
        PRP = _nP;
    }

    function UPPRP2(uint256 _nP) public onlyOwner {
        PRP2 = _nP;
    }

    function UPPRP3(uint256 _nP) public onlyOwner {
        PRP3 = _nP;
    }

    function setPricesPrivate(
        uint256 _nP,
        uint256 _nP2,
        uint256 _nP3
    ) public onlyOwner {
        PRP = _nP;
        PRP2 = _nP2;
        PRP3 = _nP3;
    }

    function setPublic(bool _truefalse) public onlyOwner {
        PUBLIC = _truefalse;
    }

    function setPrivate(bool _truefalse) public onlyOwner {
        PRIVATE = _truefalse;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();

        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(currentBaseURI, tokenId.toString(), EXT)
                )
                : "";
    }

    function VERIFY_WL(address _sender, bytes32[] calldata merkletree)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_sender));
        return MerkleProof.verify(merkletree, ROOT, leaf);
    }

    // Private minting: 1 Hand, 2 or 3: SAVE UP TO 10%. CHECK PRICES
    function MintPrivateSmart(uint256 _amount, bytes32[] calldata SealedProof)
        public
        payable
    {
        uint256 s = totalSupply();

        require(PAUSED == false, "Mint is paused atm!");
        require(PRIVATE == true, "Private mint is off!");
        require(_amount <= MAX_PRIVATE, "Amount not allowed!");
        require(balanceOf(msg.sender) <= MAX_PRIVATE - _amount, "Mint less!");
        require(s + _amount <= MAX_SUPPLY, "Exceeded max allowed [CTR]!");
        require(
            VERIFY_WL(msg.sender, SealedProof),
            "Wallet not approved for the private sale."
        );

        uint256 RP;

        if (_amount == 1) RP = PRP;
        if (_amount == 2) RP = PRP2;
        if (_amount == 3) RP = PRP3;

        if (msg.sender != owner()) require(msg.value >= RP, "Wrong ETH input!");

        for (uint256 i = 0; i < _amount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
        delete RP;
    }

    // Public minting: 1 Hand, 2 or 3: SAVE UP TO 10%. CHECK PRICES
    function MintPublicSmart(uint256 _amount) public payable {
        uint256 s = totalSupply();

        require(PAUSED == false, "Mint is paused atm!");
        require(PUBLIC == true, "Public mint is off!");
        require(_amount <= MAX_PRIVATE, "Amount not allowed!");
        require(balanceOf(msg.sender) <= MAX_PUBLIC - _amount, "Mint less!");
        require(s + _amount <= MAX_SUPPLY, "Exceeded max allowed [CTR]!");

        uint256 RP;

        if (_amount == 1) RP = PP;
        if (_amount == 2) RP = PP2;
        if (_amount == 3) RP = PP3;

        require(msg.value >= RP, "Wrong ETH input!");

        for (uint256 i = 0; i < _amount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
        delete RP;
    }

    function gift(uint256[] calldata gifts, address[] calldata recipient)
        external
        onlyOwner
    {
        require(gifts.length == recipient.length);
        uint256 g = 0;
        uint256 s = totalSupply();
        for (uint256 i = 0; i < gifts.length; ++i) {
            g += gifts[i];
        }
        require(s + g <= MAX_SUPPLY, "Exceeded max allowed!");
        delete g;
        for (uint256 i = 0; i < recipient.length; ++i) {
            for (uint256 j = 0; j < gifts[i]; ++j) {
                _safeMint(recipient[i], s++, "");
            }
        }
        delete s;
    }

    function isPublic() public view returns (bool) {
        return PUBLIC;
    }

    function isPrivate() public view returns (bool) {
        return PRIVATE;
    }

    function isPaused() public view returns (bool) {
        return PAUSED;
    }

    function getRoot() public view returns (bytes32) {
        return ROOT;
    }

    function getPrivate() public view returns (uint256) {
        return PRP;
    }

    function getPrivate2() public view returns (uint256) {
        return PRP2;
    }

    function getPrivate3() public view returns (uint256) {
        return PRP3;
    }

    function getPublic() public view returns (uint256) {
        return PP;
    }

    function getPublic2() public view returns (uint256) {
        return PP2;
    }

    function getPublic3() public view returns (uint256) {
        return PP3;
    }

    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * RBPS;
    }

    function ROYALTY_INFO(address _o, uint96 _rB) public onlyOwner {
        OWNER = _o;
        RBPS = _rB;
    }

    function royaltyInfo(uint256 _salePrice)
        external
        view
        returns (
            address receiver,
            uint256 royaltyAmount //uint256 _tokenId,
        )
    {
        return (OWNER, calculateRoyalty(_salePrice));
    }

    uint256 public MAX_SUPPLY = 7257;
    uint256 public MAX_PRIVATE = 3;
    uint256 public MAX_PUBLIC = 3;

    bytes32 public ROOT;
    string public BASE_URI;
    string public EXT = ".json";

    bool public PAUSED = false;
    bool public PUBLIC = false;
    bool public PRIVATE = true;

    uint256 private PRP = 0.257 ether;
    uint256 private PRP2 = 0.488 ether;
    uint256 private PRP3 = 0.694 ether;
    uint256 private PP = 0.357 ether;
    uint256 private PP2 = 0.678 ether;
    uint256 private PP3 = 0.964 ether;

    mapping(uint256 => uint256) public THEREVEALED;
    mapping(uint256 => uint256) public THEREFUNDED;

    address public OWNER = 0x62ee7062080D8Ce23Ae4A03a34Cd00c62f077385;
    uint96 public RBPS = 500;
    string public URI;

    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;
}