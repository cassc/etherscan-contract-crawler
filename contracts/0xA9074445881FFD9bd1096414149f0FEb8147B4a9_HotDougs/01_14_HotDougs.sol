// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/*
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdolc,........''',,,;:cloxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdoc;,...                     ..':ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:,..                                .:oxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc'.                .. ......   ....      .lxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxl'                ..  ........  ......      .cxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxc.    .  ...      ..... ......                .:dxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxl.    .  ...     .  . .                         .,:clodxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxo'       .  .      .. ..            ...  ....         ...,:ldxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxd;    .  .....      ..          .'...''.  ',......'......    .'cdxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxc.    ...  ..              ..    .  .'...''...,'....   ......   ;dxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxo'      ..  ..    .       ...  ..  .'....,'..',.    .   .'. .'.  ;dxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxx;    .. ..  .         ....  ...  ......',...'..       ..... .  .;dxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxo.   . . .. . .      ..','..........   .'.  ..   ...   ..     .,lxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxc.   .                .                      .. .....       .;oxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxx:.      .           ....',,,,;;;;;;;,,,''.....          .';ldxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxc.            ..',;:clooooooooooooooooooooollcc:;'  .':coxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxo.       ..,:loxxdoooooooooooooooooooooooooooooooc. .oxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxd;  .,;:clodxxdl::;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,'.  ';;;;:lxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxd,  ,oooooodxx:.                                           ,dxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxd'  ;oooooodxxdl:;,'..  .;.                                ;xxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxo' .:ooooooxxxxxxoooo,  oK;              ..               .lxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxo. .:ooooooxxxxxdooooc. :KOl,           .:l;.            .:dxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxo. .:ooooooxxxxxdoooooc'.,dOx;        .,cooo:.          .cdxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxo. .:oooooodxxxxdooooool;.....     ..';;:cc::::,.   .;:ldxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxo. .:oooooodxxxxdooooooooolcc:::::;,'.        .,'  .oxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxo. .:oooooodxxxxdoooooooooooolc;,..                .;:ldxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxo:'  .:oooooodxxxxdoooooooooooc'.                      .;dxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxo:'.     ;oooooooddddoooooooooooooc;'....',;;:::;,'..   .:odxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxo;.  .,;.  .',,;coooooooooooooooooooooooooooooooooooooc. .lxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxl,.  '::'........ ..,:looooooooooooooooooooooooooooooooo:. .oxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxo;.  'cooccldxkkkkxo:'. .,cooooooooooooooooooooooooooooooo,  .,lxthankxyouxbohzxxxxxxxxx
xxxxxxxxxxdc.  'coddkO00000000000Od;. .,cooooooooooooooooooooooooooool.    .,oxxxxxxxxxxxxxxxxxxxxxx
CHENKOxxxo,  .;oddxO000000000000000Ox:. .,looooooooooooooooooooooooooc. .lc. .:dxxxxxxxxxxxxxxxxxxxx
DANGYWING   'coddkO000000000000000000Od,  .cooooooooooooooooooooooooo;. ,k0x;  'lxxxxxxxxxxxxxxxxxxx
HOPPERxl.  ,ldddkO000000000000000000000kc. .:oooooooooooooooooooooooo,  ;O00Ol. .:dxxxxxxxxxxxxxxxxx
xTIG_BO  ;odddkO00000000000000000000000Ol. .cooooooooooooooooooooooo,  cO000Od'  ;dxxxxxxxxxxxxxxxxx
xxxxxo'  ,odddk00000000000000000000000000Oc. .coooooooooooooooooooool' .c000000x,  ;dxxxxxxxxxxxxxxx
xxxxd,  'odddk0000000000000000000000000000k;  ,looooooc::cloooooooool' .l0000000x,  ;dxxxxxxxxxxxxxx
xxxx:. .ldddkO00000000OOxdxkO00000000000000d. .:ooooc'.',,';loooooool' .l00000000d. .cxxxxxxxxxxxxxx
xxxo. .:oddxO0000000Od:.....:x0000000000000Oc  'loo:.'cxOkc.;oooooooo'  c00000000Ol. .oxxxxxxxxxxxxx
xxx:  'ldddk0000000Ol. .','. ,x0000000000000d. .:ol'.cdk00O;.cooooooo,  :O00000000k;  ;dxxxxxxxxxxxx
xxd'  ;oddxO0000000o. .:ooo,  :O000000000000O;  ,ll'.cdxO00d.,ooooooo;  ;O000000000o. .lxxxxxxxxxxxx
xxl. .cdddk0000000k;  ,ooooc. 'x0000000000000l. 'lo:.,oddkOOc.,looooo:. ,k000000000k,  .:dxxxxxxxxxx
xx:. 'odoxO0000000x. .cooool. .o0000000000000o. .coo;.,lddxOOo;',:looc. 'x000000000O:    ,oxxCHENKOx
xx;  ,oddxO0000000o. .cooooo' .c0000000000000d. .:ooo:'.;ldxO0Odc,',cc. .d0000000000l.    ,oxxxxxxxx
xd,  ;dddxO0000000o. .looooo;  :O000000000000x' .:ooool:'.;loxO0K0d,.:' .l0000000000o. ..  ;dxxxxxxx
xd'  :dddxO0000000o. .looooo:. ,k000000000000k, .:ooooool;...,x00KKx'''  :O000000000d. .,. .cxxxxxxx
xd' .:dddk00000000o. .loooooc. 'x000000000000k, .;ooooooool, 'x000KO,',. ,k000000000d. .:,  ,dxxxxxx
xd' .:dddk00000000d. .coooooc. .d000000000000k,  ;ooooooool,.:O00KKd.,:. .d000000000x' .::. .lxxxxxx
xd' .:dddk00000000x' .coooool. .o000000000000k,  ;oooooool,.,x0000O:.:l' .o000000000x' .:c. .:xxxxxx
*/

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title Hot Dougs
contract HotDougs is Ownable, ReentrancyGuard, ERC721A("Hot Dougs", "DOUGS") {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    /// @notice Max total supply.
    uint256 public dougsMax = 6969;

    /// @notice Max transaction amount.
    uint256 public constant dougsPerTx = 10;

    /// @notice Max Dougs per wallet in pre-sale
    uint256 public constant dougsMintPerWalletPresale = 3;

    /// @notice Total Dougs available in pre-sale
    uint256 public constant maxPreSaleDougs = 3000;

    /// @notice Dougs price.
    uint256 public constant dougsPrice = 0.05 ether;

    /// @notice 0 = closed, 1 = pre-sale, 2 = public
    uint256 public saleState;

    /// @notice Metadata baseURI.
    string public baseURI;

    /// @notice Metadata unrevealed uri.
    string public unrevealedURI;

    /// @notice Metadata baseURI extension.
    string public baseExtension;

    /// @notice OpenSea proxy registry.
    address public opensea = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    /// @notice LooksRare marketplace transfer manager.
    address public looksrare = 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;

    /// @notice Check if marketplaces pre-approve is enabled.
    bool public marketplacesApproved = true;

    /// @notice Free mint merkle root.
    bytes32 public freeMintRoot;

    /// @notice Pre-sale merkle root.
    bytes32 public preMintRoot;

    /// @notice Amount minted by address on free mint.
    mapping(address => uint256) public freeMintCount;

    /// @notice Amount minted by address on pre access.
    mapping(address => uint256) public preMintCount;

    /// @notice Authorized callers mapping.
    mapping(address => bool) public auth;

    modifier canMintDougs(uint256 numberOfTokens) {
        require(
            totalSupply() + numberOfTokens <= dougsMax,
            "Not enough Dougs remaining to mint"
        );
        _;
    }

    modifier preSaleActive() {
        require(saleState == 1, "Pre sale is not open");
        _;
    }

    modifier publicSaleActive() {
        require(saleState == 2, "Public sale is not open");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier maxDougsPerTransaction(uint256 numberOfTokens) {
        require(
            numberOfTokens <= dougsPerTx,
            "Max Dougs to mint per transaction is 10"
        );
        _;
    }

    constructor(string memory newUnrevealedURI) {
        unrevealedURI = newUnrevealedURI;
    }

    /// @notice Mint one free token and up to 3 pre-sale tokens.
    function mintFree(uint256 numberOfTokens, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        preSaleActive
        isCorrectPayment(dougsPrice, numberOfTokens - 1)
        isValidMerkleProof(merkleProof, freeMintRoot)
    {
        if (msg.sender != owner()) {
            require(
                freeMintCount[msg.sender] == 0,
                "User already minted a free token"
            );
            uint256 numAlreadyMinted = preMintCount[msg.sender];

            require(
                numAlreadyMinted + numberOfTokens - 1 <=
                    dougsMintPerWalletPresale,
                "Max Dougs to mint in pre-sale is three"
            );

            require(
                totalSupply() + numberOfTokens <= maxPreSaleDougs,
                "Not enough Dougs remaining in pre-sale"
            );

            preMintCount[msg.sender] = numAlreadyMinted + numberOfTokens;

            freeMintCount[msg.sender]++;
        }
        _safeMint(msg.sender, numberOfTokens);
    }

    /// @notice Mint one or more tokens for address on pre-sale list.
    function mintPreDoug(uint256 numberOfTokens, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        preSaleActive
        isCorrectPayment(dougsPrice, numberOfTokens)
        isValidMerkleProof(merkleProof, preMintRoot)
    {
        uint256 numAlreadyMinted = preMintCount[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= dougsMintPerWalletPresale,
            "Max Dougs to mint in pre-sale is three"
        );

        require(
            totalSupply() + numberOfTokens <= maxPreSaleDougs,
            "Not enough Dougs remaining in pre-sale"
        );

        preMintCount[msg.sender] += numberOfTokens;

        _safeMint(msg.sender, numberOfTokens);
    }

    /// @notice Mint one or more tokens.
    function mintDoug(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        publicSaleActive
        isCorrectPayment(dougsPrice, numberOfTokens)
        canMintDougs(numberOfTokens)
        maxDougsPerTransaction(numberOfTokens)
    {
        _safeMint(msg.sender, numberOfTokens);
    }

    /// @notice Allow contract owner to mint tokens.
    function ownerMint(uint256 numberOfTokens)
        external
        onlyOwner
        canMintDougs(numberOfTokens)
    {
        _safeMint(msg.sender, numberOfTokens);
    }

    /// @notice See {IERC721-tokenURI}.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (bytes(unrevealedURI).length > 0) return unrevealedURI;
        return
            string(
                abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
            );
    }

    /// @notice Set baseURI to `newBaseURI`, baseExtension to `newBaseExtension` and deletes unrevealedURI, triggering a reveal.
    function setBaseURI(
        string memory newBaseURI,
        string memory newBaseExtension
    ) external onlyOwner {
        baseURI = newBaseURI;
        baseExtension = newBaseExtension;
        delete unrevealedURI;
    }

    /// @notice Set unrevealedURI to `newUnrevealedURI`.
    function setUnrevealedURI(string memory newUnrevealedURI)
        external
        onlyOwner
    {
        unrevealedURI = newUnrevealedURI;
    }

    /// @notice Set sale state. 0 = closed 1 = pre-sale 2 = public.
    function setSaleState(uint256 newSaleState) external onlyOwner {
        saleState = newSaleState;
    }

    /// @notice Set freeMintRoot to `newMerkleRoot`.
    function setFreeMintRoot(bytes32 newMerkleRoot) external onlyOwner {
        freeMintRoot = newMerkleRoot;
    }

    /// @notice Set preMintRoot to `newMerkleRoot`.
    function setPreMintRoot(bytes32 newMerkleRoot) external onlyOwner {
        preMintRoot = newMerkleRoot;
    }

    /// @notice Update Total Supply
    function setMaxDougs(uint256 _supply) external onlyOwner {
        dougsMax = _supply;
    }

    /// @notice Toggle marketplaces pre-approve feature.
    function toggleMarketplacesApproved() external onlyOwner {
        marketplacesApproved = !marketplacesApproved;
    }

    /// @notice Withdraw balance to Owner
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /// @notice See {ERC721-isApprovedForAll}.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (!marketplacesApproved)
            return auth[operator] || super.isApprovedForAll(owner, operator);
        return
            auth[operator] ||
            operator == address(ProxyRegistry(opensea).proxies(owner)) ||
            operator == looksrare ||
            super.isApprovedForAll(owner, operator);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}