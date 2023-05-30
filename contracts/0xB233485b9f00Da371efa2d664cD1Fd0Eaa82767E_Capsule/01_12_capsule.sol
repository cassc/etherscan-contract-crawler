// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Capsule is ERC721A, ReentrancyGuard, Ownable {
    using Address for address;
    string private _tokenUriBase;
    uint256 public MAX_SUPPLY = 350;
    uint256 private PRICE = 0.035 ether;
    uint256 public MAX_CLAIM_SUPPLY = 5;
    uint256 public MAX_MINT_SUPPLY = 5;
    address public burnableAddress;

    event Mint(address user, uint256 quantity);

    enum State {
        Setup,
        PrivateSale,
        PublicSale,
        Finished
    }

    State private _state;
    mapping(uint256 => mapping(address => bool)) private _mintedInBlock;
    IERC721 private drugReceiptToken;
    IERC1155 private greetingCardToken;

    constructor() ERC721A("DRx Kill Team Collection", "DRxKC") {
        _state = State.PrivateSale;
    }

    function setDrugReceiptToken(address _drugReceiptToken) external onlyOwner {
        drugReceiptToken = IERC721(_drugReceiptToken);
    }

    function setGreetingCardToken(address _greetingCardToken) external onlyOwner {
        greetingCardToken = IERC1155(_greetingCardToken);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
    }

    function baseTokenURI() public view virtual returns (string memory) {
        return _tokenUriBase;
    }

    function setTokenURI(string memory tokenUriBase_) public onlyOwner {
        _tokenUriBase = tokenUriBase_;
    }

    function setBurnableAddress(address _burnableAddress) public onlyOwner {
        burnableAddress = _burnableAddress;
    }

    function setMaxSupply(uint256 _max_supply) public onlyOwner {
        MAX_SUPPLY = _max_supply;
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function setMaxClaimSupply(uint256 _max_claim_supply) public onlyOwner {
        MAX_CLAIM_SUPPLY = _max_claim_supply;
    }

    function setMaxMintSupply(uint256 _max_mint_supply) public onlyOwner {
        MAX_MINT_SUPPLY = _max_mint_supply;
    }

    function setStateToSetup() public onlyOwner {
        _state = State.Setup;
    }

    function setStateToPublicSale() public onlyOwner {
        _state = State.PublicSale;
    }

    function setStateToPrivateSale() public onlyOwner {
        _state = State.PrivateSale;
    }

    function setStateToFinished() public onlyOwner {
        _state = State.Finished;
    }

    function mint(uint256 quantity) external payable nonReentrant {
        require(
            quantity <= MAX_MINT_SUPPLY,
            "quantity must be less than or equal to MAX_MINT_SUPPLY."
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "amount should not exceed max supply"
        );
        require(_state == State.PublicSale, "sale is not active");
        require(msg.sender == tx.origin, "mint from contract not allowed");
        require(msg.value >= quantity * PRICE, "ether value sent is incorrect");
        require(
            !Address.isContract(msg.sender),
            "contracts are not allowed to mint"
        );
        require(
            _mintedInBlock[block.number][msg.sender] == false,
            "already minted in this block"
        );
        _mintedInBlock[block.number][msg.sender] = true;

        _safeMint(msg.sender, quantity);
        emit Mint(msg.sender, quantity);
    }

    function mintBatch(address _receiver, uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "amount should not exceed max supply"
        );
        _safeMint(_receiver, quantity);
        emit Mint(_receiver, quantity);
    }

    function airdrop(address[] calldata wallets, uint256[] memory quantity)
        external
        onlyOwner
    {
        unchecked {
            for (uint8 i = 0; i < wallets.length; i++) {
                _safeMint(wallets[i], quantity[i]);
                emit Mint(wallets[i], quantity[i]);
            }
        }
    }

    function claim(uint256 quantity) external payable nonReentrant {
        require(
            quantity <= MAX_CLAIM_SUPPLY,
            "quantity must be less than or equal to MAX_CLAIM_SUPPLY."
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "amount should not exceed max supply"
        );
        require(_state == State.PrivateSale, "sale is not active");
        require(msg.sender == tx.origin, "mint from contract not allowed");
        require(
            !Address.isContract(msg.sender),
            "contracts are not allowed to mint"
        );
        require(
            drugReceiptToken.balanceOf(msg.sender) > 0 || greetingCardToken.balanceOf(msg.sender, 0) > 0,
            "You don't have any drug receipts or greeting cards"
        );
        require(
            _mintedInBlock[block.number][msg.sender] == false,
            "already minted in this block"
        );
        _mintedInBlock[block.number][msg.sender] = true;
        _safeMint(msg.sender, quantity);
        emit Mint(msg.sender, quantity);
    }

    function burn(uint256 tokenId) public {
        require(msg.sender == burnableAddress, "Not allowed to burn");
        super._burn(tokenId);
    }

    function withdrawAll(address recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(recipient).transfer(balance);
    }

    function withdrawAllViaCall(address payable _to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = _to.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
}