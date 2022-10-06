pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MhrsNft is ERC721A, Ownable {
    uint256 public maxSupply = 625;

    bool public pause = true;

    uint256 public price;

    uint256 public revealed = 0;

    string baseURI =
        "https://six-data-chain-backend-backend-api-sixnet-gateway-3hi29er0.an.gateway.dev/api/nft/metadata/teamMHRSNFT/";
    string hiddenURI =
        "ipfs://bafkreifgyjdxjsmjfnciwenfoi7rketbm4n7mqmzymg5cp22ysuvk6dcje/";
    string tokenURIextension = "";

    address[] public reserved;
    uint256 public reserveAmount;

    constructor(uint256 reserve_, uint256 _price)
        ERC721A("Team Mahorasop", "TeamMHRS")
    {
        reserveAmount = reserve_;
        _mint(address(this), reserve_);
        price = _price;
    }

    function airdrop(address[] memory _addresses)
        public
        payable
        notReachMaxSupply(_addresses.length)
    {
        require(msg.value == price * _addresses.length, "Price invalid");

        for (uint256 i = 0; i < _addresses.length; i++) {
            mintTo(_addresses[i]);
        }
    }

    function mintTo(address _to) internal notPause notReachMaxSupply(1) {
        _mint(_to, 1);
    }

    function mintReserve() external payable onlyOwner {
        _mintReserve();
    }

    function _mintReserve() internal {
        for (uint256 i = 0; i < reserveAmount; i++) {
            if (ownerOf(i) == address(this) && (i < reserved.length)) {
                this.approve(reserved[i], i);
                this.transferFrom(address(this), reserved[i], i);
            }
        }
    }

    function setReservedAddresses(address[] memory addressList)
        external
        onlyOwner
    {
        reserved = addressList;
    }

    function isReserve(address _address) external view returns (bool) {
        for (uint256 i = 0; i < reserved.length; i++) {
            if (reserved[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPause(bool _pause) external onlyOwner {
        pause = _pause;
    }

    function withdrawETH() external onlyOwner {
        bool sent = payable(address(msg.sender)).send(address(this).balance);
        require(sent, "Withdraw error");
    }

    function reveal() external onlyOwner {
        revealed = totalSupply();
    }

    modifier notPause() {
        require(pause == false, "Smart contract is paused");
        _;
    }

    modifier notReachMaxSupply(uint256 quantity) {
        require(totalSupply() + quantity <= maxSupply, "Reach max supply");
        _;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _hiddenURI() internal view virtual returns (string memory) {
        return hiddenURI;
    }

    function setHiddenURI(string memory hiddenURI_) external onlyOwner {
        hiddenURI = hiddenURI_;
    }

    function setExtension(string memory extension_) external onlyOwner {
        tokenURIextension = extension_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (revealed <= 0) {
            return _hiddenURI();
        }

        if (tokenId >= revealed) {
            return _hiddenURI();
        }

        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        _toString(tokenId),
                        tokenURIextension
                    )
                )
                : "";
    }
}