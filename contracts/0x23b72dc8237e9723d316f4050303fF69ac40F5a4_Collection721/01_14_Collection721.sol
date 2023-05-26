// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Collection721 is Ownable, ERC721 {
    struct SaleConfig {
        string saleIdentifier;
        bool enabled;
        uint256 startTime;
        uint256 endTime;
        uint256 mintCharge;
        bytes32 whitelistRoot;
        uint256 maxMintPerWallet;
        uint256 maxMintInSale;
    }

    uint256 public tokenId = 1;
    using ECDSA for bytes32;
    bytes32 public emptyRoot =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    address public feeDestination;
    bytes32 public saleConfigsRoot;
    mapping(bytes => bool) public isSignatureRedeemed;
    mapping(string => uint256) public mintCountByIdentifier;
    mapping(string => mapping(address => uint256)) public balanceByIdentifier;
    uint256 public maxMintInTotalPerWallet;
    address public msgSigner;
    string public baseURI;
    uint256 public revealTime;

    event Mint(address msgSender, uint256 fromTokenId, uint256 toTokenId);

    constructor(
        string memory _name,
        string memory _symbol,
        address _feeDestination,
        uint256 _maxMintInTotalPerWallet,
        bytes32 _saleConfigRoot,
        address _msgSigner,
        string memory _baseURI,
        uint256 _revealTime
    ) ERC721(_name, _symbol) {
        feeDestination = _feeDestination;
        saleConfigsRoot = _saleConfigRoot;
        msgSigner = _msgSigner;
        baseURI = _baseURI;
        maxMintInTotalPerWallet = _maxMintInTotalPerWallet;
        revealTime = _revealTime;
    }

    function updateRevealTime(uint256 _revealTime) external onlyOwner {
        revealTime = _revealTime;
    }

    function updateMaxMintInTotalPerWallet(uint256 _val) external onlyOwner {
        maxMintInTotalPerWallet = _val;
    }

    function updateBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function updateSaleConfigRoot(bytes32 _saleConfigRoot) external onlyOwner {
        saleConfigsRoot = _saleConfigRoot;
    }

    function contractURI() external view returns (string memory) {
        return
            string(
                string.concat(
                    (bytes(baseURI)),
                    "contract-uri?address=",
                    (
                        bytes(
                            Strings.toHexString(
                                uint256(uint160(address(this))),
                                20
                            )
                        )
                    ),
                    "&network=",
                    (bytes(Strings.toString(block.chainid)))
                )
            );
    }

    function updateFeeToAddress(address _feeDestination) external onlyOwner {
        feeDestination = _feeDestination;
    }

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
                            config.maxMintInSale
                        )
                    )
                )
            );
    }

    modifier onlyValidMint(
        bytes32[] memory saleConfigProof,
        bytes32[] memory whitelistProof,
        uint256 numberOfMint,
        SaleConfig memory config
    ) {
        require(saleConfigsRoot != emptyRoot, "No sale configured");
        require(
            MerkleProof.verify(
                saleConfigProof,
                saleConfigsRoot,
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
            msg.value >= config.mintCharge * numberOfMint,
            "Not enough mint charge provided"
        );
        require(
            mintCountByIdentifier[config.saleIdentifier] + numberOfMint <=
                config.maxMintInSale,
            "Max Sale Limit Exceeds"
        );
        require(
            balanceByIdentifier[config.saleIdentifier][msg.sender] +
                numberOfMint <=
                config.maxMintPerWallet,
            "MaxMintPerWalletSaleLimitExceeds"
        );
        if (maxMintInTotalPerWallet != 0) {
            require(
                balanceOf(msg.sender) + numberOfMint <= maxMintInTotalPerWallet,
                "MaxTotalMintWalletLimitExceeds"
            );
        }
        if (config.whitelistRoot != emptyRoot) {
            require(
                MerkleProof.verify(
                    whitelistProof,
                    config.whitelistRoot,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "User not whitelisted"
            );
        }
        _;
    }

    modifier onlyPlatformSigned(string memory message, bytes memory signature) {
        require(!isSignatureRedeemed[signature], "Signature already redeemed");
        require(
            keccak256(abi.encodePacked(message))
                .toEthSignedMessageHash()
                .recover(signature) == msgSigner,
            "Invalid Signature"
        );
        _;
    }

    function mint(
        bytes32[] memory saleConfigProof,
        bytes32[] memory whitelistProof,
        uint256 numberOfMint,
        string memory message,
        bytes memory signature,
        SaleConfig memory config
    )
        external
        payable
        onlyValidMint(saleConfigProof, whitelistProof, numberOfMint, config)
        onlyPlatformSigned(message, signature)
    {
        require(numberOfMint > 0, "Number of mints is 0");
        for (uint256 i = 0; i < numberOfMint; ++i) {
            _mint(msg.sender, tokenId + i);
        }
        tokenId = tokenId + numberOfMint;
        balanceByIdentifier[config.saleIdentifier][msg.sender] += numberOfMint;
        mintCountByIdentifier[config.saleIdentifier] += numberOfMint;
        isSignatureRedeemed[signature] = true;
        payable(feeDestination).transfer(msg.value);
        emit Mint(msg.sender, tokenId - numberOfMint, tokenId - 1);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (revealTime != 0 && block.timestamp <= revealTime) {
            return
                string(
                    string.concat(
                        (bytes(baseURI)),
                        "hidden-token-uri?address=",
                        (
                            bytes(
                                Strings.toHexString(
                                    uint256(uint160(address(this))),
                                    20
                                )
                            )
                        ),
                        "&network=",
                        (bytes(Strings.toString(block.chainid)))
                    )
                );
        }
        return
            string(
                string.concat(
                    (bytes(baseURI)),
                    "token-uri?address=",
                    (
                        bytes(
                            Strings.toHexString(
                                uint256(uint160(address(this))),
                                20
                            )
                        )
                    ),
                    "&network=",
                    (bytes(Strings.toString(block.chainid))),
                    "&tokenId=",
                    (bytes(Strings.toString(_tokenId)))
                )
            );
    }
}