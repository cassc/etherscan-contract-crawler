// The Plague (www.plaguenft.com)

// MMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWXOxdlllloxOKNWNXXK000OOO000KXXX0OOkOO0XWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMW0o:,''''''''';cc:;;,,,'''''',,;;;,''''',;cd0WMMMMMMMMMMMMM
// MMMMMMMMMMNx;'''''''''''''''''''''''''''''''''''''''''',dXMMMMMMMMMMMM
// MMMMMMMMMM0:',lol;'.';cllc,',''',,,,,''''',''''''''''''''dNMMMMMMMMMMM
// MMMMMMMMMM0c':kkc'';;;d00x;'',,'','''''',lxl,....,:cll;'';xXWMMMMMMMMM
// MMMMMMMMMMXo';dx;.':;'lOkc,'',,,,,'''''';dOc'.;c;,o00Ol'''':xXMMMMMMMM
// MMMMMMMMMWO:'';:,'..'';::,',''''','''''',cd;..,:,,d0Od;''''''lKWMMMMMM
// MMMMMMMMMKl,''''''''','''',,',,',,'''''''','''''',clc,''''''''cKMMMMMM
// MMMMMMMMNd,''''','''''''''''''''''',,,'''''''''''''''''''''''''dNMMMMM
// MMMMMMMWk;'','''''''''''''''''''''''''''''''''''','','','''''''cKMMMMM
// MMMMMMW0c,','',''''''''''''''',,,,'''''''''''''',,,,;;;,,''''''cKMMMMM
// MMMMMNkl::;,,,,,,'''''''''''''''',''''''',,,,;;::ccccllc;''''''oNMMMMM
// MMMMMXo:lllllc:;;;;,,,,,,,,,,,,,,,;;;;::::::ccccllllllc;,''''':OMMMMMM
// MMMMMWx:cccccccccc::::::::::::::::::::ccccccccllllcc:;,'''''';kWMMMMMM
// MMMMMW0occlllllcccccccccccccccccccccclllllllcc::;,,,'''''''':OWMMMMMMM
// MMMMMMWN0xoc:::::ccccclllllllccccccc::::;;,,,,'''''''''''',oKWMMMMMMMM
// MMMMMMMMMMWX0koc,'',,,,,,,,,,,,,,,''''''',,''''''''''''';o0WMMMMMMMMMM
// MMMMMMMMMMMMMMWN0xo;'''''''''''''''''''''''''''''''.';lxKWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWKko:,''''''''''''''''''''''.',;cdkKWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWNKOxolc:;,,'''''',,,;:codk0XWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXK000OOO00KKXNWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

// Development help from @lozzereth (www.allthingsweb3.com)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract ThePlague is ERC721A, Ownable {
    uint256 public maximumSupply = 11300;
    uint256 public mintPrice = 0.05 ether;
    uint256 public maxPerWallet = 1;
    uint256 public mintableSupply = 1300;
    uint256 public mintRound = 0;

    mapping(uint256 => mapping(address => uint256)) public addressMintCount;

    constructor() ERC721A("The Plague", "FROG") {}

    modifier withinMintableSupply(uint256 _quantity) {
        require(
            totalSupply() + _quantity <= mintableSupply,
            "Surpasses supply"
        );
        _;
    }

    modifier withinMaxPerWallet(uint256 _quantity) {
        require(
            _quantity > 0 &&
                addressMintCount[mintRound][msg.sender] + _quantity <=
                maxPerWallet,
            "Minting above allocation"
        );
        _;
    }

    /**
     * @dev Mechanisms to open and close the public/whitelist sales
     */
    bool public publicSale = false;
    bool public whitelistSale = false;

    modifier publicSaleActive() {
        require(publicSale, "Public sale not started");
        _;
    }

    modifier whitelistSaleActive() {
        require(whitelistSale, "Whitelist sale not started");
        _;
    }

    function setPublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function setWhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }

    /**
     * @dev Public minting functionality
     */
    function mintPublic(uint256 _quantity)
        public
        payable
        publicSaleActive
        withinMintableSupply(_quantity)
        withinMaxPerWallet(_quantity)
    {
        require(msg.value >= mintPrice * _quantity, "Insufficent funds");
        addressMintCount[mintRound][msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @dev Tiered whitelisting system
     */
    bytes32[3] public tieredWhitelistMerkleRoot;

    modifier hasValidTier(uint256 tier) {
        require(tier >= 0 && tier <= 2, "Invalid Tier");
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
        withinMintableSupply(_quantity)
        withinMaxPerWallet(_quantity)
    {
        if (_tier != 0) {
            require(msg.value >= mintPrice * _quantity, "Insufficent funds");
        }
        addressMintCount[mintRound][msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @dev Allows the contract owner to mint within limits
     */
    function mintAdmin(address _recipient, uint256 _quantity)
        public
        onlyOwner
        withinMintableSupply(_quantity)
    {
        _safeMint(_recipient, _quantity);
    }

    /**
     * @dev Allows owner to adjust the mint price (in wei)
     */
    function setMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    /**
     * @dev Set maximum mintable amount per wallet
     */
    function setMaxPerWallet(uint256 _amount) external onlyOwner {
        maxPerWallet = _amount;
    }

    /**
     * @dev Set the NFT mintable supply
     */
    function setMintableSupply(uint256 _supply) external onlyOwner {
        require(_supply <= maximumSupply, "Above absolute maximum");
        require(_supply >= totalSupply(), "Below minted supply");
        mintableSupply = _supply;
    }

    /**
     * @dev Set the NFT absolute maximum supply
     */
    function reduceMaximumSupply(uint256 _supply) external onlyOwner {
        require(_supply <= maximumSupply, "Cannot increase maximum supply");
        require(_supply >= totalSupply(), "Below minted supply");
        maximumSupply = _supply;
    }

    /**
     * @dev Set the minting round
     */
    function setMintRound(uint256 _round) external onlyOwner {
        mintRound = _round;
    }

    /**
     * @dev Base URI for the NFT
     */
    string private baseURI;

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Distribution of sales
     */
    address private constant address1 =
        0x70B03a58336e4bF9850012DF0A640C4dE953bf94;
    address private constant address2 =
        0xA2Df5B0dee27D8f28b655d3829e3E9eED9c90DD5;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(address1), (balance * 90) / 100);
        Address.sendValue(payable(address2), (balance * 10) / 100);
    }
}