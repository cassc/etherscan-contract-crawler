// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MutantTurkeysMegaverse is ERC721A, Ownable {

    using ECDSA for bytes32;

    uint constant public MAX_SUPPLY = 6666;
    address constant public osProxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    string public baseURI = "https://storage.googleapis.com/mutantturkeysmegaverse/meta/";

    uint public price = 0.03 ether;

    uint public reservedSupply = 80;
    uint public maxMintsPerWallet = 70;
    uint public mintingStartTimestamp = 1650664800;

    mapping(address => uint) public mintedNFTs;

    address public authorizedSigner = 0x663d8E63A2Ae8f34a5C5be9A5E1662310287912C;
    bool osAutoApproveEnabled = true;

    constructor() ERC721A("Mutant Turkeys Megaverse", "MUTANT TURKEY", 60) {
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function configure(
        uint _price,
        uint _reservedSupply,
        uint _maxMintsPerWallet,
        uint _mintingStartTimestamp,
        bool _osAutoApproveEnabled,
        address _authorizedSigner
    ) external onlyOwner {
        price = _price;
        reservedSupply = _reservedSupply;
        maxMintsPerWallet = _maxMintsPerWallet;
        mintingStartTimestamp = _mintingStartTimestamp;
        osAutoApproveEnabled = _osAutoApproveEnabled;
        authorizedSigner = _authorizedSigner;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function hashTransaction(address minter, uint oracleFreeMints) internal pure returns (bytes32) {
        bytes32 argsHash = keccak256(abi.encodePacked(minter, oracleFreeMints));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", argsHash));
    }

    function recoverSignerAddress(address minter, uint oracleFreeMints, bytes memory signature) internal pure returns (address) {
        bytes32 hash = hashTransaction(minter, oracleFreeMints);
        return hash.recover(signature);
    }

    function findRemainingFreeMints(uint freeMints) internal view returns (uint) {
        uint minted = mintedNFTs[_msgSender()];
        return freeMints > minted ? freeMints - minted : 0;
    }

    function mintPrice(uint amount, uint freeMints) public view returns (uint) {
        uint remainingFreeMints = findRemainingFreeMints(freeMints);
        return remainingFreeMints >= amount ? 0 : (amount - remainingFreeMints) * price;
    }

    function mint(uint amount, uint oracleFreeMints, bytes memory signature) public payable {
        require(tx.origin == _msgSender(), "The caller is another contract");
        require(block.timestamp >= mintingStartTimestamp, "Minting is not available");

        if (oracleFreeMints > 0) {
            require(signature.length != 0 && recoverSignerAddress(_msgSender(), oracleFreeMints, signature) == authorizedSigner, "Invalid signature");
        }

        require(mintPrice(amount, oracleFreeMints) == msg.value, "Wrong ethers value");
        require(amount <= 15 + findRemainingFreeMints(oracleFreeMints), "Too much mints in one transaction");
        require(totalSupply() + reservedSupply + amount <= MAX_SUPPLY, "Tokens supply reached limit");
        require(mintedNFTs[msg.sender] + amount <= maxMintsPerWallet, "maxMintsPerWallet constraint violation");

        mintedNFTs[msg.sender] += amount;
        _safeMint(_msgSender(), amount);
    }

    function mint(uint amount) public payable {
        mint(amount, 0, bytes(""));
    }
    //endregion

    function airdrop(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            require(totalSupply() + amounts[i] <= MAX_SUPPLY, "Tokens supply reached limit");
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        if (osAutoApproveEnabled) {
            OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(osProxyRegistryAddress);
            if (address(proxyRegistry.proxies(_owner)) == operator) {
                return true;
            }
        }
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