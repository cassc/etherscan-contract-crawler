// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./DefaultOperatorFilterer.sol";
import "./INemsPrice.sol";

contract NemesisLands is
    Ownable,
    ERC721Enumerable,
    DefaultOperatorFilterer,
    Pausable,
    INemsPrice
{
    //impostare la base uri (con lo slsh finale) all'api del bridge
    //di lettura dei metadati su polygon
    uint256 public startDate;

    constructor(
        uint256 _startDate,
        address _USDCAddress, // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        address _USDTAddress, // 0xdac17f958d2ee523a2206206994597c13d831ec7
        address _NEMSAddress // 0xb435A47eCea7F5366b2520e45B9beD7E01d2FFAe
    ) ERC721("The Nemesis Lands", "LN") {
        setStartDate(_startDate);
        USDC = IERC20(_USDCAddress);
        USDT = IERC20(_USDTAddress);
        NEMS = IERC20(_NEMSAddress);
    }

    IERC20 USDT;
    IERC20 USDC;
    IERC20 NEMS;

    using Strings for uint256;

    string public baseURI = "https://api.thenemesis.io/v5/lands/assets/1/";
    string public contractURI = "https://api.thenemesis.io/v5/lands/collection/1";
    uint256 public PublicUSDPrice = 280; //costo al pubblico
    uint256 public WLUSDPrice = 140; //costo per gli utenti whitelist
    uint256 public _NemsUSDPrice = 1000000000000000000; //prezzo di 1 NEMS in USD 18 Decimali;
    uint256 public maxSupply = 11520; //numero di token della collection
    bool public isPublicOpen;

    error FunctionInvalidAtThisStage();

    mapping(uint256 => address) public _reservedLands;

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

    modifier atMintStage(MintStage mintStage_) {
        MintStage mintStage = getMintStage();

        require(mintStage == mintStage_, "This function is not allowed now");

        if (mintStage != mintStage_) revert FunctionInvalidAtThisStage();
        _;
    }

    //mette in pausa il contratto
    function pause() public onlyOwner {
        _pause();
    }

    //riattiva il contratto
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
                _reservedLands[tokenid] == msg.sender,
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
            //solo pagamento in NEMS
            return PublicUSDPrice * _NemsUSDPrice;
        } else if (stage == MintStage.ReservedLands) {
            //pagamento in USDC/USDT
            return WLUSDPrice * 1e18;
        }
    }

    function getNextFreeLand() internal view returns (uint256 _tokenID) {
        for (uint256 i = 1; i <= maxSupply; i++) {
            if (!_exists(i)) {
                return i;
            }
        }
        return 0;
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
        uint256 supply = totalSupply();
        require(
            (supply + landnum.length) <= maxSupply,
            "max NFT limit exceeded"
        );

        for (uint256 i = 0; i < landnum.length; i++) {
            uint256 _landnum = landnum[i];
            address wallet = wallets[i];
            // require(
            //     _reservedLands[_landnum] == address(0),
            //     "Land already reserved!"
            // );
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

    function setStartDate(uint256 date) public onlyOwner {
        startDate = date;
    }

    function addLandReservation(
        uint256[] memory landnum,
        address[] calldata reserve
    ) external whenNotPaused onlyOwner {
        require(
            landnum.length == reserve.length,
            "The array must have the same length"
        );

        for (uint256 i = 0; i < landnum.length; i++) {
            uint256 _landnum = landnum[i];
            address wallet = reserve[i];

            require(
                _reservedLands[_landnum] == address(0),
                "Land already reserved!"
            );
            require(!_exists(_landnum), "Land already minted!");
            _reservedLands[_landnum] = wallet;
        }
    }

    function removeLandReservation(uint256[] memory landnum)
        external
        whenNotPaused
        onlyOwner
    {
        require(landnum.length > 0, "No landNums specified");

        for (uint256 i = 0; i < landnum.length; i++) {
            _reservedLands[landnum[i]] = address(0);
        }
    }

    //trasferisce gli eth dal contratto al wallet dell'owner
    function withdraw() external onlyOwner {
        //(bool success,)=payable(owner()).call{value:address(this).balance}("");

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
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function NemsUSDPrice() external view returns (uint256) {
        return _NemsUSDPrice;
    }
}