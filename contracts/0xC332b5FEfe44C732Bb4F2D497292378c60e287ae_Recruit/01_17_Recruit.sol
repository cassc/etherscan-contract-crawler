// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./StakeIntelBase.sol";

interface IKia is IERC721 {
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}

contract Recruit is StakeIntelBase {
    using Counters for Counters.Counter;
    IKia public kiaContract;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter public _publicSaleCounter;
    uint256 public constant MAX_SUPPLY = 11_000;
    uint256 public constant MINT_PRICE = 0.1 ether;
    string internal baseURI;

    bool public publicSaleStatus;
    bool public claimStatus;

    mapping(uint256 => bool) public kiaTokenOwned;

    constructor(
        address _intelContract,
        address _kiaContract,
        string memory _uri
    ) ERC721("Recruit", "RCR") {
        setIntelContract(_intelContract);
        setKiaContract(_kiaContract);
        setBaseURI(_uri);
    }

    function setKiaContract(address _kiaContract) internal {
        kiaContract = IKia(_kiaContract);
    }

    // views

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "NONEXISTENT_TOKEN");
        return super.tokenURI(tokenId);
    }

    function tokenCheck(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    // public functions

    function mint(address _to, uint256 _amount) public payable nonReentrant {
        require(_amount <= 10, "MAX_MINT_PER_TX_IS_10");
        require(msg.value >= _amount * MINT_PRICE, "NOT_ENOUGH_ETH");
        require(
            _publicSaleCounter.current() + _amount < 1000,
            "PUBLIC_SALE_NOT_STARTED_YET"
        );
        require(_tokenIdCounter.current() + _amount < MAX_SUPPLY, "MINT_OUT");
        require(publicSaleStatus == true, "PUBLIC_SALE_NOT_STARTED");

        for (uint256 index = 0; index < _amount; index++) {
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(_to, tokenId);
            _tokenIdCounter.increment();
            _publicSaleCounter.increment();
        }
    }

    function _claimRecruitForKia(uint256 kiaTokenId) internal {
        require(claimStatus == true, "CLAIM_NOT_STARTED");
        require(
            kiaContract.ownerOf(kiaTokenId) == msg.sender,
            "NOT_YOUR_KOALA"
        );
        require(kiaTokenOwned[kiaTokenId] == false, "ALREADY_CLAIMED");
        safeMint(msg.sender);
        kiaTokenOwned[kiaTokenId] = true;
    }

    function claimRecruitForKia(uint256 kiaTokenId) public nonReentrant {
        _claimRecruitForKia(kiaTokenId);
    }

    function claimRecruitForMultipleKia(uint256[] memory kiaTokenIds)
        public
        nonReentrant
    {
        for (uint256 index = 0; index < kiaTokenIds.length; index++) {
            uint256 kiaTokenId = kiaTokenIds[index];
            _claimRecruitForKia(kiaTokenId);
        }
    }

    function claimRecruitForAllKia() public nonReentrant {
        require(claimStatus == true, "CLAIM_NOT_STARTED");
        uint256[] memory kiaTokenIds = kiaContract.walletOfOwner(msg.sender);
        for (uint256 index = 0; index < kiaTokenIds.length; index++) {
            uint256 kiaTokenId = kiaTokenIds[index];

            if (
                kiaContract.ownerOf(kiaTokenId) == msg.sender &&
                kiaTokenOwned[kiaTokenId] == false
            ) {
                safeMint(msg.sender);
                kiaTokenOwned[kiaTokenId] = true;
            }
        }
    }

    // internals
    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < MAX_SUPPLY, "MINT_OUT");
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
    }

    // owner only functions

    function togglePublicSaleStatus() public onlyOwner {
        publicSaleStatus = !publicSaleStatus;
    }

    function toggleClaimStatus() public onlyOwner {
        claimStatus = !claimStatus;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}