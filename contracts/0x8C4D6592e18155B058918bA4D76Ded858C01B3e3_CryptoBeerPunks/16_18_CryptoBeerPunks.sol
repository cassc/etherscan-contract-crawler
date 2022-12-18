// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

contract CryptoBeerPunks is ERC721A, ERC2981, Ownable, Pausable {
    using Strings for uint256;

    uint256 public preCost = 0.04 ether;
    uint256 public publicCost = 0.05 ether;
    bool public mintable = true;

    enum SaleState {
        PRE_SALE,
        PUBLIC_SALE,
        CLOSE
    }
    SaleState public saleState;

    address public royaltyAddress;
    uint96 public royaltyFee = 1000;
    address private constant DEFAULT_ROYALITY_ADDRESS =
        0x224Bfe2a58f76D112F3359Ae2f9d4454c01bee4c;

    string private baseURI = "";
    bool public revealed = false;
    string public notRevealedUri;
    string private constant BASE_EXTENSION = ".json";

    uint256 public constant MAX_SALE_SUPPLY = 2701;
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 private constant PUBLIC_MAX_PER_TX = 10;

    mapping(address => uint256) private whiteLists;
    mapping(address => uint256) private onlyBlalWhiteLists;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initNotRevealedUri
    ) ERC721A(_name, _symbol) {
        _setDefaultRoyalty(DEFAULT_ROYALITY_ADDRESS, royaltyFee);
        setNotRevealedURI(_initNotRevealedUri);
        setSaleState(SaleState.CLOSE);
    }

    modifier whenMintable() {
        require(mintable == true, "Mintable: paused");
        _;
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(ERC721A.tokenURI(_tokenId), BASE_EXTENSION)
                )
                : "";
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function isRevealed() public view returns (bool) {
        return revealed;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function publicMint(
        uint256 _mintAmount
    ) public payable whenNotPaused whenMintable callerIsUser {
        uint256 cost = publicCost * _mintAmount;
        mintCheck(_mintAmount, cost);
        require(
            saleState == SaleState.PUBLIC_SALE,
            "Public sale is not active."
        );
        require(_mintAmount <= PUBLIC_MAX_PER_TX, "Mint amount over");

        _mint(msg.sender, _mintAmount);
    }

    function preMint(
        uint256 _mintAmount
    ) public payable whenMintable whenNotPaused {
        uint256 cost = preCost * _mintAmount;
        mintCheck(_mintAmount, cost);
        require(saleState == SaleState.PRE_SALE, "Presale is not active.");
        require(
            onlyBlalWhiteLists[msg.sender] > 0 || whiteLists[msg.sender] > 0,
            "You don't have role."
        );

        if (onlyBlalWhiteLists[msg.sender] > 0) {
            require(
                onlyBlalWhiteLists[msg.sender] >= _mintAmount,
                "Over mintable amount."
            );

            _mint(msg.sender, _mintAmount);
            onlyBlalWhiteLists[msg.sender] -= _mintAmount;
        } else if (whiteLists[msg.sender] > 0) {
            require(
                whiteLists[msg.sender] >= _mintAmount,
                "Over mintable amount."
            );

            _mint(msg.sender, _mintAmount);
            whiteLists[msg.sender] -= _mintAmount;
        }
    }

    function mintCheck(uint256 _mintAmount, uint256 cost) private view {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(
            totalSupply() + _mintAmount <= MAX_SALE_SUPPLY,
            "MAXSALESUPPLY over"
        );
        require(msg.value >= cost, "Not enough funds");
    }

    function setSecondPreSaleMintAmounts(
        address[] calldata _addresses
    ) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteLists[_addresses[i]] += 2;
        }
    }

    function setSaleState(SaleState _saleState) public onlyOwner {
        saleState = _saleState;
    }

    function ownerMint(address _address, uint256 count) public onlyOwner {
        require(totalSupply() + count < MAX_SUPPLY, "MAXSUPPLY over");
        _mint(_address, count);
    }

    function setPreCost(uint256 _preCost) public onlyOwner {
        preCost = _preCost;
    }

    function setPublicCost(uint256 _publicCost) public onlyOwner {
        publicCost = _publicCost;
    }

    function setMintable(bool _state) public onlyOwner {
        mintable = _state;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setWhiteLists(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteLists[_addresses[i]] = _amounts[i];
        }
    }

    function setOnlyBlalWhiteLists(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
            onlyBlalWhiteLists[_addresses[i]] = _amounts[i];
        }
    }

    function getMintableAmount(address _address) public view returns (uint256) {
        return whiteLists[_address];
    }

    function getOnlyBlalMintableAmount(
        address _address
    ) public view returns (uint256) {
        return onlyBlalWhiteLists[_address];
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}