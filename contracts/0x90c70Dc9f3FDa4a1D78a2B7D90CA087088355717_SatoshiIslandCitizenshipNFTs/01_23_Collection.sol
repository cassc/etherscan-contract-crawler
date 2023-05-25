pragma solidity 0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import {Authorizable} from "../lib/Authorizable.sol";
import {Coupon} from "./Coupon.sol";
import {IANS} from "../ans/IANS.sol";
import {IRevocable} from "../interfaces/IRevocable.sol";
import {ICollection} from "./ICollection.sol";

contract SatoshiIslandCitizenshipNFTs is
    ICollection,
    IRevocable,
    ERC721Burnable,
    ReentrancyGuard,
    Coupon,
    Authorizable,
    VRFConsumerBaseV2
{
    using Strings for uint256;

    struct VRF {
        uint64 subscriptionId;
        uint256 requestId;
        uint16 requestConfirmations;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint256 randomWord;
        uint32 wordCount;
    }

    //compartmentalizing VRF and subscription
    VRF public vrf;
    VRFCoordinatorV2Interface public immutable coordinator;
    LinkTokenInterface public immutable linkToken;

    string private _termsAndConditions;

    //mapping of token owner to primary identity
    struct PrimaryIdentity {
        uint256 tokenId;
        uint256 unlockedAt;
    }
    mapping(address => PrimaryIdentity) private _primaryIdentities;

    //supply dynamics
    uint256 public constant maxSupply = 21_000;
    uint256 public totalSupply;

    //ANS configurations
    address public ANS;

    //metadata configurations
    string public baseURI;
    bool public permanentURI;

    //state of sale
    bool public active;

    event URIConfigured(string uri, uint256 timestamp);
    event ANSConfigured(address ans, uint256 timestamp);
    event WhitelistUpdated(string ipfsLink, uint256 timestamp);
    event PrimaryIdentityConfigured(address account, uint256 tokenId);
    event PrimaryIdentityRevoked(address account);
    event baseUriChanged(string baseUri);
    event baseUriSetPermanently(string baseUri);

    /// @dev initialization
    /// @param _name -> the name of the collection {ERC721}
    /// @param _symbol -> the symbol of the collection {ERC721}
    /// @param URI -> the base URI of the collection {ERC721}
    /// @param _TAC -> the terms and conditions ipfs link
    /// @param vrfCoordinatorAddress -> the vrf coordinator address to rely on {https://docs.chain.link/docs/vrf/v2/examples/get-a-random-number/}
    /// @param vrfSubscriptionId -> the vrf subscription id, required by the vrf coordinator {https://docs.chain.link/docs/vrf/v2/examples/get-a-random-number/}
    /// @param vrfKeyHash -> the vrf key hash (Max gas price), get values from https://vrf.chain.link/mainnet {https://docs.chain.link/docs/vrf/v2/introduction/}
    /// @param linkTokenAddress -> the token address of LINK, needed to setup the VRF integration [required by the VRF] {https://docs.chain.link/docs/vrf/v2/examples/get-a-random-number/}
    /// @param couponSigner -> the EOA of whitelist manager (coupons signer) {https://eips.ethereum.org/EIPS/eip-712}
    /// @param couponSignatureVersion -> the signature domain separator version, Signatures from different versions are not compatible {https://eips.ethereum.org/EIPS/eip-712}
    constructor(
        string memory _name,
        string memory _symbol,
        string memory URI,
        string memory _TAC,
        address vrfCoordinatorAddress,
        uint64 vrfSubscriptionId,
        bytes32 vrfKeyHash,
        address linkTokenAddress,
        address couponSigner,
        string memory couponSignatureVersion
    )
        ERC721(_name, _symbol)
        VRFConsumerBaseV2(vrfCoordinatorAddress)
        Coupon(couponSigner, _name, couponSignatureVersion)
    {
        // VRF integration setup
        coordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
        linkToken = LinkTokenInterface(linkTokenAddress);

        // VRF consumer configuration
        vrf.subscriptionId = vrfSubscriptionId;
        vrf.requestConfirmations = 3;
        vrf.keyHash = vrfKeyHash;
        vrf.callbackGasLimit = 100000;
        vrf.wordCount = 1;

        // Collection setup
        baseURI = URI;
        _termsAndConditions = _TAC;

        emit URIConfigured(URI, block.timestamp);
    }

    /// @dev functionality for enabling ANS configurations
    /// @param newANS -> the address of ANS endpoint
    /// @return successful -> confirmation of activity
    function setANS(address newANS)
        external
        onlyAuthorized
        returns (bool successful)
    {
        require(newANS != address(0), "must not be the zero address");

        ANS = newANS;
        emit ANSConfigured(newANS, block.timestamp);
        successful = true;
    }

    /// @dev functionality for setting the primary identity of a citizenship
    /// @param tokenId --> the token id of the citizenship
    /// @return successful -> confirmation of activity
    function setPrimary(uint256 tokenId) external returns (bool successful) {
        require(ownerOf(tokenId) == msg.sender, "must be owner of token id");

        _primaryIdentities[msg.sender].tokenId = tokenId;
        emit PrimaryIdentityConfigured(msg.sender, tokenId);
        successful = true;
    }

    /// @dev functionality for revoking the primary identity of a citizenship
    /// @return successful -> confirmation of activity
    function revokePrimary() external returns (bool successful) {
        require(
            _primaryIdentities[msg.sender].unlockedAt < block.timestamp,
            "must wait for primary lock to expire"
        );

        delete _primaryIdentities[msg.sender];
        emit PrimaryIdentityRevoked(msg.sender);
        successful = true;
    }

    /// @dev functionality for locking a primary identity of a citizenship
    /// @return successful -> confirmation of activity
    function lockPrimary(uint256 durationInSeconds)
        external
        returns (bool successful)
    {
        require(
            _primaryIdentities[msg.sender].tokenId != 0,
            "must set a primary identity"
        );

        uint256 lockDuration = block.timestamp + durationInSeconds;
        require(
            lockDuration > _primaryIdentities[msg.sender].unlockedAt,
            "must not shorten existing lock duration"
        );

        _primaryIdentities[msg.sender].unlockedAt = lockDuration;
        emit PrimaryIdentityRevoked(msg.sender);
        successful = true;
    }

    /// @dev persist the whitelist ipfs link as an event log (there will be multiple separate lists)
    /// @param ipfsLink -> the whitelist ipfs link
    function logWhitelist(string memory ipfsLink) external onlyOwner {
        emit WhitelistUpdated(ipfsLink, block.timestamp);
    }

    /// @dev functionality for minting tokens
    function mint(
        uint256 id,
        uint256 expiresAt,
        bytes memory signature
    ) external onlyWithCoupon(id, expiresAt, signature) nonReentrant {
        require(active, "sale must be configured");

        require(totalSupply < maxSupply, "Citizenship: exceeded max supply");

        uint256 tokenId = ((vrf.randomWord + id) % maxSupply) + 1;
        receipts[id] = tokenId;
        totalSupply++;

        _safeMint(msg.sender, tokenId);
    }

    /// @dev functionality for airdropping tokens
    ///      - SHOULD adhere to randomness logic
    /// @param ids -> the ids of whitelist coupons
    /// @return successful -> confirmation of activity
    function airdrop(uint256[] calldata ids, address[] calldata recipients)
        external
        onlyOwner
        returns (bool successful)
    {
        require(vrf.randomWord > 0, "Citizenship: randomness not ready");
        require(recipients.length == ids.length, "Citizenship: unmatched");

        uint256 counter = ids.length;
        totalSupply += counter;

        require(totalSupply <= maxSupply, "Citizenship: exceeded max supply");

        for (uint256 i = 0; i < counter; i++) {
            uint256 tokenId = ((vrf.randomWord + ids[i]) % maxSupply) + 1;
            _safeMint(recipients[i], tokenId);
        }

        successful = true;
    }

    /// @dev functionality for airdropping tokens by tokenId
    ///      - The randomness won't apply to this function
    /// @param tokenIds -> the tokenId list
    /// @return successful -> confirmation of activity
    function airdrop(uint256[] calldata tokenIds)
        external
        onlyOwner
        returns (bool successful)
    {
        uint256 counter = tokenIds.length;
        totalSupply += counter;

        require(totalSupply <= maxSupply, "Citizenship: exceeded max supply");

        for (uint256 i = 0; i < counter; i++) {
            _safeMint(msg.sender, tokenIds[i]);
        }

        successful = true;
    }

    function burn(uint256 tokenId) public override onlyAuthorized {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
        totalSupply--;
    }

    /// @dev functionality for state of sale
    /// @param state -> the state of the sale {true to activate, false to deactivate}
    /// @return successful -> confirmation of activity
    function setSaleState(bool state)
        external
        onlyOwner
        returns (bool successful)
    {
        require(vrf.randomWord > 0, "randomness not ready");
        active = state;
        successful = true;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        require(permanentURI == false, "Citizenship: permanent uri");
        baseURI = newBaseURI;
    }

    function markUriAsPermanent() external onlyOwner {
        permanentURI = true;
    }

    /// @dev set the legal rights link, onlyOwner
    function updateTermsAndConditions(string calldata link) external onlyOwner {
        _termsAndConditions = link;
    }

    /// @dev functionality for generating random word for vrf
    function requestRandomWords() external onlyOwner {
        require(vrf.randomWord == 0, "Citizenship: randomness replay ");

        //reverts if subscription is not set and funded.
        vrf.requestId = coordinator.requestRandomWords(
            vrf.keyHash,
            vrf.subscriptionId,
            vrf.requestConfirmations,
            vrf.callbackGasLimit,
            vrf.wordCount
        );
    }

    /// @dev functionality that allows authorized revocation
    /// @param to -> the recipient of the token
    /// @param tokenId -> the token id to be revoked
    /// @return successful -> confirmation of activity
    function revoke(address to, uint256 tokenId)
        external
        onlyAuthorized
        returns (bool successful)
    {
        address tokenOwner = ownerOf(tokenId);
        super._transfer(tokenOwner, to, tokenId);
        emit Revoked(tokenOwner, to, tokenId);
        successful = true;
    }

    function safeTransferFromBatch(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external {
        uint256 buffer = tokenIds.length;
        for (uint256 i; i < buffer; i++) {
            safeTransferFrom(from, to, tokenIds[i]);
        }
    }

    function getPrimaryIdentity(address account)
        external
        view
        returns (uint256)
    {
        return _primaryIdentities[account].tokenId;
    }

    function getPrimaryIdentityLock(address account)
        external
        view
        returns (uint256)
    {
        return _primaryIdentities[account].unlockedAt;
    }

    /// @dev returns the legal contract link
    function getTermsAndConditions() external view returns (string memory) {
        return _termsAndConditions;
    }

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

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    /// @dev unused function, inheritance graph
    /// @param . -> input argument not used
    /// @param randomWords -> randomness
    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        vrf.randomWord = randomWords[0];
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        //if token id is primary identity of sender, then the token can't be transferred,
        //unless the recipient is authorized (composability for future contract flexibility)
        //the sender must first revoke the token id to enable transferability of the token id
        if (!authorized[to]) {
            require(
                !_isPrimaryIdentity(from, tokenId),
                "must revoke token id from primary identity"
            );
        }
        // 1- Check if the ANS is configured, means the ANS contract is up serving requests
        // 2- Check if 2FA is enabled by the token owner
        // If 1 and 2 are satisfied we must make sure that the token owner
        // have approved the transfer of the token by {from} and not {msg.sender}
        // to make sure that transferFrom have to pass through the same process
        if (ANS != address(0)) {
            if (IANS(ANS).isAuthEnabled(from)) {
                //fetch request status and request index
                (bool successful, uint256 index) = IANS(ANS)
                    .isTokenTransferRequestApproved(
                        from,
                        address(this),
                        tokenId
                    );

                require(
                    successful,
                    "token transfer request must be approved by trustees"
                );
                // There's no Reentrancy risk because IANS is a contract owned by the same project
                IANS(ANS).clearRequest(from, index);
            }
        }
        // Transfer the asset
        super._transfer(from, to, tokenId);
    }

    // @dev fetch whether a token id is configured as primrary identity for an account
    /// @return successful -> confirmation of activity
    function _isPrimaryIdentity(address account, uint256 tokenId)
        private
        view
        returns (bool successful)
    {
        successful = _primaryIdentities[account].tokenId == tokenId;
    }
}