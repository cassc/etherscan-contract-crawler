// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//phase 1 - collabs + prestiged eggs, 2/wallet and txn.
//price starts at 0.035, and drops by 0.005 after 10 minutes of no sales.

import {Ownable} from "open-zeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Strings} from "open-zeppelin/contracts/utils/Strings.sol";
import {ECDSA} from "open-zeppelin/contracts/utils/cryptography/ECDSA.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Viperz is ERC721A("Viperz", "VIPERZ"), Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant PHASE_ONE_SUPPLY = 3333;
    uint256 private constant INCREMENT = 0.005 ether;
    uint256 private constant TIME_INCREMENT = 10 minutes;

    address private ALSigner;

    string public baseURI;
    string private extURI;

    uint256 public currentPrice = 0.035 ether;
    uint256 private lastSaleTime;

    bool public paused = true;

    event TypedEggMint(address minter, string eggType, uint256[] eggData, uint256 tokenID);
    event RandomEggMint(address minter, uint256 tokenID);
    event BurnUpgrade(address burner, uint256 burntID, uint256 upgradedID);

    constructor(address _signer) {
        ALSigner = _signer;
    }

    // USER FUNCTIONS //

    function mintEgg(
        uint256[] calldata eggData,
        string calldata eggType,
        bytes memory signature,
        uint256 phase,
        uint256 quantity
    ) external payable mintControl(quantity) phaseControl(phase) isNotPaused {
        require(signatureValidation(signature, eggType, msg.sender, eggData, phase), "Invalid signature");
        _mint(msg.sender, quantity);
        lastSaleTime = block.timestamp;
        if (quantity == 2) {
            emit RandomEggMint(msg.sender, _totalMinted() - 2);
        }
        if (eggData.length != 0 && _numberMinted(msg.sender) - quantity == 0) {
            emit TypedEggMint(msg.sender, eggType, eggData, _totalMinted() - 1);
        } else {
            emit RandomEggMint(msg.sender, _totalMinted() - 1);
        }
    }

    function burnUpgrade(uint256 burnID, uint256 upgradedID) external isNotPaused {
        require(ownerOf(burnID) == msg.sender, "Burnt token not owned by sender.");
        require(ownerOf(upgradedID) == msg.sender, "Upgraded token not owned by sender.");
        _burn(burnID);
        emit BurnUpgrade(msg.sender, burnID, upgradedID);
    }

    // ACCOUNTING AND VALIDATION FUNCTIONS //

    function signatureValidation(
        bytes memory signature,
        string calldata eggType,
        address _sender,
        uint256[] calldata eggData, //prestige, max level, level, health, strength, growth, happiness
        uint256 phase
    ) internal view returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(eggType, _sender, eggData, phase));
        return ALSigner == data.toEthSignedMessageHash().recover(signature);
    }

    function calculatePrice(uint256 quantity) public view returns (uint256) {
        uint256 timeSinceLastSale = block.timestamp - lastSaleTime;
        uint256 price = currentPrice;
        if (timeSinceLastSale > TIME_INCREMENT) {
            uint256 timeIncrements = timeSinceLastSale / TIME_INCREMENT;
            if (timeIncrements < 6) {
                price -= (INCREMENT * timeIncrements);
            } else {
                price = 0.01 ether;
            }
        }
        if (price < 0.01 ether) {
            return 0.01 ether * quantity;
        }
        return price * quantity;
    }

    // ADMIN FUNCTIONS //

    function adminMint(address _to, uint256 quantity) external onlyOwner {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Max supply reached.");
        _mint(_to, quantity);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setSigner(address _signer) external onlyOwner {
        ALSigner = _signer;
    }

    function setExtension(string memory _ext) external onlyOwner {
        extURI = _ext;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function startSale() external onlyOwner {
        paused = false;
        lastSaleTime = block.timestamp;
    }

    function adjustPrice(uint256 _price) external onlyOwner {
        currentPrice = _price;
    }

    // HOUSEKEEPING //

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), extURI));
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
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

    modifier mintControl(uint256 quantity) {
        require(msg.value >= calculatePrice(quantity), "Insufficient funds.");
        if (currentPrice > calculatePrice(1)) currentPrice = calculatePrice(1);
        require(_numberMinted(msg.sender) + quantity <= 2, "Max eggs per wallet reached.");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Max supply reached.");
        _;
    }

    modifier phaseControl(uint256 phase) {
        if (phase == 2) {
            require(_totalMinted() > PHASE_ONE_SUPPLY, "Phase 1 supply reached.");
        }
        _;
    }

    modifier isNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    receive() external payable {}
}