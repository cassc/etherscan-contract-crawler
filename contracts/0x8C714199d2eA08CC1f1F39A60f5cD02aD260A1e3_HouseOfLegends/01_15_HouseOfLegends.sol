// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract HouseOfLegends is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    // Accounts
    address public constant creatorAddress =
        0x451B5300598367ed9F2C2265edcF39fa842a36ca;

    // Minting Variables
    uint256 public maxSupply = 9993;
    uint256 public maxPrivateSupply = 438;
    uint256 public maxGiftSupply = 60;
    uint256 public maxPublicSupply =
        maxSupply - maxPrivateSupply - maxGiftSupply; //9,495
    uint256 public mintPrice = 0.14159 ether;
    uint256 public maxPurchase = 5;
    uint256 public phaseOneMaxPurchase = 3;
    uint256 public phaseTwoMaxPurchase = 2;

    // Sale Status
    bool public locked;
    bool public publicSaleActive;
    bool public phaseOnePresaleActive;
    bool public phaseTwoPresaleActive;
    uint256 public privateAmountMinted;
    uint256 public giftAmountMinted;
    uint256 public publicAmountMinted;
    mapping(address => uint256) private redeemedPhaseOneAccounts;
    mapping(address => uint256) private redeemedPhaseTwoAccounts;

    // Merkle Roots
    bytes32 private phaseOneRoot;
    bytes32 private phaseTwoRoot;
    bytes32 private giftListRoot;

    // Metadata
    string _baseTokenURI;

    // Events
    event PublicSaleActivation(bool isActive);

    event PhaseOnePresaleActivation(bool isActive);

    event PhaseTwoPresaleActivation(bool isActive);

    // Contract
    constructor() ERC721("House Of Legends", "HOL") {}

    // Merkle Proofs

    function setPhaseOneRoot(bytes32 _root) external onlyOwner {
        phaseOneRoot = _root;
    }

    function setPhaseTwoRoot(bytes32 _root) external onlyOwner {
        phaseTwoRoot = _root;
    }

    function setGiftListRoot(bytes32 _root) external onlyOwner {
        giftListRoot = _root;
    }

    function _leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function isWhitelisted(
        address _account,
        bytes32[] calldata _proof,
        bytes32 _root
    ) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leaf(_account));
    }

    // Minting
    function ownerMint(address _to, uint256 _count) external onlyOwner {
        require(
            privateAmountMinted + _count <= maxPrivateSupply,
            "exceeds max private supply"
        );
        require(totalSupply() + _count <= maxSupply, "exceeds max supply");
        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            privateAmountMinted++;
            _safeMint(_to, mintIndex);
        }
    }

    function giftMint(
        address _to,
        uint256 _count,
        bytes32[] calldata _proof
    ) external {
        require(phaseOnePresaleActive, "Phase one must be active");
        require(isWhitelisted(_to, _proof, giftListRoot), "not on gift list");
        require(
            giftAmountMinted + _count <= maxGiftSupply,
            "exceeds max gift supply"
        );
        require(totalSupply() + _count <= maxSupply, "exceeds max supply");

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            giftAmountMinted++;
            _safeMint(_to, mintIndex);
        }
    }

    function phaseOnePresaleMint(
        address _to,
        uint256 _count,
        bytes32[] calldata _proof
    ) external payable {
        uint256 tokensToMint = _count;
        if (_count == 3) {
            tokensToMint = 4;
        }
        require(phaseOnePresaleActive, "Phase one must be active");
        require(
            isWhitelisted(_to, _proof, phaseOneRoot),
            "not whitelisted for phase one"
        );
        require(
            redeemedPhaseOneAccounts[_to] + _count <= phaseOneMaxPurchase,
            "exceeds the account's quota"
        );
        require(
            publicAmountMinted + _count <= maxPublicSupply,
            "exceeds max public supply"
        );
        require(totalSupply() + _count <= maxSupply, "exceeds max supply");
        require(
            mintPrice * _count <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < tokensToMint; i++) {
            uint256 mintIndex = totalSupply();
            redeemedPhaseOneAccounts[_to]++;
            publicAmountMinted++;
            _safeMint(_to, mintIndex);
        }
    }

    function phaseTwoPresaleMint(
        address _to,
        uint256 _count,
        bytes32[] calldata _proof
    ) external payable {
        require(phaseTwoPresaleActive, "Phase two must be active");
        require(
            isWhitelisted(_to, _proof, phaseTwoRoot),
            "not whitelisted for phase two"
        );
        require(
            redeemedPhaseTwoAccounts[_to] + _count <= phaseTwoMaxPurchase,
            "exceeds the account's quota"
        );
        require(
            publicAmountMinted + _count <= maxPublicSupply,
            "exceeds max public supply"
        );
        require(totalSupply() + _count <= maxSupply, "exceeds max supply");
        require(
            mintPrice * _count <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            redeemedPhaseTwoAccounts[_to]++;
            publicAmountMinted++;
            _safeMint(_to, mintIndex);
        }
    }

    function mint(address _to, uint256 _count) external payable {
        require(publicSaleActive, "Sale must be active");
        require(_count <= maxPurchase, "exceeds maximum purchase amount");
        require(
            publicAmountMinted + _count <= maxPublicSupply,
            "exceeds max public supply"
        );
        require(totalSupply() + _count <= maxSupply, "exceeds max supply");
        require(
            mintPrice * _count <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            publicAmountMinted++;
            _safeMint(_to, mintIndex);
        }
    }

    // Configurations
    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function togglePhaseOnePresaleStatus() external onlyOwner {
        phaseOnePresaleActive = !phaseOnePresaleActive;
        emit PhaseOnePresaleActivation(phaseOnePresaleActive);
    }

    function togglePhaseTwoPresaleStatus() external onlyOwner {
        phaseTwoPresaleActive = !phaseTwoPresaleActive;
        emit PhaseOnePresaleActivation(phaseTwoPresaleActive);
    }

    function toggleSaleStatus() external onlyOwner {
        publicSaleActive = !publicSaleActive;
        emit PublicSaleActivation(publicSaleActive);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        maxPurchase = _maxPurchase;
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance can't be zero");
        _withdraw(creatorAddress, balance.div(3));
        _withdraw(owner(), address(this).balance);
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        require(!locked, "Contract metadata methods are locked");
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}