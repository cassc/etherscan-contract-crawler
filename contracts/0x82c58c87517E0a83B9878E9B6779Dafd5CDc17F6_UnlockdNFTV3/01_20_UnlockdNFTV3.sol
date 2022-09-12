// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


/// @dev tokenId structure
///      1   - 40  (40)    : 1o1 collection
///      41  - 70  (30)    : Team player collection
///      71  - 490 (450)   : Key Supporter collection
///      491 - 3500 (3010) : Generic NFT collection
///      3010 = 903(private) + rest (public)
// TODO: check total amount is increased correctly
//       renounce ownership to Gnosis multisig after 1o1 collection mint
//       mint remain nfts(Key Supporter) to treasury
//       move fund to treasury from UnlockdNFT contract
contract UnlockdNFTV3 is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    mapping(address => uint64) public teamPlayersCount;
    mapping(address => uint64) public keySupporterCount;
    mapping(address => uint64) public publicWhiteListCount;
    mapping(address => uint64) public genericPublicSaleCount;

    mapping(address => bool) public hasBeenTeamPlayer;
    mapping(address => bool) public hasBeenKeySupporter;
    mapping(address => bool) public hasBeenWhitelisted;

    string private baseURI;
    bool private _reentrancyGuard;

    uint64 public mintFee;
    uint64 private teamPlayerSaleIndex;
    uint64 public keySupporterSaleIndex;
    uint64 public publicWhiteListSaleIndex;
    uint64 private genericNFTPublicSaleIndex;
    uint64 private constant totalCollections = 3500;

    address public treasury;

    bool public rareMintStatus;
    bool public isTeamPlayerMint;
    bool public isKeySupporterMint;
    bool public isPublicWhitelistMint;
    bool public isGenericMint;

    // events
    event PremintRare(address[]);
    event WhitelistMint(address, uint64);
    event CommonMint(address, uint64);
    event SetMintingStatus(
        bool isTeamPlayerMint,
        bool isKeySupporterMint,
        bool isPublicWhitelistMint,
        bool isGenericMint
    );
    string public contractURI_;

    // rarity
    // depends on network
    function initialize(
        uint64 _mintFee,
        address[] calldata _rareOwners,
        address _treasury,
        address _multisigAddress
    ) public initializer {
        __ERC721_init("The Lockeys", "LOCKEY");
        __Ownable_init();
        __UUPSUpgradeable_init();
        oneOoneNFTMint(_rareOwners);
        mintFee = _mintFee;
        /// NOTE: id 0~32 are reserved for rare minters
        /// @dev public sale starts after beta
        treasury = _treasury;
        transferOwnership(_multisigAddress);

        teamPlayerSaleIndex = 51;
        keySupporterSaleIndex = 76;
        publicWhiteListSaleIndex = 526;
        genericNFTPublicSaleIndex = 2526;
    }

    function teamPlayersCountSetter(
        address[] calldata _teamPlayerAddresses,
        uint64[] calldata _count
    ) external onlyOwner {
        require(_teamPlayerAddresses.length == _count.length, "param mismatch");
        uint64 length = uint64(_count.length);
        for (uint64 i = 0; i < length; ++i) {
            // NOTE: increasing the count number, not set it as value
            teamPlayersCount[_teamPlayerAddresses[i]] += _count[i];
            hasBeenTeamPlayer[_teamPlayerAddresses[i]] = true;
        }
    }

    function keySupporterCountSetter(
        address[] calldata _keySupporterAddresses,
        uint64[] calldata _count
    ) external onlyOwner {
        require(
            _keySupporterAddresses.length == _count.length,
            "param mismatch"
        );
        uint64 length = uint64(_count.length);
        for (uint64 i = 0; i < length; ++i) {
            // NOTE: increasing the count number, not set it as value
            keySupporterCount[_keySupporterAddresses[i]] += _count[i];
            hasBeenKeySupporter[_keySupporterAddresses[i]] = true;
        }
    }

    function publicWhiteListCountSetter(
        address[] calldata _publicWhiteListAddresses
    ) external onlyOwner {
        uint64 length = uint64(_publicWhiteListAddresses.length);
        for (uint64 i = 0; i < length; ++i) {
            // NOTE: increasing the count number, not set it as value
            publicWhiteListCount[_publicWhiteListAddresses[i]] = 5;
            hasBeenWhitelisted[_publicWhiteListAddresses[i]] = true;
        }
    }

    function setMintingStatus(
        bool _isTeamPlayerMint,
        bool _isKeySupporterMint,
        bool _isPublicWhitelistMint,
        bool _isGenericMint
    ) external onlyOwner {
        isTeamPlayerMint = _isTeamPlayerMint;
        isKeySupporterMint = _isKeySupporterMint;
        isPublicWhitelistMint = _isPublicWhitelistMint;
        isGenericMint = _isGenericMint;

        emit SetMintingStatus(
            _isTeamPlayerMint,
            _isKeySupporterMint,
            _isPublicWhitelistMint,
            _isGenericMint
        );
    }

    function mintGetter(address user)
        external
        view
        returns (
            uint256 nftsLeftToMint,
            string memory phase,
            bool hasMintedPhase
        )
    {
        if(isKeySupporterMint) {
            phase = "keySupporter";
            if(!hasBeenKeySupporter[user]){ //user is not able to mint in keysupporter
                nftsLeftToMint = 0;
                hasMintedPhase = false;
            } else {
                if(keySupporterCount[user] == 0) {
                    nftsLeftToMint = 0; //user is able and has already minted all their nfts in keySupporter
                    hasMintedPhase = true;
                } else{
                    hasMintedPhase = false;
                    //Check total phase index to tackle edge cases
                    if((keySupporterSaleIndex + keySupporterCount[user]) < 526) {
                        nftsLeftToMint = keySupporterCount[user];
                    }else{
                        nftsLeftToMint = 526 - keySupporterSaleIndex - 1;
                    }
                }
            }
            return (nftsLeftToMint, phase, hasMintedPhase);
        }
        if(isPublicWhitelistMint) {
            phase = "whitelist";
            if(!hasBeenWhitelisted[user]){ //user is not able to mint in whitelist
                nftsLeftToMint = 0;
                hasMintedPhase = false;
            } else {
                if(publicWhiteListCount[user] == 0) {
                    nftsLeftToMint = 0; //user is able and has already minted all their nfts in whitelist
                    hasMintedPhase = true;
                } else{
                    hasMintedPhase = false;
                    //Check total phase index to tackle edge cases
                    if((publicWhiteListSaleIndex + publicWhiteListCount[user]) < 2526) {
                        nftsLeftToMint = publicWhiteListCount[user];
                    }else{
                        nftsLeftToMint = 2526 - publicWhiteListSaleIndex - 1;
                    }
                }
            }
            return (nftsLeftToMint, phase, hasMintedPhase);
        }

        if(isGenericMint) {
            phase = "publicMint";
            if(genericPublicSaleCount[user] == 50){
                nftsLeftToMint = 0; //user has already minted all their nfts in whitelist
                hasMintedPhase = true; 
            } else {
                hasMintedPhase = false; 
                //Check total phase index to tackle edge cases
                if((genericNFTPublicSaleIndex + genericPublicSaleCount[user]) < 3500) {
                    nftsLeftToMint = 50 - genericPublicSaleCount[user];
                }else{
                    nftsLeftToMint = 3500 - genericNFTPublicSaleIndex;
                }
            }
            return (nftsLeftToMint, phase, hasMintedPhase);
        }
    }

    function oneOoneNFTMint(address[] memory rareOwners) internal onlyOwner {
        /// @dev mint rare items
        require(rareOwners.length == 50, "wrong input length");
        require(rareMintStatus == false, "rare mint already done");

        for (uint64 i = 1; i <= 50; ++i) {
            _mint(rareOwners[i - 1], i);
        }
        rareMintStatus = true;
        emit PremintRare(rareOwners);
    }

    function teamNFTMint(address _to, uint64 _count)
        public
        disableContractMint
        nonReentrant
    {
        require(isTeamPlayerMint, "minting not started");
        require(teamPlayersCount[_msgSender()] >= _count, "already minted");
        require(teamPlayerSaleIndex < 76, "team players all minted");
        /// whitelsted user, should mint supporter nft
        teamPlayersCount[_msgSender()] -= _count;
        for (uint64 i = 0; i < _count; i++) {
            _mint(_to, teamPlayerSaleIndex);
            teamPlayerSaleIndex++;
        }
    }

    function keySupporterNFTMint(address _to, uint64 _count)
        public
        payable
        disableContractMint
        nonReentrant
    {
        require(isKeySupporterMint, "minting not started");
        require(keySupporterCount[_msgSender()] >= _count, "already minted");
        require(keySupporterSaleIndex < 491, "key supporters all minted");
        // check if mintFee is enough
        keySupporterCount[_msgSender()] -= _count;

        for (uint64 i = 0; i < _count; ++i) {
            _mint(_to, keySupporterSaleIndex);
            ++keySupporterSaleIndex;
        }

        /// whitelsted user, should mint supporter nft
        // _mint(_msgSender(), teamPlayerSaleIndex);
        // teamPlayerSaleIndex++;
    }

    function publicWhiteListNFTMint(address _to, uint64 _count)
        public
        payable
        disableContractMint
        nonReentrant
    {
        //require(isPublicWhitelistMint, "minting not started");
        require(publicWhiteListSaleIndex < 2526, "all tokens minted");
        require(isGenericMint, "minting not started");
            require(
                genericPublicSaleCount[_msgSender()] + _count <= 50,
                "reached maximum amount"
            );
        require(mintFee * _count <= msg.value, "!enough mintFee");
        for (uint64 i = 0; i < _count; ++i) {
            _mint(_to, publicWhiteListSaleIndex);
            ++publicWhiteListSaleIndex;
        }
        genericPublicSaleCount[_msgSender()] += _count;
        _reentrancyGuard = false;
    }

    function mintNFT(
        address _toTeamAddress,
        uint64 _teamCount,
        address _toKeySupporterAddress,
        uint64 _keySupporterCount,
        address _toPublicWhiteListAddress,
        uint64 _publicWhiteListCount,
        uint64 _count
    ) external payable disableContractMint {
        if (_teamCount > 0) {
            teamNFTMint(_toTeamAddress, _teamCount);
        }

        if (_keySupporterCount > 0) {
            keySupporterNFTMint(_toKeySupporterAddress, _keySupporterCount);
        }

        if (_publicWhiteListCount > 0) {
            publicWhiteListNFTMint(
                _toPublicWhiteListAddress,
                _publicWhiteListCount
            );
        }

        if (_count > 0) {
            publicWhiteListNFTMint(
                _toPublicWhiteListAddress,
                _count
            );
        }
    }

    function totalMintedCount() external view returns (uint64 totalMinted) {
        totalMinted =
            teamPlayerSaleIndex -
            1 +
            keySupporterSaleIndex -
            76 +
            publicWhiteListSaleIndex -
            526 +
            genericNFTPublicSaleIndex -
            2526;
    }

    function setIndexes(
        uint64 _teamPlayerSaleIndex,
        uint64 _keySupporterSaleIndex,
        uint64 _publicWhiteListSaleIndex,
        uint64 _genericNFTPublicSaleIndex
    ) external onlyOwner {
        teamPlayerSaleIndex = _teamPlayerSaleIndex;
        keySupporterSaleIndex = _keySupporterSaleIndex;
        publicWhiteListSaleIndex = _publicWhiteListSaleIndex;
        genericNFTPublicSaleIndex = _genericNFTPublicSaleIndex;
    }
    function transferToTreasury() external nonReentrant onlyOwner {
        (bool sent, ) = treasury.call{value: address(this).balance}("");
        require(sent, "failed to send eth to treasury");
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) external onlyOwner {
        contractURI_ = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return contractURI_;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (tokenId > totalCollections) {
            revert("tokenId is not valid");
        }
    }

    function totalSupply() public view virtual override returns (uint256 totalMinted) {
        totalMinted =
            teamPlayerSaleIndex -
            1 +
            keySupporterSaleIndex -
            76 +
            publicWhiteListSaleIndex -
            526 +
            genericNFTPublicSaleIndex -
            2526;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    modifier disableContractMint() {
        require(
            _msgSender() == tx.origin,
            "Minting from smart contracts is disallowed"
        );
        _;
    }
}