// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/structs/BitMaps.sol';
import 'erc721a/contracts/ERC721A.sol';

import './CryptoPunksInterface.sol';
import './ERC721ARefundable.sol';

/**
 *                      :---=====---:.
 *                .-===:..        .:-==-:
 *              ===:.   ...........    .-==.
 *           .=+:.  ..:-===-----===-::.   .=+:
 *          =+:. ..:==-:           .-=+-:.  .=+
 *         *=:..::+=.                  =*-:. .:*.  .::::-------=.
 *        *-:..:=+                       =+:. .:*=:....:::::::.:=*-
 *       *=:..:+-                         :*-: .:*:::::::::::::....
 *      -+::::==                           :*-. :-*:::...........    :
 *      #-::::*                           :-*=: .:*                ..*
 *      *-...:+                          -: -*-..:+.               =-*
 *         .::+                      :--==--+*-.::+:..............+-:*
 *        .:::*                   .==-       -==::*.          ...==-+:
 *        -:::+:                 =+::::......:.:+-*..::::::::::-*=-+:
 *       -.-:::*.               =+:::::::::::::::#=:::::::::::=+-=+
 *       :*--:::+-              #-:::::::::::::::=+:::::::::-+=-+-
 *        :*=-:::-+:            #--::::::::::::::=+:::::::-+=-+=
 *          *=--:::-+=.         ++---++=++::::::-#::::::-++-=+.
 *           -*=--::::-==------++*++=::::-#:::-=#=:::::+=-=+=-:. ....
 *             -++=--::::::::::::::::::--+*-=+**-::::=+--+-    .:...:----:
 *                -=++=-----::::-----=+***+++=--::::+-:=+                .-=
 *                   .--=++++++++++++=-------::::::+-:+-                    =-
 *                      -: .::::::::..:......::...*=-*:                      :=
 *                    .= ..              ....    +=-*:                        =:
 *                   .-                         +--#-                          *
 *                   =                        .*-=+.-+:                        *
 *                  -:            .........::-+-=+    *.                      .+
 *                  ::..::::::::::::::::::::++-+=     :+                      *
 *                   + .::::::::::::::::::=+-=+:       -+.                   +.
 *                    #-..::::::::::::-===::+-          :+-                -=
 *                     =*============+=-=+=:              :==:          :-=.
 *                       -=+==-----=++=-:                    .----------
 */
contract RichBaby is ERC721ARefundable, EIP712, Ownable {
    using ECDSA for bytes32;
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    uint256 public immutable collectionSize;
    uint256 public constant DEV_MINT_MAX = 250;
    uint256 public constant MINT_MAX_PER_PHASE = 2;
    uint256 public devMinted;

    string public baseURI;
    address private signerAddress;

    bytes32 public PROVENANCE;

    CryptoPunksInterface private immutable punksContract;
    IERC721 private immutable baycContract;

    BitMaps.BitMap private bred;

    enum SalePhase {
        Paused,
        Breed,
        AllowList,
        Public
    }

    struct SaleConfig {
        uint64 startTimestamp;
        uint64 price;
        SalePhase phase;
    }

    mapping(SalePhase => mapping(address => uint256)) public mintedCount;

    SaleConfig public saleConfig;

    struct RefundableMintInfo {
        address mintAddress;
        uint64 mintTime;
        uint16 mintQuantity;
    }
    mapping(uint256 => RefundableMintInfo) private refundableMintInfos;

    struct Parents {
        uint16 punkTokenId;
        uint16 baycTokenId;
        bool isProposerPunk;
        bool proposerClaimed;
        bool hasParents;
    }
    mapping(uint256 => Parents) public babyParents;

    event Breed(
        uint16 indexed _proposerTokenId,
        bool indexed _isProposerPunk,
        uint16 indexed _acceptorTokenId,
        address _acceptor,
        uint16 _babyTokenId
    );

    event Claim(
        uint16 indexed _babyTokenId,
        uint16 indexed _siblingTokenId,
        address indexed _claimer
    );

    constructor(
        address punkAddress,
        address baycAddress,
        address _signerAddress,
        uint16 _collectionSize,
        uint64 _refundPeriod
    )
        ERC721ARefundable(_refundPeriod)
        ERC721A('Rich Baby', 'BABY')
        EIP712('Rich Baby', '1')
    {
        punksContract = CryptoPunksInterface(punkAddress);
        baycContract = IERC721(baycAddress);
        signerAddress = _signerAddress;
        collectionSize = _collectionSize;
    }

    function setSignerAddress(address newSignerAddress) external onlyOwner {
        signerAddress = newSignerAddress;
    }

    modifier isAtSalePhase(SalePhase phase) {
        unchecked {
            require(
                saleConfig.phase == phase &&
                    block.timestamp >= saleConfig.startTimestamp,
                'Sale phase mismatch.'
            );
        }
        _;
    }

    function checkAndUpdateMintedCount(SalePhase phase, uint256 quantity)
        private
    {
        unchecked {
            require(
                mintedCount[phase][msg.sender] + quantity <= MINT_MAX_PER_PHASE,
                'Too many babies to adopt.'
            );

            mintedCount[phase][msg.sender] += quantity;
        }
    }

    modifier checkPrice(SalePhase phase, uint256 quantity) {
        unchecked {
            require(
                msg.value == quantity * saleConfig.price,
                'Incorrect price.'
            );
        }
        _;
    }

    struct MatingRequest {
        address proposerAddress;
        uint16 proposerTokenId;
        bool isProposerPunk; // proposer is punk or bayc owner
        uint32 expireAt;
    }

    bytes32 private constant MATING_REQUEST_TYPE_HASH =
        keccak256(
            'MatingRequest(address proposerAddress,uint16 proposerTokenId,bool isProposerPunk,uint32 expireAt)'
        );

    function hashRequest(MatingRequest calldata matingRequest)
        private
        view
        returns (bytes32)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    MATING_REQUEST_TYPE_HASH,
                    matingRequest.proposerAddress,
                    matingRequest.proposerTokenId,
                    matingRequest.isProposerPunk,
                    matingRequest.expireAt
                )
            )
        );
        return digest;
    }

    function validateMatingRequest(
        MatingRequest calldata matingRequest,
        bytes calldata sig
    ) internal view {
        require(
            matingRequest.expireAt >= block.timestamp,
            'Mating request expired.'
        );
        require(
            ECDSA.recover(hashRequest(matingRequest), sig) ==
                matingRequest.proposerAddress,
            'Invalid sigature.'
        );
    }

    function verifyPunkOwnership(uint16 punkId, address holder) internal view {
        require(
            punksContract.punkIndexToAddress(punkId) == holder,
            'Address does not own this token.'
        );
    }

    function verifyBaycOwnership(uint16 baycId, address holder) internal view {
        require(
            baycContract.ownerOf(baycId) == holder,
            'Address does not own this token.'
        );
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract.');
        _;
    }

    function punkId2Index(uint16 punkId) internal pure returns (uint16) {
        unchecked {
            return punkId * 2;
        }
    }

    function baycId2Index(uint16 baycId) internal pure returns (uint16) {
        unchecked {
            return baycId * 2 + 1;
        }
    }

    function punkBred(uint16 punkId) public view returns (bool) {
        return bred.get(punkId2Index(punkId));
    }

    function baycBred(uint16 baycId) public view returns (bool) {
        return bred.get(baycId2Index(baycId));
    }

    /* acceptor mint one baby, left another baby for proposer to claim */
    function breed(
        MatingRequest calldata matingRequest,
        uint16 acceptorTokenId,
        bytes calldata sig
    ) external callerIsUser isAtSalePhase(SalePhase.Breed) {
        validateMatingRequest(matingRequest, sig);

        uint16 punkId;
        uint16 baycId;
        address punkOwnerAddress;
        address baycOwnerAddress;

        if (matingRequest.isProposerPunk) {
            punkId = matingRequest.proposerTokenId;
            punkOwnerAddress = matingRequest.proposerAddress;
            baycId = acceptorTokenId;
            baycOwnerAddress = msg.sender;
        } else {
            punkId = acceptorTokenId;
            punkOwnerAddress = msg.sender;
            baycId = matingRequest.proposerTokenId;
            baycOwnerAddress = matingRequest.proposerAddress;
        }

        require(!punkBred(punkId), 'Punk already bred a baby.');
        require(!baycBred(baycId), 'Bayc already bred a baby.');

        bred.set(punkId2Index(punkId));
        bred.set(baycId2Index(baycId));

        // check ownership
        verifyPunkOwnership(punkId, punkOwnerAddress);
        verifyBaycOwnership(baycId, baycOwnerAddress);

        uint16 babyTokenId = uint16(_currentIndex);

        babyParents[babyTokenId] = Parents(
            punkId,
            baycId,
            matingRequest.isProposerPunk,
            false,
            true
        );

        emit Breed(
            matingRequest.proposerTokenId,
            matingRequest.isProposerPunk,
            acceptorTokenId,
            msg.sender,
            babyTokenId
        );

        // mint baby token for acceptor, proposer should claim the twin baby later.
        _mint(msg.sender, 1, '', false);
    }

    /* For proposer to claim the baby. */
    function claimBaby(uint16 siblingId)
        external
        callerIsUser
        isAtSalePhase(SalePhase.Breed)
    {
        Parents storage parentsInfo = babyParents[siblingId];
        require(parentsInfo.hasParents, 'No baby to be claimed.');
        if (parentsInfo.isProposerPunk) {
            verifyPunkOwnership(parentsInfo.punkTokenId, msg.sender);
        } else {
            verifyBaycOwnership(parentsInfo.baycTokenId, msg.sender);
        }
        require(!parentsInfo.proposerClaimed, 'Baby already claimed.');

        parentsInfo.proposerClaimed = true;

        uint16 babyTokenId = uint16(_currentIndex);
        babyParents[babyTokenId] = parentsInfo;

        emit Claim(babyTokenId, siblingId, msg.sender);
        _mint(msg.sender, 1, '', false);
    }

    function allowListAdopt(
        uint256 quantity,
        uint256 salt,
        bytes calldata signature
    )
        external
        payable
        callerIsUser
        isAtSalePhase(SalePhase.AllowList)
        checkPrice(SalePhase.AllowList, quantity)
    {
        checkAndUpdateMintedCount(SalePhase.AllowList, quantity);
        require(
            keccak256(abi.encodePacked('allowlist', msg.sender, salt))
                .toEthSignedMessageHash()
                .recover(signature) == signerAddress,
            'Invalid signature.'
        );
        unchecked {
            require(
                _currentIndex + quantity <= collectionSize,
                'Max supply reached.'
            );
        }

        _mint(msg.sender, quantity, '', false);
    }

    function publicAdopt(
        uint256 quantity,
        uint256 salt,
        bytes calldata signature
    )
        external
        payable
        callerIsUser
        isAtSalePhase(SalePhase.Public)
        checkPrice(SalePhase.Public, quantity)
    {
        checkAndUpdateMintedCount(SalePhase.Public, quantity);
        require(
            keccak256(abi.encodePacked('public', msg.sender, salt))
                .toEthSignedMessageHash()
                .recover(signature) == signerAddress,
            'Invalid signature.'
        );
        unchecked {
            require(
                _currentIndex + quantity <= collectionSize,
                'Max supply reached.'
            );
        }

        _mint(msg.sender, quantity, '', false);
    }

    function startBreedSale(uint64 startTime) external onlyOwner {
        saleConfig = SaleConfig(startTime, 0, SalePhase.Breed);
    }

    function startAllowlistSale(uint64 price, uint64 startTime)
        external
        onlyOwner
    {
        saleConfig = SaleConfig(startTime, price, SalePhase.AllowList);
    }

    function startPublicSale(uint64 price, uint64 startTime)
        external
        onlyOwner
    {
        saleConfig = SaleConfig(startTime, price, SalePhase.Public);
    }

    function setSaleConfig(SaleConfig calldata _saleConfig) external onlyOwner {
        saleConfig = _saleConfig;
    }

    function devMint(address to, uint256 quantity) external onlyOwner {
        require(
            devMinted + quantity <= DEV_MINT_MAX,
            'Too many babies to mint.'
        );
        unchecked {
            devMinted += quantity;
        }
        _mint(to, quantity, '', false);
    }

    function setProvenance(bytes32 provenance) external onlyOwner {
        PROVENANCE = provenance;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json'))
                : '';
    }

    function withdraw(address beneficiary)
        external
        onlyOwner
        noWithdrawBeforePossibleRefund
    {
        payable(beneficiary).transfer(address(this).balance);
    }
}