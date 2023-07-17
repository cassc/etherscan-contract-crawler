//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Alienverse is ERC721A, Ownable, PaymentSplitter {
    bool public saleActive = false;
    bool public presaleActive = false;

    string internal baseTokenURI;

    uint256 public price = 0.1 ether;
    uint256 public wlPrice = 0.095 ether;
    uint256 public maxSupply = 5757;
    uint256 public maxTx = 10;

    bytes32 internal fcMerkleRoot;
    bytes32 internal wlMerkleRoot;
    bytes32 internal vipMerkleRoot;

    uint256 private teamLength;

    constructor(
        address[] memory _team,
        uint256[] memory _teamShares,
        bytes32 _fcMerkleRoot,
        bytes32 _wlMerkleRoot,
        bytes32 _vipMerkleRoot,
        string memory _baseTokenURI
    ) ERC721A("Alienverse", "ALIEN") PaymentSplitter(_team, _teamShares) {
        fcMerkleRoot = _fcMerkleRoot;
        wlMerkleRoot = _wlMerkleRoot;
        vipMerkleRoot = _vipMerkleRoot;
        baseTokenURI = _baseTokenURI;
        teamLength = _team.length;
    }

    function getMaxWLMintAmount(uint256 wlType)
        internal
        pure
        returns (uint256)
    {
        if (wlType == 0) {
            // FC Whitelist
            return 2;
        } else if (wlType == 1) {
            // Normal WL
            return 3;
        } else if (wlType == 2) {
            // VIP
            return 4;
        } else {
            return 0;
        }
    }

    function getMerkleRoot(uint256 wlType) internal view returns (bytes32) {
        if (wlType == 0) {
            //FC Whitelist
            return fcMerkleRoot;
        } else if (wlType == 1) {
            // Normal WL
            return wlMerkleRoot;
        } else if (wlType == 2) {
            // VIP
            return vipMerkleRoot;
        } else {
            return 0;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string calldata uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function setFcMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        fcMerkleRoot = newMerkleRoot;
    }

    function setWlMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        wlMerkleRoot = newMerkleRoot;
    }

    function setVipMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        vipMerkleRoot = newMerkleRoot;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setWlPrice(uint256 newPrice) external onlyOwner {
        wlPrice = newPrice;
    }

    function setMaxSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function togglePresaleActive() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function setMaxTx(uint256 newMax) external onlyOwner {
        maxTx = newMax;
    }

    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokens = new uint256[](balanceOf(_owner));
        uint256 ctr = 0;
        for (uint256 i = 0; i < totalSupply(); i++) {
            if (ownerOf(i) == _owner) {
                tokens[ctr] = i;
                ctr++;
            }
        }
        return tokens;
    }

    function giveaway(address[] calldata adds, uint256 qty) external onlyOwner {
        uint256 minted = totalSupply();
        require(
            (adds.length * qty) + minted <= maxSupply,
            "Value exceeds total supply"
        );
        for (uint256 i = 0; i < adds.length; i++) {
            _safeMint(adds[i], qty);
        }
    }

    function mintWhitelist(
        uint256 qty,
        uint256 wlType,
        bytes32[] calldata _merkleProof
    ) external payable canMint(qty, true) canMintWl(qty, wlType, _merkleProof) {
        _safeMint(msg.sender, qty);
    }

    function mint(uint256 qty) external payable canMint(qty, false) {
        _safeMint(msg.sender, qty);
    }

    function releaseAll() external onlyOwner {
        for (uint256 i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    // Modifiers
    modifier canMint(uint256 qty, bool isWl) {
        if (isWl) {
            require(presaleActive, "Pre-sale isn't active");
        } else {
            require(saleActive, "Sale isn't active");
        }
        require(
            _numberMinted(msg.sender) + qty <= 10,
            "Can't mint more than 10"
        );
        require(qty <= maxTx && qty > 0, "Qty of mints not allowed");
        require(qty + totalSupply() <= maxSupply, "Value exceeds total supply");
        require(msg.value == (isWl ? wlPrice : price) * qty, "Invalid value");
        _;
    }

    modifier canMintWl(
        uint256 qty,
        uint256 wlType,
        bytes32[] calldata _merkleProof
    ) {
        uint256 numAllowed = getMaxWLMintAmount(wlType);
        bytes32 merkleRoot = getMerkleRoot(wlType);
        require(
            _numberMinted(msg.sender) + qty <= numAllowed,
            "Can't mint anymore during presale"
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Address not on the whitelist"
        );
        _;
    }
}