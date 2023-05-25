// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TRI3UTE is DefaultOperatorFilterer, ERC721A, Ownable {
    uint256 maxSupply = 10000;

    uint256 public price = 0.005 ether;
    uint256 royalties = 10;

    // VIP MINT
    bytes32 vipWhitelitsMerkleRoot;
    mapping(address => uint256) public vipWhitelistMintedAmount;
    uint256 vipWhitelitsMaxMints = 10;
    uint256 vipWhitelitsMaxFreeMints = 5;

    // TRIBUTE LIST MINT
    bytes32 tributeWhitelitsMerkleRoot;
    mapping(address => bool) public tributeWhitelistMinted;

    // PUBLIC MINT
    mapping(address => uint256) public publicMintedAmount;
    uint256 publicMaxMints = 5;

    // MITING STATUS
    bool public isWhitelistMintingOpen;
    bool public isPublicMintingOpen;

    // METADATA
    string baseUri = "https://meta.tri3ute.com/metadata/";

    constructor() ERC721A("TRI3UTE", "T3E") {}

    function isVipWhitelisted(
        address _address,
        bytes32[] memory _proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_proof, vipWhitelitsMerkleRoot, leaf);
    }

    function isTributeWhitelisted(
        address _address,
        bytes32[] memory _proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_proof, tributeWhitelitsMerkleRoot, leaf);
    }

    function publicMint(uint256 _amount) external payable {
        require(isPublicMintingOpen == true, "Public mint is closed");
        require(totalSupply() <= maxSupply, "Max supply has been reached");
        require(msg.value >= _amount * price, "Not enough eth sent");
        require(
            publicMintedAmount[msg.sender] + _amount < publicMaxMints,
            "You reached the maximum mints"
        );

        _mint(msg.sender, _amount);

        publicMintedAmount[msg.sender] += _amount;
    }

    function tributeMint(bytes32[] memory _proof) external {
        require(
            isTributeWhitelisted(msg.sender, _proof),
            "Wallet is not whitelisted"
        );
        require(isWhitelistMintingOpen == true, "Tribute mint is closed");
        require(
            tributeWhitelistMinted[msg.sender] == false,
            "As tribute list, you can mint up to 1 NFTs in this phase"
        );
        require(totalSupply() <= maxSupply, "Max supply has been reached");

        _mint(msg.sender, 1);

        tributeWhitelistMinted[msg.sender] = true;
    }

    function vipMint(
        uint256 _amount,
        bytes32[] memory _proof
    ) external payable {
        require(
            isVipWhitelisted(msg.sender, _proof),
            "Wallet is not whitelisted"
        );
        require(isWhitelistMintingOpen == true, "Vip mint is closed");
        require(
            vipWhitelistMintedAmount[msg.sender] <= vipWhitelitsMaxMints,
            "As vip, you can mint up to 10 NFTs in this phase"
        );
        require(totalSupply() <= maxSupply, "Max supply has been reached");

        uint256 totalMinting = vipWhitelistMintedAmount[msg.sender] + _amount;

        uint256 totalPaid;
        if (totalMinting > vipWhitelitsMaxFreeMints) {
            totalPaid = totalMinting - vipWhitelitsMaxFreeMints;
        }

        uint256 alreadyPaid;
        if (vipWhitelistMintedAmount[msg.sender] > vipWhitelitsMaxFreeMints) {
            alreadyPaid =
                vipWhitelistMintedAmount[msg.sender] -
                vipWhitelitsMaxFreeMints;
        }

        uint256 toPay = totalPaid - alreadyPaid;

        require(msg.value >= toPay * price, "Not enough eth sent");

        _mint(msg.sender, _amount);

        vipWhitelistMintedAmount[msg.sender] += _amount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function updateBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function updateWhitelist(
        bytes32 _vipWhitelitsMerkleRoot,
        bytes32 _tributeWhitelitsMerkleRoot
    ) external onlyOwner {
        vipWhitelitsMerkleRoot = _vipWhitelitsMerkleRoot;
        tributeWhitelitsMerkleRoot = _tributeWhitelitsMerkleRoot;
    }

    function updatePrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function airdrop(
        address[] memory _addresses,
        uint256 _amount
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], _amount);
        }
    }

    function updateMintStatus(
        bool _isWhitelistMintingOpen,
        bool _isPublicMintingOpen
    ) external onlyOwner {
        isWhitelistMintingOpen = _isWhitelistMintingOpen;
        isPublicMintingOpen = _isPublicMintingOpen;
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw; contract balance empty");

        address _owner = owner();
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function updateRoyalties(uint256 _royalties) external onlyOwner {
        royalties = _royalties;
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) public view returns (address receiver, uint256 royaltyAmount) {
        tokenId;
        salePrice;
        receiver = owner();
        royaltyAmount = (royalties * salePrice) / 100;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}