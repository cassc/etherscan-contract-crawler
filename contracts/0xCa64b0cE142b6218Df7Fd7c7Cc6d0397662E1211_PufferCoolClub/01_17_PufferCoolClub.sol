// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PufferCoolClub is ERC721A, Ownable, VRFConsumerBase {
    using SafeMath for uint256;
    using Strings for uint256;

    struct chainlinkParams {
        address coordinator;
        address linkToken;
        bytes32 keyHash;
    }

    string public METADATA_PROVENANCE_HASH = "";
    uint256 public price = 0.1 ether;
    uint256 public saleStart = 1655467200;
    uint256 public MAX_SUPPLY = 10000;

    // withdraw addresses
    address public f1;
    address public f2;

    uint256 public offsetIndex;
    uint256 public offsetIndexBlock;
    bool public isReveal;

    string private baseTokenURI;
    string private _preRevealURI;

    // Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    
    constructor(
        string memory baseURI,
        string memory preRevealURI,
        uint256 _fee,
        chainlinkParams memory chainlink
    ) VRFConsumerBase(chainlink.coordinator, chainlink.linkToken) ERC721A("Puffer Cool Club", "PUFFER") {
        keyHash = chainlink.keyHash;
        fee = _fee;
        setBaseURI(baseURI);
        setPreRevealURI(preRevealURI);
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (isReveal) {
            uint256 offsetId = tokenId.add(MAX_SUPPLY.sub(offsetIndex)).mod(MAX_SUPPLY);
            return string(abi.encodePacked(_baseURI(), offsetId.toString()));
        } else {
            return _preRevealURI;
        }
    }

    function publicMint(uint256 amount) public payable callerIsUser {
        require(block.timestamp > saleStart, "Public sale not live");
        require(amount > 0, "Bad amount");
        require(amount <= 20, "You can mint a maximum of 20 Puffer");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds maximum token supply");
        require(msg.value >= price * amount, "Ether sent is not correct");
        
        _safeMint(msg.sender, amount);
        if (offsetIndexBlock == 0 && totalSupply() >= MAX_SUPPLY) {
            offsetIndexBlock = block.number;
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setOffsetIndex() public onlyOwner returns (bytes32 requestId) {
        require(offsetIndex == 0, "Starting index has already been set");
        require(offsetIndexBlock != 0, "Starting index block must be set");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }
    
    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        isReveal = true;
        offsetIndex = (randomness % MAX_SUPPLY);
        if (offsetIndex == 0) {
            offsetIndex = 1;
        }
    }

    function emergencySetOffsetIndexBlock() external onlyOwner {
        require(offsetIndex == 0, "Starting index is already set");
        offsetIndexBlock = block.number;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setPreRevealURI(string memory preRevealURI) public onlyOwner {
        _preRevealURI = preRevealURI;
    }

    function setProvenanceHash(string memory _hash) external onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }

    function setSaleStart(uint256 _saleStart) external onlyOwner {
        saleStart = _saleStart;
    }

    function setAddresses(address[] memory _f) public onlyOwner {
        f1 = _f[0];
        f2 = _f[1];
    }

    function withdrawBalance() public onlyOwner {
        require(f1 != address(0) && f2 != address(0), "Beneficiary address not set");
        uint256 _onePerc = address(this).balance.div(100);
        uint256 _f1Amt = _onePerc.mul(21);
        uint256 _f2Amt = _onePerc.mul(79);

        require(payable(f1).send(_f1Amt));
        require(payable(f2).send(_f2Amt));
    }

    function withdrawERC20(address token, address to) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transfer(to, bal));
    }
}