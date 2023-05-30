// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

struct PhaseSettings {
    uint64 maxSupply;
    uint64 maxPerWallet;
    uint64 freePerWallet;
    uint64 whitelistPerWallet;
    uint64 whitelistFreePerWallet;
    uint256 price;
    uint256 whitelistPrice;
}

struct Characters {
    uint64 male;
    uint64 flower;
    uint64 fox;
    uint64 demon;
    uint64 undeadGirl;
}

contract LoonySquad is
    ERC721AQueryable,
    DefaultOperatorFilterer,
    Ownable,
    ReentrancyGuard
{
    string public baseTokenURI;
    string[5] public unrevealedTokenURI;

    PhaseSettings public currentPhase;
    Characters public charactersLeft;

    bool public revealed = false;

    mapping(uint256 => uint256) public characterPerTokenId;

    bytes32 private _root;

    address t1 = 0x402351069CFF2F0324A147eC0a138a1C21491591;
    address t2 = 0x0566c0574c86d4826B16FCBFE01332956e3cf3aD;

    constructor() ERC721A("Loony Squad", "Loony") {
        charactersLeft = Characters(500, 800, 900, 600, 700);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function nonFreeAmount(
        address _owner,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 _freeAmountLeft = _numberMinted(_owner) >=
            currentPhase.freePerWallet
            ? 0
            : currentPhase.freePerWallet - _numberMinted(_owner);

        return _freeAmountLeft >= _amount ? 0 : _amount - _freeAmountLeft;
    }

    function whitelistNonFreeAmount(
        address _owner,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 _freeAmountLeft = _numberMinted(_owner) >=
            currentPhase.whitelistFreePerWallet
            ? 0
            : currentPhase.whitelistFreePerWallet - _numberMinted(_owner);

        return _freeAmountLeft >= _amount ? 0 : _amount - _freeAmountLeft;
    }

    function characterOf(uint256 _tokenId) public view returns (uint256) {
        return characterPerTokenId[_tokenId];
    }

    /**
     * @notice _characters Array of characters to mint where
     *  _characters[0] - male,
     *  _characters[1] - flower,
     *  _characters[2] - fox,
     *  _characters[3] - demon,
     *  _characters[4] - undeadGirl
     */
    function whitelistMint(
        uint8[] memory _characters,
        bytes32[] memory _proof
    ) public payable {
        verify(_proof);

        uint256 _amount = _totalAmount(_characters);
        uint256 _nonFreeAmount = whitelistNonFreeAmount(msg.sender, _amount);

        require(
            _nonFreeAmount == 0 ||
                msg.value >= currentPhase.whitelistPrice * _nonFreeAmount,
            "Ether value sent is not correct"
        );

        require(
            _numberMinted(msg.sender) + _amount <=
                currentPhase.whitelistPerWallet,
            "Exceeds maximum tokens at address"
        );

        mint(_characters);
    }

    /**
     * @notice _characters Array of characters to mint where
     *  _characters[0] - male,
     *  _characters[1] - flower,
     *  _characters[2] - fox,
     *  _characters[3] - demon,
     *  _characters[4] - undeadGirl
     */
    function publicMint(uint8[] memory _characters) public payable {
        uint256 _amount = _totalAmount(_characters);
        uint256 _nonFreeAmount = nonFreeAmount(msg.sender, _amount);

        require(
            _nonFreeAmount == 0 ||
                msg.value >= currentPhase.price * _nonFreeAmount,
            "Ether value sent is not correct"
        );

        require(
            _numberMinted(msg.sender) + _amount <= currentPhase.maxPerWallet,
            "Exceeds maximum tokens at address"
        );

        mint(_characters);
    }

    function mint(uint8[] memory _characters) private {
        uint256 _amount = _totalAmount(_characters);

        require(
            _totalMinted() + _amount <= currentPhase.maxSupply,
            "Exceeds maximum supply"
        );

        require(
            charactersLeft.male >= _characters[0] &&
                charactersLeft.flower >= _characters[1] &&
                charactersLeft.fox >= _characters[2] &&
                charactersLeft.demon >= _characters[3] &&
                charactersLeft.undeadGirl >= _characters[4],
            "Exceeds maximum supply of character"
        );

        _safeMint(msg.sender, _amount);
        _reduceCharactersLeft(_characters);
        _setCharacterPerTokenId(_characters);
    }

    /**
     * @notice _characters Array of characters to mint where
     *  _characters[0] - male,
     *  _characters[1] - flower,
     *  _characters[2] - fox,
     *  _characters[3] - demon,
     *  _characters[4] - undeadGirl
     */
    function airdrop(uint8[] memory _characters, address _to) public onlyOwner {
        uint256 _amount = _totalAmount(_characters);

        require(
            _totalMinted() + _amount <= currentPhase.maxSupply,
            "Exceeds maximum supply"
        );

        require(
            charactersLeft.male >= _characters[0] &&
                charactersLeft.flower >= _characters[1] &&
                charactersLeft.fox >= _characters[2] &&
                charactersLeft.demon >= _characters[3] &&
                charactersLeft.undeadGirl >= _characters[4],
            "Exceeds maximum supply of character"
        );

        _safeMint(_to, _amount);

        _reduceCharactersLeft(_characters);
        _setCharacterPerTokenId(_characters);
    }

    function _totalAmount(
        uint8[] memory _characters
    ) private pure returns (uint256) {
        uint256 _amount = 0;

        for (uint8 i = 0; i < _characters.length; i++) {
            _amount += _characters[i];
        }

        return _amount;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setUnrevealedTokenURI(
        string memory _male,
        string memory _flower,
        string memory _fox,
        string memory _demon,
        string memory _undeadGirl
    ) public onlyOwner {
        unrevealedTokenURI = [_male, _flower, _fox, _demon, _undeadGirl];
    }

    function setPhase(
        uint64 _maxSupply,
        uint64 _maxPerWallet,
        uint64 _freePerWallet,
        uint64 _whitelistPerWallet,
        uint64 _whitelistFreePerWallet,
        uint256 _price,
        uint256 _whitelistPrice
    ) public onlyOwner {
        currentPhase = PhaseSettings(
            _maxSupply,
            _maxPerWallet,
            _freePerWallet,
            _whitelistPerWallet,
            _whitelistFreePerWallet,
            _price,
            _whitelistPrice
        );
    }

    function setCharactersLeft(
        uint64 _male,
        uint64 _flower,
        uint64 _fox,
        uint64 _demon,
        uint64 _undeadGirl
    ) public onlyOwner {
        charactersLeft = Characters(_male, _flower, _fox, _demon, _undeadGirl);
    }

    function setRoot(bytes32 root) public onlyOwner {
        _root = root;
    }

    function setRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 _balance = address(this).balance / 100;

        require(payable(t1).send(_balance * 12));
        require(payable(t2).send(_balance * 88));
    }

    function _reduceCharactersLeft(uint8[] memory _characters) private {
        charactersLeft = Characters(
            charactersLeft.male - _characters[0],
            charactersLeft.flower - _characters[1],
            charactersLeft.fox - _characters[2],
            charactersLeft.demon - _characters[3],
            charactersLeft.undeadGirl - _characters[4]
        );
    }

    function _setCharacterPerTokenId(uint8[] memory _characters) private {
        uint256 _startId = _nextTokenId() - _totalAmount(_characters);

        for (uint8 i = 0; i < _characters.length; i++) {
            for (uint8 j = 0; j < _characters[i]; j++) {
                characterPerTokenId[_startId + j] = i;
            }
            _startId += _characters[i];
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function verify(bytes32[] memory _proof) private view {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender)))
        );
        require(MerkleProof.verify(_proof, _root, leaf), "Invalid proof");
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (revealed) {
            return
                bytes(baseTokenURI).length != 0
                    ? string(abi.encodePacked(baseTokenURI, _toString(tokenId)))
                    : "";
        }

        return unrevealedTokenURI[characterPerTokenId[tokenId]];
    }
}