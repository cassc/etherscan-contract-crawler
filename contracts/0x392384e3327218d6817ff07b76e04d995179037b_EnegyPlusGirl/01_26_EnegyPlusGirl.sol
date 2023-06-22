// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC4906.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {UpdatableOperatorFilterer} from "./opensea/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "./opensea/RevokableDefaultOperatorFilterer.sol";

contract EnegyPlusGirl is ERC4906, Ownable, ERC2981, RevokableDefaultOperatorFilterer {
    using Strings for uint256;

    ////////////////////////////////////////////////////////////////////////////////////
    // Constant & variable
    ////////////////////////////////////////////////////////////////////////////////////
    uint public rd1Price;
    uint public rd2Price;
    uint public pbPrice;
    uint public rd1StrTime;
    uint public rd1EndTime;
    uint public rd2StrTime;
    uint public rd2EndTime;
    uint public pbStrTime;
    uint public pbEndTime;
    uint public revealTime;
    uint public maxMintCount;
    
    string private CID;
    string private revealCID;
    
    bytes32 private rd1MerkleRoot;
    bytes32 private rd2MerkleRoot;
    mapping(address => uint) public mintedCount;
    
    address payable public depositAddress;
    
    constructor(
        address payable _depositAddress,
        string memory _CID,
        string memory _revealCID,
        uint _rd1Price,
        uint _rd2Price,
        uint _pbPrice,
        uint _maxMintCount
    ) ERC4906("Energy Plus Girl", "EPG") {
        depositAddress = _depositAddress;
        CID = _CID;
        revealCID = _revealCID;
        rd1Price = _rd1Price;
        rd2Price = _rd2Price;
        pbPrice = _pbPrice;
        maxMintCount = _maxMintCount;
    }
    
    ////////////////////////////////////////////////////////////////////////////////////
    // User Function
    ////////////////////////////////////////////////////////////////////////////////////
    function Mint(bytes32[] calldata _proof, uint _upperLimit, uint _amount) external payable {
        require((_totalMinted() + _amount) <= maxMintCount, "Beyond Max Supply");

        uint price;

        uint section = GetRoundSection();
        if (section == 1) {
            require(CheckValidityPlusLimit(_proof, rd1MerkleRoot, _upperLimit), "Not on the AllowList1");
            require((_amount + mintedCount[msg.sender]) <= _upperLimit, "Cannot mint more than your upper limit");
            unchecked{ price = rd1Price * _amount; }
        } else if (section == 2) {
            require(CheckValidityPlusLimit(_proof, rd2MerkleRoot, _upperLimit), "Not on the AllowList2");
            require((_amount + mintedCount[msg.sender]) <= _upperLimit, "Cannot mint more than your upper limit");
            unchecked{ price = rd2Price * _amount; }
        } else if (section == 3) {
            price = pbPrice * _amount;
        } else {
            require(false, "Not a sale period");
        }

        require(price == msg.value, "Different amounts");
        depositAddress.transfer(address(this).balance);

        unchecked{
            mintedCount[msg.sender] += _amount;
        }
        _safeMint(msg.sender, _amount);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Not exists");

        if (block.timestamp < revealTime) {
            return string(abi.encodePacked(revealCID));
        }
        
        return string.concat(CID, Strings.toString(_tokenId), ".json");
    }

    // before:0, round1:1, round2:2, public:3, after:9
    function GetRoundSection() public view returns (uint) {
        if (block.timestamp < rd1StrTime) {
            return 0;
        } else if (rd1StrTime < block.timestamp && block.timestamp < rd1EndTime) {
            return 1;
        } else if (rd2StrTime < block.timestamp && block.timestamp < rd2EndTime) {
            return 2;
        } else if (pbStrTime < block.timestamp && block.timestamp < pbEndTime) {
            return 3;
        }

        return 9;
    }

    ////////////////////////////////////////////////////////////////////////////////////
    // Owner Function
    ////////////////////////////////////////////////////////////////////////////////////
    function OwnerMint(address _toAddress, uint256 _amount) public onlyOwner {
        _safeMint(_toAddress, _amount);
    }

    function BulkMint(address[] calldata _toAddress, uint[] calldata _amount) external onlyOwner {
        for(uint i = 0; i < _toAddress.length;) {
            OwnerMint(_toAddress[i], _amount[i]);
            unchecked{ i++; }
        }
    }

    function SetMaxMintCount(uint256 _amount) external onlyOwner {
        require(_totalMinted() <= _amount, "mintCount <= _amount");
        maxMintCount = _amount;
    }

    function SetPrice(uint _rd1Price, uint _rd2Price, uint _pbPrice) external onlyOwner {
        rd1Price = _rd1Price;
        rd2Price = _rd2Price;
        pbPrice = _pbPrice;
    }

    function SetRoundSection(
        uint256 _rd1StrTime, uint256 _rd1EndTime,
        uint256 _rd2StrTime, uint256 _rd2EndTime,
        uint256 _pbStrTime, uint256 _pbEndTime) external onlyOwner {
        rd1StrTime = _rd1StrTime;
        rd1EndTime = _rd1EndTime;
        rd2StrTime = _rd2StrTime;
        rd2EndTime = _rd2EndTime;
        pbStrTime = _pbStrTime;
        pbEndTime = _pbEndTime;
    }

    function SetRevealTime(uint256 _revealTime) external onlyOwner {
        revealTime = _revealTime;
    }

    function SetCID(string calldata _CID, string calldata _revealCID) external onlyOwner {
        CID = _CID;
        revealCID = _revealCID;
    }

    function SetDepositAddress(address payable _depositAddress) external onlyOwner {
        depositAddress = _depositAddress;
    }

    function SetAllowList1(bytes32 _merkleRoot) external onlyOwner {
        rd1MerkleRoot = _merkleRoot;
    }
    function SetAllowList2(bytes32 _merkleRoot) external onlyOwner {
        rd2MerkleRoot = _merkleRoot;
    }

    function SetDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    ////////////////////////////////////////////////////////////////////////////////////
    // Private Function
    ////////////////////////////////////////////////////////////////////////////////////
    function CheckValidityPlusLimit(bytes32[] calldata proof, bytes32 merkleRoot, uint _upperLimit) private view returns (bool) {
        string memory tmpLeaf = string.concat(Strings.toHexString(uint160(msg.sender)), ',', _upperLimit.toString());
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(tmpLeaf)));
    }

    ////////////////////////////////////////////////////////////////////////////////////
    // Opensea Function
    ////////////////////////////////////////////////////////////////////////////////////
    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721Psi, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override(ERC721Psi, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Psi, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721Psi, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721Psi, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the ERC721 token contract.
     */
    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC4906, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}