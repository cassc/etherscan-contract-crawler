// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DigitalPunk is ERC721AQueryable, BaseTokenURI, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant FEE_DENOMINATOR = 1000;
    uint256 public constant MAX_SUPPLY = 6;
    bytes32 public merkleRoot;

    uint256 public totalCollectedFunds;
    uint256 public mintPrice;
    uint256 public distribution1Percentage = 500;
    uint256 public distribution2Percentage = 500;
    address public distribution1address =
        0x8ba4c8705905522b0A89D5eA597E33ec1F828035;
    address public distribution2address =
        0x8464bFa0d5aB3D91CFB401E77EfDE5158dCeE48f;

    bool public whitelisting = true;

    mapping(address => uint256) public withdrewAmount;

    modifier merkleWhitelisted(bytes32[] calldata merkleProof) {
        if (whitelisting) {
            require(
                MerkleProof.verify(
                    merkleProof,
                    merkleRoot,
                    toBytes32(msg.sender)
                ) == true,
                "invalid merkle proof for whitelist"
            );
        }
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        uint256 _mintPrice,
        bytes32 _merkleRoot
    ) ERC721A(_name, _symbol) BaseTokenURI(_initBaseURI) {
        require(_mintPrice > 0, "Mint price must be greater than 0");
        mintPrice = _mintPrice;
        merkleRoot = _merkleRoot;
    }

    function withdraw() external nonReentrant {
        _withdraw(distribution1address);
        _withdraw(distribution2address);
    }

    function _withdraw(address _to) private {
        uint256 availableAmount = getAvailableAmount(_to);
        require(availableAmount > 0, "No funds to claim");

        withdrewAmount[_to] += availableAmount;

        (bool success, ) = _to.call{value: availableAmount}("");
        require(success, "Unable to distribute address funds");
    }

    function getAvailableAmount(
        address _address
    ) public view returns (uint256) {
        uint256 percentage = _address == distribution1address
            ? distribution1Percentage
            : distribution2Percentage;
        uint256 ownedAmount = (totalCollectedFunds * percentage) /
            FEE_DENOMINATOR;
        uint256 availableAmount = ownedAmount - withdrewAmount[_address];
        return availableAmount;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721A)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    function mint(
        uint256 _mintAmount,
        bytes32[] calldata merkleProof
    ) external payable merkleWhitelisted(merkleProof) {
        require(_mintAmount > 0, "Amount to mint can not be 0");
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "Cannot mint more than max supply"
        );
        require(
            msg.value >= mintPrice * _mintAmount,
            "Amount sent less than the cost of minting NFT(s)"
        );
        _safeMint(_msgSender(), _mintAmount);

        uint256 costNative = _mintAmount * mintPrice;
        uint256 excessNative = msg.value - costNative;

        totalCollectedFunds += costNative;

        if (msg.value > costNative) {
            (bool success, ) = address(_msgSender()).call{value: excessNative}(
                ""
            );
            require(success, "Unable to refund excess ether");
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: tokenURI queried for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function configure(
        uint256 _mintPrice,
        address _distribution1address,
        address _distribution2address
    ) external onlyOwner {
        mintPrice = _mintPrice;
        setDistribution1address(_distribution1address);
        setDistribution2address(_distribution2address);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setDistribution1address(
        address _distribution1address
    ) public onlyOwner {
        withdrewAmount[_distribution1address] = withdrewAmount[
            distribution1address
        ];
        delete withdrewAmount[distribution1address];

        distribution1address = _distribution1address;
    }

    function setDistribution2address(
        address _distribution2address
    ) public onlyOwner {
        withdrewAmount[_distribution2address] = withdrewAmount[
            distribution2address
        ];
        delete withdrewAmount[distribution2address];

        distribution2address = _distribution2address;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        require(whitelisting, "whitelisting off");
        merkleRoot = _merkleRoot;
    }

    function renounceWhitelist() public onlyOwner {
        require(whitelisting, "whitelist already off");
        whitelisting = false;
    }
}