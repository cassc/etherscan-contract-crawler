// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFC is ERC721, Ownable {
    uint256 public tokenId;
    string public unrevealedUri;
    string public revealedUri;
    address public signer;
    uint256 public maxSupply = 100;
    uint256 public price = 0.03 ether;
    uint256 public saleStart = 1677092400;
    mapping(uint256 => bool) public revealed;
    mapping(address => uint256) public purchases;

    constructor(
        address _owner,
        string memory _unrevealedUri,
        address _signer
    ) ERC721("NFC", "Cat's Causality Contract") {
        // mint 1 to owner
        _mint(_owner, tokenId);
        tokenId++;
        unrevealedUri = _unrevealedUri;
        signer = _signer;
        transferOwnership(_owner);
    }

    // * sale * //

    function forceActivate() public onlyOwner {
        saleStart = block.timestamp;
    }

    function purchaseNFT(uint256 amount) public payable {
        require(purchases[msg.sender] + amount <= 10, "Max 10 per address");
        require(block.timestamp >= saleStart, "Sale has not started");
        require(
            tokenId + amount <= maxSupply,
            "Purchase would exceed max supply"
        );
        require(msg.value >= price * amount, "Ether value sent is not correct");

        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, tokenId);
            tokenId++;
            purchases[msg.sender] += 1;
        }
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // * reveal process * //

    /// @dev owner can change or remove signer

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    /// @dev revealedUri is not conscious of token id. all images are the same

    function setRevealedUri(string memory _revealedUri) public onlySigner {
        revealedUri = _revealedUri;
    }

    /// @dev signer can reveal specific token when nfc is scanned

    function reveal(uint256 _tokenId) public onlySigner {
        revealed[_tokenId] = true;
    }

    /// @dev unrevealedUri is conscious of token id

    function setUnrevealedUri(string memory _uri) public onlySigner {
        unrevealedUri = _uri;
    }

    /// @dev owner or signer can relenquish signer role to owner

    function renounceSigner() public {
        require(
            msg.sender == signer || msg.sender == owner(),
            "only owner or signer"
        );
        signer = owner();
    }

    // * overrides * //

    /// @dev _baseURI is used for unrevealedUri because it appends token id

    function _baseURI() internal view override returns (string memory) {
        return unrevealedUri;
    }

    /// @dev if token is revealed, return revealedUri, otherwise return unrevealedUri

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (revealed[_tokenId]) {
            return revealedUri;
        } else {
            return super.tokenURI(_tokenId);
        }
    }

    // * utils * //

    modifier onlySigner() {
        require(msg.sender == signer, "only signer");
        _;
    }

    function isActive() public view returns (bool) {
        return block.timestamp >= saleStart;
    }
}