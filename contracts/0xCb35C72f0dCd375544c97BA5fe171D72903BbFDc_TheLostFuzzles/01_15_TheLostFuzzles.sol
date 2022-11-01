// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TheLostFuzzles is
    ERC721,
    ERC721Enumerable,
    IERC2981,
    Ownable,
    Pausable
{
    using Strings for uint256;
    using Address for address payable;

    enum Entity {
        AIRDROP,
        TREASURY,
        PUBLIC
    }

    string private constant BASE_URI =
        "ipfs://QmSJ3fwcSh1DcsYdArsHqR4ECDtVgHoA4HCUAxNmuacfMx/";
    uint256 private constant TOTAL_MAX_SUPPLY = 5000;
    uint256 private constant AIRDROP_MAX = 500;
    uint256 private constant TREASURY_MAX = 300;
    uint256 private constant PUBLIC_MAX = 4200;

    uint256 public royaltyFee;
    address public royaltyRecipient;
    bytes9 private _randomness;

    mapping(Entity => uint256) public supplyTracker;
    mapping(address => bool) private _authorized;
    mapping(uint256 => uint256) private _randomForwarder;

    event onMint(
        address indexed beneficiary,
        uint256[] tokenIds,
        uint8 quantity,
        uint256 randomNum,
        uint256 timestamp
    );

    constructor(address _royaltyRecipient)
        ERC721("The Lost Fuzzles", "TLFUZZ")
    {
        royaltyFee = 500; // 5% in basis points
        royaltyRecipient = _royaltyRecipient;
    }

    modifier onlyAuthorized() {
        _checkOnlyAuthorized();
        _;
    }

    modifier updateRandomness() {
        bytes32 randomness = _randomness;
        assembly {
            // Pick any of the last 256 blocks psuedorandomly for the blockhash.
            // Store the blockhash, the current `randomness` and the `coinbase()`
            // into the scratch space.
            mstore(0x00, blockhash(sub(number(), add(1, byte(0, randomness)))))
            // `randomness` is left-aligned.
            // `coinbase()` is right-aligned.
            // `difficulty()` is right-aligned.
            // After the merge, if [EIP-4399](https://eips.ethereum.org/EIPS/eip-4399)
            // is implemented, the randomness will be determined by the beacon chain.
            mstore(0x20, xor(randomness, xor(coinbase(), difficulty())))
            // Compute the new `randomness` by hashing the scratch space.
            randomness := keccak256(0x00, 0x40)
        }
        _randomness = bytes9(randomness);
        _;
    }

    function airdrop(address beneficiary, uint8 quantity)
        external
        onlyAuthorized
        whenNotPaused
    {
        if (msg.sender == owner()) {
            require(
                supplyTracker[Entity.TREASURY] < TREASURY_MAX,
                "TREASURY all received"
            );
            uint256 remaining = TREASURY_MAX - supplyTracker[Entity.TREASURY];
            require(remaining >= quantity, "not enough TREASURY supply");
            supplyTracker[Entity.TREASURY] += quantity;
        } else {
            require(
                supplyTracker[Entity.AIRDROP] < AIRDROP_MAX,
                "AIRDROP all received"
            );
            uint256 remaining = AIRDROP_MAX - supplyTracker[Entity.AIRDROP];
            require(remaining >= quantity, "not enough AIRDROP supply");
            supplyTracker[Entity.AIRDROP] += quantity;
        }

        _mintTLFUZZ(beneficiary, quantity);
    }

    function mint(address beneficiary, uint8 quantity)
        external
        payable
        onlyAuthorized
        whenNotPaused
    {
        require(
            supplyTracker[Entity.PUBLIC] < PUBLIC_MAX,
            "PUBLIC all received"
        );
        uint256 remaining = PUBLIC_MAX - supplyTracker[Entity.PUBLIC];
        require(remaining >= quantity, "not enough PUBLIC supply");
        supplyTracker[Entity.PUBLIC] += quantity;

        _mintTLFUZZ(beneficiary, quantity);
    }

    function _mintTLFUZZ(address beneficiary, uint8 quantity)
        internal
        updateRandomness
    {
        uint256 remaining = TOTAL_MAX_SUPPLY - totalSupply();
        require(remaining >= quantity, "not enough supply");

        uint256[] memory newTokenIds = new uint256[](quantity);
        uint256 randomNum = getRandomness();

        for (uint256 i = 0; i < quantity; ) {
            uint256 newId = (randomNum % remaining);
            uint256 newTokenId = _randomForwarder[newId] > 0
                ? _randomForwarder[newId]
                : newId;

            _randomForwarder[newId] = _randomForwarder[remaining - 1] > 0
                ? _randomForwarder[remaining - 1]
                : remaining - 1;

            _safeMint(beneficiary, newTokenId);

            newTokenIds[i] = newTokenId;

            remaining--;

            unchecked {
                ++i;
            }
        }

        emit onMint(
            beneficiary,
            newTokenIds,
            quantity,
            randomNum,
            block.timestamp
        );
    }

    function getRandomness() public view returns (uint256) {
        return uint256(keccak256(abi.encode(_randomness, address(this))));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Throws if the sender is not the authorized.
     */
    function _checkOnlyAuthorized() internal view virtual {
        require(
            _authorized[msg.sender] || owner() == msg.sender,
            "not authorized"
        );
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(IERC721, ERC721)
        returns (bool isOperator)
    {
        // OpenSea whitelisting
        if (operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(owner, operator);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        return (royaltyRecipient, (salePrice * royaltyFee) / 10_000);
    }

    function setRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "newRecipient is empty");
        royaltyRecipient = newRecipient;
    }

    function setRoyaltyFee(uint256 newRotaltyFee) external onlyOwner {
        require(newRotaltyFee != 0, "newRotaltyFee is zero");
        royaltyFee = newRotaltyFee;
    }

    function addAuthorized(address authorized) external onlyOwner {
        require(authorized != address(0), "authorized is empty");
        _authorized[authorized] = true;
    }

    function removeAuthorized(address authorized) external onlyOwner {
        require(authorized != address(0), "authorized is empty");
        _authorized[authorized] = false;
    }
}