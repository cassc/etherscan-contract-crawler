// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract KeepersOfTheInn is ERC721, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    uint256 public maxPerTransaction = 20;
    uint256 public maxPerWalletPresale = 20;
    uint256 public price = 0.09 ether;

    uint256 public constant SUPPLY = 3356;
    uint256 public constant GIFT_SUPPLY = 60;
    uint256 public constant PRESALE_SUPPLY = 2000;

    string public _baseTokenURI;
    string public provenance;

    enum SaleState {
        CLOSED,
        PRESALE,
        OPEN
    }

    SaleState saleState = SaleState.CLOSED;

    address private buenoWallet = 0xc358522c2eb462e4886F4c5a53e5e380a616b63A;
    address private signer = address(0);

    event Mint(address purchaser, uint256 amount);
    event SaleStateChange(SaleState newState);

    constructor() ERC721("Keepers of the Inn", "KEEPER") {}

    function mint(uint256 qty) public payable {
        require(saleState == SaleState.OPEN, "SALE_INACTIVE");
        require(qty <= maxPerTransaction, "TOO_MANY_TOKENS");
        require((_tokenId.current() + qty) <= SUPPLY, "SOLD_OUT");
        require(msg.value == price * qty, "INVALID_PRICE");

        for (uint256 i = 0; i < qty; i++) {
            _tokenId.increment();
            _safeMint(msg.sender, _tokenId.current());
        }

        emit Mint(msg.sender, qty);
    }

    /**
     * @dev Presale for verified wallets, max supply of 1000
     */
    function mintPresale(uint256 qty, bytes memory signature) public payable {
        require(saleState == SaleState.PRESALE, "SALE_INACTIVE");
        require(qty <= maxPerTransaction, "TOO_MANY_TOKENS");
        require((_tokenId.current() + qty) <= PRESALE_SUPPLY, "SOLD_OUT");
        require(
            balanceOf(msg.sender) + qty <= maxPerWalletPresale,
            "MAX_PER_WALLET"
        );
        require(msg.value == price * qty, "INVALID_PRICE");
        bytes32 messageHash = keccak256(abi.encode(msg.sender));
        require(verify(messageHash, signature), "INVALID_SIGNATURE");

        for (uint256 i = 0; i < qty; i++) {
            _tokenId.increment();
            _safeMint(msg.sender, _tokenId.current());
        }

        emit Mint(msg.sender, qty);
    }

    /**
     * @dev 16 tokens reserved for gifting to the community wallet
     */
    function gift(address receiver, uint256 qty) external onlyOwner {
        require(_tokenId.current() + qty <= GIFT_SUPPLY, "INVALID_QUANTITY");

        for (uint256 i = 0; i < qty; i++) {
            _tokenId.increment();
            _safeMint(receiver, _tokenId.current());
        }
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenId.current();
    }

    function verify(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        require(signer != address(0), "INVALID_SYSTEM_ADDRESS");
        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == signer;
    }

    /**
     * @notice This is an unoptimized implementation of ERC721Enumerable::tokenOfOwnerByIndex
     * The lookup data structure is unoptimized to save gas fees on minting. it should not be used in contract-to-contract calls
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256 tokenId)
    {
        require(index <= balanceOf(owner), "Index out of bounds");
        uint256 s = totalSupply();
        uint256 currIdx = 1;
        for (uint256 i = 1; i <= s; i++) {
            if (owner == ownerOf(i)) {
                if (currIdx == index) return i;
                else currIdx++;
            }
        }
        require(false, "Owner does not have the token with the given index");
    }

    /**
     * @notice View only mechanism to retrieve all owned tokens for a given address
     */
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        require(0 < balanceOf(owner), "Owner has no tokens");
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i + 1);
        }
        return tokenIds;
    }

    /**
     * @dev Sets sale state to CLOSED (0), PRESALE (1), or OPEN (2).
     */
    function setSaleState(uint8 _state) public onlyOwner {
        saleState = SaleState(_state);
        emit SaleStateChange(saleState);
    }

    function getSaleState() public view returns (uint8) {
        return uint8(saleState);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setProvenanceHash(string calldata hash) external onlyOwner {
        provenance = hash;
    }

    function withdraw() external onlyOwner {
        payable(buenoWallet).transfer((address(this).balance));
    }

    function setPerTransactionMax(uint256 limit) public onlyOwner {
        maxPerTransaction = limit;
    }

    function setPresalePerWalletLimit(uint256 limit) public onlyOwner {
        maxPerWalletPresale = limit;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }
}