// Squishiland by Squishiverse (www.squishiland.com / www.squishiverse.com)

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOdlod0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:'....,lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMWKxc'..;cll:,..,lkXWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWXkc'..,cldddddol;'..,lOXWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWXkl,..,:lddoodoooooool:'..;oOXWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWXOl,..';lodddooodddollloodol;...;o0NWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWNOl,..';cloddddxxxxxddollodddddoc:,...;o0NWMMMMMMMMMMMMM
// MMMMMMMMMMMNOo;..';coooodxxxxxkkxdddoodxxxddddooolc;...:d0NMMMMMMMMMMM
// MMMMMMMMN0o;...;coddddddxxxxxddddddddxkOkkxdxxxxddddo:,...:xKNMMMMMMMM
// MMMMMN0d:...;lodddddxxxxxxxxdddxxxddxkkkxxxxdxxxxxxddolc;'..'cxKWMMMMM
// MMN0d:'..,:odxxddddxxkOOkxxxddodxxxxdddddddddxxxxxddollllol:,..'cxKWMM
// Kd:'..,:coodddddddxxxkkkkxxxddoodddddxxxxxdxkOO00kdolllloooool:,..'ckX
// :..';cooooodddddddddddddddddddoooooddxxxxxxxxk00Okddoolloooodddol:'..l
// '..:cloooooddddddddddddddddxxdddoooooddddddxxxxxxdoooooddddddollcl;..:
// ;..',;coddddddddddddddddxxxdddddddddddoooddxxxxxdolllloooooooolc::,..c
// c....',;clooooddddddddxxxxxddddddddddddddddddxxxollllllllclllcc;;;'..o
// o.......';::cldddddddxxxxxxxdddddddddddddddddooolllooooolc:::;;,,,'..d
// x. .......'',:loddddddddddddddxkkxddddddddddddollloooolc:,;,,,''',. .x
// k. ..........',;clooooooddddddxO0Okkxddoooddddoolcccc:;,''''''''''..'O
// O' .............',;;:clloddddxkOOkkkxooooollllool:;,,,''''''''.'''..;0
// O,..................';:cloodddxxdooollooooolccccc:,''',,,,'''.......:K
// 0;...................',,;:clddooloddoloddolc::::;,,''',,,''.........lX
// 0:......................'',;clooodxxdolllc:;,,,,,'''''''''..........dN
// Kc. .......................',,:coxxddl:;;,,''''''',,,''.'......... .xN
// Xo. .........................',;:loll:;,''''''''',,,''............ 'kW
// Nd. ...........................',;:::;,,,,'',,,''',''............. 'OW
// Wk' ............................',;;;,,,;,'',,,'''''.............. 'OM
// M0;. ............ ..............',,,;;;,,'''''''...................;0M
// MNk;.  ..........................',,;;,''''''''...................:OWM
// MMWXOl'.  ............ ..........',,,,''''''''.................,lONWMM
// MMMMMWKx:.. .....................',,,,''...'''..............'ckXWMMMMM
// MMMMMMMMNOo,.  ..................',,,''...................,d0NMMMMMMMM
// MMMMMMMMMMWKkc..  ...............'',''.................'lkXWMMMMMMMMMM
// MMMMMMMMMMMMMW0o,.  ..............'''................;dKWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWXkc'.  ...........................,lONWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMN0d;.   ......................:xXWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWXkc'.  ........''.......,o0NMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWKx:.. ............'ckXWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMNOo,..........;d0NMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc'....'lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOocld0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

// Development help from @lozzereth (www.allthingsweb3.com)

// SPDX-License-Identifier: CC-BY-NC-4.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Squishiland is ERC721, Ownable {
    /// @dev Maximum mints per wallet
    uint256 public maxPerWallet = 1;

    /// @dev Mint round
    uint256 public mintRound = 0;

    /// @dev Mint count based off the current mint round
    mapping(uint256 => mapping(address => uint256)) public addressMintCount;

    /// @dev Tiered whitelisting system
    bytes32[3] public tieredWhitelistMerkleRoot;

    /// @dev Land sizes
    enum LandSize {
        Rare,
        Epic,
        Legendary,
        Mythic
    }

    /// @dev Maximum land sizes
    uint256 public constant MAX_LAND_SIZES = 4;

    /// @dev Attribute for each piece of land
    struct LandAttribute {
        uint256 price;
        uint256 supply;
        uint256 startingId;
        uint256 minted;
        uint256 burnt;
    }

    /// @dev Mapping for lands and their respective attributes
    mapping(LandSize => LandAttribute) public land;

    constructor() ERC721("Squishiland", "SVLAND") {
        land[LandSize.Rare] = LandAttribute(0.2 ether, 2494, 1950, 0, 0);
        land[LandSize.Epic] = LandAttribute(0.4 ether, 1500, 450, 0, 0);
        land[LandSize.Legendary] = LandAttribute(0.75 ether, 400, 50, 0, 0);
        land[LandSize.Mythic] = LandAttribute(1.25 ether, 50, 0, 0, 0);
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
    function mintPublic(LandSize _size, uint256 _quantity)
        public
        payable
        publicSaleActive
        withinSupplyLimit(_size, _quantity)
        hasFunding(_size, _quantity)
        withinMaxPerWallet(_quantity)
    {
        unchecked {
            addressMintCount[mintRound][msg.sender] += _quantity;
        }
        _mintMany(_size, msg.sender, _quantity);
    }

    modifier hasFunding(LandSize _size, uint256 _quantity) {
        require(
            msg.value >= land[_size].price * _quantity,
            "Insufficent funds"
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
     * @notice Set the whitelist merkle root for a specific tier
     */
    function setWhitelistMerkleRoot(uint256 tier, bytes32 merkleRoot)
        external
        onlyOwner
        hasValidTier(tier)
    {
        tieredWhitelistMerkleRoot[tier] = merkleRoot;
    }

    modifier hasValidTier(uint256 tier) {
        require(tier >= 0 && tier <= 2, "Invalid tier");
        _;
    }

    /**
     * @notice Whitelist mint based on tier
     */
    function mintWhitelist(
        LandSize _size,
        uint256 _tier,
        uint256 _quantity,
        bytes32[] calldata merkleProof
    )
        public
        payable
        whitelistSaleActive
        hasValidTier(_tier)
        hasValidMerkleProof(merkleProof, tieredWhitelistMerkleRoot[_tier])
        withinSupplyLimit(_size, _quantity)
        withinMaxPerWallet(_quantity)
        hasFunding(_size, _quantity)
    {
        unchecked {
            addressMintCount[mintRound][msg.sender] += _quantity;
        }
        _mintMany(_size, msg.sender, _quantity);
    }

    modifier hasValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address not allowed"
        );
        _;
    }

    /**
     * @notice Allows the contract owner to mint within limits
     */
    function mintAdmin(
        LandSize _size,
        address _recipient,
        uint256 _quantity
    ) public onlyOwner withinSupplyLimit(_size, _quantity) {
        _mintMany(_size, _recipient, _quantity);
    }

    /**
     * @dev Mints many nfts
     */
    function _mintMany(
        LandSize _size,
        address _to,
        uint256 _quantity
    ) private {
        uint256 startingId = land[_size].minted + land[_size].startingId;
        unchecked {
            land[_size].minted += _quantity;
        }
        for (uint256 i; i < _quantity; i++) {
            _mint(_to, startingId + i);
        }
    }

    modifier withinSupplyLimit(LandSize _size, uint256 _quantity) {
        require(
            land[_size].minted + _quantity <= land[_size].supply,
            "Surpasses supply"
        );
        _;
    }

    /**
     * @notice Allows owner to adjust the mint price
     * @dev All amounts assume a wei amount
     */
    function setMintPrice(LandSize _size, uint256 _price) public onlyOwner {
        land[_size].price = _price;
    }

    /**
     * @notice Allows owner to decrease the maximum supply of a size
     */
    function reduceMaximumSupply(LandSize _size, uint256 _supply)
        external
        onlyOwner
    {
        require(_supply <= land[_size].supply, "Cannot increase supply");
        require(_supply >= land[_size].minted, "Below minted supply");
        land[_size].supply = _supply;
    }

    /**
     * @notice Set maximum mintable amount per wallet
     */
    function setMaxPerWallet(uint256 _amount) external onlyOwner {
        maxPerWallet = _amount;
    }

    /**
     * @notice Set the minting round
     */
    function setMintRound(uint256 _round) external onlyOwner {
        mintRound = _round;
    }

    /**
     * @notice Fetch total supply
     */
    function totalSupply() public view returns (uint256) {
        uint256 total;
        for (uint256 s; s < MAX_LAND_SIZES; s++) {
            LandSize size = LandSize(s);
            total += land[size].minted;
        }
        return total;
    }

    /**
     * @notice Fetch total burnt
     */
    function totalBurnt() public view returns (uint256) {
        uint256 total;
        for (uint256 s; s < MAX_LAND_SIZES; s++) {
            LandSize size = LandSize(s);
            total += land[size].burnt;
        }
        return total;
    }

    /**
     * @notice Burn a piece of land
     */
    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Squishiland: caller is not owner nor approved"
        );
        LandSize size = getLandSize(tokenId);
        unchecked {
            land[size].burnt++;
        }
        _burn(tokenId);
    }

    /**
     * @notice Fetch the total minted on a per size basis
     */
    function totalSupplyBySize(LandSize _size) public view returns (uint256) {
        return land[_size].minted;
    }

    /**
     * @notice Fetch the total burnt on a per size basis
     */
    function totalBurntBySize(LandSize _size) public view returns (uint256) {
        return land[_size].burnt;
    }

    /**
     * @notice Get the land size for a token
     */
    function getLandSize(uint256 _tokenId) public view returns (LandSize) {
        for (uint256 s; s < MAX_LAND_SIZES; s++) {
            LandSize size = LandSize(s);
            uint256 start = land[size].startingId;
            if (_tokenId >= start && _tokenId <= start + land[size].minted) {
                return size;
            }
        }
        revert("Squishiland: land size query for nonexistent token");
    }

    /**
     * @notice Base URI for the NFT
     */
    string private baseURI;

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Distribution of sales
     */
    address private constant address1 =
        0x55B80Cb7E2ea8780B29BB20D08F70A148ea7c12a;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(address1), balance);
    }
}