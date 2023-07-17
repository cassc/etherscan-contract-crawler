// SPDX-License-Identifier: MIT

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffpfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffpfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffpf7777Tpffffffpf7777777fpWY"7"4ffffffffffffffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffX``````OfffffffS``````,fS``````.fffffffffffffffffffffffffffffffffffffffffff    //
//    ffpffffffffffffffffffffff\``````.WffffffS``````,ffn.....dfffffffffffffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffp% A.`````(ffffffS``````,fr???????fffffY"7!!!??"T7pfffY"7!<!?7Tffffffffffffff    //
//    ffffffffffffffffffffffff (fL``````jfffffS``````,fk``````,ffX=```` .dfVI- fW=```.dfk.`` Cffffffffffff    //
//    fffffffffffffffpfXY7""T'.fff/`````.WffffS``````,fk```.``,ff``````Jfff:``.W!````Jfff[````Offfffffffff    //
//    ffpffffffffffff=`...((, . ?TW.`.```,ffffS```.``,fk``````,f\````` ffffk-.X$`````7777^````,fffffffffff    //
//    ffffffffffffff\``.4fff`(fW&,````````jpffS``````,fk``````,f;``````jfffffffr`````jffffffffffffffffffff    //
//    ffffffffffffff-```.fW!.fffffW+`````` WffS``````,fk``````,fL```````(TWffUTk.`````?4WfffUYwfffffffffff    //
//    ffpffffffffffffAJdff\.Wfffffffk.`.```,ffS```.``,fk```.``,ffo````````````Jfh.`.`````````.ffffffffffff    //
//    ffffffffffffffffffff dfffffffff%``````(ff``````,ff``````,fffW-.`````` .dffffn. ``````.Jfffffffffffff    //
//    ffffffffffpY"4fffff`,fffffffffffffffWWUWffffffffffffffffWWffWUfffkkXfffffUWfffWfWXXpffffffffffffffff    //
//    ffffffffff%```(ffW'.ffffffffffffffpk_(!??f<?4f=7?Y7?6?=z!.pf%.ff<?Y7?4=?4~Z7?=`j<Y?fffpfffffffffffff    //
//    ffpfffffffk,``XWY!.ffffffffffffk..ff~(!(`}./Jf:(`{./J'.W},f0_Xff(.\.{. fj`>./(`d[`,fh..fffffffffffff    //
//    fffffffffffffWkwWfffffffffffffffffffkwkXXVkdffkXXWkwWXWXWwfkdfffXdfkdfkwVXWkwfkXC.Vfffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffVVffffffffffffVffffffffffffffffff    //
//    ffpfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffffffpffpffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffffffffVYI-<~._?4pffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffpffffffffffffffffffffffffffffffffffffpW^.+<(-~<_~~~(4ffffffffp6+Wfffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffff',d$CzO<__~~.~_Wffffffffzz(fffffffpfWpffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffffS.3III<<I<-<~<~_(fffffff$v1(ffffppY++<Jffffffffffffffffffffff    //
//    ffpfffffffffffffffffffffffffffffffffffpCdJ><l+(:(e,<(<((ffffffffZIWfffffzuC<(fffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffffI#?'.(TH_.TCS+%((ffffffY4zVTWWWTJ??jdffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffpIb_~..~~..((K<C((fffff_` ...._+-_4fffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffffcM/i-....(VdFr<(Jfffffv!......_7WWfffffffffffffffffffffffffff    //
//    ffpffffffffffffffffffffffffffffffffffffLdN-((-.(xIZi1idfffffk.7&?>~---__(fffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffAMMMMb.JX&+XUUWffffffk+_~<<<+1=dffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffpY77TYTD!!``````.=vffffffVVk&++dXfffffffffffffffffffffffffffff    //
//    ffpffffffffffffffffffffffffffffffffffpP (l.1:-z?I+?YT=11-?UffffffffVVVffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffff!(.O_.l_(l>z(l(:j(l<-1Wfffffffffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffp l<1z.(z.(2v({(_1_<1(i<Wffffffffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffW.(i.?z.(C(+>(:z_v-<<1(cjpfffffffffffffffffffffffffffffffffffff    //
//    ffpfffffffffffffffffffffffffffffffffffAiJOJJ7_7?j(C(>.lj(s(oQWffffffffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffffWkq_`` ..((~v-c(>gM#!`(ffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffW_l(` .-Bv(<I>[email protected]!` .jffffffffffffffffffffffffffffffffffffff    //
//    ffpfffffffffffffffffffffffffffffffffffpffZ1d,` .J\v~l~zHh.x_~~Wfffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffpKWdH%` <`` -<<<<&dfVVfL.__4ffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffpWUZuXX,``.!``.(..Jfffffffo-._4fffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffWVMB=?1W,..( `.-_-JfffWffff|`..jffffffffffffffffffffffffffffffffff    //
//    ffpffffffffffffffffffffffffffffpWSZ+w6dAZgX,_``.-J(1<7T/?WfffW,..(Wfffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffWyX+d>d83<dMY` .(dmx!.>+X-jffffW,..(Wffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffWw-W0II<vzv` [email protected]\(v-di?+WfffffL..?pfffffffffffffffffffffffffffffff    //
//    ffpfffffffffffffffffffffffffffffpRXC1x+zdC_.(HMEld(>.jOvl.<WfffVVk..?Wffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffWZaZud=(o(JSXXslvZ_(v<I?O(zfffffff,JOWfffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffdN9<OltwHuuZWylG.gK(cJEl>Wfffff0OllOWffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffW=``.qXMD(KQROltOM#(ulIl1wfffffWszv=~?4ffffffffffffffffffffffffff    //
//    ffpffffffffffffffffffffffffffffffffD___(#[email protected](JJjlvJffffffWW._~_((OXfffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffk__(wXMNHM9UllltOzH(vb>ZlzWfffffffkJ+(--?4fffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffpP1-UyQV6lllOlllzOlw_>N(+gNAXfffffffffVVffffffffffffffffffffffffff    //
//    ffpffffffffffffffffffffffffffffffffAAJOdTZllv<8z?:(?71_zdb14ffffffffffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffffk`. .....-_...J:1(W/:Wfffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffff;``` ....~..(fnJ/fS(Xfffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffk.```....<.-dfffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffpffffffffffffffffffffffffffffffffffffffh ``...(_(fffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffh``...((ffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffp;`...(fffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffpffffffffffffffffffffffffffffffffffffffff]`..<(fffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffffffff%.` __?pfffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffW`.``...(Wffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffff$`.:``...(pfffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffpfffffffffffffffffffffffffffffffffffffff%``~`.....Xfffffffffffffffffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffffffpW, -.`....Jfffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffpf??YWb`....Jfffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffpfffffffffffffffffffffffffffffffpWWkfff!``.WfL ...Jfffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffWMOXHf%``.ffff.((-dfffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffWMwXWY``.ffffff:>?Offfffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffWMNHF `.ffffffk```Jfffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffpffffffffffffffffffffffffffffffffWMP` `(ffffffW. `Jfffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffWN..Jdkffffff)``(fffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffWNQMMMfffffff[``(fffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffpffffffffffffffffffffffffffffffffffHMMNffffffff}` (fffffffffffffffffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffffffffffffff!``,fffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffffffffp.` (kffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffWSZWWQB(XMMMkfffffffffffffffffffffffffffffffffffffffffffff    //
//    ffpfffffffffffffffffffffffffffffffffffffffWMMMMU0XXdMMNfffffffffffffffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffffffffWHXMMMMMMNHffffffffffffffffffffffffffffffffffffffffffffff    //
//    fffffffffffffffffffffffffffffffffffffffffffffffffmkkkWffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffpfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//    ffpfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Alice https://alice.slash.vision/
// Slash https://slash.fi/

pragma solidity >=0.8.18;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "operator-filter-registry/src/lib/Constants.sol";
import "operator-filter-registry/src/upgradeable/UpdatableOperatorFiltererUpgradeable.sol";

contract Alice is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    UpdatableOperatorFiltererUpgradeable,
    Ownable2StepUpgradeable,
    IERC2981Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using MerkleProofUpgradeable for bytes32[];
    using StringsUpgradeable for uint256;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize this contract.
     */
    function initialize() public initializer {
        // Upgradeable contracts need to call their parent initializer.
        __ERC721_init("Alice", "ALICE");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __UpdatableOperatorFiltererUpgradeable_init(
            CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS,
            CANONICAL_CORI_SUBSCRIPTION,
            true
        );
        __Ownable2Step_init();

        baseURI = "https://d14k2sqdzi7ue4.cloudfront.net/";
        mintLimit = 2000;
        revealLastIndex = 0;
        keccakPrefix = "ALC_";
        isPublicMintPaused = true;
        isAllowlistMintPaused = true;
        publicPrice = 0.09 ether;
        allowListPrice = 0.09 ether;
        allowlistedMemberMintLimit = 3;
        allowlistSaleId = 0;
        _royaltyFraction = 500; // 5%
        _royaltyReceiver = msg.sender;
        _withdrawalReceiver = msg.sender;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * We implemented ERC2981 by ourselves without inheriting one of the implementation that OpenZeppelin provides,
     * so we need to add it to the list of supported interfaces here.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    ///////////////////////////////////////////////////////////////////
    //// Ownable
    ///////////////////////////////////////////////////////////////////

    /**
     * @notice Returns the address of the current owner.
     */
    function owner()
        public
        view
        virtual
        override(OwnableUpgradeable, UpdatableOperatorFiltererUpgradeable)
        returns (address)
    {
        // OperatorFilterer just needs to know who the owner is, so we return the owner from Ownable
        return OwnableUpgradeable.owner();
    }

    ///////////////////////////////////////////////////////////////////
    //// Apply Operator Filter
    ///////////////////////////////////////////////////////////////////

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    ///////////////////////////////////////////////////////////////////
    //// ERC2981
    ///////////////////////////////////////////////////////////////////

    /**
     * @dev The royalty fraction in percentage * 100. e.g. 500 means 5%.
     */
    uint96 private _royaltyFraction;

    /**
     * @dev Set the royalty fraction.
     * @param royaltyFraction The royalty fraction in percentage * 100. e.g. 500 means 5%.
     */
    function setRoyaltyFraction(uint96 royaltyFraction) external onlyOwner {
        require(royaltyFraction <= 1_000, "royalty fraction exceeds the limit"); // 10%
        _royaltyFraction = royaltyFraction;
    }

    /**
     * @dev The address to receive the royalty.
     */
    address private _royaltyReceiver;

    /**
     * @dev Set the royalty receiver.
     * @param receiver The royalty receiver.
     */
    function setRoyaltyReceiver(address receiver) external onlyOwner {
        _royaltyReceiver = receiver;
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override checkTokenIdExists(tokenId) returns (address receiver, uint256 royaltyAmount) {
        receiver = _royaltyReceiver;
        royaltyAmount = (salePrice * _royaltyFraction) / 10_000;
    }

    ///////////////////////////////////////////////////////////////////
    //// URI
    ///////////////////////////////////////////////////////////////////

    //////////////////////////////////
    //// Base URI
    //////////////////////////////////

    /**
     * @dev Base URI for all token IDs.
     */
    string public baseURI;

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Set the base URI for all token IDs.
     * @param baseURI_ The base URI for all token IDs.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    //////////////////////////////////
    //// Contract URI
    //////////////////////////////////

    /**
     * @dev Returns the contract URI.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "index.json"));
    }

    //////////////////////////////////
    //// Token URI
    //////////////////////////////////

    /**
     * @dev Returns the token URI for a given token ID.
     * @param tokenId The token ID.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override checkTokenIdExists(tokenId) returns (string memory) {
        if (tokenId > revealLastIndex) return string(abi.encodePacked(baseURI, "seed.json"));
        bytes32 keccak = keccak256(abi.encodePacked(keccakPrefix, tokenId.toString()));
        return string(abi.encodePacked(baseURI, _toHexString(keccak), ".json"));
    }

    //////////////////////////////////
    //// Reveal
    //////////////////////////////////

    /**
     * @dev Last index of token that is revealed.
     */
    uint256 public revealLastIndex;

    /**
     * @dev Set the last index of token that is revealed.
     * @param index The last index of token that is revealed.
     */
    function setRevealLastIndex(uint256 index) external onlyOwner {
        revealLastIndex = index;
    }

    /**
     * @dev A magic string that is used to generate keccak256 hash for tokenURI.
     */
    string private keccakPrefix;

    /**
     * @dev Set a magic string that is used to generate keccak256 hash for tokenURI.
     * @param prefix The magic string.
     */
    function setKeccakPrefix(string memory prefix) external onlyOwner {
        keccakPrefix = prefix;
    }

    ///////////////////////////////////////////////////////////////////
    //// Minting Tokens
    ///////////////////////////////////////////////////////////////////

    /**
     * @dev Counter to point to the next token ID to mint.
     */
    CountersUpgradeable.Counter private _tokenIdCounter;

    /**
     * @dev Mint tokens to the specified address.
     * @param to The address to mint tokens to.
     * @param quantity The number of tokens to mint.
     */
    function _mintTokens(address to, uint256 quantity) private checkMintQuantity(quantity) {
        // to avoid jamming, we limit the number of tokens that can be minted per transaction
        require(quantity <= 100, "minting quantity per transaction exceeds the limit");

        for (uint256 i = 0; i < quantity; i++) {
            // Count up the token ID counter before minting
            _tokenIdCounter.increment();
            // So we start from 1, not 0
            _mint(to, _tokenIdCounter.current());
        }
    }

    modifier checkSenderIsNotContract() {
        require(msg.sender == tx.origin, "minting from contract is not allowed");
        _;
    }

    //////////////////////////////////
    //// Admin Mint
    //////////////////////////////////

    /**
     * @dev Mint tokens to the owner.
     * @param quantity The number of tokens to mint.
     */
    function adminMint(uint256 quantity) external onlyOwner {
        _mintTokens(msg.sender, quantity);
    }

    /**
     * @dev Mint tokens to the specified address.
     * @param to The address to mint tokens to.
     * @param quantity The number of tokens to mint.
     */
    function adminMintTo(address to, uint256 quantity) external onlyOwner {
        _mintTokens(to, quantity);
    }

    //////////////////////////////////
    //// Public Mint
    //////////////////////////////////

    /**
     * @dev Mint tokens to the sender with public price.
     * @param quantity The number of tokens to mint.
     */
    function publicMint(
        uint256 quantity
    ) external payable checkSenderIsNotContract whenPublicMintNotPaused checkPay(publicPrice, quantity) {
        _mintTokens(msg.sender, quantity);
    }

    //////////////////////////////////
    //// Allowlist Mint
    //////////////////////////////////

    /**
     * @dev The ID of the allowlist sale.
     */
    uint256 public allowlistSaleId;

    /**
     * @dev Increment the allowlist sale ID.
     */
    function incrementAllowlistSaleId() external onlyOwner {
        allowlistSaleId++;
    }

    /**
     * @dev The number of tokens minted in the allowlist minting for each address and sale ID.
     * Solidity does not support iterating over a mapping and clearing all entries.
     * Additionally iterating to erase all entries with another mapping to remember keys is expensive.
     * So we use a mapping of mapping to switch (reset) the mapping.
     */
    mapping(uint256 => mapping(address => uint256)) private _allowlistSaleIdToMemberMintCount;

    /**
     * @dev The number of tokens minted in the allowlist minting for the specified address.
     * @param member The address to check the number of tokens minted in the allowlist minting.
     */
    function allowlistMemberMintCount(address member) external view returns (uint256) {
        return _allowlistSaleIdToMemberMintCount[allowlistSaleId][member];
    }

    /**
     * @dev Count up the number of tokens minted in the allowlist minting for the specified address.
     * @param member The address to count up the number of tokens minted in the allowlist minting.
     * @param quantity The number of tokens to mint.
     */
    function _incrementNumberAllowlistMinted(address member, uint256 quantity) private {
        _allowlistSaleIdToMemberMintCount[allowlistSaleId][member] += quantity;
    }

    /**
     * @dev Mint tokens to the sender with allowlist price.
     * @param quantity The number of tokens to mint.
     * @param merkleProof The merkle proof of the sender's address.
     */
    function allowlistMint(
        uint256 quantity,
        bytes32[] calldata merkleProof
    )
        external
        payable
        checkSenderIsNotContract
        whenAllowlistMintNotPaused
        checkAllowlist(merkleProof)
        checkAllowlistMintLimit(quantity)
        checkPay(allowListPrice, quantity)
    {
        _incrementNumberAllowlistMinted(msg.sender, quantity);
        _mintTokens(msg.sender, quantity);
    }

    ///////////////////////////////////////////////////////////////////
    //// Minting Limit
    ///////////////////////////////////////////////////////////////////

    /**
     * @notice The maximum number of mintLimit
     */
    uint256 public constant MAX_SUPPLY = 10000;

    /**
     * @notice The maximum number of tokens that can be minted.
     */
    uint256 public mintLimit;

    /**
     * @dev Set the maximum number of tokens that can be minted.
     * @param _mintLimit The maximum number of tokens that can be minted.
     */
    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        require(_mintLimit > _tokenIdCounter.current(), "mint limit must be greater than the last token ID");
        require(_mintLimit <= MAX_SUPPLY, "mint limit must be less equal MAX_SUPPLY");
        mintLimit = _mintLimit;
    }

    /**
     * @dev Check if the minting quantity exceeds the limit.
     * @param quantity The number of tokens to mint.
     */
    modifier checkMintQuantity(uint256 quantity) {
        require(quantity > 0, "minting quantity must be greater than 0");
        require(_tokenIdCounter.current() + quantity <= mintLimit, "minting exceeds the limit");
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //// Pricing
    ///////////////////////////////////////////////////////////////////

    /**
     * @dev Check if the amount of eth sent is enough.
     * @param price The price of a token.
     * @param quantity The number of tokens to mint.
     */
    modifier checkPay(uint256 price, uint256 quantity) {
        require(msg.value == price * quantity, "invalid amount of eth sent");
        _;
    }

    //////////////////////////////////
    //// Public Mint
    //////////////////////////////////

    /**
     * @notice The price of a token in public minting.
     */
    uint256 public publicPrice;

    /**
     * @dev Set the price of a token in public minting.
     * @param publicPrice_ The price of a token in public minting.
     */
    function setPublicPrice(uint256 publicPrice_) external onlyOwner {
        publicPrice = publicPrice_;
    }

    //////////////////////////////////
    //// Allowlist Mint
    //////////////////////////////////

    /**
     * @notice The price of a token in allowlist minting.
     */
    uint256 public allowListPrice;

    /**
     * @dev Set the price of a token in allowlist minting.
     * @param allowListPrice_ The price of a token in allowlist minting.
     */
    function setAllowListPrice(uint256 allowListPrice_) external onlyOwner {
        allowListPrice = allowListPrice_;
    }

    ///////////////////////////////////////////////////////////////////
    //// Allowlist
    ///////////////////////////////////////////////////////////////////

    //////////////////////////////////
    //// Verification
    //////////////////////////////////

    /**
     * @notice The merkle root of the allowlist.
     */
    bytes32 private _merkleRoot;

    /**
     * @dev Set the merkle root of the allowlist.
     * @param merkleRoot The merkle root of the allowlist.
     */
    function setAllowlist(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    /**
     * @dev Check if the sender is allowlisted.
     * @param merkleProof The merkle proof of the sender's address.
     */
    function isAllowlisted(bytes32[] calldata merkleProof) public view returns (bool) {
        return merkleProof.verify(_merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    /**
     * @dev Check if the sender is allowlisted.
     * @param merkleProof The merkle proof of the sender's address.
     */
    modifier checkAllowlist(bytes32[] calldata merkleProof) {
        require(isAllowlisted(merkleProof), "invalid merkle proof");
        _;
    }

    //////////////////////////////////
    //// Limit
    //////////////////////////////////

    /**
     * @notice The maximum number of tokens that can be minted by an allowlisted member.
     */
    uint256 public allowlistedMemberMintLimit;

    /**
     * @dev Set the maximum number of tokens that can be minted by an allowlisted member.
     * @param quantity The maximum number of tokens that can be minted by an allowlisted member.
     */
    function setAllowlistedMemberMintLimit(uint256 quantity) external onlyOwner {
        allowlistedMemberMintLimit = quantity;
    }

    /**
     * @dev Check if the minting quantity exceeds the limit.
     * @param quantity The number of tokens to mint.
     */
    modifier checkAllowlistMintLimit(uint256 quantity) {
        require(
            _allowlistSaleIdToMemberMintCount[allowlistSaleId][msg.sender] + quantity <= allowlistedMemberMintLimit,
            "allowlist minting exceeds the limit"
        );
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //// Pausing
    ///////////////////////////////////////////////////////////////////

    event PublicMintPaused();
    event PublicMintUnpaused();
    event AllowlistMintPaused();
    event AllowlistMintUnpaused();

    //////////////////////////////////
    //// Public Mint
    //////////////////////////////////

    /**
     * @notice Whether public minting is paused.
     */
    bool public isPublicMintPaused;

    /**
     * @dev Pause public minting.
     */
    function pausePublicMint() external onlyOwner whenPublicMintNotPaused {
        isPublicMintPaused = true;
        emit PublicMintPaused();
    }

    /**
     * @dev Unpause public minting.
     */
    function unpausePublicMint() external onlyOwner whenPublicMintPaused {
        isPublicMintPaused = false;
        emit PublicMintUnpaused();
    }

    /**
     * @dev Modifier to make a function callable only when public minting is not paused.
     */
    modifier whenPublicMintNotPaused() {
        require(!isPublicMintPaused, "public mint: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when public minting is paused.
     */
    modifier whenPublicMintPaused() {
        require(isPublicMintPaused, "public mint: not paused");
        _;
    }

    //////////////////////////////////
    //// Allowlist Mint
    //////////////////////////////////

    /**
     * @notice Whether allowlist minting is paused.
     */
    bool public isAllowlistMintPaused;

    /**
     * @dev Pause allowlist minting.
     */
    function pauseAllowlistMint() external onlyOwner whenAllowlistMintNotPaused {
        isAllowlistMintPaused = true;
        emit AllowlistMintPaused();
    }

    /**
     * @dev Unpause allowlist minting.
     */
    function unpauseAllowlistMint() external onlyOwner whenAllowlistMintPaused {
        isAllowlistMintPaused = false;
        emit AllowlistMintUnpaused();
    }

    /**
     * @dev Modifier to make a function callable only when allowlist minting is not paused.
     */
    modifier whenAllowlistMintNotPaused() {
        require(!isAllowlistMintPaused, "allowlist mint: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when allowlist minting is paused.
     */
    modifier whenAllowlistMintPaused() {
        require(isAllowlistMintPaused, "allowlist mint: not paused");
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //// Withdraw
    ///////////////////////////////////////////////////////////////////

    /**
     * @notice The address to receive the withdrawal.
     */
    address private _withdrawalReceiver;

    /**
     * @dev Set the address to receive the withdrawal.
     * @param receiver The address to receive the withdrawal.
     */
    function setWithdrawalReceiver(address receiver) external onlyOwner {
        _withdrawalReceiver = receiver;
    }

    /**
     * @dev Withdraw the balance.
     */
    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(_withdrawalReceiver).call{value: amount}(new bytes(0));
        if (!success) revert("withdrawal failed");
    }

    ///////////////////////////////////////////////////////////////////
    //// Utilities
    ///////////////////////////////////////////////////////////////////

    /**
     * @dev Check if the token exists.
     * @param tokenId The token ID.
     */
    modifier checkTokenIdExists(uint256 tokenId) {
        require(_exists(tokenId), "tokenId not exist");
        _;
    }

    /**
     * @dev Convert bytes32 to hex string.
     * @param data The bytes32 data.
     */
    function _toHexString(bytes32 data) private pure returns (string memory) {
        uint256 k = uint256(data);
        bytes16 symbols = "0123456789abcdef";
        uint256 length = data.length * 2;
        bytes memory result = new bytes(length);
        for (uint256 i = 1; i <= length; i++ + (k >>= 4)) result[length - i] = symbols[k & 0xf];
        return string(result);
    }
}