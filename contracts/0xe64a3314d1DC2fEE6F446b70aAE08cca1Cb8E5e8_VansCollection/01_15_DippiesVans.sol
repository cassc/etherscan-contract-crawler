// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract VansCollection is ERC721A, ERC2981, Ownable {
    using Strings for uint256;

    IERC721Enumerable constant DIPPIES_CONTRACT = IERC721Enumerable(0x82F5eF9dDC3D231962Ba57A9c2eBb307Dc8d26c2);
    uint256 constant ALLOW_LIST_PRICE = 0.08 ether;
    uint256 constant MINT_PRICE = 0.1 ether;
    uint256 constant CLAIM_SUPPLY = 8888;
    uint256 constant MINT_SUPPLY = 5000;
    uint256 constant MAX_SUPPLY = CLAIM_SUPPLY + MINT_SUPPLY;
    uint256 constant MAX_PER_ALLOW_LIST = 1;
    uint256 constant MAX_PER_TRANSACTION = 1;

    address private _signer = 0xEb30a3D891245b2b8EF01A56A068D866FC64D758;
    uint256 private _reservedTeamTokens;
    bool private _isRevealed;

    enum Status {
        NOT_LIVE,
        PRESALE,
        LIVE,
        CLAIM,
        ENDED
    }

    // minting variables
    string public baseURI;
    Status public state;
    uint256 public mintCount;
    uint256 public claimCount;
    
    mapping(bytes32 => bool) _nonces;
    mapping(uint256 => bool) _vanClaimedByDippie;

    constructor() ERC721A("Vans Collection", "VANS") { 
        _safeMint(address(this), 1);
        _burn(0);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity, bytes calldata signature, bytes32 nonce) external payable {
        require(state == Status.LIVE || state == Status.PRESALE, "Vans: Mint Not Active");
        require(msg.sender == tx.origin, "Vans: Contract Interaction Not Allowed");
        require(ECDSA.recover(keccak256(abi.encodePacked(msg.sender, quantity, nonce)), signature) == _signer, "Vans: Invalid Signer");
        require(quantity <= MAX_PER_TRANSACTION, "Vans: Max 1 Per Transaction");
        require(totalSupply() + quantity <= MINT_SUPPLY, "Vans: Mint Supply Exceeded");
        require(msg.value >= (quantity * (state == Status.LIVE ? MINT_PRICE : ALLOW_LIST_PRICE)), "Vans: Insufficient ETH");

        if(state == Status.PRESALE) {
            require(_numberMinted(msg.sender) + quantity <= MAX_PER_ALLOW_LIST, "Vans: Exceeds Max Per Wallet");
        } else {
            require(!_nonces[nonce], "Vans: Nonce Already Used");
            _nonces[nonce] = true;
        }

        mintCount += quantity;
        _safeMint(msg.sender, quantity);
    }

    function claim() external {
        require(state == Status.CLAIM, "Vans: Claim Is Not Live");
        require(msg.sender == tx.origin, "Vans: Contract Interaction Not Allowed");

        uint256 vanCount;

        for (uint256 i; i < DIPPIES_CONTRACT.balanceOf(msg.sender); i++) {
            uint256 tokenId = DIPPIES_CONTRACT.tokenOfOwnerByIndex(msg.sender, i);
            
            if (!_vanClaimedByDippie[tokenId]) {
                _vanClaimedByDippie[tokenId] = true;
                vanCount++;
            }
        }

        claimCount += vanCount;
        _safeMint(msg.sender, vanCount);
    }

    function amountClaimable(address _address) external view returns (uint256) {
        uint256 dippiesClaimable;

        for (uint256 i; i < DIPPIES_CONTRACT.balanceOf(_address); i++) {
            uint256 tokenId = DIPPIES_CONTRACT.tokenOfOwnerByIndex(_address, i);
            
            if (!_vanClaimedByDippie[tokenId]) dippiesClaimable++;
        }

        return dippiesClaimable;
    }

    function dippieBalanceView(address _address) external view returns (uint256) {
        return DIPPIES_CONTRACT.balanceOf(_address);
    }

    function setBaseURI(string memory _newBaseURI, bool _revealed) external onlyOwner {
        baseURI = _newBaseURI;

        _isRevealed = _revealed;
    }

    function setSigner(address _newSigner) external onlyOwner {
        _signer = _newSigner;
    }

    function setState(Status _state) external onlyOwner {
        state = _state;
    }

    function sendRemainingToTreasury(uint256 _qty) external onlyOwner {
        require(state == Status.ENDED, "Vans: Cannot Claim Unminted Tokens If Sale Live");
        require(totalSupply() + _qty <= MAX_SUPPLY, "Vans: Total Supply Minted");

        _safeMint(0xC1433f0D731a30F5DCbBDd3Bbb8E72b538FFb9bC, _qty);
    }

    function reserveTeamTokens(uint256 quantity) external onlyOwner {
        require(_reservedTeamTokens + quantity <= 150, "Dippies: Team Tokens Already Minted");
        _reservedTeamTokens += quantity;
        mintCount += quantity;
        _safeMint(0xC1433f0D731a30F5DCbBDd3Bbb8E72b538FFb9bC, quantity);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!_isRevealed) return _baseURI();
        return string(abi.encodePacked(_baseURI(), "/", _tokenId.toString(), ".json"));
    }

    /*
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(0x3428baB379a1D3091653938338d4BBB8b4B07547).transfer(balance * 3 / 10);
        payable(0x64BC86B593C9F0F371D98660F9579507F442e6C9).transfer(balance * 3 / 10);
        payable(0xC1433f0D731a30F5DCbBDd3Bbb8E72b538FFb9bC).transfer(balance * 39 / 200);
        payable(0x2795033F658E8E2a8DeB1A28C7c65d743aA3154C).transfer(balance * 3 / 40);
        payable(0x249C406f08C79c3220c3D401B77e7155fD706021).transfer(balance * 1 / 20);
        payable(0xaAA217e121433F6482f78371910930FC1AcA226b).transfer(balance * 1 / 20);
        payable(0xEc53FDe80883708751B57DeC6914B12F12147a3b).transfer(address(this).balance);
    }
}