// SPDX-License-Identifier: GPL-3.0-or-later

//         .;.
//      'lo;;c:.
//   .;lcokkocdkl'...................................................
//  .dXN0dld0KOl;oxxdddddddddddddddddddddddddddddddddddddddddddddddol'
// .cxkKNXK0xoxko:oOOkxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdoc:'
//  .;lxk0XN0dldOK0o;oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxl:;::'
//    .;oxkKNX00kdxkolxk00000000KKKKKKKKKKKKKKKKKKKKKKKKKKKK0kl;,;;::'
//      cOkx0XXNKxldO0k:,okkKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKkl,'',,;::'
//      cKKK0kk0NN0xooxko,.:dOKNNNNNNNNNNNNNNNNNNNNNNNNNXOc'..'',,;::'
//      cKKXXKkxkKNNKxllxocxkc;o0NNNNNNNNNNNNNNNNNNNNNNOc'....'',,;::'
//      cKKXNNNKkxkKNNKxc:d00o;:lkKNNWWWNNNNNNNNNNNWNOc.......'',,;;:'
//      cKKXNNNWWKkdxOK0xxkxxOKdc::oKNWWWWWWWNNNNWNk:.........'',,;;:'
//      cKKXNNWWWWNOxx0XNN0o;,'.. .cdxOXNWWWWWWWXk:...........'',,;;:'
//      cKXXNNWWWWWWXOx0WNo.  ....l0x''cd0NWWWXk:.............'',,;;:.
//      cKXXNNWWWWMMWKdkXx.  .;,.:xOOdlclok0Xk;................',,;;:'
//      cKXXNNWWWWWWMMWWKc  .':lxOOxxko:;,',dd'................',,;;:'
//      cKXXNNWWWWMMMMMMW0xdd0NWWNx,..     ;do,................',,;;:'
//      cKXXNNWWWWWMMMMMMMMW0oo0WO'  .','.,k0l.'::,............',,;;:'
//      cKXXNNWWWWMMMMMMMMMMW0kK0;   ';,.,dkkkkdlodl;..........'',;;:'
//      cKXXNNWWWWMMMMMMMMMMMMWWO,..':odx00kdoo:'..:xc.........'',;;:'
//      cKXXNNWWWWMMMMMMMMMMMWMNOodkkKNNWWKc.. ...'od:.........'',;;:'
//      cKXXNNWWWWMMMMMMMMMMMW0dc:col:d0XXc. .;c,.lKOc,:ll;....'',;;:'
//      cKXXNNNWWWMMMMMMMMMWKdc:::::::xKKo.  .:;,lkxk0Oocc;....'',;;:'
//      cKXXNNNWWWMMMMMMMWKxlccc::::::cloc,,,cx0KX0d::,..   ...'',;;:'
//      cKKXXNNWWWMMMMMWKxlcccc:::::::::::okkxkKWNd.  ..;:'.':,'',;;:'
//      cKKXXNNWWWWMMWXklcccccc::::::::::;;::,:kXx..'oxxkOko,,cl:,;;:'
//      cKKXXNNWWWWWXklcccccccc::::::::::::;;;lOk, .cXWXOkxkko,cxdc;:'
//      cKKXXNNWWWXkocccccccccccc:::::::::::;;;cc'..,ckNNK0kxkOkdldxo'
//      cKKXXNNNXkocccccccccccccccccc::::::::::;;;,;lllOXXNKOOOOkxxdoc.
//      cKKXXXKOdlllllllcccccccccccccccccc::::::::::;lkOddKNNKOkOOOd,,cc.
//      cKKKKOdolllllllllllcccccccccccccccccc::::::::::ldOOxONXXOxxkkodxo;.
//      c00kdoooooollllllllllccccccccccccccccccccccccccccoddkkkXNKkxxO0x;'.
//      ;dlllccccccccccc:::::::::::::::::::::::::::::::::::ldo:ckNN0kxxo'
//                                                           .:c:ckNXo'
//                                                             .:c,;,.
//                                                               ..

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Ownable is required by OpenSea.
contract Batons is
    ERC721,
    VRFConsumerBase,
    ReentrancyGuard,
    IERC2981,
    Ownable,
    AccessControl
{
    using Strings for uint256; // enables number.toString()

    uint256 public constant BATONS_PER_GROUP = 1968;
    uint256 public constant CHARITY_GROUPS = 4;
    uint256 public constant MAX_BATON_SUPPLY =
        BATONS_PER_GROUP * CHARITY_GROUPS;
    uint256 public constant SALE_PRICE = 0.1 ether;
    uint256 public constant MAX_AMOUNT_PER_MINT = 4;
    string private constant CONTRACT_METADATA_URI =
        "ipfs://QmWHCVAykdMdUYEcqrCSgMUQjZXFEvNLDBfwLW3vEQFhfj";

    // Create a new role identifier for the treasurer role.
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");

    uint256 public constant BRONZE_UPGRADE = 0.5 ether;
    uint256 public constant SILVER_UPGRADE = 2.5 ether;
    uint256 public constant GOLD_UPGRADE = 7.5 ether;
    uint256 public constant CHARITY_SALES_PCT = 30;
    uint256 constant ROYALTY_PERCENT_BIPS = 750; // = 7.5%

    // The numbers of batons minted non-publicly, e.g., advisors and early
    // birds, by each wallet address. Note that `balanceOf()` cannot substitute
    // these state variables due to the mint-and-transfer hack.
    mapping(address => mapping(uint256 => uint256)) private _advisorMints;
    mapping(address => mapping(uint256 => uint256)) private _earlyBirdMints;

    function getBatonDonation(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return batonDonations[_tokenId];
    }

    function getAdvisorMints(address _advisor, uint256 _charityGroup)
        external
        view
        returns (uint256)
    {
        return _advisorMints[_advisor][_charityGroup];
    }

    function getEarlyBirdMints(address _earlyBird, uint256 _charityGroup)
        external
        view
        returns (uint256)
    {
        return _earlyBirdMints[_earlyBird][_charityGroup];
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not the admin"
        );
        _;
    }

    modifier onlyTreasurer() {
        require(
            hasRole(TREASURER_ROLE, msg.sender),
            "Caller is not the treasurer"
        );
        _;
    }

    bytes32 private immutable vrfKeyHash;
    uint256 private immutable vrfFee; // in LINK.

    /**
     * @param _vrfCoordinator Address of the Chainlink VRF Coordinator. See [Chainlink VRF Addresses](https://docs.chain.link/docs/vrf-contracts/) for details.
     * @param _link Address of the LINK token. See [LINK Token Addresses](https://docs.chain.link/docs/link-token-contracts/) for details.
     * @param _vrfKeyHash The public key against which randomness is generated. See [Chainlink VRF Addresses](https://docs.chain.link/docs/vrf-contracts/) for details.
     * @param _vrfFee The fee, in LINK, for the request. Specified by the oracle.
     */
    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _vrfKeyHash,
        uint256 _vrfFee,
        address _treasurer
    )
        VRFConsumerBase(_vrfCoordinator, _link)
        ERC721("Pass the Baton", "BATON")
    {
        // We need to make sure that the treasurer is different from the admin
        // (deployer). If not, there'll be no treasurer when the admin calls
        // `renounceAdmin()` because it revokes all of their roles. Nobody can
        // grant the treasurer role ever again once the admin role is renounced.
        require(
            _treasurer != msg.sender,
            "Treasurer should be different from deployer"
        );
        vrfKeyHash = _vrfKeyHash;
        vrfFee = _vrfFee;
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles. Note that _setupRole() is for
        // constructor only. Use grantRole() outside of the constructor.
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Grant the deployer the treasurer role as well.
        _setupRole(TREASURER_ROLE, msg.sender);
        // Grant the treasurer the treasurer role.
        _setupRole(TREASURER_ROLE, _treasurer);
    }

    // Once the admin renounces their roles, nobody can grant someone the
    // treasurer role ever again. Even the treasurer cannot.
    function renounceAdmin() external onlyAdmin {
        require(saleState == State.LIVE, "Admin required to start sale");
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        renounceRole(TREASURER_ROLE, msg.sender);
        if (owner() == msg.sender) {
            renounceOwnership();
        }
    }

    // For when the constructor granted a wrong user the treasurer role.
    function grantTreasurer(address _treasurer) external onlyAdmin {
        grantRole(TREASURER_ROLE, _treasurer);
    }

    // For when the constructor granted a wrong user the treasurer role.
    function revokeTreasurer(address _treasurer) external onlyAdmin {
        revokeRole(TREASURER_ROLE, _treasurer);
    }

    /* CHARITY GROUPS AND PAYMENT SPLITTERS */
    PaymentSplitter[CHARITY_GROUPS + 1] private charityGroupSplitters;
    PaymentSplitter private artistAndDevSplitter;
    PaymentSplitter private royaltySplitter;

    /* STATE, SALES, AND PRESALES */
    enum State {
        ADVISOR_SALE, // Only advisors can mint
        PRESALE, // 12 hour presale window for earlybirds and advisors
        LIVE // sale
    }
    State public saleState = State.ADVISOR_SALE;
    bytes32 private advisorMerkleRoot; // redeem for free
    bytes32 private earlybirdMerkleRoot; // redeem early
    uint256[CHARITY_GROUPS + 1] private nextMintIdx; // holds the index of the next token to mint in each charity group, 0 <= nextMintIdx[i] < 1968

    // Returns the number of batons mintable in the given charity group.
    function numMintableBatons(uint256 _charityGroup)
        external
        view
        returns (uint256)
    {
        return BATONS_PER_GROUP - nextMintIdx[_charityGroup];
    }

    /**
     * internal function that keeps track of pointers within charity groups and prevents out-of-bounds
     * @param _charityGroup - the charityGroup
     * @dev payment is to be handled by each caller
     */
    function _mintToCharityGroup(
        uint256 _charityGroup,
        address _recipient,
        uint256 _amountToMint
    ) internal returns (uint256 firstTokenId) {
        require(
            0 < _amountToMint &&
                _amountToMint <= BATONS_PER_GROUP - nextMintIdx[_charityGroup],
            "Charity Group is sold out"
        );
        firstTokenId =
            _charityGroup *
            BATONS_PER_GROUP +
            nextMintIdx[_charityGroup];
        for (uint256 i = 0; i < _amountToMint; ++i) {
            _safeMint(_recipient, firstTokenId + i);
        }
        nextMintIdx[_charityGroup] += _amountToMint;
    }

    /**
     * free reserved batons for handful of advisors and artist
     */
    function mintAdvisor(
        address _advisor,
        uint256 _charityGroup,
        uint256 _maxMints,
        bytes32[] calldata _merkleProof,
        uint256 _amountToMint
    ) external nonReentrant onlyMintableGroup(_charityGroup) {
        bytes32 node = getMerkleLeaf(_advisor, _charityGroup, _maxMints);
        require(
            MerkleProof.verify(_merkleProof, advisorMerkleRoot, node),
            "Invalid Merkle proof"
        );
        require(
            _advisorMints[_advisor][_charityGroup] + _amountToMint <= _maxMints,
            "Tried to mint too many"
        );
        _advisorMints[_advisor][_charityGroup] += _amountToMint;
        _mintToCharityGroup(_charityGroup, _advisor, _amountToMint);
    }

    /**
     * Supporters will have the opportunity to mint batons
     * during the presale. Once the public sale is live, they'd
     * just have to mint like everyone else.
     */
    function mintEarlybird(
        address _supporter,
        uint256 _charityGroup,
        uint256 _maxMints,
        bytes32[] calldata _merkleProof,
        uint256 _amountToMint
    ) external payable nonReentrant onlyMintableGroup(_charityGroup) {
        require(saleState != State.ADVISOR_SALE, "Presale hasn't started");
        require(
            address(charityGroupSplitters[_charityGroup]) != address(0) &&
                address(artistAndDevSplitter) != address(0),
            "PaymentSplitters not set"
        );
        require(msg.value == SALE_PRICE * _amountToMint, "Wrong ETHs received");
        bytes32 node = getMerkleLeaf(_supporter, _charityGroup, _maxMints);
        require(
            MerkleProof.verify(_merkleProof, earlybirdMerkleRoot, node),
            "Invalid Merkle proof"
        );
        require(
            _earlyBirdMints[_supporter][_charityGroup] + _amountToMint <=
                _maxMints,
            "Tried to mint too many"
        );
        _earlyBirdMints[_supporter][_charityGroup] += _amountToMint;
        // Pay the charity group.
        uint256 amountToCharityGroup = (msg.value * CHARITY_SALES_PCT) / 100;
        (bool sent, ) = address(charityGroupSplitters[_charityGroup]).call{
            value: amountToCharityGroup
        }("");
        require(sent, "Payment failed");
        // Pay the artist and dev teams.
        (sent, ) = address(artistAndDevSplitter).call{
            value: msg.value - amountToCharityGroup
        }("");
        require(sent, "Payment failed");
        _mintToCharityGroup(_charityGroup, _supporter, _amountToMint);
    }

    function mintPublic(uint256 _charityGroup, uint256 _amountToMint)
        external
        payable
        nonReentrant
        onlyMintableGroup(_charityGroup)
    {
        require(saleState == State.LIVE, "Sale state isn't LIVE");
        require(
            address(charityGroupSplitters[_charityGroup]) != address(0) &&
                address(artistAndDevSplitter) != address(0),
            "PaymentSplitters not set"
        );
        require(
            _amountToMint <= MAX_AMOUNT_PER_MINT,
            "Tried to mint too many per request"
        );
        require(msg.value == SALE_PRICE * _amountToMint, "Wrong ETHs received");
        // Pay the charity group.
        uint256 amountToCharityGroup = (msg.value * CHARITY_SALES_PCT) / 100;
        (bool sent, ) = address(charityGroupSplitters[_charityGroup]).call{
            value: amountToCharityGroup
        }("");
        require(sent, "Payment failed");
        // Pay the artist and dev teams.
        (sent, ) = address(artistAndDevSplitter).call{
            value: msg.value - amountToCharityGroup
        }("");
        require(sent, "Payment failed");
        _mintToCharityGroup(_charityGroup, msg.sender, _amountToMint);
    }

    /* SALE LIFECYCLE */
    function stopSale() external onlyAdmin {
        require(saleState != State.ADVISOR_SALE, "Sale state is ADVISOR_SALE");
        saleState = State.ADVISOR_SALE;
    }

    function startPresale() external onlyAdmin {
        require(
            saleState == State.ADVISOR_SALE,
            "Sale state isn't ADVISOR_SALE"
        );
        require(
            address(royaltySplitter) != address(0),
            "Configure payment splitters"
        );
        saleState = State.PRESALE;
    }

    function startSale() external onlyAdmin {
        require(saleState == State.PRESALE, "Sale state isn't PRESALE");
        saleState = State.LIVE;
    }

    /* RANDOMIZATION AND REVEALING METADATA */
    uint256 private randomOffset; // random result % 1968
    string private baseURI =
        "ipfs://QmZP6G4ddkh8XcTAbeStDRox3e2msNaKWNEAk3dagjbJ1T/"; // an ipfs:// URL ending in a slash

    /**
     * @param _ipfsBase MUST end in a slash (/).
     */
    function revealMetadata(string memory _ipfsBase)
        public
        onlyAdmin
        returns (bytes32)
    {
        require(LINK.balanceOf(address(this)) >= vrfFee, "Not enough LINK");
        baseURI = _ipfsBase;
        return requestRandomness(vrfKeyHash, vrfFee);
    }

    function fulfillRandomness(
        bytes32, /*requestId*/
        uint256 randomness
    ) internal override {
        randomOffset = randomness % MAX_BATON_SUPPLY;
    }

    function assetIdForToken(uint256 _tokenId)
        public
        view
        returns (uint256 assetId)
    {
        uint256 charityGroup = _tokenId / BATONS_PER_GROUP;
        uint256 offset = (_tokenId + randomOffset) % BATONS_PER_GROUP;
        assetId = charityGroup * BATONS_PER_GROUP + offset;
    }

    function charityGroupForToken(uint256 _tokenId)
        public
        pure
        returns (uint256)
    {
        return _tokenId / BATONS_PER_GROUP;
    }

    /* DONATIONS & EVOLUTIONS */
    uint256[MAX_BATON_SUPPLY + BATONS_PER_GROUP] private batonDonations; // per baton - with an extra slot for final batons

    event Donated(
        uint256 indexed tokenId,
        address indexed donor,
        uint256 amount
    );

    /**
     * Determine how "upgraded" the token is for use in `tokenURI`.
     * Upgrades come from donations
     */
    function getEvolutionLevel(uint256 _tokenId) public view returns (uint256) {
        require(
            0 <= charityGroupForToken(_tokenId) &&
                charityGroupForToken(_tokenId) < CHARITY_GROUPS,
            "Final batons don't evolve"
        );
        uint256 amountDonated = batonDonations[_tokenId];
        if (amountDonated >= GOLD_UPGRADE) {
            return 3;
        } else if (amountDonated >= SILVER_UPGRADE) {
            return 2;
        } else if (amountDonated >= BRONZE_UPGRADE) {
            return 1;
        } else {
            // default non-upgraded state
            return 0;
        }
    }

    function donate(uint256 _tokenId) external payable nonReentrant {
        require(
            msg.sender == ownerOf(_tokenId),
            "You must own the baton to donate"
            /* ownerOf also asserts that _exists(_tokenId) */
        );
        uint256 charityGroup = charityGroupForToken(_tokenId);
        // An advisor can mint batons and donate to them even before the
        // PaymentSplitters are set.
        require(
            address(charityGroupSplitters[charityGroup]) != address(0),
            "PaymentSplitters not set"
        );
        batonDonations[_tokenId] += msg.value;
        (bool sent, ) = address(charityGroupSplitters[charityGroup]).call{
            value: msg.value
        }("");
        require(sent, "Donation failed");
        emit Donated(_tokenId, msg.sender, msg.value);
    }

    // looks at the paymentsplitter to calculate how much has been donated to a charity group
    function cumulativePayoutTo(PaymentSplitter _p)
        internal
        view
        returns (uint256)
    {
        if (address(_p) == address(0)) {
            return 0;
        }
        return _p.totalReleased() + address(_p).balance;
    }

    /**
     * The amount given to a charity is a factor of primary sales, secondary sales (times charity %), and donations
     */
    function getAmountDonated(uint256 _charityGroup)
        public
        view
        returns (uint256)
    {
        uint256 donationVolume = cumulativePayoutTo(
            charityGroupSplitters[_charityGroup]
        );
        if (_charityGroup == CHARITY_GROUPS) {
            // Final baton group has no primary sales. Final baton royalties count
            // towards project charities, so are intentionally excluded.
            return donationVolume;
        }
        uint256 secondaryVolume = cumulativePayoutTo(royaltySplitter);
        // the amount specific to this charity. final batons don't count in the divisor bc
        return
            donationVolume +
            ((secondaryVolume / CHARITY_GROUPS) * CHARITY_SALES_PCT) /
            100;
    }

    /**
     * the amount raised from the project is a function of primaries, royalties, and donations
     */
    function getDonationsFromProject() external view returns (uint256 total) {
        total = 0;
        for (uint256 i = 0; i < CHARITY_GROUPS + 1; i++) {
            total += getAmountDonated(i);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint256 batonId = assetIdForToken(_tokenId);
        string memory relativePath;
        if (charityGroupForToken(_tokenId) == CHARITY_GROUPS) {
            // final baton, no evolution level
            relativePath = string(
                abi.encodePacked(batonId.toString(), "/0.json")
            );
        } else {
            uint256 evolutionLevel = getEvolutionLevel(_tokenId);
            relativePath = string(
                abi.encodePacked(
                    batonId.toString(),
                    "/",
                    evolutionLevel.toString(),
                    ".json"
                )
            );
        }
        return
            bytes(_baseURI()).length > 0
                ? string(abi.encodePacked(_baseURI(), relativePath))
                : "";
    }

    /**
     * FINAL EVOLUTION BURN-TO-Mint
     * @param _tokenIds, tokenId array with a token for each charity group
     * batons must be in final evolution. batons must be owned by caller
     * @return tokenId of newly created baton, in range [1968*4-1968*5)
     * @dev it's not necessary to enforce <= 1968 final batons because
     *      that's guaranteed by the burn-to-mint logic
     */
    function burnToMint(uint256[CHARITY_GROUPS] calldata _tokenIds)
        external
        nonReentrant
        returns (uint256 tokenId)
    {
        // CHECKS
        for (uint256 i = 0; i < CHARITY_GROUPS; i++) {
            require(
                charityGroupForToken(_tokenIds[i]) == i,
                "Must have a token from each charity"
            );
            require(
                getEvolutionLevel(_tokenIds[i]) == 3,
                "Must be in final form"
            );
            require(
                ownerOf(_tokenIds[i]) == msg.sender,
                /* ownerOf also asserts _exists() */
                "Must own the batons to burn-to-mint"
            );
        }
        for (uint256 i = 0; i < CHARITY_GROUPS; i++) {
            _burn(_tokenIds[i]);
        }
        tokenId = _mintToCharityGroup(CHARITY_GROUPS, msg.sender, 1);
        // The donation amounts of all four burnt batons are aggregated and
        // transferred to the newly minted baton.
        for (uint256 i = 0; i < CHARITY_GROUPS; i++) {
            batonDonations[tokenId] += batonDonations[_tokenIds[i]];
            batonDonations[_tokenIds[i]] = 0;
        }
    }

    // See https://docs.opensea.io/docs/contract-level-metadata for details.
    function contractURI() public pure returns (string memory) {
        return CONTRACT_METADATA_URI;
    }

    /* ROYALTIES */
    function royaltyInfo(
        uint256, /*_tokenId*/
        uint256 _salePrice
    )
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(royaltySplitter);
        require(receiver != address(0));
        royaltyAmount = (_salePrice * ROYALTY_PERCENT_BIPS) / 10000;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /* HELPER FUNCTIONS */
    function getMerkleLeaf(
        address _claimer,
        uint256 _charityGroup,
        uint256 _maxMints
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_claimer, _charityGroup, _maxMints));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Checks if _charityGroup can be minted by users.
     */
    modifier onlyMintableGroup(uint256 _charityId) {
        require(
            0 <= _charityId && _charityId < CHARITY_GROUPS,
            "Can only mint one of four lanes"
        );
        _;
    }

    function setAdvisorMerkleRoot(bytes32 _merkleRoot) public onlyAdmin {
        require(
            saleState == State.ADVISOR_SALE,
            "Sale state isn't ADVISOR_SALE"
        );
        advisorMerkleRoot = _merkleRoot;
    }

    function setEarlybirdMerkleRoot(bytes32 _merkleRoot) public onlyAdmin {
        require(
            saleState == State.ADVISOR_SALE,
            "Sale state isn't ADVISOR_SALE"
        );
        earlybirdMerkleRoot = _merkleRoot;
    }

    function setPaymentSplitters(
        address[] calldata _charityGroupSplitters,
        address _artistAndDevSplitter,
        address _royaltySplitter
    ) public onlyTreasurer {
        require(
            _charityGroupSplitters.length == CHARITY_GROUPS + 1,
            "Need a PaymentSplitter for each charity group"
        );
        for (uint256 i = 0; i < _charityGroupSplitters.length; i++) {
            charityGroupSplitters[i] = PaymentSplitter(
                payable(_charityGroupSplitters[i])
            );
        }
        artistAndDevSplitter = PaymentSplitter(payable(_artistAndDevSplitter));
        royaltySplitter = PaymentSplitter(payable(_royaltySplitter));
    }

    function _pendingPaymentAmount(PaymentSplitter _splitter, address _payee)
        private
        view
        returns (uint256)
    {
        if (address(_splitter) == address(0)) {
            return 0;
        }
        uint256 totalReceived = address(_splitter).balance +
            _splitter.totalReleased();
        uint256 alreadyReleased = _splitter.released(_payee);
        return
            (totalReceived * _splitter.shares(_payee)) /
            _splitter.totalShares() -
            alreadyReleased;
    }

    // Returns the pending payment amount for the payee. You need to call
    // pullPayments() to actually transfer ETHs to the payee.
    function pendingPaymentAmount(address _payee)
        external
        view
        returns (uint256)
    {
        uint256 amount = _pendingPaymentAmount(royaltySplitter, _payee);
        amount += _pendingPaymentAmount(artistAndDevSplitter, _payee);
        for (uint256 i = 0; i < CHARITY_GROUPS + 1; i++) {
            amount += _pendingPaymentAmount(charityGroupSplitters[i], _payee);
        }
        return amount;
    }

    // Transfers ETHs from all PaymentSplitters to the payee. You may call
    // pendingPaymentAmount() to see if the payee has any pending payments.
    function pullPayments(address payable _payee) external {
        // Try to pull the royalty payments. The try-catch block is
        // required because PaymentSplitter.release() fails if the payee doesn't
        // have any shares or pending payments.
        try royaltySplitter.release(_payee) {} catch {}
        for (uint256 i = 0; i < CHARITY_GROUPS + 1; i++) {
            // Try to pull the charity payments. See the comment above.
            try charityGroupSplitters[i].release(_payee) {} catch {}
        }
        // Try to pull the artist and dev payments. See the comment above.
        try artistAndDevSplitter.release(_payee) {} catch {}
    }
}