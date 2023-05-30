// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@shoyunft/contracts/contracts/interfaces/INFT721.sol";

contract NFTAirdrops is Ownable {
    address public immutable nftContract;
    mapping(bytes32 => Airdrop) public airdrops;
    mapping(address => bool) public isMinter;
    mapping(bytes32 => mapping(bytes32 => bool)) internal _minted;
    uint256 internal _tokenId;

    struct Airdrop {
        address signer;
        uint32 deadline;
        uint32 max;
        uint32 minted;
    }

    event SetMinter(address account, bool indexed isMinter);
    event Add(bytes32 indexed slug, address signer, uint32 deadline, uint32 max);
    event Claim(bytes32 indexed slug, bytes32 indexed id, address indexed to, uint256 tokenId);

    constructor(address _nftContract, uint256 fromTokenId) {
        nftContract = _nftContract;
        _tokenId = fromTokenId;
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
        uint32 deadline,
        uint32 max
    ) external onlyOwner {
        Airdrop storage airdrop = airdrops[slug];
        require(airdrop.signer == address(0), "LEVX: ADDED");

        airdrop.signer = signer;
        airdrop.deadline = deadline;
        airdrop.max = max;

        emit Add(slug, signer, deadline, max);
    }

    function claim(
        bytes32 slug,
        bytes32 id,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address to,
        bytes calldata data
    ) external {
        Airdrop storage airdrop = airdrops[slug];
        (address signer, uint32 deadline, uint32 max, uint32 minted) = (
            airdrop.signer,
            airdrop.deadline,
            airdrop.max,
            airdrop.minted
        );

        require(signer != address(0), "LEVX: INVALID_SLUG");
        require(deadline == 0 || uint32(block.timestamp) < deadline, "LEVX: EXPIRED");
        require(max == 0 || minted < max, "LEVX: FINISHED");
        require(!_minted[slug][id], "LEVX: MINTED");

        {
            bytes32 message = keccak256(abi.encodePacked(slug, id));
            require(ECDSA.recover(ECDSA.toEthSignedMessageHash(message), v, r, s) == signer, "LEVX: UNAUTHORIZED");
        }

        airdrop.minted = minted + 1;
        _minted[slug][id] = true;

        uint256 tokenId = _tokenId++;
        emit Claim(slug, id, to, tokenId);
        INFT721(nftContract).mint(to, tokenId, data);
    }
}