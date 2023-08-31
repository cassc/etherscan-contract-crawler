// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract BTGG is Ownable, ERC721A, PaymentSplitter {
    using Strings for uint256;

    enum Step {
        Before,
        PublicSale,
        SoldOut,
        Reveal
    }

    string public baseURI;

    Step public sellingStep;

    uint256 public MAX_SUPPLY = 6666;
    uint256 public MAX_PER_WALLET = 3;

    uint256 public publicSalePrice = 0 ether;

    mapping(address => uint256) public amountNFTsperWallet;

    uint256 private teamLength;

    constructor(
        address[] memory _team,
        uint256[] memory _teamShares,
        string memory _baseURI
    ) ERC721A("BigTiddyGothGirls", "BTGG") PaymentSplitter(_team, _teamShares) {
        baseURI = _baseURI;
        teamLength = _team.length;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function publicSaleMint(address _account, uint256 _quantity)
        external
        payable
        callerIsUser
    {
        uint256 price = publicSalePrice;
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(
            amountNFTsperWallet[msg.sender] + _quantity <= MAX_PER_WALLET,
            "You can only get 3 NFTs"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWallet[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function gift(address _to, uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max Supply");
        _safeMint(_to, _quantity);
    }

    function lowerSupply(uint256 _MAX_SUPPLY) external onlyOwner {
        require(_MAX_SUPPLY < MAX_SUPPLY, "Cannot increase supply!");
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function setMaxPerWallet(uint256 _MAX_PER_WALLET) external onlyOwner {
        MAX_PER_WALLET = _MAX_PER_WALLET;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function currentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    function setStep(uint256 _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    //ReleaseALL
    function releaseAll() external onlyOwner {
        for (uint256 i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    receive() external payable override {
        revert("Only if you mint");
    }
}