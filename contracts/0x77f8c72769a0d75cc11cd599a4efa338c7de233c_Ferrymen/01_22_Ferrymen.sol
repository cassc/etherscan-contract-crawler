// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";
import "./DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
interface ISoulContract {
    function burnMultiple(uint256[] memory tokenIds) external;
}

contract Ferrymen is ERC721Enumerable, Ownable, DefaultOperatorFilterer, PaymentSplitter {
    using Strings for uint256;
    using ECDSA for bytes32;

    event Burned(uint256[] tokenIds, address account);

    string private _baseTokenURI;
    string private _tokenURISuffix;
    uint256 private teamLength;

    uint256 public maxSupply = 10000;

    uint256 public publicMintCost = 25000000000000000; // 0.025 ETH

    uint256 public maxPerTx = 25;
    
    uint256 public maxBurnPerTx = 25;

    address public signerAddress = 0x7d350fcf9b40fB38DFCb5dEF91AEE01573A23619;

    bool public isPublic;
    bool public isAllowList;

    address public soulContract = 0x4928c942D9334971afF7CCd4941A078bDCAC648D;

    mapping(bytes => bool) public usedSignatures;

    constructor(string memory newBaseURI, string memory newSuffix, address[] memory team, uint[] memory teamShares)
        ERC721("Ferrymen", "Ferrymen") PaymentSplitter(team, teamShares)
    {
        _baseTokenURI = newBaseURI;
        _tokenURISuffix = newSuffix;
        teamLength = team.length;
    }

    function mint(uint256 count) external payable {
        require(isPublic, "Public sale is not active");
        require(count <= maxPerTx, "Max per tx");
        require(msg.value >= publicMintCost * count, "Insufficient ETH sent");
        uint256 supply = _owners.length;
        require(supply + count < maxSupply, "Max supply reached");
        for (uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function allowListMint(uint256[] calldata tokenIds, bytes memory signature)
        external
        payable
    {
        require(isAllowList, "Wait for allowlist mint");
        require(soulContract != address(0), "Soul contract not set");
        require(signerAddress != address(0), "Signer not set");
        require(!usedSignatures[signature], "Signature already used");
        bytes32 inputHash = keccak256(abi.encodePacked(msg.sender, tokenIds));
        bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
        address recoveredAddress = ethSignedMessageHash.recover(signature);
        require(recoveredAddress == signerAddress, "Wrong signer");
        usedSignatures[signature] = true;
        uint256 supply = _owners.length;
        uint256 len = tokenIds.length;
        require(len <= maxBurnPerTx, "Max burn per tx");
        require(supply + len < maxSupply, "Max supply reached");
        ISoulContract(soulContract).burnMultiple(tokenIds);
        emit Burned(tokenIds, msg.sender);
        for (uint256 i = 0; i < len; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    tokenId.toString(),
                    _tokenURISuffix
                )
            );
    }

    function airdrop(uint256[] calldata quantity, address[] calldata recipient)
        external
        onlyOwner
    {
        require(
            quantity.length == recipient.length,
            "Quantity length is not equal to recipients"
        );

        uint256 totalQuantity;
        for (uint256 i = 0; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }

        uint256 supply = _owners.length;
        require(supply + totalQuantity <= maxSupply, "Max supply reached");

        delete totalQuantity;

        for (uint256 i = 0; i < recipient.length; ++i) {
            for (uint256 j = 0; j < quantity[i]; ++j) {
                _safeMint(recipient[i], supply++);
            }
        }
    }

    function toggleAllowList() external onlyOwner {
        isAllowList = !isAllowList;
    }

    function setMaxSupply(uint256 newMax) external onlyOwner {
        require(newMax < maxSupply, "Must be less than current supply");
        maxSupply = newMax;
    }

    function toggleSales() external onlyOwner {
        isPublic = !isPublic;
        isAllowList = !isAllowList;
    }

    function togglePublicSale() external onlyOwner {
        isPublic = !isPublic;
    }

    function setSigner(address signer) external onlyOwner {
        signerAddress = signer;
    }

    function setPublicMintCost(uint256 cost) external onlyOwner {
        publicMintCost = cost;
    }

    function setMaxPerTx(uint256 newMax) external onlyOwner {
        maxPerTx = newMax;
    }
  
    function setMaxBurnPerTx(uint256 newMax) external onlyOwner {
        maxBurnPerTx = newMax;
    }

    function setBaseURI(string calldata newBaseURI, string calldata newSuffix)
        external
        onlyOwner
    {
        _baseTokenURI = newBaseURI;
        _tokenURISuffix = newSuffix;
    }

  function releaseAll() external onlyOwner {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}