// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@shoyunft/contracts/contracts/interfaces/INFT721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFTAirdropsAndSales is Ownable {
    using SafeERC20 for IERC20;

    address public immutable nftContract;
    address public immutable levx;
    address public immutable wallet;
    mapping(bytes32 => Airdrop) public airdrops;
    mapping(address => bool) public isMinter;
    mapping(bytes32 => mapping(bytes32 => bool)) internal _minted;

    struct Airdrop {
        address signer;
        uint64 deadline;
        uint256 nextTokenId;
        uint256 maxTokenId;
    }

    event SetMinter(address account, bool indexed isMinter);
    event Add(bytes32 indexed slug, address signer, uint64 deadline, uint256 fromTokenId, uint256 maxTokenId);
    event Claim(bytes32 indexed slug, bytes32 indexed id, address indexed to, uint256 tokenId, uint256 price);

    constructor(
        address _nftContract,
        address _levx,
        address _wallet
    ) {
        nftContract = _nftContract;
        levx = _levx;
        wallet = _wallet;
    }

    function setMinter(address account, bool _isMinter) external onlyOwner {
        isMinter[account] = _isMinter;

        emit SetMinter(account, _isMinter);
    }

    function transferOwnershipOfNFTContract(address newOwner) external onlyOwner {
        INFT721(nftContract).transferOwnership(newOwner);
    }

    function setRoyaltyFeeRecipient(address _royaltyFeeRecipient) external onlyOwner {
        INFT721(nftContract).setRoyaltyFeeRecipient(_royaltyFeeRecipient);
    }

    function setRoyaltyFee(uint8 _royaltyFee) external onlyOwner {
        INFT721(nftContract).setRoyaltyFee(_royaltyFee);
    }

    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        INFT721(nftContract).setTokenURI(tokenId, uri);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        INFT721(nftContract).setBaseURI(baseURI);
    }

    function parkTokenIds(uint256 toTokenId) external onlyOwner {
        INFT721(nftContract).parkTokenIds(toTokenId);
    }

    function mint(
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {
        require(msg.sender == owner() || isMinter[msg.sender], "LEVX: FORBIDDEN");

        INFT721(nftContract).mint(to, tokenId, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external {
        require(msg.sender == owner() || isMinter[msg.sender], "LEVX: FORBIDDEN");

        INFT721(nftContract).mintBatch(to, tokenIds, data);
    }

    function add(
        bytes32 slug,
        address signer,
        uint64 deadline,
        uint256 fromTokenId,
        uint256 maxTokenId
    ) external onlyOwner {
        Airdrop storage airdrop = airdrops[slug];
        require(airdrop.signer == address(0), "LEVX: ADDED");

        airdrop.signer = signer;
        airdrop.deadline = deadline;
        airdrop.nextTokenId = fromTokenId;
        airdrop.maxTokenId = maxTokenId;

        emit Add(slug, signer, deadline, fromTokenId, maxTokenId);
    }

    function claim(
        bytes32 slug,
        bytes32 id,
        uint256 tokenId,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address to,
        bytes calldata data
    ) external {
        Airdrop storage airdrop = airdrops[slug];
        {
            (address signer, uint64 deadline) = (airdrop.signer, airdrop.deadline);

            require(signer != address(0), "LEVX: INVALID_SLUG");
            require(deadline == 0 || uint64(block.timestamp) < deadline, "LEVX: EXPIRED");
            require(!_minted[slug][id], "LEVX: MINTED");

            bytes32 message = keccak256(abi.encodePacked(slug, id, tokenId, price));
            require(ECDSA.recover(ECDSA.toEthSignedMessageHash(message), v, r, s) == signer, "LEVX: UNAUTHORIZED");
        }

        {
            (uint256 nextTokenId, uint256 maxTokenId) = (airdrop.nextTokenId, airdrop.maxTokenId);

            if (tokenId == 0) {
                tokenId = nextTokenId;
                while (tokenId < maxTokenId) {
                    if (INFT721(nftContract).ownerOf(tokenId) == address(0)) {
                        break;
                    }
                    tokenId++;
                }
                require(tokenId < maxTokenId, "LEVX: INVALID_TOKEN_ID");
                airdrop.nextTokenId = tokenId + 1;
            } else {
                require(tokenId >= nextTokenId && tokenId < maxTokenId, "LEVX: INVALID_TOKEN_ID");
            }
        }

        _minted[slug][id] = true;

        emit Claim(slug, id, to, tokenId, price);
        if (price > 0) IERC20(levx).safeTransferFrom(msg.sender, wallet, price);
        INFT721(nftContract).mint(to, tokenId, data);
    }
}