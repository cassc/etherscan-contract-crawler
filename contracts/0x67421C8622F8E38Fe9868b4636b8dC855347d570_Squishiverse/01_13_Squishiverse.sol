// Squishiverse by FourLeafClover (www.squishiverse.com)

// MMMMMW0dxxxdkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMM0cdKNNKloXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMKolk00kloXMWNK0KKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMXkxxddkXWKdoddxxxxkOKXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMWWMMMXllO000KKKOkxxxxkkkkkkkkkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMKccO000000KKXNNNNNNNXXXK0OkkkkkkOKNMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMN0xocck0000000000KKKKXXXNNNNWWWWNX0kkkkOKWMMMMMMMMMMMMMMMMM
// MMMMMMMMWXkoodkOOO00000000000000000000KKXXNNWWWMWXOxxk0NMMMMMMMMMMMMMM
// MMMMMMWKxlokO000000000000000000000000000000KXWMMMMMMN0kxkKWMMMMMMMMMMM
// MMMMMXxlok0000000000000000000000000000000000KNMMMMMMMMMN0xxONMMMMMMMMM
// MMMW0ook0000000000000000000000000000000000000XWMMMMMMMMMMWKxdONMMMMMMM
// MMWkldO000000000000000000000000000000000000000KXNWMMWNNWMMMWKxd0WMMMMM
// MNxcx00000000000000000000000000000000000000000000KXOc,':ONWWMW0dkNMMMM
// Wkcd0000000000000000Oo;,:dO00000000000000000000000d.    .oXWWMMXxdKMMM
// KloO000000000000000k;    .:k000000000000000000000O:    ;'.dNNWWMNxoKMM
// dck000000000000000Oc    '..lO00000000000000000000O:       ;KNNWWMNxoXM
// lo0000000000000000x'   .:;.;k00000000000000000000Ol.      'ONNNWWMXdxN
// cd0000000000000000x'       ,k000000000000000000000x'      .xNNNNWWM0o0
// cd0000000000000000x'       ;O000000000000000000000Oo.     ;kXNNNNWMNdd
// cd0000000000000000k;      .lO0000000000000000000000Od:'.,ck0KXNNNWWWko
// olO0000000000000000d'     'x000000000000000O0000000000Okxk000XNNNNWMOl
// kcx00000000000000000x:...;xOOxkO00000OOxolc::cclooodolccok000KNNNNWMOl
// XolO00000000000000000OkkkO00kollccclcc:;,,;;;;,,,,,'.,lk00000KNNNNWMko
// M0loO0000000000000000000000000Oko:,''',,,,,,,,,,,;;:okO000000KNNNNWWxd
// MWOloO000000000000000000000000000OkkxdddddddoodddxkO000000000XNNNWMKoO
// MMW0lok00000000000000000000000000000000000000000000000000000KXNNWWNddN
// MMMMXdlxO000000000000000000000000000000000000000000000000000XNNNWNxdXM
// MMMMMWOolxO000000000000000000000000000000000000000000000000KNNNWKxdKMM
// MMMMMMMNOoldO000000000000000000000000000000000000000000000KNNNXkdkNMMM
// MMMMMMMMMN0dooxO00000000000000000000000000000000000000000KXKkxdkXWMMMM
// MMMMMMMMMMMWXOxdooxkO0000000000000000000000000000000Okxxdxxxk0NMMMMMMM
// MMMMMMMMMMMMMMMNKOxdddoooddxxxxkkkkkkkxxxxxddddoooodddxkOKNWMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWNKOxdollccccccccccccccccllodxk0KNWMMMMMMMMMMMMMMMM

// Development help from @lozzereth (www.allthingsweb3.com)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract Squishiverse is ERC721A, Ownable {
    uint256 public constant MINT_PRICE = 0.065 ether;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MAX_PER_WALLET = 5;

    constructor() ERC721A("Squishiverse", "SQUISHIE") {}

    modifier hasCorrectAmount(uint256 _wei, uint256 _quantity) {
        require(_wei >= MINT_PRICE * _quantity, "Insufficent funds");
        _;
    }

    modifier withinMaximumSupply(uint256 _quantity) {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Surpasses supply");
        _;
    }

    /**
     * Public sale and whitelist sale mechansim
     */
    bool public publicSale = false;
    bool public whitelistSale = false;

    modifier publicSaleActive() {
        require(publicSale, "Public sale not started");
        _;
    }

    function setPublicSale(bool toggle) external onlyOwner {
        publicSale = toggle;
    }

    modifier whitelistSaleActive() {
        require(whitelistSale, "Whitelist sale not started");
        _;
    }

    function setWhitelistSale(bool toggle) external onlyOwner {
        whitelistSale = toggle;
    }

    /**
     * Public minting
     */
    mapping(address => uint256) public publicAddressMintCount;

    function mintPublic(uint256 _quantity)
        public
        payable
        publicSaleActive
        hasCorrectAmount(msg.value, _quantity)
        withinMaximumSupply(_quantity)
    {
        require(
            _quantity > 0 &&
                publicAddressMintCount[msg.sender] + _quantity <=
                MAX_PER_WALLET,
            "Minting above public limit"
        );
        publicAddressMintCount[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * Tiered whitelisting system
     */
    bytes32[5] public tieredWhitelistMerkleRoot;
    uint256[4] public tieredWhitelistMaximums = [1, 2, 3, 5];
    mapping(address => uint256) public whitelistAddressMintCount;
    mapping(address => uint256) public whitelistAddressCustomLimit;

    modifier hasValidTier(uint256 tier) {
        require(tier >= 0 && tier <= 4, "Invalid Tier");
        _;
    }

    modifier hasValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address not whitelisted"
        );
        _;
    }

    function setWhitelistMerkleRoot(uint256 tier, bytes32 merkleRoot)
        external
        onlyOwner
        hasValidTier(tier)
    {
        tieredWhitelistMerkleRoot[tier] = merkleRoot;
    }

    function setWhitelistAddressCustomLimit(address _address, uint256 _amount)
        external
        onlyOwner
    {
        whitelistAddressCustomLimit[_address] = _amount;
    }

    function mintWhitelist(
        uint256 _tier,
        uint256 _quantity,
        bytes32[] calldata merkleProof
    )
        public
        payable
        whitelistSaleActive
        hasValidTier(_tier)
        hasValidMerkleProof(merkleProof, tieredWhitelistMerkleRoot[_tier])
        hasCorrectAmount(msg.value, _quantity)
        withinMaximumSupply(_quantity)
    {
        // Mint according to the whitelisted tier limit, otherwise assume custom limit
        if (_tier <= 3) {
            require(
                _quantity > 0 &&
                    whitelistAddressMintCount[msg.sender] + _quantity <=
                    tieredWhitelistMaximums[_tier],
                "Minting above allocation"
            );
        } else {
            require(
                _quantity > 0 &&
                    whitelistAddressMintCount[msg.sender] + _quantity <=
                    whitelistAddressCustomLimit[msg.sender],
                "Minting above allocation"
            );
        }
        whitelistAddressMintCount[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * Admin minting
     */
    function mintAdmin(address _recipient, uint256 _quantity)
        public
        onlyOwner
        withinMaximumSupply(_quantity)
    {
        _safeMint(_recipient, _quantity);
    }

    /**
     * Base URI
     */
    string private baseURI;

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Withdrawal
     */
    address private constant treasuryAddress =
        0x55B80Cb7E2ea8780B29BB20D08F70A148ea7c12a;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(treasuryAddress), balance);
    }
}