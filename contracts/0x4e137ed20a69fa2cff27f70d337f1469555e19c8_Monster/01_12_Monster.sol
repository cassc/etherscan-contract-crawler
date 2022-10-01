//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract Monster is Ownable, ERC721A, ERC2981, ReentrancyGuard {
    enum Phase {
        disable,
        claim,
        open
    }

    Phase public PHASE = Phase.disable;
    uint96 public immutable ROYALTY_FEE = 750;
    uint256 public immutable MAX_TX_PER_WALLET = 3;
    uint256 public immutable PRICE = 0.003 ether;
    uint256 public immutable TOTAL_SUPPLY = 4444;
    uint256 public immutable TOTAL_CLAIM_SUPPLY = 2222;
    string internal baseURI = "";
    address public immutable SCIENTIST_CONTRACT =
        0xD48A5b0c8Bc760AAfcEd576504fcB884a2cbeb14;

    constructor() ERC721A("Monster", "Monster") {
        _setDefaultRoyalty(owner(), ROYALTY_FEE);
    }

    modifier isUserOwnedScientist() {
        require(
            getUserToken(msg.sender) > 3,
            "You do not have required scientist"
        );

        _;
    }

    modifier isEthAvailable(uint256 quantity) {
        _;
    }

    modifier isMaxTxReached(uint256 quantity) {
        require(
            _numberMinted(msg.sender) + quantity <=
                MAX_TX_PER_WALLET + getAllowedClaim(msg.sender),
            "Exceeded tx limit"
        );
        _;
    }

    modifier isSupplyUnavailable(uint256 quantity) {
        require(totalSupply() + quantity <= TOTAL_SUPPLY, "Max supply reached");
        _;
    }

    modifier isUser() {
        require(tx.origin == msg.sender, "Invalid User");
        _;
    }

    function getTotalSupplyLeft() public view returns (uint256) {
        return TOTAL_SUPPLY - totalSupply();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function devMint(address buyerAddress, uint256 quantity)
        external
        onlyOwner
        nonReentrant
        isUser
        isSupplyUnavailable(quantity)
    {
        _mint(buyerAddress, quantity);
    }

    function claimMint(uint256 quantity)
        public
        payable
        virtual
        nonReentrant
        isUser
        isSupplyUnavailable(quantity)
        isMaxTxReached(quantity)
        isUserOwnedScientist
    {
        require(
            totalSupply() + quantity <= TOTAL_CLAIM_SUPPLY,
            "Max claim supply reached"
        );

        require(
            getAllowedClaim(msg.sender) >= quantity,
            "You have no claim left"
        );

        _mint(msg.sender, quantity);
    }

    function getUserToken(address _wallet) public view returns (uint256) {
        return IERC721(SCIENTIST_CONTRACT).balanceOf(_wallet);
    }

    function mintNow(uint256 quantity)
        public
        payable
        virtual
        nonReentrant
        isUser
        isSupplyUnavailable(quantity)
        isMaxTxReached(quantity)
    {
        require(msg.value >= getSalePrice(quantity), "Insufficient funds");
        require(PHASE == Phase.open, "Not in public mint stage");

        _mint(msg.sender, quantity);
    }

    function getTotalMinted(address addr) public view returns (uint256) {
        return _numberMinted(addr);
    }

    function setBaseURI(string memory newURI) external virtual onlyOwner {
        baseURI = newURI;
    }

    function setPhase(Phase phase) external onlyOwner {
        PHASE = phase;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function salePrice(address sender, uint256 quantity)
        public
        view
        returns (uint256)
    {}

    function getAllowedClaim(address sender) public view returns (uint256) {
        return mod(getUserToken(sender), 3);
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return uint(a) / b;
    }

    function getSalePrice(uint256 quantity) public pure returns (uint256) {
        return PRICE * (quantity);
    }

    function withdrawAll() external onlyOwner nonReentrant isUser {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        require(success, "Transfer failed.");
    }
}