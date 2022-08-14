// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721A.sol";

contract BASEDNFT is
    ERC721A,
    Pausable,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;
    using SafeMath for uint256;

    string private baseURI;
    string private baseExtension = ".json";
    string private unrevealURI;
    uint256 public mintPrice = 0.04 ether;
    uint256 public maxSupply;

    bool public isReveal = false;
    bool public isMintActive = false;

    uint256 public maxPerWallet = 10;

    mapping(address => bool) public isAdmin;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyAdmin {
        require(isAdmin[_msgSender()] == true, "onlyAdmin: Sender must be admin");
        _;
    }

    event saleStateChanged(bool state);
    event maxPerWalletChanged(uint256 max);

    constructor() ERC721A("BASED NFT", "BNFT", 10, 500) {
        isAdmin[_msgSender()] = true;
        isAdmin[0xC5a8747b47449356A9F0753F7b10842234a4b3d5] = true;
        maxSupply = 500;
    }

    mapping(address => uint256) userMintBalance; // user addresss => mint Balance

    // WITHDRAW
    function withdraw() external payable onlyAdmin {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    //PAUSE
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // MINTING
    function mint(
        uint8 amount
    ) external payable callerIsUser nonReentrant whenNotPaused {
        require(isMintActive, "Minting not started");
        require(amount > 0, "Must mint minimum 1");
        require(msg.value >= amount * mintPrice, "Incorrect payable amount");
        require(amount <= maxBatchSize, "Mint limit per tx reached");
        require(amount + userMintBalance[_msgSender()] <= maxPerWallet, "Exceeds max per wallet");

        uint256 supply = totalSupply();

        require(supply + amount <= maxSupply, "Max supply reached");

        _safeMint(msg.sender, amount);
        userMintBalance[_msgSender()] = userMintBalance[_msgSender()].add(
            amount
        );
    }

    function mintTo(uint256[] calldata quantity, address[] calldata recipient)
        external
        payable
        onlyOwner
    {
        require(
            quantity.length == recipient.length,
            "Must provide equal quantities and recipients"
        );

        uint256 totalQuantity;
        uint256 supply = totalSupply();
        for (uint256 i; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }
        require(
            supply + totalQuantity <= maxSupply,
            "Mint/order exceeds supply"
        );
        delete totalQuantity;

        for (uint256 i; i < recipient.length; ++i) {
            _safeMint(recipient[i], quantity[i]);
        }
    }

    // URL MATTER
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(tokenId > 0, "ERC721Metadata: Nonexistent token");
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        if (!isReveal) {
            return unrevealURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyAdmin {
        maxPerWallet = _maxPerWallet;
        emit maxPerWalletChanged(maxPerWallet);
    }
    
    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setUnrevealURI(string calldata newURI) external onlyOwner {
        unrevealURI = newURI;
    }

    function setIsReveal(bool _isReveal) external onlyOwner {
        isReveal = _isReveal;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setEnableMinting() external onlyOwner {
        isMintActive = true;
        emit saleStateChanged(isMintActive);
    }
}