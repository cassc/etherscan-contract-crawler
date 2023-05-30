// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

pragma solidity ^0.8.4;

contract TheLuckyOriginals is  Ownable, ERC721AQueryable {
    using ECDSA for bytes32;
    using Strings for uint256;

    event SaleUpdate(uint32 indexed saleId);

    struct saleParams {
        string name;
        uint64 startTime;
        uint64 endTime;
        uint64 supply;
        uint32 claimable;
        bool requireSignature;
    }
    mapping(uint32 => saleParams) public sales;
    mapping(uint32 => uint256) public mintsPerSale;
    mapping(uint32 => mapping(address => uint256)) public mintsPerWallet;
    uint256 public maxSupply = 777;
    bool  private revealState = false;
    string public baseURI;

    address private deployer;

    constructor() ERC721A("TheLuckyOriginals", "TLO") {
        deployer = msg.sender;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function configureSale(
        uint32 _id,
        string memory _name,
        uint64 _startTime,
        uint64 _endTime,
        uint64 _supply,
        uint32 _claimable,
        bool _requireSignature
    ) external onlyOwner {
        require(_startTime > 0 && _endTime > 0 && _endTime > _startTime, "Time range is invalid.");
        sales[_id] = saleParams(_name, _startTime, _endTime, _supply, _claimable, _requireSignature);
        emit SaleUpdate(_id);
    }

    function saleMint(
        uint32 _saleId,
        uint256 numberOfTokens,
        uint256 _alloc,
        bytes calldata _signature
    ) external payable callerIsUser {
        saleParams memory _sale = sales[_saleId];
        require(_sale.startTime > 0 && _sale.endTime > 0, "Sale doesn't exists");
        require(block.timestamp > _sale.startTime && block.timestamp < _sale.endTime,  "Sale is not active");
        uint256 alloc = _sale.requireSignature ? _alloc : uint256(_sale.claimable);

        if (_sale.requireSignature) {
            bytes32 _messageHash = hashMessage(abi.encode(_sale.name, address(this), _msgSender(), _alloc));
            require(verifyAddressSigner(_messageHash, _signature), "Invalid signature.");
        }
        require(numberOfTokens > 0, "Wrong amount requested");
        require(block.timestamp > _sale.startTime && block.timestamp < _sale.endTime, "Sale is not active.");
        require(totalSupply() + numberOfTokens <= maxSupply, "Not enough tokens left.");
        require(mintsPerSale[_saleId] + numberOfTokens <= _sale.supply, "Not enough supply.");
        require(mintsPerWallet[_saleId][_msgSender()] + numberOfTokens <= alloc, "Allocation exceeded.");
        mintsPerWallet[_saleId][_msgSender()] += numberOfTokens;
        mintsPerSale[_saleId] += numberOfTokens;
        mintInternal(_msgSender(), numberOfTokens);
    }

    function mintInternal(address wallet, uint amount) internal {
        require(totalSupply() + amount <= maxSupply, "Not enough tokens left");
        _safeMint(wallet, amount);
    }

    function airdropToWallet(address walletAddress, uint amount) external onlyOwner{
        mintInternal(walletAddress, amount);
    }

    function changeStateReveal() public onlyOwner returns(bool) {
        revealState = !revealState;
        return revealState;
    }

    function setBaseURI(string calldata _newBaseUri) external onlyOwner {
        baseURI = _newBaseUri;
    }

    function changeDeployer(address _newDeployer) public onlyOwner returns(address) {
        deployer = _newDeployer;
        return deployer;
    }

    function verifyAddressSigner(bytes32 _messageHash, bytes memory _signature) private view returns (bool) {
        return deployer == _messageHash.toEthSignedMessageHash().recover(_signature);
    }

    function hashMessage(bytes memory _msg) private pure returns (bytes32) {
        return keccak256(_msg);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        if (!revealState) {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI)) : "";
        }

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}