// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SweetPalss is ERC721A, IERC2981, Ownable {
    // Max supply and Team Reserve
    uint256 public maxSupply;
    uint256 public maxPerTx = 5;
    uint256 public maxPerAddress = 20;
    uint256 public amountForAllowlistOrReserve = 200;

    // Mint Price
    uint256 public mintPrice;

    // ERC2981 Royalties Settings
    address public royaltyAddress;
    uint256 public royaltyPercent;

    // Metadata
    string private _baseTokenURI;
    bytes32 private merkleRoot;
    address private systemAddress;
    address private vault;

    bool public isDevMint;
    mapping(address => bool) public allowlists;

    uint256 public allowListAdoptTime;
    uint256 public publicAdoptTime;

    constructor(
        uint256 _maxBatchSize,
        uint256 _maxSupply,
        uint256 _mintPrice,
        address _royaltyAddress,
        uint256 _royaltyPercent,
        address _vault
    ) ERC721A("SweetPalss", "PAL", _maxBatchSize, _maxSupply) {
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        royaltyAddress = _royaltyAddress;
        royaltyPercent = _royaltyPercent;

        vault = _vault;
    }

    modifier userOnly() {
        require(tx.origin == msg.sender, "SP: We like real users");
        _;
    }

    function allowListAdopt(bytes32[] memory _merkleProof)
        external
        payable
        userOnly
    {
        require(
            block.timestamp > allowListAdoptTime &&
                block.timestamp < allowListAdoptTime + 24 hours,
            "SP: Allowlist adopt time has not passed"
        );
        require(
            !allowlists[msg.sender],
            "SP: Exceed more than allowlist limit"
        );
        require(msg.value >= mintPrice, "SP: Insufficient ether amount");
        require(_allowlistVerify(_merkleProof), "SP: Invalid merkle proof");
        require(totalSupply() + 1 <= maxSupply, "SP: Exceed max token supply");

        allowlists[msg.sender] = true;
        amountForAllowlistOrReserve -= 1;

        _safeMint(msg.sender, 1);

        refundIfOver(mintPrice);
    }

    function publicAdopt(uint256 _num) external payable userOnly {
        require(
            block.timestamp > publicAdoptTime &&
                block.timestamp < allowListAdoptTime,
            "SP: Public adopt time has not passed"
        );
        require(_num <= maxPerTx, "SP: Exceed max batch size");
        require(
            totalSupply() + _num <= maxSupply - amountForAllowlistOrReserve,
            "SP: Not enough remaining reserved"
        );
        require(
            numberMinted(msg.sender) + _num <= maxPerAddress,
            "SP: Can not mint this many"
        );

        _safeMint(msg.sender, _num);

        refundIfOver(mintPrice * _num);
    }

    function refundIfOver(uint256 _value) private {
        require(msg.value >= _value, "SP: Insufficient ether amount");
        if (msg.value > _value) {
            payable(msg.sender).transfer(msg.value - _value);
        }
    }

    function _allowlistVerify(bytes32[] memory merkleProof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    // For marketing use.
    function reserveMint() external onlyOwner {
        require(!isDevMint, "SP: Reserve mint has already been done");
        isDevMint = true;

        uint256 numChunks = amountForAllowlistOrReserve / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }

        uint256 remain = amountForAllowlistOrReserve - numChunks * maxBatchSize;

        _safeMint(msg.sender, remain);
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setAllowlistRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setSystemAddress(address _systemAddress) external onlyOwner {
        systemAddress = _systemAddress;
    }

    function setSystemTime(
        uint256 _publicAdoptTime,
        uint256 _allowListAdoptTime
    ) external onlyOwner {
        publicAdoptTime = _publicAdoptTime;
        allowListAdoptTime = _allowListAdoptTime;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(vault).transfer(balance);
    }

    function setRoyaltyReceiver(address royaltyReceiver) public onlyOwner {
        royaltyAddress = royaltyReceiver;
    }

    function setRoyaltyPercentage(uint256 royaltyPercentage) public onlyOwner {
        royaltyPercent = royaltyPercentage;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Non-existent token");
        return (royaltyAddress, (salePrice * royaltyPercent) / 100);
    }
}