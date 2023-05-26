// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TurkeysMegaverse is ERC721A, Ownable {

    using ECDSA for bytes32;

    uint constant public MAX_SUPPLY = 7777;

    string public baseURI = "https://storage.googleapis.com/turkeysmegaverse/meta/";

    uint public price = 0.01 ether;

    uint public reservedSupply = 100;
    uint public defaultFreeMints = 1;
    uint public maxMintsPerWallet = 50;
    uint public mintingStartTimestamp = 1642806000;

    mapping(address => uint) public mintedNFTs;

    address public authorizedSigner = 0x4637A97Ab486A66A4D8F154975863453Bd8e3065;

    mapping(address => bool) public projectProxy;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    constructor() ERC721A("Turkeys Megaverse", "TURKEY", 15) {
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function toggleProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function configure(
        uint _price,
        uint _reservedSupply,
        uint _defaultFreeMints,
        uint _maxMintsPerWallet,
        uint _mintingStartTimestamp,
        address _authorizedSigner
    ) external onlyOwner {
        price = _price;
        reservedSupply = _reservedSupply;
        defaultFreeMints = _defaultFreeMints;
        maxMintsPerWallet = _maxMintsPerWallet;
        mintingStartTimestamp = _mintingStartTimestamp;
        authorizedSigner = _authorizedSigner;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function hashTransaction(address minter, uint oracleFreeMints) private pure returns (bytes32) {
        bytes32 argsHash = keccak256(abi.encodePacked(minter, oracleFreeMints));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", argsHash));
    }

    function recoverSignerAddress(address minter, uint oracleFreeMints, bytes memory signature) private pure returns (address) {
        bytes32 hash = hashTransaction(minter, oracleFreeMints);
        return hash.recover(signature);
    }

    function mintPrice(uint amount, uint oracleFreeMints, bytes memory signature) public view returns (uint) {
        uint freeMints = defaultFreeMints;
        if (signature.length != 0 && recoverSignerAddress(_msgSender(), oracleFreeMints, signature) == authorizedSigner) {
            freeMints = oracleFreeMints;
        }

        uint minted = mintedNFTs[_msgSender()];
        uint remainingFreeMints = freeMints > minted ? freeMints - minted : 0;

        return remainingFreeMints >= amount ? 0 : (amount - remainingFreeMints) * price;
    }

    function mint(uint amount, uint oracleFreeMints, bytes memory signature) public payable {
        require(tx.origin == _msgSender(), "The caller is another contract");
        require(block.timestamp >= mintingStartTimestamp, "Minting is not available");
        require(totalSupply() + reservedSupply + amount <= MAX_SUPPLY, "Tokens supply reached limit");

        require(mintedNFTs[msg.sender] + amount <= maxMintsPerWallet, "maxMintsPerWallet constraint violation");
        require(mintPrice(amount, oracleFreeMints, signature) == msg.value, "Wrong ethers value");

        mintedNFTs[msg.sender] += amount;
        _safeMint(_msgSender(), amount);
    }

    function mint(uint amount) public payable {
        mint(amount, defaultFreeMints, bytes(""));
    }
    //endregion

    function airdrop(address[] memory addresses, uint[] memory amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            require(totalSupply() + amounts[i] <= MAX_SUPPLY, "Tokens supply reached limit");
            _safeMint(_msgSender(), amounts[i]);
        }
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }


    receive() external payable {

    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(0x993F42634C113E478244452a453505a26fbB121b).transfer(balance * 7 / 100);
        payable(0xE24E767B73DC585999833Fb02debd8ACC99daF69).transfer(balance * 7 / 100);
        payable(0x612DBBe0f90373ec00cabaEED679122AF9C559BE).transfer(balance * 6 / 100);
        payable(0x5cb648aCf319381081e38137500Fb002bbEAbEFf).transfer(balance * 5 / 100);
        payable(0x0bcD8F69207899F220b53A71317f6731E9140144).transfer(balance * 75 / 100);
    }

}


contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}