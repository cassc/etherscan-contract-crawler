// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

contract FiveKMSneaker is ERC721A, Ownable {
    using ECDSA for bytes32;

    enum Status {
        Pending,
        PreSale,
        PublicSale,
        Finished
    }

    Status public status;
    string public baseURI;
    address private _signer;
    uint256 public constant MAX_MINT = 5;
    uint256 public SaleMaxSupply = 5000;
    uint256 public PresalePrice;
    uint256 public PublicPrice;

    mapping(address => bool) public publicMinted;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event SignerChanged(address signer);
    event BaseURIChanged(string newBaseURI);
    event Incubate(address recipient, uint256 amount);

    constructor(
        string memory initBaseURI,
        address signer,
        uint256 initPresalePrice,
        uint256 initPublicPrice
    ) ERC721A("5KM Sneaker", "5KMSneaker")
    {
        baseURI = initBaseURI;
        _signer = signer;
        PresalePrice = initPresalePrice;
        PublicPrice = initPublicPrice;
    }

    function presaleMint(
        uint256 amount,
        string calldata salt,
        bytes calldata sig
    ) external payable {
        require(status == Status.PreSale, "5KM: Presale is not active.");
        require(
            tx.origin == msg.sender,
            "5KM: contract is not allowed to mint."
        );
        require(_verify(_hash(salt, msg.sender), sig), "5KM: invalid sig.");
        require(
            numberMinted(msg.sender) + amount <= MAX_MINT,
            "5KM: max mint amount per wallet exceeded."
        );
        require(
            totalSupply() + amount <= SaleMaxSupply,
            "5KM: max supply exceeded."
        );

        _safeMint(msg.sender, amount);
        refundIfOver(PresalePrice * amount);

        emit Minted(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        require(status == Status.PublicSale, "5KM: Public sale is not active.");
        require(
            tx.origin == msg.sender,
            "5KM: contract is not allowed to mint."
        );
        require(
            !publicMinted[msg.sender],
            "5KM: The wallet has already minted during public sale."
        );
        require(
            numberMinted(msg.sender) + amount <= MAX_MINT,
            "5KM: max mint amount per wallet exceeded."
        );
        require(
            totalSupply() + amount <= SaleMaxSupply,
            "5KM: max supply exceeded."
        );

        _safeMint(msg.sender, amount);
        publicMinted[msg.sender] = true;
        refundIfOver(PublicPrice * amount);

        emit Minted(msg.sender, amount);
    }

    function genesisIncubate(address recipient, uint256 amount) external onlyOwner {
        require(status == Status.Finished, "5KM: sale not finished.");
        require(recipient != address(0), "5KM: zero address.");

        _safeMint(recipient, amount);
        emit Incubate(recipient, amount);
    }

    //for future public supply
    function update(
        uint256 presalePrice,
        uint256 publicPrice,
        uint256 maxSale
    ) external onlyOwner {
        PresalePrice = presalePrice;
        PublicPrice = publicPrice;
        SaleMaxSupply = maxSale;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "5KM: need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "5KM: no balance to withdraw.");
        (bool ok, ) = payable(owner()).call{value: balance}("");

        require(ok, "Transfer failed.");
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(_status);
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
        emit SignerChanged(signer);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _hash(string calldata salt, address _address)
    internal
    view
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(salt, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory sig)
    internal
    view
    returns (bool)
    {
        return (_recover(hash, sig) == _signer);
    }

    function _recover(bytes32 hash, bytes memory sig)
    internal
    pure
    returns (address)
    {
        return hash.toEthSignedMessageHash().recover(sig);
    }

}