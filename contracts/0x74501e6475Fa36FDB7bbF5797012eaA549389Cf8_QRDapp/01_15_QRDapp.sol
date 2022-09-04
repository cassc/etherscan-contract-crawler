// SPDX-License-Identifier: MIT

        //////////////                    //////////////
        //          //                    //          //
        //  //////  //                    //  //////  //
        //  //////  //                    //  //////  //
        //  //////  //                    //  //////  //
        //          //                    //          //
        //////////////                    //////////////

        ////
        ////               WELCOME TO
        ////                QR DAPP
        ////             SMART CONTRACT
        ////

        //////////////            AUTHOR: YomYom
        //          //
        //  //////  //
        //  //////  //
        //  //////  //
        //          //
        //////////////



pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';


contract QRDapp is
    ERC721,
    ERC2981,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public uriPrefix;
    string public uriInfix;
    string public uriSuffix;
    string public uriCID;
    string public contractURI;

    uint256 public cost;
    uint256 public maxSupply;

    bool public paused;

    constructor (
        string memory _uriPrefix,
        string memory _uriInfix,
        string memory _uriSuffix,
        string memory _uriCID,
        string memory _contractURI,
        uint256 _cost,
        uint256 _maxSupply,
        address _royalty,
        uint96 _royaltyFee
    ) ERC721 ("QRDapp", "QRD") {
        uriPrefix = _uriPrefix;
        uriInfix = _uriInfix;
        uriSuffix = _uriSuffix;
        uriCID = _uriCID;
        contractURI = _contractURI;
        cost = _cost;
        maxSupply = _maxSupply;
        paused = true;
        _setDefaultRoyalty(_royalty, _royaltyFee);
    }

    modifier mintCompliance() {
        require(totalSupply() < maxSupply, "Max supply exceeded");
        _;
    }

    modifier mintPriceCompliance() {
        require(msg.value >= cost, "Insufficient funds");
        _;
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _tokenIds.current();
    }

    function mint()
        external
        payable
        mintCompliance
        mintPriceCompliance
        nonReentrant
    {
        require(!paused, "The contract is paused");
        _mint(msg.sender);
    }

    function mintForAddress(address _receiver)
        external
        mintCompliance
        onlyOwner
        nonReentrant
    {
        _mint(_receiver);
    }

    function _mint(address _receiver) internal {
        _tokenIds.increment();
        _safeMint(_receiver, totalSupply());
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory tokenId = Strings.toString(_tokenId);
        return bytes(uriCID).length > 0
            ? string(abi.encodePacked(uriPrefix, uriCID, uriInfix, tokenId, uriSuffix))
            : "";
    }

    function setRoyaltyInfo(address _receiver, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriInfix(string memory _uriInfix) external onlyOwner {
        uriInfix = _uriInfix;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setUriCID(string memory _uriCID) external onlyOwner {
        uriCID = _uriCID;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns(bool)
    {
        return super.supportsInterface(interfaceId);
    }
}