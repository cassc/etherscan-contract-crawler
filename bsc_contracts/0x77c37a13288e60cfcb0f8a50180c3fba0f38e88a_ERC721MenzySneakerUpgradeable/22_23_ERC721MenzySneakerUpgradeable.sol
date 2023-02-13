//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "./VRFConsumerBaseV2Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

// import "hardhat/console.sol";

contract ERC721MenzySneakerUpgradeable is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    EIP712Upgradeable,
    VRFConsumerBaseV2Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    // events
    event TokenRedeemed(uint256 tokenId, address buyer);
    event LootBoxTokensRedeemed(uint256 requestId, uint256[] tokenId);
    event LootBoxVoucherExpired(uint256[] tokenId, uint256[] collectionTime);
    event LootBoxOpenRequested(uint256 nftsAmount, uint256 s_requestId);
    event SneakersFused(
        uint256 _sneaker1,
        uint256 _sneaker2,
        uint256 nextFusionToken
    );

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private constant SIGNING_DOMAIN = "SneakerNFT-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    mapping(address => uint256) pendingWithdrawals;
    string private baseURI;

    // keep track of NFTs claimed from loot boxes
    uint256 lootBoxNFTs;
    // keep track of NFTs that are products of fusion
    uint256 fusionNFTs;

    // VRF variables
    VRFCoordinatorV2Interface public COORDINATOR;
    LinkTokenInterface public LINKTOKEN;
    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 public keyHash;
    uint64 public s_subscriptionId;

    // randomizer
    uint256 private randoms;

    // gas limit for minting 1 NFT from a loot box
    uint32 public gasLimit;
    // gas per loot box
    uint32 public gasPerLootBox;

    // request ID to lootbox ID
    mapping(uint256 => Request) private requests;

    // sneaker tier chances
    uint256[] public sneakerChances;

    // enums
    enum SneakerTier {
        none,
        common,
        uncommon,
        rare,
        legendary
    }

    /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
    struct NFTVoucher {
        /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
        uint256 tokenId;
        /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
        uint256 minPrice;
        /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }
    struct LootBoxVoucher {
        /// @notice The id of the token to be redeemed from loot boxes. Must be unique - if another token with this ID already exists, the redeem function will revert.
        uint256[] tokenId;
        /// @notice Sneaker tier used to collect loot boxes.
        uint256[] sneakerTier;
        /// @notice the timestamp of when the loot box was collected
        uint256[] collectionTime;
        /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    struct Request {
        // loot box opener
        address lootBoxOwner;
        // token Ids user has requested to mint
        uint256[] tokenId;
        // sneaker tiers used to open loot boxes
        uint256[] sneakerTier;
        // collection times
        uint256[] collectionTime;
    }

    // token used for buying sneakers
    IERC20 public erc20Token;

    // tracks loot box vouchers that have expired
    mapping(bytes => bool) expiredLootBoxVouchers;

    function initialize(
        string memory _baseUri,
        IERC20 _erc20Token,
        address _coordinator,
        address link,
        uint64 _subscriptionId
    ) public initializer {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        __ERC721_init("MenzySneaker", "MNZS");
        __AccessControl_init();
        __VRFConsumerBaseV2_init(_coordinator);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        baseURI = _baseUri;
        erc20Token = _erc20Token;
        LINKTOKEN = LinkTokenInterface(link);
        COORDINATOR = VRFCoordinatorV2Interface(_coordinator);
        keyHash = 0x17cd473250a9a479dc7f234c64332ed4bc8af9e8ded7556aa6e66d83da49f470;
        // subscription ID
        s_subscriptionId = _subscriptionId;

        uint256[] memory _sneakerChances = new uint256[](5);

        // set chances for each sneaker tier
        _sneakerChances[0] = 1000; // 10% chance
        _sneakerChances[1] = 2500; // 25%
        _sneakerChances[2] = 4000; // 40%
        _sneakerChances[3] = 6000; // 60%
        _sneakerChances[4] = 7500; // 75%

        sneakerChances = _sneakerChances;

        gasLimit = 400000;
        gasPerLootBox = 250000;
    }

    // / @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    function redeemNFT(NFTVoucher calldata voucher)
        public
        whenNotPaused
        returns (uint256)
    {
        // make sure signature is valid and get the address of the signer
        address signer = _verifyNFTVoucher(voucher);

        // make sure that the signer is authorized to mint NFTs
        require(
            hasRole(MINTER_ROLE, signer),
            "Signature invalid or unauthorized"
        );

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(
            erc20Token.balanceOf(msg.sender) >= voucher.minPrice,
            "Insufficient funds to redeem"
        );

        // first assign the token to the signer, to establish provenance on-chain
        _mint(signer, voucher.tokenId);
        // transfer the token to the redeemer
        _transfer(signer, msg.sender, voucher.tokenId);

        // record payment to signer's withdrawal balance
        pendingWithdrawals[signer] += voucher.minPrice;

        // transfer minPrice amount to contract
        erc20Token.transferFrom(msg.sender, address(this), voucher.minPrice);

        emit TokenRedeemed(voucher.tokenId, msg.sender);

        return voucher.tokenId;
    }

    // / @param voucher A signed LootBoxVoucher that describes the NFTs to be redeemed.
    function redeemNFTsFromLootBox(LootBoxVoucher calldata voucher)
        public
        whenNotPaused
        returns (uint256)
    {
        // if the contents of the voucher are incorrect, it will revert
        if (!_verifyLootBoxVoucher(voucher)) {
            revert("incorrect voucher data");
        }

        // return vrf request id
        // a front-end listener will await request completion event containing this request id
        return requestRandomNumbers(voucher);
    }

    /**
     * @dev burn 2 nfts and mint a new one
     * @param _sneaker1 first sneaker to burn
     * @param _sneaker2 second sneaker to burn
     * @return the new token created through fusion
     */
    function fuseNFTs(uint256 _sneaker1, uint256 _sneaker2)
        public
        whenNotPaused
        returns (uint256)
    {
        // check if caller is owner of nfts
        require(
            ownerOf(_sneaker1) == msg.sender &&
                ownerOf(_sneaker2) == msg.sender,
            "caller is not owner"
        );

        fusionNFTs++;

        // there can be 2^254 fusion nfts
        require(fusionNFTs >> 254 == 0, "fusion NFTs have run out");

        uint256 nextFusionToken = (uint256(2) << 254) + fusionNFTs;

        // burn fused nfts
        _burn(_sneaker1);
        _burn(_sneaker2);

        // mint new sneaker
        _mint(msg.sender, nextFusionToken);

        // it is possible that fusion is done directly from contract, a listener will listen to this event
        emit SneakersFused(_sneaker1, _sneaker2, nextFusionToken);

        // front-end will receive new token and create a new sneaker with generative algo and new calculated tier
        return (nextFusionToken);
    }

    function mint(address _to, uint256 _tokenId)
        external
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        _mint(_to, _tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        whenNotPaused
    {
        super._burn(tokenId);
    }

    /**
    @dev sets the base URI for founder NFT
     */
    function setBaseURI(string memory _baseUri)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _baseUri;
    }

    /**
    @dev the base uri will be the uri for every founder NFT
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC721Upgradeable.tokenURI(tokenId);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI()
        internal
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return baseURI;
    }

    /// @notice Transfers all pending withdrawal balance to the caller. Reverts if the caller is not default admin.
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = pendingWithdrawals[msg.sender];
        // zero account before transfer to prevent re-entrancy attack
        pendingWithdrawals[msg.sender] = 0;

        // withdraw amount
        erc20Token.transfer(msg.sender, amount);
    }

    /// @notice Returns the amount available to the caller to withdraw.
    function availableToWithdraw() public view returns (uint256) {
        return pendingWithdrawals[msg.sender];
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hashNFTVoucher(NFTVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(uint256 tokenId,uint256 minPrice)"
                        ),
                        voucher.tokenId,
                        voucher.minPrice
                    )
                )
            );
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hashLootBoxVoucher(LootBoxVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "LootBoxVoucher(uint256[] tokenId,uint256[] sneakerTier,uint256[] collectionTime)"
                        ),
                        keccak256(abi.encodePacked(voucher.tokenId)),
                        keccak256(abi.encodePacked(voucher.sneakerTier)),
                        keccak256(abi.encodePacked(voucher.collectionTime))
                    )
                )
            );
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verifyNFTVoucher(NFTVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        // check that NFT is not coming from a loot box or fusion
        require(voucher.tokenId >> 254 == 0, "incorrect NFT token id");

        bytes32 digest = _hashNFTVoucher(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    /// @notice Verifies the signature for a given LootBoxVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An LootBoxVoucher describing unminted NFTs.
    function _verifyLootBoxVoucher(LootBoxVoucher calldata voucher)
        internal
        returns (bool verificationSuccess)
    {
        bytes32 digest = _hashLootBoxVoucher(voucher);
        address signer = ECDSAUpgradeable.recover(digest, voucher.signature);

        // make sure that the signer is authorized to mint NFTs

        if (!hasRole(MINTER_ROLE, signer)) {
            emit LootBoxVoucherExpired(voucher.tokenId, voucher.collectionTime);
            revert("Signature invalid or unauthorized");
        }

        /**
         * @dev if signer is correct, that means the data is signed correctly - make other checks below
         */

        if (
            voucher.tokenId.length < 1 || // cannot open more than 5 loot boxes at a time to avoid too much gas
            voucher.tokenId.length > 5 ||
            voucher.sneakerTier.length != voucher.tokenId.length ||
            voucher.sneakerTier.length != voucher.collectionTime.length
        ) {
            return false;
        }
        for (uint256 i = 0; i < voucher.sneakerTier.length; i++) {
            if (
                uint256(voucher.sneakerTier[i]) >
                uint256(SneakerTier.legendary) || // check: sneaker tier is correct
                (block.timestamp - voucher.collectionTime[i] > 30 days ||
                    block.timestamp < voucher.collectionTime[i]) || // check: collection time is less than block time and time since collection is less than month
                voucher.tokenId[i] >> 254 != 1 // token ID belongs to loot box pool
            ) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev chainlink RNG oracle
     * NOTE: Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
     * Assumes the subscription is funded sufficiently.
     */
    function requestRandomNumbers(LootBoxVoucher calldata voucher)
        internal
        returns (uint256)
    {
        uint256 s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            3, // request confirmations
            gasLimit + (gasPerLootBox) * (uint32(voucher.tokenId.length) - 1), // calculated using hardhat-gas-reporter
            1
        );

        Request memory request = Request(
            msg.sender,
            voucher.tokenId,
            voucher.sneakerTier,
            voucher.collectionTime
        );

        // save request
        requests[s_requestId] = request;

        emit LootBoxOpenRequested(voucher.tokenId.length, s_requestId);

        return s_requestId;
    }

    /**
     * @dev callback function that recieves the requested random numbers and mints loot box NFTs
     * @param randomWords random numbers
     * @param requestId request Id of random number request
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // we recieve the random numbers here and mint according to the random class and random token Ids
        Request memory request = requests[requestId];

        bytes memory voucherBytes = abi.encode(
            request.tokenId,
            request.collectionTime
        );

        // check if voucher has already been used
        require(
            !expiredLootBoxVouchers[voucherBytes],
            "voucher has been used up"
        );

        delete requests[requestId];

        uint256 randomNum;
        uint256[] memory tokenIds = new uint256[](request.tokenId.length);

        for (uint256 i = 0; i < request.tokenId.length; i++) {
            // get random percentage
            randomNum = getRandomPercentage(randomWords[0]);

            // randomize whether nft is receivable
            if (randomNum <= sneakerChances[uint256(request.sneakerTier[i])]) {
                // mint sneaker
                _mint(request.lootBoxOwner, request.tokenId[i]);
                tokenIds[i] = request.tokenId[i];
                lootBoxNFTs++;
            }
        }

        // expire the loot box
        expiredLootBoxVouchers[voucherBytes] = true;

        // loot boxes that contained an nft will have a token Id in its index and the others will simply contain zero
        // emit event containing array of unboxed sneaker tokens
        emit LootBoxTokensRedeemed(requestId, tokenIds);
    }

    function setGasLimit(uint32 _gasLimit, uint32 _gasPerLootBox)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        gasLimit = _gasLimit;
        gasPerLootBox = _gasPerLootBox;
    }

    function setSneakerChances(uint256[] memory _sneakerChances)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _sneakerChances.length > 0 && _sneakerChances.length <= 5,
            "incorrect chances passed"
        );

        sneakerChances = _sneakerChances;
    }

    function setKeyHash(bytes32 _keyHash)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        keyHash = _keyHash;
    }

    // HELPERS

    function getRandomPercentage(uint256 randomNum)
        internal
        returns (uint16 randomPercentage)
    {
        uint256 randomValue = uint256(
            keccak256(abi.encode(randomNum, randoms))
        );
        // to get around overflows
        unchecked {
            randoms++;
        }
        randomPercentage = uint16(randomValue % 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }
}