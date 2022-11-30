// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GITS is ERC721, ERC721Enumerable, AccessControl, ERC721Burnable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private constant BASE_URI = "https://ipfs.madworld.io/ghostintheshell/";
    address public constant PAYMENT_ADDRESS = 0x682DbEB158118C86987C2Ac6a8cC6e0b18a96f88;
    address public constant owner = 0x246cD0529fC31eCC5Bde42019b17322B11E2C73B;

    event TokenRedeemed(uint256 tokenId, bytes32 addressId);
    struct Drop {
        uint8 status;
        uint256 initTokenId;
        uint256 totalNum;
        uint256 maxPreWallet;
        uint256 maxPreWhiteList;
        bytes32 whiteListProofRoot;
        mapping(address => uint256) mintCount;
        uint256 tokenCounter;
    }
    struct Purchase {
        uint8 dropId;
        uint256 price;
        uint256 quantity;
        bytes32[] proof;
    }
    Drop[] public _drop;
    mapping(uint256 => bytes32) public _redeemAddress;

    constructor() ERC721("GITS", "GITS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        // Initialize the contract with the first Drop
        addDrop(1, 100001224706000001, 500, 0, 0, keccak256("0x0"));
        _grantRole(MINTER_ROLE, address(0xd3A94F0630329Ab9096826cC96F203a6709e1744));
    }

    function _baseURI() internal pure override returns (string memory) {
        return BASE_URI;
    }

    function getRedeemAddress(uint256 _tokenId) public view returns (bytes32) {
        return _redeemAddress[_tokenId];
    }

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(BASE_URI, "metadata.json"));
    }

    function addDrop(
        uint8 status,
        uint256 initTokenId,
        uint256 totalNum,
        uint256 maxPreWallet,
        uint256 maxPreWhiteList,
        bytes32 whiteListProofRoot
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Drop storage drop = _drop.push();
        drop.status = status;
        drop.initTokenId = initTokenId;
        drop.totalNum = totalNum;
        drop.maxPreWallet = maxPreWallet;
        drop.maxPreWhiteList = maxPreWhiteList;
        drop.whiteListProofRoot = whiteListProofRoot;
    }

    function setRoot(uint8 dropId, bytes32 whiteListProofRoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _drop[dropId].whiteListProofRoot = whiteListProofRoot;
    }

    function setStatus(uint8 dropId, uint8 status)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _drop[dropId].status = status;
    }

    function redeemToken(uint256 _tokenId, bytes32 _addressId) public {
        require(_exists(_tokenId), "GITS: Token not exist");
        require(ownerOf(_tokenId) == msg.sender, "GITS: Only owner can redeem");
        require(
            _redeemAddress[_tokenId] == bytes32(0),
            "GITS: Already redeemed"
        );
        _redeemAddress[_tokenId] = _addressId;
        emit TokenRedeemed(_tokenId, _addressId);
    }

    function buy(
        Purchase calldata data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        bytes32 payloadHash = keccak256(
            abi.encode(
                keccak256(
                    "mint(address receiver, uint256 price, uint256 quantity, uint8 dropId, uint chainId)"
                ),
                msg.sender,
                data.price,
                data.quantity,
                data.dropId,
                block.chainid
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash)
        );
        address addr = ecrecover(digest, v, r, s);
        require(hasRole(MINTER_ROLE, addr), "GITS: Invalid signer");
        Drop storage drop = _drop[data.dropId];
        require(drop.status > 0, "GITS: Drop not exist or not open");
        require(data.quantity > 0, "GITS: Quantity must be greater than 0");
        require(
            (drop.mintCount[msg.sender] + data.quantity) <= drop.maxPreWallet,
            "GITS: Reach Max Pre Wallet"
        );
        if (drop.status == 1) {
            require(
                (drop.mintCount[msg.sender] + data.quantity) <=
                    drop.maxPreWhiteList,
                "GITS: Reach Max Pre White List"
            );
            bytes32 leaf = keccak256(abi.encode(msg.sender));
            require(
                MerkleProof.verify(data.proof, drop.whiteListProofRoot, leaf),
                "GITS: Not in White List"
            );
        }

        require(msg.value >= data.price, "GITS: Invalid msg.value ");
        payable(PAYMENT_ADDRESS).transfer(msg.value);

        mintNew(data.dropId, msg.sender, data.quantity);
    }

    function safeMint(
        uint8 dropId,
        address to,
        uint256 quantity
    ) public onlyRole(MINTER_ROLE) {
        mintNew(dropId, to, quantity);
    }

    function mintNew(
        uint8 dropId,
        address to,
        uint256 quantity
    ) private {
        Drop storage drop = _drop[dropId];
        require(drop.status > 0, "GITS: Drop not exist or not open");
        require(
            (drop.tokenCounter + quantity) <= drop.totalNum,
            "GITS: Total Mint Num Reached"
        );
        for (uint256 index = 0; index < quantity; index++) {
            uint256 tokenId = drop.initTokenId + drop.tokenCounter;
            drop.tokenCounter++;
            drop.mintCount[to]++;
            _safeMint(to, tokenId);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
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