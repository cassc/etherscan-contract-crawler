// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";


contract PixelFoxxies is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using SafeCast for uint256;

    event WhiteListConfigChanged(address whitelistSigner, uint32 startTime, uint32 endTime);
    event IsBurnEnabledChanged(bool newIsBurnEnabled);
    event BaseURIChanged(string newBaseURI);
    event WhiteListMint(address minter, uint256 count);

    // Both structs fit in a single storage slot for gas optimization
    struct WhiteListConfig {
        address whitelistSigner;
        uint32 startTime;
        uint32 endTime;
    }

    uint256 public immutable maxSupply;
    uint256 public nextTokenId;
    bool public isBurnEnabled;


    WhiteListConfig public whiteListConfig;
    mapping(address => uint256) public whiteListBoughtCounts;

    string public baseURI;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant WHITELIST_TYPEHASH = keccak256("WhiteList(address buyer,uint256 maxCount)");

    constructor(uint256 _maxSupply) ERC721("Pixel Foxxies", "PFox") {

        maxSupply = _maxSupply;
        nextTokenId = 1; // We start from token 1

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("PixelFoxxies")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }
 
    function setUpWhiteList(
        address whitelistSigner,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        uint32 _startTime = startTime.toUint32();
        uint32 _endTime = endTime.toUint32();

        // Check params
        require(whitelistSigner != address(0), "PixelFoxxies: zero address");
        require(_startTime > 0 && _endTime > _startTime, "PixelFoxxies: invalid time range");

        whiteListConfig = WhiteListConfig({whitelistSigner: whitelistSigner, startTime: _startTime, endTime: _endTime});

        emit WhiteListConfigChanged(whitelistSigner, _startTime, _endTime);
    }


    function setIsBurnEnabled(bool _isBurnEnabled) external onlyOwner {
        isBurnEnabled = _isBurnEnabled;
        emit IsBurnEnabledChanged(_isBurnEnabled);
    }


    function setBaseURI(string calldata newbaseURI) external onlyOwner {
        baseURI = newbaseURI;
        emit BaseURIChanged(newbaseURI);
    }

    function mintWhiteListTokens(
        uint256 count,
        uint256 maxCount,
        bytes calldata signature
    ) external payable {
        // Gas optimization
        uint256 _nextTokenId = nextTokenId;

        // Make sure presale has been set up
        WhiteListConfig memory _whiteListConfig = whiteListConfig;
        require(_whiteListConfig.whitelistSigner != address(0), "PixelFoxxies: whiteList sale not configured");

        require(count > 0, "PixelFoxxies: invalid count");
        require(block.timestamp >= _whiteListConfig.startTime, "PixelFoxxies: whiteList sale not started");
        require(block.timestamp < _whiteListConfig.endTime, "PixelFoxxies: whiteList sale ended");

        require(_nextTokenId + count <= maxSupply, "PixelFoxxies: max supply exceeded");
        require(0 == msg.value, "PixelFoxxies: incorrect Ether value");

        // Verify EIP-712 signature
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(WHITELIST_TYPEHASH, msg.sender, maxCount)))
        );
        address recoveredAddress = digest.recover(signature);
        require(
            recoveredAddress != address(0) && recoveredAddress == _whiteListConfig.whitelistSigner,
            "PixelFoxxies: invalid signature"
        );

        require(whiteListBoughtCounts[msg.sender] + count <= maxCount, "PixelFoxxies: presale max count exceeded");
        whiteListBoughtCounts[msg.sender] += count;


        for (uint256 ind = 0; ind < count; ind++) {
            _safeMint(msg.sender, _nextTokenId + ind);
        }
        nextTokenId += count;

        emit WhiteListMint(msg.sender, count);
    }


    function burn(uint256 tokenId) external {
        require(isBurnEnabled, "PixelFoxxies: burning disabled");
        require(_isApprovedOrOwner(msg.sender, tokenId), "PixelFoxxies: burn caller is not owner nor approved");
        _burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}