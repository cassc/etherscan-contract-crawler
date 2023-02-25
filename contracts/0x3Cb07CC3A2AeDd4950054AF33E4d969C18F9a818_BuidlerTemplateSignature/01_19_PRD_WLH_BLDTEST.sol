//SPDX-License-Identifier: None
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

contract BuidlerTemplateSignature is Context, Ownable, ReentrancyGuard, ERC2981, ERC721A, DefaultOperatorFilterer {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*
    BBBBBBBBBBBBBBBBB   UUUUUUUU     UUUUUUUUIIIIIIIIIIDDDDDDDDDDDDD        LLLLLLLLLLL             EEEEEEEEEEEEEEEEEEEEEERRRRRRRRRRRRRRRRR
    B::::::::::::::::B  U::::::U     U::::::UI::::::::ID::::::::::::DDD     L:::::::::L             E::::::::::::::::::::ER::::::::::::::::R
    B::::::BBBBBB:::::B U::::::U     U::::::UI::::::::ID:::::::::::::::DD   L:::::::::L             E::::::::::::::::::::ER::::::RRRRRR:::::R
    BB:::::B     B:::::BUU:::::U     U:::::UUII::::::IIDDD:::::DDDDD:::::D  LL:::::::LL             EE::::::EEEEEEEEE::::ERR:::::R     R:::::R
      B::::B     B:::::B U:::::U     U:::::U   I::::I    D:::::D    D:::::D   L:::::L                 E:::::E       EEEEEE  R::::R     R:::::R
      B::::B     B:::::B U:::::D     D:::::U   I::::I    D:::::D     D:::::D  L:::::L                 E:::::E               R::::R     R:::::R
      B::::BBBBBB:::::B  U:::::D     D:::::U   I::::I    D:::::D     D:::::D  L:::::L                 E::::::EEEEEEEEEE     R::::RRRRRR:::::R
      B:::::::::::::BB   U:::::D     D:::::U   I::::I    D:::::D     D:::::D  L:::::L                 E:::::::::::::::E     R:::::::::::::RR
      B::::BBBBBB:::::B  U:::::D     D:::::U   I::::I    D:::::D     D:::::D  L:::::L                 E:::::::::::::::E     R::::RRRRRR:::::R
      B::::B     B:::::B U:::::D     D:::::U   I::::I    D:::::D     D:::::D  L:::::L                 E::::::EEEEEEEEEE     R::::R     R:::::R
      B::::B     B:::::B U:::::D     D:::::U   I::::I    D:::::D     D:::::D  L:::::L                 E:::::E               R::::R     R:::::R
      B::::B     B:::::B U::::::U   U::::::U   I::::I    D:::::D    D:::::D   L:::::L         LLLLLL  E:::::E       EEEEEE  R::::R     R:::::R
    BB:::::BBBBBB::::::B U:::::::UUU:::::::U II::::::IIDDD:::::DDDDD:::::D  LL:::::::LLLLLLLLL:::::LEE::::::EEEEEEEE:::::ERR:::::R     R:::::R
    B:::::::::::::::::B   UU:::::::::::::UU  I::::::::ID:::::::::::::::DD   L::::::::::::::::::::::LE::::::::::::::::::::ER::::::R     R:::::R
    B::::::::::::::::B      UU:::::::::UU    I::::::::ID::::::::::::DDD     L::::::::::::::::::::::LE::::::::::::::::::::ER::::::R     R:::::R
    BBBBBBBBBBBBBBBBB         UUUUUUUUU      IIIIIIIIIIDDDDDDDDDDDDD        LLLLLLLLLLLLLLLLLLLLLLLLEEEEEEEEEEEEEEEEEEEEEERRRRRRRR     RRRRRRR


    Developed and deployed with Buidler Launcher
    https://buidler.it
    */

    /** @notice Capped max supply */
    uint256 public immutable supplyCap = 6900;

    uint256 public immutable batchMintCap = 520;

    /** @notice Capped max supply for free claim */
    uint256 public immutable freeClaimCap = 2580;

    /** @notice Each address has a mint quota */
    uint16 public immutable holdersQuota = 6;
    uint16 public immutable whiteQuota = 5000;
    uint16 public immutable publicQuota = 5000;

    string private _baseTokenURI;

    /** @notice Token ID counter declared */
    Counters.Counter private _tokenIds;

    /** @notice Token ID counter declared */
    Counters.Counter private _freeClaimTokenIds;

    /** @notice Public mint open */
    bool public isOpenPublic;
    bool public isOpenWhite;
    bool public isOpenHolders;

    uint256 public dtStartHolders = 1677250800; //24-02 12h00
    uint256 public dtCloseHolders = 1677258000; //24-02 14h00
    uint256 public dtCloseWhiteList = 1677344400; //25-02 14h45
    uint256 public dtClosePublic = 1679763600;

    uint256 private mintHoldersValue = 0.016 ether;
    uint256 private mintWLValue = 0.018 ether;
    uint256 private mintPublicValue = 0.021 ether;

    mapping(address => bool) public __holders;
    mapping(address => bool) public __whitelist;

    mapping(address => bool) public __holdersFree;
    mapping(address => uint256) public __quotasFree;


    /** @notice Mapping to track number of mints per address */
    mapping(address => uint256) public userHoldersMintCount;
    mapping(address => uint256) public userWhiteMintCount;
    mapping(address => uint256) public userPublicMintCount;
    mapping(address => uint256) public userFreeMintCount;
    mapping(address => uint256) public ownerBatchMintCount;

    address private signerAddress = 0xaa030cCA457Ee250341ea24853693BBeA845D91E;

    using ECDSA for bytes32;

    /**
     * @notice Verify signature
     */
    function verifyAddressSigner(bytes memory signature) private view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
        return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    /*store metadata*/
    function contractURI() public view returns (string memory) {
        return "https://buidler.it/minters/cw/v1/json/contractmetadata";
    }

    modifier publicMintOpen() {
        require(isOpenPublic, "Public sale is not open");
        _;
    }

    modifier holdersMintOpen() {
        require(isOpenWhite, "Holders sale is not open");
        _;
    }

    modifier whiteListMintOpen() {
        require(isOpenHolders, "Whitelist sale is not open");
        _;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    constructor() ERC721A("Creepy World Vol. 1", "CWV1") {
        _baseTokenURI = 'https://buidler.it/minters/cw/v1/json/';
        isOpenPublic = false;
        isOpenWhite = false;
        isOpenHolders = false;

        /*set royalties*/
        address _receiver = 0xCc3714049eD0A6EE7C013808c8e6C255A07D8466;
        _setDefaultRoyalty(_receiver, 150);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
      _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /** @notice Owner can change baseURI */
    function setBaseURI(string memory baseTokenURI)
        external
        onlyOwner
    {
        _baseTokenURI = baseTokenURI;
    }

    /** @notice Open public mint */
    function openPublicMint() external onlyOwner {
        isOpenPublic = true;
    }

    /** @notice End public mint */
    function closePublicMint() external onlyOwner {
        isOpenPublic = false;
    }

    /** @notice Open public mint */
    function openWhiteMint() external onlyOwner {
        isOpenWhite = true;
    }

    /** @notice End public mint */
    function closeWhiteMint() external onlyOwner {
        isOpenWhite = false;
    }

    /** @notice Open holders mint */
    function openHoldersMint() external onlyOwner {
        isOpenHolders = true;
    }

    /** @notice End public mint */
    function closeHoldersMint() external onlyOwner {
        isOpenHolders = false;
    }

    function mint( uint256 amount, bytes memory signature) external payable {
        require(msg.sender == tx.origin, "You can't use other contract.");

        if ((block.timestamp >= dtStartHolders && block.timestamp <= dtCloseHolders)) {
            holdersMint(amount, signature);
        } else if (block.timestamp > dtCloseHolders && block.timestamp <= dtCloseWhiteList) {
            whiteListMint(amount, signature);
        } else if (block.timestamp > dtCloseWhiteList && block.timestamp <= dtClosePublic ) { 
            publicSaleMint(amount);
        } else if (isOpenHolders == true){
            holdersMint(amount, signature);
        } else if (isOpenWhite == true){
            whiteListMint(amount, signature);
        } else if (isOpenPublic == true){
            publicSaleMint(amount);
        }

        sendBuidlerFee(msg.value);
    }


    function publicSaleMint(uint256 _amount) private {        
            require(msg.value >= _amount * mintPublicValue, "Not enough funds.");
        for (uint256 i = 0; i < _amount; i++) {
            require(userPublicMintCount[msg.sender] < publicQuota, "Exceed quota");
            require(_tokenIds.current() < supplyCap, "Exceed cap");
            userPublicMintCount[msg.sender]++;
            _safeMint(msg.sender, 1);
            _tokenIds.increment();
        }
    }

    function holdersMint(uint256 _amount, bytes memory signature) private {
        require(verifyAddressSigner(signature), "NOT_IN_HOLDERS_LIST");
        require(msg.value >= _amount * mintHoldersValue, "Not enough funds.");

        for (uint256 i = 0; i < _amount; i++) {
            require(userHoldersMintCount[msg.sender] < holdersQuota, "Exceed quota");
            require(_tokenIds.current() < supplyCap, "Exceed cap");
            userHoldersMintCount[msg.sender]++;
            _safeMint(msg.sender, 1);
            _tokenIds.increment();
        }
    }

    function whiteListMint(uint256 _amount, bytes memory signature) private {
        require(verifyAddressSigner(signature), "NOT_IN_WHITE_LIST");
        require(msg.value >= _amount * mintWLValue, "Not enough funds.");

        for (uint256 i = 0; i < _amount; i++) {
            require(userWhiteMintCount[msg.sender] < whiteQuota, "Exceed quota");
            require(_tokenIds.current() < supplyCap, "Exceed cap");
            userWhiteMintCount[msg.sender]++;
            _safeMint(msg.sender, 1);
            _tokenIds.increment();
        }
    }

    /** @notice Contract owner can burn token he owns
     * @param _id token to be burned
     */
    function burn(uint256 _id) external onlyOwner {
        require(ownerOf(_id) == msg.sender);
        _burn(_id);
    }

    /** @notice Owner can batch mint to itself
     * @param _amount Number of tokens to be minted
     */
    function batchMintForOwner(uint256 _amount) external onlyOwner {
        for (uint256 i = 0; i < _amount; i++) {
            require(ownerBatchMintCount[msg.sender] < batchMintCap, "Exceed cap");
            ownerBatchMintCount[msg.sender]++;
            _safeMint(msg.sender, 1);
            //increment
            _tokenIds.increment();
        }
    }

   /*do Free Claim Mint*/
    function freeClaimMint(uint256 _amount, uint quota, bytes memory signature) external {
        require(verifyAddressSigner(signature), "NOT_IN_FREE_LIST");

        for (uint256 i = 0; i < _amount; i++) {
            require(userFreeMintCount[msg.sender] < quota, "Exceed quota");
            require(_freeClaimTokenIds.current() < freeClaimCap, "Exceed cap");
            userFreeMintCount[msg.sender]++;
            _safeMint(msg.sender, 1);
            _freeClaimTokenIds.increment();
        }
    }

    function isMintActive() external view returns (bool) {
        return isOpenPublic;
    }

    function totalMintCount() external view returns (uint256) {
        return _tokenIds.current();
    }

    function sendBuidlerFee(uint256 value) private {

        address __buidler_wallet = 0xCc3714049eD0A6EE7C013808c8e6C255A07D8466;

        //get only 1.5% to buidler 
        uint256 totalToSend1 = value * 3 / 2 / 100;

        (bool success, ) = __buidler_wallet.call{value: totalToSend1}("");
        require(success, "Transfer to buidler failed.");
    }

    /**
     * override(ERC721, ERC721Enumerable) -> here you're specifying only two base classes ERC721, ERC721Enumerable
     * */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, ERC2981)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) payable {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from) payable
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() external onlyOwner nonReentrant {
        
        uint256 totalBalance = address(this).balance;

        (bool success, ) = msg.sender.call{value: totalBalance}("");
        require(success, "Transfer failed.");
    }
}