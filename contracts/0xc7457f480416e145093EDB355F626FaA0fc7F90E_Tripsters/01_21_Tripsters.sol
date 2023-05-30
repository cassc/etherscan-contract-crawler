// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "hardhat/console.sol";
import "./ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "@divergencetech/ethier/contracts/thirdparty/opensea/OpenSeaGasFreeListing.sol";
import "./interfaces/IMerkle.sol";

contract Tripsters is
    ERC721Enumerable,
    Pausable,
    Ownable,
    ERC2981ContractWideRoyalties
{
    using Strings for uint256;

    uint256 public maxSupply = 1200;

    uint256 public pioneerPrice = 0.15 ether;
    uint256 public ogPrice = 0.2 ether;
    uint256 public whitelistPrice = 0.25 ether;

    uint256 public pioneerLimit = 2;
    uint256 public ogLimit = 1;
    uint256 public whitelistLimit = 1;

    string public baseURI = "ipfs.io/ipfs/QmcNFhsop7ty9BSDETNQVjw1A3DB67TDrriKHxjCB38SeQ/";
    string public contractURI;

    bool public pioneerLive;
    bool public ogLive;
    bool public whitelistLive;

    string public extension = ".json";

    struct Balance {
        uint256 pioneer;
        uint256 og;
        uint256 whitelist;
    }

    IMerkle public pioneerMerkle;
    IMerkle public ogMerkle;
    IMerkle public whitelistMerkle;

    mapping(address => bool) private admins;
    mapping(address => Balance) public balances;

    constructor(
        address _pioneerMerkle,
        address _ogMerkle,
        address _whitelistMerkle
    ) ERC721("Tripsters", "TRIPSTERS", 0) {
        _setRoyalties(msg.sender, 750);
        pioneerMerkle = IMerkle(_pioneerMerkle);
        ogMerkle = IMerkle(_ogMerkle);
        whitelistMerkle = IMerkle(_whitelistMerkle);
    }

    event PioneerLive(bool live);
    event OgLive(bool live);
    event WhitelistLive(bool live);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is not user");
        _;
    }

    function adminMint(uint256 amount, address to) external adminOrOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds Supply");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, totalSupply() + i);
        }
    }

    function pioneerMint(uint256 _amount, bytes32[] memory proof)
        external
        payable
        whenNotPaused
        callerIsUser
    {
        uint256 currentSupply = totalSupply();
        require(_amount > 0, "Must exceed Zero");
        require(pioneerLive, "Not live");
        require(msg.value >= _amount * pioneerPrice, "Incorrect Price");
        require(
            balances[msg.sender].pioneer + _amount <= pioneerLimit,
            "Exceeds allocated"
        );
        require(pioneerMerkle.isPermitted(msg.sender, proof), "Not verified");
        require(currentSupply + _amount <= maxSupply, "Exceeds Supply");

        balances[msg.sender].pioneer += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, currentSupply + i);
        }
    }

    function ogMint(uint256 _amount, bytes32[] memory proof)
        external
        payable
        whenNotPaused
        callerIsUser
    {
        uint256 currentSupply = totalSupply();
        require(_amount > 0, "Must exceed Zero");
        require(ogLive, "Not live");
        require(msg.value >= _amount * ogPrice, "Incorrect Price");
        require(
            balances[msg.sender].og + _amount <= ogLimit,
            "Exceeds allocated"
        );
        require(ogMerkle.isPermitted(msg.sender, proof), "Not verified");
        require(currentSupply + _amount <= maxSupply, "Exceeds Supply");

        balances[msg.sender].og += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, currentSupply + i);
        }
    }

    function whitelistMint(uint256 _amount, bytes32[] memory proof)
        external
        payable
        whenNotPaused
        callerIsUser
    {
        uint256 currentSupply = totalSupply();
        require(_amount > 0, "Must exceed Zero");
        require(whitelistLive, "Not live");
        require(msg.value >= _amount * whitelistPrice, "Incorrect Price");
        require(
            balances[msg.sender].whitelist + _amount <= whitelistLimit,
            "Exceeds allocated"
        );
        require(whitelistMerkle.isPermitted(msg.sender, proof), "Not verified");
        require(currentSupply + _amount <= maxSupply, "Exceeds Supply");

        balances[msg.sender].whitelist += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, currentSupply + i);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        extension
                    )
                )
                : "";
    }

    function setPaused(bool _paused) external adminOrOwner {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function updateMaxSupply(uint256 _supply) public adminOrOwner {
        maxSupply = _supply;
    }

    function updatePioneerPrice(uint256 _price) external adminOrOwner {
        pioneerPrice = _price;
    }

    function updateOgPrice(uint256 _price) external adminOrOwner {
        ogPrice = _price;
    }

    function updateWhitelistPrice(uint256 _price) external adminOrOwner {
        whitelistPrice = _price;
    }

    function updatePioneerLimit(uint256 _limit) external adminOrOwner {
        pioneerLimit = _limit;
    }

    function updateOgLimit(uint256 _limit) external adminOrOwner {
        ogLimit = _limit;
    }

    function updateWhitelistLimit(uint256 _limit) external adminOrOwner {
        whitelistLimit = _limit;
    }

    function updateBaseURI(string memory _uri) external adminOrOwner {
        baseURI = _uri;
    }

    function updateContractURI(string memory _uri) external adminOrOwner {
        contractURI = _uri;
    }

    function withdrawAll() external onlyOwner {
        withdraw(address(this).balance);
    }

    function withdraw(uint256 _weiAmount) public onlyOwner {
        (bool success, ) = payable(_msgSender()).call{value: _weiAmount}("");
        require(success, "Failed to withdraw");
    }

    function ogStage() public adminOrOwner {
        togglePioneerLive();
        updateMaxSupply(2200);
        toggleOgLive();
    }

    function daStage() public adminOrOwner {
        toggleOgLive();
        updateMaxSupply(6500);
    }

    function whitelistStage() public adminOrOwner {
        updateMaxSupply(10000);
        toggleWhitelistLive();
    }

    function togglePioneerLive() public adminOrOwner {
        bool isLive = !pioneerLive;
        pioneerLive = isLive;
        emit PioneerLive(isLive);
    }

    function toggleOgLive() public adminOrOwner {
        bool isLive = !ogLive;
        ogLive = isLive;
        emit OgLive(isLive);
    }

    function toggleWhitelistLive() public adminOrOwner {
        bool isLive = !whitelistLive;
        whitelistLive = isLive;
        emit WhitelistLive(isLive);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721, IERC721)
        returns (bool)
    {
        return
            super.isApprovedForAll(owner, operator) ||
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator) ||
            admins[msg.sender];
    }

    function setExtension(string memory _extension) external adminOrOwner {
        extension = _extension;
    }

    function setAdminPermissions(address _account, bool _enable)
        external
        adminOrOwner
    {
        admins[_account] = _enable;
    }

    modifier adminOrOwner() {
        require(msg.sender == owner() || admins[msg.sender], "Unauthorized");
        _;
    }

    function setRoyalties(address _recipient, uint256 _value)
        external
        adminOrOwner
    {
        _setRoyalties(_recipient, _value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Base, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setPioneerMerkle(IMerkle _merkle) external adminOrOwner {
        pioneerMerkle = IMerkle(_merkle);
    }

    function setOgMerkle(IMerkle _merkle) external adminOrOwner {
        ogMerkle = IMerkle(_merkle);
    }

    function setWhitelistMerkle(IMerkle _merkle) external adminOrOwner {
        whitelistMerkle = IMerkle(_merkle);
    }
}