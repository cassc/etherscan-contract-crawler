// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DefaultOperatorFilterer} from "../OperatorFilterRegistry/DefaultOperatorFilterer.sol";

contract Collection721 is
    Ownable,
    ERC721,
    ERC2981,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    struct SaleConfig {
        string saleIdentifier;
        bool enabled;
        uint256 startTime;
        uint256 endTime;
        uint256 mintCharge;
        bytes32 whitelistRoot;
        uint256 maxMintPerWallet;
        uint256 maxMintInSale;
        address tokenGatedAddress;
    }

    struct State {
        address feeDestination;
        uint256 maxMintInTotalPerWallet;
        bytes32 saleConfigRoot;
        address msgSigner;
        string baseURI;
        uint256 revealTime;
        uint96 royaltyBasis;
        address platformOwner;
        uint256 maxMintCap;
        address priceFeedAddress;
    }

    State public state;

    uint256 public tokenId = 1;
    uint256 public mintCount = 0;
    using ECDSA for bytes32;
    bytes32 public constant EMPTY_ROOT =
        0x0000000000000000000000000000000000000000000000000000000000000000;

    mapping(bytes => bool) public isSignatureRedeemed;
    mapping(string => uint256) public mintCountByIdentifier;
    mapping(string => mapping(address => uint256))
        public mintCountByIdentifierWallet;
    mapping(address => uint256) public mintCountByWallet;

    event Mint(address msgSender, uint256 fromTokenId, uint256 toTokenId);

    struct ConstructorArgs {
        string _name;
        string _symbol;
        address _feeDestination;
        uint256 _maxMintInTotalPerWallet;
        bytes32 _saleConfigRoot;
        address _msgSigner;
        string _baseURI;
        uint256 _revealTime;
        uint96 _royaltyBasis;
        address _platformOwner;
        uint256 _maxMintCap;
        address _priceFeedAddress;
    }

    struct MintArgs {
        bytes32[] saleConfigProof;
        bytes32[] whitelistProof;
        uint256 numberOfMint;
        string message;
        bytes signature;
        SaleConfig config;
        uint256 whitelistMintLimit;
    }

    constructor(ConstructorArgs memory args)
        payable
        ERC721(args._name, args._symbol)
    {
        if (args._priceFeedAddress != address(0)) {
            (, int256 usdPerEth, , , ) = AggregatorV3Interface(
                args._priceFeedAddress
            ).latestRoundData();
            require(
                int256(msg.value) >=
                    (10**18 * 15 * int256(args._maxMintCap)) /
                        (((usdPerEth * 100) / 10**8)),
                "Not enough charge provided"
            );
        } else {
            require(
                msg.value >= 15 * 10**13 * args._maxMintCap,
                "Not enough charge provided"
            );
        }
        state.feeDestination = args._feeDestination;
        state.saleConfigRoot = args._saleConfigRoot;
        state.msgSigner = args._msgSigner;
        state.baseURI = args._baseURI;
        state.maxMintInTotalPerWallet = args._maxMintInTotalPerWallet;
        state.revealTime = args._revealTime;
        _setDefaultRoyalty(address(this), args._royaltyBasis);
        state.royaltyBasis = args._royaltyBasis;
        state.platformOwner = args._platformOwner;
        state.maxMintCap = args._maxMintCap;
        state.priceFeedAddress = args._priceFeedAddress;
        payable(address(args._platformOwner)).transfer(msg.value);
    }

    // Operator Filter Registry Overrides
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override onlyAllowedOperator(_from) {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId, data);
    }

    function updateRoyaltyBasis(uint96 _val) external onlyOwner {
        _setDefaultRoyalty(address(this), _val);
        state.royaltyBasis = _val;
    }

    modifier onlyPlatformOwner() {
        require(msg.sender == state.platformOwner, "Only Platform Owner");
        _;
    }

    function updatePlatformOwner(address _address) external onlyPlatformOwner {
        state.platformOwner = _address;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function updateRevealTime(uint256 _revealTime) external onlyOwner {
        state.revealTime = _revealTime;
    }

    function updateMaxMintInTotalPerWallet(uint256 _val) external onlyOwner {
        state.maxMintInTotalPerWallet = _val;
    }

    function updateBaseURI(string memory _baseURI) external onlyOwner {
        state.baseURI = _baseURI;
    }

    function updateSaleConfigRoot(bytes32 _saleConfigRoot) external onlyOwner {
        state.saleConfigRoot = _saleConfigRoot;
    }

    function contractURI() external view returns (string memory) {
        return
            string(
                string.concat(
                    (state.baseURI),
                    "contract-uri?address=",
                    (Strings.toHexString(uint256(uint160(address(this))), 20)),
                    "&network=",
                    (Strings.toString(block.chainid)),
                    "&royalty=",
                    (Strings.toString(state.royaltyBasis))
                )
            );
    }

    function updateFeeToAddress(address _feeDestination) external onlyOwner {
        state.feeDestination = _feeDestination;
    }

    // function getTokenGatedLimit(uint256 _base) internal pure returns (uint256) {
    //     if (_base > 39) return _base + 12;
    //     return _base + [0, 1, 3, 4, 6, 7, 9, 10][_base / 5];
    // }

    function getSaleConfigLeaf(SaleConfig memory config)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    keccak256(
                        abi.encodePacked(
                            config.saleIdentifier,
                            config.enabled,
                            config.startTime,
                            config.endTime,
                            config.mintCharge,
                            config.whitelistRoot,
                            config.maxMintPerWallet,
                            config.maxMintInSale,
                            config.tokenGatedAddress
                        )
                    )
                )
            );
    }

    modifier onlyValidMint(
        bytes32[] memory saleConfigProof,
        bytes32[] memory whitelistProof,
        uint256 numberOfMint,
        SaleConfig memory config,
        uint256 whitelistMintLimit
    ) {
        require(
            mintCount + numberOfMint <= state.maxMintCap,
            "Mint Count exceeds Max Cap"
        );
        require(state.saleConfigRoot != EMPTY_ROOT, "No sale configured");
        require(
            MerkleProof.verify(
                saleConfigProof,
                state.saleConfigRoot,
                getSaleConfigLeaf(config)
            ),
            "Invalid Sale Config"
        );
        require(config.enabled, "Sale is not enabled");
        uint256 time = block.timestamp;
        require(
            config.startTime != 0 && time >= config.startTime,
            "Sale has not started yet"
        );
        require(
            time <= config.endTime || config.endTime == 0,
            "Sale has ended"
        );
        require(
            mintCountByIdentifier[config.saleIdentifier] + numberOfMint <=
                config.maxMintInSale,
            "Max Mint in Sale Limit Exceeds"
        );
        // if (config.tokenGatedAddress != address(0) && config.mintCharge == 0) {
        //     require(
        //         mintCountByIdentifierWallet[config.saleIdentifier][msg.sender] +
        //             numberOfMint <=
        //             getTokenGatedLimit(
        //                 IERC721(config.tokenGatedAddress).balanceOf(msg.sender)
        //             ),
        //         "Formula : Max Mint Per Wallet Sale Limit Exceeds"
        //     );
        // } else
        if (config.tokenGatedAddress != address(0) && config.mintCharge > 0) {
            require(
                mintCountByIdentifierWallet[config.saleIdentifier][msg.sender] +
                    numberOfMint <=
                    1,
                "Token Gated Paid Mint : Max Mint Per Wallet Sale Limit (1) Exceeds"
            );
        }
        if (config.tokenGatedAddress == address(0)) {
            require(
                mintCountByIdentifierWallet[config.saleIdentifier][msg.sender] +
                    numberOfMint <=
                    config.maxMintPerWallet,
                "Max Mint Per Wallet Sale Limit Exceeds"
            );
        }
        if (state.maxMintInTotalPerWallet != 0) {
            require(
                mintCountByWallet[msg.sender] + numberOfMint <=
                    state.maxMintInTotalPerWallet,
                "Max Mint per Wallet in total Limit Exceeds"
            );
        }
        if (
            config.whitelistRoot != EMPTY_ROOT &&
            config.tokenGatedAddress == address(0)
        ) {
            require(
                MerkleProof.verify(
                    whitelistProof,
                    config.whitelistRoot,
                    keccak256(
                        abi.encodePacked(
                            keccak256(
                                abi.encodePacked(msg.sender, whitelistMintLimit)
                            )
                        )
                    )
                ),
                "You are not whitelisted"
            );
            require(
                mintCountByIdentifierWallet[config.saleIdentifier][msg.sender] +
                    numberOfMint <=
                    whitelistMintLimit,
                "Max Mint Per Wallet Sale Whitelist-Limit Exceeds"
            );
        }
        require(
            msg.value >= config.mintCharge * numberOfMint,
            "Not enough mint charge provided"
        );
        _;
    }

    modifier onlyPlatformSigned(
        uint256 numberOfMint,
        bytes memory signature,
        string memory message
    ) {
        require(!isSignatureRedeemed[signature], "Signature already redeemed");
        require(
            keccak256(abi.encodePacked(msg.sender, message, numberOfMint))
                .toEthSignedMessageHash()
                .recover(signature) == state.msgSigner,
            "Invalid Mint Signature"
        );
        _;
    }

    function mint(MintArgs memory args)
        external
        payable
        nonReentrant
        onlyValidMint(
            args.saleConfigProof,
            args.whitelistProof,
            args.numberOfMint,
            args.config,
            args.whitelistMintLimit
        )
        onlyPlatformSigned(args.numberOfMint, args.signature, args.message)
    {
        require(args.numberOfMint > 0, "Number of mints is 0");
        mintCount += args.numberOfMint;
        mintCountByIdentifierWallet[args.config.saleIdentifier][
            msg.sender
        ] += args.numberOfMint;
        mintCountByIdentifier[args.config.saleIdentifier] += args.numberOfMint;
        mintCountByWallet[msg.sender] += 1;
        isSignatureRedeemed[args.signature] = true;
        uint256 startId = tokenId;
        tokenId = tokenId + args.numberOfMint;
        uint256 platformCharge = (msg.value * 300) / 10000;
        if (state.platformOwner != address(0)) {
            payable(address(state.platformOwner)).transfer(platformCharge);
        }
        payable(state.feeDestination).transfer(
            state.platformOwner != address(0)
                ? msg.value - platformCharge
                : msg.value
        );
        for (uint256 i = 0; i < args.numberOfMint; ++i) {
            _mint(msg.sender, startId + i);
        }
        emit Mint(msg.sender, startId, tokenId - 1);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                string.concat(
                    (state.baseURI),
                    state.revealTime != 0 && block.timestamp <= state.revealTime
                        ? "hidden-"
                        : "",
                    "token-uri?address=",
                    (Strings.toHexString(uint256(uint160(address(this))), 20)),
                    "&network=",
                    (Strings.toString(block.chainid)),
                    "&tokenId=",
                    (Strings.toString(_tokenId))
                )
            );
    }

    receive() external payable {
        uint256 platformRoyalty = (msg.value * 2) / 100;
        if (state.platformOwner != address(0)) {
            payable(address(state.platformOwner)).transfer(platformRoyalty);
        }
        payable(address(state.feeDestination)).transfer(
            state.platformOwner != address(0)
                ? msg.value - platformRoyalty
                : msg.value
        );
    }
}