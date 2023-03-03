// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import "./NemesisLands.sol";
import "./IERC20.sol";
import "./INemsPrice.sol";

contract NemesisLands_V0 is
    Initializable,
    OwnableUpgradeable,
    ERC721Upgradeable,
    DefaultOperatorFiltererUpgradeable,
    PausableUpgradeable,
    INemsPrice
{
    NemesisLands public res;

    using Strings for uint256;

    string public baseURI;
    string public contractURI;
    uint256 public PublicUSDPrice;
    uint256 public WLUSDPrice;
    uint256 public _NemsUSDPrice;
    uint256 public maxSupply;
    bool public isPublicOpen;

    function initialize(
        address _USDCAddress, 
        address _USDTAddress, 
        address _NEMSAddress, 
        address _NemesisLands
    ) public initializer {
        USDC = IERC20(_USDCAddress);
        USDT = IERC20(_USDTAddress);
        NEMS = IERC20(_NEMSAddress);
        res = NemesisLands(_NemesisLands);

        baseURI = "https://api.thenemesis.io/v5/lands/assets/1/";
        contractURI = "https://api.thenemesis.io/v5/lands/collection/1";
        PublicUSDPrice = 280; 
        WLUSDPrice = 140; 
        _NemsUSDPrice = 1000000000000000000; 
        maxSupply = 11520; 
        isPublicOpen = false;

        __Ownable_init();
    }

    IERC20 USDT;
    IERC20 USDC;
    IERC20 NEMS;

    error FunctionInvalidAtThisStage();

    enum MintStage {
        NotOpen,
        ReservedLands,
        Public
    }

    function uri(uint256 _tokenID) public view returns (string memory) {
        return tokenURI(_tokenID);
    }

    function _contractURI() public view returns (string memory) {
        return contractURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function readReservedLands(uint256 landId) public view returns (address) {
        return res._reservedLands(landId);
    }

    modifier atMintStage(MintStage mintStage_) {
        MintStage mintStage = getMintStage();

        require(mintStage == mintStage_, "This function is not allowed now");

        if (mintStage != mintStage_) revert FunctionInvalidAtThisStage();
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getMintStage() public view returns (MintStage) {
        return isPublicOpen ? MintStage.Public : MintStage.ReservedLands;
    }

    function mintReservedLands(uint256[] memory _tokenIds, bool _usdt)
        public
        whenNotPaused
        atMintStage(MintStage.ReservedLands)
    {
        uint256 numNft = _tokenIds.length;

        require(numNft > 0, "need to mint at least 1 NFT");

        for (uint256 i = 0; i < numNft; i++) {
            uint256 tokenid = _tokenIds[i];
            require(
                res._reservedLands(tokenid) == msg.sender,
                "You have not reserved all the requested lands"
            );
        }

        for (uint256 i = 0; i < numNft; i++) {
            _safeMint(msg.sender, _tokenIds[i]);
        }

        if (_usdt) {
            _checkAllowanceAndTransferERC20(USDT, numNft);
        } else {
            //USDC
            _checkAllowanceAndTransferERC20(USDC, numNft);
        }
    }

    function mintPublicLands(uint256[] memory _tokenIds)
        public
        whenNotPaused
        atMintStage(MintStage.Public)
    {
        uint256 numNft = _tokenIds.length;

        require(numNft > 0, "need to mint at least 1 NFT");

        for (uint256 i = 0; i < numNft; i++) {
            uint256 tokenid = _tokenIds[i];
            bool tokenExist = _exists(tokenid);
            require(!tokenExist, "Land already minted");
        }

        for (uint256 i = 0; i < numNft; i++) {
            _safeMint(msg.sender, _tokenIds[i]);
        }

        _checkAllowanceAndTransferERC20(NEMS, numNft);
    }

    function _checkAllowanceAndTransferERC20(IERC20 token, uint256 numnft)
        internal
    {
        uint256 balancetoken = token.balanceOf(msg.sender);
        uint256 amount = getLandPrice();
        uint256 totalprice = amount * numnft;
        require(
            balancetoken >= totalprice,
            "You don't have enough funds to process the payment."
        );
        token.transferFrom(msg.sender, address(this), totalprice);
    }

    function getLandPrice() public view returns (uint256 _price) {
        MintStage stage = getMintStage();

        if (stage == MintStage.Public) {
            return PublicUSDPrice * _NemsUSDPrice;
        } else if (stage == MintStage.ReservedLands) {
            return WLUSDPrice * 10**6;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    function airdrop(uint256[] memory landnum, address[] calldata wallets)
        external
        whenNotPaused
        onlyOwner
    {
        require(
            landnum.length == wallets.length,
            "The array must have the same length"
        );
        require(landnum.length > 0, "Mint amount should be greater than 0");

        for (uint256 i = 0; i < landnum.length; i++) {
            uint256 _landnum = landnum[i];
            address wallet = wallets[i];
            require(!_exists(_landnum), "Land already minted!");
            _safeMint(wallet, _landnum);
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractURI(string memory _newContractURI) public onlyOwner {
        contractURI = _newContractURI;
    }

    function setPublicUSDPrice(uint256 _PublicUSDPrice) public onlyOwner {
        PublicUSDPrice = _PublicUSDPrice;
    }

    function setWLUSDPrice(uint256 _WLUSDPrice) public onlyOwner {
        WLUSDPrice = _WLUSDPrice;
    }

    function setNemsUSDPrice(uint256 USDPrice) public onlyOwner {
        _NemsUSDPrice = USDPrice;
    }

    function setmaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setisPublicOpen(bool _isPublicOpen) public onlyOwner {
        isPublicOpen = _isPublicOpen;
    }

    function withdraw() external onlyOwner {

        uint256 balanceUsdt = USDT.balanceOf(address(this));
        if (balanceUsdt > 0) {
            USDT.transfer(owner(), balanceUsdt);
        }

        uint256 balanceUsdc = USDC.balanceOf(address(this));
        if (balanceUsdc > 0) {
            USDC.transfer(owner(), balanceUsdc);
        }

        uint256 balanceNems = NEMS.balanceOf(address(this));
        if (balanceNems > 0) {
            NEMS.transfer(owner(), balanceNems);
        }
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function NemsUSDPrice() external view returns (uint256) {
        return _NemsUSDPrice;
    }
}