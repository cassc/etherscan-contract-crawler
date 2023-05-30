// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

interface ArtifactsInterface {
    function burnAsBurner(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external;

    function balanceOf(address account, uint256 tokenID)
        external
        view
        returns (uint256 balance);
}

interface SSSInterface {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract Repus is ERC721, Ownable {
    uint256 public totalSupply = 0;
    address public proxyRegistryAddress =
        0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address private _manager = 0xf5383b4e0d3EDDA3B6c091e51AbE58F882c98ce3;
    uint256 private constant ARTIFACT_ID = 1;

    string public baseUri = "";
    string public endingUri = ".json";
    string private revealedBaseURI;
    bool public saleIsActive = true;
    ArtifactsInterface artifactsContract;
    SSSInterface sssContract;

    constructor(address artifactsAddress, address sssAddress)
        ERC721("The Repus", "REPUS")
    {
        artifactsContract = ArtifactsInterface(artifactsAddress);
        sssContract = SSSInterface(sssAddress);
    }

    receive() external payable {}

    modifier onlyOwnerOrManager() {
        require(
            owner() == _msgSender() || _manager == _msgSender(),
            "Caller not the owner or manager"
        );
        _;
    }

    function setManager(address manager) external onlyOwnerOrManager {
        _manager = manager;
    }

    function setArtifactsContract(address _artifactsContract)
        external
        onlyOwnerOrManager
    {
        artifactsContract = ArtifactsInterface(_artifactsContract);
    }

    function setSSSContract(address _sssContract) external onlyOwnerOrManager {
        sssContract = SSSInterface(_sssContract);
    }

    function withdraw() public onlyOwnerOrManager {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mint(uint256 amount) external {
        require(
            artifactsContract.balanceOf(msg.sender, ARTIFACT_ID) >= amount,
            "not enough artifacts"
        );
        require(sssContract.balanceOf(msg.sender) > 0, "not an sss owner");
        artifactsContract.burnAsBurner(msg.sender, ARTIFACT_ID, amount);
        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, totalSupply);
            totalSupply = totalSupply + 1;
        }
    }

    function setBaseURI(string calldata _URI) external onlyOwnerOrManager {
        baseUri = _URI;
    }

    function setRevealedBaseURI(string calldata URI)
        external
        onlyOwnerOrManager
    {
        revealedBaseURI = URI;
    }

    function setEndingURI(string calldata _URI) external onlyOwnerOrManager {
        endingUri = _URI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            bytes(revealedBaseURI).length > 0
                ? string(abi.encodePacked(super.tokenURI(_tokenId), endingUri))
                : baseUri;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return revealedBaseURI;
    }

    function setProxyRegistry(address preg) external onlyOwnerOrManager {
        proxyRegistryAddress = preg;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}