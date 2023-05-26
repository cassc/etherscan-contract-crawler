//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// https://www.alliedesports.gg/terms-of-use-privacy-policy
// https://www.alliedesports.gg/digital-collectible-terms

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EpicBeast is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 8591;
    uint256 public constant MAX_MINT_AMOUNT = 6;

    uint256 public constant OG_PRICE = 0.045 ether;
    uint256 public constant BEAST_LIST_PRICE = 0.055 ether;
    uint256 public constant PUBLIC_PRICE = 0.065 ether;

    uint256 public presaleAt;
    uint256 public launchAt;
    uint256 public launchEndAt;

    address public ogSigner;
    address public beastListSigner;

    bool public operational = true;
    mapping(address => uint256) public addressMintBalance;

    constructor(
        string memory baseURI_,
        uint256 presaleAt_,
        uint256 launchAt_,
        uint256 launchEndAt_,
        address ogSigner_,
        address beastListSigner_
    ) ERC721A("EpicBeast", "EPICBEAST") {
        _baseTokenURI = baseURI_;

        presaleAt = presaleAt_;
        launchAt = launchAt_;
        launchEndAt = launchEndAt_;

        ogSigner = ogSigner_;
        beastListSigner = beastListSigner_;
    }

    modifier mintValidation(uint256 _mintQty) {
        uint256 supply = totalSupply();
        require(operational, "Operation is paused");
        require(_mintQty > 0, "Must mint minimum of 1 token");
        require(supply + _mintQty <= MAX_SUPPLY, "Exceeds maximum token supply");

        if (isPresale()) {
            uint256 ownerMintedCount = addressMintBalance[msg.sender];
            require(ownerMintedCount + _mintQty <= MAX_MINT_AMOUNT, "Max NFT per address exceeded");
        }
        _;
    }

    function isPresale() public view returns (bool) {
        return block.timestamp >= presaleAt && block.timestamp < launchAt;
    }

    function isLaunched() public view returns (bool) {
        return block.timestamp >= launchAt && block.timestamp < launchEndAt;
    }

    function ogMint(
        address _to, 
        uint256 _mintQty,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external payable mintValidation(_mintQty) {
        require(block.timestamp >= presaleAt, "OG sale has not begun");
        require(block.timestamp < launchAt, "OG sale has ended");
        require(msg.value == _mintQty * OG_PRICE, "Amount of Ether sent is not correct");

        bytes32 digest = keccak256(abi.encode(msg.sender));

        require(_validMint(ogSigner, digest, r, s, v), "Invalid mint signature");
        
        mint(_to, _mintQty);
    }

    function beastlistMint(
        address _to, 
        uint256 _mintQty,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external payable mintValidation(_mintQty) {
        require(block.timestamp >= presaleAt, "Beastlist sale has not begun");
        require(block.timestamp < launchAt, "Beastlist sale has ended");
        require(msg.value == _mintQty * BEAST_LIST_PRICE, "Amount of Ether sent is not correct");

        bytes32 digest = keccak256(abi.encode(msg.sender));

        require(_validMint(beastListSigner, digest, r, s, v), "Invalid mint signature");
        
        mint(_to, _mintQty);
    }

    function launchMint(address _to, uint256 _mintQty) external payable mintValidation(_mintQty) {
        require(block.timestamp >= launchAt, "Public sale has not begun");
        require(block.timestamp < launchEndAt, "Public sale has ended");
        require(msg.value == _mintQty * PUBLIC_PRICE, "Amount of Ether sent is not correct");
        
        mint(_to, _mintQty);
    }

    function devMint(uint256 _mintQty) external onlyOwner {
        uint256 supply = totalSupply();

        require(supply + _mintQty <= MAX_SUPPLY, "Exceeds maximum token supply");
        
        _safeMint(msg.sender, _mintQty);
    }

    function mint(address _to, uint256 _mintQty) internal {
        addressMintBalance[msg.sender] += _mintQty;
        _safeMint(_to, _mintQty);
    }

    function _validMint(
        address administrator,
        bytes32 digest,
        bytes32 r,
        bytes32 s,
        uint8 v
    )
        internal view
        returns (bool)
    {
        address signer = ecrecover(digest, v, r, s);
        return signer == administrator;
    }

    function setPresaleAt(uint256 value) external onlyOwner {
        presaleAt = value;
    }

    function setLaunchAt(uint256 value) external onlyOwner {
        launchAt = value;
    }

    function setLaunchEndAt(uint256 value) external onlyOwner {
        launchEndAt = value;
    }

    function toggleOperational() external onlyOwner {
        operational = !operational;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    address private constant creatorAddress = 0xE91D76FEc73df000EBC0094E08A25A95cb0146aB;

    function withdraw() external onlyOwner {
        (bool success, ) = creatorAddress.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }
}